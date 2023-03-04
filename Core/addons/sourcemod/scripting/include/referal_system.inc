#if defined _referal_system_included
	#endinput
#endif
#define _referal_system_included

/*
Регистрирует пункт в меню бонусов для приглашенного
	const char[] name - Название пункта
	const char[] unique_name - Уникальное имя пункта
return: -1 если не добавило пункт, если добавило - порядковый номер пункта

*/
native int Referal_RegisterItemInvited(const char[] name, const char[] unique_name);

/*
Регистрирует пункт в меню магазина за бонусы для приглащающих
	const char[] name - Название пункта
	const char[] unique_name - Уникальное имя пункта
return: -1 если не добавило пункт, если добавило - порядковый номер пункта

*/
native int Referal_RegisterItemInviter(const char[] name, const char[] unique_name);

/*
Показывает главное меню реферальной системы
	int iClient - Клиент
*/
native int Referal_OpenMainMenu(int iClient);

/*
Показывает меню управления реферальным кодом
	int iClient - Клиент
*/

native int Referal_OpenControlRefMenu(int iClient);

/*
Показывает меню в выбором бонуса
	int iClient - Клиент
*/

native int Referal_OpenBonusMenu(int iClient);

/*
Получает количество бонусов у клиента
	int iClient - Клиент
*/
native int Referal_GetBonus(int iClient);

/*
Выдает бонусы клиенту если он реферал
	int iClient - Клиент
	int Count - Количество бонусов
*/
native int Referal_GiveBonus(int iClient,int Count);

/*
Забирает бонусы клиенту если он реферал
	int iClient - Клиент
	int Count - Количество бонусов
*/
native int Referal_TakeBonus(int iClient,int Count);

/*
Проверяет является ли клиент рефералом
	int iClient - Клиент
*/
native bool Referal_ClientReferal(int iClient);

/*
Проверяет ввел ли клиент реферальный код
	int iClient - Клиент
*/
native bool Referal_ClientUseRefCode(int iClient);

/*
Событие нажатия на пункт в меню бонусов для приглашенных
	int iClient - Клиента
	int ItemID - Номер Предмета
*/
forward void ReferalCore_TakeItemInvited(int iClient, int ItemID);

/*
Событие нажатия на пункт в меню бонусов для приглашающего
	int iClient - Клиента
	int ItemID - Номер Предмета
*/
forward void ReferalCore_TakeItemInviter(int iClient, int ItemID);

/*
Вызывается когда ядро загрузилось

	@noreturn
*/
forward void ReferalCore_OnCoreLoaded();

/*
Получение Базы Данных

	return: Handle базы данных
*/
native Database Referal_GetDatabase();

/*
Ядро загрузилось и готово к работе

	@noreturn
*/

native bool Referal_CoreIsLoad();

public SharedPlugin __pl_referal_system= 
{
	name = "referal_system",
	file = "Referal_system.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_referal_system_SetNTVOptional()
{
	MarkNativeAsOptional("Referal_RegisterItemInvited");
	MarkNativeAsOptional("Referal_RegisterItemInviter");
	MarkNativeAsOptional("Referal_GetDatabase");
}
#endif