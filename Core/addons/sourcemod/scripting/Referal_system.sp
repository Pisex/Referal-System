#pragma semicolon 1
#pragma newdecls required

#include <referal_system>
#include <multicolors>
#include <clientprefs>

Database g_hDatabase;

Handle g_hOnItemTakedInvited,
	g_hOnItemTakedInviter,
	g_hCoreIsLoad,
	g_hTimer[MAXPLAYERS+1],
	g_hCookie;

Menu BonusMenuInviter,	//Приглашающий
	BonusMenuInvited;	//Приглашенный

int g_iItemID_Inviter,
	g_iItemID_Invited,
	g_iClientID[MAXPLAYERS+1],
	g_iClientRID[MAXPLAYERS+1],
	g_iReferalBonuses[MAXPLAYERS+1],
	g_iGameTime[MAXPLAYERS+1],
	g_iBonus[MAXPLAYERS+1],
	g_iTarget[MAXPLAYERS+1],
	g_iRID[MAXPLAYERS+1],
	g_iGiveRefBonus,			//Сколько бонусов давать за приглашенного игрока
	g_iInputActiveTimeRefCode,	//Сколько времени можно ввести реф код
	g_iUnlockCreationsRefCode, // КонВар Когда можно создать реф код
	g_iUnlockInputRefCode,
	g_iCountTop,				//Количество игроков отображающихся в топе
	g_iTimeGive,				//Время отыгранное с реф кодом чтобы получить бонус
	g_iTransferCommission,		//Комиссия при передаче бонусов
	g_iID_Server;



char g_sRefCodeInviter[MAXPLAYERS+1][16],	//Реф код приглащающего
	g_sRefCodeInvited[MAXPLAYERS+1][16],	//Реф код приглашенного
	g_sPrefix[64];	

bool g_bUseChat[MAXPLAYERS+1],
	g_bUseChatRegRefCode[MAXPLAYERS+1],
	g_bClientIsReferal[MAXPLAYERS+1],
	g_bUseChatBonus[MAXPLAYERS+1],
	g_bLoaded,
	g_bTransferBonus;

public Plugin myinfo =
{
	name	= "[RS] Core",
	version	= "1.1.2",
	author	= "Pisex",
    url = "Discord => Pisex#0023"
};

public void OnPluginStart()
{
	LoadTranslations("Referal_System.phrases");
	
	LoadCFG();
	g_hOnItemTakedInvited = CreateGlobalForward("ReferalCore_TakeItemInvited", ET_Ignore, Param_Cell, Param_Cell);
	g_hOnItemTakedInviter = CreateGlobalForward("ReferalCore_TakeItemInviter", ET_Ignore, Param_Cell, Param_Cell);
	g_hCoreIsLoad = CreateGlobalForward("ReferalCore_OnCoreLoaded", ET_Ignore);

	g_hCookie = RegClientCookie("referal_system_givebonus", "Given bonus", CookieAccess_Private);

	AddCommandListener(HookPlayerChat, "say");
	AddCommandListener(HookPlayerChat, "say_team");

	if (SQL_CheckConfig("referal_system"))	//Проверка есть ли в конфиг бд пункт referal_system 
	{
		Database.Connect(OnDBConnect, "referal_system");
	}
	else
	{
		SetFailState("No databases.cfg referal_system");
	}

	RegConsoleCmd("sm_ref",CMD_CallBack);

	BonusMenuInviter = new Menu(BonusMenuInviterCallBack); //Меню Приглашающий
	SetMenuExitBackButton(BonusMenuInviter, true);
	SetMenuExitButton(BonusMenuInviter, true);

	BonusMenuInvited = new Menu(BonusMenuInvitedCallBack); //Меню Приглашенный
	char Title[128];
	FormatEx(Title,sizeof Title,"%t","TitleInvited");
	SetMenuTitle(BonusMenuInvited, Title);
	SetMenuExitBackButton(BonusMenuInvited, false);
	SetMenuExitButton(BonusMenuInvited, true);
}

void LoadCFG()
{
	char buffer[PLATFORM_MAX_PATH];
	KeyValues KV = CreateKeyValues("RS");
	BuildPath(Path_SM, buffer, sizeof buffer, "configs/Referal_System/Core.ini");
	FileToKeyValues(KV, buffer);
	KvRewind(KV);
	g_iGiveRefBonus = KvGetNum(KV,"NumberBonusGive");
	g_iInputActiveTimeRefCode = KvGetNum(KV,"ActiveTimeInput");
	g_iUnlockCreationsRefCode = KvGetNum(KV,"UnlockTimeCreate");
	g_iUnlockInputRefCode = KvGetNum(KV,"UnlockTimeInput");
	g_iCountTop = KvGetNum(KV,"CountTop");
	g_iTimeGive = KvGetNum(KV,"AfterTimeGive");
	g_bTransferBonus = view_as<bool>(KvGetNum(KV,"Transfer"));
	g_iTransferCommission = KvGetNum(KV,"TCommission");
	KvGetString(KV,"PrefixTable",g_sPrefix,sizeof g_sPrefix);
	g_iID_Server = KvGetNum(KV,"ServerID");
}

