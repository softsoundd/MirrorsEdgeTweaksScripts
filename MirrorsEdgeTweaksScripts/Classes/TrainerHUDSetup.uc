/**
 *  Using this class as we need a way to monitor when we have changed game modes to adjust the trainer HUDs accordingly.
 *
 *  I really dislike this, and we wouldn't have to use it at all if we could solve the core trainer HUD issue - see Gist: https://gist.github.com/softsoundd/43c79349a27e0d380253883d09c97865
 */

class TrainerHUDSetup extends TdPlayerController
    native
    config(Game)
    hidecategories(Navigation)
    implements(TdController);

simulated event PostBeginPlay()
{
    SetTimer(0.01, false, 'SetupTrainerHUD'); // for whatever reason we must delay this in order for it to be called. I hate this
    super.PostBeginPlay();
    DefaultFOV = Class'TdPlayerCamera'.default.DefaultFOV;
    DesiredFOV = DefaultFOV;
    FOVAngle = DefaultFOV;
}

function SetupTrainerHUD()
{
    local GameInfo CurrentGame;
    local string CurrentHUDName;
    local string GameMode;

    CurrentGame = WorldInfo.Game;

    if (CurrentGame != None)
    {
        CurrentHUDName = String(CurrentGame.HUDType);

        if (WorldInfo.Game.IsA('TdSPLevelRace'))
        {
            if (CurrentHUDName != "MirrorsEdgeTrainerSPLevelRaceHUD")
            {
                ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.MirrorsEdgeTrainerSPLevelRaceHUD");
                GameMode = "speed run";
                ConsoleCommand("RestartLevel");
            }
            else
            {
                return;
            }
        }
        else if (WorldInfo.Game.IsA('TdSPStoryGame'))
        {
            if (CurrentHUDName != "MirrorsEdgeTrainerSPHUD")
            {
                ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.MirrorsEdgeTrainerSPHUD");
                GameMode = "story";
                ConsoleCommand("RestartLevel");
            }
            else
            {
                return;
            }
        }
        else if (WorldInfo.Game.IsA('TdSPTimeTrialGame'))
        {
            if (CurrentHUDName != "MirrorsEdgeTrainerTimeTrialHUD")
            {
                ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.MirrorsEdgeTrainerTimeTrialHUD");
                GameMode = "time trial";
                ConsoleCommand("RestartLevel");
            }
            else
            {
                return;
            }
        }
        else if (WorldInfo.Game.IsA('TdSPTutorialGame'))
        {
            if (CurrentHUDName != "MirrorsEdgeTrainerTutorialHUD")
            {
                ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.MirrorsEdgeTrainerTutorialHUD");
                GameMode = "tutorial";
                ConsoleCommand("RestartLevel");
            }
            else
            {
                return;
            }
        }
        else if (WorldInfo.Game.IsA('TdMenuGameInfo'))
        {
            return;
        }
    }
    else
    {
        return;
    }

    ConsoleCommand("set TdHudEffectManager bEnableReactionTimeEffect false");
    ClientMessage(" ");
    ClientMessage("Restarted level to update trainer HUD for " $ GameMode $ " mode. Type \"ListTrainerHUDItems\" to view a list of what each item on the trainer HUD represents.");
    ClientMessage("Type \"ToggleTrainerHUD\" to show/hide the trainer items on the right.");
    ClientMessage("Type \"ToggleHUDMessages\" to show/hide the macro and cheat feedback messages.");
    ClientMessage(" ");
}

exec function ListTrainerHUDItems()
{
    ClientMessage(" ");
    ClientMessage("Note: You can disable the trainer HUD with \"exec trainerhudoff\"");
    ClientMessage("T = Timer location (checkpoint). Set your current position with \"SaveTimerLocation\". When you activate \"TpToSavedLocation\" the timer will start and stop once you reach the T location");
    ClientMessage("H = Health");
    ClientMessage("RT = Reaction time charge");
    ClientMessage("MS = Movement state");
    ClientMessage("V = Velocity");
    ClientMessage("VT = Top velocity (V) achieved in the past three seconds");
    ClientMessage("X = Location on the X-coordinate");
    ClientMessage("Y = Location on the Y-coordinate");
    ClientMessage("Z = Location on the Z-coordinate");
    ClientMessage("ZT = Top height (Z) achieved in the past three seconds");
    ClientMessage("SZ = Stored height (Z) of the last jump location");
    ClientMessage("SZD = Difference between Z and SZ");
    ClientMessage("P = Pitch rotation in degrees");
    ClientMessage("Y = Yaw rotation in degrees");
    ClientMessage(" ");
}

defaultproperties
{
}