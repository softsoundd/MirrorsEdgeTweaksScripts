/**
 * Dedicated class just for spam macros (speedrun legal since cheats are stripped).
 * Also has the mutual exclusivity between interact and grab macros. MirrorsEdgeCheatManager class does not impose this restriction.
 *
 * Todo: Currently we're disabling the flushing of player input during tabbing/menuing as a semi-workaround to the macro not spamming during menus.
 * This allows macros held BEFORE tabbing/menuing to continue executing when back in-game, but this does not work if the macro was spammed during.
 * Since we rely on TdInput bindings for the macros, these only execute while we have control of the character. Need to somehow fool the game
 * into thinking we still have player control during menus, OR rewrite this to emulate mouse scroll directly like Phoenix's (unlikely under UScript scope)
 */

class MirrorsEdgeMacro extends TdCheatManager;

var CheatHelperProxy HelperProxy;
var SaveLoadHandlerMEM SaveLoad; // Instance of our SaveLoadHandlerMEM
var bool bJumpMacroActive;
var bool bInteractMacroActive;
var bool bGrabMacroActive;

// Active macro mode: 0 = Interact, 1 = Grab
var int ActiveMacroMode;

function PostBeginPlay()
{
    Super.PostBeginPlay();
}

function EnsureHelperProxy()
{
    local string SavedMode;

    if (HelperProxy == None)
    {
        HelperProxy = WorldInfo.Spawn(class'CheatHelperProxy');
        HelperProxy.MacroReference = self;
    }

    if (SaveLoad == None)
    {
        SaveLoad = new class'SaveLoadHandlerMEM';
    }

    // Load the saved macro mode
    if (SaveLoad != None)
    {
        SavedMode = SaveLoad.LoadData("ActiveMacroMode");
        if (SavedMode == "1")
        {
            ActiveMacroMode = 1;
        }
        else // Default to InteractMacro (0) if not found or not "1"
        {
            ActiveMacroMode = 0;
        }
    }
    else
    {
        ActiveMacroMode = 0; // Default to InteractMacro if SaveLoad handler couldn't be initialized
    }
}

// Call this via the console to switch grab/interact
exec function SwitchMacroMode()
{
    if (ActiveMacroMode == 0)
    {
        ActiveMacroMode = 1;
        ClientMessage("Switched to Grab macro.");
        if (SaveLoad != None)
        {
            SaveLoad.SaveData("ActiveMacroMode", "1");
        }
    }
    else
    {
        ActiveMacroMode = 0;
        ClientMessage("Switched to Interact macro.");
        if (SaveLoad != None)
        {
            SaveLoad.SaveData("ActiveMacroMode", "0");
        }
    }
}

exec function JumpMacro()
{
    EnsureHelperProxy();
    if (!bJumpMacroActive)
    {
        bJumpMacroActive = true;
        HelperProxy.LoopFunction(0.002, "MacroJump");  // Start looping at a rate of 2ms
        ConsoleCommand("set UIScene bFlushPlayerInput 0");
        ConsoleCommand("StartMacroTimer Jump");
    }
}

exec function JumpMacro_OnRelease()
{
    if (bJumpMacroActive)
    {
        if (HelperProxy != None)
        {
            HelperProxy.StopTimer();
        }
        bJumpMacroActive = false;
        ConsoleCommand("ResetMacroTimer");
        ConsoleCommand("DisplayTrainerHUDMessage Macro stopped");
    }
}

exec function InteractMacro()
{
    EnsureHelperProxy();
    if (ActiveMacroMode == 0 && !bInteractMacroActive)
    {
        bInteractMacroActive = true;
        HelperProxy.LoopFunction(0.002, "MacroInteract");
        ConsoleCommand("set UIScene bFlushPlayerInput 0");
        ConsoleCommand("StartMacroTimer Interact");
    }
}

exec function InteractMacro_OnRelease()
{
    if (bInteractMacroActive)
    {
        if (HelperProxy != None)
        {
            HelperProxy.StopTimer();
        }
        bInteractMacroActive = false;
        ConsoleCommand("ResetMacroTimer");
        ConsoleCommand("DisplayTrainerHUDMessage Macro stopped");
    }
}

exec function GrabMacro()
{
    EnsureHelperProxy();
    if (ActiveMacroMode == 1 && !bGrabMacroActive)
    {
        bGrabMacroActive = true;
        HelperProxy.LoopFunction(0.002, "MacroGrab");
        ConsoleCommand("set UIScene bFlushPlayerInput 0");
        ConsoleCommand("StartMacroTimer Grab");
    }
}

exec function GrabMacro_OnRelease()
{
    if (bGrabMacroActive)
    {
        if (HelperProxy != None)
        {
            HelperProxy.StopTimer();
        }
        bGrabMacroActive = false;
        ConsoleCommand("ResetMacroTimer");
        ConsoleCommand("DisplayTrainerHUDMessage Macro stopped");
    }
}

// Internal functions to simulate the inputs
exec function MacroJump()
{
    ConsoleCommand("Jump");
    ConsoleCommand("StopJump | Axis aUp Speed=1.0  AbsoluteAxis=100 | PrevStaticViewTarget");
}

exec function MacroInteract()
{
    ConsoleCommand("UsePress");
    ConsoleCommand("UseRelease");
}

exec function MacroGrab()
{
    ConsoleCommand("PressedSwitchWeapon");
    ConsoleCommand("ReleasedSwitchWeapon");
}

function ExecuteCommand(string Command)
{
    // Use ConsoleCommand to dynamically invoke exec functions or native commands
    ConsoleCommand(Command);
}

defaultproperties
{
}