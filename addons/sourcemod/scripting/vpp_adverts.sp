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
						- Immunity now uses overrides, You can set this up by adding advertisement_immunity to admin_overrides.cfg.
					- Added old Cvar catcher (Thanks Pinion for the idea)
					- Replaced Cvar sm_vpp_immunity with sm_vpp_immunity_enabled
						- Set to 1 to prevent displaying ads to users with access to 'advertisement_immunity', Root flag is always immune.
			1.2.5 - 
					- Added Cvar sm_vpp_radio_resumation
						- When this Cvar is enabled, The radio will be resumed for players who recieve an ad while listening or attempting to start the radio. (Once the ad finishes).
						- This Cvar is enabled by default.
					- Added Cvar sm_vpp_messages
						- When this Cvar is enabled, Messages will be printed to clients.
							- This Cvar is enabled by default.
					- Overrides now makes reserve flag immune by default, You can change this by using advertisement_immunity inside admin_overrides.cfg.
					- General code cleanup.
			1.2.6 - 
					- Attempted to fix error, although if its not fixed, then this error is nothing serious.
					- Made setting sm_vpp_ad_total -1 exlude join adverts, (It will only affect periodic, spec & phase ads now) If you want to disable join adverts you can use sm_vpp_onjoin 0.
						- This is a lump total of all ads other than the join ad, once it has been reached then no more ads will play the client until he rejoins or map changes.
					- Made setting sm_vpp_ad_period 0 disable periodic adverts.
			1.2.7 - 
					- Fixed a regression with overriding Motd on ProtoBuf games.
					- Added Cvar sm_vpp_onjoin_type, 1 = Override Motd, 2 = Wait for team join.
						- If you have issues with method 1 then set this to method 2, It defaults at 1, in most cases you should leave this at 1.
			1.2.8 - 
					- Fixed team join getting stuck on CSCO and potentially on CSGO aswell.
					- Fixed Convar change hook for sm_vpp_onjoin_type.
					- Fixed SteamWorks support in Updater.
			1.2.9 - 
					- Added Cvar sm_vpp_wait_until_dead
						- When enabled the plugin will wait until the player is dead before playing an advert (Except first join).
						- This Cvar is disabled by default, If you run a gamemode where players don't die then you will want to leave this disabled.
			1.3.0 - 
					- Fixed radio resumation in cases where the radio was started before the advert started.
					- Fixed an issue where the periodic ad timer would repeat itself even when Periodic ads were disabled.
					- Added Cvar sm_vpp_every_x_deaths (Default 0) If you have a DM / Retakes / Arena or mod where the client dies a lot then you will want to leave this at 0.
						- This Cvar allows you to play adverts every time the client dies this many times, Please note that if the last ad was less than 3 mins it will it will wait until 3 mins have passed.
					- Added some developer stuff for people who want to play ads in various other scenarios.
						- Forward VPP_OnAdvertStarted(int iClient, const char[] szRadioResumeUrl);
						- Forward VPP_OnAdvertFinished(int iClient, const char[] szRadioResumeUrl);
						- Native BOOL VPP_PlayAdvert(int iClient) - Note to prevent spam it will delay the ad until 3 mins have passed since previous ad (If applicable)
						- Native BOOL VPP_IsAdvertPlaying(int iClient);
						
			1.3.1 - 
					- Rewrote Timer and advert logic to fix error and prevent useless handles being opened.
			1.3.2 - 
					- Fixed a missing ! which caused ads not to be played and nested the if statement.
					- Removed useless check which might of caused spectator ads not to play.
					- Fixed a bug where a new UserMessage was being created inside the hook instead of overriding the existing one.
			1.3.3 - 
					- Fixed invalid handle error spam.
					- Improved check before serving ad to make sure client is properly authorized and immunity checks are accurate.
					- Added notify option to as an alternative to kicking player for having html motd disabled, sm_vpp_kickmotd 1 = Kick, 2 = Notify, 0 = Do nothing.
					- Added min and max values to cvars and decreased default advert interval from 15 to 5 mins.
					- Increased advert play time to 60 seconds to improve completion rates.
					- Removed redirect to about:blank after advert as its now broken due to a CSGO update (and was not too important anyway).
			1.3.4 -
					- Fixed missing advert play times to improve completion rates.
			1.3.5 -
					- (IMPORTANT UPDATE) Fixed adverts not playing after first ad had started.
			1.3.6 	- (IMPORTANT UPDATE 2) Fixed intial advert not playing on games other than CSGO. 
					- This update is optional only if you run CSGO, if you run a game other than CSGO then its important!
			1.3.7   - Fix the remaining issues where ads would refuse to play regardless of the game.
					- Fixed the a few cvar min values (Thanks Rushy for reporting the issue.)
					- Changed how adverts play on phases -- 
						- If an advert was qued (Regardless of the trigger) it would either wait for the client to die or for a phase to start, It will now respect the value of sm_vpp_onphase.
						- For example if you have sm_vpp_onphase 0, It will continue waiting until the client dies before the qued advert starts, if however you set this to 1, it will supersede 
						sm_vpp_wait_until_dead and play regardless of if the client is alive or not. (Thanks to Rushy for bringing this to my attention.)
			1.3.8	- (IMPORTANT UPDATE 3) Fix advert interval cvar.
					
					
