#pragma semicolon 1
#pragma newdecls required

#include <shop>
#include <referal_system>
#include <csgo_colors>

public Plugin myinfo =
{
	name	= "[RS] Credits(SHOP)",
	version	= "1.0.0",
	author	= "Pisex",
    url = "Discord => Pisex#0023"
};

int g_iItemID,
    g_iTypeNotification,
    g_iCreditsGive;

char NamePoint[32];

public void OnPluginStart()
{       
    ConVar Cvar = CreateConVar("sm_rs_notification_credits", "2", "Тип уведомления о получении бонуса\n1 - Только игроку\n2 - Всему серверу", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Bonus_Notification);
	CVarChanged_Bonus_Notification(Cvar, NULL_STRING, NULL_STRING);

    Cvar = CreateConVar("sm_rs_credits_give", "2500", "Количество кредитов выдаваемые игроку если он выбрал этот бонус", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Bonus_Credits);
	CVarChanged_Bonus_Credits(Cvar, NULL_STRING, NULL_STRING);

    Cvar = CreateConVar("sm_rs_credits_name", "SHOP Кредиты", "Название пункта в меню выбора бонуса");
	HookConVarChange(Cvar, CVarChanged_Credits_Name);
	GetConVarString(Cvar, NamePoint, sizeof(NamePoint));

	AutoExecConfig(true, "Credits","ReferalSystem");
}

public void CVarChanged_Credits_Name(ConVar hCvar, const char[] sOldValue, const char[] sNewValue)
{
	strcopy(NamePoint, sizeof(NamePoint), sNewValue);
}

public void CVarChanged_Bonus_Notification(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_iTypeNotification = cvar.IntValue;
}

public void CVarChanged_Bonus_Credits(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    g_iCreditsGive = cvar.IntValue;
}

public void ReferalCore_OnCoreLoaded()
{
    if((g_iItemID = Referal_RegisterItemInvited(NamePoint, "credits")) == -1)
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
            case 1: CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы получили %i кр. за реферальный код",g_iCreditsGive);
            case 2: CGOPrintToChatAll("{RED}[RS]{GRAY}Игрок %N получил бонус за реферальный код в виде %i кр.",iClient,g_iCreditsGive);
        }
        Shop_GiveClientCredits(iClient, g_iCreditsGive);
    }
}