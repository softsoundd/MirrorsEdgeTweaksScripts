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
    local int storyMaskValue;
    local int timeTrialMaskValue;

    bAnySettingChangedSuccessfully = false;

    EnsureHelperProxy();
    Profile = Outer.GetProfileSettings();
    if (Profile == none)
    {
        ClientMessage("UnlockProgression: failed to get profile settings. No actions taken.");
        return;
    }

    if (bStory)
    {
        // MAX_LEVELS is 10. Game's IsAllLevelsUnlocked checks for (10+1) = 11 bits.
        storyMaskValue = (1 << (Profile.MAX_LEVELS + 1)) - 1; // Sets bits 0 through 10 (value = 2047)

        bCurrentOpSuccess = Profile.SetProfileSettingValueInt(Profile.TDPID_LevelUnlockMask, storyMaskValue);
        if (bCurrentOpSuccess)
        {
            bAnySettingChangedSuccessfully = true;
        }
        else
        {
            ClientMessage("UnlockProgression: failed to apply settings to unlock Story Levels (Normal) with mask " $ storyMaskValue);
        }
    }

    if (bTimeTrials)
    {
        timeTrialMaskValue = (1 << 24) - 1; // Sets bits 0 through 23 (value = 16777215)

        bCurrentOpSuccess = Profile.SetProfileSettingValueInt(Profile.TDPID_TimeTrialUnlockMask, timeTrialMaskValue);
        if (bCurrentOpSuccess)
        {
            bAnySettingChangedSuccessfully = true;
        }
        else
        {
            ClientMessage("UnlockProgression: failed to apply settings to unlock Time Trials with mask " $ timeTrialMaskValue);
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
                ClientMessage("UnlockProgression: Profile save failed. Changes may not persist.");
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
        ClientMessage("LockProgression: failed to get profile settings. No actions taken.");
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
            ClientMessage("LockProgression: failed to apply settings to lock Story Levels (Normal).");
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
            ClientMessage("LockProgression: failed to apply settings to lock Time Trials.");
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
                ClientMessage("LockProgression: Profile save failed. Changes may not persist.");
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
        ClientMessage("GhostWriteCallback: failed to write ghost data. Result: " $ ResultString $ ". (Tag: " $ GhostTagReceived $ ")");
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
        ClientMessage("ResetAllTimeTrialTimes: failed to get profile settings.");
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
                ClientMessage("ResetAllTimeTrialTimes: failed to set time for Time Trial Stretch Index " $ StretchIndex $ ".");
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
                        ClientMessage("ResetAllTimeTrialTimes: failed to create TdOfflineGhostStorageManager for Stretch " $ StretchIndex $ ".");
                    }
                }
                else
                {
                    ClientMessage("ResetAllTimeTrialTimes: failed to create TdGhost object for Stretch " $ StretchIndex $ ".");
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
        ClientMessage("ResetAllSpeedrunTimes: failed to get profile settings.");
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
                    ClientMessage("ResetAllSpeedrunTimes: failed to set time for speedrun-specific Stretch Index " $ SpeedrunStretchIndex $ ".");
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
            ClientMessage("ResetAllSpeedrunTimes: Profile save failed to initiate. Changes may not persist.");
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
        ClientMessage("SetSpecificBagCollected: Error - failed to get profile settings.");
        return;
    }

    // Each chapter has 3 bags. Chapter 1: bags 0,1,2. Chapter 2: bags 3,4,5. etc
    OverallBagIndex = (ChapterNumber) * 3 + (BagInChapter - 1);

    if (!Profile.GetProfileSettingValueInt(HiddenBagMaskID, CurrentBagMask))
    {
        // If the setting doesn't exist or fails to read, it's safer to assume no bags are collected
        ClientMessage("SetSpecificBagCollected: Warning - failed to retrieve current bag mask for ID " $ HiddenBagMaskID $ ". Assuming 0 (no bags collected initially).");
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
                ClientMessage("SetSpecificBagCollected: Error - Profile save failed after updating bag mask. Changes may not persist.");
            }
        }
        else
        {
            ClientMessage("SetSpecificBagCollected: Error - Could not get OnlinePlayerData for saving. Changes may not persist.");
        }
    }
    else
    {
        ClientMessage("SetSpecificBagCollected: Error - failed to set the new bag mask (ID: " $ HiddenBagMaskID $ ") in profile settings object.");
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
        ClientMessage("MarkAllHintsAsShown: failed to get profile settings.");
        return;
    }

    HintMaskID = Profile.TDPID_HintsShownFlags;

    if (bShown)
    {
        NewValue = (1 << 8) - 1;
    }
    else
    {
        NewValue = 0;
    }

    if (Profile.SetProfileSettingValueInt(HintMaskID, NewValue))
    {
        if (Outer.OnlinePlayerData != none)
        {
            if (!Outer.OnlinePlayerData.SaveProfileData())
            {
                ClientMessage("MarkAllHintsAsShown: Profile save failed. Changes may not persist.");
            }
        }
        else
        {
            ClientMessage("MarkAllHintsAsShown: Could not get OnlinePlayerData for saving.");
        }
    }
    else
    {
        ClientMessage("MarkAllHintsAsShown: failed to set new hint mask (ID: " $ HintMaskID $ ") in profile object.");
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
        ClientMessage("failed to get profile settings.");
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
        ClientMessage("failed to set keybind via SetProfileSettingValueInt. Profile not modified for this keybind.");
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
            ClientMessage("Profile save failed. Keybind changes may not persist in profile storage.");
        }
    }
    else
    {
        ClientMessage("Could not get OnlinePlayerData for saving profile. Keybind changes may not persist in profile storage.");
    }
}

