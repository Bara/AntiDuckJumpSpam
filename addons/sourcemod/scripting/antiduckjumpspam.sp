#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

#define ADJS_NAME "Anti Duck/Jump Spam"
#define ADJS_VERSION "1.0.2"

#define UPDATE_URL    "https://bara.in/update/antiduckjumpspam.txt"

int g_iDuck[MAXPLAYERS+1] = {0,...};
bool g_bDuck[MAXPLAYERS+1] = {false,...};
ConVar g_cAllowDuck = null;
ConVar g_cRestrictDuck = null;
ConVar g_cResetDuck = null;
ConVar g_cDuckEnable = null;
ConVar g_cDuckPerma = null;
ConVar g_cDuckTeam = null;
Handle g_cDuckTimer[MAXPLAYERS+1] = {null,...};
Handle g_cDuckReset[MAXPLAYERS+1] = {null,...};

int g_iJumps[MAXPLAYERS+1] = {0,...};
bool g_bJump[MAXPLAYERS+1] = {false,...};
bool g_bIsDuck[MAXPLAYERS+1] = {false,...};
ConVar g_cAllowJumps = null;
ConVar g_cRestrictJump = null;
ConVar g_cResetJumps = null;
ConVar g_cJumpEnable = null;
ConVar g_cJumpPerma = null;
ConVar g_cJumpTeam = null;
Handle g_cJumpTimer[MAXPLAYERS+1] = {null,...};
Handle g_cJumpReset[MAXPLAYERS+1] = {null,...};

public Plugin myinfo = 
{
	name = ADJS_NAME,
	author = "Bara",
	description = "Block jump and duck spam",
	version = ADJS_VERSION,
	url = "www.bara.in"
}

