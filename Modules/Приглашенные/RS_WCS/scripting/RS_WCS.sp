#pragma semicolon 1
#pragma newdecls required

#include <wcs>
#include <referal_system>
#include <csgo_colors>

public Plugin myinfo =
{
	name	= "[RS] WCS",
	version	= "1.0.0",
	author	= "Pisex",
    url = "Discord => Pisex#0023"
};

int g_iItemID,
    g_iTypeNotification,
    g_iWCSGiveGold,
    g_iWCSGiveLVL,
    g_iTypeWCSGive,
    g_iTimeVIP;

char g_sNamePoint[32],
    g_sNameRace[64],
    g_sNameVIP[64];

public void OnPluginStart()
{       
    ConVar Cvar = CreateConVar("sm_rs_notification_wcs", "2", "Тип уведомления о получении бонуса\n1 - Только игроку\n2 - Всему серверу", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Bonus_Notification);
	CVarChanged_Bonus_Notification(Cvar, NULL_STRING, NULL_STRING);

    Cvar = CreateConVar("sm_rs_wcs_give_type", "4", "Типо выдачи\n1-Уровень WCS\n2-Золото WCS\n3-Приватная раса\n4-Вип доступ\n5-На выбор игроку", _, true, 1.0,true,4.0);
	Cvar.AddChangeHook(CVarChanged_Bonus_wcs_type);
	CVarChanged_Bonus_wcs_type(Cvar, NULL_STRING, NULL_STRING);

    Cvar = CreateConVar("sm_rs_wcs_give_lvl", "2", "Уровень выдаваемый клиенту при sm_rs_wcs_give_type 1 и 5[0 - Исключить из 5]", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Bonus_wcs_lvl);
	CVarChanged_Bonus_wcs_lvl(Cvar, NULL_STRING, NULL_STRING);

    Cvar = CreateConVar("sm_rs_wcs_give_gold", "5", "Золото выдаваемое клиенту при sm_rs_wcs_give_type 2 и 5[0 - Исключить из 5]", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Bonus_wcs_gold);
	CVarChanged_Bonus_wcs_gold(Cvar, NULL_STRING, NULL_STRING);

    Cvar = CreateConVar("sm_rs_wcs_name_private", "Nigga", "Название приватной расы при sm_rs_wcs_give_type 3 и 5[Оставить пустым - Исключить из 5]");
	HookConVarChange(Cvar, CVarChanged_wcs_Name_race);
	GetConVarString(Cvar, g_sNameRace, sizeof(g_sNameRace));

    Cvar = CreateConVar("sm_rs_wcs_name", "WCS Золото/Уровень/Раса/Вип", "Название пункта в меню выбора бонуса");
	HookConVarChange(Cvar, CVarChanged_wcs_Name);
	GetConVarString(Cvar, g_sNamePoint, sizeof(g_sNamePoint));

    Cvar = CreateConVar("sm_rs_wcs_vip_name", "", "Имя WCS Вип группы для 4 и 5[Оставить пустым - Исключить из 5]");
	HookConVarChange(Cvar, CVarChanged_wcs_Name_vip);
	GetConVarString(Cvar, g_sNameVIP, sizeof(g_sNameVIP));

    Cvar = CreateConVar("sm_rs_wcs_vip_time", "60", "Время выдачаемой вип группы sm_rs_wcs_give_type 4 и 5[0 - Исключить из 5]", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Bonus_wcs_time_vip);
	CVarChanged_Bonus_wcs_time_vip(Cvar, NULL_STRING, NULL_STRING);

	AutoExecConfig(true, "WCS","ReferalSystem");
}

public void CVarChanged_wcs_Name(ConVar hCvar, const char[] sOldValue, const char[] sNewValue)
{
	strcopy(g_sNamePoint, sizeof(g_sNamePoint), sNewValue);
}

public void CVarChanged_wcs_Name_vip(ConVar hCvar, const char[] sOldValue, const char[] sNewValue)
{
	strcopy(g_sNameVIP, sizeof(g_sNameVIP), sNewValue);
}

public void CVarChanged_wcs_Name_race(ConVar hCvar, const char[] sOldValue, const char[] sNewValue)
{
	strcopy(g_sNameRace, sizeof(g_sNameRace), sNewValue);
}

public void CVarChanged_Bonus_Notification(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_iTypeNotification = cvar.IntValue;
}

public void CVarChanged_Bonus_wcs_type(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    g_iTypeWCSGive = cvar.IntValue;
}

public void CVarChanged_Bonus_wcs_lvl(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    g_iWCSGiveLVL = cvar.IntValue;
}

public void CVarChanged_Bonus_wcs_gold(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    g_iWCSGiveGold = cvar.IntValue;
}

public void CVarChanged_Bonus_wcs_time_vip(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    g_iTimeVIP = cvar.IntValue;
}