exec function SetAutoAimStatus(bool bEnable)
{
    local int ValueToSet;
    local bool bSuccess;

    EnsureHelperProxy();

    if (Outer == none) {
        ClientMessage("SetAutoAimStatus: Error - Outer (PlayerController) is None.");
        return;
    }
    Profile = Outer.GetProfileSettings();
    if (Profile == none)
    {
        ClientMessage("SetAutoAimStatus: failed to get profile settings.");
        return;
    }

    if (bEnable)
    {
        ValueToSet = 1;
        ClientMessage("SetAutoAimStatus: Attempting to set Auto-Aim to ON (Value: " $ ValueToSet $ ").");
    }
    else
    {
        ValueToSet = 0;
        ClientMessage("SetAutoAimStatus: Attempting to set Auto-Aim to OFF (Value: " $ ValueToSet $ ").");
    }

    bSuccess = Profile.SetProfileSettingValueId(Profile.TDPID_AutoAim, ValueToSet);

    if (bSuccess)
    {
        ClientMessage("SetAutoAimStatus: Successfully updated Auto-Aim setting in profile object (ID: " $ Profile.TDPID_AutoAim $ ").");
        if (Outer.OnlinePlayerData != none)
        {
            if (!Outer.OnlinePlayerData.SaveProfileData())
            {
                ClientMessage("SetAutoAimStatus: Profile save failed. Changes may not persist.");
            }
            else
            {
                ClientMessage("SetAutoAimStatus: Profile save initiated successfully.");
            }
        }
        else
        {
            ClientMessage("SetAutoAimStatus: Could not get OnlinePlayerData for saving. Changes may not persist.");
        }
    }
    else
    {
        ClientMessage("SetAutoAimStatus: failed to update Auto-Aim setting (ID: " $ Profile.TDPID_AutoAim $ ") in profile object.");
    }
}

exec function DefaultProfile()
{
    EnsureHelperProxy();

    Outer.GetProfileSettings().SetToDefaults();
    Outer.OnlinePlayerData.SaveProfileData();
}

