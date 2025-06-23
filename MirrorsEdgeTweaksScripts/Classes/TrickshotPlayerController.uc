/**
 *  Meme class that removes restrictions on weapons.
 *
 *  Trickshot time baby
 */

class TrickshotPlayerController extends TdPlayerController
    native
    config(Game)
    hidecategories(Navigation)
    implements(TdController);

var SaveLoadHandlerTSHUD SaveLoad;
var transient float LastKnownScore;

var bool bBruteforce;
var bool bHeavyPose;
var bool bInstantSwitch;
var bool bFullAuto;
var bool bIsHoldingZoomKey;
var bool bEnableHoldToZoom;

var Name ZoomKey;
var Name WallrunFireKey;

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

    bEnableHoldToZoom = false; // Default to original zoom behavior
}

event PlayerTick(float DeltaTime)
{
    local TdMove_StumbleBase StumbleMove;
    local TdWeapon_Heavy HeavyWeapon;
    local TdWeapon_Sniper_BarretM95 SniperWeapon;
    local float CurrentScore;

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

    if (bEnableHoldToZoom && bIsHoldingZoomKey)
    {
        if (ZoomKey != '' && PlayerInput.PressedKeys.Find(ZoomKey) == -1) 
        {
            self.UnZoom();
            bIsHoldingZoomKey = false;
        }
    }

    StumbleMove = TdMove_StumbleBase(myPawn.Moves[35]);
    if (StumbleMove.DisableMovementTime != 0)
    {
        StumbleMove.DisableMovementTime = 0;
    }
    if (StumbleMove.DisableLookTime != 0)
    {
        StumbleMove.DisableLookTime = 0;
    }
    if (StumbleMove.MovementGroup != MG_Free)
    {
        StumbleMove.MovementGroup = MG_Free;
    }

    // Make sniper OP
    HeavyWeapon = TdWeapon_Heavy(myPawn.Weapon);
    if (HeavyWeapon != none && HeavyWeapon.WeaponType != EWT_Light)
    {
        HeavyWeapon.WeaponType = EWT_Light;
    }

    SniperWeapon = TdWeapon_Sniper_BarretM95(myPawn.Weapon);
    if (SniperWeapon != none && SniperWeapon.AdditionalUnzoomedSpread != 0)
    {
        SniperWeapon.AdditionalUnzoomedSpread = 0;
    }

    if (myPawn.Weapon != none)
    {
        if (myPawn.Mesh3p != none && myPawn.Mesh3p.AnimSets[1] != myPawn.CommonArmedHeavy3p)
        {
            myPawn.Mesh3p.AnimSets[1] = myPawn.CommonArmedHeavy3p;
            myPawn.Mesh3p.UpdateAnimations();
        }

        if (bHeavyPose)
        {
            if (myPawn.Mesh1p != none && myPawn.Mesh1p.AnimSets[1] != myPawn.CommonArmedHeavy1p)
            {
                myPawn.Mesh1p.AnimSets[1] = myPawn.CommonArmedHeavy1p;
                myPawn.Mesh1p.UpdateAnimations();
            }

            if (myPawn.WeaponAnimState == WS_Relaxed)
            {
                myPawn.SetWeaponAnimState(WS_Ready);
            }
        }
    }
}

exec function SetWallrunFireKey(Name NewKeyName) 
{
    if (NewKeyName == '')
    {
        ClientMessage("Alternate Attack key cannot be empty. Current key: " $ string(WallrunFireKey));
        return;
    }
    WallrunFireKey = NewKeyName;
    ClientMessage("Wallrun fire key set to: " $ string(WallrunFireKey));

    SaveLoad.SaveData("WallrunFireKey", string(WallrunFireKey));
}