public int BonusMenuInviterCallBack(Menu menu, MenuAction action, int iClient, int itemSelect) // выдача бонуса
{
	if(action == MenuAction_Select)
	{
		char szItemName[16], szItemDescription[32];
		GetMenuItem(menu, itemSelect, szItemDescription, sizeof(szItemDescription), _, szItemName, sizeof(szItemName));
		Call_StartForward(g_hOnItemTakedInviter);
		Call_PushCell(iClient);
		Call_PushCell(itemSelect+1);
		Call_Finish();
	}
	else if(action == MenuAction_Cancel)
	{
		if (itemSelect == MenuCancel_ExitBack)
		{
			Panel_Ref(iClient);
		}
	}
}

public int BonusMenuInvitedCallBack(Menu menu, MenuAction action, int iClient, int itemSelect) // выдача бонуса
{
	if(action == MenuAction_Select)
	{
		char szItemName[16], szItemDescription[32];
		GetMenuItem(menu, itemSelect, szItemDescription, sizeof(szItemDescription), _, szItemName, sizeof(szItemName));
		Call_StartForward(g_hOnItemTakedInvited);
		Call_PushCell(iClient);
		Call_PushCell(itemSelect+1);
		Call_Finish();

		char szQuery[256];

		FormatEx(szQuery, sizeof(szQuery), "SELECT `rid` FROM `%sreferal_system_inviter` WHERE `referal_code` = '%s';",g_sPrefix, g_sRefCodeInvited[iClient]);
		g_hDatabase.Query(SQL_Callback_GetRID, szQuery, GetClientUserId(iClient)); // Отправляем запрос
	}
}

public void SQL_Callback_GetRID(Database hDatabase, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQL_Callback_GetRID: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}

	if(hResults.FetchRow())	// Игрок есть в базе
	{
		// Получаем значения из результата
		int RID = hResults.FetchInt(0);	// id
		bool ClientIsGame;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i))
				if(RID == g_iClientRID[i])
				{
					int iClient = GetClientOfUserId(iUserID);
					Referal_GiveBonus(i,g_iGiveRefBonus);
					CPrintToChat(iClient, "%t", "GivenBonus", g_iGiveRefBonus,iClient);
					ClientIsGame = true;
					break;
				}
		}
		if(!ClientIsGame)
		{
			char szQuery[256];

			FormatEx(szQuery, sizeof(szQuery), "UPDATE `%sreferal_system_inviter` SET `referal_bonuses` = `referal_bonuses`+%i WHERE `rid` = %i;",g_sPrefix,g_iGiveRefBonus, RID);
			g_hDatabase.Query(SQL_CheckError, szQuery);
		}
	}
}

public Action AutoTickFSF(Handle timer)
{
	char Bonus[12];
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
		{
			g_iGameTime[i] += 1;
			if(strcmp(g_sRefCodeInvited[i],"unknown") && g_iBonus[i] == 0)
			{
				if(g_iTimeGive == 0)
				{
					DisplayMenu(BonusMenuInvited, i, MENU_TIME_FOREVER);
					g_iBonus[i] = 1;
					g_hTimer[i] = null;
					return Plugin_Stop;
				}
				else
				{
					GetClientCookie(i,g_hCookie,Bonus,sizeof Bonus);
					if(StringToInt(Bonus) >= g_iGameTime[i])
					{
						DisplayMenu(BonusMenuInvited, i, MENU_TIME_FOREVER);
						g_iBonus[i] = 1;
						g_hTimer[i] = null;
						return Plugin_Stop;
					}
				}	
			}
		}
	}
	return Plugin_Continue;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Referal_RegisterItemInvited", ReferalRegisterItemInvited);	//Добавление в меню бонуса Приглашённого
	CreateNative("Referal_RegisterItemInviter", ReferalRegisterItemInviter);	//Добавление в меню бонуса Приглашающего
	CreateNative("Referal_GiveBonus", ReferalGiveBonus);	//Выдает бонусы
	CreateNative("Referal_TakeBonus", ReferalTakeBonus);	//Забирает бонусы
	CreateNative("Referal_GetBonus", ReferalGetBonus); 		//Получает количество бонусов у клиента
	CreateNative("Referal_OpenMainMenu", ReferalMainMenu); 		//Получает количество бонусов у клиента
	CreateNative("Referal_OpenControlRefMenu", ReferalControlMenu); 		//Получает количество бонусов у клиента
	CreateNative("Referal_OpenBonusMenu", ReferalBonusMenu); 		//Получает количество бонусов у клиента
	CreateNative("Referal_ClientReferal", ReferalCheckClientRef); //Проверяет реферал ли игрок
	CreateNative("Referal_ClientUseRefCode", ReferalCheckRefCode);//Проверяем ввёл ли игрок реф код
	CreateNative("Referal_CoreIsLoad", ReferalCoreIsLoad);
	CreateNative("Referal_GetDatabase", ReferalGetDatabase);					//Возвращает Handle Базы Данных
	RegPluginLibrary("referal_system");

	return APLRes_Success;
}

public int ReferalCheckRefCode(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(1);
	if(!strcmp(g_sRefCodeInvited[iClient],"unknown"))
		return false;
	else
		return true;
}

public int ReferalGetDatabase(Handle hPlugin, int iParams)
{
	return view_as<int>(CloneHandle(g_hDatabase, hPlugin));
}

