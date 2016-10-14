/****************************************************************************************************
	[ANY] VPP Adverts
*****************************************************************************************************

*****************************************************************************************************
	CHANGELOG: 
			1.1.0 - Rewriten plugin.
			1.1.1 - 
					- Override motd instead of popping out window.
					- Remove advert on death and instead play advert periodically
						- Cvar: sm_vpp_ad_period - How often the periodic adverts should be played (In Minutes)
						- Cvar: sm_vpp_ad_total - How many periodic adverts should be played in total? 0 = Unlimited. -1 = Disabled.
			1.1.2 - 
					- Remove default root immunity.
			1.1.3 - 
					- Revert override motd due to some issues.
			1.1.4 - 
					- Added playing adverts on game phases.
						- Cvar: sm_vpp_onphase - Show adverts during game phases (HalfTime, OverTime, MapEnd etc)
			1.1.5 - 
					- Added advert grace period cvar, This prevents adverts playing too soon after last advert, min value is 180, don't abuse it or you risk account termination.
						- Cvar: sm_vpp_ad_grace - Don't show adverts to client if one has already played in the last x seconds, Min value = 180, Abusing this value may result in termination.
					- Added cvar to kick player if they have motd disabled (Disabled by default)
						- Cvar: sm_vpp_kickmotd - Kick players with motd disabled? (Immunity flag is ignored)
					- Updated advert serve url to VPP host.
			1.1.6 - 
					- Wait until player is dead before showing advert unless its in phasetime.
									
*****************************************************************************************************

*****************************************************************************************************
	INCLUDES
*****************************************************************************************************/
#include <sdktools>
#include <autoexecconfig>

/****************************************************************************************************
	DEFINES
*****************************************************************************************************/
#define PL_VERSION "1.1.6"
#define LoopValidClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsValidClient(%1))

/****************************************************************************************************
	ETIQUETTE.
*****************************************************************************************************/
#pragma newdecls required;
#pragma semicolon 1;

/****************************************************************************************************
	PLUGIN INFO.
*****************************************************************************************************/
public Plugin myinfo = 
{
	name = "VPP Advertisement Plugin", 
	author = "VPP Network & SM9(xCoderx)", 
	description = "Plugin for displaying VPP Network's advertisement on server aswell as allowing extra ones.", 
	version = PL_VERSION, 
	url = "http://vppgamingnetwork.com/"
}

/****************************************************************************************************
	HANDLES.
*****************************************************************************************************/
Handle g_hAdvertUrl = null;
Handle g_hCvarJoinGame = null;
Handle g_hCvarAdvertPeriod = null;
Handle g_hCvarImmunity = null;
Handle g_hCvarAdvertTotal = null;
Handle g_hCvarPhaseAds = null;
Handle g_hCvarGracePeriod = null;
Handle g_hCvarKickMotd = null;

/****************************************************************************************************
	STRINGS.
*****************************************************************************************************/
char g_szAdvertUrl[512];

/****************************************************************************************************
	BOOLS.
*****************************************************************************************************/
bool g_bImmune[MAXPLAYERS + 1] = false;
bool g_bJoinGame = false;
bool g_bProtoBuf = false;
bool g_bClientJoined[MAXPLAYERS + 1] = false;
bool g_bClientTeamSelected[MAXPLAYERS + 1] = false;
bool g_bPhaseAds = false;
bool g_bKickMotd = false;
bool g_bPhase = false;

/****************************************************************************************************
	INTS.
*****************************************************************************************************/
int g_iFlagBit;
int g_iAdvertGracePeriod = 180;
int g_iAdvertTotal = -1;
int g_iAdvertPlays[MAXPLAYERS + 1] = 0;
int g_iLastAdvertTime[MAXPLAYERS + 1] = 0;

/****************************************************************************************************
	FLOATS.
*****************************************************************************************************/
float g_fAdvertPeriod;

