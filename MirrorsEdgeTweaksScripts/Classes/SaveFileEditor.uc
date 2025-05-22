class SaveFileEditor extends TdCheatManager;

var CheatHelperProxy HelperProxy;
var bool bIsProfileSaving;
var TdProfileSettings Profile;
var OnlineSubsystem OnlineSub;
var UIDataStore_OnlinePlayerData PlayerDataStore;
var UIDataProvider_OnlineProfileSettings ProfileDataProvider;

var LocalPlayer LocPlayer;  
var TdGameViewportClient ViewportClient;
var TdUIInteraction UIController;

exec function EnsureHelperProxy()
{
    if (HelperProxy == None)
    {
        HelperProxy = WorldInfo.Spawn(class'CheatHelperProxy');
        HelperProxy.SaveFileEditorReference = self;
    }
}

function OnTick(float DeltaTime)
{
    local OnlineProfileSettings OnlineProf;
    local byte ControllerId;

    OnlineSub = Class'GameEngine'.static.GetOnlineSubsystem();
    ControllerId = byte(Class'UIInteraction'.static.GetPlayerControllerId(0));
    OnlineProf = OnlineSub.PlayerInterface.GetProfileSettings(ControllerId);

    if((OnlineProf != none) && OnlineProf.AsyncState == OPAS_Write)
    {
        if(!bIsProfileSaving)
        {
            bIsProfileSaving = true;

            LocPlayer = LocalPlayer(Outer.Player);

            if (LocPlayer.ViewportClient != none)
            {
                ViewportClient = TdGameViewportClient(LocPlayer.ViewportClient); 
                if (ViewportClient != none && ViewportClient.UIController != none)
                {
                    UIController = TdUIInteraction(ViewportClient.UIController); 
                    if (UIController != none)
                    {
                        UIController.BlockUIInput(true);
                    }
                }
            }
        }   
    }
    else
    {
        if(bIsProfileSaving)
        {
            bIsProfileSaving = false;
            UIController.BlockUIInput(false);
        }
    }
}

exec function UnlockProgression(optional bool bStory, optional bool bTimeTrials)
{
    local bool bAnySettingChangedSuccessfully;
    local bool bCurrentOpSuccess;

    bAnySettingChangedSuccessfully = false;

    EnsureHelperProxy();
    Profile = Outer.GetProfileSettings();
    if (Profile == none)
    {
        ClientMessage("UnlockProgression: Failed to get profile settings. No actions taken.");
        return;
    }

    if (bStory)
    {
        // Profile.UnlockAllLevels() internally calls SetProfileSettingValueInt(TDPID_LevelUnlockMask, -1)
        bCurrentOpSuccess = Profile.UnlockAllLevels(); 
        if (bCurrentOpSuccess)
        {
            bAnySettingChangedSuccessfully = true;
        }
        else
        {
            ClientMessage("UnlockProgression: FAILED to apply settings to unlock Story Levels (Normal).");
        }
    }

    if (bTimeTrials)
    {
        // Profile.UnLockAllTTStretches() internally calls SetProfileSettingValueInt(TDPID_TimeTrialUnlockMask, -1)
        bCurrentOpSuccess = Profile.SetProfileSettingValueInt(Profile.TDPID_TimeTrialUnlockMask, -1); 
        if (bCurrentOpSuccess)
        {
            bAnySettingChangedSuccessfully = true;
        }
        else
        {
            ClientMessage("UnlockProgression: FAILED to apply settings to unlock Time Trials.");
        }
    }

    if (!bStory && !bTimeTrials)
    {
        ClientMessage("UnlockProgression: No unlock options specified. Use arguments like bStory=true, bStoryHard=true, or bTimeTrials=true.");
        return;
    }

    if (bAnySettingChangedSuccessfully)
    {
        if (Outer.OnlinePlayerData != none)
        {
            if (!Outer.OnlinePlayerData.SaveProfileData())
            {
                ClientMessage("UnlockProgression: Profile save FAILED. Changes may not persist.");
            }
        }
        else
        {
            ClientMessage("UnlockProgression: Could not get OnlinePlayerData for saving. Changes may not persist.");
        }
    }
    else
    {
        ClientMessage("UnlockProgression: No settings were successfully changed in the profile object, or operations failed/not selected. No save attempted.");
    }
}