*****************************************************************************************************
*****************************************************************************************************
	INCLUDES
*****************************************************************************************************/
#include <sdktools>
#include <autoexecconfig>
#include <multicolors>
#include <vpp_adverts>

#undef REQUIRE_PLUGIN
#tryinclude <updater>

#define UPDATE_URL    "http://vppgamingnetwork.com/smplugin/update.txt"


/****************************************************************************************************
	DEFINES
*****************************************************************************************************/
#define PL_VERSION "1.3.8"
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
ConVar g_hCvarMotdCheck = null;
ConVar g_hCvarSpecAdvertPeriod = null;
ConVar g_hCvarRadioResumation = null;
ConVar g_hCvarMessages = null;
ConVar g_hCvarJoinType = null;
ConVar g_hCvarWaitUntilDead = null;
ConVar g_hCvarDeathAds = null;

Handle g_hFinishedTimer[MAXPLAYERS + 1] = null;
Handle g_hSpecTimer[MAXPLAYERS + 1] = null;
Handle g_hPeriodicTimer[MAXPLAYERS + 1] = null;
Handle g_hOnAdvertStarted = null;
Handle g_hOnAdvertFinished = null;

Menu g_mMenuWarning = null;

ArrayList g_alRadioStations = null;
EngineVersion g_eVersion = Engine_Unknown;

/****************************************************************************************************
	STRINGS.
*****************************************************************************************************/
char g_szAdvertUrl[256];
char g_szGameName[256];

