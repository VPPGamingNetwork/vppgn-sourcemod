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
					
*****************************************************************************************************

*****************************************************************************************************
	INCLUDES
*****************************************************************************************************/
#include <sdktools>
#include <autoexecconfig>

/****************************************************************************************************
	DEFINES
*****************************************************************************************************/
#define PL_VERSION "1.1.8"
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
bool g_bFirstJoin[MAXPLAYERS+1] = false;
bool g_bAttemptingAdvert[MAXPLAYERS + 1] = false;
bool g_bJoinGame = false;
bool g_bProtoBuf = false;
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
	
	g_eVersion = GetEngineVersion();
	
	if(g_eVersion != Engine_CSGO && g_eVersion != Engine_TF2) {
		SetFailState("This plugin has only been tested in CSGO and TF2, Support for more games is planned.");
	}
	
	AutoExecConfig_SetFile("plugin.vpp_adverts");
	HookConVarChange(g_hAdvertUrl = AutoExecConfig_CreateConVar("sm_vpp_url", "", "Put your VPP Advert Link here"), OnCvarChanged);
	HookConVarChange(g_hCvarJoinGame = AutoExecConfig_CreateConVar("sm_vpp_onjoin", "1", "Should advertisement be displayed to players on first team join? 0 = no 1 = yes"), OnCvarChanged);
	HookConVarChange(g_hCvarAdvertTotal = AutoExecConfig_CreateConVar("sm_vpp_ad_total", "0", "How many periodic adverts should be played in total? 0 = Unlimited. -1 = Disabled."), OnCvarChanged);
	HookConVarChange(g_hCvarAdvertPeriod = AutoExecConfig_CreateConVar("sm_vpp_ad_period", "15", "How often the periodic adverts should be played (In Minutes)"), OnCvarChanged);
	HookConVarChange(g_hCvarImmunity = AutoExecConfig_CreateConVar("sm_vpp_immunity", "0", "Makes specific flag immune to adverts. 0 - off, abcdef - admin flags"), OnCvarChanged);
	HookConVarChange(g_hCvarPhaseAds = AutoExecConfig_CreateConVar("sm_vpp_onphase", "1", "Show adverts during game phases (CSGO only currently) (HalfTime, OverTime, MapEnd etc)"), OnCvarChanged);
	HookConVarChange(g_hCvarGracePeriod = AutoExecConfig_CreateConVar("sm_vpp_ad_grace", "180", "Don't show adverts to client if one has already played in the last x seconds, Min value = 180, Abusing this value may result in termination."), OnCvarChanged);
	HookConVarChange(g_hCvarKickMotd = AutoExecConfig_CreateConVar("sm_vpp_kickmotd", "0", "Kick players with motd disabled? (Immunity flag is ignored)"), OnCvarChanged);
	
	HookEventEx("player_activate", Event_PlayerActivated, EventHookMode_Post);
	HookEventEx("announce_phase_end", Event_PhaseEnd, EventHookMode_Pre);
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

public void Event_PlayerActivated(Handle hEvent, const char[] szEvent, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (!IsValidClient(iClient)) {
		return;
	}
	
	CreateTimer(g_fAdvertPeriod * 60.0, Timer_PeriodicAdvert, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	
	if (g_bJoinGame) {
		CreateTimer(0.0, Timer_JoinAdvert, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
	
	g_bFirstJoin[iClient] = true;
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

public void Event_PhaseEnd(Handle hEvent, char[] chEvent, bool bDontBroadcast)
{
	g_bPhase = true;
	
	if (!g_bPhaseAds) {
		return;
	}
	
	LoopValidClients(iClient) {
		CreateTimer(0.0, Timer_PeriodicAdvert, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return;
}

public Action Timer_JoinAdvert(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return Plugin_Stop;
	}
	
	if(HasEntProp(iClient, Prop_Send, "m_iTeamNum")) {
		int iTeam = GetClientTeam(iClient);
		
		if (iTeam <= 0) {
			return Plugin_Continue;
		}
		
		if(HasEntProp(iClient, Prop_Send, "m_iClass")) {
			if (GetEntProp(iClient, Prop_Send, "m_iClass") <= 0 && iTeam > 1) {
				return Plugin_Continue;
			}
		}
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
	
	if (g_iAdvertTotal <= -1 || g_bAttemptingAdvert[iClient]) {
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
			KickClient(iClient, "You must set cl_disablehtmlmotd 0 to play here");
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
	
	g_bAttemptingAdvert[iClient] = true;
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
	
	if(IsPlayerAlive(iClient) && !g_bPhase && !g_bFirstJoin[iClient]) {
		return Plugin_Continue;
	}
	
	if (StrEqual(g_szAdvertUrl, "")) {
		LogError("[VPP] Please specify a valid advert url.");
		return Plugin_Stop;
	}
	
	KeyValues hKv = CreateKeyValues("data");
	
	hKv.SetNum("cmd", 5);
	hKv.SetString("title", "VPP Network Advertisement MOTD");
	hKv.SetNum("type", MOTDPANEL_TYPE_URL);
	
	ShowAdvert(iClient, "info", hKv, USERMSG_BLOCKHOOKS | USERMSG_RELIABLE);
	
	g_bFirstJoin[iClient] = false;
	g_bAttemptingAdvert[iClient] = false;
	
	return Plugin_Stop;
}

stock void ShowAdvert(int iClient, const char[] szName, KeyValues hKv, int iFlags = 0)
{
	if (hKv == null) {
		CloseHandle(hKv);
		return;
	}
	
	if(!hKv.GotoFirstSubKey(false)) {
		CloseHandle(hKv);
		return;
	}
	
	TrimString(g_szAdvertUrl); StripQuotes(g_szAdvertUrl);
	
	hKv.Rewind();
	
	char szAdvertUrl[sizeof(g_szAdvertUrl)];
	
	if (g_eVersion == Engine_CSGO) {
		Format(szAdvertUrl, sizeof(szAdvertUrl), "http://vppgamingnetwork.com/vppadserver.html?url=%s", g_szAdvertUrl); // CSGO is a nightmare..
	} else {
		strcopy(szAdvertUrl, sizeof(szAdvertUrl), g_szAdvertUrl);
	}
	
	hKv.SetString("msg", szAdvertUrl);
	hKv.GotoFirstSubKey(false);
	
	Handle hMsg = StartMessageOne("VGUIMenu", iClient, iFlags);
	
	if (g_bProtoBuf) {
		PbSetString(hMsg, "name", szName);
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
		BfWriteString(hMsg, szName);
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
	
	EndMessage();
	CloseHandle(hKv);
}

public void OnClientDisconnect(int iClient)
{
	g_iAdvertPlays[iClient] = 0;
	g_iLastAdvertTime[iClient] = 0;
	g_bFirstJoin[iClient] = false;
	g_bAttemptingAdvert[iClient] = false;
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