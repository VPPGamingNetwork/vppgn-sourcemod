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
			1.2.0 - 
					- Added initial support for CSS, NMRIH, Please report any bugs which you may find. 
					- Added support for Radio resumation.
						- This feature will automatically resume the radio for players after ad finishes or if they try to use the radio while the advert is playing it will wait for ad to finish.
						- The radio stations are stored in a KeyValue formatted config file, You can add your own if you wish, But please let me know about them so I can add them to an update, Thanks!
					- Added Multi-Lang support - Contributions are welcome!
					- Improved checks when trying to play advert, ads should play in more cases that don't disturb players.
					- Set sm_vpp_kickmotd 0 by default again.
					- Some Syntax modernization.
*****************************************************************************************************
*****************************************************************************************************
	INCLUDES
*****************************************************************************************************/
#include <sdktools>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL    "http://vppgamingnetwork.com/smplugin/update.txt"

/****************************************************************************************************
	DEFINES
*****************************************************************************************************/
#define PL_VERSION "1.2.0"
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
ConVar g_hAdvertUrl = null;
ConVar g_hCvarJoinGame = null;
ConVar g_hCvarAdvertPeriod = null;
ConVar g_hCvarImmunity = null;
ConVar g_hCvarAdvertTotal = null;
ConVar g_hCvarPhaseAds = null;
ConVar g_hCvarGracePeriod = null;
ConVar g_hCvarKickMotd = null;

Handle g_hRadioTimer[MAXPLAYERS + 1] = null;

