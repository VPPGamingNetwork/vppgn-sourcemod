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
			1.1.7 - 
					- Added initial TF2 support, Please report any bugs which you may find.
					- Adverts on Join will now play instantly (after team / class join) without waiting for client death.
					- General code / logic improvement.
			1.1.8 - 
					- Fixed issues with adverts not playing to spectators on join.
					- Fixed a rare but potential error that could of occured if the KV handle was invalid somehow.
					- Slight code refactor / cleanup.
			1.1.9 - 
					- Override initial motd instead of waiting for team join.
					- Improve completion rates by blocking info UserMessages while an advert is in progress.
					- Added extra events for TF2, This can be controlled with the sm_vpp_onphase cvar.
					- Miscellaneous tweaks / code & timer logic improvements.
					- Set sm_vpp_kickmotd to 1 by default.
					
*****************************************************************************************************
*****************************************************************************************************
	INCLUDES
*****************************************************************************************************/
#include <sdktools>
#include <autoexecconfig>

/****************************************************************************************************
	DEFINES
*****************************************************************************************************/
#define PL_VERSION "1.1.9"
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

EngineVersion g_eVersion = Engine_Unknown;

/****************************************************************************************************
	STRINGS.
*****************************************************************************************************/
char g_szAdvertUrl[512];

