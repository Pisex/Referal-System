#pragma semicolon 1
#pragma newdecls required

#include <wcs>
#include <referal_system>
#include <csgo_colors>

public Plugin myinfo =
{
	name	= "[RS] WCS - Shop",
	version	= "1.0.0",
	author	= "Pisex",
    url = "Discord => Pisex#0023"
};

bool g_bUseChatGold[MAXPLAYERS+1],
	g_bUseChatLVL[MAXPLAYERS+1];

char g_sGold[MAXPLAYERS+1][12],
	g_sLVL[MAXPLAYERS+1][12],
	NamePoint[32],
	NameGold[32],
	NameLVL[32],
	NameVIP[32],
	NameRace[32],
	g_sRace[32][32],
	g_sVIP[32][32];

Menu BonusWCS,
	BonusWCSVIP,
	BonusWCSRace;

#define CountBonusLVL (CourseBonusLVL * StringToFloat(g_sLVL[iClient])/CourseLVL)
#define CountBonusGold (CourseBonusGold * StringToFloat(g_sGold[iClient])/CourseGold)

int g_iItemID,
	CourseBonusLVL,
	CourseBonusGold,
    CourseGold,
    CourseLVL,
	g_iPriceRace[32],
	g_iTimeVIP[32],
	g_iPriceVIP[32];

public void OnPluginStart()
{
	AddCommandListener(HookPlayerChat, "say");
	AddCommandListener(HookPlayerChat, "say_team");

    

	ConVar Cvar = CreateConVar("sm_rs_shop_course_wcs_gold", "500", "Количество кредитов на sm_rs_shop_course_wcs_gold_bonus(500 голды за 5б. на данный момент)", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Shop_Course_WCS_gold);
	CVarChanged_Shop_Course_WCS_gold(Cvar, NULL_STRING, NULL_STRING);

	Cvar = CreateConVar("sm_rs_shop_WCS_name_gold", "WCS Золото", "Название пункта золота в меню магазина бонусов[Оставить пустым - Исключить из меню]");
	HookConVarChange(Cvar, CVarChanged_WCS_Name_gold);
	GetConVarString(Cvar, NameGold, sizeof(NameGold));

	Cvar = CreateConVar("sm_rs_shop_course_wcs_gold_bonus", "5", "Стоимость за sm_rs_shop_course_wcs_gold", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Shop_Course_WCS_Bonus_gold);
	CVarChanged_Shop_Course_WCS_Bonus_gold(Cvar, NULL_STRING, NULL_STRING);

	Cvar = CreateConVar("sm_rs_shop_course_wcs_lvl", "10", "Количество кредитов на sm_rs_shop_course_wcs_lvl_bonus(10 уровней за 5б. на данный момент)", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Shop_Course_WCS_lvl);
	CVarChanged_Shop_Course_WCS_lvl(Cvar, NULL_STRING, NULL_STRING);

	Cvar = CreateConVar("sm_rs_shop_WCS_lvl", "WCS Уровень", "Название пункта уровней в меню магазина бонусов[Оставить пустым - Исключить из меню]");
	HookConVarChange(Cvar, CVarChanged_WCS_Name_lvl);
	GetConVarString(Cvar, NameLVL, sizeof(NameLVL));

	Cvar = CreateConVar("sm_rs_shop_course_wcs_lvl_bonus", "5", "Стоимость за sm_rs_shop_course_wcs_lvl", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Shop_Course_WCS_Bonus_lvl);
	CVarChanged_Shop_Course_WCS_Bonus_lvl(Cvar, NULL_STRING, NULL_STRING);
	
	Cvar = CreateConVar("sm_rs_shop_WCS_name", "WCS Золото/Уровень/Раса/Вип", "Название пункта в меню магазина бонусов");
	HookConVarChange(Cvar, CVarChanged_WCS_Name);
	GetConVarString(Cvar, NamePoint, sizeof(NamePoint));

	Cvar = CreateConVar("sm_rs_shop_WCS_vip", "WCS Вип группы", "Название пункта випок в меню магазина бонусов[Оставить пустым - Исключить из меню]");
	HookConVarChange(Cvar, CVarChanged_WCS_Name_vip);
	GetConVarString(Cvar, NameVIP, sizeof(NameVIP));

	Cvar = CreateConVar("sm_rs_shop_WCS_race", "WCS Расы", "Название пункта рас в меню магазина бонусов[Оставить пустым - Исключить из меню]");
	HookConVarChange(Cvar, CVarChanged_WCS_Name_race);
	GetConVarString(Cvar, NameRace, sizeof(NameRace));

	AutoExecConfig(true, "WCS_Shop","ReferalSystem");

	BonusWCS = new Menu(BonusMenuWCSCallBack);
	SetMenuExitBackButton(BonusWCS, true);
	SetMenuExitButton(BonusWCS, true);

	BonusWCSRace = new Menu(BonusMenuWCS_Race_CallBack);
	SetMenuExitBackButton(BonusWCSRace, true);
	SetMenuExitButton(BonusWCSRace, true);

	BonusWCSVIP = new Menu(BonusMenuWCS_VIP_CallBack);
	SetMenuExitBackButton(BonusWCSVIP, true);
	SetMenuExitButton(BonusWCSVIP, true);
}

