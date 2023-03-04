#pragma semicolon 1
#pragma newdecls required

#include <lk>
#include <referal_system>
#include <csgo_colors>

public Plugin myinfo =
{
	name	= "[RS] LK",
	version	= "1.0.0",
	author	= "Pisex",
    url = "Discord => Pisex#0023"
};

int g_iItemID,
    g_iTypeNotification,
    g_iLKGive;

char NamePoint[32];

public void OnPluginStart()
{       
    ConVar Cvar = CreateConVar("sm_rs_notification_lk", "2", "Тип уведомления о получении бонуса\n1 - Только игроку\n2 - Всему серверу", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Bonus_Notification);
	CVarChanged_Bonus_Notification(Cvar, NULL_STRING, NULL_STRING);

    Cvar = CreateConVar("sm_rs_lk_give", "25", "Количество рублей выдаваемые игроку если он выбрал этот бонус", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Bonus_LK);
	CVarChanged_Bonus_LK(Cvar, NULL_STRING, NULL_STRING);

    Cvar = CreateConVar("sm_rs_lk_name", "LK Баланс", "Название пункта в меню выбора бонуса");
	HookConVarChange(Cvar, CVarChanged_LK_Name);
	GetConVarString(Cvar, NamePoint, sizeof(NamePoint));

	AutoExecConfig(true, "LK","ReferalSystem");
}

public void CVarChanged_LK_Name(ConVar hCvar, const char[] sOldValue, const char[] sNewValue)
{
	strcopy(NamePoint, sizeof(NamePoint), sNewValue);
}

public void CVarChanged_Bonus_Notification(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_iTypeNotification = cvar.IntValue;
}

public void CVarChanged_Bonus_LK(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    g_iLKGive = cvar.IntValue;
}

public void ReferalCore_OnCoreLoaded()
{
    if((g_iItemID = Referal_RegisterItemInvited(NamePoint, "lk")) == -1)
    {
        SetFailState("Не удалось создать пункт[%s]",NamePoint);
    }
}

public void ReferalCore_TakeItemInvited(int iClient, int iItemID)
{
    if(g_iItemID == iItemID && iClient > 0)
    {
        switch(g_iTypeNotification)
        {
            case 1: CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы получили %i руб. за реферальный код",g_iLKGive);
            case 2: CGOPrintToChatAll("{RED}[RS]{GRAY}Игрок %N получил бонус за реферальный код в виде %i руб.",iClient,g_iLKGive);
        }
        LK_AddClientCash(iClient,g_iLKGive);
    }
}