exec function LockProgression(optional bool bStory, optional bool bTimeTrials)
{
    local bool bAnySettingChangedSuccessfully;
    local bool bCurrentOpSuccess;

    bAnySettingChangedSuccessfully = false;

    EnsureHelperProxy();
    Profile = Outer.GetProfileSettings();
    if (Profile == none)
    {
        ClientMessage("LockProgression: Failed to get profile settings. No actions taken.");
        return;
    }

    if (bStory)
    {
        // Profile.LockAllLevels() internally calls SetProfileSettingValueInt(TDPID_LevelUnlockMask, 0)
        bCurrentOpSuccess = Profile.LockAllLevels(); 
        if (bCurrentOpSuccess)
        {
            bAnySettingChangedSuccessfully = true;
        }
        else
        {
            ClientMessage("LockProgression: FAILED to apply settings to lock Story Levels (Normal).");
        }
    }

    if (bTimeTrials)
    {
        // Profile.LockAllTTStretches() internally calls SetProfileSettingValueInt(TDPID_TimeTrialUnlockMask, 0)
        bCurrentOpSuccess = Profile.SetProfileSettingValueInt(Profile.TDPID_TimeTrialUnlockMask, 0);
        if (bCurrentOpSuccess)
        {
            bAnySettingChangedSuccessfully = true;
        }
        else
        {
            ClientMessage("LockProgression: FAILED to apply settings to lock Time Trials.");
        }
    }

    if (!bStory && !bTimeTrials)
    {
        ClientMessage("LockProgression: No lock options specified. Use arguments like bStory=true, bStoryHard=true, or bTimeTrials=true.");
        return;
    }

    if (bAnySettingChangedSuccessfully)
    {
        if (Outer.OnlinePlayerData != none)
        {
            if (!Outer.OnlinePlayerData.SaveProfileData())
            {
                ClientMessage("LockProgression: Profile save FAILED. Changes may not persist.");
            }
        }
        else
        {
            ClientMessage("LockProgression: Could not get OnlinePlayerData for saving. Changes may not persist.");
        }
    }
    else
    {
        ClientMessage("LockProgression: No settings were successfully changed in the profile object, or operations failed/not selected. No save attempted.");
    }
}

function GhostWriteCompleteCallback(TdGhostStorageManager.EGhostStorageResult Result, optional int GhostTagReceived)
{
    local string ResultString;

    EnsureHelperProxy();

    switch (Result)
    {
        case 0: ResultString = "EGR_Ok (Success)"; break;
        case 1: ResultString = "EGR_OkNoGhost"; break;
        case 2: ResultString = "EGR_ErrorInconsistentTime"; break;
        case 3: ResultString = "EGR_Error"; break;
        case 4: ResultString = "EGR_IncompatibleVersion"; break;
    }
    if (Result != 0)
    {
        ClientMessage("GhostWriteCallback: Failed to write ghost data. Result: " $ ResultString $ ". (Tag: " $ GhostTagReceived $ ")");
    }
}

