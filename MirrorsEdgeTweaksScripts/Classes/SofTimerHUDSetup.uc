/**
 *  Using this class as we need a way to monitor when we have changed game modes to adjust the softimer HUDs accordingly.
 */

class SofTimerHUDSetup extends TdPlayerController
    native
    config(Game)
    hidecategories(Navigation)
    implements(TdController);

var SaveLoadHandlerSTPC SaveLoad;
var SaveLoadHandlerSTHUD STSaveLoad;
var TdProfileSettings   Profile;
var UIDataStore_TdGameData GameData;
var bool bDifficultySceneOpen;

// True glitchless vars
var bool bTrueGlitchless;
var vector PreviousPawnVelocity;
var transient Vector LastKnownBaseVelocity;
var bool bPending180TurnJumpFalling;
var bool bIsPostWCDJFalling;
var SoundCue LookAtNegativeSound;
var SoundCue TrainSound;
var bool bPendingDodgeJumpLanding;
var float DodgeJumpLandingBlockTimer;
var int OldMovementState;

simulated event PostBeginPlay()
{
    local GameInfo CurrentGame;
    local TdOnScreenErrorHandler ErrorHandler;

    super(PlayerController).PostBeginPlay();
    DefaultFOV = Class'TdPlayerCamera'.default.DefaultFOV;
    DesiredFOV = DefaultFOV;
    FOVAngle = DefaultFOV;
    FOVZoomRate = 0;
    ReactionTimeEnergy = ReactionTimeSpawnLevel;
    ErrorHandler = new Class'TdOnScreenErrorHandler';
    ErrorHandler.Initialize();

    CurrentGame = WorldInfo.Game;

    // for whatever reason we must delay these via a timer in order for it to be called from PostBeginPlay
    if (CurrentGame != None && WorldInfo.Game.IsA('TdMenuGameInfo'))
    {
        SetTimer(0.01, true, 'CheckIntendedGameMode');
        SetTimer(0.01, true, 'CheckNewGameConfirmed');
        //SetTimer(0.05, false, 'SofTimerMessage');
    }
    
    SetTimer(0.001, false, 'SetupSofTimerHUD'); // fallback in case we didn't access a game mode through the menu buttons

    SetTimer(1, false, 'CustomTimeTrialOrder');

    SetTimer(0.01, false, 'RelayBinds');

    SetTimer(1, false, 'TrueGlitchlessCheck');
}

/* function SofTimerMessage()
{
    ClientMessage("SofTimer currently active. You can toggle various HUD elements with the following commands:");
    ClientMessage("- \"toggletimer\" | LRT Timer (enabled by default) - it is recommended to use the SofTimer readout LiveSplit ASL in either case");
    ClientMessage("- \"toggletrainerhud\" | Trainer HUD (disabled by default, has mutual exclusivity with the speedometer)");
    ClientMessage("- \"togglespeed\" | Speedometer (disabled by default, has mutual exclusivity with the Trainer HUD)");
    ClientMessage("- \"togglemacrofeedback\" | Macro feedback messages (disabled by default)");
} */

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
                        else if (RemoteEvent.EventName == 'panel2' || RemoteEvent.EventName == 'panel3' || RemoteEvent.EventName == 'panel4')
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

    if (SaveLoad == none)
    {
        SaveLoad = new class'SaveLoadHandlerSTPC';
    }

    ConsoleCommand("set SequenceObject bSuppressAutoComment true");
    ConsoleCommand("set SequenceObject bOutputObjCommentToScreen false");
    ConsoleCommand("set SeqAct_Log bOutputToScreen false");

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
            ConsoleCommand("set TdSPHUD PopUpPos (X=96,Y=80)");
            ConsoleCommand("set TdTimeTrialHUD StarRatingPos (X=1056,Y=61)"); // default position of tt star rating hud if we're done with 69 stars
        }
    }
}

function SaveStatsToProfile(bool bLevelStats, bool bGameStats, bool bGlobalStats)
{
    local TdProfileSettings ProfileSettings;
    local DataStoreClient DataStoreManager;
    local array<float> IntermediateTimes;
    local int ProfileIDToTest;
    local float TimeToSet;
    local string SavedTimeStr;
    local string NewMapFlag;

    ProfileSettings = GetProfileSettings();
    if (ProfileSettings == none)
    {
        return;
    }

    if (STSaveLoad == none)
    {
        STSaveLoad = new class'SaveLoadHandlerSTHUD';
    }

    DataStoreManager = Class'UIInteraction'.static.GetDataStoreClient();
    GameData = UIDataStore_TdGameData(DataStoreManager.FindDataStore('TdGameData'));

    NewMapFlag = STSaveLoad.LoadData("bNewMapSavePending");

    if (NewMapFlag == "true")
    {
        // This is the first save on a new map. Load time from the file.
        SavedTimeStr = STSaveLoad.LoadData("TimeAttackClock");
        if (SavedTimeStr != "")
        {
            TimeToSet = float(SavedTimeStr);
        }
    }
    else
    {
        TimeToSet = GameData.TimeAttackClock;
    }
    
    ProfileIDToTest = 1204; // TDPID_StretchTime_04
    IntermediateTimes.Length = 0;
    IntermediateTimes.AddItem(TimeToSet);

    ProfileSettings.SetTTStretchTime(ProfileIDToTest, TimeToSet, IntermediateTimes, 0.0, 0.0);

    StatsManager.SaveStatsToProfile(ProfileSettings, bLevelStats, bGameStats, bGlobalStats);
}