public void OnPluginStart()
{
	CreateConVar("adjs_version", ADJS_VERSION, ADJS_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_cJumpEnable = CreateConVar("anti_jump_enable", "1", "Anti jump enable = 1; disable = 0", _, true, 0.0, true, 1.0);
	g_cJumpPerma = CreateConVar("anti_jump_perma", "0", "If anti jump should be permanent enabled set this to 1", _, true, 0.0, true, 1.0);
	g_cAllowJumps = CreateConVar("anti_jump_count", "3", "After how many jumps, jumping is blocked for X (anti_jump_time) seconds?");
	g_cRestrictJump = CreateConVar("anti_jump_time", "3.0", "Set jump block time in seconds");
	g_cResetJumps = CreateConVar("anti_jump_reset", "5.0", "After how many seconds jumps will reset to zero, if anti_jump_count were not reached?");
	g_cJumpTeam = CreateConVar("anti_jump_team", "1", "Which team should not be allowed to jump? 0 - Disables; 1 - Both; 2 - Terrorist; 3 - Counter-Terrorist");

	g_cDuckEnable = CreateConVar("anti_duck_enable", "1", "Anti duck enable = 1; disable = 0", _, true, 0.0, true, 1.0);
	g_cDuckPerma = CreateConVar("anti_duck_perma", "0", "If anti duck should be permanent enabled set this to 1", _, true, 0.0, true, 1.0);
	g_cAllowDuck = CreateConVar("anti_duck_count", "3", "After how many ducks, duck is blocked for X (anti_duck_time) seconds?");
	g_cRestrictDuck = CreateConVar("anti_duck_time", "3.0", "Set duck block time in seconds");
	g_cResetDuck = CreateConVar("anti_duck_reset", "3.0", "After how many seconds ducks will reset to zero, if anti_duck_count were not reached?");
	g_cDuckTeam = CreateConVar("anti_duck_team", "1", "Which team should not be allowed to duck? 0 - Disables; 1 - Both; 2 - Terrorist; 3 - Counter-Terrorist");

	AutoExecConfig();

	HookEvent("player_jump", Event_PlayerJump);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnClientDisconnect(int client)
{
	Reset(client);
	ResetTimers(client);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	Reset(client);
	ResetTimers(client);
	
	return Plugin_Continue;
}

public Action Event_PlayerJump(Event event, const char[] name, bool dontBroadcast)
{
	if(g_cJumpEnable.BoolValue)
	{
		if(!g_cJumpPerma.BoolValue)
		{
			int client = GetClientOfUserId(event.GetInt("userid"));

			if(g_cJumpTeam.IntValue == 1 || g_cJumpTeam.IntValue == GetClientTeam(client))
			{
				g_iJumps[client]++;

				if(g_cJumpReset[client] == null)
				{
					g_cJumpReset[client] = CreateTimer(g_cResetJumps.FloatValue, Timer_ResetJump2, client);
				}

				if(g_iJumps[client] == GetConVarInt(g_cAllowJumps))
				{
					g_bJump[client] = true;
					g_cJumpTimer[client] = CreateTimer(g_cRestrictJump.FloatValue, Timer_ResetJump, client);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Timer_ResetJump(Handle timer, any client)
{
	g_bJump[client] = false;
	g_iJumps[client] = 0;
	g_cJumpTimer[client] = null;
}

public Action Timer_ResetJump2(Handle timer, any client)
{
	g_iJumps[client] = 0;
	g_cJumpReset[client] = null;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(buttons & IN_JUMP)
	{
		if(g_cJumpEnable.BoolValue)
		{
			if(g_cJumpPerma.BoolValue)
			{
				buttons &= ~IN_JUMP;
				return Plugin_Changed;
			}

			if(g_bJump[client])
			{
				buttons &= ~IN_JUMP;
				return Plugin_Changed;
			}
		}
	}
	if(buttons & IN_DUCK)
	{
		if(g_cDuckEnable.BoolValue)
		{
			if(g_cDuckTeam.IntValue == 1 || g_cDuckTeam.IntValue == GetClientTeam(client))
			{
				if(g_cDuckPerma.BoolValue)
				{
					buttons &= ~IN_DUCK;
					return Plugin_Changed;
				}
				
				g_bIsDuck[client] = true;

				if(g_bDuck[client])
				{
					buttons &= ~IN_DUCK;
					return Plugin_Changed;
				}
			}
		}
	}
	else if(g_bIsDuck[client])
	{
		g_bIsDuck[client] = false;

		if(!g_bDuck[client])
			g_iDuck[client]++;
		
		if(g_cDuckReset[client] == null)
			g_cDuckReset[client] = CreateTimer(g_cResetDuck.FloatValue, Timer_ResetDuck2, client);

		if(g_iDuck[client] == GetConVarInt(g_cAllowDuck))
		{
			g_bDuck[client] = true;
			g_iDuck[client] = 0;
			g_cDuckTimer[client] = CreateTimer(g_cRestrictDuck.FloatValue, Timer_ResetDuck, client);
		}
	}
	return Plugin_Continue;
}

public Action Timer_ResetDuck(Handle timer, any client)
{
	g_bDuck[client] = false;
	g_iDuck[client] = 0;
	g_cDuckTimer[client] = null;
}

public Action Timer_ResetDuck2(Handle timer, any client)
{
	g_iDuck[client] = 0;
	g_cDuckReset[client] = null;
}

void Reset(int client)
{
	g_bDuck[client] = false;
	g_iDuck[client] = 0;

	g_bJump[client] = false;
	g_iJumps[client] = 0;
}

void ResetTimers(int client)
{
	if(g_cJumpTimer[client] != null)
	{
		CloseHandle(g_cJumpTimer[client]);
		g_cJumpTimer[client] = null;
	}

	if(g_cJumpReset[client] != null)
	{
		CloseHandle(g_cJumpReset[client]);
		g_cJumpReset[client] = null;
	}

	if(g_cDuckTimer[client] != null)
	{
		CloseHandle(g_cDuckTimer[client]);
		g_cDuckTimer[client] = null;
	}

	if(g_cDuckReset[client] != null)
	{
		CloseHandle(g_cDuckReset[client]);
		g_cDuckReset[client] = null;
	}
}