public int BonusMenuWCS_VIP_CallBack(Menu menu, MenuAction action, int iClient, int iItem)
{    
	switch(action)
	{
		case MenuAction_Select:
		{
            char s_iItem[64];
			GetMenuItem(menu, iItem, s_iItem, sizeof s_iItem);
			int Item = StringToInt(s_iItem);
			if(Referal_GetBonus(iClient) >= g_iPriceVIP[Item])
			{
				Referal_TakeBonus(iClient,g_iPriceVIP[Item]);
				char NickName[32],
					Auth[32];
				GetClientName(iClient,NickName,sizeof NickName);
				GetClientAuthId(iClient, AuthId_Engine, Auth, sizeof Auth, true);
				WCS_GiveVIP(Auth,NickName,g_sVIP[Item],g_iTimeVIP[Item]);
				CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы успешно купили WCS вип-группу %s",g_sVIP[Item]);
			}
			else
				CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Недостаточно бонусов");
		}
		case MenuAction_Cancel: if(iItem == MenuCancel_ExitBack) Referal_OpenControlRefMenu(iClient);
	}
}

public int BonusMenuWCS_Race_CallBack(Menu menu, MenuAction action, int iClient, int iItem)
{    
	switch(action)
	{
		case MenuAction_Select:
		{
            char s_iItem[64];
			GetMenuItem(menu, iItem, s_iItem, sizeof s_iItem);
			int Item = StringToInt(s_iItem);
			if(Referal_GetBonus(iClient) >= g_iPriceRace[Item])
			{
				Referal_TakeBonus(iClient,g_iPriceRace[Item]);
				char Auth[32];
				GetClientAuthId(iClient, AuthId_Engine, Auth, sizeof Auth, true);
				WCS_GivePrivateRace(Auth,g_sRace[Item]);
				CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы успешно купили расу %s",g_sRace[Item]);
			}
			else
				CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Недостаточно бонусов");
		}
		case MenuAction_Cancel: if(iItem == MenuCancel_ExitBack) Referal_OpenControlRefMenu(iClient);
	}
}

public void CVarChanged_WCS_Name(ConVar hCvar, const char[] sOldValue, const char[] sNewValue)
{
	strcopy(NamePoint, sizeof(NamePoint), sNewValue);
}

public void CVarChanged_WCS_Name_lvl(ConVar hCvar, const char[] sOldValue, const char[] sNewValue)
{
	strcopy(NameLVL, sizeof(NameLVL), sNewValue);
}

public void CVarChanged_WCS_Name_vip(ConVar hCvar, const char[] sOldValue, const char[] sNewValue)
{
	strcopy(NameVIP, sizeof(NameVIP), sNewValue);
}

public void CVarChanged_WCS_Name_gold(ConVar hCvar, const char[] sOldValue, const char[] sNewValue)
{
	strcopy(NameGold, sizeof(NameGold), sNewValue);
}

public void CVarChanged_WCS_Name_race(ConVar hCvar, const char[] sOldValue, const char[] sNewValue)
{
	strcopy(NameRace, sizeof(NameRace), sNewValue);
}

public void CVarChanged_Shop_Course_WCS_gold(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CourseGold = cvar.IntValue;
}

public void CVarChanged_Shop_Course_WCS_Bonus_gold(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CourseBonusGold = cvar.IntValue;
}

public void CVarChanged_Shop_Course_WCS_lvl(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CourseLVL = cvar.IntValue;
}

public void CVarChanged_Shop_Course_WCS_Bonus_lvl(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CourseBonusLVL = cvar.IntValue;
}