public int ReferalCoreIsLoad(Handle hPlugin, int iParams)
{
	return g_bLoaded;
}

public int ReferalRegisterItemInvited(Handle hPlugin, int iParams) //Добавление в меню бонуса Приглашённого
{
	char ItemName[64];
	if(GetNativeString(1, ItemName, sizeof(ItemName)) == SP_ERROR_NONE)
	{
		char Unique_Name[64];
		if(GetNativeString(2, Unique_Name, sizeof(Unique_Name)) == SP_ERROR_NONE)
		{
			AddMenuItem(BonusMenuInvited, Unique_Name, ItemName);
			g_iItemID_Invited++;
			return g_iItemID_Invited;
		}
	}
	return -1;
}

void Referal_OnCoreLoaded()
{
	g_bLoaded = true;
	Call_StartForward(g_hCoreIsLoad);
	Call_Finish();
}

public int ReferalRegisterItemInviter(Handle hPlugin, int iParams) //Добавление в меню бонуса Приглашающего
{
	char ItemName[64];
	if(GetNativeString(1, ItemName, sizeof(ItemName)) == SP_ERROR_NONE)
	{
		char Unique_Name[64];
		if(GetNativeString(2, Unique_Name, sizeof(Unique_Name)) == SP_ERROR_NONE)
		{
			AddMenuItem(BonusMenuInviter, Unique_Name, ItemName);
			g_iItemID_Inviter++;
			return g_iItemID_Inviter;
		}
	}
	return -1;
}

public int ReferalGiveBonus(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(1);
	if(Referal_ClientReferal(iClient))
	{
		int iCount = GetNativeCell(2);
		g_iReferalBonuses[iClient] += iCount;
	}
}

public int ReferalTakeBonus(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(1);
	if(Referal_ClientReferal(iClient))
	{
		int iCount = GetNativeCell(2);
		g_iReferalBonuses[iClient] -=iCount;
	}
}

public int ReferalGetBonus(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(1);
	if(Referal_ClientReferal(iClient))
	{
		return g_iReferalBonuses[iClient];
	}
	return 0;
}

public int ReferalMainMenu(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(1);
	CMD_CallBack(iClient,0);
}

public int ReferalControlMenu(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(1);
	Panel_Ref(iClient);
}

public int ReferalBonusMenu(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(1);
	DisplayMenu(BonusMenuInvited,iClient,0);
}

public int ReferalCheckClientRef(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(1);
	return g_bClientIsReferal[iClient];
}

public void OnDBConnect(Database hDatabase, const char[] sError, any data)
{
	if(!hDatabase)	// Соединение неудачное
	{
		SetFailState("Database failure: %s", sError);
		return;
	}

	g_hDatabase = hDatabase;
	CreateTables();
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
}

public void CreateTables()
{
	char driver[16],query[1024];
    DBDriver Driver = g_hDatabase.Driver;
    
    Driver.GetIdentifier(driver, sizeof(driver));

	if(driver[0] == 'm')
    {
		FormatEx(query, sizeof(query), 	    "CREATE TABLE IF NOT EXISTS `%sreferal_system_players`(\
																`id` INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,\
																`server_id` INTEGER NOT NULL default 0,\
																`steamid` VARCHAR(32) NOT NULL,\
																`name` VARCHAR(32) NOT NULL,\
																`game_time` INTEGER NOT NULL default '0',\
																`ref_code` VARCHAR(16) NOT NULL default 'unknown',\
																`bonus` INTEGER NOT NULL default '0');",g_sPrefix);

		g_hDatabase.Query(SQL_CheckError, query);

		FormatEx(query,sizeof query,"CREATE TABLE IF NOT EXISTS `%sreferal_system_inviter`(\
																`rid` INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,\
																`server_id` INTEGER NOT NULL default 0,\
																`steamid` VARCHAR(32) NOT NULL,\
																`name` VARCHAR(32) NOT NULL,\
																`referal_bonuses` INTEGER NOT NULL DEFAULT 0,\
																`referals_count` INTEGER NOT NULL DEFAULT 0,\
																`referal_code` VARCHAR(16) NOT NULL);",g_sPrefix);

		g_hDatabase.Query(SQL_CheckError, query);
		g_hDatabase.SetCharset("utf8");
	}
	else if(driver[0] == 's')
    {
		SQL_LockDatabase(g_hDatabase);

		FormatEx(query, sizeof(query), 	    "CREATE TABLE IF NOT EXISTS `%sreferal_system_players`(\
																`id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\
																`server_id` INTEGER NOT NULL default 0,\
																`steamid` VARCHAR(32) NOT NULL,\
																`name` VARCHAR(32) NOT NULL,\
																`game_time` INTEGER NOT NULL default '0',\
																`ref_code` VARCHAR(16) NOT NULL default 'unknown',\
																`bonus` INTEGER NOT NULL default '0');",g_sPrefix);

		g_hDatabase.Query(SQL_CheckError, query);

		FormatEx(query,sizeof query,"CREATE TABLE IF NOT EXISTS `%sreferal_system_inviter`(\
																`rid` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,\
																`server_id` INTEGER NOT NULL default 0,\
																`steamid` VARCHAR(32) NOT NULL,\
																`name` VARCHAR(32) NOT NULL,\
																`referal_bonuses` INTEGER NOT NULL DEFAULT 0,\
																`referals_count` INTEGER NOT NULL DEFAULT 0,\
																`referal_code` VARCHAR(16) NOT NULL);",g_sPrefix);

		g_hDatabase.Query(SQL_CheckError, query);
		g_hDatabase.SetCharset("utf8");
        SQL_UnlockDatabase(g_hDatabase);
	}
	Referal_OnCoreLoaded();
}