function RelayBinds()
{
    if (WorldInfo.GetMapName() == "Edge_p")
    {
        ConsoleCommand("exec RelayBindsCH0");
    }
    else if (WorldInfo.GetMapName() == "Escape_p")
    {
        ConsoleCommand("exec RelayBindsCH1");
    }
    else if (WorldInfo.GetMapName() == "Stormdrain_p")
    {
        ConsoleCommand("exec RelayBindsCH2");
    }
    else if (WorldInfo.GetMapName() == "Cranes_p")
    {
        ConsoleCommand("exec RelayBindsCH3");
    }
    else if (WorldInfo.GetMapName() == "Subway_p")
    {
        ConsoleCommand("exec RelayBindsCH4");
    }
    else if (WorldInfo.GetMapName() == "Mall_p")
    {
        ConsoleCommand("exec RelayBindsCH5");
    }
    else if (WorldInfo.GetMapName() == "Factory_p")
    {
        ConsoleCommand("exec RelayBindsCH6");
    }
    else if (WorldInfo.GetMapName() == "Boat_p")
    {
        ConsoleCommand("exec RelayBindsCH7");
    }
    else if (WorldInfo.GetMapName() == "Convoy_p")
    {
        ConsoleCommand("exec RelayBindsCH8");
    }
    else if (WorldInfo.GetMapName() == "Scraper_p")
    {
        ConsoleCommand("exec RelayBindsCH9");
    }
}

exec function SetKeyBind(string ActionCommandString, string KeyName1, optional string KeyName2, optional string KeyName3, optional string KeyName4)
{
    local int ActionIndex;
    local name KeyBinds[4];
    local int KeyActionProfileId; // The TDPID_KeyAction_XX value
    local int KeyBindingValue;
    local int KeyEnumValue;
    local int KeyBindIdx;
    local name KeyToUnbindName;
    local int KeyToUnbindEnum;
    local int CurrentPackedValue, NewPackedValue;
    local int OldSlotIdx, NewSlotIdx;
    local int SlotKeyEnum;
    local bool bWasModified;
    local int i;

    Profile = GetProfileSettings();
    if (Profile == none)
    {
        ClientMessage("failed to get profile settings.");
        return;
    }

    if (Caps(ActionCommandString) == "NULL" || Caps(ActionCommandString) == "UNBIND")
    {
        KeyToUnbindName = name(KeyName1);
        if (KeyToUnbindName == 'None' || KeyName1 == "")
        {
            ClientMessage("Usage: SetKeyBind null <KeyName>");
            return;
        }

        KeyToUnbindEnum = Profile.FindKeyEnum(KeyToUnbindName);
        if (KeyToUnbindEnum == -1)
        {
            ClientMessage("Cannot unbind key '" $ KeyToUnbindName $ "' as it is not a valid bindable key.");
            return;
        }

        for (i = 0; i < Profile.DigitalButtonActionsToCommandMapping.Length; i++)
        {
            if (Profile.DigitalButtonActionsToCommandMapping[i] == "" || i == 0)
                continue;

            KeyActionProfileId = 501 + i;
            if (Profile.GetProfileSettingValueInt(KeyActionProfileId, CurrentPackedValue) && CurrentPackedValue != 0)
            {
                NewPackedValue = 0;
                NewSlotIdx = 0;
                bWasModified = false;

                for (OldSlotIdx = 0; OldSlotIdx < 4; OldSlotIdx++)
                {
                    SlotKeyEnum = 255 & (CurrentPackedValue >> (OldSlotIdx * 8));
                    if (SlotKeyEnum != 0)
                    {
                        if (SlotKeyEnum == KeyToUnbindEnum)
                        {
                            bWasModified = true;
                        }
                        else
                        {
                            NewPackedValue = NewPackedValue | (SlotKeyEnum << (NewSlotIdx * 8));
                            NewSlotIdx++;
                        }
                    }
                }

                if (bWasModified)
                {
                    Profile.SetProfileSettingValueInt(KeyActionProfileId, NewPackedValue);
                    ClientMessage("Unbound key '" $ KeyToUnbindName $ "' from action '" $ Profile.DigitalButtonActionsToCommandMapping[i] $ "'.");
                }
            }
        }
        return;
    }

    ActionIndex = Profile.GetDBAFromCommand(ActionCommandString);
    if (ActionIndex < 0 || ActionIndex >= Profile.DigitalButtonActionsToCommandMapping.Length)
    {
        ClientMessage("Invalid ActionCommandString '" $ ActionCommandString $ "'.");
        return;
    }

    KeyActionProfileId = 501 + ActionIndex;
    if (KeyActionProfileId < Profile.TDPID_KeyAction_1 || KeyActionProfileId > Profile.TDPID_KeyAction_49)
    {
        ClientMessage("Calculated KeyActionProfileId " $ KeyActionProfileId $ " is out of expected range.");
        return;
    }

    KeyBinds[0] = (KeyName1 != "") ? name(KeyName1) : 'None';
    KeyBinds[1] = (KeyName2 != "") ? name(KeyName2) : 'None';
    KeyBinds[2] = (KeyName3 != "") ? name(KeyName3) : 'None';
    KeyBinds[3] = (KeyName4 != "") ? name(KeyName4) : 'None';

    KeyBindingValue = 0;
    for (KeyBindIdx = 0; KeyBindIdx < 4; KeyBindIdx++)
    {
        if (KeyBinds[KeyBindIdx] != 'None')
        {
            KeyEnumValue = Profile.FindKeyEnum(KeyBinds[KeyBindIdx]);
            if (KeyEnumValue != -1)
            {
                KeyBindingValue = KeyBindingValue | (KeyEnumValue << (KeyBindIdx * 8));
            }
            else
            {
                ClientMessage("Warning - Key '" $ KeyBinds[KeyBindIdx] $ "' not found. Will not be bound.");
            }
        }
    }

    if (!Profile.SetProfileSettingValueInt(KeyActionProfileId, KeyBindingValue))
    {
        ClientMessage("Failed to set keybind in profile for '" $ ActionCommandString $ "'.");
    }
}