public Action HookPlayerChat(int iClient, char[] command, int args)
{
    if(g_bUseChatLVL[iClient])
    {
        g_bUseChatLVL[iClient] = false;
		GetCmdArg(1, g_sLVL[iClient], sizeof g_sLVL[]);
        char Title[128];
        Panel hPanel = new Panel();
        FormatEx(Title,sizeof Title,"Referal System\nБаланс: %i б.",Referal_GetBonus(iClient));
		hPanel.SetTitle(Title);
		hPanel.DrawText(" ");
        FormatEx(Title,sizeof Title,"Перевести %i б. → %s ур.",RoundToCeil(CountBonusLVL),g_sLVL[iClient]);
		hPanel.DrawText(Title);
		hPanel.DrawText(" ");
		SetPanelCurrentKey(hPanel,7);
		hPanel.DrawItem("Подтвердить");
		hPanel.DrawText(" ");
		SetPanelCurrentKey(hPanel,9);
		hPanel.DrawItem("Отмена");
		hPanel.Send(iClient, PanelCallbackLVL, 0);
		delete hPanel;
        return Plugin_Handled;
    }
	else if(g_bUseChatGold[iClient])
    {
        g_bUseChatGold[iClient] = false;
		GetCmdArg(1, g_sGold[iClient], sizeof g_sGold[]);
		char Title[128];
        Panel hPanel = new Panel();
        FormatEx(Title,sizeof Title,"Referal System\nБаланс: %i б.",Referal_GetBonus(iClient));
		hPanel.SetTitle(Title);
		hPanel.DrawText(" ");
        FormatEx(Title,sizeof Title,"Перевести %i б. → %s золота",RoundToCeil(CountBonusGold),g_sGold[iClient]);
		hPanel.DrawText(Title);
		hPanel.DrawText(" ");
		SetPanelCurrentKey(hPanel,7);
		hPanel.DrawItem("Подтвердить");
		hPanel.DrawText(" ");
		SetPanelCurrentKey(hPanel,9);
		hPanel.DrawItem("Отмена");
		hPanel.Send(iClient, PanelCallbackGold, 0);
		delete hPanel;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public int PanelCallbackLVL(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action == MenuAction_Select)
	{
		switch(iItem)
		{
			case 7:
			{
				int iBonus = RoundToCeil(CountBonusLVL);
				if(Referal_GetBonus(iClient) >= iBonus)
				{
					Referal_TakeBonus(iClient,iBonus);
					WCS_GiveLBlvl(iClient,StringToInt(g_sLVL[iClient]));
					CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы успешно купили %s ур. за %i б.",g_sLVL[iClient],iBonus);
				}
				else
					CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Недостаточно бонусов");
				
				Referal_OpenControlRefMenu(iClient);
			}
			case 9:
			{
				Referal_OpenControlRefMenu(iClient);
			}
		}
	}
	return 0;
}

public int PanelCallbackGold(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action == MenuAction_Select)
	{
		switch(iItem)
		{
			case 7:
			{
				int iBonus = RoundToCeil(CountBonusGold);
				if(Referal_GetBonus(iClient) >= iBonus)
				{
					Referal_TakeBonus(iClient,iBonus);
					WCS_GiveGold(iClient,StringToInt(g_sGold[iClient]));
					CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы успешно купили %s золота за %i б.",g_sGold[iClient],iBonus);
				}
				else
					CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Недостаточно бонусов");
				
				Referal_OpenControlRefMenu(iClient);
			}
			case 9:
			{
				Referal_OpenControlRefMenu(iClient);
			}
		}
	}
	return 0;
}

public void OnPluginEnd()
{
	delete BonusWCS;
	delete BonusWCSRace;
	delete BonusWCSVIP;
}

public void ReferalCore_OnCoreLoaded()
{
    if((g_iItemID = Referal_RegisterItemInviter(NamePoint, "wcs")) == -1)
    {
        SetFailState("Не удалось создать пункт[%s]",NamePoint);
    }

	if(strcmp(NameRace,""))
		KFG_load_race();

	if(strcmp(NameVIP,""))
		KFG_load_vip();
}

public void ReferalCore_TakeItemInviter(int iClient, int iItemID)
{
    if(g_iItemID == iItemID && iClient > 0)
    {
		char Title[128];
		FormatEx(Title,sizeof Title,"Referal System\nБаланс: %i б.",Referal_GetBonus(iClient));
		SetMenuTitle(BonusWCS, Title);

        if(strcmp(NameGold,""))
			AddMenuItem(BonusWCS,"wcs_gold",NameGold);
        if(strcmp(NameLVL,""))
			AddMenuItem(BonusWCS,"wcs_lvl",NameLVL);
        if(strcmp(NameRace,""))
			AddMenuItem(BonusWCS,"wcs_race",NameRace);
        if(strcmp(NameVIP,""))
			AddMenuItem(BonusWCS,"wcs_vip",NameVIP);
		
		DisplayMenu(BonusWCS,iClient,0);
    }
}

