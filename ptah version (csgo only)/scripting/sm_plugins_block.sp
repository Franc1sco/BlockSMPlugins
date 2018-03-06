/*  SM Franug Plugin list blocker
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <PTaH>

public Plugin:myinfo = 
{
	name = "SM Franug Plugin list blocker",
	author = "Franc1sco steam: franug",
	description = "",
	version = "1.5 (CSGO version)",
	url = "http://steamcommunity.com/id/franug"
};

#define INTERVAL 3

int g_iTime[MAXPLAYERS + 1] =  { -1, ... };

new String:g_sCmdLogPath[256];

ConVar cv_ban;

public void OnPluginStart()
{    
	LoadTranslations("sm_plugins_block.phrases.txt");
	
	cv_ban = CreateConVar("sm_plugins_block_ban", "-1", "Ban player? -1 = no ban, 0 = permanent, other value is ban time");
	
	PTaH(PTaH_ConsolePrint, Hook, ConsolePrint);
	PTaH(PTaH_ExecuteStringCommand, Hook, ExecuteStringCommand);
	
 	for(new i=0;;i++)
	{
		BuildPath(Path_SM, g_sCmdLogPath, sizeof(g_sCmdLogPath), "logs/blocksmplugins_%d.log", i);
		if ( !FileExists(g_sCmdLogPath) )
			break;
	}
}

public Action ConsolePrint(int client, char message[512])
{
	if(client == 0) return Plugin_Continue;
	
	if (IsClientValid(client) && GetUserFlagBits(client) & ADMFLAG_ROOT)
		return Plugin_Continue;
		
	if(message[1] == '"' && (StrContains(message, "\" (") != -1 || (StrContains(message, ".smx\" ") != -1)))
		return Plugin_Handled;
	else if(StrContains(message, "To see more, type \"sm plugins", false) != -1 || StrContains(message, "To see more, type \"sm exts", false) != -1)
	{
		if(g_iTime[client] == -1 || GetTime() - g_iTime[client] > INTERVAL)
		{
			PrintMSG(client, "sm plugins");
		}
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
	
}

public Action ExecuteStringCommand(int client, char message[512]) 
{
	if(client == 0) return Plugin_Continue;
	
	static char sMessage[512];
	sMessage = message;
	TrimString(sMessage);
		
	if (IsClientValid(client) && GetUserFlagBits(client) & ADMFLAG_ROOT)
			return Plugin_Continue;
		
	if(StrContains(sMessage, "sm ") == 0 || StrEqual(sMessage, "sm", false))
	{
		if(g_iTime[client] == -1 || GetTime() - g_iTime[client] > INTERVAL)
		{
			PrintMSG(client, "sm");
		}
		return Plugin_Handled;
	}
		
	if(StrContains(sMessage, "meta ") == 0 || StrEqual(sMessage, "meta", false))
	{
		if(g_iTime[client] == -1 || GetTime() - g_iTime[client] > INTERVAL)
		{
			PrintMSG(client, "meta");
		}
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

PrintMSG(client, const char[] command)
{
	if (!IsClientValid(client))return;
	
	char msg[128], msg2[128];
			
	Format(msg, 128, "%T", "NoChance", client);
	Format(msg2, 128, "[Franug Plugin list blocker] %s \n",msg);
				
	PrintToConsole(client, msg2);
			
	Format(msg2, 128, " \x04[Franug Plugin list blocker]\x01 %s \n",msg);
			
	PrintToChat(client, msg2);
			
	LogToFile(g_sCmdLogPath, "\"%L\" tried access to \"%s\"", client, command);
	
	int ban = GetConVarInt(cv_ban);
	if(ban > -1)
		ServerCommand("sm_ban #%d %i blocksm", GetClientUserId(client), ban);
}

bool IsClientValid(int client)
{
	if (client > 0 && client <= MaxClients)
		if (IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
			return true;
	return false;
}