exec function ResetAllTimeTrialTimes(optional bool b69Stars)
{
    local float TimeToSet;
    local array<float> IntermediateTimesToSet;
    local int i;
    local int StretchIndex; // ETTStretch enum value will be used here
    local bool bOverallSuccess;

    // Ghost saving variables
    local TdOfflineGhostStorageManager LocalGhostStorageMgr;
    local TdGhost NewGhostRecord;
    local UniqueNetId PlayerId;
    local string PlayerName;
    local int ControllerId;

    EnsureHelperProxy();

    bOverallSuccess = true;

    if (b69Stars)
    {
        TimeToSet = 0.00f;
    }
    else
    {
        TimeToSet = 3599.99f; 
    }

    IntermediateTimesToSet.Length = 0;
    IntermediateTimesToSet.AddItem(TimeToSet);

    Profile = Outer.GetProfileSettings(); 
    if (Profile == none)
    {
        ClientMessage("ResetAllTimeTrialTimes: Failed to get profile settings.");
        return;
    }
    
    ControllerId = LocPlayer.ControllerId;
    OnlineSub = Class'GameEngine'.static.GetOnlineSubsystem();
    if (OnlineSub != none && OnlineSub.PlayerInterface != none)
    {
        PlayerName = OnlineSub.PlayerInterface.GetPlayerNickname(byte(ControllerId));
        if (!OnlineSub.PlayerInterface.GetUniquePlayerId(byte(ControllerId), PlayerId))
        {
            ClientMessage("ResetAllTimeTrialTimes: GetUniquePlayerId failed for ControllerId " $ ControllerId $ ".");
        }
    }
    else
    {
        ClientMessage("ResetAllTimeTrialTimes: Could not get OnlineSubsystem/PlayerInterface. Using fallback PlayerName.");
        PlayerName = "Faith"; 
    }

    OnlineSub = Class'GameEngine'.static.GetOnlineSubsystem();
    if (OnlineSub != none && OnlineSub.PlayerInterface != none)
    {
        PlayerName = OnlineSub.PlayerInterface.GetPlayerNickname(byte(ControllerId));
        if (!OnlineSub.PlayerInterface.GetUniquePlayerId(byte(ControllerId), PlayerId))
        {
            ClientMessage("ResetAllTimeTrialTimes: GetUniquePlayerId failed for ControllerId " $ ControllerId $ ". Ghost saving may use default ID.");
        }
    }
    else
    {
        ClientMessage("ResetAllTimeTrialTimes: Could not get OnlineSubsystem or PlayerInterface. Using fallback PlayerName for ghost.");
        PlayerName = "Faith"; 
    }

    if (Profile.TTUnlockTTCompletedMap.Length == 0)
    {
        ClientMessage("ResetAllTimeTrialTimes: TTUnlockTTCompletedMap is empty in profile. Cannot identify time trial stretches.");
    }
    
    for (i = 0; i < Profile.TTUnlockTTCompletedMap.Length; i++)
    {
        StretchIndex = Profile.TTUnlockTTCompletedMap[i].CompletedTT; 
        if (StretchIndex > 0)
        {
            if (!Profile.SetTTTimeForStretch(StretchIndex, TimeToSet, IntermediateTimesToSet, 0.0f, 0.0f))
            {
                ClientMessage("ResetAllTimeTrialTimes: Failed to set time for Time Trial Stretch Index " $ StretchIndex $ ".");
                bOverallSuccess = false;
            }
            else
            {
                NewGhostRecord = new class'TdGhost';
                if (NewGhostRecord != none)
                {
                    NewGhostRecord.Info.StretchId = StretchIndex;
                    NewGhostRecord.Info.PlayerName = PlayerName;
                    NewGhostRecord.Info.TotalTime = TimeToSet; 
                    NewGhostRecord.Info.GhostTag = 0; 
                    NewGhostRecord.RawBytes.Length = 0; 

                    LocalGhostStorageMgr = new class'TdOfflineGhostStorageManager';
                    if (LocalGhostStorageMgr != none)
                    {
                        if (!LocalGhostStorageMgr.WriteGhost(NewGhostRecord, PlayerId, GhostWriteCompleteCallback))
                        {
                            ClientMessage("ResetAllTimeTrialTimes: Call to WriteGhost failed to initiate for Stretch " $ StretchIndex $ ".");
                        }
                    }
                    else
                    {
                        ClientMessage("ResetAllTimeTrialTimes: Failed to create TdOfflineGhostStorageManager for Stretch " $ StretchIndex $ ".");
                    }
                }
                else
                {
                    ClientMessage("ResetAllTimeTrialTimes: Failed to create TdGhost object for Stretch " $ StretchIndex $ ".");
                }
            }
        }
    }

    if (!bOverallSuccess)
    {
        ClientMessage("ResetAllTimeTrialTimes: One or more time trial stretch times failed to update.");
    }

    if (Outer.OnlinePlayerData != none)
    {
        if (!Outer.OnlinePlayerData.SaveProfileData())
        {
            ClientMessage("ResetAllTimeTrialTimes: Profile times save failed. Changes may not persist.");
        }
    }
    else
    {
        ClientMessage("ResetAllTimeTrialTimes: Could not get OnlinePlayerData for saving profile times. Changes may not persist.");
    }
}

