#pragma semicolon 1
#pragma newdecls required

#include <FirePlayersStats>
#include <referal_system>
#include <csgo_colors>

public Plugin myinfo =
{
	name	= "[RS] FPS - Shop",
	version	= "1.0.0",
	author	= "Pisex",
    url = "Discord => Pisex#0023"
};

bool g_bUseChat[MAXPLAYERS+1];
char g_sFPS[MAXPLAYERS+1][12],
	NamePoint[32];

#define CountBonus (CourseBonus * StringToFloat(g_sFPS[iClient])/CourseFPS)

int g_iItemID,
	CourseBonus;

float CourseFPS;

public void OnPluginStart()
{
	AddCommandListener(HookPlayerChat, "say");
	AddCommandListener(HookPlayerChat, "say_team");


	ConVar Cvar = CreateConVar("sm_rs_shop_course_fps", "500", "Количество кредитов на sm_rs_shop_course_fps_bonus(500 опыта за 5б. на данный момент)", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Shop_Course_fps);
	CVarChanged_Shop_Course_fps(Cvar, NULL_STRING, NULL_STRING);

	Cvar = CreateConVar("sm_rs_shop_course_fps_bonus", "5", "Стоимость за sm_rs_shop_course_fps", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Shop_Course_fps_Bonus);
	CVarChanged_Shop_Course_fps_Bonus(Cvar, NULL_STRING, NULL_STRING);
	
	Cvar = CreateConVar("sm_rs_shop_fps_name", "FPS Опыт", "Название пункта в меню магазина бонусов");
	HookConVarChange(Cvar, CVarChanged_fps_Name);
	GetConVarString(Cvar, NamePoint, sizeof(NamePoint));

	AutoExecConfig(true, "FPS_Shop","ReferalSystem");
}

public void CVarChanged_fps_Name(ConVar hCvar, const char[] sOldValue, const char[] sNewValue)
{
	strcopy(NamePoint, sizeof(NamePoint), sNewValue);
}

public void CVarChanged_Shop_Course_fps(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CourseFPS = cvar.FloatValue;
}

public void CVarChanged_Shop_Course_fps_Bonus(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CourseBonus = cvar.IntValue;
}

public Action HookPlayerChat(int iClient, char[] command, int args)
{
    if(g_bUseChat[iClient])
    {
        g_bUseChat[iClient] = false;
		GetCmdArg(1, g_sFPS[iClient], sizeof g_sFPS[]);
        char Title[128];
        Panel hPanel = new Panel();
        FormatEx(Title,sizeof Title,"Referal System\nБаланс: %i б.",Referal_GetBonus(iClient));
		hPanel.SetTitle(Title);
		hPanel.DrawText(" ");
        FormatEx(Title,sizeof Title,"Перевести %i б. → %s опыта.",RoundToCeil(CountBonus),g_sFPS[iClient]);
		hPanel.DrawText(Title);
		hPanel.DrawText(" ");
		SetPanelCurrentKey(hPanel,7);
		hPanel.DrawItem("Подтвердить");
		hPanel.DrawText(" ");
		SetPanelCurrentKey(hPanel,9);
		hPanel.DrawItem("Отмена");
		hPanel.Send(iClient, PanelCallback2, 0);

		delete hPanel;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public int PanelCallback2(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			switch(iItem)
			{
                case 7:
				{
                    int iBonus = RoundToCeil(CountBonus);
                    if(Referal_GetBonus(iClient) >= iBonus)
                    {
                        Referal_TakeBonus(iClient,iBonus);
                        FPS_SetPoints(iClient,StringToFloat(g_sFPS[iClient]));
                        CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы успешно купили %s опыта. за %i б.",g_sFPS[iClient],iBonus);
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
	}
	return 0;
}

public int PanelCallback(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			switch(iItem)
			{
				case 9:
				{
					g_bUseChat[iClient] = false;
				}
			}
		}
	}
	return 0;
}

public void ReferalCore_OnCoreLoaded()
{
    if((g_iItemID = Referal_RegisterItemInviter(NamePoint, "shopfps")) == -1)
    {
        SetFailState("Не удалось создать пункт[%s]",NamePoint);
    }
}

public void ReferalCore_TakeItemInviter(int iClient, int iItemID)
{
    if(g_iItemID == iItemID && iClient > 0)
    {
        g_bUseChat[iClient] = true;
        char Title[128];
        Panel hPanel = new Panel();
        FormatEx(Title,sizeof Title,"Referal System\nТекущий курс кредитов\n%i кр. → %i б.",CourseFPS,CourseBonus);
		hPanel.SetTitle(Title);
		hPanel.DrawText(" ");
		hPanel.DrawText("Введите в чат желаемое количество кредитов");
		hPanel.DrawText(" ");
		SetPanelCurrentKey(hPanel,9);
		hPanel.DrawItem("Отмена");
		hPanel.Send(iClient, PanelCallback, 0);

		delete hPanel;
    }
}