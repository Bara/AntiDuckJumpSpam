#pragma semicolon 1

#include <sourcemod>
#include <autoexecconfig>

#undef REQUIRE_PLUGIN
#include <updater>

#define ADJS_VERSION "1.0.2"

#define UPDATE_URL    "https://bara.in/update/antiduckjumpspam.txt"

new g_iDuck[MAXPLAYERS+1] = {0,...};
new bool:g_bDuck[MAXPLAYERS+1] = {false,...};
new Handle:g_hAllowDuck = INVALID_HANDLE;
new Handle:g_hRestrictDuck = INVALID_HANDLE;
new Handle:g_hResetDuck = INVALID_HANDLE;
new Handle:g_hDuckEnable = INVALID_HANDLE;
new Handle:g_hDuckPerma = INVALID_HANDLE;
new Handle:g_hDuckTeam = INVALID_HANDLE;
new Handle:g_hDuckTimer[MAXPLAYERS+1] = {INVALID_HANDLE,...};
new Handle:g_hDuckReset[MAXPLAYERS+1] = {INVALID_HANDLE,...};

new g_iJumps[MAXPLAYERS+1] = {0,...};
new bool:g_bJump[MAXPLAYERS+1] = {false,...};
new bool:g_bIsDuck[MAXPLAYERS+1] = {false,...};
new Handle:g_hAllowJumps = INVALID_HANDLE;
new Handle:g_hRestrictJump = INVALID_HANDLE;
new Handle:g_hResetJumps = INVALID_HANDLE;
new Handle:g_hJumpEnable = INVALID_HANDLE;
new Handle:g_hJumpPerma = INVALID_HANDLE;
new Handle:g_hJumpTeam = INVALID_HANDLE;
new Handle:g_hJumpTimer[MAXPLAYERS+1] = {INVALID_HANDLE,...};
new Handle:g_hJumpReset[MAXPLAYERS+1] = {INVALID_HANDLE,...};

public Plugin:myinfo = 
{
	name = "Anti Duck/Jump Spam",
	author = "Bara",
	description = "Block jump and duck spam",
	version = ADJS_VERSION,
	url = "www.bara.in"
}

public OnPluginStart()
{
	CreateConVar("adjs_version", ADJS_VERSION, "Anti Duck Jump Spam", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	AutoExecConfig_SetFile("plugin.anti_duckjump_spam");
	AutoExecConfig_SetCreateFile(true);

	g_hJumpEnable = AutoExecConfig_CreateConVar("anti_jump_enable", "1", "Anti jump enable = 1; disable = 0", _, true, 0.0, true, 1.0);
	g_hJumpPerma = AutoExecConfig_CreateConVar("anti_jump_perma", "0", "If anti jump should be permanent enabled set this to 1", _, true, 0.0, true, 1.0);
	g_hAllowJumps = AutoExecConfig_CreateConVar("anti_jump_count", "3", "After how many jumps, jumping is blocked for X (anti_jump_time) seconds?");
	g_hRestrictJump = AutoExecConfig_CreateConVar("anti_jump_time", "3.0", "Set jump block time in seconds");
	g_hResetJumps = AutoExecConfig_CreateConVar("anti_jump_reset", "5.0", "After how many seconds jumps will reset to zero, if anti_jump_count were not reached?");
	g_hJumpTeam = AutoExecConfig_CreateConVar("anti_jump_team", "1", "Which team should not be allowed to jump? 0 - Disables; 1 - Both; 2 - Terrorist; 3 - Counter-Terrorist");

	g_hDuckEnable = AutoExecConfig_CreateConVar("anti_duck_enable", "1", "Anti duck enable = 1; disable = 0", _, true, 0.0, true, 1.0);
	g_hDuckPerma = AutoExecConfig_CreateConVar("anti_duck_perma", "0", "If anti duck should be permanent enabled set this to 1", _, true, 0.0, true, 1.0);
	g_hAllowDuck = AutoExecConfig_CreateConVar("anti_duck_count", "3", "After how many ducks, duck is blocked for X (anti_duck_time) seconds?");
	g_hRestrictDuck = AutoExecConfig_CreateConVar("anti_duck_time", "3.0", "Set duck block time in seconds");
	g_hResetDuck = AutoExecConfig_CreateConVar("anti_duck_reset", "3.0", "After how many seconds ducks will reset to zero, if anti_duck_count were not reached?");
	g_hDuckTeam = AutoExecConfig_CreateConVar("anti_duck_team", "1", "Which team should not be allowed to duck? 0 - Disables; 1 - Both; 2 - Terrorist; 3 - Counter-Terrorist");

	AutoExecConfig_CleanFile();
	AutoExecConfig_ExecuteFile();

	HookEvent("player_jump", Event_PlayerJump);
	HookEvent("player_spawn", Event_PlayerSpawn);

	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnClientDisconnect(client)
{
	Reset(client);
	ResetTimers(client);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	Reset(client);
	ResetTimers(client);
	
	return Plugin_Continue;
}

public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_hJumpEnable))
	{
		if(!GetConVarInt(g_hJumpPerma))
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));

			if(GetConVarInt(g_hJumpTeam) == 1 || GetConVarInt(g_hJumpTeam) == GetClientTeam(client))
			{
				g_iJumps[client]++;

				if(g_hJumpReset[client] == INVALID_HANDLE)
				{
					g_hJumpReset[client] = CreateTimer(GetConVarFloat(g_hResetJumps), Timer_ResetJump2, client);
				}

				if(g_iJumps[client] == GetConVarInt(g_hAllowJumps))
				{
					g_bJump[client] = true;
					g_hJumpTimer[client] = CreateTimer(GetConVarFloat(g_hRestrictJump), Timer_ResetJump, client);
				}
			}
		}
	}
	
	return Plugin_Handled;
}