exec function ClearBinds()
{
    local int i;
    local string CurrentCommand;
    local string JumpMacroCmd;
    local string InteractMacroCmd;

    Profile = GetProfileSettings();

    if (Profile == none)
    {
        ClientMessage("Error: Failed to get Profile or PlayerInput. Cannot clear binds.");
        return;
    }

    Profile.RemoveDBABindings(PlayerInput);

    JumpMacroCmd = "JumpMacro | OnRelease JumpMacro_OnRelease";
    InteractMacroCmd = "InteractMacro | OnRelease InteractMacro_OnRelease";

    PlayerInput = TdPlayerInput(PlayerInput);
    if (PlayerInput == none)
    {
        return;
    }

    for (i = PlayerInput.Bindings.Length - 1; i >= 0; i--)
    {
        CurrentCommand = PlayerInput.Bindings[i].Command;

        if (CurrentCommand == JumpMacroCmd || CurrentCommand == InteractMacroCmd)
        {
            PlayerInput.Bindings.Remove(i, 1);
        }
    }
}

exec function SaveBinds()
{
    Profile.ApplyAllKeyBindings(PlayerInput);
}

exec function SetMacroBind(string MacroType, string KeyName)
{
	local string CommandToBind;
	local name KeyNameToBind;

	if (PlayerInput == none)
	{
		ClientMessage("Failed to get PlayerInput. Cannot set macro bind.");
		return;
	}

	switch (Caps(MacroType))
	{
		case "JUMP":
			CommandToBind = "JumpMacro | OnRelease JumpMacro_OnRelease";
			break;
		case "INTERACT":
			CommandToBind = "InteractMacro | OnRelease InteractMacro_OnRelease";
			break;
		default:
			ClientMessage("Invalid MacroType '" $ MacroType $ "'. Please use 'Jump' or 'Interact'.");
			return;
	}

	KeyNameToBind = name(KeyName);

	if (KeyNameToBind == 'None' || KeyName == "")
	{
		ClientMessage("An invalid KeyName was provided. Bind failed.");
		return;
	}

	PlayerInput.SetBind(KeyNameToBind, CommandToBind);
	PlayerInput.SaveConfig();
}

exec function SetMouseSensitivity(float PersonalDPI, float SharedMouseDPI)
{
    local float NewSensitivity;
    local float BaseSensitivity;

    BaseSensitivity = 10.08;

    if (PersonalDPI <= 0 || SharedMouseDPI <= 0)
    {
        ClientMessage("Error: DPI values must be positive.");
        return;
    }

    if (PlayerInput == none)
    {
        ClientMessage("Failed to get PlayerInput. Cannot set sensitivity.");
        return;
    }

    NewSensitivity = (PersonalDPI * BaseSensitivity) / SharedMouseDPI;
    PlayerInput.MouseSensitivity = NewSensitivity;

    PlayerInput.SaveConfig();
}

exec function FOV(float F)
{
    if(PlayerCamera != none)
    {
        PlayerCamera.SetFOV(F);
        PlayerCamera.DefaultFOV = F;
        DefaultFOV = F;
        return;
    }
}

function CustomTimeTrialOrder()
{
    ConsoleCommand("exec timetrialorder");
}

exec function ModeTrueGlitchless()
{
    bTrueGlitchless = !bTrueGlitchless;
    SaveLoad.SaveData("bTrueGlitchless", string(bTrueGlitchless));
    ClientMessage("True glitchless mode set to " $ bTrueGlitchless);
}

function TrueGlitchlessCheck()
{
    bTrueGlitchless = (SaveLoad.LoadData("bTrueGlitchless") == "") ? false : bool(SaveLoad.LoadData("bTrueGlitchless"));
}