public void OnPluginStart()
{
	UserMsg umVGUIMenu = GetUserMessageId("VGUIMenu");
	
	if (umVGUIMenu == INVALID_MESSAGE_ID) {
		SetFailState("[VPP] The server's engine version doesn't supports VGUI menus.");
	}
	
	g_bProtoBuf = (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf);
	
	EngineVersion eVersion = GetEngineVersion();
	
	if (eVersion != Engine_CSGO) {
		SetFailState("This plugin is only supported on CSGO currently");
	}
	
	if (g_bProtoBuf) {
		AddCommandListener(Client_JoinGame, "joingame");
	}
	
	AddCommandListener(Client_JoinTeam, "jointeam");
	
	AutoExecConfig_SetFile("plugin.vpp_adverts");
	HookConVarChange(g_hAdvertUrl = AutoExecConfig_CreateConVar("sm_vpp_url", "", "Put your VPP Advert Link here"), OnCvarChanged);
	HookConVarChange(g_hCvarJoinGame = AutoExecConfig_CreateConVar("sm_vpp_onjoin", "1", "Should advertisement be displayed to players on first team join? 0 = no 1 = yes"), OnCvarChanged);
	HookConVarChange(g_hCvarAdvertTotal = AutoExecConfig_CreateConVar("sm_vpp_ad_total", "0", "How many periodic adverts should be played in total? 0 = Unlimited. -1 = Disabled."), OnCvarChanged);
	HookConVarChange(g_hCvarAdvertPeriod = AutoExecConfig_CreateConVar("sm_vpp_ad_period", "15", "How often the periodic adverts should be played (In Minutes)"), OnCvarChanged);
	HookConVarChange(g_hCvarImmunity = AutoExecConfig_CreateConVar("sm_vpp_immunity", "0", "Makes specific flag immune to adverts. 0 - off, abcdef - admin flags"), OnCvarChanged);
	HookConVarChange(g_hCvarPhaseAds = AutoExecConfig_CreateConVar("sm_vpp_onphase", "1", "Show adverts during game phases (HalfTime, OverTime, MapEnd etc)"), OnCvarChanged);
	HookConVarChange(g_hCvarGracePeriod = AutoExecConfig_CreateConVar("sm_vpp_ad_grace", "180", "Don't show adverts to client if one has already played in the last x seconds, Min value = 180, Abusing this value may result in termination."), OnCvarChanged);
	HookConVarChange(g_hCvarKickMotd = AutoExecConfig_CreateConVar("sm_vpp_kickmotd", "0", "Kick players with motd disabled? (Immunity flag is ignored)"), OnCvarChanged);
	
	HookEvent("player_connect_full", Event_PlayerActivated, EventHookMode_Post);
	HookEvent("announce_phase_end", Event_PhaseEnd, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	
	UpdateConVars();
	AutoExecConfig_CleanFile(); AutoExecConfig_ExecuteFile();
}

public void OnConfigsExecuted() {
	UpdateConVars();
}

public void UpdateConVars()
{
	char szBuffer[10]; GetConVarString(g_hCvarImmunity, szBuffer, sizeof(szBuffer));
	g_iFlagBit = IsValidFlag(szBuffer) ? ReadFlagString(szBuffer) : -1;
	
	g_bJoinGame = view_as<bool>(GetConVarInt(g_hCvarJoinGame));
	g_bKickMotd = view_as<bool>(GetConVarInt(g_hCvarKickMotd));
	g_bPhaseAds = view_as<bool>(GetConVarInt(g_hCvarPhaseAds));
	g_fAdvertPeriod = float(GetConVarInt(g_hCvarAdvertPeriod));
	g_iAdvertTotal = GetConVarInt(g_hCvarAdvertTotal);
	g_iAdvertGracePeriod = GetConVarInt(g_hCvarGracePeriod);
	
	// ---------------------------- Don't mess with this code. ----------------------------
	if (g_iAdvertGracePeriod < 180) {
		SetConVarInt(g_hCvarGracePeriod, 180);
		g_iAdvertGracePeriod = 180;
	}
	// ---------------------------- Don't mess with this code. ----------------------------
	
	GetConVarString(g_hAdvertUrl, g_szAdvertUrl, sizeof(g_szAdvertUrl));
}

public void OnCvarChanged(Handle hConVar, const char[] szOldValue, const char[] szNewValue)
{
	if (hConVar == g_hAdvertUrl) {
		strcopy(g_szAdvertUrl, sizeof(g_szAdvertUrl), szNewValue);
	} else if (hConVar == g_hCvarJoinGame) {
		g_bJoinGame = view_as<bool>(StringToInt(szNewValue));
	} else if (hConVar == g_hCvarPhaseAds) {
		g_bPhaseAds = view_as<bool>(StringToInt(szNewValue));
	} else if (hConVar == g_hCvarAdvertPeriod) {
		g_fAdvertPeriod = StringToFloat(szNewValue);
	} else if (hConVar == g_hCvarAdvertTotal) {
		g_iAdvertTotal = StringToInt(szNewValue);
	} else if (hConVar == g_hCvarImmunity) {
		g_iFlagBit = IsValidFlag(szNewValue) ? ReadFlagString(szNewValue) : -1;
	} else if (hConVar == g_hCvarImmunity) {
		g_iFlagBit = IsValidFlag(szNewValue) ? ReadFlagString(szNewValue) : -1;
	} else if (hConVar == g_hCvarKickMotd) {
		g_bKickMotd = view_as<bool>(StringToInt(szNewValue));
	} else if (hConVar == g_hCvarGracePeriod) {
		// ---------------------------- Don't mess with this code. ----------------------------
		g_iAdvertGracePeriod = StringToInt(szNewValue);
		
		if (g_iAdvertGracePeriod < 180) {
			SetConVarInt(g_hCvarGracePeriod, 180);
			g_iAdvertGracePeriod = 180;
		}
		// ---------------------------- Don't mess with this code. ----------------------------
	}
}

public Action Event_PlayerActivated(Handle hEvent, const char[] szEvent, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (!IsValidClient(iClient)) {
		return Plugin_Continue;
	}
	
	CreateTimer(g_fAdvertPeriod * 60.0, Timer_PeriodicAdvert, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	
	if (g_bJoinGame) {
		CreateTimer(0.0, Timer_JoinAdvert, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
	
	return Plugin_Continue;
}

public void OnMapEnd() {
	g_bPhase = false;
}

public void OnMapStart() {
	g_bPhase = false;
}

public Action Event_RoundStart(Handle hEvent, char[] chEvent, bool bDontBroadcast) {
	g_bPhase = false;
}

public Action Event_PhaseEnd(Handle hEvent, char[] chEvent, bool bDontBroadcast)
{
	g_bPhase = true;
	
	if (!g_bPhaseAds) {
		return Plugin_Continue;
	}
	
	LoopValidClients(iClient) {
		CreateTimer(0.0, Timer_PeriodicAdvert, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

public Action Client_JoinTeam(int iClient, const char[] szCommand, int iArgs)
{
	char szTeam[5]; GetCmdArgString(szTeam, sizeof(szTeam));
	
	int iSelectedTeam = StringToInt(szTeam);
	
	if (iSelectedTeam > 0) {
		g_bClientTeamSelected[iClient] = true;
	}
}

public Action Client_JoinGame(int iClient, char[] szCommand, int iArg) {
	g_bClientJoined[iClient] = true;
}

public Action Timer_JoinAdvert(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return Plugin_Stop;
	}
	
	if (!g_bClientJoined[iClient]) {
		ClearMotd(iClient);
		return Plugin_Continue;
	}
	
	if (!g_bClientTeamSelected[iClient]) {
		return Plugin_Continue;
	}
	
	QueryClientConVar(iClient, "cl_disablehtmlmotd", Query_MotdCheck, iUserId);
	
	return Plugin_Stop;
}

public Action Timer_PeriodicAdvert(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return Plugin_Stop;
	}
	
	if (g_iAdvertTotal <= -1) {
		return Plugin_Continue;
	}
	
	if (g_iAdvertTotal > 0) {
		if (g_iAdvertPlays[iClient] >= g_iAdvertTotal) {
			return Plugin_Stop;
		}
	}
	
	QueryClientConVar(iClient, "cl_disablehtmlmotd", Query_MotdCheck, iUserId);
	
	return Plugin_Continue;
}

public void Query_MotdCheck(QueryCookie qCookie, int iClient, ConVarQueryResult cqResult, const char[] szCvarName, const char[] szCvarValue, int iUserId)
{
	iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return;
	}
	
	int iFlags = GetUserFlagBits(iClient);
	g_bImmune[iClient] = g_iFlagBit != -1 ? view_as<bool>(iFlags & g_iFlagBit) : false;
	
	if (g_bImmune[iClient]) {
		return;
	}
	
	if (cqResult != ConVarQuery_Okay || StringToInt(szCvarValue) > 0) {
		if(g_bKickMotd) {
			KickClient(iClient, "You must set cl_disablehtmlmotd 0 to play here.");
		}
		return;
	}
	
	// ---------------------------- Don't mess with this code. ----------------------------
	if (g_iLastAdvertTime[iClient] > 0 && GetTime() - g_iLastAdvertTime[iClient] < g_iAdvertGracePeriod) {
		return;
	}
	
	g_iLastAdvertTime[iClient] = GetTime();
	// ---------------------------- Don't mess with this code. ----------------------------
	
	CreateTimer(0.0, Timer_TryAdvert, iUserId, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_TryAdvert(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if(!IsValidClient(iClient)) {
		return Plugin_Stop;
	}
	
	int iFlags = GetUserFlagBits(iClient);
	g_bImmune[iClient] = g_iFlagBit != -1 ? view_as<bool>(iFlags & g_iFlagBit) : false;
	
	if (g_bImmune[iClient]) {
		return Plugin_Stop;
	}
	
	if(IsPlayerAlive(iClient) && !g_bPhase) {
		return Plugin_Continue;
	}
	
	ShowAdvert(iClient);
	
	return Plugin_Stop;
}

public void ShowAdvert(int iClient)
{
	if (StrEqual(g_szAdvertUrl, "")) {
		LogError("[VPP] Please specify a valid advert url.");
		return;
	}
	
	//char szAuthId[64]; GetClientAuthId(iClient, AuthId_SteamID64, szAuthId, sizeof(szAuthId), true);
	char szAdvertUrl[512]; Format(szAdvertUrl, 512, "http://vppgamingnetwork.com/vppadserver.html?url=%s", g_szAdvertUrl);
	
	Handle hKv = CreateKeyValues("data");
	KvSetNum(hKv, "cmd", 5);
	KvSetString(hKv, "msg", szAdvertUrl);
	KvSetString(hKv, "title", "VPP Network Advertisement MOTD");
	KvSetNum(hKv, "type", MOTDPANEL_TYPE_URL);
	
	ShowVGUIPanel(iClient, "info", hKv, true);
	g_iAdvertPlays[iClient]++;
	
	CloseHandle(hKv);
}

public void OnClientDisconnect(int iClient)
{
	g_iAdvertPlays[iClient] = 0;
	g_iLastAdvertTime[iClient] = 0;
	g_bClientJoined[iClient] = false;
	g_bClientTeamSelected[iClient] = false;
}

stock bool IsValidClient(int iClient)
{
	if (iClient <= 0 || iClient > MaxClients) {
		return false;
	}
	
	if (!IsClientInGame(iClient)) {
		return false;
	}
	
	if (IsFakeClient(iClient)) {
		return false;
	}
	
	return true;
}

stock void ClearMotd(int iClient)
{
	Handle hPb = StartMessageOne("VGUIMenu", iClient);
	Handle hSubkey;
	
	PbSetString(hPb, "name", "info");
	PbSetBool(hPb, "show", false);
	
	hSubkey = PbAddMessage(hPb, "subkeys");
	PbSetString(hSubkey, "name", "title");
	PbSetString(hSubkey, "str", "");
	
	hSubkey = PbAddMessage(hPb, "subkeys");
	PbSetString(hSubkey, "name", "type");
	PbSetString(hSubkey, "str", "0");
	
	hSubkey = PbAddMessage(hPb, "subkeys");
	PbSetString(hSubkey, "name", "msg");
	PbSetString(hSubkey, "str", "");
	
	hSubkey = PbAddMessage(hPb, "subkeys");
	PbSetString(hSubkey, "name", "cmd");
	PbSetString(hSubkey, "str", "1");
	
	EndMessage();
}

stock bool IsValidFlag(const char[] szText)
{
	int iLen = strlen(szText);
	
	for (int i = 0; i < iLen; i++) {
		if (IsCharNumeric(szText[i]) || !IsCharAlpha(szText[i])) {
			return false;
		}
	}
	
	return true;
} 