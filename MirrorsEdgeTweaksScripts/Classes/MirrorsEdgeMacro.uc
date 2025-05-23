/**
 *  Dedicated class just for spam macros (speedrun legal since cheats are stripped).
 *  Also has the mutual exclusivity between interact and grab macros. MirrorsEdgeCheatManager class does not impose this restriction.
 *
 *  Todo: Currently we're disabling the flushing of player input during tabbing/menuing as a semi-workaround to the macro not spamming during menus.
 *  This allows macros held BEFORE tabbing/menuing to continue executing when back in-game, but this does not work if the macro was spammed during.
 *  Since we rely on TdInput bindings for the macros, these only execute while we have control of the character. Need to somehow fool the game
 *  into thinking we still have player control during menus, OR rewrite this to emulate mouse scroll directly like Phoenix's (unlikely under UScript scope)
 */

class MirrorsEdgeMacro extends TdCheatManager;

var CheatHelperProxy HelperProxy;
var bool bJumpMacroActive;
var bool bInteractMacroActive;
var bool bGrabMacroActive;

// Active macro mode: 0 = Interact, 1 = Grab
var int ActiveMacroMode;

// Don't think this does anything but here just in case
function PostBeginPlay()
{
    Super.PostBeginPlay();
    ActiveMacroMode = 0; // Default to InteractMacro
}

exec function test()
{
    local TdPlayerInput TdInput;

    TdInput = TdPlayerInput(PlayerInput);
    TdInput.Jump();
}

function EnsureHelperProxy()
{
    if (HelperProxy == None)
    {
        HelperProxy = WorldInfo.Spawn(class'CheatHelperProxy');
        HelperProxy.MacroReference = self;
    }
}

// Call this via the console to switch grab/interact
exec function SwitchMacroMode()
{
    if (ActiveMacroMode == 0)
    {
        ActiveMacroMode = 1;
        ClientMessage("Switched to Grab macro.");
    }
    else
    {
        ActiveMacroMode = 0;
        ClientMessage("Switched to Interact macro.");
    }
}

exec function JumpMacro()
{
    if (!bJumpMacroActive)
    {
        EnsureHelperProxy();
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
    if (ActiveMacroMode == 0 && !bInteractMacroActive)
    {
        EnsureHelperProxy();
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
    if (ActiveMacroMode == 1 && !bGrabMacroActive)
    {
        EnsureHelperProxy();
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
    local TdPlayerInput TdInput;

    TdInput = TdPlayerInput(PlayerInput);
    TdInput.Jump();
    TdInput.StopJump();
}

exec function MacroInteract()
{
    Outer.UsePress();
    Outer.UseRelease();
}

exec function MacroGrab()
{
    Outer.PressedSwitchWeapon();
    Outer.ReleasedSwitchWeapon();
}

function ExecuteCommand(string Command)
{
    // Use ConsoleCommand to dynamically invoke exec functions or native commands
    ConsoleCommand(Command);
}

defaultproperties
{
}