public void SQL_CheckError(Database hDatabase, DBResultSet results, const char[] szError, any data) // проверка ошибки нету ли ошибок
{
	if(szError[0]) LogError("SQL_Callback_CheckError: %s", szError);
}

public void OnClientPostAdminCheck(int iClient)
{
	if(!IsFakeClient(iClient))
	{
		char szQuery[256], szAuth[32];
		GetClientAuthId(iClient, AuthId_Engine, szAuth, sizeof(szAuth), true); // Получаем SteamID игрока
		FormatEx(szQuery, sizeof(szQuery), "SELECT `id`, `game_time`, `ref_code`, `bonus` FROM `%sreferal_system_players` WHERE `steamid` = '%s' AND `server_id` = '%i';",g_sPrefix, szAuth,g_iID_Server);
		g_hDatabase.Query(SQL_Callback_SelectClient, szQuery, GetClientUserId(iClient)); // Отправляем запрос

		
		FormatEx(szQuery, sizeof(szQuery), "SELECT `rid`, `referal_bonuses`, `referal_code` FROM `%sreferal_system_inviter` WHERE `steamid` = '%s' AND `server_id` = '%i';",g_sPrefix,szAuth,g_iID_Server);
		g_hDatabase.Query(SQL_Callback_SelectRef, szQuery, GetClientUserId(iClient)); // Отправляем запрос

		g_hTimer[iClient] = CreateTimer(60.0, AutoTickFSF, _, TIMER_REPEAT);
	}
}

public void SQL_Callback_SelectRef(Database hDatabase, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQL_Callback_SelectRef: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
	
	int iClient = GetClientOfUserId(iUserID);
	if(iClient)
	{
		char szQuery[256], szName[MAX_NAME_LENGTH*2+1];
		GetClientName(iClient, szQuery, MAX_NAME_LENGTH);
		g_hDatabase.Escape(szQuery, szName, sizeof(szName)); // Экранируем запрещенные символы в имени

		// Игрок всё еще на сервере
		if(hResults.FetchRow())	// Игрок есть в базе
		{
			// Получаем значения из результата
			g_iClientRID[iClient] = hResults.FetchInt(0);	// id
			g_iReferalBonuses[iClient] = hResults.FetchInt(1);
			hResults.FetchString(2,g_sRefCodeInviter[iClient],sizeof g_sRefCodeInviter[]);
			g_bClientIsReferal[iClient] = true;

			// Обновляем в базе ник и дату последнего входа
			FormatEx(szQuery, sizeof(szQuery), "UPDATE `%sreferal_system_inviter` SET `name` = '%s' WHERE `rid` = %i;",g_sPrefix, szName, g_iClientRID[iClient]);
			g_hDatabase.Query(SQL_CheckError, szQuery);
		}
		else
			g_bClientIsReferal[iClient] = false;
	}
}

public void SQL_Callback_SelectClient(Database hDatabase, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQL_Callback_SelectClient: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
	
	int iClient = GetClientOfUserId(iUserID);
	if(iClient)
	{
		char szQuery[256], szName[MAX_NAME_LENGTH*2+1];
		GetClientName(iClient, szQuery, MAX_NAME_LENGTH);
		g_hDatabase.Escape(szQuery, szName, sizeof(szName)); // Экранируем запрещенные символы в имени

		// Игрок всё еще на сервере
		if(hResults.FetchRow())	// Игрок есть в базе
		{
			// Получаем значения из результата
			g_iClientID[iClient] = hResults.FetchInt(0);	// id
			g_iGameTime[iClient] = hResults.FetchInt(1);
			hResults.FetchString(2,g_sRefCodeInvited[iClient],sizeof g_sRefCodeInvited[]);
			g_iBonus[iClient] = hResults.FetchInt(3);

			// Обновляем в базе ник и дату последнего входа
			FormatEx(szQuery, sizeof(szQuery), "UPDATE `%sreferal_system_players` SET `name` = '%s' WHERE `id` = %i;",g_sPrefix, szName, g_iClientID[iClient]);
			g_hDatabase.Query(SQL_CheckError, szQuery);
		}
		else
		{
			g_iClientID[iClient] = 0;
			g_iGameTime[iClient] = 0;
			g_sRefCodeInvited[iClient] = "unknown";
			g_iBonus[iClient] = 0;

			// Добавляем игрока в базу
			char szAuth[32];
			GetClientAuthId(iClient, AuthId_Engine, szAuth, sizeof(szAuth));
			FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `%sreferal_system_players` (`steamid`, `name`, `server_id`) VALUES ( '%s', '%s', '%i');",g_sPrefix, szAuth, szName,g_iID_Server);
			g_hDatabase.Query(SQL_Callback_CreateClient, szQuery, GetClientUserId(iClient));
		}
	}
}