exec function ResetAllSpeedrunTimes()
{
    local float TimeToSet;
    local array<float> IntermediateTimesToSet;
    local int i, j;
    local int SpeedrunStretchIndex;
    local bool bOverallSuccess;
    local array<int> ActualTimeTrialStretchIndicies;
    local bool bIsActualTimeTrialStretch;

    EnsureHelperProxy();

    bOverallSuccess = true;
    TimeToSet = 3599.99f;

    IntermediateTimesToSet.Length = 0;
    IntermediateTimesToSet.AddItem(TimeToSet);

    Profile = Outer.GetProfileSettings();
    if (Profile == none)
    {
        ClientMessage("ResetAllSpeedrunTimes: Failed to get profile settings.");
        return;
    }

    ActualTimeTrialStretchIndicies.Length = 0;
    if (Profile.TTUnlockTTCompletedMap.Length > 0)
    {
        for (i = 0; i < Profile.TTUnlockTTCompletedMap.Length; i++)
        {
            if (Profile.TTUnlockTTCompletedMap[i].CompletedTT > 0) 
            {
                ActualTimeTrialStretchIndicies.AddItem(Profile.TTUnlockTTCompletedMap[i].CompletedTT);
            }
        }
    }
    
    if (ActualTimeTrialStretchIndicies.Length == 0 && Profile.TTUnlockTTCompletedMap.Length > 0)
    {
        ClientMessage("ResetAllSpeedrunTimes: Warning - TTUnlockTTCompletedMap was parsed but no valid time trial stretch IDs found. All speedruns will be reset.");
    }

    if (Profile.TTUnlockLevelCompletedMap.Length == 0)
    {
        ClientMessage("ResetAllSpeedrunTimes: TTUnlockLevelCompletedMap is empty in profile. Cannot identify speedrun stretches.");
    }

    for (i = 0; i < Profile.TTUnlockLevelCompletedMap.Length; i++)
    {
        SpeedrunStretchIndex = Profile.TTUnlockLevelCompletedMap[i];
        if (SpeedrunStretchIndex > 0)
        {
            bIsActualTimeTrialStretch = false;
            if (ActualTimeTrialStretchIndicies.Length > 0)
            {
                for (j = 0; j < ActualTimeTrialStretchIndicies.Length; j++)
                {
                    if (ActualTimeTrialStretchIndicies[j] == SpeedrunStretchIndex)
                    {
                        bIsActualTimeTrialStretch = true;
                        break;
                    }
                }
            }

            if (!bIsActualTimeTrialStretch)
            {
                if (!Profile.SetTTTimeForStretch(SpeedrunStretchIndex, TimeToSet, IntermediateTimesToSet, 0.0f, 0.0f))
                {
                    ClientMessage("ResetAllSpeedrunTimes: Failed to set time for speedrun-specific Stretch Index " $ SpeedrunStretchIndex $ ".");
                    bOverallSuccess = false;
                }
            }
        }
    }

    if (!bOverallSuccess && Profile.TTUnlockLevelCompletedMap.Length > 0) 
    {
        ClientMessage("ResetAllSpeedrunTimes: One or more speedrun stretch times intended for update failed or were skipped.");
    }

    if (Outer.OnlinePlayerData != none)
    {
        if (!Outer.OnlinePlayerData.SaveProfileData())
        {
            ClientMessage("ResetAllSpeedrunTimes: Profile save FAILED to initiate. Changes may not persist.");
        }
    }
    else
    {
        ClientMessage("ResetAllSpeedrunTimes: Could not get OnlinePlayerData for saving. Changes may not persist.");
    }
}

exec function SetCollectedBagCount(int NumBagsToSet)
{
    local int HiddenBagMaskID;
    local int NewBagMaskValue;
    local int MaxBagsAllowed;

    EnsureHelperProxy();

    MaxBagsAllowed = 30; // Based on TdProfileSettings.MAX_BAGS

    if (NumBagsToSet < 0)
    {
        NumBagsToSet = 0;
    }
    else if (NumBagsToSet > MaxBagsAllowed)
    {
        NumBagsToSet = MaxBagsAllowed;
    }

    PlayerDataStore = Outer.OnlinePlayerData;
    if (PlayerDataStore != none)
    {
        ProfileDataProvider = PlayerDataStore.ProfileProvider;
        if (ProfileDataProvider != none)
        {
            Profile = TdProfileSettings(ProfileDataProvider.Profile);
        }
    }

    if (Profile == none)
    {
        return;
    }

    // Bags in Mirror's Edge are bitmask
    if (NumBagsToSet == 0)
    {
        NewBagMaskValue = 0;
    }
    else if (NumBagsToSet == MaxBagsAllowed) 
    {
        NewBagMaskValue = (1 << MaxBagsAllowed) - 1;
        if (MaxBagsAllowed == 31)
        { // Max for a positive signed 32-bit int if all bits are used
            NewBagMaskValue = 0x7FFFFFFF;
        }
        else if (MaxBagsAllowed >= 32)
        {
            NewBagMaskValue = -1;
        }
    }
    else
    {
        NewBagMaskValue = (1 << NumBagsToSet) - 1;
    }

    HiddenBagMaskID = 1020;

    if (Profile.SetProfileSettingValueInt(HiddenBagMaskID, NewBagMaskValue))
    {
        if (PlayerDataStore != none)
        {
            PlayerDataStore.SaveProfileData();
        }
    }
}

