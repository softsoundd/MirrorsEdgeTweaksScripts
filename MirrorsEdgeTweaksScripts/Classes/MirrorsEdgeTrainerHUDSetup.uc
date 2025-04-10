/**
 *  Using this class as we need a way to monitor when we have changed game modes to adjust the trainer HUDs accordingly.
 *
 *  I really dislike this, and we wouldn't have to use it at all if we could solve the core trainer HUD issue - see Gist: https://gist.github.com/softsoundd/43c79349a27e0d380253883d09c97865
 */

class MirrorsEdgeTrainerHUDSetup extends TdPlayerController
    native
    config(Game)
    hidecategories(Navigation)
    implements(TdController);

var SaveLoadHandler SaveLoad;
var UIDataStore_TdGameData GameData;

simulated event PostBeginPlay()
{
    local GameInfo CurrentGame;

    CurrentGame = WorldInfo.Game;

    super.PostBeginPlay();

    // for whatever reason we must delay these in order for it to be called...
    if (CurrentGame != None && WorldInfo.Game.IsA('TdMenuGameInfo'))
    {
        SetTimer(0.005, true, 'CheckIntendedGameMode');
    }
    
    SetTimer(0.001, false, 'SetupTrainerHUD');
    
    DefaultFOV = Class'TdPlayerCamera'.default.DefaultFOV;
    DesiredFOV = DefaultFOV;
    FOVAngle = DefaultFOV;
    FOVZoomRate = 0;
    ReactionTimeEnergy = ReactionTimeSpawnLevel;
}

function CheckIntendedGameMode()
{
    local GameInfo CurrentGame;
    local Sequence CurrentSeq;
    local SequenceObject SeqObj;
    local SeqEvent_RemoteEvent RemoteEvent;
    local array<Sequence> SequencesToCheck;
    local int i;

    CurrentGame = WorldInfo.Game;

    if (CurrentGame != None && WorldInfo.Game.IsA('TdMenuGameInfo'))
    {
        CurrentSeq = WorldInfo.GetGameSequence();
        if (CurrentSeq != None)
        {
            SequencesToCheck.AddItem(CurrentSeq);

            while (SequencesToCheck.Length > 0)
            {
                CurrentSeq = SequencesToCheck[SequencesToCheck.Length - 1];
                SequencesToCheck.Remove(SequencesToCheck.Length - 1, 1);

                for (i = 0; i < CurrentSeq.SequenceObjects.Length; i++)
                {
                    SeqObj = CurrentSeq.SequenceObjects[i];
                    RemoteEvent = SeqEvent_RemoteEvent(SeqObj);
                    if (RemoteEvent != None && RemoteEvent.TriggerCount > 0)
                    {
                        // Reset the counter so we don't process the same click again.
                        RemoteEvent.TriggerCount = 0;
                        
                        if (RemoteEvent.EventName == 'NewGameButton_Clicked')
                        {
                            ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.MirrorsEdgeTrainerTutorialHUD");
                        }
                        else if (RemoteEvent.EventName == 'LoadLevelButton_Clicked')
                        {
                            ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.MirrorsEdgeTrainerSPHUD");
                        }
                        else if (RemoteEvent.EventName == 'LevelRaceButton_Clicked')
                        {
                            ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.MirrorsEdgeTrainerSPLevelRaceHUD");
                        }
                        else if (RemoteEvent.EventName == 'TimeTrialOnlineButton_Clicked')
                        {
                            ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.MirrorsEdgeTrainerTimeTrialHUD");
                        }
                    }
                }
            }
        }
    }
}

function SetupTrainerHUD()
{
    local GameInfo CurrentGame;
    local string CurrentHUDName;

    CurrentGame = WorldInfo.Game;

    if (CurrentGame != None)
    {
        CurrentHUDName = String(CurrentGame.HUDType);

        if (WorldInfo.Game.IsA('TdSPLevelRace'))
        {
            if (CurrentHUDName != "MirrorsEdgeTrainerSPLevelRaceHUD")
            {
                ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.MirrorsEdgeTrainerSPLevelRaceHUD");
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
                ConsoleCommand("RestartLevel");
            }
            else
            {
                return;
            }
        }
        else if (WorldInfo.Game.IsA('TdSPTutorialGame'))
        {
            ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.MirrorsEdgeTrainerSPHUD"); // avoids a second load when transitioning from training to story for any% (dumb)

            if (CurrentHUDName != "MirrorsEdgeTrainerTutorialHUD")
            {
                ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.MirrorsEdgeTrainerTutorialHUD");
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