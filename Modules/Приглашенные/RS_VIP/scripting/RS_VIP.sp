#pragma semicolon 1
#pragma newdecls required

#include <vip_core>
#include <referal_system>
#include <csgo_colors>

public Plugin myinfo =
{
	name	= "[RS] VIP",
	version	= "1.0.0",
	author	= "Pisex",
    url = "Discord => Pisex#0023"
};

int g_iItemID,
    g_iTypeNotification,
    g_iGiveTimeUpdate,
    g_iGiveTime;

char NamePoint[32],
    VIP_Group[32];

public void OnPluginStart()
{       
    ConVar Cvar = CreateConVar("sm_rs_notification_vip", "2", "Тип уведомления о получении бонуса\n1 - Только игроку\n2 - Всему серверу", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Bonus_Notification);
	CVarChanged_Bonus_Notification(Cvar, NULL_STRING, NULL_STRING);

    Cvar = CreateConVar("sm_rs_vip_groupname_give", "star", "Название Вип статуса", _, true, 1.0);
	HookConVarChange(Cvar, CVarChanged_VIP_Group_Name);
	GetConVarString(Cvar, VIP_Group, sizeof(VIP_Group));

    Cvar = CreateConVar("sm_rs_vip_time_give", "3600", "Время вип статуса", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Bonus_TimeGiveCount);
	CVarChanged_Bonus_TimeGiveCount(Cvar, NULL_STRING, NULL_STRING);

    Cvar = CreateConVar("sm_rs_vip_time_update_give", "3600", "Время продления вип статуса если у игрока уже есть вип группа указанная в sm_rs_vip_groupname_give", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Bonus_TimeUpdateGiveCount);
	CVarChanged_Bonus_TimeUpdateGiveCount(Cvar, NULL_STRING, NULL_STRING);

    Cvar = CreateConVar("sm_rs_vip_name", "VIP Статус", "Название пункта в меню выбора бонуса");
	HookConVarChange(Cvar, CVarChanged_VIP_Name);
	GetConVarString(Cvar, NamePoint, sizeof(NamePoint));

	AutoExecConfig(true, "VIP","ReferalSystem");
}

public void CVarChanged_VIP_Name(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	strcopy(NamePoint, sizeof(NamePoint), newValue);
}

public void CVarChanged_VIP_Group_Name(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	strcopy(VIP_Group, sizeof(VIP_Group), newValue);
}

public void CVarChanged_Bonus_Notification(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_iTypeNotification = cvar.IntValue;
}

public void CVarChanged_Bonus_TimeGiveCount(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_iGiveTime = cvar.IntValue;
}

public void CVarChanged_Bonus_TimeUpdateGiveCount(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_iGiveTimeUpdate = cvar.IntValue;
}

public void ReferalCore_OnCoreLoaded()
{
    if((g_iItemID = Referal_RegisterItemInvited(NamePoint, "vip")) == -1)
    {
        SetFailState("Не удалось создать пункт[%s]",NamePoint);
    }
}

public void ReferalCore_TakeItemInvited(int iClient, int iItemID)
{
    if(g_iItemID == iItemID && iClient > 0)
    {
        char vipg[32];
        if(VIP_IsClientVIP(iClient))
            VIP_GetClientVIPGroup(iClient,vipg,sizeof vipg);

        if(!strcmp(vipg,VIP_Group) && VIP_GetClientAccessTime(iClient) > 0)
        {
            VIP_SetClientAccessTime(iClient, g_iGiveTimeUpdate + VIP_GetClientAccessTime(iClient));
            switch(g_iTypeNotification)
            {
                case 1: CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы получили продление вип статус %i с. за реферальный код",g_iGiveTimeUpdate);
                case 2: CGOPrintToChatAll("{RED}[RS]{GRAY}Игрок %N получил бонус за реферальный код в виде продления вип статуса на %i с.",iClient,g_iGiveTimeUpdate);
            }
        }
        else
        {
            VIP_GiveClientVIP(1,iClient,g_iGiveTime,VIP_Group);
            switch(g_iTypeNotification)
            {
                case 1: CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы получили Вип статус %s на %i с. за реферальный код",VIP_Group,g_iGiveTime);
                case 2: CGOPrintToChatAll("{RED}[RS]{GRAY}Игрок %N получил бонус за реферальный код в виде Вип статуса %s на %i с.",iClient,VIP_Group,g_iGiveTime);
            }
        }
    }
}