function NotifyTakeHit(Controller InstigatedBy, Vector HitLocation, int Damage, class<DamageType> DamageType, Vector Momentum)
{
    local TdMove_MeleeAir MeleeAirMove;
    local TdMove_Landing LandingMove;

    local int iDam;

    super(PlayerController).NotifyTakeHit(InstigatedBy, HitLocation, Damage, DamageType, Momentum);
    iDam = Clamp(Damage, 0, 250);
    if(!bGodMode)
    {
        if(InstigatedBy == none)
        {
            ClientPlayTakeHit(vect(0, 0, 0), byte(iDam), DamageType);            
        }
        else
        {
            ClientPlayTakeHit(InstigatedBy.Pawn.Location - HitLocation, byte(iDam), DamageType);
        }
    }

    // Glitchless neutral kick hard landing
    if (myPawn != none && bTrueGlitchless && DamageType == class'DmgType_Fell' && myPawn.Moves[myPawn.MovementState].IsA('TdMove_MeleeAir'))
    {
        MeleeAirMove = TdMove_MeleeAir(myPawn.Moves[myPawn.MovementState]);

        if (MeleeAirMove.MeleeType == 1) // MeleeInAirStill
        {
            LandingMove = TdMove_Landing(myPawn.Moves[20]);
            if (LandingMove != none)
            {
                myPawn.SetMove(20);
            }
        }
    }
}

exec function UseRelease()
{
    local TdMove CurrentMove;

    CurrentMove = myPawn.Moves[myPawn.MovementState];

    if (bTrueGlitchless && !CurrentMove.IsA('TdMove_Walking'))
    {
        return;
    }

    if(IsButtonInputIgnored())
    {
        return;
    }

    Use();
}

exec function LookAtPress()
{
    local TdGameInfo GInfo;

    if(bCinematicMode)
    {
        return;
    }
    
    if (bTrueGlitchless && bPending180TurnJumpFalling)
    {
        LookAtNegativeSound = SoundCue(DynamicLoadObject("A_HUD.Look_At.Negative", class'SoundCue'));
        ClientHearSound(LookAtNegativeSound, self, Location, false, false);
        return;
    }

    GInfo = TdGameInfo(WorldInfo.Game);
    if(GInfo != none)
    {
        CurrentLookAtPoint = GInfo.GetLookAtPoint(myPawn);
        if(CurrentLookAtPoint != none)
        {
            CurrentLookAtPoint.SetupTime(0.6, 3);            
        }
        else
        {
            LookAtNegativeSound = SoundCue(DynamicLoadObject("A_HUD.Look_At.Negative", class'SoundCue'));
            ClientHearSound(LookAtNegativeSound, self, Location, false, false);
        }
    }
}

