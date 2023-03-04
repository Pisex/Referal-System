#pragma semicolon 1
#pragma newdecls required

#include <shop>
#include <referal_system>
#include <csgo_colors>

public Plugin myinfo =
{
	name	= "[RS] Credits(SHOP) - Shop",
	version	= "1.0.0",
	author	= "Pisex",
    url = "Discord => Pisex#0023"
};

bool g_bUseChat[MAXPLAYERS+1];
char g_sCredits[MAXPLAYERS+1][12],
	NamePoint[32];

#define CountBonus (CourseBonus * StringToFloat(g_sCredits[iClient])/CourseCredits)

int g_iItemID,
	CourseBonus,
    CourseCredits;

public void OnPluginStart()
{
	AddCommandListener(HookPlayerChat, "say");
	AddCommandListener(HookPlayerChat, "say_team");

	ConVar Cvar = CreateConVar("sm_rs_shop_course_credits", "500", "Количество кредитов на sm_rs_shop_course_credits_bonus(500 кредитов за 5б. на данный момент)", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Shop_Course_Credits);
	CVarChanged_Shop_Course_Credits(Cvar, NULL_STRING, NULL_STRING);

	Cvar = CreateConVar("sm_rs_shop_course_credits_bonus", "5", "Стоимость за sm_rs_shop_course_credits", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Shop_Course_Credits_Bonus);
	CVarChanged_Shop_Course_Credits_Bonus(Cvar, NULL_STRING, NULL_STRING);
	
	Cvar = CreateConVar("sm_rs_shop_credits_name", "SHOP Кредиты", "Название пункта в меню магазина бонусов");
	HookConVarChange(Cvar, CVarChanged_Credits_Name);
	GetConVarString(Cvar, NamePoint, sizeof(NamePoint));

	AutoExecConfig(true, "Credits_Shop","ReferalSystem");
}

public void CVarChanged_Credits_Name(ConVar hCvar, const char[] sOldValue, const char[] sNewValue)
{
	strcopy(NamePoint, sizeof(NamePoint), sNewValue);
}

public void CVarChanged_Shop_Course_Credits(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CourseCredits = cvar.IntValue;
}

public void CVarChanged_Shop_Course_Credits_Bonus(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CourseBonus = cvar.IntValue;
}

public Action HookPlayerChat(int iClient, char[] command, int args)
{
    if(g_bUseChat[iClient])
    {
        g_bUseChat[iClient] = false;
		GetCmdArg(1, g_sCredits[iClient], sizeof g_sCredits[]);
        char Title[128];
        Panel hPanel = new Panel();
        FormatEx(Title,sizeof Title,"Referal System\nБаланс: %i б.",Referal_GetBonus(iClient));
		hPanel.SetTitle(Title);
		hPanel.DrawText(" ");
        FormatEx(Title,sizeof Title,"Перевести %i б. → %s кр.",RoundToCeil(CountBonus),g_sCredits[iClient]);
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
                        Shop_GiveClientCredits(iClient,StringToInt(g_sCredits[iClient]));
                        CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы успешно купили %s кр. за %i б.",g_sCredits[iClient],iBonus);
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
    if((g_iItemID = Referal_RegisterItemInviter(NamePoint, "shopcredits")) == -1)
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
        FormatEx(Title,sizeof Title,"Referal System\nТекущий курс кредитов\n%i кр. → %i б.",CourseCredits,CourseBonus);
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