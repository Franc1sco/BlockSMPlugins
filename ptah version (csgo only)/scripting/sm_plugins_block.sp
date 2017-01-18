#pragma semicolon 1

#include <sourcemod>
#include <dhooks>
#include <sdktools>
#include <PTaH>

public Plugin:myinfo = 
{
	name = "SM Franug Plugin list blocker",
	author = "Franc1sco steam: franug",
	description = "",
	version = "1.3.2 (CSGO version)",
	url = "http://steamcommunity.com/id/franug"
};

#define INTERVAL 3

int g_iTime[MAXPLAYERS + 1] =  { -1, ... };

new String:g_sCmdLogPath[256];

public void OnPluginStart()
{    
	LoadTranslations("sm_plugins_block.phrases.txt");
	
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
	if (IsClientValid(client))
	{
		if (GetUserFlagBits(client) & ADMFLAG_ROOT)
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
	}
	return Plugin_Continue;
}

public Action ExecuteStringCommand(int client, char message[512]) 
{
	if (IsClientValid(client))
	{
		static char sMessage[512];
		sMessage = message;
		TrimString(sMessage);
		
		if (GetUserFlagBits(client) & ADMFLAG_ROOT)
				return Plugin_Continue;
		
		if(StrContains(sMessage, "sm ") != -1 || StrEqual(sMessage, "sm", false))
		{
			if(g_iTime[client] == -1 || GetTime() - g_iTime[client] > INTERVAL)
			{
				PrintMSG(client, "sm");
			}
			return Plugin_Handled;
		}
		
		if(StrContains(sMessage, "meta ") != -1 || StrEqual(sMessage, "meta", false))
		{
			if(g_iTime[client] == -1 || GetTime() - g_iTime[client] > INTERVAL)
			{
				PrintMSG(client, "meta");
			}
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue; 
}

PrintMSG(client, const char[] command)
{
	char msg[128], msg2[128];
			
	Format(msg, 128, "%T", "NoChance", client);
	Format(msg2, 128, "[Franug Plugin list blocker] %s \n",msg);
				
	PrintToConsole(client, msg2);
			
	Format(msg2, 128, " \x04[Franug Plugin list blocker]\x01 %s \n",msg);
			
	PrintToChat(client, msg2);
			
	LogToFile(g_sCmdLogPath, "\"%L\" tried access to \"%s\"", client, command);
}

bool IsClientValid(int client)
{
	if (client > 0 && client <= MaxClients)
		if (IsClientInGame(client) && !IsFakeClient(client) && !IsClientSourceTV(client))
			return true;
	return false;
}