void KFG_load_race()
{
	char szPath[128],SectionName[64];
	KeyValues KV = new KeyValues("WCS_Race");
	BuildPath(Path_SM, szPath, sizeof(szPath), "configs/Referal_System/WCS_Race.ini");

	KV.Rewind();
	if(KV.GotoFirstSubKey(true))
	{
		int g_iItem = 0;
		do 
		{
			if(KV.GetSectionName(SectionName, sizeof(SectionName)))
			{
				KV.GetString("race", g_sRace[g_iItem], sizeof(g_sRace[]));
				g_iPriceRace[g_iItem] = KV.GetNum("price", 1);
				char Item[6];
				IntToString(g_iItem,Item,sizeof Item);
				BonusWCSRace.AddItem(Item,SectionName);
				g_iItem++;
			}
		} while(KV.GotoNextKey(true));
	}
	delete KV;
}

void KFG_load_vip()
{
	char szPath[128],SectionName[64];
	KeyValues KV = new KeyValues("WCS_VIP");
	BuildPath(Path_SM, szPath, sizeof(szPath), "configs/Referal_System/WCS_VIP.ini");

	KV.Rewind();
	if(KV.GotoFirstSubKey(true))
	{
		int g_iItem = 0;
		do 
		{
			if(KV.GetSectionName(SectionName, sizeof(SectionName)))
			{
				KV.GetString("vip_group", g_sVIP[g_iItem], sizeof(g_sVIP[]));
				g_iTimeVIP[g_iItem] = KV.GetNum("time", 1);
				g_iPriceVIP[g_iItem] = KV.GetNum("price", 1);
				char Item[6];
				IntToString(g_iItem,Item,sizeof Item);
				BonusWCSVIP.AddItem(Item,SectionName);
				g_iItem++;
			}
		} while(KV.GotoNextKey(true));
	}
	delete KV;
}

public int BonusMenuWCSCallBack(Menu menu, MenuAction action, int iClient, int iItem)
{    
	switch(action)
	{
		case MenuAction_Select:
		{
            char Item[64];
			GetMenuItem(menu, iItem, Item, sizeof Item);
			if(!strcmp(Item,"wcs_gold"))
			{
				g_bUseChatGold[iClient] = true;
				char Title[128];
				Panel hPanel = new Panel();
				FormatEx(Title,sizeof Title,"Referal System\nТекущий курс золота\n%i кр. → %i б.",CourseGold,CourseBonusGold);
				hPanel.SetTitle(Title);
				hPanel.DrawText(" ");
				hPanel.DrawText("Введите в чат желаемое количество золота");
				hPanel.DrawText(" ");
				SetPanelCurrentKey(hPanel,9);
				hPanel.DrawItem("Отмена");
				hPanel.Send(iClient, PanelCallback, 0);

				delete hPanel;
			}
			else if(!strcmp(Item,"wcs_lvl"))
			{
				g_bUseChatLVL[iClient] = true;
				char Title[128];
				Panel hPanel = new Panel();
				FormatEx(Title,sizeof Title,"Referal System\nТекущий курс уровня\n%i ур. → %i б.",CourseLVL,CourseBonusLVL);
				hPanel.SetTitle(Title);
				hPanel.DrawText(" ");
				hPanel.DrawText("Введите в чат желаемое количество уровней");
				hPanel.DrawText(" ");
				SetPanelCurrentKey(hPanel,9);
				hPanel.DrawItem("Отмена");
				hPanel.Send(iClient, PanelCallback, 0);

				delete hPanel;
			}
			else if(!strcmp(Item,"wcs_vip"))
				DisplayMenu(BonusWCSVIP,iClient,0);
			else if(!strcmp(Item,"wcs_race"))
				DisplayMenu(BonusWCSRace,iClient,0);
		}
		case MenuAction_Cancel: if(iItem == MenuCancel_ExitBack) Referal_OpenControlRefMenu(iClient);
		case MenuAction_End: CloseHandle(menu);
	}
}

public int PanelCallback(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action == MenuAction_Select)
		if(iItem == 9)
		{
			g_bUseChatLVL[iClient] = false;
			g_bUseChatGold[iClient] = false;
		}
	return 0;
}