exec function SetSpecificBagCollected(int ChapterNumber, int BagInChapter, bool bCollected)
{
    local int OverallBagIndex;
    local int CurrentBagMask;
    local int NewBagMask;
    local int BitToModify;
    local int HiddenBagMaskID;

    EnsureHelperProxy();

    HiddenBagMaskID = 1020;

    if (ChapterNumber < 0 || ChapterNumber > 9)
    {
        ClientMessage("SetSpecificBagCollected: Error - Invalid ChapterNumber '" $ ChapterNumber $ "'. Must be between 0 and 9.");
        return;
    }
    if (BagInChapter < 1 || BagInChapter > 3)
    {
        ClientMessage("SetSpecificBagCollected: Error - Invalid BagInChapter '" $ BagInChapter $ "' for Chapter " $ ChapterNumber $ ". Must be between 1 and 3.");
        return;
    }

    Profile = Outer.GetProfileSettings();
    if (Profile == none)
    {
        ClientMessage("SetSpecificBagCollected: Error - Failed to get profile settings.");
        return;
    }

    // Each chapter has 3 bags. Chapter 1: bags 0,1,2. Chapter 2: bags 3,4,5. etc
    OverallBagIndex = (ChapterNumber) * 3 + (BagInChapter - 1);

    if (!Profile.GetProfileSettingValueInt(HiddenBagMaskID, CurrentBagMask))
    {
        // If the setting doesn't exist or fails to read, it's safer to assume no bags are collected
        ClientMessage("SetSpecificBagCollected: Warning - Failed to retrieve current bag mask for ID " $ HiddenBagMaskID $ ". Assuming 0 (no bags collected initially).");
        CurrentBagMask = 0; 
    }

    BitToModify = (1 << OverallBagIndex); // Creates a mask like 00...010...00 where the '1' is at OverallBagIndex

    if (bCollected)
    {
        NewBagMask = CurrentBagMask | BitToModify; // Set the bit using bitwise
    }
    else
    {
        NewBagMask = CurrentBagMask & ~BitToModify; // Clear the bit using bitwise and with the inverse of the bit
    }

    if (Profile.SetProfileSettingValueInt(HiddenBagMaskID, NewBagMask))
    {
        if (Outer.OnlinePlayerData != none)
        {
            if (!Outer.OnlinePlayerData.SaveProfileData())
            {
                ClientMessage("SetSpecificBagCollected: Error - Profile save FAILED after updating bag mask. Changes may not persist.");
            }
        }
        else
        {
            ClientMessage("SetSpecificBagCollected: Error - Could not get OnlinePlayerData for saving. Changes may not persist.");
        }
    }
    else
    {
        ClientMessage("SetSpecificBagCollected: Error - Failed to set the new bag mask (ID: " $ HiddenBagMaskID $ ") in profile settings object.");
    }
}