char g_szTestedGames[][] =  {
	"csgo", 
	"csco", 
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

char g_szResumeUrl[MAXPLAYERS + 1][256];

/****************************************************************************************************
	BOOLS.
*****************************************************************************************************/
bool g_bFirstJoin[MAXPLAYERS + 1] = false;
bool g_bAdvertPlaying[MAXPLAYERS + 1] = false;
bool g_bJoinGame = false;
bool g_bProtoBuf = false;
bool g_bPhaseAds = false;
bool g_bPhase = false;
bool g_bGameTested = false;
bool g_bForceJoinGame = false;
bool g_bImmunityEnabled = false;
bool g_bRadioResumation = false;
bool g_bMessages = false;
bool g_bWaitUntilDead = false;
bool g_bAdvertQued[MAXPLAYERS + 1] = false;
bool g_bMotdDisabled[MAXPLAYERS + 1] = false;

/****************************************************************************************************
	INTS.
*****************************************************************************************************/
int g_iAdvertTotal = -1;
int g_iAdvertPlays[MAXPLAYERS + 1] = 0;
int g_iLastAdvertTime[MAXPLAYERS + 1] = 0;
int g_iJoinType = 1;
int g_iMotdOccurence[MAXPLAYERS + 1] = 0;
int g_iDeathAdCount = 0;
int g_iMotdAction = 0;

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
	
	AutoExecConfig_SetFile("plugin.vpp_adverts");
	
	g_hAdvertUrl = AutoExecConfig_CreateConVar("sm_vpp_url", "", "Put your VPP Advert Link here");
	g_hAdvertUrl.AddChangeHook(OnCvarChanged);
	
	g_hCvarJoinGame = AutoExecConfig_CreateConVar("sm_vpp_onjoin", "1", "Should advertisement be displayed to players on first team join?, 0 = Disabled.", _, true, 0.0, true, 1.0);
	g_hCvarJoinGame.AddChangeHook(OnCvarChanged);
	
	g_hCvarAdvertPeriod = AutoExecConfig_CreateConVar("sm_vpp_ad_period", "5", "How often the periodic adverts should be played (In Minutes), 0 = Disabled.", _, true, 0.0);
	g_hCvarAdvertPeriod.AddChangeHook(OnCvarChanged);
	
	g_hCvarSpecAdvertPeriod = AutoExecConfig_CreateConVar("sm_vpp_spec_ad_period", "3", "How often should ads be played to spectators (In Minutes), 0 = Disabled.", _, true, 0.0);
	g_hCvarSpecAdvertPeriod.AddChangeHook(OnCvarChanged);
	
	g_hCvarPhaseAds = AutoExecConfig_CreateConVar("sm_vpp_onphase", "1", "Should advertisement be displayed on game phases? (HalfTime, OverTime, MapEnd, WinPanels etc) (This will supersede sm_vpp_wait_until_dead) 0 = Disabled.", _, true, 0.0, true, 1.0);
	g_hCvarPhaseAds.AddChangeHook(OnCvarChanged);
	
	g_hCvarDeathAds = AutoExecConfig_CreateConVar("sm_vpp_every_x_deaths", "0", "Play an advert every time somebody dies this many times, 0 = Disabled.", _, true, 0.0);
	g_hCvarDeathAds.AddChangeHook(OnCvarChanged);
	
	g_hCvarAdvertTotal = AutoExecConfig_CreateConVar("sm_vpp_ad_total", "0", "How many adverts should be played in total (excluding join adverts)? 0 = Unlimited, -1 = Disabled.", _, true, -1.0);
	g_hCvarAdvertTotal.AddChangeHook(OnCvarChanged);
	
	g_hCvarImmunityEnabled = AutoExecConfig_CreateConVar("sm_vpp_immunity_enabled", "0", "Prevent displaying ads to users with access to 'advertisement_immunity', 0 = Disabled. (Default: Reservation Flag)", _, true, 0.0, true, 1.0);
	g_hCvarImmunityEnabled.AddChangeHook(OnCvarChanged);
	
	g_hCvarMotdCheck = AutoExecConfig_CreateConVar("sm_vpp_kickmotd", "0", "Action for player with html motd disabled, 0 = Disabled, 1 = Kick Player, 2 = Display notifications.", _, true, 0.0, true, 2.0);
	g_hCvarMotdCheck.AddChangeHook(OnCvarChanged);
	
	g_hCvarRadioResumation = AutoExecConfig_CreateConVar("sm_vpp_radio_resumation", "1", "Resume Radio after advertisement finishes, 0 = Disabled.", _, true, 0.0, true, 1.0);
	g_hCvarRadioResumation.AddChangeHook(OnCvarChanged);
	
	g_hCvarMessages = AutoExecConfig_CreateConVar("sm_vpp_messages", "1", "Show messages to clients, 0 = Disabled.", _, true, 0.0, true, 1.0);
	g_hCvarMessages.AddChangeHook(OnCvarChanged);
	
	g_hCvarJoinType = AutoExecConfig_CreateConVar("sm_vpp_onjoin_type", "1", "2 = Wait for team join, If you have issues with method 1 then set this to method 2, It defaults at 1, in most cases you should leave this at 1.", _, true, 1.0, true, 2.0);
	g_hCvarJoinType.AddChangeHook(OnCvarChanged);
	
	g_hCvarWaitUntilDead = AutoExecConfig_CreateConVar("sm_vpp_wait_until_dead", "0", "Wait until player is dead (Except first join) 0 = Disabled.", _, true, 0.0, true, 1.0);
	g_hCvarWaitUntilDead.AddChangeHook(OnCvarChanged);
	
	RegAdminCmd("sm_vppreload", Command_Reload, ADMFLAG_CONVARS, "Reloads radio stations");
	
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
	HookEventEx("round_start", Event_RoundStart, EventHookMode_Post);
	HookEventEx("player_team", Event_PlayerTeam, EventHookMode_Post);
	HookEventEx("player_death", Event_PlayerDeath, EventHookMode_Post);
	
	LoadTranslations("vppadverts.phrases.txt");
	
	UpdateConVars();
	AutoExecConfig_CleanFile(); AutoExecConfig_ExecuteFile();
	LoadRadioStations();
	
	
	#if defined _updater_included
	if (LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
	
	RegServerCmd("sm_vpp_immunity", OldCvarFound, "Outdated cvar, please update your config.");
	RegServerCmd("sm_vpp_ad_grace", OldCvarFound, "Outdated cvar, please update your config.");
	
	LoopValidClients(iClient) {
		OnClientPutInServer(iClient); g_bFirstJoin[iClient] = false;
	}
	
	g_hOnAdvertStarted = CreateGlobalForward("VPP_OnAdvertStarted", ET_Ignore, Param_Cell, Param_String);
	g_hOnAdvertFinished = CreateGlobalForward("VPP_OnAdvertFinished", ET_Ignore, Param_Cell, Param_String);
	
	CreateMotdMenu();
}

public APLRes AskPluginLoad2(Handle hNyself, bool bLate, char[] chError, int iErrMax)
{
	CreateNative("VPP_PlayAdvert", Native_PlayAdvert);
	CreateNative("VPP_IsAdvertPlaying", Native_IsAdvertPlaying);
	
	RegPluginLibrary("VPPAdverts");
	return APLRes_Success;
}

public int Native_IsAdvertPlaying(Handle hPlugin, int iNumParams) {
	int iClient = GetNativeCell(1);
	
	return g_bAdvertPlaying[iClient];
}

public int Native_PlayAdvert(Handle hPlugin, int iNumParams) {
	int iClient = GetNativeCell(1);
	
	if (HasClientFinishedAds(iClient) || g_bAdvertQued[iClient]) {
		return false;
	}
	
	while (QueryClientConVar(iClient, "cl_disablehtmlmotd", Query_MotdPlayAd, true) < view_as<QueryCookie>(0)) {  }
	
	if (!IsClientConnected(iClient)) {
		return false;
	}
	
	return !g_bMotdDisabled[iClient];
}

public Action OldCvarFound(int iArgs)
{
	if (iArgs != 1) {
		return Plugin_Handled;
	}
	
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
	
	LogError("After you have acknowledged the above message(s) and updated your config, you may completely remove the cvars to prevent this message displaying again.");
	
	return Plugin_Handled;
}

#if defined _updater_included
public void OnLibraryAdded(const char[] szName)
{
	if (StrEqual(szName, "updater")) {
		Updater_AddPlugin(UPDATE_URL);
	}
}
#endif

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
		
		if (g_fAdvertPeriod > 0.0 && g_fAdvertPeriod < 3.0) {
			g_fAdvertPeriod = 3.0;
			g_hCvarAdvertPeriod.IntValue = 3;
			
			if (g_fAdvertPeriod > 0.0) {
				LoopValidClients(iClient) {
					OnClientPutInServer(iClient); g_bFirstJoin[iClient] = false;
				}
			}
		}
	} else if (hConVar == g_hCvarAdvertTotal) {
		g_iAdvertTotal = StringToInt(szNewValue);
	} else if (hConVar == g_hCvarImmunityEnabled) {
		g_bImmunityEnabled = view_as<bool>(StringToInt(szNewValue));
		
		if (g_bImmunityEnabled) {
			LoopValidClients(iClient) {
				if (!CheckCommandAccess(iClient, "advertisement_immunity", ADMFLAG_RESERVATION)) {
					continue;
				}
				
				OnClientPutInServer(iClient);
			}
		}
	} else if (hConVar == g_hCvarSpecAdvertPeriod) {
		g_fSpecAdvertPeriod = StringToFloat(szNewValue);
		
		if (g_fSpecAdvertPeriod < 3.0 && g_fSpecAdvertPeriod > 0.0) {
			g_fSpecAdvertPeriod = 3.0;
		}
	} else if (hConVar == g_hCvarRadioResumation) {
		g_bRadioResumation = view_as<bool>(StringToInt(szNewValue));
	} else if (hConVar == g_hCvarWaitUntilDead) {
		g_bWaitUntilDead = view_as<bool>(StringToInt(szNewValue));
	} else if (hConVar == g_hCvarMessages) {
		g_bMessages = view_as<bool>(StringToInt(szNewValue));
	} else if (hConVar == g_hCvarJoinType) {
		g_iJoinType = StringToInt(szNewValue);
	} else if (hConVar == g_hCvarDeathAds) {
		g_iDeathAdCount = StringToInt(szNewValue);
	} else if (hConVar == g_hCvarMotdCheck) {
		g_iMotdAction = StringToInt(szNewValue);
	}
}