/****************************************************************************************************
	BOOLS.
*****************************************************************************************************/
bool g_bImmune[MAXPLAYERS + 1] = false;
bool g_bFirstJoin[MAXPLAYERS + 1] = false;
bool g_bAttemptingAdvert[MAXPLAYERS + 1] = false;
bool g_bAdvertPlaying[MAXPLAYERS + 1] = false;
bool g_bJoinGame = false;
bool g_bProtoBuf = false;
bool g_bPhaseAds = false;
bool g_bKickMotd = false;
bool g_bPhase = false;
bool g_bMotdEnabled[MAXPLAYERS + 1] = false;

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
	
	HookUserMessage(umVGUIMenu, OnVGUIMenu, true);
	
	g_bProtoBuf = (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf);
	
	g_eVersion = GetEngineVersion();
	
	if (g_eVersion != Engine_CSGO && g_eVersion != Engine_TF2) {
		SetFailState("This plugin has only been tested in CSGO and TF2, Support for more games is planned.");
	}
	
	AutoExecConfig_SetFile("plugin.vpp_adverts");
	HookConVarChange(g_hAdvertUrl = AutoExecConfig_CreateConVar("sm_vpp_url", "", "Put your VPP Advert Link here"), OnCvarChanged);
	HookConVarChange(g_hCvarJoinGame = AutoExecConfig_CreateConVar("sm_vpp_onjoin", "1", "Should advertisement be displayed to players on first team join? 0 = no 1 = yes"), OnCvarChanged);
	HookConVarChange(g_hCvarAdvertTotal = AutoExecConfig_CreateConVar("sm_vpp_ad_total", "0", "How many periodic adverts should be played in total? 0 = Unlimited. -1 = Disabled."), OnCvarChanged);
	HookConVarChange(g_hCvarAdvertPeriod = AutoExecConfig_CreateConVar("sm_vpp_ad_period", "15", "How often the periodic adverts should be played (In Minutes)"), OnCvarChanged);
	HookConVarChange(g_hCvarImmunity = AutoExecConfig_CreateConVar("sm_vpp_immunity", "0", "Makes specific flag immune to adverts. 0 - off, abcdef - admin flags"), OnCvarChanged);
	HookConVarChange(g_hCvarPhaseAds = AutoExecConfig_CreateConVar("sm_vpp_onphase", "1", "Show adverts during game phases (HalfTime, OverTime, MapEnd, WinPanels etc)"), OnCvarChanged);
	HookConVarChange(g_hCvarGracePeriod = AutoExecConfig_CreateConVar("sm_vpp_ad_grace", "180", "Don't show adverts to client if one has already played in the last x seconds, Min value = 180, Abusing this value may result in termination."), OnCvarChanged);
	HookConVarChange(g_hCvarKickMotd = AutoExecConfig_CreateConVar("sm_vpp_kickmotd", "1", "Kick players with motd disabled? (Immunity flag is ignored)"), OnCvarChanged);
	
	// General events when an Ad can get triggered.
	HookEventEx("announce_phase_end", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("cs_win_panel_match", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("tf_game_over", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("teamplay_win_panel", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("teamplay_round_win", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("arena_win_panel", Phase_Hooks, EventHookMode_Pre);
	
	// Misc events.
	HookEventEx("round_start", Event_RoundStart, EventHookMode_Post);
	
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

public void OnClientPostAdminCheck(int iClient)
{
	if (!IsValidClient(iClient)) {
		return;
	}
	
	CreateTimer(g_fAdvertPeriod * 60.0, Timer_PeriodicAdvert, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	
	if (!g_bJoinGame) {
		return;
	}
	
	g_bFirstJoin[iClient] = true;
}

public Action OnVGUIMenu(UserMsg umId, Handle hMsg, const int[] iPlayers, int iPlayersNum, bool bReliable, bool bInit)
{
	int iClient = iPlayers[0];
	
	if (!IsValidClient(iClient)) {
		return Plugin_Continue;
	}
	
	char szKey[1024];
	
	if (g_bProtoBuf) {
		PbReadString(hMsg, "name", szKey, sizeof(szKey));
	} else {
		BfReadString(hMsg, szKey, sizeof(szKey));
	}
	
	if (!StrEqual(szKey, "info")) {
		return Plugin_Continue;
	}
	
	if (g_bAdvertPlaying[iClient]) {
		return Plugin_Handled;
	}
	
	if (g_bProtoBuf) {
		Handle hSubKey = null;
		
		for (int i = 0; i < 3; i++) {
			hSubKey = PbReadRepeatedMessage(hMsg, "subkeys", i);
			
			PbReadString(hSubKey, "name", szKey, sizeof(szKey));
			
			if (StrEqual(szKey, "msg")) {
				PbReadString(hSubKey, "str", szKey, sizeof(szKey));
			}
		}
		
	} else {
		BfReadByte(hMsg);
		
		int iKeyCount = BfReadByte(hMsg);
		
		for (int i = 0; i < iKeyCount; i++) {
			BfReadString(hMsg, szKey, sizeof(szKey));
			
			if (StrEqual(szKey, "msg") || StrEqual(szKey, "#L4D_MOTD")) {
				BfReadString(hMsg, szKey, sizeof(szKey));
			}
		}
	}
	
	if (StrEqual(szKey, "motd") && g_bFirstJoin[iClient]) {
		if (g_bProtoBuf) {
			ShowAdvert(iClient, hMsg); // We can simply override ProtoBuf messages.
		} else {
			CreateTimer(0.0, Timer_PeriodicAdvert, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE); // Although BitBuffer is different, we have to delay it.
			
			// Some games such as L4D2 wont work unless you block the original motd first.
			if (g_eVersion == Engine_Left4Dead || g_eVersion == Engine_Left4Dead2) {  // Although Unfortunately L4D / L4D2 support is postponed due to some issues with video Motd not working :(
				return Plugin_Handled; // Does not hurt to leave this code here though, incase we find a way to fix it later.
			}
		}
	}
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int iClient)
{
	g_iAdvertPlays[iClient] = 0;
	g_iLastAdvertTime[iClient] = 0;
	g_bFirstJoin[iClient] = false;
	g_bAttemptingAdvert[iClient] = false;
	g_bAdvertPlaying[iClient] = false;
	g_bMotdEnabled[iClient] = false;
}

public void OnMapEnd() {
	g_bPhase = false;
}

public void OnMapStart() {
	g_bPhase = false;
}

public void Event_RoundStart(Handle hEvent, char[] chEvent, bool bDontBroadcast) {
	g_bPhase = false;
}

public void Phase_Hooks(Handle hEvent, char[] chEvent, bool bDontBroadcast)
{
	g_bPhase = true;
	
	if (!g_bPhaseAds) {
		return;
	}
	
	LoopValidClients(iClient) {
		CreateTimer(0.0, Timer_PeriodicAdvert, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_PeriodicAdvert(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return Plugin_Stop;
	}
	
	if (g_bAttemptingAdvert[iClient]) {
		return Plugin_Continue;
	}
	
	CreateTimer(0.0, Timer_TryAdvert, GetClientUserId(iClient), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	g_bAttemptingAdvert[iClient] = true;
	
	return Plugin_Continue;
}

public Action Timer_TryAdvert(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return Plugin_Stop;
	}
	
	if(g_iAdvertTotal <= -1) {
		return Plugin_Stop;
	}
	
	if (g_iAdvertTotal > 0) {
		if (g_iAdvertPlays[iClient] >= g_iAdvertTotal) {
			g_bAttemptingAdvert[iClient] = false;
			return Plugin_Stop;
		}
	}
	
	int iFlags = GetUserFlagBits(iClient);
	g_bImmune[iClient] = g_iFlagBit != -1 ? view_as<bool>(iFlags & g_iFlagBit) : false;
	
	if (g_bAdvertPlaying[iClient] || g_bImmune[iClient]) {
		g_bAttemptingAdvert[iClient] = false;
		return Plugin_Stop;
	}
	
	if (IsPlayerAlive(iClient) && !g_bPhase && !g_bFirstJoin[iClient]) {
		return Plugin_Continue;
	}
	
	if(g_iLastAdvertTime[iClient] > 0 && GetTime() - g_iLastAdvertTime[iClient] < g_iAdvertGracePeriod) {
		return Plugin_Continue;
	}
	
	ShowAdvert(iClient);
	
	g_bAttemptingAdvert[iClient] = false;
	
	return Plugin_Stop;
}

stock void ShowAdvert(int iClient, Handle hMsg = null)
{
	if (g_bAdvertPlaying[iClient] || (g_iLastAdvertTime[iClient] > 0 && GetTime() - g_iLastAdvertTime[iClient] < g_iAdvertGracePeriod)) {
		return;
	}
	
	while (QueryClientConVar(iClient, "cl_disablehtmlmotd", Query_MotdCheck) < view_as<QueryCookie>(0)) {  }
	
	KeyValues hKv = CreateKeyValues("data");
	TrimString(g_szAdvertUrl); StripQuotes(g_szAdvertUrl);
	
	hKv.SetString("title", "VPP Network Advertisement MOTD");
	hKv.SetNum("type", MOTDPANEL_TYPE_URL);
	hKv.SetString("msg", g_szAdvertUrl);
	hKv.GotoFirstSubKey(false);
	
	bool bOverride = false;
	
	if (hMsg == null) {
		hKv.SetNum("cmd", 5);
		hMsg = StartMessageOne("VGUIMenu", iClient, USERMSG_BLOCKHOOKS | USERMSG_RELIABLE);
	} else {
		bOverride = true;
	}
	
	if (g_bProtoBuf) {
		PbSetString(hMsg, "name", "info");
		PbSetBool(hMsg, "show", true);
		
		Handle hSubKey;
		
		do {
			char szKey[128]; char szValue[128];
			hKv.GetSectionName(szKey, sizeof(szKey));
			hKv.GetString(NULL_STRING, szValue, sizeof(szValue), "");
			
			hSubKey = PbAddMessage(hMsg, "subkeys");
			
			PbSetString(hSubKey, "name", szKey);
			PbSetString(hSubKey, "str", szValue);
			
		} while (hKv.GotoNextKey(false));
		
	} else {
		BfWriteString(hMsg, "info");
		BfWriteByte(hMsg, true);
		
		int iKeyCount = 0;
		
		do {
			iKeyCount++;
		} while (hKv.GotoNextKey(false));
		
		BfWriteByte(hMsg, iKeyCount);
		
		if (iKeyCount > 0) {
			hKv.GoBack(); hKv.GotoFirstSubKey(false);
			do {
				char szKey[128]; char szValue[128];
				hKv.GetSectionName(szKey, sizeof(szKey));
				hKv.GetString(NULL_STRING, szValue, sizeof(szValue), "");
				
				BfWriteString(hMsg, szKey);
				BfWriteString(hMsg, szValue);
			} while (hKv.GotoNextKey(false));
		}
	}
	
	g_iAdvertPlays[iClient]++;
	g_bFirstJoin[iClient] = false;
	g_bAdvertPlaying[iClient] = true;
	
	CreateTimer(45.0, Timer_AdvertFinished, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
	g_iLastAdvertTime[iClient] = GetTime();
	
	if (!bOverride) {
		EndMessage();
	}
	
	CloseHandle(hKv);
}

public void Query_MotdCheck(QueryCookie qCookie, int iClient, ConVarQueryResult cqResult, const char[] szCvarName, const char[] szCvarValue)
{
	if (cqResult != ConVarQuery_Okay) {
		return;
	}
	
	if (!IsValidClient(iClient)) {
		return;
	}
	
	int iFlags = GetUserFlagBits(iClient);
	g_bImmune[iClient] = g_iFlagBit != -1 ? view_as<bool>(iFlags & g_iFlagBit) : false;
	
	if (StringToInt(szCvarValue) > 0) {
		if (g_bKickMotd && !g_bImmune[iClient]) {
			KickClient(iClient, "You must set cl_disablehtmlmotd 0 to play here");
		}
	}
}

public Action Timer_AdvertFinished(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return Plugin_Stop;
	}
	
	g_bAdvertPlaying[iClient] = false;
	
	return Plugin_Stop;
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