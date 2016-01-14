#pragma semicolon 1

#include <sourcemod>
#include <dhooks>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "SM Franug Plugin list blocker",
	author = "Franc1sco steam: franug",
	description = "",
	version = "1.0",
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

public void OnPluginStart()
{    
	StartPlugin();
	//CreateTimer(0.3, Timer_RestartPlugin, TIMER_REPEAT);
}

/* public Action Timer_RestartPlugin(Handle timer)
{
	StartPlugin();
} */

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
			DHookSetParamString(hParams, 2, "If you want plugins of this server, then contact with Franc1sco steam: franug -> http://steamcommunity.com/id/franug\n");
			return MRES_ChangedHandled;
		}
	}
	return MRES_Ignored;
}  