public void OnConfigsExecuted() {
	UpdateConVars();
}

public void UpdateConVars()
{
	g_bJoinGame = g_hCvarJoinGame.BoolValue;
	g_bPhaseAds = g_hCvarPhaseAds.BoolValue;
	g_bImmunityEnabled = g_hCvarImmunityEnabled.BoolValue;
	g_bRadioResumation = g_hCvarRadioResumation.BoolValue;
	g_bWaitUntilDead = g_hCvarWaitUntilDead.BoolValue;
	g_bMessages = g_hCvarMessages.BoolValue;
	g_iMotdAction = g_hCvarMotdCheck.IntValue;
	g_iJoinType = g_hCvarJoinType.IntValue;
	
	g_fAdvertPeriod = g_hCvarAdvertPeriod.FloatValue;
	g_fSpecAdvertPeriod = g_hCvarSpecAdvertPeriod.FloatValue;
	
	if (g_fAdvertPeriod > 0.0 && g_fAdvertPeriod < 3.0) {
		g_fAdvertPeriod = 3.0;
		g_hCvarAdvertPeriod.IntValue = 3;
	}
	
	if (g_fSpecAdvertPeriod < 3.0 && g_fSpecAdvertPeriod > 0.0) {
		g_fSpecAdvertPeriod = 3.0;
		g_hCvarSpecAdvertPeriod.IntValue = 3;
	}
	
	g_iDeathAdCount = g_hCvarDeathAds.IntValue;
	g_iAdvertTotal = g_hCvarAdvertTotal.IntValue;
	
	g_hAdvertUrl.GetString(g_szAdvertUrl, sizeof(g_szAdvertUrl));
}

