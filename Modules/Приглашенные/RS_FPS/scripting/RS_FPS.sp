#pragma semicolon 1
#pragma newdecls required

#include <FirePlayersStats>
#include <referal_system>
#include <csgo_colors>

public Plugin myinfo =
{
	name	= "[RS] FPS",
	version	= "1.0.0",
	author	= "Pisex",
    url = "Discord => Pisex#0023"
};

int g_iItemID,
    g_iTypeNotification;
    
float g_fFPSGive;

char NamePoint[32];

public void OnPluginStart()
{       
    ConVar Cvar = CreateConVar("sm_rs_notification_FPS", "2", "Тип уведомления о получении бонуса\n1 - Только игроку\n2 - Всему серверу", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Bonus_Notification);
	CVarChanged_Bonus_Notification(Cvar, NULL_STRING, NULL_STRING);

    Cvar = CreateConVar("sm_rs_FPS_give", "2500.0", "Количество опыта выдаваемые игроку если он выбрал этот бонус", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Bonus_FPS);
	CVarChanged_Bonus_FPS(Cvar, NULL_STRING, NULL_STRING);

    Cvar = CreateConVar("sm_rs_FPS_name", "FPS Опыт", "Название пункта в меню выбора бонуса");
	HookConVarChange(Cvar, CVarChanged_FPS_Name);
	GetConVarString(Cvar, NamePoint, sizeof(NamePoint));

	AutoExecConfig(true, "FPS","ReferalSystem");
}

public void CVarChanged_FPS_Name(ConVar hCvar, const char[] sOldValue, const char[] sNewValue)
{
	strcopy(NamePoint, sizeof(NamePoint), sNewValue);
}

public void CVarChanged_Bonus_Notification(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_iTypeNotification = cvar.IntValue;
}

public void CVarChanged_Bonus_FPS(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    g_fFPSGive = cvar.FloatValue;
}

public void ReferalCore_OnCoreLoaded()
{
    if((g_iItemID = Referal_RegisterItemInvited(NamePoint, "FPS")) == -1)
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
            case 1: CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы получили %i опыта за реферальный код",g_fFPSGive);
            case 2: CGOPrintToChatAll("{RED}[RS]{GRAY}Игрок %N получил бонус за реферальный код в виде %i опыта",iClient,g_fFPSGive);
        }
        FPS_SetPoints(iClient, g_fFPSGive);
    }
}