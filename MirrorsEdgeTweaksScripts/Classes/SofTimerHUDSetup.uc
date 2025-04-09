/**
 *  Using this class as we need a way to monitor when we have changed game modes to adjust the softimer HUDs accordingly.
 *
 *  I really dislike this, and we wouldn't have to use it at all if we could solve the core custom HUD issue - see Gist: https://gist.github.com/softsoundd/43c79349a27e0d380253883d09c97865
 */

class SofTimerHUDSetup extends TdPlayerController
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
        SetTimer(0.05, false, 'SofTimerMessage');
    }
    
    SetTimer(0.001, false, 'SetupSofTimerHUD');
    
    DefaultFOV = Class'TdPlayerCamera'.default.DefaultFOV;
    DesiredFOV = DefaultFOV;
    FOVAngle = DefaultFOV;
    FOVZoomRate = 0;
    ReactionTimeEnergy = ReactionTimeSpawnLevel;
}

function SofTimerMessage()
{
    ClientMessage("SofTimer currently active. If you want to hide the in-game timer HUD, enter \"toggletimer\".");
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
                            ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.SofTimerTutorialHUD");
                        }
                        else if (RemoteEvent.EventName == 'LoadLevelButton_Clicked')
                        {
                            ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.SofTimerSPHUD");
                        }
                        else if (RemoteEvent.EventName == 'LevelRaceButton_Clicked')
                        {
                            ClientMessage("clicked!");
                            ConsoleCommand("set TdSPTimeTrialGame HUDType TdTimeTrialHUD");
                            ConsoleCommand("set TdSPLevelRace HUDType TdSPLevelRaceHUD");
                        }
                        else if (RemoteEvent.EventName == 'TimeTrialOnlineButton_Clicked')
                        {
                            ConsoleCommand("set TdSPTimeTrialGame HUDType TdTimeTrialHUD");
                            ConsoleCommand("set TdSPLevelRace HUDType TdSPLevelRaceHUD");
                        }
                    }
                }
            }
        }
    }
}


function SetupSofTimerHUD()
{
    local GameInfo CurrentGame;
    local string CurrentHUDName;

    CurrentGame = WorldInfo.Game;

    if (CurrentGame != None)
    {
        CurrentHUDName = String(CurrentGame.HUDType);

        if (WorldInfo.Game.IsA('TdSPLevelRace'))
        {
            if (CurrentHUDName != "TdSPLevelRaceHUD")
            {
                ConsoleCommand("set TdSPTimeTrialGame HUDType TdTimeTrialHUD");
                ConsoleCommand("set TdSPTutorialGame HUDType TdTutorialHUD");
                ConsoleCommand("set TdSPLevelRace HUDType TdSPLevelRaceHUD");
                ConsoleCommand("RestartLevel");
            }
            else
            {
                return;
            }
        }
        else if (WorldInfo.Game.IsA('TdSPTimeTrialGame'))
        {
            if (CurrentHUDName != "TdTimeTrialHUD")
            {
                ConsoleCommand("set TdSPTimeTrialGame HUDType TdTimeTrialHUD");
                ConsoleCommand("set TdSPTutorialGame HUDType TdTutorialHUD");
                ConsoleCommand("set TdSPLevelRace HUDType TdSPLevelRaceHUD");
                ConsoleCommand("RestartLevel");
            }
            else
            {
                return;
            }
        }
        else if (WorldInfo.Game.IsA('TdSPTutorialGame'))
        {
            ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.SofTimerSPHUD"); // avoids a second load when transitioning from training to story

            if (SaveLoad == none)
            {
                SaveLoad = new class'SaveLoadHandler';
            }

            GameData.TimeAttackClock = 0;

            SaveLoad.SaveData("TimeAttackClock", string(GameData.TimeAttackClock));

            if (CurrentHUDName != "SofTimerTutorialHUD")
            {
                ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.SofTimerTutorialHUD");
                ConsoleCommand("RestartLevel");
            }
        }
        else if (WorldInfo.Game.IsA('TdSPStoryGame'))
        {
            if (CurrentHUDName != "SofTimerSPHUD")
            {
                ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.SofTimerSPHUD");
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
}

defaultproperties
{
}