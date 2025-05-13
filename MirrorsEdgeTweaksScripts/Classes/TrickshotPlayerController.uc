/**
 *  Meme class that stops held weapons from preventing wallrun kicks, and prevents non-walking states from unzooming the sniper.
 *
 *  Trickshot time baby
 */

class TrickshotPlayerController extends TdPlayerController
    native
    config(Game)
    hidecategories(Navigation)
    implements(TdController);

var transient float LastKnownScore;

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
    }

    SetTimer(0.001, false, 'SetupHitmarkerHUD');
    SetTimer(0.001, false, 'AdditionalTrickshotSetup');

    if (PlayerReplicationInfo != none)
    {
        LastKnownScore = PlayerReplicationInfo.Score;
    }
    else
    {
        LastKnownScore = 0;
    }
}

event PlayerTick(float DeltaTime)
{
    local TdWeapon_Heavy HeavyWeapon;
    local TdWeapon_Sniper_BarretM95 SniperWeapon;
    local float CurrentScore;

    // Kill detection
    if (PlayerReplicationInfo != none)
    {
        CurrentScore = PlayerReplicationInfo.Score;
        if (CurrentScore > LastKnownScore)
        {
            ConsoleCommand("DisplayHitmarker");

            LastKnownScore = CurrentScore; // Update for the next check
        }
    }

    MaintainEnemyList();
    MouseX = PlayerInput.aMouseX;
    MouseY = PlayerInput.aMouseY;

    if(ControllerTilt)
    {
        ActualAccelX = PlayerInput.aPS3AccelX;
        ActualAccelY = PlayerInput.aPS3AccelY;
        ActualAccelZ = PlayerInput.aPS3AccelZ;        
    }
    else
    {
        ActualAccelX = 0;
        ActualAccelY = 0;
        ActualAccelZ = 0;
    }
    super(PlayerController).PlayerTick(DeltaTime);
    UpdateReactionTime(DeltaTime);

    if(!WorldInfo.IsPlayInEditor())
    {
        UpdateMomentumStats(DeltaTime);
    }

    // Make sniper OP
    HeavyWeapon = TdWeapon_Heavy(myPawn.Weapon);
    if (HeavyWeapon.WeaponType != EWT_Light)
    {
        HeavyWeapon.WeaponType = EWT_Light;
    }

    SniperWeapon = TdWeapon_Sniper_BarretM95(myPawn.Weapon);
    if (SniperWeapon.AdditionalUnzoomedSpread != 0)
    {
        SniperWeapon.AdditionalUnzoomedSpread = 0;
    }
}

exec function AttackPress()
{
    local TdPlayerController PC;

    PC = TdPlayerController(Pawn.Controller);

    if(IsButtonInputIgnored())
    {
        return;
    }

    if (myPawn != none && (myPawn.MovementState == 4 || myPawn.MovementState == 5))
    {
        if (PC.PlayerInput.PressedKeys.Find('RightMouseButton') != -1)
        {
            StartFire();
            return;
        }
        else
        {
            myPawn.HandleMoveAction(3);
            return;
        }
    }

    if(!myPawn.HasWeapon() || (myPawn.MovementState == 1) && myPawn.Moves[19].CanDoMove())
    {
        myPawn.HandleMoveAction(3);
    }
    else
    {
        StartFire();
    }
}

// Overwritten version from TdPlayerController where we strip the bCanZoom function and movestate checks
exec function ZoomWeapon()
{
    local TdWeapon TdW;
    local float FOV, Rate, delay;

    TdW = TdWeapon(Pawn.Weapon);

    if(TdW != none && !TdW.IsZooming())
    {
        TdW.ToggleZoom(FOV, Rate, delay);
        StartZoom(FOV, Rate, delay);
    }
}

// stop any other state that might make us unzoom the sniper, shorten wallkick targetting distance
function AdditionalTrickshotSetup()
{
    ConsoleCommand("set TdMove bShouldUnzoom false");
    ConsoleCommand("set TdMove_MeleeBase TargetingMaxDistance 50");
    ConsoleCommand("set TdMove_MeleeAir TargetingMaxDistance 50");
}

function SetupHitmarkerHUD()
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
            if (CurrentHUDName != "TdTimeTrialHUD")
            {
                ConsoleCommand("set TdSPTimeTrialGame HUDType TdTimeTrialHUD");
                ConsoleCommand("set TdSPTutorialGame HUDType TdTutorialHUD");
                ConsoleCommand("set TdSPLevelRace HUDType TdSPLevelRaceHUD");
                ConsoleCommand("RestartLevel");
            }
        }
        else if (WorldInfo.Game.IsA('TdSPTutorialGame'))
        {
            if (CurrentHUDName != "TdTutorialHUD")
            {
                ConsoleCommand("set TdSPTimeTrialGame HUDType TdTimeTrialHUD");
                ConsoleCommand("set TdSPTutorialGame HUDType TdTutorialHUD");
                ConsoleCommand("set TdSPLevelRace HUDType TdSPLevelRaceHUD");
                ConsoleCommand("RestartLevel");
            }
        }
        else if (WorldInfo.Game.IsA('TdSPStoryGame'))
        {
            if (CurrentHUDName != "TrickshotHUD")
            {
                ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.TrickshotHUD");
                ConsoleCommand("RestartLevel");
            }
        }
    }
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
                            ConsoleCommand("set TdGameInfo HUDType MirrorsEdgeTweaksScripts.TrickshotHUD");
                        }
                        else if (RemoteEvent.EventName == 'LevelRaceButton_Clicked')
                        {
                            ConsoleCommand("set TdSPTimeTrialGame HUDType TdTimeTrialHUD");
                            ConsoleCommand("set TdSPTutorialGame HUDType TdTutorialHUD");
                            ConsoleCommand("set TdSPLevelRace HUDType TdSPLevelRaceHUD");
                        }
                        else if (RemoteEvent.EventName == 'TimeTrialOnlineButton_Clicked')
                        {
                            ConsoleCommand("set TdSPTimeTrialGame HUDType TdTimeTrialHUD");
                            ConsoleCommand("set TdSPTutorialGame HUDType TdTutorialHUD");
                            ConsoleCommand("set TdSPLevelRace HUDType TdSPLevelRaceHUD");
                        }
                    }
                }
            }
        }
    }
}

defaultproperties
{
    LastKnownScore = 0
}