public Action:Timer_ResetJump(Handle:timer, any:client)
{
	g_bJump[client] = false;
	g_iJumps[client] = 0;
	g_hJumpTimer[client] = INVALID_HANDLE;
}

public Action:Timer_ResetJump2(Handle:timer, any:client)
{
	g_iJumps[client] = 0;
	g_hJumpReset[client] = INVALID_HANDLE;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(buttons & IN_JUMP)
	{
		if(GetConVarInt(g_hJumpEnable))
		{
			if(GetConVarInt(g_hJumpPerma))
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
		if(GetConVarInt(g_hDuckEnable))
		{
			if(GetConVarInt(g_hDuckTeam) == 1 || GetConVarInt(g_hDuckTeam) == GetClientTeam(client))
			{
				if(GetConVarInt(g_hDuckPerma))
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
		{
			g_iDuck[client]++;
		}
		
		if(g_hDuckReset[client] == INVALID_HANDLE)
		{
			g_hDuckReset[client] = CreateTimer(GetConVarFloat(g_hResetDuck), Timer_ResetDuck2, client);
		}

		if(g_iDuck[client] == GetConVarInt(g_hAllowDuck))
		{
			g_bDuck[client] = true;
			g_iDuck[client] = 0;
			g_hDuckTimer[client] = CreateTimer(GetConVarFloat(g_hRestrictDuck), Timer_ResetDuck, client);
		}
	}
	return Plugin_Continue;
}

public Action:Timer_ResetDuck(Handle:timer, any:client)
{
	g_bDuck[client] = false;
	g_iDuck[client] = 0;

	g_hDuckTimer[client] = INVALID_HANDLE;
}

public Action:Timer_ResetDuck2(Handle:timer, any:client)
{
	g_iDuck[client] = 0;

	g_hDuckReset[client] = INVALID_HANDLE;
}

stock Reset(client)
{
	g_bDuck[client] = false;
	g_iDuck[client] = 0;

	g_bJump[client] = false;
	g_iJumps[client] = 0;
}

stock ResetTimers(client)
{
	if(g_hJumpTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hJumpTimer[client]);
		g_hJumpTimer[client] = INVALID_HANDLE;
	}

	if(g_hJumpReset[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hJumpReset[client]);
		g_hJumpReset[client] = INVALID_HANDLE;
	}

	if(g_hDuckTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hDuckTimer[client]);
		g_hDuckTimer[client] = INVALID_HANDLE;
	}

	if(g_hDuckReset[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hDuckReset[client]);
		g_hDuckReset[client] = INVALID_HANDLE;
	}
}