event PlayerTick(float DeltaTime)
{
    local Actor GroundActor;
    local TdMove CurrentMove, OldMove;
    local float JumpSpeedCap;
    local Vector RelativeVelocity;
    local TdMove_WallRun PreviousWallrunMove;
    local TdMove_WallrunJump WallrunJumpMove;
    local Vector CamDir, WallProjVelocity, CorrectPushAwayVelocity, CorrectHorizontalVelocity;
    local Vector ErrorVelocity, ActualParallelVelocity, CorrectParallelVelocity;
    local float PushSpeed, PushAwaySpeed, ParallelMultiplier;
    local TdPhysicsMove CurrentPhysicsMove;
    local AnimNodeSequence CurrentAnimNode;
    local float AnimTimeRemaining;
    local Vector HitLocation, HitNormal, TraceStart, TraceEnd, Extent;
    local TdMove_WallClimb WallClimbMove;
    local float OriginalZVelocity;
    local Vector HorizontalVelocity, WallNormal, PerpendicularVelocity;
    local TdBarbedWireVolume BarbedWire;
    local TdBalanceWalkVolume BalanceVolume;
    local bool bShouldIgnoreInput;
    local TdMove_Jump JumpMove;
    local float ForwardVelocityFloat;
    local TdMove_WallClimbDodgeJump DodgeJumpMove;
    local Vector DodgeDirection;
    local Vector CorrectVelocity;
    local float TheoreticalMaxSpeed, TheoreticalMaxSpeedSq;
    local TdMove_SpeedVault VaultMove;
    local bool bIsValidSurface;
    local Actor FoundSurfaceActor;
    local StaticMeshActor FoundStaticMeshActor;
    local StaticMesh SpringboardMeshRef;
    local TdMove_LayOnGround LayOnGroundMove;
    local TdMove_SoftLanding SoftLandingMove;
    local float LandingBackwardsDot;
    local bool bIsLandingBackwards;
    local int i;

    if (myPawn != none && bTrueGlitchless)
    {
        CurrentMove = myPawn.Moves[myPawn.MovementState];
        OldMove = myPawn.Moves[myPawn.OldMovementState];
        bShouldIgnoreInput = false;

        if (myPawn.Physics == PHYS_Walking)
        {
            if (myPawn.Base != none && !myPawn.Base.bWorldGeometry)
            {
                LastKnownBaseVelocity = myPawn.Base.Velocity;
            }
            else
            {
                LastKnownBaseVelocity = vect(0,0,0);
            }
        }

        if (myPawn.Physics == PHYS_Walking || CurrentMove.IsA('TdMove_WallClimb'))
        {
            bIsPostWCDJFalling = false;
        }

        // Set moves with an exploitable end state of walking to falling instead
		if (CurrentMove.IsA('TdMove_MeleeWallrun') || CurrentMove.IsA('TdMove_SkillRoll') || CurrentMove.IsA('TdMove_Stumble') || CurrentMove.IsA('TdMove_MeleeAirAbove') || CurrentMove.IsA('TdMOVE_Disarm'))
		{
			CurrentAnimNode = CurrentMove.CurrentCustomAnimNode;

			if (CurrentAnimNode != none && CurrentAnimNode.AnimSeq != none && CurrentAnimNode.bPlaying)
			{
				AnimTimeRemaining = (CurrentAnimNode.AnimSeq.SequenceLength / CurrentAnimNode.Rate) - CurrentAnimNode.CurrentTime;

				if (AnimTimeRemaining > 0.0 && AnimTimeRemaining <= DeltaTime)
				{
					TraceStart = myPawn.Location;
					TraceEnd = myPawn.Location;
					TraceEnd.Z -= (myPawn.CylinderComponent.CollisionHeight * 0.5) + 50.0f;
					GroundActor = myPawn.Trace(HitLocation, HitNormal, TraceEnd, TraceStart, false);
                    
					if (GroundActor == none && myPawn.Base == none)
					{
						myPawn.SetMove(MOVE_Falling);
                        TrueGlitchlessJumpscare();
					}
				}
			}
		}
        // Prevent elevator bounce
        else if (CurrentMove.IsA('TdMove_Walking'))
        {
            if (myPawn.Floor == vect(0,0,0))
            {
                myPawn.SetMove(2);
                TrueGlitchlessJumpscare();
            }
        }

        // Prevent the snatch animation staying in the flying physics state if we're on geometry that would otherwise not be standable
        if (OldMove.IsA('TdMOVE_Disarm') && CurrentMove.IsA('TdMove_Walking'))
        {
            TraceStart = myPawn.Location;
            TraceEnd = TraceStart - vect(0,0,50);
            
            Extent.X = myPawn.CylinderComponent.CollisionRadius * 0.9f;
            Extent.Y = myPawn.CylinderComponent.CollisionRadius * 0.9f;
            Extent.Z = 1.0f;

            GroundActor = myPawn.Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true, Extent);

            if (GroundActor == none)
            {
                myPawn.SetMove(MOVE_Falling);
            }
        }

        // Always cap jump speed to the max achievable from max running speed
        if (CurrentMove.IsA('TdMove_Jump'))
        {
            JumpSpeedCap = 820.0f;

            RelativeVelocity = myPawn.Velocity - LastKnownBaseVelocity;

            HorizontalVelocity = RelativeVelocity;
            HorizontalVelocity.Z = 0;

            if (VSizeSq(HorizontalVelocity) > (JumpSpeedCap * JumpSpeedCap))
            {
                HorizontalVelocity = Normal(HorizontalVelocity) * JumpSpeedCap;

                myPawn.Velocity = HorizontalVelocity + (vect(0,0,1) * RelativeVelocity.Z) + LastKnownBaseVelocity;
            }
        }

        // Prevent wallboosts - corrects the velocity calculation when the inward angle exploit is used
        if (CurrentMove.IsA('TdMove_WallrunJump') && OldMove.IsA('TdMove_WallRun'))
        {
            WallrunJumpMove = TdMove_WallrunJump(CurrentMove);

            if (WallrunJumpMove != none && myPawn.IllegalLedgeNormal != vect(0,0,0))
            {
                WallNormal = Normal(myPawn.IllegalLedgeNormal);

                CamDir = vector(Rotation);
                CamDir.Z = 0;
                CamDir = Normal(CamDir);
                
                PushSpeed = WallNormal Dot CamDir;

                if (PushSpeed < 0)
                {
                    WallProjVelocity = PreviousPawnVelocity - (WallNormal * (PreviousPawnVelocity Dot WallNormal));
                    WallProjVelocity.Z = 0;

                    PushAwaySpeed = WallrunJumpMove.default.WallRunningPushAwaySpeedNoob + (WallrunJumpMove.default.WallRunningPushAwaySpeedProAdd * 0);
                    CorrectPushAwayVelocity = WallNormal * PushAwaySpeed;

                    ParallelMultiplier = WallrunJumpMove.default.WallRunningPushForwardSpeedMin + ((1.0 - WallrunJumpMove.default.WallRunningPushForwardSpeedMin) * (1.0 - 0));
                    CorrectParallelVelocity = WallProjVelocity * ParallelMultiplier;

                    CorrectHorizontalVelocity = CorrectPushAwayVelocity + CorrectParallelVelocity;

                    myPawn.Velocity.X = CorrectHorizontalVelocity.X;
                    myPawn.Velocity.Y = CorrectHorizontalVelocity.Y;
                }
            }
        }

        // Prevent wallrun kick speed boosts
        if (CurrentMove.IsA('TdMove_MeleeWallrun') && OldMove.IsA('TdMove_WallRun'))
        {
            PreviousWallrunMove = TdMove_WallRun(OldMove);
            if (PreviousWallrunMove != none)
            {
                WallNormal = PreviousWallrunMove.WallNormal;

                ActualParallelVelocity = PreviousPawnVelocity - (WallNormal * (PreviousPawnVelocity Dot WallNormal));
                ActualParallelVelocity.Z = 0;
                
                CorrectParallelVelocity = Normal(ActualParallelVelocity) * PreviousWallrunMove.WallRunningBeginSpeed;

                if (VSizeSq(ActualParallelVelocity) > VSizeSq(CorrectParallelVelocity))
                {
                    ErrorVelocity = ActualParallelVelocity - CorrectParallelVelocity;
                    myPawn.Velocity -= ErrorVelocity;
                }
            }
        }
        
        // Infinite wallclimb prevention
        if (CurrentMove.IsA('TdMove_WallClimbDodgeJump'))
        {
            bIsPostWCDJFalling = true;

            if (myPawn.Moves[4] != none)
            {
                myPawn.Moves[4].LastStopMoveTime = WorldInfo.TimeSeconds;
            }
            if (myPawn.Moves[5] != none)
            {
                myPawn.Moves[5].LastStopMoveTime = WorldInfo.TimeSeconds;
            }
        }

        // If we did a wallclimb sidestep, do not allow us to grab/step up to a ledge that is higher than the point we sidestepped
        if (bIsPostWCDJFalling)
        {
            CurrentPhysicsMove = TdPhysicsMove(CurrentMove);
            if (CurrentPhysicsMove != none)
            {
                if (myPawn.Location.Z > myPawn.LastJumpLocation.Z)
                {
                    CurrentPhysicsMove.bCheckForGrab = false;
                    CurrentPhysicsMove.bCheckForVaultOver = false;
                    CurrentPhysicsMove.bCheckForWallClimb = false;
                    
                    if (myPawn.Moves[MOVE_AUTOSTEPUP] != none)
                    {
                        myPawn.Moves[MOVE_AUTOSTEPUP].LastStopMoveTime = WorldInfo.TimeSeconds;
                    }
                    if (myPawn.Moves[MOVE_STEPUP] != none)
                    {
                        myPawn.Moves[MOVE_STEPUP].LastStopMoveTime = WorldInfo.TimeSeconds;
                    }
                }
                else
                {
                    CurrentPhysicsMove.bCheckForGrab = CurrentPhysicsMove.default.bCheckForGrab;
                    CurrentPhysicsMove.bCheckForVaultOver = CurrentPhysicsMove.default.bCheckForVaultOver;
                    CurrentPhysicsMove.bCheckForWallClimb = CurrentPhysicsMove.default.bCheckForWallClimb;
                }
            }

            if (!CurrentMove.IsA('TdMove_Falling') && !CurrentMove.IsA('TdMove_WallClimbDodgeJump'))
            {
                bIsPostWCDJFalling = false;
            }
        }

        // Sidestep boost prevention
        if (CurrentMove.IsA('TdMove_DodgeJump'))
        {
            bPendingDodgeJumpLanding = true;
        }
        else if (bPendingDodgeJumpLanding && myPawn.Physics == PHYS_Walking)
        {
            DodgeJumpLandingBlockTimer = DeltaTime * 2;
            bPendingDodgeJumpLanding = false;
        }
        else if (bPendingDodgeJumpLanding && myPawn.Physics != PHYS_Falling)
        {
            bPendingDodgeJumpLanding = false;
        }
        if (DodgeJumpLandingBlockTimer > 0)
        {
            DodgeJumpLandingBlockTimer -= DeltaTime;

            myPawn.Velocity = vect(0,0,0);
            myPawn.Acceleration = vect(0,0,0);
            
            if (!CurrentMove.IsA('TdMove_MeleeBase'))
            {
                bShouldIgnoreInput = true;
            }
        }

        // Hard landing movement disable logic
        if (CurrentMove.IsA('TdMove_Landing'))
        {
            bShouldIgnoreInput = true;
        }

        if (bShouldIgnoreInput)
        {
            myPawn.SetIgnoreMoveInput();
        }
        else
        {
            if(OldMove != none && (OldMove.IsA('TdMove_Landing') || OldMove.IsA('TdMove_DodgeJump')))
            {
                myPawn.StopIgnoreMoveInput();
            }
        }

        // Fling prevention
        if (CurrentMove.IsA('TdMove_SpringBoard') || CurrentMove.IsA('TdMove_SwingJump'))
        {
            myPawn.LastJumpLocation = myPawn.Location;
        }

        // Sliding wallclimb prevention
        WallClimbMove = TdMove_WallClimb(CurrentMove);
        if (WallClimbMove != none && !WallClimbMove.bHasReachedWall)
        {
            OriginalZVelocity = myPawn.Velocity.Z;
            
            HorizontalVelocity = myPawn.Velocity;
            HorizontalVelocity.Z = 0;
            WallNormal = myPawn.MoveNormal;

            PerpendicularVelocity = ProjectOnTo(HorizontalVelocity, WallNormal);

            myPawn.Velocity = PerpendicularVelocity;

            myPawn.Velocity.Z = OriginalZVelocity;
        }

        // Hint climb prevention
        if (CurrentMove.IsA('TdMove_WallClimb180TurnJump'))
        {
            bPending180TurnJumpFalling = true;
        }
        else if (bPending180TurnJumpFalling && !CurrentMove.IsA('TdMove_Falling'))
        {
            bPending180TurnJumpFalling = false;
        }

        // Prevent walking states ontop of barbed wire volumes
        for (i = 0; i < myPawn.Touching.Length; i++)
        {
            BarbedWire = TdBarbedWireVolume(myPawn.Touching[i]);
            if (BarbedWire != none)
            {
                BarbedWire.Touch(myPawn, myPawn.CylinderComponent, myPawn.Location, vect(0,0,1));
            }
        }

        BalanceVolume = TdBalanceWalkVolume(myPawn.PhysicsVolume);
        if (BalanceVolume != none)
        {
            if (myPawn.MovementState == 1)
            {
                myPawn.SetMove(29);
            }
        }
        else
        {
            if (myPawn.MovementState == 29)
            {
                myPawn.SetMove(1);
            }
        }

        // Prevent glides - intercepts SetPreciseLocation
        if (CurrentMove.IsA('TdMove_Jump'))
        {
            JumpMove = TdMove_Jump(CurrentMove);

            if (JumpMove != none && myPawn.Physics == PHYS_Flying && JumpMove.bUsePreciseLocation)
            {
                JumpMove.bUsePreciseLocation = false;

                myPawn.SetCollision(true, true);
                myPawn.bCollideWorld = true;
                myPawn.SetPhysics(PHYS_Falling);

                myPawn.Velocity = JumpMove.WantedJumpVelocity;

                ForwardVelocityFloat = vector(myPawn.Rotation) Dot myPawn.Velocity;

                if (ForwardVelocityFloat < 5.0f)
                {
                    JumpMove.PlayMoveAnim(3, name("JumpStill"), 1.0f, 0.15f, 0.15f);        
                }
                else if (ForwardVelocityFloat < JumpMove.default.LongJumpNormalThreshold)
                {
                    JumpMove.PlayMoveAnim(3, name("JumpSlow"), 1.0f, JumpMove.default.JumpBlendInTime, JumpMove.default.JumpBlendOutTime);            
                }
                else
                {
                    JumpMove.PlayMoveAnim(3, name("JumpFast"), 1.0f, JumpMove.default.JumpBlendInTime, JumpMove.default.JumpBlendOutTime);
                }
            }
        }

        // Prevent beamers
        if (CurrentMove.IsA('TdMove_WallClimb180TurnJump') || CurrentMove.IsA('TdMove_WallClimbDodgeJump'))
        {
            if(CurrentMove.IsA('TdMove_WallClimb180TurnJump'))
            {
                TheoreticalMaxSpeed = 980.0f; 
            }
            else
            {
                TheoreticalMaxSpeed = 1002.0f;
            }

            TheoreticalMaxSpeedSq = TheoreticalMaxSpeed * TheoreticalMaxSpeed;

            if (VSizeSq(myPawn.Velocity) > TheoreticalMaxSpeedSq)
            {
                if (CurrentMove.IsA('TdMove_WallClimb180TurnJump'))
                {
                    myPawn.Velocity.X = 0;
                    myPawn.Velocity.Y = 0;
                }
                else if (CurrentMove.IsA('TdMove_WallClimbDodgeJump'))
                {
                    DodgeJumpMove = TdMove_WallClimbDodgeJump(CurrentMove);
                    if (DodgeJumpMove != none)
                    {
                        if (myPawn.MoveActionHint == MAH_Left)
                        {
                            DodgeDirection = (-1.0f * DodgeJumpMove.default.JumpAddXY) * Normal(vect(0, 0, 1) Cross vector(myPawn.Rotation));
                        }
                        else
                        {
                            DodgeDirection = (DodgeJumpMove.default.JumpAddXY) * Normal(vect(0, 0, 1) Cross vector(myPawn.Rotation));
                        }

                        CorrectVelocity = DodgeDirection;
                        CorrectVelocity.Z = DodgeJumpMove.default.BaseJumpZ;

                        myPawn.Velocity = CorrectVelocity;
                    }
                }
            }
        }

        // Prevent ceiling clips
        if (CurrentMove.IsA('TdMove_SpeedVault'))
        {
            VaultMove = TdMove_SpeedVault(CurrentMove);

            if (VaultMove != none && VaultMove.ActiveVaultType == 5 && VaultMove.MoveActiveTime < 0.1f)
            {
                Extent = myPawn.GetCollisionExtent();
                
                TraceStart = myPawn.Location;
                TraceStart.Z += Extent.Z; 

                TraceEnd = TraceStart;
                TraceEnd.Z += 10.0f;
                
                if (myPawn.Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true, Extent) != none)
                {
                    myPawn.SetCollision(true, true);
                    myPawn.bCollideWorld = true;
                    myPawn.StopAllCustomAnimations(0);
                    myPawn.SetMove(MOVE_Falling);
                }
            }
        }

        // Hidden springboard prevention
        if (myPawn.MovementState == MOVE_SpringBoarding && myPawn.OldMovementState != MOVE_SpringBoarding)
        {
            FoundSurfaceActor = myPawn.MovementActor;
            bIsValidSurface = false;

            if (FoundSurfaceActor != none)
            {
                if (FoundSurfaceActor.IsA('BlockingVolume'))
                {
                    bIsValidSurface = true;
                }
                else
                {
                    FoundStaticMeshActor = StaticMeshActor(FoundSurfaceActor);
                    if (FoundStaticMeshActor != none && FoundStaticMeshActor.StaticMeshComponent != none)
                    {
                        if (SpringboardMeshRef == none) 
                        {
                            SpringboardMeshRef = StaticMesh(DynamicLoadObject("P_Gameplay.SpringBoard.SpringBoardHigh_ColMesh", class'StaticMesh'));
                        }
                        
                        if (FoundStaticMeshActor.StaticMeshComponent.StaticMesh == SpringboardMeshRef)
                        {
                            bIsValidSurface = true;
                        }
                    }
                }
            }

            if (!bIsValidSurface)
            {
                myPawn.SetMove(MOVE_Falling);
            }
        }

        // Prevent left/right camera input during springboards
        if (CurrentMove.IsA('TdMove_SpringBoard'))
        {
            myPawn.SetIgnoreLookInput(-1);
        }

        // Prevent lay on back movement when landing on soft landing pads
        if (CurrentMove.IsA('TdMove_Landing') && (OldMove.IsA('TdMove_FallingUncontrolled') || OldMove.IsA('TdMove_SoftLanding')))
        {
            SoftLandingMove = TdMove_SoftLanding(myPawn.Moves[78]);

            LandingBackwardsDot = Normal(vector(myPawn.Rotation)) Dot Normal(PreviousPawnVelocity);
            bIsLandingBackwards = (SoftLandingMove != none && SoftLandingMove.bMovingBackwards) || (LandingBackwardsDot < -0.3f);

            if (SoftLandingMove != none && (SoftLandingMove.bMovingBackwards || bIsLandingBackwards))
            {
                myPawn.SetMove(26);
                myPawn.SetIgnoreMoveInput(-1);
                myPawn.SetIgnoreLookInput(-1);
                LayOnGroundMove = TdMove_LayOnGround(myPawn.Moves[26]);

                if (LayOnGroundMove != none)
                {
                    myPawn.Velocity = vect(0,0,0);
                    LayOnGroundMove.ResetCameraLook(0.3f);
                }
            }
        }

        // Dirty disarm prevention for celeste boss fight when backflopping on her head
        if (CurrentMove.IsA('TdMove_LayOnGround') && WorldInfo.GetMapName() == "Boat_p")
        {
            ConsoleCommand("set TdAi_Celeste bIsVulnerableToDisarm false");
        }

        // Prevent dropkick death cancels
        if (myPawn.Physics == PHYS_Falling && myPawn.MovementState != MOVE_FallingUncontrolled)
        {
            if (myPawn.EnterFallingHeight > 0)
            {
                if ((myPawn.EnterFallingHeight - myPawn.Location.Z) > myPawn.FallingUncontrolledHeight)
                {
                    if (myPawn.CanDoMove(MOVE_FallingUncontrolled))
                    {
                        myPawn.SetMove(MOVE_FallingUncontrolled);
                    }
                }
            }
        }

        // Strang prevention
        if (myPawn.MovementState == MOVE_Walking && myPawn.Physics == PHYS_Walking)
        {
            TheoreticalMaxSpeed = myPawn.default.GroundSpeed;
            TheoreticalMaxSpeedSq = TheoreticalMaxSpeed * TheoreticalMaxSpeed;

            HorizontalVelocity = myPawn.Velocity;
            HorizontalVelocity.Z = 0;

            if (VSizeSq(HorizontalVelocity) > TheoreticalMaxSpeedSq)
            {
                OriginalZVelocity = myPawn.Velocity.Z;

                HorizontalVelocity = Normal(HorizontalVelocity) * TheoreticalMaxSpeed;

                myPawn.Velocity = HorizontalVelocity;
                myPawn.Velocity.Z = OriginalZVelocity;
            }
        }

        OldMove = myPawn.Moves[myPawn.OldMovementState];
        PreviousPawnVelocity = myPawn.Velocity;
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
}

