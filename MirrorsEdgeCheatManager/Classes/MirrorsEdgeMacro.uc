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

function EnsureHelperProxy()
{
    if (HelperProxy == None)
    {
        HelperProxy = WorldInfo.Spawn(class'CheatHelperProxy');
        HelperProxy.MacroReference = self;
        // ClientMessage("Macros are ready for use (make sure you have set their binds in Mirror's Edge Tweaks)");
        // ClientMessage("Interact macro is active by default - to switch to the grab macro type \"SwitchMacroMode\"");
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
        // ClientMessage("Jump macro started.");
        ConsoleCommand("set UIScene bFlushPlayerInput 0");
    }
}

exec function JumpMacro_OnRelease()
{
    if (bJumpMacroActive)
    {
        if (HelperProxy != None)
        {
            HelperProxy.StopTimer(); // Stop the loop
        }
        bJumpMacroActive = false;
        // ClientMessage("Jump macro stopped.");
    }
}

exec function InteractMacro()
{
    if (ActiveMacroMode == 0 && !bInteractMacroActive)
    {
        EnsureHelperProxy();
        bInteractMacroActive = true;
        HelperProxy.LoopFunction(0.002, "MacroInteract");  // Start looping at a rate of 2ms
        // ClientMessage("Interact macro started.");
        ConsoleCommand("set UIScene bFlushPlayerInput 0");
    }
}

exec function InteractMacro_OnRelease()
{
    if (bInteractMacroActive)
    {
        if (HelperProxy != None)
        {
            HelperProxy.StopTimer(); // Stop the loop
        }
        bInteractMacroActive = false;
        // ClientMessage("Interact macro stopped.");
    }
}

exec function GrabMacro()
{
    if (ActiveMacroMode == 1 && !bGrabMacroActive)
    {
        EnsureHelperProxy(); // Ensure the helper proxy is initialised
        bGrabMacroActive = true;
        HelperProxy.LoopFunction(0.002, "MacroGrab");  // Start looping at a rate of 2ms
        // ClientMessage("Grab macro started.");
        ConsoleCommand("set UIScene bFlushPlayerInput 0");
    }
}

exec function GrabMacro_OnRelease()
{
    if (bGrabMacroActive)
    {
        if (HelperProxy != None)
        {
            HelperProxy.StopTimer(); // Stop the loop
        }
        bGrabMacroActive = false;
        // ClientMessage("Grab macro stopped.");
    }
}

// Internal functions to simulate the inputs
exec function MacroJump()
{
    ConsoleCommand("Jump");
    ConsoleCommand("OnRelease StopJump | Axis aUp Speed=1.0  AbsoluteAxis=100 | PrevStaticViewTarget");
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