exec function AttackPress()
{
    if ((myPawn.MovementState == 4 || myPawn.MovementState == 5))
    {
        if (WallrunFireKey != '' && PlayerInput.PressedKeys.Find(WallrunFireKey) != -1)
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

    if(!myPawn.HasWeapon())
    {
        myPawn.HandleMoveAction(3);
    }
    else
    {
        StartFire();
    }
}

exec function StartFire(optional byte FireModeNum)
{
    if (!bBruteforce)
    {
        if(((myPawn.Weapon.IsA('TdWeapon_Light') && myPawn.Moves[myPawn.MovementState].MovementGroup >= 2) || myPawn.Weapon.IsA('TdWeapon_Heavy') && myPawn.Moves[myPawn.MovementState].MovementGroup >= 1) || myPawn.WeaponAnimState == 4)
        {
            return;
        }
        super(PlayerController).StartFire(FireModeNum);
    }
    else
    {
        super(PlayerController).StartFire(FireModeNum);
    }
}

function InstantDropWeapon()
{
    local TdWeapon TdW;

    TdW = myPawn.MyWeapon;
    if (TdW == none)
    {
        return;
    }

    if ((myPawn.WeaponAnimState == 4) || myPawn.IsTimerActive('RemoveWeaponAfterDrop'))
    {
        return;
    }

    myPawn.ClearTimer('DropWeapon'); 
    if (TdW.IsZoomingOrZoomed())
    {
        myPawn.SetTimer(0.5, false, 'DropWeapon');
        return;
    }

    SafeRemoveWeapon();
}

function SafeRemoveWeapon()
{
    local TdWeapon TdW;
    local TdInventoryManager InvMan;

    if (myPawn == none)
    {
        return;
    }

    TdW = myPawn.MyWeapon;
    InvMan = TdInventoryManager(myPawn.InvManager);

    if (TdW != none && InvMan != none)
    {
        if (!TdW.bHidden)
        {
            myPawn.TossWeapon(TdW);
        }

        InvMan.RemoveFromInventory(TdW);

        myPawn.SetAimOffsetNodesProfile('OneHanded');
    }
}

exec function PressedSwitchWeapon()
{
    local TdInventoryManager InvMan;
    local TdMOVE_Disarm DisarmMove;

    if(IsButtonInputIgnored())
    {
        return;
    }
    myPawn.OnTutorialEvent(19);
    InvMan = TdInventoryManager(Pawn.InvManager);
    DisarmTimeMultiplier = 1;

    if(myPawn.Weapon != none)
    {
        UnZoom();

        if (!bInstantSwitch)
        {
            myPawn.DropWeapon();
            return;
        }
        else
        {
            InstantDropWeapon();
            return;
        }
    }
    else
    {
        // Try our custom pickup function that bypasses movement checks
        if (ForceWeaponPickup())
        {
            return;
        }
        else if (SnatchAttempt())
        {
            return;
        }
        else if((InvMan != none) && myPawn.Moves[myPawn.MovementState].bAllowPickup)
        {
            // Let the game try its normal way
            InvMan.PressedSwitchWeapon();
            if(myPawn.Weapon == none)
            {
                DisarmMove = TdMOVE_Disarm(myPawn.Moves[18]);
                DisarmMove.ForceMiss(true);
                myPawn.HandleMoveAction(4);
            }
        }
    }
    if((myPawn.Weapon != none) && myPawn.Weapon.IsA('TdWeapon_Sniper_BarretM95'))
    {
        CallPopUp(1, 4);
    }
}

function bool ForceWeaponPickup()
{
    local TdPickup BestPickup;
    local TdPickup P;
    local TdInventoryManager InvMan;
    local TdWeapon WeaponToPickup;
    local Inventory.EInventorySlot FreeSlot;
    local float BestDistSq, DistSq;
    
    local float MaxPickupRadius;
    MaxPickupRadius = 1000.0;

    InvMan = TdInventoryManager(Pawn.InvManager);
    if (InvMan == None)
    {
        return false;
    }

    BestDistSq = MaxPickupRadius * MaxPickupRadius;

    foreach AllActors(class'TdPickup', P)
    {
        DistSq = VSizeSq(P.Location - Pawn.Location);

        if (DistSq > (MaxPickupRadius * MaxPickupRadius))
        {
            continue;
        }

        if (P.GetAmmoCount() > 0)
        {
            if (DistSq < BestDistSq)
            {
                BestDistSq = DistSq;
                BestPickup = P;
            }
        }
    }

    if (BestPickup != None)
    {
        if (BestPickup.Inventory == none)
        {
            BestPickup.Inventory = Spawn(BestPickup.InventoryClass);
        }

        WeaponToPickup = TdWeapon(BestPickup.Inventory);
        if (WeaponToPickup != none)
        {
            FreeSlot = InvMan.FindFreeSlotForWeaponClass(WeaponToPickup.Class);
            if (FreeSlot != 0)
            {
                BestPickup.GiveTo(Pawn);
                InvMan.SwitchToWeaponInSlot(FreeSlot);
                return true;
            }
        }
    }

    return false;
}

exec function SetZoomKey(Name NewKeyName)
{
    local TdProfileSettings Profile;
    local int ZoomAction;
    local name KeyBinds[4];
    local int KeyActionProfileId; // The TDPID_KeyAction_XX value
    local int KeyBindingValue;
    local int KeyEnumValue;
    local int KeyBindIdx;

    if (NewKeyName == '')
    {
        ClientMessage("Zoom key cannot be empty. Current key: " $ string(ZoomKey));
        return;
    }
    ZoomKey = NewKeyName;
    ClientMessage("Zoom key set to: " $ string(ZoomKey));

    Profile = GetProfileSettings();
    if (Profile == none)
    {
        ClientMessage("Failed to get profile settings.");
        return;
    }
    
    ZoomAction = Profile.GetDBAFromCommand("GBA_ZoomWeapon");

    KeyActionProfileId = 501 + ZoomAction; 

    KeyBinds[0] = NewKeyName;

    KeyBindingValue = 0; 
    for (KeyBindIdx = 0; KeyBindIdx < 1; KeyBindIdx++)
    {
        if (KeyBinds[KeyBindIdx] != 'None')
        {
            KeyEnumValue = Profile.FindKeyEnum(KeyBinds[KeyBindIdx]); 
            if (KeyEnumValue != -1)
            {
                KeyBindingValue = KeyBindingValue | (KeyEnumValue << (KeyBindIdx * 8));
            }
        }
    }

    if (!Profile.SetProfileSettingValueInt(KeyActionProfileId, KeyBindingValue))
    {
        ClientMessage("Failed to set keybind via SetProfileSettingValueInt. Profile not modified for this keybind.");
        return; 
    }

    if (PlayerInput != none)
    {
        Profile.ApplyAllKeyBindings(PlayerInput); 
        PlayerInput.SaveConfig(); 
    }

    if (OnlinePlayerData != none)
    {
        OnlinePlayerData.SaveProfileData();
    }
}

exec function HoldToZoom()
{
    bEnableHoldToZoom = !bEnableHoldToZoom;
    if (bEnableHoldToZoom)
    {
        ClientMessage("Hold to zoom enabled");

        if (ZoomKey != '' && PlayerInput.PressedKeys.Find(ZoomKey) == -1)
        {
            bIsHoldingZoomKey = false;
        }
    }
    else
    {
        ClientMessage("Hold to zoom disabled");

        if (bIsHoldingZoomKey) {
            self.UnZoom();
            bIsHoldingZoomKey = false;
        }
    }
}

exec function ZoomWeapon()
{
    local TdWeapon TdW;
    local float FOV, Rate, delay;

    if (bEnableHoldToZoom)
    {
        if (!bIsHoldingZoomKey && PlayerInput.PressedKeys.Find(ZoomKey) != -1)
        {
            TdW = TdWeapon(Pawn.Weapon);

            if (TdW != none) 
            {
                TdW.ToggleZoom(FOV, Rate, delay);
                self.StartZoom(FOV, Rate, delay);
                bIsHoldingZoomKey = true; 
            }
        }
    }
    else
    {
        TdW = TdWeapon(Pawn.Weapon);
        if(TdW != none)
        {
            TdW.ToggleZoom(FOV, Rate, delay);
            self.StartZoom(FOV, Rate, delay);
        }
    }
}

function Reset()
{
    super.Reset();
    LastKnownScore = PlayerReplicationInfo.Score;
    bIsHoldingZoomKey = false;
}

function PawnDied(Pawn inPawn)
{
    super.PawnDied(inPawn);
    LastKnownScore = PlayerReplicationInfo.Score;
    if (bIsHoldingZoomKey)
    {
        self.UnZoom();
        bIsHoldingZoomKey = false;
    }
}

function SetCinematicMode(bool bInCinematicMode, bool bHidePlayer, bool bAffectsHUD, bool bAffectsMovement, bool bAffectsTurning, bool bAffectsButtons, bool bSwitchSoundMode)
{
    if (!bBruteforce)
    {
        if(bInCinematicMode)
        {
            if(bSwitchSoundMode)
            {
                SetSoundMode(7);
            }
            SetTimer(1.2, false, 'CallSkippablePopUp');        
        }
        else
        {
            if(bSwitchSoundMode)
            {
                ClearSoundMode();
            }
        }
        super(PlayerController).SetCinematicMode(bInCinematicMode, bHidePlayer, bAffectsHUD, bAffectsMovement, bAffectsTurning, bAffectsButtons, bSwitchSoundMode);
    }
}

reliable client simulated function ClientSetCinematicMode(bool bInCinematicMode, bool bAffectsMovement, bool bAffectsTurning, bool bAffectsHUD)
{
    if (!bBruteforce)
    {
        bCinematicMode = bInCinematicMode;
        if((myHUD != none) && bAffectsHUD)
        {
            myHUD.bShowHUD = !bCinematicMode;
        }
        if(bAffectsMovement)
        {
            IgnoreMoveInput(bCinematicMode);
        }
        if(bAffectsTurning)
        {
            IgnoreLookInput(bCinematicMode);
        }
    }
}

function OnTdDisablePlayerInput(SeqAct_TdDisablePlayerInput Action)
{
    if (!bBruteforce)
    {
        if(Action.bSetCinematicMode)
        {
            UnZoom();
            myPawn.DropWeapon();
            SetCinematicMode(true, false, false, Action.bDisablePlayerMoveInput, Action.bDisablePlayerLookInput, true, true);        
        }
        else
        {
            IgnoreMoveInput(Action.bDisablePlayerMoveInput);
            IgnoreLookInput(Action.bDisablePlayerLookInput);
        }
        IgnoreButtonInput(true);
        bDuck = 0;
        bReleasedJump = true;
        bGodMode = true;
        if(Action.bDisableSkipCutscenes)
        {
            bDisableSkipCutscenes = true;
        }
    }
}

exec function Bruteforce()
{
    bBruteforce = !bBruteforce;
    ClientMessage("Trickshot bruteforce mode set to " $ bBruteforce);
}

exec function HeavyPose()
{
    bHeavyPose = !bHeavyPose;
    ClientMessage("Heavy weapon pose mode set to " $ bHeavyPose);
}

exec function InstantSwitch()
{
    bInstantSwitch = !bInstantSwitch;

    if (bInstantSwitch)
    {
        ConsoleCommand("set TdWeapon_Sniper_BarretM95 EquipTime 0");
    }
    else
    {
        ConsoleCommand("set TdWeapon_Sniper_BarretM95 EquipTime 0.75");
    }
    ClientMessage("Instant weapon equip/drop set to " $ bInstantSwitch);
}

exec function M95FireRate(float FireRate)
{
    ConsoleCommand("set TdWeapon_Sniper_BarretM95 FireInterval (" $ FireRate $ ")");
    ClientMessage("M95 fire rate set to " $ FireRate $ " seconds");
}

exec function FullAuto()
{
    bFullAuto = !bFullAuto;

    ConsoleCommand("set TdWeapon bAutomaticRefire (" $ bFullAuto $ ")");
    ClientMessage("Full auto mode for all weapons set to " $ bFullAuto);
}

reliable client simulated function ClientRestart(Pawn NewPawn)
{
    super(PlayerController).ClientRestart(NewPawn);
    bReactionTime = false;
    ReactionTimeEnergy = ReactionTimeSpawnLevel;
    bOverrideReactionTimeSettings = false;
    AddStatsEvent(7);
    WorldInfo.Game.SetGameSpeed(1);
    if(myHUD != none)
    {
        TdHUD(myHUD).PlayerOwnerRestart();
    }
    SetAudioProfileSettings();
    SetPause(false);
    SetSoundMode(0,, true, 1.5);
    LastKnownScore = PlayerReplicationInfo.Score;
}

// Stop any other state that might make us unzoom the sniper, shorten wallkick targetting distance, make collats work
function AdditionalTrickshotSetup()
{
    ConsoleCommand("set TdMove bShouldUnzoom false");
    ConsoleCommand("set TdMove_MeleeBase TargetingMaxDistance 50");
    ConsoleCommand("set TdMove_MeleeAir TargetingMaxDistance 50");
    ConsoleCommand("set TdBotPawn bIgnoreForAITraces true");
    ConsoleCommand("set TdWeapon PassThroughLimit 999999");
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
    ZoomKey="F"
    WallrunFireKey="RightMouseButton"
    LastKnownScore = 0
}