#pragma semicolon 1
#pragma newdecls required

#include <lk>
#include <referal_system>
#include <csgo_colors>

public Plugin myinfo =
{
	name	= "[RS] LK - Shop",
	version	= "1.0.0",
	author	= "Pisex",
    url = "Discord => Pisex#0023"
};

bool g_bUseChat[MAXPLAYERS+1];
char g_sLK[MAXPLAYERS+1][12],
	NamePoint[32];

#define CountBonus (CourseBonus * StringToFloat(g_sLK[iClient])/CourseLK)

int g_iItemID,
	CourseBonus,
    CourseLK;

public void OnPluginStart()
{
	AddCommandListener(HookPlayerChat, "say");
	AddCommandListener(HookPlayerChat, "say_team");

	ConVar Cvar = CreateConVar("sm_rs_shop_course_lk", "500", "Количество рублей на sm_rs_shop_course_lk_bonus(500 рублей за 5б. на данный момент)", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Shop_Course_LK);
	CVarChanged_Shop_Course_LK(Cvar, NULL_STRING, NULL_STRING);

	Cvar = CreateConVar("sm_rs_shop_course_lk_bonus", "5", "Стоимость за sm_rs_shop_course_lk", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Shop_Course_LK_Bonus);
	CVarChanged_Shop_Course_LK_Bonus(Cvar, NULL_STRING, NULL_STRING);
	
	Cvar = CreateConVar("sm_rs_shop_lk_name", "LK рубли", "Название пункта в меню магазина бонусов");
	HookConVarChange(Cvar, CVarChanged_LK_Name);
	GetConVarString(Cvar, NamePoint, sizeof(NamePoint));

	AutoExecConfig(true, "LK_Shop","ReferalSystem");
}

public void CVarChanged_LK_Name(ConVar hCvar, const char[] sOldValue, const char[] sNewValue)
{
	strcopy(NamePoint, sizeof(NamePoint), sNewValue);
}

public void CVarChanged_Shop_Course_LK(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CourseLK = cvar.IntValue;
}

public void CVarChanged_Shop_Course_LK_Bonus(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CourseBonus = cvar.IntValue;
}

public Action HookPlayerChat(int iClient, char[] command, int args)
{
    if(g_bUseChat[iClient])
    {
        g_bUseChat[iClient] = false;
		GetCmdArg(1, g_sLK[iClient], sizeof g_sLK[]);
        char Title[128];
        Panel hPanel = new Panel();
        FormatEx(Title,sizeof Title,"Referal System\nБаланс: %i б.",Referal_GetBonus(iClient));
		hPanel.SetTitle(Title);
		hPanel.DrawText(" ");
        FormatEx(Title,sizeof Title,"Перевести %i б. → %s руб.",RoundToCeil(CountBonus),g_sLK[iClient]);
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
						LK_AddClientCash(iClient,StringToInt(g_sLK[iClient]));
                        CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы успешно купили %s руб. за %i б.",g_sLK[iClient],iBonus);
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
    if((g_iItemID = Referal_RegisterItemInviter(NamePoint, "shoplk")) == -1)
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
        FormatEx(Title,sizeof Title,"Referal System\nТекущий курс руб.\n%i кр. → %i б.",CourseLK,CourseBonus);
		hPanel.SetTitle(Title);
		hPanel.DrawText(" ");
		hPanel.DrawText("Введите в чат желаемое количество руб.");
		hPanel.DrawText(" ");
		SetPanelCurrentKey(hPanel,9);
		hPanel.DrawItem("Отмена");
		hPanel.Send(iClient, PanelCallback, 0);

		delete hPanel;
    }
}