public void ReferalCore_OnCoreLoaded()
{
    if((g_iItemID = Referal_RegisterItemInvited(g_sNamePoint, "wcs")) == -1)
    {
        SetFailState("Не удалось создать пункт[%s]",g_sNamePoint);
    }
}

public void ReferalCore_TakeItemInvited(int iClient, int iItemID)
{
    if(g_iItemID == iItemID && iClient > 0)
    {
        switch(g_iTypeWCSGive)
        {
            case 1:
            {   
                GiveGold(iClient);
            }
            case 2:
            {
                GiveLVL(iClient);
            }
            case 3:
            {
                GiveRace(iClient);
            }
            case 5:
            {
                Menu WCS_Menu = new Menu(WCS_MenuCallBack); //Меню Приглашенный
                SetMenuTitle(WCS_Menu, "Выберите WCS бонус");
                char Text[64];
                if(g_iWCSGiveLVL)
                {
                    FormatEx(Text,sizeof Text,"WCS Уровень[+%i]",g_iWCSGiveLVL);
                    WCS_Menu.AddItem("lvl",Text);
                }
                if(g_iWCSGiveGold)
                {
                    FormatEx(Text,sizeof Text,"WCS Золото[+%i]",g_iWCSGiveGold);
                    WCS_Menu.AddItem("gold",Text);
                }
                if(strcmp(g_sNameRace,"")) 
                {
                    FormatEx(Text,sizeof Text,"WCS Раса[%s]",g_sNameRace);
                    WCS_Menu.AddItem("race",Text);
                }
                if(strcmp(g_sNameVIP,"")) 
                {
                    FormatEx(Text,sizeof Text,"WCS VIP Группа");
                    WCS_Menu.AddItem("vip",Text);
                }
                SetMenuExitBackButton(WCS_Menu, true);
                SetMenuExitButton(WCS_Menu, true);
            }
        }
    }
}

public int WCS_MenuCallBack(Menu menu, MenuAction action, int iClient, int itemSelect) // выдача бонуса
{
    if (action == MenuAction_Select)
    {
        char Item[16];
        GetMenuItem(menu, itemSelect, Item, sizeof Item);
        if(!strcmp(Item,"lvl")) GiveLVL(iClient); 
        if(!strcmp(Item,"gold")) GiveGold(iClient);
        if(!strcmp(Item,"race")) GiveRace(iClient);
    }
    else if (action == MenuAction_Cancel)if (itemSelect == MenuCancel_ExitBack) Referal_OpenBonusMenu(iClient);
    else if (action == MenuAction_End) CloseHandle(menu);
}

public Action GiveRace(int iClient)
{
    switch(g_iTypeNotification)
    {
        case 1: CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы получили приватную расу %s за реферальный код",g_sNameRace);
        case 2: CGOPrintToChatAll("{RED}[RS]{GRAY}Игрок %N получил бонус за реферальный код в виде приватной расы %s",iClient,g_sNameRace);
    }
    char Auth[32];
    GetClientAuthId(iClient, AuthId_Engine, Auth, sizeof Auth, true); // Получаем SteamID игрока
    WCS_GivePrivateRace(Auth, g_sNameRace);
}

public Action GiveLVL(int iClient)
{
    switch(g_iTypeNotification)
    {
        case 1: CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы получили %i ур. WCS за реферальный код",g_iWCSGiveLVL);
        case 2: CGOPrintToChatAll("{RED}[RS]{GRAY}Игрок %N получил бонус за реферальный код в виде %i ур. WCS",iClient,g_iWCSGiveLVL);
    }
    WCS_GiveLBlvl(iClient,g_iWCSGiveLVL);
}

public Action GiveGold(int iClient)
{
    switch(g_iTypeNotification)
    {
        case 1: CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы получили %i золота WCS за реферальный код",g_iWCSGiveGold);
        case 2: CGOPrintToChatAll("{RED}[RS]{GRAY}Игрок %N получил бонус за реферальный код в виде %i золота WCS",iClient,g_iWCSGiveGold);
    }
    WCS_GiveGold(iClient,g_iWCSGiveGold);
}

public Action GiveVIP(int iClient)
{
    switch(g_iTypeNotification)
    {
        case 1: CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы получили WCS VIP Группу за реферальный код");
        case 2: CGOPrintToChatAll("{RED}[RS]{GRAY}Игрок %N получил бонус за реферальный код в виде WCS VIP Группы",iClient);
    }
    char NickName[32],
        Auth[32];
    GetClientName(iClient,NickName,sizeof NickName);
    GetClientAuthId(iClient, AuthId_Engine, Auth, sizeof Auth, true);
    WCS_GiveVIP(Auth,NickName,g_sNameVIP,g_iTimeVIP);
}