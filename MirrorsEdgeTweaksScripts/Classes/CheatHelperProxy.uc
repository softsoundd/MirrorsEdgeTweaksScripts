/**
 *  Proxy class for providing the CheatManager-extended classes access to low-level UScript functions (ticks, loops, etc.).
 *
 *  This allows us to monitor certain states or loop through functions - this is what permits fall height monitoring, macros etc. to work
 *  Doing it like this is relatively unconventional, but it works.
 */

class CheatHelperProxy extends Actor;

var MirrorsEdgeCheatManager CheatManagerReference;
var MirrorsEdgeMacro MacroReference;
var SaveFileEditor SaveFileEditorReference;
var TdPawn Pawn;
var bool bEnableTick;
var string PendingCommand;

// Don't think this does anything but here just in case
event PostBeginPlay()
{
    super.PostBeginPlay();
    bEnableTick = true;
}

event Tick(float DeltaTime)
{
    if (bEnableTick && CheatManagerReference != None)
    {
        CheatManagerReference.OnTick(DeltaTime);
    }
    else if (bEnableTick && SaveFileEditorReference != None)
    {
        SaveFileEditorReference.OnTick(DeltaTime);
    }
}

event Timer()
{
    if (PendingCommand != "")
    {
        // Check which reference is available and execute the command
        if (CheatManagerReference != None)
        {
            CheatManagerReference.ExecuteCommand(PendingCommand);
        }
        else if (MacroReference != None)
        {
            MacroReference.ExecuteCommand(PendingCommand);
        }
    }
}

function StartTimer(float Duration, bool bLoop)
{
    SetTimer(Duration, bLoop);
    if (CheatManagerReference != None)
    {
        CheatManagerReference.OnTimerStart(Duration, bLoop);
    }
}

function StopTimer()
{
    ClearTimer();
    if (CheatManagerReference != None)
    {
        CheatManagerReference.OnTimerStop();
    }
}

function DelayedFunction(float Delay, string Command)
{
    PendingCommand = Command;
    SetTimer(Delay, false);
    if (CheatManagerReference != None)
    {
        CheatManagerReference.OnDelayStart(Command);
    }
}

function LoopFunction(float Interval, string Command)
{
    PendingCommand = Command;

    // Execute the command immediately
    if (CheatManagerReference != None && PendingCommand != "")
    {
        CheatManagerReference.ExecuteCommand(PendingCommand);
    }

    // Set the looping timer for subsequent executions
    SetTimer(Interval, true);
    if (CheatManagerReference != None)
    {
        CheatManagerReference.OnLoopStart(Command);
    }
}

simulated function Destroyed()
{
    ClearTimer(); // Ensure timer is cleared when destroyed
    super.Destroyed();
}

defaultproperties
{
}