#pragma semicolon 1
#pragma newdecls required


#include <shop>
#include <referal_system>
#include <csgo_colors>

public Plugin myinfo =
{
	name	= "[RS] Items(SHOP) - Shop",
	version	= "1.0.0",
	author	= "Pisex",
    url = "Discord => Pisex#0023"
};

int g_iItemID,
	g_iCountGive[32],
	g_iPrice[32],
	g_iCountBuy[32];

char NamePoint[32],
	Item[32][32],
	Category[32][32];

public void OnPluginStart()
{       
    ConVar Cvar = CreateConVar("sm_rs_shop_items_name", "SHOP Предметы", "Название пункта в меню магазина бонусов");
	HookConVarChange(Cvar, CVarChanged_Items_Name);
	GetConVarString(Cvar, NamePoint, sizeof(NamePoint));

	AutoExecConfig(true, "Items_Shop","ReferalSystem");
}

public void CVarChanged_Items_Name(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	strcopy(NamePoint, sizeof(NamePoint), newValue);
}

public void ReferalCore_OnCoreLoaded()
{
    if((g_iItemID = Referal_RegisterItemInviter(NamePoint, "shopitems")) == -1)
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
		KeyValues kv = CreateKeyValues("Shop");
		BuildPath(Path_SM, szPath, sizeof szPath, "configs/Referal_System/Items_shop.ini");
		if(!kv.ImportFromFile(szPath))
			SetFailState("[RS] Items - Shop - Файл конфигураций не найден");
		FileToKeyValues(kv, szPath);
		KvRewind(kv);
		int iMKB = -1;
		if (KvJumpToKey(kv, "Items", false) && KvGotoFirstSubKey(kv, true))
		{
			do 
			{
				if(KvGetSectionName(kv, ItemName, sizeof ItemName))
				{
					++iMKB;
					kv.GetString("ItemName",Item[iMKB],sizeof Item[]);
					kv.GetString("Category",Category[iMKB],sizeof Category[]);
					g_iCountGive[iMKB] = kv.GetNum("Count");
					g_iPrice[iMKB] = kv.GetNum("Price");
					g_iCountBuy[iMKB] = kv.GetNum("CountBuy");
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
			CategoryId category = Shop_GetCategoryId(Category[iMKB]);
			ItemId ItemID = Shop_GetItemId(category, Item[iMKB]);
			
			if(Shop_IsClientHasItem(iClient,ItemID) && g_iCountBuy[iMKB])
			{
				CGOPrintToChat(iClient,"{RED}[RS]{GRAY}У вас уже имеется данный предмет");
			}
			else
			{
				if(Referal_GetBonus(iClient) >= g_iPrice[iMKB])
				{
					Referal_TakeBonus(iClient,g_iPrice[iMKB]);
					Shop_GiveClientItem(iClient, ItemID, g_iCountGive[iMKB]);
					char ItemName[32];
					Shop_GetItemNameById(ItemID,ItemName,sizeof ItemName);
					CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы успешно купили предмет %s в шоп",ItemName);
				}
				else
					CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Недостаточно бонусов");
			}
		}
		case MenuAction_Cancel: if(iItem == MenuCancel_ExitBack) Referal_OpenControlRefMenu(iClient);
		case MenuAction_End: CloseHandle(menu);
	}
}