public void SQL_Callback_SelectReferalClient(Database hDatabase, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQL_Callback_SelectReferalClient: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
	
	int iClient = GetClientOfUserId(iUserID);
	if(iClient)
	{
		if(hResults.FetchRow())
			CPrintToChat(iClient, "%t", "YouAlreadyRefCode");
		else
		{
			if(g_iGameTime[iClient] >= g_iUnlockCreationsRefCode || g_iUnlockCreationsRefCode == 0)
			{
				g_iClientRID[iClient] = 0;
				g_iReferalBonuses[iClient] = 0;
				g_bUseChatRegRefCode[iClient] = true;
				g_bUseChat[iClient] = false;
				g_bUseChatBonus[iClient] = false;
				CPrintToChat(iClient, "%t", "EnterRefCodeCreate");
			}
			else
				CPrintToChat(iClient, "%t", "DontEnterRefCodeCreate");
		}
	}
}


public void SQL_Callback_CreateClient(Database hDatabase, DBResultSet results, const char[] szError, any iUserID)
{
	if(szError[0])
	{
		LogError("SQL_Callback_CreateClient: %s", szError);
		return;
	}
	
	int iClient = GetClientOfUserId(iUserID);
	if(iClient)
	{
		g_iClientID[iClient] = results.InsertId; // Получаем ID только что добавленного игрока
	}
}

public void SQL_Callback_CreateReferalClient(Database hDatabase, DBResultSet results, const char[] szError, any iUserID)
{
	if(szError[0])
	{
		LogError("SQL_Callback_CreateReferalClient: %s", szError);
		return;
	}
	
	int iClient = GetClientOfUserId(iUserID);
	if(iClient)
	{
		g_iClientRID[iClient] = results.InsertId; // Получаем ID только что добавленного игрока
	}
}

// Игрок отключился
public void OnClientDisconnect(int iClient)
{
	if(g_hTimer[iClient] != null)g_hTimer[iClient] = null;
	delete g_hTimer[iClient];
	if(!IsFakeClient(iClient))
	{
		char szQuery[512];
		FormatEx(szQuery, sizeof(szQuery), "UPDATE `%sreferal_system_players` SET `game_time` = %i,`bonus` = %i WHERE `id` = %i;",g_sPrefix, g_iGameTime[iClient],g_iBonus[iClient], g_iClientID[iClient]);
		g_hDatabase.Query(SQL_CheckError, szQuery);
		if(Referal_ClientReferal(iClient))
		{
			FormatEx(szQuery, sizeof(szQuery), "UPDATE `%sreferal_system_inviter` SET `referal_bonuses` = %i WHERE `rid` = %i;",g_sPrefix,g_iReferalBonuses[iClient], g_iClientRID[iClient]);
			g_hDatabase.Query(SQL_CheckError, szQuery);
		}
	}
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			OnClientDisconnect(i);
	}
}

public Action CMD_CallBack(int iClient,int args)
{
	Menu hMenu = new Menu(MenuCallback);

	hMenu.SetTitle("Referal System");
	char Item[64];
	FormatEx(Item,sizeof Item,"%t","InputMenu");
	hMenu.AddItem("input",Item);
	FormatEx(Item,sizeof Item,"%t","CreateRefMenu");
	hMenu.AddItem("create",Item);
	FormatEx(Item,sizeof Item,"%t","UprRefMenu");
	hMenu.AddItem("MenuRef",Item);
	FormatEx(Item,sizeof Item,"%t","TopMenu");
	if(g_iCountTop) hMenu.AddItem("Top",Item);

	DisplayMenu(hMenu,iClient,0);

	return Plugin_Handled;
}

public int MenuCallback(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char Item[32];
			GetMenuItem(hMenu,iItem,Item,sizeof Item);

			if(!strcmp(Item,"input"))
			{
				char szQuery[256], szAuth[32];
				GetClientAuthId(iClient, AuthId_Engine, szAuth, sizeof(szAuth), true); // Получаем SteamID игрока
				FormatEx(szQuery, sizeof(szQuery), "SELECT `ref_code` FROM `%sreferal_system_players` WHERE `steamid` = '%s' AND `server_id` = '%i';",g_sPrefix, szAuth,g_iID_Server);
				g_hDatabase.Query(SQL_Callback_CheckRefCodeVvod, szQuery, iClient); // Отправляем запрос
			}
			else if(!strcmp(Item,"create"))
			{
				char szQuery[256], szAuth[32];
				GetClientAuthId(iClient, AuthId_Engine, szAuth, sizeof(szAuth), true); // Получаем SteamID игрока
				FormatEx(szQuery, sizeof(szQuery), "SELECT `rid`, `referal_bonuses`, `referal_code` FROM `%sreferal_system_inviter` WHERE `steamid` = '%s' AND `server_id` = '%i';",g_sPrefix, szAuth, g_iID_Server);
				g_hDatabase.Query(SQL_Callback_SelectReferalClient, szQuery, GetClientUserId(iClient)); // Отправляем запрос
			}
			else if(!strcmp(Item,"MenuRef"))
			{
				if(Referal_ClientReferal(iClient) && strcmp(g_sRefCodeInviter[iClient],""))
				{
					Panel_Ref(iClient);
				}
				else
					CPrintToChat(iClient, "%t", "YouDontRefCode");
			}
			else if(!strcmp(Item,"Top"))
			{
				char szQuery[256];
				FormatEx(szQuery, sizeof(szQuery), "SELECT `name`, `referals_count` FROM `%sreferal_system_inviter` WHERE `server_id` = '%i' ORDER BY `referals_count` DESC LIMIT %i;",g_sPrefix, g_iID_Server,g_iCountTop);
				g_hDatabase.Query(SQL_Callback_TopInviters, szQuery, iClient);
			}
		}
	}
}

