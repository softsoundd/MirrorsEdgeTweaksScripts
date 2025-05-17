/**
 *  Using this class as we need a way to monitor when we have changed game modes to adjust the softimer HUDs accordingly.
 */

class SofTimerHUDSetup extends TdPlayerController
    native
    config(Game)
    hidecategories(Navigation)
    implements(TdController);

var bool bDifficultySceneOpen;

simulated event PostBeginPlay()
{
    local GameInfo CurrentGame;
    
    super.PostBeginPlay();

    DefaultFOV = Class'TdPlayerCamera'.default.DefaultFOV;
    DesiredFOV = DefaultFOV;
    FOVAngle = DefaultFOV;
    FOVZoomRate = 0;
    ReactionTimeEnergy = ReactionTimeSpawnLevel;

    CurrentGame = WorldInfo.Game;

    // for whatever reason we must delay these via a timer in order for it to be called from PostBeginPlay
    if (CurrentGame != None && WorldInfo.Game.IsA('TdMenuGameInfo'))
    {
        SetTimer(0.01613, true, 'CheckIntendedGameMode');
        SetTimer(0.01613, true, 'CheckNewGameConfirmed');
        SetTimer(0.05, false, 'SofTimerMessage');
    }
    
    SetTimer(0.001, false, 'SetupSofTimerHUD'); // fallback in case we didn't access a game mode through the menu buttons

    SetTimer(1, false, 'CustomTimeTrialOrder');
}

function SofTimerMessage()
{
    ClientMessage("SofTimer currently active. You can toggle various HUD elements with the following commands:");
    ClientMessage("- \"toggletimer\" | LRT Timer (enabled by default) - it is recommended to use the SofTimer readout LiveSplit ASL in either case");
    ClientMessage("- \"toggletrainerhud\" | Trainer HUD (disabled by default, has mutual exclusivity with the speedometer)");
    ClientMessage("- \"togglespeed\" | Speedometer (disabled by default, has mutual exclusivity with the Trainer HUD)");
    ClientMessage("- \"togglemacrofeedback\" | Macro feedback messages (disabled by default)");
}

// More robust check compared to CheckIntendedGameMode() since we need to be sure the player meant to
// do new game before we go ahead with resetting the timer. This checks if we were in the
// difficulty select screen and the disk save indicator appears after accepting
function bool CheckNewGameConfirmed()
{
    local TdGameUISceneClient SceneClient;
    local UIScene ActiveScene;
    local TdUIScene_LoadIndicator IndicatorScene;
    local TdHUD CurrentHUD;

    SceneClient = TdGameUISceneClient(Class'UIRoot'.static.GetSceneClient());
    if (SceneClient == None)
        return false;

    ActiveScene = SceneClient.GetActiveScene();

    if (ActiveScene != None && ActiveScene.SceneTag == 'TdDifficultySettings')
    {
        if (!bDifficultySceneOpen)
        {
            bDifficultySceneOpen = true;
        }

        CurrentHUD = TdHUD(MyHUD);
        if (CurrentHUD != None)
        {
            IndicatorScene = TdUIScene_LoadIndicator(CurrentHUD.DiskAccessIndicatorInstance);
            if (IndicatorScene != None && IndicatorScene.bIsDiscAccess)
            {
                ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.SofTimerTutorialHUD");
            }
        }

        return true;
    }

    bDifficultySceneOpen = false;
    return false;
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
                        
                        if (RemoteEvent.EventName == 'LoadLevelButton_Clicked')
                        {
                            ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.SofTimerSPHUD");
                        }
                        else if (RemoteEvent.EventName == 'LevelRaceButton_Clicked')
                        {
                            ConsoleCommand("set TdSPLevelRace HUDType TdSPLevelRaceHUD");
                        }
                        else if (RemoteEvent.EventName == 'TimeTrialOnlineButton_Clicked')
                        {
                            ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.SofTimerTimeTrialHUD");
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
        }
        else if (WorldInfo.Game.IsA('TdSPTimeTrialGame'))
        {
            if (CurrentHUDName != "SofTimerTimeTrialHUD")
            {
                ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.SofTimerTimeTrialHUD");
                ConsoleCommand("RestartLevel");
            }
        }
        else if (WorldInfo.Game.IsA('TdSPTutorialGame'))
        {
            // avoids a second load when transitioning from training to story. todo: probably better to tie this to skip training button
            ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.SofTimerSPHUD");

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
        }
        else if (WorldInfo.Game.IsA('TdMenuGameInfo'))
        {
            ConsoleCommand("set TdTimeTrialHUD StarRatingPos (X=1056,Y=61)"); // default position of tt star rating hud if we're done with 69 stars
        }
    }
}

function CustomTimeTrialOrder()
{
    ConsoleCommand("exec timetrialorder");
}

defaultproperties
{
}