ArrayList g_alRadioStations = null;
DataPack g_dRadioPack[MAXPLAYERS + 1] = null;
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
bool g_bRoundEnd = false;
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
	
	if (g_eVersion != Engine_CSGO && g_eVersion != Engine_TF2 && g_eVersion != Engine_CSS && g_eVersion != view_as<EngineVersion>(19)) {
		LogMessage("This plugin has not been tested on this engine / game, things may not work correctly.");
	}
	
	//AddCommandListener(OnPageClosed, "closed_htmlpage"); Probably for later use?
	
	AutoExecConfig_SetFile("plugin.vpp_adverts");
	
	g_hAdvertUrl = AutoExecConfig_CreateConVar("sm_vpp_url", "", "Put your VPP Advert Link here");
	g_hAdvertUrl.AddChangeHook(OnCvarChanged);
	
	g_hCvarJoinGame = AutoExecConfig_CreateConVar("sm_vpp_onjoin", "1", "Should advertisement be displayed to players on first team join? 0 = no 1 = yes");
	g_hCvarJoinGame.AddChangeHook(OnCvarChanged);
	
	g_hCvarAdvertTotal = AutoExecConfig_CreateConVar("sm_vpp_ad_total", "0", "How many periodic adverts should be played in total? 0 = Unlimited. -1 = Disabled.");
	g_hCvarAdvertTotal.AddChangeHook(OnCvarChanged);
	
	g_hCvarAdvertPeriod = AutoExecConfig_CreateConVar("sm_vpp_ad_period", "15", "How often the periodic adverts should be played (In Minutes)");
	g_hCvarAdvertPeriod.AddChangeHook(OnCvarChanged);
	
	g_hCvarImmunity = AutoExecConfig_CreateConVar("sm_vpp_immunity", "0", "Makes specific flag immune to adverts. 0 - off, abcdef - admin flags");
	g_hCvarImmunity.AddChangeHook(OnCvarChanged);
	
	g_hCvarPhaseAds = AutoExecConfig_CreateConVar("sm_vpp_onphase", "1", "Show adverts during game phases (HalfTime, OverTime, MapEnd, WinPanels etc)");
	g_hCvarPhaseAds.AddChangeHook(OnCvarChanged);
	
	g_hCvarGracePeriod = AutoExecConfig_CreateConVar("sm_vpp_ad_grace", "180.0", "Don't show adverts to client if one has already played in the last x seconds", _, _, _, true, 180.0);
	g_hCvarGracePeriod.AddChangeHook(OnCvarChanged);
	
	g_hCvarKickMotd = AutoExecConfig_CreateConVar("sm_vpp_kickmotd", "0", "Kick players with motd disabled? (Immunity flag is ignored)");
	g_hCvarKickMotd.AddChangeHook(OnCvarChanged);
	
	// General events when an Ad can get triggered.
	HookEventEx("announce_phase_end", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("cs_win_panel_match", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("tf_game_over", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("teamplay_win_panel", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("teamplay_round_win", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("arena_win_panel", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("wave_complete", Phase_Hooks, EventHookMode_Pre);
	
	// Misc events.
	HookEventEx("round_start", Event_RoundStart, EventHookMode_Post);
	HookEventEx("round_end", Event_RoundEnd, EventHookMode_Pre);
	
	UpdateConVars();
	AutoExecConfig_CleanFile(); AutoExecConfig_ExecuteFile();
	LoadRadioStationsFromFile();
	
	LoadTranslations("vppadverts.phrases.txt");
	
	if (LibraryExists("updater")) {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public void OnLibraryAdded(const char[] szName)
{
    if (StrEqual(szName, "updater")) {
        Updater_AddPlugin(UPDATE_URL);
    }
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
		g_iAdvertGracePeriod = StringToInt(szNewValue);
	}
}

stock bool LoadRadioStationsFromFile()
{
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof(szPath), "configs/vpp_adverts_radios.txt");
	
	if (!FileExists(szPath)) {
		LogError("%s is missing, Radio resumation support will be disabled.", szPath);
		return false;
	}
	
	KeyValues hKv = new KeyValues("Radio Stations");
	
	if (!hKv.ImportFromFile(szPath)) {
		LogError("Failed to import Radio stations from %s, Please make sure your config is not corrupt, Radio resumation support will be disabled.", szPath);
		return false;
	}
	
	if (g_alRadioStations != null) {  // If the array is already created, we can simply refresh it.
		g_alRadioStations.Clear();
	} else {
		g_alRadioStations = new ArrayList(256);
	}
	
	hKv.GotoFirstSubKey();
	
	char szBuffer[255];
	do {
		hKv.GetString("url", szBuffer, sizeof(szBuffer));
		g_alRadioStations.PushString(szBuffer);
	} while (hKv.GotoNextKey());
	
	delete hKv;
	
	return true;
}

public void OnConfigsExecuted() {
	UpdateConVars();
}

public void UpdateConVars()
{
	char szBuffer[10];
	
	g_bJoinGame = g_hCvarJoinGame.BoolValue;
	g_bKickMotd = g_hCvarKickMotd.BoolValue;
	g_bPhaseAds = g_hCvarPhaseAds.BoolValue;
	
	g_fAdvertPeriod = g_hCvarAdvertPeriod.FloatValue;
	
	g_iAdvertTotal = g_hCvarAdvertTotal.IntValue;
	g_iAdvertGracePeriod = g_hCvarGracePeriod.IntValue;
	
	g_hAdvertUrl.GetString(g_szAdvertUrl, sizeof(g_szAdvertUrl));
	g_hCvarImmunity.GetString(szBuffer, sizeof(szBuffer));
	
	g_iFlagBit = IsValidFlag(szBuffer) ? ReadFlagString(szBuffer) : -1;
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

/* Probably for later use?
public Action OnPageClosed(int iClient, const char[] szCommand, int iArgs)
{
	if (!g_bFirstJoin[iClient]) {
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
} */

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
	
	char szTitle[1024];
	char szUrl[1024];
	bool bShow = false;
	
	if (g_bProtoBuf) {
		Handle hSubKey = null;
		
		int iKeyCount = PbGetRepeatedFieldCount(hMsg, "subkeys");
		
		for (int i = 0; i < iKeyCount; i++) {
			hSubKey = PbReadRepeatedMessage(hMsg, "subkeys", i);
			
			PbReadString(hSubKey, "name", szKey, sizeof(szKey));
			
			if (StrEqual(szKey, "title")) {
				PbReadString(hSubKey, "str", szTitle, sizeof(szTitle));
			}
			
			if (StrEqual(szKey, "show")) {
				bShow = PbReadBool(hSubKey, "str");
			}
			if (StrEqual(szKey, "msg")) {
				PbReadString(hSubKey, "str", szUrl, sizeof(szUrl));
			}
		}
		
	} else {
		BfReadByte(hMsg);
		
		int iKeyCount = BfReadByte(hMsg);
		
		for (int i = 0; i < iKeyCount; i++) {
			BfReadString(hMsg, szKey, sizeof(szKey));
			
			if (StrEqual(szKey, "title")) {
				BfReadString(hMsg, szTitle, sizeof(szTitle));
			}
			
			BfReadString(hMsg, szKey, sizeof(szKey));
			BfReadString(hMsg, szKey, sizeof(szKey));
			
			if (StrEqual(szKey, "show")) {
				bShow = view_as<bool>(BfReadByte(hMsg));
			}
			
			BfReadString(hMsg, szKey, sizeof(szKey));
			
			if (StrEqual(szKey, "msg") || StrEqual(szKey, "#L4D_MOTD")) {
				BfReadString(hMsg, szUrl, sizeof(szUrl));
			}
		}
	}
	
	if (StrEqual(szUrl, "motd") && g_bFirstJoin[iClient]) {
		if (g_bProtoBuf) {
			ShowAdvert(iClient, USERMSG_BLOCKHOOKS | USERMSG_RELIABLE, hMsg); // We can simply override (ALL?) ProtoBuf messages.
		} else {
			switch (g_eVersion) {  // Various engines can require some special treatment for the ads to work correctly.
				case Engine_Left4Dead, Engine_Left4Dead2, 19 :  { // 19 = NMRIH
					CreateTimer(0.0, Timer_PeriodicAdvert, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
					return Plugin_Handled;
				}
				
				default: { // For the most part this "MAY" work in other games, but full support probably won't not be available.
					CreateTimer(0.0, Timer_PeriodicAdvert, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		
		return Plugin_Continue;
	}
	
	bool bRadio = false;
	char szBuffer[256];
	
	int iRadioStations = sizeof(g_alRadioStations);
	
	for (int i = 0; i < iRadioStations; i++) {
		g_alRadioStations.GetString(i, szBuffer, sizeof(szBuffer));
		
		if (StrContains(szUrl, szBuffer, false) != -1) {
			bRadio = true;
			break;
		}
	}
	
	if (StrEqual(szTitle, "VPP Network Advertisement MOTD") || StrEqual(szUrl, g_szAdvertUrl, false)) {
		if (g_hRadioTimer[iClient] == null && g_dRadioPack[iClient] != null) {
			g_hRadioTimer[iClient] = CreateTimer(0.0, Timer_AfterAdRequest, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		}
		
		if (g_bAdvertPlaying[iClient]) {  // Fix for some quirky quirks.
			return Plugin_Handled;
		}
	} else if (g_bAdvertPlaying[iClient]) {
		if (bRadio) {
			DataPack dPack = CreateDataPack();
			dPack.WriteString(szTitle); dPack.WriteCell(view_as<int>(bShow)); dPack.WriteString(szUrl);
			
			if (g_dRadioPack[iClient] != null) {
				delete g_dRadioPack[iClient];
				g_dRadioPack[iClient] = null;
			}
			
			g_dRadioPack[iClient] = dPack;
			
			RequestFrame(PrintRadioMessage, GetClientUserId(iClient));
		} else {
			RequestFrame(PrintMiscMessage, GetClientUserId(iClient));
		}
		
		if (g_hRadioTimer[iClient] == null && g_dRadioPack[iClient] != null) {
			g_hRadioTimer[iClient] = CreateTimer(0.0, Timer_AfterAdRequest, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void PrintRadioMessage(int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return;
	}
	
	PrintToChat(iClient, "\x01[\x04Advert\x01] \x04%t", "Radio Message");
}

public void PrintMiscMessage(int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return;
	}
	
	PrintToChat(iClient, "\x01[\x04Advert\x01] \x04%t", "Misc Message");
}

public void OnClientDisconnect(int iClient)
{
	g_iAdvertPlays[iClient] = 0;
	g_iLastAdvertTime[iClient] = 0;
	g_bFirstJoin[iClient] = false;
	g_bAttemptingAdvert[iClient] = false;
	g_bAdvertPlaying[iClient] = false;
	g_bMotdEnabled[iClient] = false;
	
	if (g_dRadioPack[iClient] != null) {
		delete g_dRadioPack[iClient];
		g_dRadioPack[iClient] = null;
	}
	
	if (g_hRadioTimer[iClient] != null) {
		CloseHandle(g_hRadioTimer[iClient]);
		g_hRadioTimer[iClient] = null;
	}
}

public void OnMapEnd() {
	g_bPhase = false;
}

public void OnMapStart() {
	g_bPhase = false;
}

public void Event_RoundStart(Handle hEvent, char[] chEvent, bool bDontBroadcast) {
	g_bRoundEnd = false;
	g_bPhase = false;
}

public void Event_RoundEnd(Handle hEvent, char[] chEvent, bool bDontBroadcast) {
	g_bRoundEnd = true;
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
	
	if (g_iAdvertTotal <= -1) {
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
	
	if (IsPlayerAlive(iClient) && (!g_bPhase && !g_bFirstJoin[iClient] && !g_bRoundEnd && !CheckGameSpecificConditions())) {
		return Plugin_Continue;
	}
	
	if (g_iLastAdvertTime[iClient] > 0 && GetTime() - g_iLastAdvertTime[iClient] < g_iAdvertGracePeriod) {
		return Plugin_Continue;
	}
	
	ShowAdvert(iClient, g_bFirstJoin[iClient] ? USERMSG_BLOCKHOOKS | USERMSG_RELIABLE : 0);
	
	g_bAttemptingAdvert[iClient] = false;
	
	return Plugin_Stop;
}

public Action Timer_AfterAdRequest(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return Plugin_Stop;
	}
	
	if (g_bAdvertPlaying[iClient]) {
		return Plugin_Continue;
	}
	
	g_dRadioPack[iClient].Reset();
	
	char szTitle[1024]; char szUrl[1024];
	bool bShow = false;
	
	g_dRadioPack[iClient].ReadString(szTitle, sizeof(szTitle));
	bShow = view_as<bool>(g_dRadioPack[iClient].ReadCell());
	g_dRadioPack[iClient].ReadString(szUrl, sizeof(szUrl));
	
	if (g_bAttemptingAdvert[iClient] || (bShow && (IsPlayerAlive(iClient) && !g_bPhase && !g_bFirstJoin[iClient] && !g_bRoundEnd && !CheckGameSpecificConditions()))) {
		return Plugin_Continue;
	}
	
	ShowVGUIPanelEx(iClient, szTitle, szUrl, MOTDPANEL_TYPE_URL, 0, bShow);
	g_hRadioTimer[iClient] = null;
	
	return Plugin_Stop;
}

stock void ShowAdvert(int iClient, int iFlags, Handle hMsg = null)
{
	if (g_bAdvertPlaying[iClient] || (g_iLastAdvertTime[iClient] > 0 && GetTime() - g_iLastAdvertTime[iClient] < g_iAdvertGracePeriod)) {
		return;
	}
	
	while (QueryClientConVar(iClient, "cl_disablehtmlmotd", Query_MotdCheck) < view_as<QueryCookie>(0)) {  }
	
	if (!IsValidClient(iClient)) {
		return;
	}
	
	TrimString(g_szAdvertUrl); StripQuotes(g_szAdvertUrl);
	
	if (g_bFirstJoin[iClient] && g_eVersion == Engine_CSS) {
		FakeClientCommandEx(iClient, "joingame"); // Fix the bug with team menu.
	}
	
	ShowVGUIPanelEx(iClient, "VPP Network Advertisement MOTD", g_szAdvertUrl, MOTDPANEL_TYPE_URL, iFlags, true, hMsg);
	CreateTimer(45.0, Timer_AdvertFinished, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
	
	g_bAdvertPlaying[iClient] = true;
	g_iLastAdvertTime[iClient] = GetTime();
	g_iAdvertPlays[iClient]++;
	
	g_bFirstJoin[iClient] = false;
}

stock void ShowVGUIPanelEx(int iClient, const char[] szTitle, const char[] szUrl, int iType = MOTDPANEL_TYPE_URL, int iFlags = 0, bool bShow = true, Handle hMsg = null)
{
	KeyValues hKv = CreateKeyValues("data");
	
	hKv.SetString("title", szTitle);
	hKv.SetNum("type", iType);
	hKv.SetString("msg", szUrl);
	
	hKv.GotoFirstSubKey(false);
	
	bool bOverride = false;
	
	if (hMsg == null) {
		hKv.SetNum("cmd", 5);
		hMsg = StartMessageOne("VGUIMenu", iClient, iFlags);
	} else {
		bOverride = true;
	}
	
	if (g_bProtoBuf) {
		PbSetString(hMsg, "name", "info");
		PbSetBool(hMsg, "show", bShow);
		
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
		BfWriteByte(hMsg, bShow);
		
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
	
	if (!bOverride) {
		EndMessage();
	}
	
	delete hKv;
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
			KickClient(iClient, "%t", "Kick Message");
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
	
	PrintToChat(iClient, "\x01[\x04Advert\x01] \x04%t", "Advert Finished");
	
	return Plugin_Stop;
}

/* Probably for later use?
stock bool GameUsesVGUIEnum()
{
	return g_eVersion == Engine_CSS
		|| g_eVersion == Engine_TF2
		|| g_eVersion == Engine_DODS
		|| g_eVersion == Engine_HL2DM
		|| g_eVersion == Engine_NuclearDawn
		|| g_eVersion == Engine_CSGO
		|| g_G == Engine_Insurgency;
} */

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

stock bool CheckGameSpecificConditions()
{
	if(g_eVersion == Engine_CSGO) {
		if (GameRules_GetProp("m_bWarmupPeriod") == 1 || GameRules_GetProp("m_bFreezePeriod") == 1) {
			return true;
		}
	}
	
	return false;
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