void SQL_Callback_TopInviters(Database database, DBResultSet result, const char[] error, int iClient)
{
    if(result == null)
    {
        LogError("SQL_Callback_TopInviters: %s", error);
        return;
    }

    if(!iClient) return;

    char buff[128], name[64];
    Panel panel = new Panel();
	
	char Item[64];
	FormatEx(Item,sizeof Item,"%t","OpenTopMenu");
    panel.SetTitle(Item);

    int count = result.RowCount;

    for(int i = 1; i <= count; i++)
    {
        if(result.FetchRow())
        {
            result.FetchString(0, name, sizeof(name));
            FormatEx(buff, sizeof(buff), "%d. %s [%i]", i, name, result.FetchInt(1));
            panel.DrawText(buff);
        }
    }
    panel.DrawText(" ");
	FormatEx(Item,sizeof Item,"%t","Back");
    panel.CurrentKey = 7;
    panel.DrawItem(Item);
    panel.DrawText(" ");
	FormatEx(Item,sizeof Item,"%t","Exit");
    panel.CurrentKey = 9;
    panel.DrawItem(Item);
    panel.Send(iClient, HandlerOfPanelTopInviter, MENU_TIME_FOREVER);

    delete panel;
}

int HandlerOfPanelTopInviter(Menu menu, MenuAction action, int iClient, int item)
{
    if(action == MenuAction_Select)
    {
        if(item == 7)
        {
            CMD_CallBack(iClient,0);
        }
    }
}

public void SQL_Callback_CheckRefCodeVvod(Database hDatabase, DBResultSet hResults, const char[] sError, int iClient)
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQL_Callback_CheckRefCodeVvod: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
	if(hResults.FetchRow())
	{
		char Result[16];
		hResults.FetchString(0,Result,sizeof Result);
		if(!strcmp(Result,"") || !strcmp(Result,"unknown"))
		{
			if(g_iGameTime[iClient] >= g_iUnlockInputRefCode)
			{
				if(g_iGameTime[iClient] <= (g_iInputActiveTimeRefCode+g_iUnlockInputRefCode) || (g_iInputActiveTimeRefCode+g_iUnlockInputRefCode) == 0)
				{
					g_bUseChat[iClient] = true;
					g_bUseChatRegRefCode[iClient] = false;
					g_bUseChatBonus[iClient] = false;
					CPrintToChat(iClient, "%t", "EnterRefCode");
				}
				else
				{
					CPrintToChat(iClient, "%t", "TimedOut");
					CMD_CallBack(iClient,0);
				}
			}
			else
			{
				CPrintToChat(iClient, "%t", "YouDidntPlayAllottedTime");
				CMD_CallBack(iClient,0);
			}
		}
		else
		{
			CPrintToChat(iClient, "%t", "YouAlreadyEntered");
		}
	}
}

