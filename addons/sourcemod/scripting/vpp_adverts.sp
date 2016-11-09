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
			1.2.1 - 
					- Added command sm_vppreload with Admin Cvar flag to reload radios from config file.
					- Added some polish radio stations (Thanks xWangan - Also helped me with translations)
			1.2.2 - 
					- Added support for Day of defeat: Source, Fist full of Frags, Please report any bugs which you may find. 
					- Added support for loading third party radio stations (https://forums.alliedmods.net/showthread.php?p=512035)
					- Added vpp_adverts_radios_custom.txt from now on, please avoid editing vpp_adverts_radios.txt as this file may get overwritten when plugin updates happen.
						- If you have any custom radio stations in vpp_adverts_radios.txt then please move them to vpp_adverts_radios_custom.txt, 
						Also let us know and we can add them to vpp_adverts_radios.txt for next update.
					- Added duplicate radio detection to prevent the same radio station getting added multiple times.
					- Improved reload command, it will now say how many radio stations were actually loaded.
					- Fixed an issue which would cause radio resume to wait until player died or fail in some special cases.
			
			1.2.3 - 
					- Added initial support for Codename: CURE, BrainBread 2 & Nuclear Dawn, Please report any bugs which you may find.
					- Improved game detection to use path instead of engine version now, We still use engine version to determine a couple of things though.
						- You are welcome to try the plugin on games which we don't yet officially support, but please note that things might not work correctly.
						- If you want game support then please let us know!
					- Added Cvar sm_vpp_spec_ad_period to play adverts to spectators on a set period (In minutes), Default = 3, Min = 3, 0 = Disabled.
					- Fixed a couple of issues where Radio would not resume correctly & Fixed a rare case where adverts could resume for players who were not listening it.
					- Remove adverts at round end / freezetime being a "Good" period, it apppers to have caused a couple of complaints that it was disturbing players.
					- Removed advert grace period cvar and set it to 3 mins, Adverts should not be playing more often than every 3 mins anyway as it will risk getting you banned for spamming ads.
			1.2.4 - 
					- Fixed timer error from caused by it being closed twice due to disconnect and team event happening at same time.
					- Fixed Immunity not working, (Thanks sneaK for reporting the bug)
						- Immunity now uses overrides, You can set this up by adding advertisement_immunity to admin_overrides.cfg, Root flag is always immune.
					- Added old Cvar catcher (Thanks Pinion for the idea)
					- Replaced Cvar sm_vpp_immunity with sm_vpp_immunity_enabled
						- Set to 1 to prevent displaying ads to users with access to 'advertisement_immunity', Root flag is always immune.
					
*****************************************************************************************************
*****************************************************************************************************
	INCLUDES
*****************************************************************************************************/
#include <sdktools>
#include <autoexecconfig>
#include <multicolors>

#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL    "http://vppgamingnetwork.com/smplugin/update.txt"

/****************************************************************************************************
	DEFINES
*****************************************************************************************************/
#define PL_VERSION "1.2.4"
#define LoopValidClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsValidClient(%1))
#define PREFIX "[{lightgreen}Advert{default}] "

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
ConVar g_hCvarImmunityEnabled = null;
ConVar g_hCvarAdvertTotal = null;
ConVar g_hCvarPhaseAds = null;
ConVar g_hCvarKickMotd = null;
ConVar g_hCvarSpecAdvertPeriod = null;

Handle g_hRadioTimer[MAXPLAYERS + 1] = null;
Handle g_hSpecTimer[MAXPLAYERS + 1] = null;

ArrayList g_alRadioStations = null;
DataPack g_dRadioPack[MAXPLAYERS + 1] = null;
EngineVersion g_eVersion = Engine_Unknown;

/****************************************************************************************************
	STRINGS.
*****************************************************************************************************/
char g_szAdvertUrl[256];
char g_szGameName[256];

char g_szTestedGames[][] =  {
	"csgo", 
	"tf", 
	"cstrike", 
	"cure", 
	"brainbread2", 
	"dod", 
	"fof", 
	"nucleardawn", 
	"nmrih"
};

char g_szJoinGames[][] =  {
	"dod", 
	"nucleardawn", 
	"brainbread2",
	"cstrike"
};

/****************************************************************************************************
	BOOLS.
*****************************************************************************************************/
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
bool g_bGameTested = false;
bool g_bForceJoinGame = false;
bool g_bImmunityEnabled = false;

/****************************************************************************************************
	INTS.
*****************************************************************************************************/
int g_iAdvertTotal = -1;
int g_iAdvertPlays[MAXPLAYERS + 1] = 0;
int g_iLastAdvertTime[MAXPLAYERS + 1] = 0;

/****************************************************************************************************
	FLOATS.
*****************************************************************************************************/
float g_fAdvertPeriod;
float g_fSpecAdvertPeriod;

public void OnPluginStart()
{
	UserMsg umVGUIMenu = GetUserMessageId("VGUIMenu");
	
	if (umVGUIMenu == INVALID_MESSAGE_ID) {
		SetFailState("[VPP] The server's engine version doesn't supports VGUI menus.");
	}
	
	HookUserMessage(umVGUIMenu, OnVGUIMenu, true);
	
	g_bProtoBuf = (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf);
	
	if (GetGameFolderName(g_szGameName, sizeof(g_szGameName)) <= 0) {
		SetFailState("Something went very wrong with this game / engine, thus support is not available.");
	}
	
	g_eVersion = GetEngineVersion();
	
	int iSupportedGames = sizeof(g_szTestedGames);
	int iJoinGames = sizeof(g_szJoinGames);
	
	for (int i = 0; i < iSupportedGames; i++) {
		if (StrEqual(g_szGameName, g_szTestedGames[i])) {
			g_bGameTested = true;
			break;
		}
	}
	
	for (int i = 0; i < iJoinGames; i++) {
		if (StrEqual(g_szGameName, g_szJoinGames[i])) {
			g_bForceJoinGame = true;
			break;
		}
	}
	
	if (!g_bGameTested) {
		LogMessage("This plugin has not been tested on this engine / (game: %s, engine: %d), things may not work correctly.", g_szGameName, g_eVersion);
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
	
	g_hCvarSpecAdvertPeriod = AutoExecConfig_CreateConVar("sm_vpp_spec_ad_period", "3", "How often should ads be played to spectators (In Minutes) 0 = Disabled");
	g_hCvarSpecAdvertPeriod.AddChangeHook(OnCvarChanged);
	
	g_hCvarImmunityEnabled = AutoExecConfig_CreateConVar("sm_vpp_immunity_enabled", "0", "Set to 1 to prevent displaying ads to users with access to 'advertisement_immunity', Root flag is always immune.");
	g_hCvarImmunityEnabled.AddChangeHook(OnCvarChanged);
	
	g_hCvarPhaseAds = AutoExecConfig_CreateConVar("sm_vpp_onphase", "1", "Show adverts during game phases (HalfTime, OverTime, MapEnd, WinPanels etc)");
	g_hCvarPhaseAds.AddChangeHook(OnCvarChanged);
	
	g_hCvarKickMotd = AutoExecConfig_CreateConVar("sm_vpp_kickmotd", "0", "Kick players with motd disabled? (Immunity flag is ignored)");
	g_hCvarKickMotd.AddChangeHook(OnCvarChanged);
	
	RegAdminCmd("sm_vppreload", Command_Reload, ADMFLAG_CONVARS, "Reloads radio stations");
	
	// Special events where ads can get triggered.
	HookEventEx("game_win", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("game_end", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("round_win", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("tf_game_over", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("teamplay_win_panel", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("teamplay_round_win", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("arena_win_panel", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("announce_phase_end", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("cs_win_panel_match", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("wave_complete", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("dod_game_over", Phase_Hooks, EventHookMode_Pre);
	HookEventEx("dod_win_panel", Phase_Hooks, EventHookMode_Pre);
	
	// Misc events.
	HookEventEx("round_start", Event_RoundStart, EventHookMode_Post);
	HookEventEx("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	
	LoadTranslations("vppadverts.phrases.txt");
	
	UpdateConVars();
	AutoExecConfig_CleanFile(); AutoExecConfig_ExecuteFile();
	LoadRadioStations();
	
	if (LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
	
	RegServerCmd("sm_vpp_immunity", OldCvarFound, "Outdated cvar, please update your config.");
	RegServerCmd("sm_vpp_ad_grace", OldCvarFound, "Outdated cvar, please update your config.");
}

public Action OldCvarFound(int iArgs)
{
	if (iArgs != 1)
		return Plugin_Stop;
		
	char szCvarName[64]; GetCmdArg(0, szCvarName, sizeof(szCvarName));
	
	LogError("\n\nHey, it looks like your config is outdated, Please consider having a look at the information below and update your config.\n");

	if (StrEqual(szCvarName, "sm_vpp_immunity", false)) {
		LogError("======================[sm_vpp_immunity]======================");
		LogError("sm_vpp_immunity has changed to sm_vpp_immunity_enabled, and the overrides system is now being used.");
		LogError("Users with access to 'advertisement_immunity' are now immune to ads when sm_vpp_immunity_enabled is set to 1.\n");
	} else if (StrEqual(szCvarName, "sm_vpp_ad_grace", false)) {
		LogError("======================[sm_vpp_ad_grace]======================");
		LogError("sm_vpp_ad_grace no longer exists and the cvar is now unused.");
		LogError("You can simply use the other cvars to control when how often ads are played, But a 3 min cooldown between each ad is always enforced.\n");
	}
	
	LogError("After you have acknowledged the above messages and updated your config, you may completely remove the cvars to prevent this message displaying again.");
	
	return Plugin_Handled;
}

public void OnLibraryAdded(const char[] szName)
{
	if (StrEqual(szName, "updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
}

public void OnCvarChanged(ConVar hConVar, const char[] szOldValue, const char[] szNewValue)
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
	} else if (hConVar == g_hCvarImmunityEnabled) {
		g_bImmunityEnabled = view_as<bool>(StringToInt(szNewValue));
	}  else if (hConVar == g_hCvarKickMotd) {
		g_bKickMotd = view_as<bool>(StringToInt(szNewValue));
	} else if (hConVar == g_hCvarSpecAdvertPeriod) {
		g_fSpecAdvertPeriod = StringToFloat(szNewValue);
		
		if (g_fSpecAdvertPeriod < 3.0 && g_fSpecAdvertPeriod > 0.0) {
			g_fSpecAdvertPeriod = 3.0;
		}
	}
}

public Action Command_Reload(int iClient, int iArgs)
{
	CReplyToCommand(iClient, "%s%t", PREFIX, "Radios Loaded", LoadRadioStations());
	
	return Plugin_Handled;
}

stock int LoadRadioStations()
{
	if (g_alRadioStations != null) {  // If the array is already created, we can simply refresh it.
		g_alRadioStations.Clear();
	} else {
		g_alRadioStations = new ArrayList(256);
	}
	
	LoadThirdPartyRadioStations();
	LoadPresetRadioStations();
	
	int iLoaded = g_alRadioStations.Length;
	
	LogMessage("%t", "Radios Loaded", iLoaded);
	
	return iLoaded;
}

stock void LoadPresetRadioStations()
{
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof(szPath), "configs/vpp_adverts_radios.txt");
	
	if (!FileExists(szPath)) {
		return;
	}
	
	KeyValues hKv = new KeyValues("Radio Stations");
	
	if (!hKv.ImportFromFile(szPath)) {
		return;
	}
	
	hKv.GotoFirstSubKey();
	
	char szBuffer[256];
	do {
		hKv.GetString("url", szBuffer, sizeof(szBuffer));
		
		TrimString(szBuffer); StripQuotes(szBuffer); ReplaceString(szBuffer, sizeof(szBuffer), ";", "");
		
		if (RadioEntryExists(szBuffer)) {
			continue;
		}
		
		g_alRadioStations.PushString(szBuffer);
		
	} while (hKv.GotoNextKey());
	
	delete hKv;
}

stock void LoadThirdPartyRadioStations()
{
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof(szPath), "configs/radiovolume.txt");
	
	if (FileExists(szPath)) {
		KeyValues hKv = new KeyValues("Radio Stations");
		
		if (hKv.ImportFromFile(szPath)) {
			hKv.GotoFirstSubKey();
			
			char szBuffer[256];
			do {
				hKv.GetString("Stream URL", szBuffer, sizeof(szBuffer));
				
				TrimString(szBuffer); StripQuotes(szBuffer); ReplaceString(szBuffer, sizeof(szBuffer), ";", "");
				
				if (RadioEntryExists(szBuffer)) {
					continue;
				}
				
				g_alRadioStations.PushString(szBuffer);
				
			} while (hKv.GotoNextKey());
			
			delete hKv;
		}
	}
	
	BuildPath(Path_SM, szPath, sizeof(szPath), "configs/vpp_adverts_radios_custom.txt");
	
	if (FileExists(szPath)) {
		KeyValues hKv = new KeyValues("Radio Stations");
		
		if (hKv.ImportFromFile(szPath)) {
			hKv.GotoFirstSubKey();
			
			char szBuffer[256];
			do {
				hKv.GetString("url", szBuffer, sizeof(szBuffer));
				
				TrimString(szBuffer); StripQuotes(szBuffer); ReplaceString(szBuffer, sizeof(szBuffer), ";", "");
				
				if (RadioEntryExists(szBuffer)) {
					continue;
				}
				
				g_alRadioStations.PushString(szBuffer);
				
			} while (hKv.GotoNextKey());
			
			delete hKv;
		}
	}
}

public void OnConfigsExecuted() {
	UpdateConVars();
}

public void UpdateConVars()
{
	g_bJoinGame = g_hCvarJoinGame.BoolValue;
	g_bKickMotd = g_hCvarKickMotd.BoolValue;
	g_bPhaseAds = g_hCvarPhaseAds.BoolValue;
	g_bImmunityEnabled = g_hCvarImmunityEnabled.BoolValue;
	
	g_fAdvertPeriod = g_hCvarAdvertPeriod.FloatValue;
	g_fSpecAdvertPeriod = g_hCvarSpecAdvertPeriod.FloatValue;
	
	if (g_fSpecAdvertPeriod < 3.0 && g_fSpecAdvertPeriod > 0.0) {
		g_fSpecAdvertPeriod = 3.0;
		g_hCvarSpecAdvertPeriod.IntValue = 3;
	}
	
	g_iAdvertTotal = g_hCvarAdvertTotal.IntValue;
	
	g_hAdvertUrl.GetString(g_szAdvertUrl, sizeof(g_szAdvertUrl));
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
	
	if(IsClientImmune(iClient)) {
		return Plugin_Continue;
	}
	
	char szKey[256];
	
	if (g_bProtoBuf) {
		PbReadString(hMsg, "name", szKey, sizeof(szKey));
	} else {
		BfReadString(hMsg, szKey, sizeof(szKey));
	}
	
	if (!StrEqual(szKey, "info")) {
		return Plugin_Continue;
	}
	
	char szTitle[256];
	char szUrl[256];
	
	if (g_bProtoBuf) {
		Handle hSubKey = null;
		
		int iKeyCount = PbGetRepeatedFieldCount(hMsg, "subkeys");
		
		for (int i = 0; i < iKeyCount; i++) {
			hSubKey = PbReadRepeatedMessage(hMsg, "subkeys", i);
			
			PbReadString(hSubKey, "name", szKey, sizeof(szKey));
			
			if (StrEqual(szKey, "title")) {
				PbReadString(hSubKey, "str", szTitle, sizeof(szTitle));
			}
			
			if (StrEqual(szKey, "msg")) {
				PbReadString(hSubKey, "str", szUrl, sizeof(szUrl));
			}
		}
		
	} else {
		int iKeyCount = BfGetNumBytesLeft(hMsg);
		
		for (int i = 0; i < iKeyCount; i++) {
			BfReadString(hMsg, szKey, sizeof(szKey));
			
			if (StrEqual(szKey, "title")) {
				BfReadString(hMsg, szTitle, sizeof(szTitle));
			}
			
			if (StrEqual(szKey, "msg") || StrEqual(szKey, "#L4D_MOTD")) {
				BfReadString(hMsg, szUrl, sizeof(szUrl));
			}
		}
	}
	
	if (StrEqual(szUrl, "motd") && g_bFirstJoin[iClient]) {
		if (g_bProtoBuf) {
			ShowAdvert(iClient, USERMSG_RELIABLE, hMsg); // We can simply override (ALL?) ProtoBuf messages.
		} else {
			switch (g_eVersion) {  // Various engines can require some special treatment for the ads to work correctly.
				case Engine_Left4Dead, Engine_Left4Dead2, 19: {  // 19 = NMRIH, BrainBread 2
					CreateTimer(0.0, Timer_PeriodicAdvert, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
					return Plugin_Handled;
				}
				
				default: {  // For the most part this "MAY" work in other games, but full support probably won't not be available.
					CreateTimer(0.0, Timer_PeriodicAdvert, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		
		return Plugin_Continue;
	}
	
	bool bRadio = false;
	char szBuffer[256];
	
	int iRadioStations = g_alRadioStations.Length;
	
	for (int i = 0; i < iRadioStations; i++) {
		g_alRadioStations.GetString(i, szBuffer, sizeof(szBuffer));
		
		if (StrContains(szUrl, szBuffer, false) != -1) {
			bRadio = true;
			break;
		}
	}
	
	if (StrEqual(szUrl, "http://clanofdoom.co.uk/servers/motd/?id=radio")) {  // For some reason this gets sent with the FragRadio plugin, it does nothing and it interferes with shit.
		return Plugin_Handled; // So lets block it.
	}
	
	if (StrEqual(szTitle, "VPP Network Advertisement MOTD") || StrEqual(szUrl, g_szAdvertUrl, false)) {
		if (g_hRadioTimer[iClient] == null && g_dRadioPack[iClient] != null) {
			g_hRadioTimer[iClient] = CreateTimer(0.0, Timer_AfterAdRequest, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		}
		
		if (g_bAdvertPlaying[iClient]) {  // Fix for some quirky quirks.
			return Plugin_Handled;
		}
		
		g_bAdvertPlaying[iClient] = true;
	} else if (g_bAdvertPlaying[iClient] || bRadio) {
		if (bRadio) {
			DataPack dPack = CreateDataPack();
			dPack.WriteCell(GetClientUserId(iClient));
			dPack.WriteString(szTitle); dPack.WriteString(szUrl);
			
			if (g_dRadioPack[iClient] != null) {
				delete g_dRadioPack[iClient];
				g_dRadioPack[iClient] = null;
			}
			
			g_dRadioPack[iClient] = dPack;
		}
		
		if (g_bAdvertPlaying[iClient]) {
			if (g_hRadioTimer[iClient] == null && g_dRadioPack[iClient] != null) {
				g_hRadioTimer[iClient] = CreateTimer(0.0, Timer_AfterAdRequest, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
			}
			if (bRadio) {
				RequestFrame(PrintRadioMessage, GetClientUserId(iClient));
			} else {
				RequestFrame(PrintMiscMessage, GetClientUserId(iClient));
			}
			
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public void PrintRadioMessage(int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return;
	}
	
	CPrintToChat(iClient, "%s%t", PREFIX, "Radio Message");
}

public void PrintMiscMessage(int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return;
	}
	
	CPrintToChat(iClient, "%s%t", PREFIX, "Misc Message");
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
		KillTimer(g_hRadioTimer[iClient]);
		g_hRadioTimer[iClient] = null;
	}
	
	if (g_hSpecTimer[iClient] != null) {
		KillTimer(g_hSpecTimer[iClient]);
		g_hSpecTimer[iClient] = null;
	}
}

public void OnMapEnd() {
	g_bPhase = false;
}

public void OnMapStart() {
	g_bPhase = false;
}

public void Event_RoundStart(Event eEvent, char[] chEvent, bool bDontBroadcast) {
	g_bRoundEnd = false;
	g_bPhase = false;
}

public void Event_RoundEnd(Event eEvent, char[] chEvent, bool bDontBroadcast) {
	g_bRoundEnd = true;
}

public void Phase_Hooks(Event eEvent, char[] chEvent, bool bDontBroadcast)
{
	g_bPhase = true;
	
	if (!g_bPhaseAds) {
		return;
	}
	
	bool bShouldAdBeSent = false;
	
	if (StrEqual(g_szGameName, "cure")) {
		bShouldAdBeSent = eEvent.GetInt("wave") % 3 == 0; // Play an ad every 3 waves? TODO: Tweak if needed.
	} else {
		bShouldAdBeSent = true;
	}
	
	if (!bShouldAdBeSent) {
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
	
	if (IsClientImmune(iClient)) {
		return Plugin_Continue;
	}
	
	if (g_bAttemptingAdvert[iClient] || g_hSpecTimer[iClient] != null) {
		return Plugin_Continue;
	}
	
	CreateTimer(0.0, Timer_TryAdvert, GetClientUserId(iClient), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	g_bAttemptingAdvert[iClient] = true;
	
	return Plugin_Continue;
}

public Action Event_PlayerTeam(Event eEvent, char[] chEvent, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(eEvent.GetInt("userid"));
	int iTeam = eEvent.GetInt("team");
	bool bDisconnect = eEvent.GetBool("disconnect");
	
	if(bDisconnect) {
		return Plugin_Continue;
	}
	
	if (iTeam == 1 && g_fSpecAdvertPeriod > 0.0) {
		CreateTimer(0.0, Timer_TryAdvert, GetClientUserId(iClient), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	} else if (g_hSpecTimer[iClient] != null) {
		KillTimer(g_hSpecTimer[iClient]);
		g_hSpecTimer[iClient] = null;
	}
	
	return Plugin_Continue;
}

public Action Timer_TryAdvert(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return Plugin_Stop;
	}
	
	if (IsClientImmune(iClient)) {
		g_bAttemptingAdvert[iClient] = false;
		return Plugin_Stop;
	}
	
	if (g_iAdvertTotal <= -1) {
		g_bAttemptingAdvert[iClient] = false;
		return Plugin_Stop;
	}
	
	if (g_iAdvertTotal > 0) {
		if (g_iAdvertPlays[iClient] >= g_iAdvertTotal) {
			g_bAttemptingAdvert[iClient] = false;
			return Plugin_Stop;
		}
	}
	
	int iTeam = GetClientTeam(iClient);
	
	if (g_bAdvertPlaying[iClient]) {
		if (iTeam == 1 && g_fSpecAdvertPeriod > 0.0) {
			return Plugin_Continue;
		}
		
		g_bAttemptingAdvert[iClient] = false;
		return Plugin_Stop;
	}
	
	if (g_eVersion == Engine_DODS && iTeam < 1) {
		return Plugin_Continue;
	}
	
	if (g_iLastAdvertTime[iClient] > 0 && GetTime() - g_iLastAdvertTime[iClient] < 180) {  // Don't set this any lower than 180 or you risk getting banned for spamming adverts.
		if (iTeam == 1 && g_fSpecAdvertPeriod > 0.0) {
			return Plugin_Continue;
		}
		
		g_bAttemptingAdvert[iClient] = false;
		return Plugin_Stop;
	}
	
	if (IsPlayerAlive(iClient) && iTeam > 1 && (!g_bPhase && !g_bFirstJoin[iClient] && !CheckGameSpecificConditions())) {
		return Plugin_Continue;
	}
	
	if (iTeam == 1 && g_fSpecAdvertPeriod > 0.0) {
		if (g_hSpecTimer[iClient] == null) {
			g_hSpecTimer[iClient] = CreateTimer(g_fSpecAdvertPeriod * 60.0, Timer_TryAdvert, iUserId, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	ShowAdvert(iClient, USERMSG_RELIABLE);
	
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
	
	int iDataUserId = g_dRadioPack[iClient].ReadCell();
	
	if (GetClientOfUserId(iDataUserId) != iClient || iDataUserId != iUserId) {
		delete g_dRadioPack[iClient];
		g_dRadioPack[iClient] = null;
		g_hRadioTimer[iClient] = null;
		
		return Plugin_Stop;
	}
	
	char szTitle[256]; char szUrl[256];
	
	g_dRadioPack[iClient].ReadString(szTitle, sizeof(szTitle));
	g_dRadioPack[iClient].ReadString(szUrl, sizeof(szUrl));
	
	if (g_bAttemptingAdvert[iClient]) {
		return Plugin_Continue;
	}
	
	ShowVGUIPanelEx(iClient, szTitle, szUrl, MOTDPANEL_TYPE_URL, 0, false);
	g_hRadioTimer[iClient] = null;
	
	return Plugin_Stop;
}

stock void ShowAdvert(int iClient, int iFlags = USERMSG_RELIABLE, Handle hMsg = null)
{
	if (g_bAdvertPlaying[iClient] || (g_iLastAdvertTime[iClient] > 0 && GetTime() - g_iLastAdvertTime[iClient] < 180) || IsClientImmune(iClient)) {  // Don't set this any lower than 180 or you risk getting banned for spamming adverts.
		return;
	}
	
	while (QueryClientConVar(iClient, "cl_disablehtmlmotd", Query_MotdCheck) < view_as<QueryCookie>(0)) {  }
	
	if (!IsValidClient(iClient)) {
		return;
	}
	
	TrimString(g_szAdvertUrl); StripQuotes(g_szAdvertUrl);
	
	if (g_bFirstJoin[iClient] && g_bForceJoinGame) {
		FakeClientCommandEx(iClient, "joingame"); // Fix the bug with team menu.
	}
	
	ShowVGUIPanelEx(iClient, "VPP Network Advertisement MOTD", g_szAdvertUrl, MOTDPANEL_TYPE_URL, iFlags, true, hMsg);
	CreateTimer(45.0, Timer_AdvertFinished, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
	
	g_iLastAdvertTime[iClient] = GetTime();
	g_iAdvertPlays[iClient]++;
	
	g_bFirstJoin[iClient] = false;
}

stock void ShowVGUIPanelEx(int iClient, const char[] szTitle, const char[] szUrl, int iType = MOTDPANEL_TYPE_URL, int iFlags = USERMSG_RELIABLE, bool bShow = true, Handle hMsg = null)
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
	
	char szKey[256]; char szValue[256];
	
	if (g_bProtoBuf) {
		PbSetString(hMsg, "name", "info");
		PbSetBool(hMsg, "show", bShow);
		
		Handle hSubKey;
		
		do {
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
	
	if (StringToInt(szCvarValue) > 0) {
		if (g_bKickMotd && !IsClientImmune(iClient)) {
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
	
	CPrintToChat(iClient, "%s%t", PREFIX, "Advert Finished");
	
	g_bAdvertPlaying[iClient] = false;
	ShowVGUIPanelEx(iClient, "Advert finished", "about:blank", MOTDPANEL_TYPE_URL, 0, false);
	
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

stock bool IsClientImmune(int iClient) 
{
	if(!g_bImmunityEnabled) {
		return false;
	}
	
	return CheckCommandAccess(iClient, "advertisement_immunity", ADMFLAG_ROOT);
}

stock bool CheckGameSpecificConditions()
{
	if (g_eVersion == Engine_CSGO) {
		if (GameRules_GetProp("m_bWarmupPeriod") == 1) {
			return true;
		}
	}
	
	return false;
}

stock bool RadioEntryExists(const char[] szEntry)
{
	int iRadioStations = g_alRadioStations.Length;
	
	if (iRadioStations <= 0) {
		return false;
	}
	
	char szBuffer[256];
	
	for (int i = 0; i < iRadioStations; i++) {
		g_alRadioStations.GetString(i, szBuffer, sizeof(szBuffer));
		
		
		if (StrEqual(szEntry, szBuffer, false)) {
			return true;
		}
	}
	
	return false;
}