exec function SetAllHintsViewed(optional bool bShown)
{
    local int HintMaskID;
    local int NewValue;

    EnsureHelperProxy();

    Profile = Outer.GetProfileSettings();
    if (Profile == none)
    {
        ClientMessage("MarkAllHintsAsShown: Failed to get profile settings.");
        return;
    }

    HintMaskID = Profile.TDPID_HintsShownFlags;
    NewValue = bShown ? -1 : 0;

    if (Profile.SetProfileSettingValueInt(HintMaskID, NewValue))
    {
        if (Outer.OnlinePlayerData != none)
        {
            if (!Outer.OnlinePlayerData.SaveProfileData())
            {
                ClientMessage("MarkAllHintsAsShown: Profile save FAILED. Changes may not persist.");
            }
        }
        else
        {
            ClientMessage("MarkAllHintsAsShown: Could not get OnlinePlayerData for saving.");
        }
    }
    else
    {
        ClientMessage("MarkAllHintsAsShown: Failed to set new hint mask (ID: " $ HintMaskID $ ") in profile object.");
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
    local int i;
    local int NumExamplesToPrint;

    EnsureHelperProxy();

    Profile = Outer.GetProfileSettings();
    if (Profile == none)
    {
        ClientMessage("Failed to get profile settings.");
        return;
    }
    
    ActionIndex = Profile.GetDBAFromCommand(ActionCommandString);

    if (ActionIndex < 0 || ActionIndex >= Profile.DigitalButtonActionsToCommandMapping.Length)
    {
        ClientMessage("Invalid ActionCommandString '" $ ActionCommandString $ "'.");
        ClientMessage("Please use one of the defined GBA_ command names (case sensitive):");

        if (Profile.DigitalButtonActionsToCommandMapping.Length > 0)
        {
            NumExamplesToPrint = Min(Profile.DigitalButtonActionsToCommandMapping.Length, 25);
            for (i = 0; i < NumExamplesToPrint; i++)
            {
                if (Profile.DigitalButtonActionsToCommandMapping[i] != "")
                {
                    ClientMessage("  - '" $ Profile.DigitalButtonActionsToCommandMapping[i] $ "'");
                }
            }
        }
        return;
    }

    // GetProfileIDForDBA(KeyAction) returns (501 + KeyAction)
    // TDPID_KeyAction_1 is 501. EDigitalButtonActions.DBA_None is 0
    KeyActionProfileId = 501 + ActionIndex; 
    if (KeyActionProfileId < Profile.TDPID_KeyAction_1 || KeyActionProfileId > Profile.TDPID_KeyAction_49) 
    {
        ClientMessage("Calculated KeyActionProfileId " $ KeyActionProfileId $ " is out of expected range (" $ Profile.TDPID_KeyAction_1 $ "-" $ Profile.TDPID_KeyAction_49 $ ")");
        return;
    }

    // Prepare KeyBinds array
    KeyBinds[0] = name(KeyName1);
    KeyBinds[1] = (KeyName2 != "") ? name(KeyName2) : 'None';
    KeyBinds[2] = (KeyName3 != "") ? name(KeyName3) : 'None';
    KeyBinds[3] = (KeyName4 != "") ? name(KeyName4) : 'None';

    // Calculate KeyBindingValue (the packed integer)
    KeyBindingValue = 0; 
    for (KeyBindIdx = 0; KeyBindIdx < 4; KeyBindIdx++)
    {
        if (KeyBinds[KeyBindIdx] != 'None')
        {
            KeyEnumValue = Profile.FindKeyEnum(KeyBinds[KeyBindIdx]); 
            if (KeyEnumValue != -1) // FindKeyEnum returns -1 if not found, 0 for TDBND_Unbound
            {
                KeyBindingValue = KeyBindingValue | (KeyEnumValue << (KeyBindIdx * 8));
            }
            else
            {
                ClientMessage("Warning - Key '" $ KeyBinds[KeyBindIdx] $ "' not found by FindKeyEnum. Will not be bound for this slot.");
            }
        }
    }
    
    ClientMessage("Action " $ ActionCommandString $ " (Index: " $ ActionIndex $ ")");
    ClientMessage("Keys: " $ KeyBinds[0] $ ", " $ KeyBinds[1] $ ", " $ KeyBinds[2] $ ", " $ KeyBinds[3]);
    ClientMessage("Calculated KeyActionProfileId: " $ KeyActionProfileId);
    ClientMessage("Calculated KeyBindingValue (packed): " $ KeyBindingValue);

    if (!Profile.SetProfileSettingValueInt(KeyActionProfileId, KeyBindingValue))
    {
        ClientMessage("Failed to set keybind via SetProfileSettingValueInt. Profile not modified for this keybind.");
        return; 
    }

    if (Outer != none && Outer.PlayerInput != none)
    {
        Profile.ApplyAllKeyBindings(Outer.PlayerInput); 
        Outer.PlayerInput.SaveConfig(); 
    }
    else
    {
        ClientMessage("Could not get PlayerInput to apply bindings live. Changes are in profile only until next load or manual apply.");
    }

    if (Outer.OnlinePlayerData != none)
    {
        if (!Outer.OnlinePlayerData.SaveProfileData())
        {
            ClientMessage("Profile save FAILED. Keybind changes may not persist in profile storage.");
        }
    }
    else
    {
        ClientMessage("Could not get OnlinePlayerData for saving profile. Keybind changes may not persist in profile storage.");
    }
}

exec function DefaultProfile()
{
    EnsureHelperProxy();

    Outer.GetProfileSettings().SetToDefaults();
    Outer.OnlinePlayerData.SaveProfileData();
}