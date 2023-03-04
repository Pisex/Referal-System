#pragma semicolon 1
#pragma newdecls required


#include <vip_core>
#include <referal_system>
#include <csgo_colors>

public Plugin myinfo =
{
	name	= "[RS] VIP - Shop",
	version	= "1.0.0",
	author	= "Pisex",
    url = "Discord => Pisex#0023"
};

int g_iItemID,
	g_iPrice[32],
	g_iTimeVIP[32],
	g_iTimeUp[32];

char NamePoint[32],
	g_sVIP_G[32][32];

public void OnPluginStart()
{       
    ConVar Cvar = CreateConVar("sm_rs_vip_groups_name", "Вип статусы", "Название пункта в меню магазина бонусов");
	HookConVarChange(Cvar, CVarChanged_VIPS_Name);
	GetConVarString(Cvar, NamePoint, sizeof(NamePoint));

	AutoExecConfig(true, "VIPS","ReferalSystem");
}

public void CVarChanged_VIPS_Name(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	strcopy(NamePoint, sizeof(NamePoint), newValue);
}

public void ReferalCore_OnCoreLoaded()
{
    if((g_iItemID = Referal_RegisterItemInviter(NamePoint, "shopvip")) == -1)
    {
        SetFailState("Не удалось создать пункт[%s]",NamePoint);
    }
}

public void ReferalCore_TakeItemInviter(int iClient, int iItemID)
{
    if(g_iItemID == iItemID && iClient > 0)
    {
		Menu hMenu = new Menu(MenuHandler);
    	hMenu.SetTitle("Выберите желаемый предмет");
        char szPath[PLATFORM_MAX_PATH],ItemName[64];
		KeyValues kv = CreateKeyValues("VIPS");
		BuildPath(Path_SM, szPath, sizeof szPath, "configs/Referal_System/VIPS.ini");
		if(!kv.ImportFromFile(szPath))
			SetFailState("[RS] VIP - Shop - Файл конфигураций не найден");
		FileToKeyValues(kv, szPath);
		KvRewind(kv);
		int iMKB = -1;
		if (KvJumpToKey(kv, "VIP", false) && KvGotoFirstSubKey(kv, true))
		{
			do 
			{
				if(KvGetSectionName(kv, ItemName, sizeof ItemName))
				{
					++iMKB;
					kv.GetString("vip_group",g_sVIP_G[iMKB],sizeof g_sVIP_G[]);
					g_iTimeVIP[iMKB] = kv.GetNum("vip_time");
					g_iPrice[iMKB] = kv.GetNum("price");
					g_iTimeUp[iMKB] = kv.GetNum("extend");
					char s_iMKB[12];
					IntToString(iMKB,s_iMKB,sizeof s_iMKB);
					hMenu.AddItem(s_iMKB,ItemName);
				}
			} while (KvGotoNextKey(kv, true));
		}
		hMenu.ExitBackButton = true;
		DisplayMenu(hMenu,iClient,0);
    }
}

public int MenuHandler(Menu menu, MenuAction action, int iClient, int iItem)
{    
	switch(action)
	{
		case MenuAction_Select:
		{
            char s_iMKB[64];
			GetMenuItem(menu, iItem, s_iMKB, sizeof s_iMKB);
			int iMKB = StringToInt(s_iMKB);

			if(Referal_GetBonus(iClient) >= g_iPrice[iMKB])
			{
				Referal_TakeBonus(iClient,g_iPrice[iMKB]);
				char vipg[32];
				if(VIP_IsClientVIP(iClient))
					VIP_GetClientVIPGroup(iClient,vipg,sizeof vipg);

				if(!strcmp(vipg,g_sVIP_G[iMKB]) && VIP_GetClientAccessTime(iClient) > 0)
				{
            		VIP_SetClientAccessTime(iClient, g_iTimeUp[iMKB] + VIP_GetClientAccessTime(iClient));
					CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы получили продление вип статус %i с. за реферальный код",g_iTimeUp[iMKB]);
				}
				else
				{
					VIP_GiveClientVIP(1,iClient,g_iTimeVIP[iMKB],g_sVIP_G[iMKB]);
					CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы успешно купили Вип Статус %s на %i",g_sVIP_G[iMKB],g_iTimeVIP[iMKB]);
				}
			}
			else
				CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Недостаточно бонусов");
		}
		case MenuAction_Cancel: if(iItem == MenuCancel_ExitBack) Referal_OpenControlRefMenu(iClient);
		case MenuAction_End: CloseHandle(menu);
	}
}