exec function ViewProfileID(int PropertyID)
{
    local int IntValue;
    local float FloatValue;
    local string StringValue;
    local int IdValue;
    local bool bHandledSpecially;
    local bool bAttemptedSpecialHandling;
    local bool bValueFoundThisType;
    local name ResolvedSettingName;
    local int i;
    local bool bOverallValueFound;
    local string DisplayKeyForLog;
    local bool bPropertyExistsInSettingsArray;

    local float StretchTotalTime, StretchAverageSpeed, StretchDistanceRun;
    local array<float> StretchIntermediateTimes;
    local int StretchNumber;
    local int currentBagsFound;

    local int ActionIndex;
    local string KeyActionCommandName;
    local name KeyBinds[4];
    local int KeyEnumValue;
    local int StoredKeyBindingValue;

    EnsureHelperProxy();

    if (Outer == none)
    {
        ClientMessage("ViewProfileID: Error - Outer (PlayerController) is None.");
        return;
    }
    Profile = Outer.GetProfileSettings();
    if (Profile == none)
    {
        ClientMessage("ViewProfileID: Error - failed to get TdProfileSettings object.");
        return;
    }

    ResolvedSettingName = Profile.GetProfileSettingName(PropertyID);
    bOverallValueFound = false;

    ClientMessage("==============================================================");
    if (ResolvedSettingName != 'None' && ResolvedSettingName != '')
    {
        ClientMessage("Viewing Profile ID: " $ PropertyID $ " (Name: '" $ ResolvedSettingName $ "')");
    }
    else
    {
        ClientMessage("Viewing Profile ID: " $ PropertyID $ " (Name: Not Mapped or Unknown)");
    }
    ClientMessage("--------------------------------------------------------------");

    bHandledSpecially = false;
    bAttemptedSpecialHandling = false;

    // Time trial stretch data
    if (PropertyID >= Profile.TDPID_StretchTime_00 && PropertyID <= Profile.TDPID_StretchTime_33)
    {
        bAttemptedSpecialHandling = true;
        StretchNumber = (PropertyID - Profile.TDPID_StretchTime_00) + 1;
        ClientMessage("Type: Time Trial Stretch Data (For Stretch Index #" $ StretchNumber $ ")");
        if (Profile.GetTTTimeForStretch(StretchNumber, StretchTotalTime, StretchIntermediateTimes, StretchAverageSpeed, StretchDistanceRun))
        {
            ClientMessage("  Total Time: " $ StretchTotalTime);
            ClientMessage("  Average Speed: " $ StretchAverageSpeed);
            ClientMessage("  Distance Run: " $ StretchDistanceRun);
            if (StretchIntermediateTimes.Length > 0)
            {
                ClientMessage("  Intermediate Times (" $ StretchIntermediateTimes.Length $ " splits):");
                for (i = 0; i < StretchIntermediateTimes.Length; i++)
                {
                    ClientMessage("    - Split " $ (i+1) $ ": " $ StretchIntermediateTimes[i]);
                }
            }
            else
            {
                ClientMessage("  Intermediate Times: None recorded or not applicable.");
            }
            bHandledSpecially = true;
            bOverallValueFound = true;
        }
        else
        {
            ClientMessage("  failed to retrieve detailed stretch data via GetTTTimeForStretch.");
            ClientMessage("  (Will attempt generic data reads below if this was the only interpretation.)");
        }
    }

    // Key binding
    else if (PropertyID >= Profile.TDPID_KeyAction_1 && PropertyID <= Profile.TDPID_KeyAction_49)
    {
        bAttemptedSpecialHandling = true;
        ClientMessage("Type: Key Binding Data");
        ActionIndex = PropertyID - Profile.TDPID_KeyAction_1;

        if (ActionIndex >= 0 && ActionIndex < Profile.DigitalButtonActionsToCommandMapping.Length)
        {
            KeyActionCommandName = Profile.DigitalButtonActionsToCommandMapping[ActionIndex];
            ClientMessage("  Action Command: '" $ KeyActionCommandName $ "' (Action Enum Index: " $ ActionIndex $ ")");

            if (Profile.GetProfileSettingValueInt(PropertyID, StoredKeyBindingValue))
            {
                ClientMessage("  Stored Integer Value (Packed): " $ StoredKeyBindingValue);
                
                for (i = 0; i < Profile.MAX_NUM_KEY_BINDS; i++)
                {
                    KeyEnumValue = (StoredKeyBindingValue >> (i * 8)) & 0xFF;
                    KeyBinds[i] = Profile.FindKeyName(ETDBindableKeys(KeyEnumValue)); 
                                        
                    DisplayKeyForLog = string(KeyBinds[i]);

                    if (KeyEnumValue == 0 && KeyBinds[i] == 'None')
                    { 
                        DisplayKeyForLog = "None (Unbound)";
                    }
                    
                    ClientMessage("    Slot " $ (i+1) $ ": Key '" $ DisplayKeyForLog $ "' (Raw Enum Val in Slot: " $ KeyEnumValue $ ")");
                }
                bHandledSpecially = true;
                bOverallValueFound = true;
            }
            else
            {
                ClientMessage("  failed to read stored integer value for this key action ID.");
            }
        }
        else
        {
            ClientMessage("  Error: Calculated ActionIndex " $ ActionIndex $ " is out of bounds for DigitalButtonActionsToCommandMapping array.");
        }
    }

    // Enum based settings and simple bools
    else if (!bAttemptedSpecialHandling) 
    {
        if (!Profile.GetProfileSettingValueId(PropertyID, IdValue))
        {
            Profile.GetProfileSettingValueInt(PropertyID, IdValue);
        }

        switch (PropertyID)
        {
            case Profile.TDPID_ControllerVibration:
                bAttemptedSpecialHandling = true; ClientMessage("Type: Controller Vibration (Boolean/Enum)");
                ClientMessage("  Interpreted Value: " $ Profile.GetEnum(enum'EControllerVibrationValues', IdValue) $ " (Raw Stored ID/Int: " $ IdValue $ ")");
                bHandledSpecially = true; bOverallValueFound = true; break;
            case Profile.TDPID_YInversion:
                bAttemptedSpecialHandling = true; ClientMessage("Type: Y-Axis Inversion (Boolean/Enum)");
                ClientMessage("  Interpreted Value: " $ Profile.GetEnum(enum'EYInversionValues', IdValue) $ " (Raw Stored ID/Int: " $ IdValue $ ")");
                bHandledSpecially = true; bOverallValueFound = true; break;
            case Profile.TDPID_GameDifficulty:
                bAttemptedSpecialHandling = true; ClientMessage("Type: Game Difficulty (Enum)");
                ClientMessage("  Interpreted Value: " $ Profile.GetEnum(enum'EDifficultySettingValue', IdValue) $ " (Raw Stored ID/Int: " $ IdValue $ ")");
                bHandledSpecially = true; bOverallValueFound = true; break;
            case Profile.TDPID_AutoAim:
                bAttemptedSpecialHandling = true; ClientMessage("Type: Auto-Aim (Boolean/Enum)");
                ClientMessage("  Interpreted Value: " $ Profile.GetEnum(enum'EAutoAimValues', IdValue) $ " (Raw Stored ID/Int: " $ IdValue $ ")");
                bHandledSpecially = true; bOverallValueFound = true; break;
            case Profile.TDPID_MeasurementUnits:
                bAttemptedSpecialHandling = true; ClientMessage("Type: Measurement Units (Enum)");
                ClientMessage("  Interpreted Value: " $ Profile.GetEnum(enum'EMeasurementUnitsValues', IdValue) $ " (Raw Stored ID/Int: " $ IdValue $ ")");
                bHandledSpecially = true; bOverallValueFound = true; break;
            case Profile.TDPID_FaithOVision:
                bAttemptedSpecialHandling = true; ClientMessage("Type: FaithOVision (Runner Vision) (Enum)");
                ClientMessage("  Interpreted Value: " $ Profile.GetEnum(enum'EFaithOVisionValues', IdValue) $ " (Raw Stored ID/Int: " $ IdValue $ ")");
                bHandledSpecially = true; bOverallValueFound = true; break;
            case Profile.TDPID_Reticule:
                bAttemptedSpecialHandling = true; ClientMessage("Type: Reticule (Crosshair) (Enum)");
                ClientMessage("  Interpreted Value: " $ Profile.GetEnum(enum'EReticuleValues', IdValue) $ " (Raw Stored ID/Int: " $ IdValue $ ")");
                bHandledSpecially = true; bOverallValueFound = true; break;
            case Profile.TDPID_Subtitles:
                bAttemptedSpecialHandling = true; ClientMessage("Type: Subtitles (Boolean/Enum)");
                ClientMessage("  Interpreted Value: " $ Profile.GetEnum(enum'ESubValues', IdValue) $ " (Raw Stored ID/Int: " $ IdValue $ ")");
                bHandledSpecially = true; bOverallValueFound = true; break;
            case Profile.TDPID_ControllerConfig:
                bAttemptedSpecialHandling = true; ClientMessage("Type: Controller Configuration (Enum)");
                ClientMessage("  Interpreted Value: " $ Profile.GetEnum(enum'EControllerConfigValues', IdValue) $ " (Raw Stored ID/Int: " $ IdValue $ ")");
                bHandledSpecially = true; bOverallValueFound = true; break;
            case Profile.TDPID_ControllerTilt:
                bAttemptedSpecialHandling = true; ClientMessage("Type: Controller Tilt (PS3 Sixaxis) (Boolean/Enum)");
                ClientMessage("  Interpreted Value: " $ Profile.GetEnum(enum'EProfileControllerTiltValues', IdValue) $ " (Raw Stored ID/Int: " $ IdValue $ ")");
                bHandledSpecially = true; bOverallValueFound = true; break;
        }
    }
    
    // Known bitmasks
    if (!bAttemptedSpecialHandling || 
        PropertyID == Profile.TDPID_LevelUnlockMask || PropertyID == Profile.TDPID_LevelUnlockMaskHard ||
        PropertyID == Profile.TDPID_HiddenBagMask || PropertyID == Profile.TDPID_TimeTrialUnlockMask ||
        PropertyID == Profile.TDPID_TimeTrialQualifierMask || PropertyID == Profile.TDPID_HintsShownFlags ||
        PropertyID == Profile.TDPID_ViewedUnlocksFlags1 || PropertyID == Profile.TDPID_ViewedUnlocksFlags2 ||
        PropertyID == Profile.TDPID_ViewedUnlocksFlags3 || PropertyID == Profile.TDPID_ViewedUnlocksFlags4)
    {
        switch(PropertyID)
        {
            case Profile.TDPID_LevelUnlockMask: ClientMessage("Type Context: Level Unlock Mask (Normal)"); bAttemptedSpecialHandling = true; break;
            case Profile.TDPID_LevelUnlockMaskHard: ClientMessage("Type Context: Level Unlock Mask (Hard)"); bAttemptedSpecialHandling = true; break;
            case Profile.TDPID_HiddenBagMask: ClientMessage("Type Context: Hidden Bag Mask"); bAttemptedSpecialHandling = true; break;
            case Profile.TDPID_TimeTrialUnlockMask: ClientMessage("Type Context: Time Trial Unlock Mask"); bAttemptedSpecialHandling = true; break;
            case Profile.TDPID_TimeTrialQualifierMask: ClientMessage("Type Context: Time Trial Qualifier Mask"); bAttemptedSpecialHandling = true; break;
            case Profile.TDPID_HintsShownFlags: ClientMessage("Type Context: Hints Shown Flags"); bAttemptedSpecialHandling = true; break;
            case Profile.TDPID_ViewedUnlocksFlags1: ClientMessage("Type Context: Viewed Unlocks Flags 1"); bAttemptedSpecialHandling = true; break;
            case Profile.TDPID_ViewedUnlocksFlags2: ClientMessage("Type Context: Viewed Unlocks Flags 2"); bAttemptedSpecialHandling = true; break;
            case Profile.TDPID_ViewedUnlocksFlags3: ClientMessage("Type Context: Viewed Unlocks Flags 3"); bAttemptedSpecialHandling = true; break;
            case Profile.TDPID_ViewedUnlocksFlags4: ClientMessage("Type Context: Viewed Unlocks Flags 4"); bAttemptedSpecialHandling = true; break;
        }
        if (bAttemptedSpecialHandling && !bHandledSpecially)
        {
            if (Profile.GetProfileSettingValueInt(PropertyID, IntValue))
            {
                ClientMessage("  Raw Integer Value (Bitmask): " $ IntValue);
                if(PropertyID == Profile.TDPID_HiddenBagMask)
                {
                    currentBagsFound = 0;
                    for(i=0; i < Profile.MAX_BAGS; ++i) if((IntValue & (1 << i)) != 0) currentBagsFound++;
                    ClientMessage("  (Interpreted from mask: " $ currentBagsFound $ " bags marked as found)");
                }
                bHandledSpecially = true;
                bOverallValueFound = true;
            }
            else
            {
                ClientMessage("  failed to read integer value for this known bitmask ID.");
            }
        }
    }

    // Generic data interpretations
    ClientMessage("--------------------------------------------------------------");
    if (bHandledSpecially && bOverallValueFound)
    {
        ClientMessage("Generic Data Reads (for completeness or raw value view):");
    }
    else if (!bOverallValueFound)
    {
        ClientMessage("No specific type handler matched or succeeded. Attempting Generic Data Reads:");
    }
    else
    {
        ClientMessage("Specialised data retrieval failed or not applicable. Attempting Generic Data Reads:");
    }
    
    bValueFoundThisType = Profile.GetProfileSettingValueInt(PropertyID, IntValue);
    if (bValueFoundThisType)
    {
        ClientMessage("  Value as Int: " $ IntValue);
        bOverallValueFound = true;
    }
    else
    {
        ClientMessage("  Value as Int: Not found or not readable as Int.");
    }

    bValueFoundThisType = Profile.GetProfileSettingValueFloat(PropertyID, FloatValue);
    if (bValueFoundThisType)
    {
        ClientMessage("  Value as Float: " $ FloatValue);
        bOverallValueFound = true;
    }
    else
    {
        ClientMessage("  Value as Float: Not found or not readable as Float.");
    }
    
    // GetProfileSettingValueId is used for enums, but show if not specifically handled as one of our listed enums.
    // This catches cases where it might be an ID for a less common enum or a generic mapped ID.
    bValueFoundThisType = Profile.GetProfileSettingValueId(PropertyID, IdValue);
    if (bValueFoundThisType)
    {
        ClientMessage("  Value as Mapped ID/Index (from GetProfileSettingValueId): " $ IdValue);
        bOverallValueFound = true;
    }
    else
    {
        ClientMessage("  Value as Mapped ID/Index: Not found or not readable via GetProfileSettingValueId.");
    }

    bValueFoundThisType = Profile.GetProfileSettingValue(PropertyID, StringValue);
    if (bValueFoundThisType)
    {
        ClientMessage("  Value as String: '" $ StringValue $ "'");
        bOverallValueFound = true;
    }
    else
    {
        ClientMessage("  Value as String: Not found or not readable as String.");
    }
    
    ClientMessage("--------------------------------------------------------------");
    if (!bOverallValueFound) {
         // Check if the property even exists in the internal array of settings
         
        bPropertyExistsInSettingsArray = false;
        for(i=0; i < Profile.ProfileSettings.Length; ++i)
        {
            if(Profile.ProfileSettings[i].ProfileSetting.PropertyId == PropertyID)
            {
                bPropertyExistsInSettingsArray = true;
                break;
            }
        }
        if(bPropertyExistsInSettingsArray)
        {
            ClientMessage("Property ID " $ PropertyID $ ": Found in profile, but no value readable via standard accessors in expected types.");
        }
        else
        {
            ClientMessage("Property ID " $ PropertyID $ ": Not found in profile settings array OR no value readable. It might be invalid or uninitialised.");
        }
    }
    ClientMessage("==============================================================");
}