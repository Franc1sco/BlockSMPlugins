#pragma semicolon 1

#include <sourcemod>
#include <dhooks>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "SM Franug Plugin list blocker",
	author = "Franc1sco steam: franug",
	description = "",
	version = "1.3.1",
	url = "http://steamcommunity.com/id/franug"
};

char Triggers[][] = { 
	"To see running plugins, type \"sm plugins", 
	"To see credits, type \"sm credits", 
	"SourceMod would not be possible without:",
	"by AlliedModders LLC",
	"David \"BAILOPAN\" Anderson, Matt \"pRED\" Woodrow",
	"Scott \"DS\" Ehlert, Fyren",
	"Nicholas \"psychonic\" Hastings, Asher \"asherkin\" Baker",
	"Borja \"faluco\" Ferrer, Pavol \"PM OnoTo\" Marko"
};

char Triggers2[][] = { 
	"To see more, type \"sm plugins", 
	"To see more, type \"sm exts", 
	"SourceMod is open source under the GNU General Public License.",
	"Visit http://www.sourcemod.net/"
};

Handle hClientPrintf = null;
new String:g_sCmdLogPath[256];

public void OnPluginStart()
{    
	LoadTranslations("sm_plugins_block.phrases.txt");
	
 	for(new i=0;;i++)
	{
		BuildPath(Path_SM, g_sCmdLogPath, sizeof(g_sCmdLogPath), "logs/blocksmplugins_%d.log", i);
		if ( !FileExists(g_sCmdLogPath) )
			break;
	}
	
	StartPlugin();
	CreateTimer(5.0, Timer_RestartPlugin, _, TIMER_REPEAT);
}

public Action Timer_RestartPlugin(Handle timer)
{
	StartPlugin();
}

stock void StartPlugin()
{
	Handle gameconf = LoadGameConfigFile("clientprintf-hook.games");
	if(gameconf == null)
		SetFailState("Failed to find clientprintf-hook.games.txt gamedata");
	
	int offset = GameConfGetOffset(gameconf, "ClientPrintf");
	if(offset == -1)
	{
		SetFailState("Failed to find offset for ClientPrintf");
		delete gameconf;
	}
	
	StartPrepSDKCall(SDKCall_Static);
	
	if(!PrepSDKCall_SetFromConf(gameconf, SDKConf_Signature, "CreateInterface"))
	{
		SetFailState("Failed to get CreateInterface");
		delete gameconf;
	}
	
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	char identifier[64];
	if(!GameConfGetKeyValue(gameconf, "EngineInterface", identifier, sizeof(identifier)))
	{
		SetFailState("Failed to get engine identifier name");
		delete gameconf;
	}
	
	Handle temp = EndPrepSDKCall();
	Address addr = SDKCall(temp, identifier, 0);
	
	delete gameconf;
	delete temp;
	
	if(!addr)
		SetFailState("Failed to get engine ptr");
	
	hClientPrintf = DHookCreate(offset, HookType_Raw, ReturnType_Void, ThisPointer_Ignore, Hook_ClientPrintf);
	DHookAddParam(hClientPrintf, HookParamType_Edict);
	DHookAddParam(hClientPrintf, HookParamType_CharPtr);
	DHookRaw(hClientPrintf, false, addr);
}

public MRESReturn Hook_ClientPrintf(Handle hParams)
{
	int client = DHookGetParam(hParams, 1);
	
	if(client < 1 || !IsClientInGame(client)) return MRES_Ignored;
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT) return MRES_Ignored;
	
	char buffer[1024];
	DHookGetParamString(hParams, 2, buffer, 1024);
	if(buffer[1] == '"' && (StrContains(buffer, "\" (") != -1 || (StrContains(buffer, ".smx\" ") != -1))) 
	{
		DHookSetParamString(hParams, 2, "");
		return MRES_ChangedHandled;
	}
	for(new i = 0; i < sizeof(Triggers); i++)
	{
		if (StrContains(buffer, Triggers[i], false) != -1)
		{
			DHookSetParamString(hParams, 2, "");
			return MRES_ChangedHandled;
		}
	}
	for(new i = 0; i < sizeof(Triggers2); i++)
	{
		if (StrContains(buffer, Triggers2[i], false) != -1)
		{
			char msg[128], msg2[128];
			
			Format(msg, 128, "%T", "NoChance", client);
			Format(msg2, 128, "[Franug Plugin list blocker] %s \n",msg);
			
			DHookSetParamString(hParams, 2, msg2);
			
			Format(msg2, 128, " \x04[Franug Plugin list blocker]\x01 %s \n",msg);
			
			PrintToChat(client, msg2);
			
			LogToFileEx(g_sCmdLogPath, "%L used the command.", client);
			return MRES_ChangedHandled;
		}
	}
	return MRES_Ignored;
}  