public Action HookPlayerChat(int iClient, char[] command, int args)
{
	char szQuery[256];
	if (g_bUseChat[iClient])
	{
		g_bUseChat[iClient] = false;
		GetCmdArg(1, g_sRefCodeInvited[iClient], sizeof g_sRefCodeInvited[]);

		FormatEx(szQuery, sizeof(szQuery), "SELECT `name`, `rid`, `steamid` FROM `%sreferal_system_inviter` WHERE `referal_code` = '%s' AND `server_id` = '%i';",g_sPrefix, g_sRefCodeInvited[iClient], g_iID_Server);
		g_hDatabase.Query(SQL_Callback_CheckRefCode, szQuery, iClient); // Отправляем запрос
		return Plugin_Handled;
	}
	if(g_bUseChatRegRefCode[iClient])
	{
		char szName[MAX_NAME_LENGTH*2+1],RefCode[16];
		GetClientName(iClient, szQuery, MAX_NAME_LENGTH);
		g_hDatabase.Escape(szQuery, szName, sizeof(szName));
		g_bUseChatRegRefCode[iClient] = false;
		GetCmdArg(1,RefCode, sizeof RefCode);
		if(RefCode[4] == '-' && strlen(RefCode) == 9)
		{
			g_sRefCodeInviter[iClient] = RefCode;
			char szAuth[32];
			GetClientAuthId(iClient, AuthId_Engine, szAuth, sizeof(szAuth));
			FormatEx(szQuery, sizeof(szQuery), "SELECT `name` FROM `%sreferal_system_inviter` WHERE `referal_code` = '%s' AND `server_id` = '%i';",g_sPrefix, g_sRefCodeInviter[iClient], g_iID_Server);
			g_hDatabase.Query(SQL_Callback_CheckRefCodeSush, szQuery, iClient); // Отправляем запрос
		}
		else
			CPrintToChat(iClient, "%t", "NotMatchTheFormat");

		return Plugin_Handled;
	}
	if(g_bUseChatBonus[iClient])
	{
		g_bUseChatBonus[iClient] = false;
		char Count[12];
		GetCmdArg(1, Count, sizeof Count);
		int iCount = StringToInt(Count);
		if((Referal_GetBonus(iClient) - iCount) > 0)
		{
			int iCommission = RoundFloat((StringToFloat(Count) * g_iTransferCommission)/100);
			Referal_TakeBonus(iClient,iCount);
			if(g_iTransferCommission > 0)
			{
				Referal_GiveBonus(g_iTarget[iClient], iCommission);
				CPrintToChat(iClient, "%t", "TransferMeCommision",g_iTarget[iClient],iCount,iCommission);
				CPrintToChat(iClient, "%t", "TransferYouCommision", iClient,iCount,iCommission);
			}
			else if(g_iTransferCommission == 0)
			{
				Referal_GiveBonus(g_iTarget[iClient], iCount);
				CPrintToChat(iClient, "%t", "TransferMeNotCommision",g_iTarget[iClient],iCount);
				CPrintToChat(iClient, "%t", "TransferYouNotCommision", iClient,iCount);
			}
		}
		else
			CPrintToChat(iClient, "%t", "NotTransferBonus");
		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void SQL_Callback_CheckRefCodeSush(Database hDatabase, DBResultSet hResults, const char[] sError, int iClient)
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQL_CallbackGetMaxRID: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
	if(hResults.FetchRow())	// Игрок есть в базе
	{
		char Result[MAX_NAME_LENGTH*2+1];
		hResults.FetchString(0,Result,sizeof Result);
		CPrintToChat(iClient, "%t", "DontCreateRef",Result);
	}
	else
	{
		CPrintToChat(iClient, "%t", "CreatedRefCode");
		char szAuth[32],
			szQuery[256],
			szName[MAX_NAME_LENGTH*2+1];
		GetClientName(iClient, szQuery, MAX_NAME_LENGTH);
		g_hDatabase.Escape(szQuery, szName, sizeof(szName));
		GetClientAuthId(iClient, AuthId_Engine, szAuth, sizeof(szAuth));
		FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `%sreferal_system_inviter` (`steamid`, `name`,`referal_code`,`server_id`) VALUES ( '%s', '%s', '%s','%i');",g_sPrefix, szAuth, szName, g_sRefCodeInviter[iClient],g_iID_Server);
		g_hDatabase.Query(SQL_Callback_CreateReferalClient, szQuery, GetClientUserId(iClient));
		g_bClientIsReferal[iClient] = true;
	}
}

public Action Panel_Ref(int iClient)
{
	Menu hMenu = new Menu(MenuRefValidCallback);
	char Item[256];
	FormatEx(Item,sizeof Item,"%t","MenuRefCodeUpr",g_sRefCodeInviter[iClient],g_iReferalBonuses[iClient]);
	hMenu.SetTitle(Item);
	FormatEx(Item,sizeof Item,"%t","ShopBonus");
	hMenu.AddItem("shop",Item);
	FormatEx(Item,sizeof Item,"%t","transfer");
	if(g_bTransferBonus) hMenu.AddItem("transfer",Item);
	else
	{
		FormatEx(Item,sizeof Item,"%t","transfer_off");
		hMenu.AddItem("transfer",Item,ITEMDRAW_DISABLED);
	}
	FormatEx(Item,sizeof Item,"%t","myreferals");
	hMenu.AddItem("MyReferal",Item);
	hMenu.ExitBackButton = true;

	DisplayMenu(hMenu,iClient,0);
}

public int MenuRefValidCallback(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char Item[64];
			GetMenuItem(hMenu,iItem,Item,sizeof Item);

			if(!strcmp(Item,"shop"))
			{
				char Title[256];
				FormatEx(Title,sizeof Title,"%t","TitleInviter",g_iReferalBonuses[iClient]);
				SetMenuTitle(BonusMenuInviter, Title);
				DisplayMenu(BonusMenuInviter, iClient, MENU_TIME_FOREVER);
			}
			else if(!strcmp(Item,"transfer"))
			{
				Handle menu;
				menu = CreateMenu(Select_PL);
				FormatEx(Item,sizeof Item,"%t","SelectPlayer");
				SetMenuTitle(menu, Item);
				char userid[15], name[64];
				bool ClientEst;
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i) && !IsClientSourceTV(i) && iClient != i && Referal_ClientReferal(i))
					{
						IntToString(i, userid, 15);
						GetClientName(i, name, 64);
						AddMenuItem(menu, userid, name);
						ClientEst = true;
					}
				}
				if(!ClientEst)
				{
					CPrintToChat(iClient, "%t", "DontPlayerFound");
					Panel_Ref(iClient);
				}
				SetMenuExitBackButton(menu, true);
				SetMenuExitButton(menu, true);
				DisplayMenu(menu,iClient,0);
			}
			else if(!strcmp(Item,"MyReferal"))
			{
				char szQuery[256];
				FormatEx(szQuery, sizeof(szQuery), "SELECT `name` FROM `%sreferal_system_players` WHERE `ref_code` = '%s' AND `server_id` = '%i';",g_sPrefix, g_sRefCodeInviter[iClient], g_iID_Server);
				g_hDatabase.Query(SQL_Callback_MyInvite, szQuery, GetClientUserId(iClient));
			}
		}
		case MenuAction_Cancel:
            if(iItem == MenuCancel_ExitBack) CMD_CallBack(iClient,0);
	}
}

