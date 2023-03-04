#pragma semicolon 1
#pragma newdecls required


#include <shop>
#include <referal_system>
#include <csgo_colors>

public Plugin myinfo =
{
	name	= "[RS] Item(SHOP)",
	version	= "1.0.0",
	author	= "Pisex",
    url = "Discord => Pisex#0023"
};

int g_iItemID,
    g_iTypeNotification,
    g_iGiveCount;

char NamePoint[32],
    ItemCategory[32],
    ItemNameCategory[32];

public void OnPluginStart()
{       
    ConVar Cvar = CreateConVar("sm_rs_notification_item", "2", "Тип уведомления о получении бонуса\n1 - Только игроку\n2 - Всему серверу", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Bonus_Notification);
	CVarChanged_Bonus_Notification(Cvar, NULL_STRING, NULL_STRING);

    Cvar = CreateConVar("sm_rs_itemname_give", "Toki", "Уникальное имя предмета из выбранной вами категории", _, true, 1.0);
	HookConVarChange(Cvar, CVarChanged_Bonus_ItemNameCategory);
	GetConVarString(Cvar, ItemNameCategory, sizeof(ItemNameCategory));

    Cvar = CreateConVar("sm_rs_itemcategory_give", "skins", "Имя категории где находится предмет для выдачи", _, true, 1.0);
	HookConVarChange(Cvar, CVarChanged_Bonus_ItemCategory);
	GetConVarString(Cvar, ItemCategory, sizeof(ItemCategory));

    Cvar = CreateConVar("sm_rs_itemcount_give", "1", "Количество выдаваемого предмета", _, true, 1.0);
	Cvar.AddChangeHook(CVarChanged_Bonus_ItemGiveCount);
	CVarChanged_Bonus_ItemGiveCount(Cvar, NULL_STRING, NULL_STRING);

    Cvar = CreateConVar("sm_rs_credits_name", "SHOP Кредиты", "Название пункта в меню выбора бонуса");
	HookConVarChange(Cvar, CVarChanged_Item_Name);
	GetConVarString(Cvar, NamePoint, sizeof(NamePoint));

	AutoExecConfig(true, "Items","ReferalSystem");
}

public void CVarChanged_Item_Name(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	strcopy(NamePoint, sizeof(NamePoint), newValue);
}

public void CVarChanged_Bonus_Notification(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_iTypeNotification = cvar.IntValue;
}

public void CVarChanged_Bonus_ItemGiveCount(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	g_iGiveCount = cvar.IntValue;
}

public void CVarChanged_Bonus_ItemCategory(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    strcopy(ItemCategory, sizeof(ItemCategory), newValue);
}

public void CVarChanged_Bonus_ItemNameCategory(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    strcopy(ItemNameCategory, sizeof(ItemNameCategory), newValue);
}

public void ReferalCore_OnCoreLoaded()
{
    if((g_iItemID = Referal_RegisterItemInvited(NamePoint, "item")) == -1)
    {
        SetFailState("Не удалось создать пункт[%s]",NamePoint);
    }
}

public void ReferalCore_TakeItemInvited(int iClient, int iItemID)
{
    if(g_iItemID == iItemID && iClient > 0)
    {
        char ItemName[32];
        CategoryId category = Shop_GetCategoryId(ItemCategory);
        ItemId ItemID = Shop_GetItemId(category, ItemNameCategory);
        Shop_GetItemNameById(ItemID,ItemName,sizeof ItemName);
        switch(g_iTypeNotification)
        {
            case 1: CGOPrintToChat(iClient,"{RED}[RS]{GRAY}Вы получили предмет %s в шоп за реферальный код",ItemName);
            case 2: CGOPrintToChatAll("{RED}[RS]{GRAY}Игрок %N получил бонус за реферальный код в виде предмета %s в шоп",iClient,ItemName);
        }
        Shop_GiveClientItem(iClient, ItemID, g_iGiveCount);
    }
}