function TrueGlitchlessJumpscare()
{
    local float Chance;

    Chance = FRand();
    if (Chance <= 0.001)
    {
        TrainSound = SoundCue(DynamicLoadObject("A_SP04.Trains.Horn_Long", class'SoundCue'));
        ClientHearSound(TrainSound, self, Location, false, false);
    }
}

function Reset()
{
    super(PlayerController).Reset();
    PlayerInput.ResetInput();
    bCinemaDisableInputMove = false;
    bCinemaDisableInputLook = false;
    bCinematicMode = false;
    bIgnoreLookInput = 0;
    bIgnoreMoveInput = 0;
    bGodMode = false;
    ClientStopForceFeedbackWaveform();
    bOverrideReactionTimeSettings = false;
    ReactionTimeEnergy = 0;
    UpdateReactionTime(1);
    bReactionTime = false;
    ReactionTimeEnergy = ReactionTimeSpawnLevel;
    TargetingPawn = none;
    TargetingPawnInterp = 0;
    TargetPawn = none;
    TargetActor = none;
    CurrentLookAtPoint = none;
    CurrentForcedLookAtPoint = none;
    bLeftThumbStickPassedDeadZone = default.bLeftThumbStickPassedDeadZone;
    bRightThumbStickPassedDeadZone = default.bRightThumbStickPassedDeadZone;
    LocalEnemies.Length = 0;
    bDisableLoadFromLastCheckpoint = false;
    AddStatsEvent(7);

    if (bTrueGlitchless)
    {
        bIsPostWCDJFalling = false;
        bPendingDodgeJumpLanding = false;
        bPending180TurnJumpFalling = false;
        DodgeJumpLandingBlockTimer = 0.0f;
    }
}

defaultproperties
{
}