public Action Command_Reload(int iClient, int iArgs)
{
	CReplyToCommand(iClient, "%s%t", PREFIX, "Radios Loaded", LoadRadioStations());
	return Plugin_Handled;
}

stock int LoadRadioStations()
{
	if (g_alRadioStations != null) {
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

public void OnClientPutInServer(int iClient)
{
	if (g_fAdvertPeriod > 0.0 && g_fAdvertPeriod < 3.0) {
		g_fAdvertPeriod = 3.0;
		g_hCvarAdvertPeriod.IntValue = 3;
	}
	
	if (g_fAdvertPeriod > 0.0) {
		if (g_hPeriodicTimer[iClient] != null) {
			delete g_hPeriodicTimer[iClient];
		}
		
		g_hPeriodicTimer[iClient] = CreateTimer(g_fAdvertPeriod * 60.0, Timer_IntervalAd, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
	
	strcopy(g_szResumeUrl[iClient], 128, "about:blank");
	
	if (!g_bJoinGame) {
		return;
	}
	
	g_bFirstJoin[iClient] = true;
	g_iMotdOccurence[iClient] = 0;
}

public Action OnVGUIMenu(UserMsg umId, Handle hMsg, const int[] iPlayers, int iPlayersNum, bool bReliable, bool bInit)
{
	int iClient = iPlayers[0];
	
	if (!IsValidClient(iClient)) {
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
	
	if (StrEqual(szUrl, "http://clanofdoom.co.uk/servers/motd/?id=radio")) {
		return Plugin_Handled;
	}
	
	if (StrEqual(szUrl, "motd")) {
		if (g_bProtoBuf) {
			if (g_iMotdOccurence[iClient] == 1) {
				if (g_iJoinType == 2 || AdShouldWait(iClient) || g_bMotdDisabled[iClient]) {
					VPP_PlayAdvert(iClient);
				} else {
					if (!ShowVGUIPanelEx(iClient, "VPP Network Advertisement MOTD", g_szAdvertUrl, MOTDPANEL_TYPE_URL, _, true, hMsg)) {
						VPP_PlayAdvert(iClient);
					} else {
						if (g_hFinishedTimer[iClient] == null) {
							g_hFinishedTimer[iClient] = CreateTimer(60.0, Timer_AdvertFinished, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
						}
						
						RequestFrame(Frame_AdvertStartedForward, GetClientUserId(iClient));
						g_bAdvertPlaying[iClient] = true;
					}
				}
				
				g_bFirstJoin[iClient] = false;
				
				return Plugin_Continue;
			}
		} else {
			switch (g_eVersion) {
				case Engine_Left4Dead, Engine_Left4Dead2, 19: {
					VPP_PlayAdvert(iClient);
					return Plugin_Handled;
				}
				
				default: {
					VPP_PlayAdvert(iClient);
				}
			}
		}
		
		g_iMotdOccurence[iClient]++;
		
		return Plugin_Continue;
	}
	
	bool bRadio = false;
	
	if (g_bRadioResumation) {
		char szBuffer[256];
		
		int iRadioStations = g_alRadioStations.Length;
		
		for (int i = 0; i < iRadioStations; i++) {
			g_alRadioStations.GetString(i, szBuffer, sizeof(szBuffer));
			
			if (StrContains(szUrl, szBuffer, false) != -1) {
				strcopy(g_szResumeUrl[iClient], 128, szUrl);
				bRadio = true;
				break;
			}
		}
	}
	
	if (StrEqual(szTitle, "VPP Network Advertisement MOTD") || StrEqual(szUrl, g_szAdvertUrl, false)) {
		if (g_hFinishedTimer[iClient] == null) {
			g_hFinishedTimer[iClient] = CreateTimer(60.0, Timer_AdvertFinished, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		if (g_bAdvertPlaying[iClient]) {
			return Plugin_Handled;
		}
		
		RequestFrame(Frame_AdvertStartedForward, GetClientUserId(iClient));
		
		g_bAdvertPlaying[iClient] = true;
		
		if (!g_bFirstJoin[iClient]) {
			g_iAdvertPlays[iClient]++;
		}
		
		g_bFirstJoin[iClient] = false;
		
		return Plugin_Continue;
	}
	
	if (g_bAdvertPlaying[iClient]) {
		if (bRadio || (!StrEqual(g_szResumeUrl[iClient], "", false) && !StrEqual(g_szResumeUrl[iClient], "about:blank", false)) && g_bRadioResumation) {
			
			strcopy(g_szResumeUrl[iClient], 128, szUrl);
			
			if (g_hFinishedTimer[iClient] == null) {
				g_hFinishedTimer[iClient] = CreateTimer(60.0, Timer_AdvertFinished, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE);
			}
			
			RequestFrame(PrintRadioMessage, GetClientUserId(iClient));
		} else {
			
			if (g_bFirstJoin[iClient] || g_iMotdOccurence[iClient] == 1) {
				strcopy(g_szResumeUrl[iClient], 128, szUrl);
			} else {
				RequestFrame(PrintMiscMessage, GetClientUserId(iClient));
			}
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void Frame_AdvertStartedForward(int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return;
	}
	
	Call_StartForward(g_hOnAdvertStarted);
	Call_PushCell(iClient);
	Call_PushString(g_szResumeUrl[iClient]);
	Call_Finish();
}

public void Frame_AdvertFinishedForward(int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return;
	}
	
	Call_StartForward(g_hOnAdvertFinished);
	Call_PushCell(iClient);
	Call_PushString(g_szResumeUrl[iClient]);
	Call_Finish();
}

public void PrintRadioMessage(int iUserId)
{
	if (!g_bMessages) {
		return;
	}
	
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return;
	}
	
	CPrintToChat(iClient, "%s%t", PREFIX, "Radio Message");
}

public void PrintMiscMessage(int iUserId)
{
	if (!g_bMessages) {
		return;
	}
	
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
	g_bAdvertPlaying[iClient] = false;
	g_bAdvertQued[iClient] = false;
	g_iMotdOccurence[iClient] = 0;
	
	if (g_hPeriodicTimer[iClient] != null && IsValidHandle(g_hPeriodicTimer[iClient])) {
		delete g_hPeriodicTimer[iClient];
	}
	
	g_hPeriodicTimer[iClient] = null;
	
	if (g_hFinishedTimer[iClient] != null && IsValidHandle(g_hPeriodicTimer[iClient])) {
		delete g_hFinishedTimer[iClient];
	}
	
	g_hFinishedTimer[iClient] = null;
	
	if (g_hSpecTimer[iClient] != null && IsValidHandle(g_hPeriodicTimer[iClient])) {
		delete g_hSpecTimer[iClient];
	}
	
	g_hSpecTimer[iClient] = null;
	
	strcopy(g_szResumeUrl[iClient], 128, "about:blank");
}

public void OnMapEnd() {
	g_bPhase = false;
}

public void OnMapStart() {
	g_bPhase = false;
}

public void Event_RoundStart(Event eEvent, char[] szEvent, bool bDontBroadcast) {
	g_bPhase = false;
}

public void Phase_Hooks(Event eEvent, char[] szEvent, bool bDontBroadcast)
{
	if (!g_bPhaseAds) {
		return;
	}
	
	g_bPhase = true;
	
	bool bShouldAdBeSent = false;
	
	if (StrEqual(g_szGameName, "cure")) {
		bShouldAdBeSent = eEvent.GetInt("wave") % 3 == 0;
	} else {
		bShouldAdBeSent = true;
	}
	
	if (!bShouldAdBeSent) {
		return;
	}
	
	LoopValidClients(iClient) {
		VPP_PlayAdvert(iClient);
	}
}

public Action Event_PlayerTeam(Event eEvent, char[] szEvent, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(eEvent.GetInt("userid"));
	int iTeam = eEvent.GetInt("team");
	bool bDisconnect = eEvent.GetBool("disconnect");
	
	if (bDisconnect || !IsClientConnected(iClient)) {
		return Plugin_Continue;
	}
	
	if (iTeam == 1 && g_fSpecAdvertPeriod > 0.0) {
		VPP_PlayAdvert(iClient);
	} else if (g_hSpecTimer[iClient] != null) {
		delete g_hSpecTimer[iClient];
	}
	
	return Plugin_Continue;
}

public void Event_PlayerDeath(Event evEvent, char[] szEvent, bool bDontBroadcast)
{
	if (CheckGameSpecificConditions()) {
		return;
	}
	
	int iClient = GetClientOfUserId(evEvent.GetInt("userid"));
	int iDeathCount = GetClientDeaths(iClient);
	
	if (g_iDeathAdCount > 0) {
		if (iDeathCount % g_iDeathAdCount == 0) {
			VPP_PlayAdvert(iClient);
		}
	}
}

public Action Timer_IntervalAd(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return Plugin_Stop;
	}
	
	VPP_PlayAdvert(iClient);
	
	return Plugin_Continue;
}

public Action Timer_PlayAdvert(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		if (iClient > -1 && iClient <= MaxClients) {
			g_hSpecTimer[iClient] = null;
			g_hPeriodicTimer[iClient] = null;
		}
		
		return Plugin_Stop;
	}
	
	if (HasClientFinishedAds(iClient)) {
		if (hTimer == g_hSpecTimer[iClient]) {
			g_hSpecTimer[iClient] = null;
		} else if (hTimer == g_hPeriodicTimer[iClient]) {
			g_hPeriodicTimer[iClient] = null;
		}
		
		return Plugin_Stop;
	}
	
	if (g_bAdvertPlaying[iClient] || g_hFinishedTimer[iClient] != null) {
		if (hTimer == g_hSpecTimer[iClient] || hTimer == g_hPeriodicTimer[iClient]) {
			return Plugin_Continue;
		}
		
		return Plugin_Stop;
	}
	
	if (AdShouldWait(iClient)) {
		g_bAdvertQued[iClient] = hTimer != g_hSpecTimer[iClient] && hTimer != g_hPeriodicTimer[iClient];
		
		if (!g_bAdvertQued[iClient]) {
			VPP_PlayAdvert(iClient);
		}
		
		return Plugin_Continue;
	}
	
	if (IsClientImmune(iClient)) {
		g_hSpecTimer[iClient] = null;
		g_hPeriodicTimer[iClient] = null;
		
		return Plugin_Stop;
	}
	
	ShowVGUIPanelEx(iClient, "VPP Network Advertisement MOTD", g_szAdvertUrl, MOTDPANEL_TYPE_URL, _, true);
	
	int iTeam = GetClientTeam(iClient);
	
	if (hTimer == g_hPeriodicTimer[iClient]) {
		return Plugin_Continue;
	} else if (iTeam == 1 && g_fSpecAdvertPeriod > 0.0) {
		if (g_hSpecTimer[iClient] == null) {
			g_hSpecTimer[iClient] = CreateTimer(g_fSpecAdvertPeriod * 60.0, Timer_PlayAdvert, iUserId, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		}
		
		return Plugin_Continue;
		
	} else if (iTeam != 1 && g_hSpecTimer[iClient] != null && hTimer != g_hSpecTimer[iClient]) {
		delete g_hSpecTimer[iClient];
	}
	
	return Plugin_Stop;
}

stock bool ShowVGUIPanelEx(int iClient, const char[] szTitle, const char[] szUrl, int iType = MOTDPANEL_TYPE_URL, int iFlags = 0, bool bShow = true, Handle hMsg = null, bool bAdvert = true)
{
	if (bAdvert) {
		g_bAdvertQued[iClient] = false;
		
		if (AdShouldWait(iClient) || HasClientFinishedAds(iClient) || IsClientImmune(iClient)) {
			return false;
		}
		
		while (QueryClientConVar(iClient, "cl_disablehtmlmotd", Query_MotdPlayAd, false) < view_as<QueryCookie>(0)) {  }
		
		if (!IsClientConnected(iClient)) {
			return false;
		}
	}
	
	if (g_bMotdDisabled[iClient]) {
		return false;
	}
	
	TrimString(g_szAdvertUrl); StripQuotes(g_szAdvertUrl);
	
	if (g_bFirstJoin[iClient] && g_bForceJoinGame) {
		FakeClientCommandEx(iClient, "joingame");
	}
	
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
		if (!bOverride) {
			PbSetString(hMsg, "name", "info");
			PbSetBool(hMsg, "show", bShow);
		}
		
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
	
	if (bAdvert) {
		g_iLastAdvertTime[iClient] = GetTime();
	}
	
	return true;
}

public void Query_MotdPlayAd(QueryCookie qCookie, int iClient, ConVarQueryResult cqResult, const char[] szCvarName, const char[] szCvarValue, bool bPlayAd)
{
	if (!IsValidClient(iClient)) {
		return;
	}
	
	if (IsClientImmune(iClient)) {
		return;
	}
	
	if (StringToInt(szCvarValue) > 0) {
		g_bMotdDisabled[iClient] = true;
		
		if (g_iMotdAction == 1) {
			KickClient(iClient, "%t", "Kick Message");
		} else if (g_iMotdAction == 2) {
			PrintHintText(iClient, "%t", "Menu_Title");
			g_mMenuWarning.Display(iClient, 10);
		}
	} else {
		if (bPlayAd) {
			CreateTimer(0.0, Timer_PlayAdvert, GetClientUserId(iClient), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
		}
		
		g_bMotdDisabled[iClient] = false;
	}
}

public void CreateMotdMenu()
{
	if (g_mMenuWarning != null) {
		return;
	}
	
	char szBuffer[128];
	
	g_mMenuWarning = new Menu(MenuHandler);
	
	Format(szBuffer, sizeof(szBuffer), "%t", "Menu_Title");
	
	g_mMenuWarning.SetTitle(szBuffer);
	g_mMenuWarning.Pagination = MENU_NO_PAGINATION;
	g_mMenuWarning.ExitBackButton = false;
	g_mMenuWarning.ExitButton = false;
	
	Format(szBuffer, sizeof(szBuffer), "%t", "Menu_Phrase_0");
	g_mMenuWarning.AddItem("", szBuffer, ITEMDRAW_DISABLED);
	
	Format(szBuffer, sizeof(szBuffer), "%t", "Menu_Phrase_1");
	g_mMenuWarning.AddItem("", szBuffer, ITEMDRAW_DISABLED);
	
	Format(szBuffer, sizeof(szBuffer), "%t", "Menu_Phrase_2");
	g_mMenuWarning.AddItem("", szBuffer, ITEMDRAW_DISABLED);
	
	Format(szBuffer, sizeof(szBuffer), "%t", "Menu_Phrase_Exit");
	g_mMenuWarning.AddItem("0", szBuffer);
}

public int MenuHandler(Menu mMenu, MenuAction maAction, int iParam1, int iParam2) {  }

public Action Timer_AdvertFinished(Handle hTimer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (!IsValidClient(iClient)) {
		return Plugin_Stop;
	}
	
	if (!g_bAdvertPlaying[iClient]) {
		return Plugin_Stop;
	}
	
	if (g_bMessages) {
		CPrintToChat(iClient, "%s%t", PREFIX, "Advert Finished");
	}
	
	g_bAdvertPlaying[iClient] = false;
	
	if (g_bRadioResumation && !StrEqual(g_szResumeUrl[iClient], "about:blank", false) && !StrEqual(g_szResumeUrl[iClient], "", false)) {
		ShowVGUIPanelEx(iClient, "Radio Resumation", g_szResumeUrl[iClient], MOTDPANEL_TYPE_URL, 0, false, null, false);
	}
	
	RequestFrame(Frame_AdvertFinishedForward, GetClientUserId(iClient));
	
	g_hFinishedTimer[iClient] = null;
	
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

stock bool IsClientImmune(int iClient)
{
	if (!IsClientConnected(iClient)) {
		return true;
	}
	
	if (!g_bImmunityEnabled) {
		return false;
	}
	
	return CheckCommandAccess(iClient, "advertisement_immunity", ADMFLAG_RESERVATION);
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

stock bool AdShouldWait(int iClient)
{
	char szAuthId[64];
	
	if (!IsClientAuthorized(iClient) || !GetClientAuthId(iClient, AuthId_Steam2, szAuthId, 64, true)) {
		return true;
	}
	
	if (StrEqual(szAuthId, "STEAM_ID_PENDING", false)) {
		return true;
	}
	
	if (g_hFinishedTimer[iClient] != null) {
		return true;
	}
	
	int iTeam = GetClientTeam(iClient);
	
	if (iTeam < 1 && (g_eVersion == Engine_DODS || (g_bFirstJoin[iClient] && g_iJoinType == 2))) {
		return true;
	}
	
	if (g_bWaitUntilDead && IsPlayerAlive(iClient) && iTeam > 1 && (!g_bPhase && !g_bFirstJoin[iClient] && !CheckGameSpecificConditions())) {
		return true;
	}
	
	if (g_bAdvertPlaying[iClient] || g_hFinishedTimer[iClient] != null || (g_iLastAdvertTime[iClient] > 0 && GetTime() - g_iLastAdvertTime[iClient] < 180)) {
		return true;
	}
	
	return false;
}

stock bool HasClientFinishedAds(int iClient)
{
	if (g_iAdvertTotal > 0 && !g_bFirstJoin[iClient] && g_iAdvertPlays[iClient] >= g_iAdvertTotal) {
		return true;
	}
	
	if (g_iAdvertTotal <= -1 && !g_bFirstJoin[iClient]) {
		return true;
	}
	
	if (!g_bFirstJoin[iClient] && g_fAdvertPeriod <= 0.0 && g_iDeathAdCount <= 0) {
		return true;
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