void SQL_Callback_MyInvite(Database database, DBResultSet result, const char[] error, int iUserID)
{
    if(result == null)
    {
        LogError("SQL_Callback_MyInvite: %s", error);
        return; 
	}

	int iClient = GetClientOfUserId(iUserID);
    if(!iClient) return;
	
    Handle menu;
	menu = CreateMenu(MenuCMD_MyInvite);
	char Item[64];
	FormatEx(Item,sizeof Item,"%t","MyReferalsMenu");
	SetMenuTitle(menu, Item);
	char name[64];
	bool ClientEst;
	while(result.FetchRow())
	{
		result.FetchString(0,name,sizeof name);
		AddMenuItem(menu, name, name,ITEMDRAW_DISABLED);
		ClientEst = true;
	}
	if(!ClientEst)
	{
		CPrintToChat(iClient, "%t", "ReferalNoPlayer");
		Panel_Ref(iClient);
	}
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu,iClient,0);
}

public int MenuCMD_MyInvite(Handle menu, MenuAction action, int iClient, int option)
{
	if (action == MenuAction_Cancel)if (option == MenuCancel_ExitBack) Panel_Ref(iClient);
	else if (action == MenuAction_End) CloseHandle(menu);
}

public int Select_PL(Handle menu, MenuAction action, int iClient, int option)
{
	if (action == MenuAction_Select)
	{
		char sid[15];
		GetMenuItem(menu, option, sid, 15);
		g_iTarget[iClient] = StringToInt(sid);
		if(g_iTarget[iClient])
		{
			g_bUseChatBonus[iClient] = true;
			g_bUseChat[iClient] = false;
			g_bUseChatRegRefCode[iClient] = false;
			CPrintToChat(iClient, "%t", "EnterBonusTransfer");
		}
		else 
			CPrintToChat(iClient, "%t", "PlayerDisconnectTransfer");
	}
	else if (action == MenuAction_Cancel)if (option == MenuCancel_ExitBack) Panel_Ref(iClient);
	else if (action == MenuAction_End) CloseHandle(menu);
}

public void SQL_Callback_CheckRefCode(Database hDatabase, DBResultSet hResults, const char[] sError, int iClient)
{
	if(sError[0]) // Если произошла ошибка
	{
		LogError("SQL_Callback_CheckRefCode: %s", sError); // Выводим в лог
		return; // Прекращаем выполнение ф-и
	}
	if(hResults.FetchRow())	// Игрок есть в базе
	{
		char Result[MAX_NAME_LENGTH*2+1],rSteamID[64],sSteamID[64];
		hResults.FetchString(0,Result,sizeof Result);
		g_iRID[iClient] = hResults.FetchInt(1);
		hResults.FetchString(2,rSteamID,sizeof rSteamID);
		
		GetClientAuthId(iClient, AuthId_Steam2, sSteamID, sizeof(sSteamID), true);

		if(strcmp(Result,""))
		{
			if(strcmp(sSteamID,rSteamID))
			{
				Menu hMenu = new Menu(MenuRefCallback);
				char textpanel[128];
				FormatEx(textpanel,sizeof textpanel,"%t","SelectRef",Result);
				hMenu.SetTitle(textpanel);
				FormatEx(textpanel,sizeof textpanel,"%t","yes");
				hMenu.AddItem("yes",textpanel);
				FormatEx(textpanel,sizeof textpanel,"%t","no");
				hMenu.AddItem("no",textpanel);
				hMenu.ExitButton = false;
				hMenu.Display(iClient,0);
			}
			else
				CPrintToChat(iClient, "%t", "YouRefCode");
		}
	}
	else
		CPrintToChat(iClient, "%t", "NoFoundRefCode");
}

public int MenuRefCallback(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char Item[10];
			GetMenuItem(hMenu,iItem,Item,sizeof Item);
			
			if(!strcmp(Item,"yes"))
			{
				char szQuery[256],Bonus[12];
				CPrintToChat(iClient, "%t", "SuccessfullyFoundRefCode");
				FormatEx(szQuery, sizeof(szQuery), "UPDATE `%sreferal_system_players` SET `ref_code` = '%s' WHERE `id` = %i;",g_sPrefix, g_sRefCodeInvited[iClient], g_iClientID[iClient]);
				g_hDatabase.Query(SQL_CheckError, szQuery);
				FormatEx(szQuery, sizeof(szQuery), "UPDATE `%sreferal_system_inviter` SET `referals_count` = `referals_count`+1 WHERE `rid` = %i;",g_sPrefix, g_iRID[iClient]);
				g_hDatabase.Query(SQL_CheckError, szQuery);

				IntToString(g_iGameTime[iClient] + g_iTimeGive,Bonus,sizeof Bonus);

				SetClientCookie(iClient,g_hCookie,Bonus);
			}
			else
				delete hMenu;
		}
	}
}