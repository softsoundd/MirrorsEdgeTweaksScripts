class SofTimerTutorialHUD extends TdTutorialHUD
    transient
    config(Game)
    hidecategories(Navigation);

var SaveLoadHandler        SaveLoad;
var UIDataStore_TdGameData GameData;
var TdPlayerController     SpeedrunController;
var TdProfileSettings      Profile;
var(HUDIcons) Vector2D     TimerPos;
var(HUDIcons) Vector2D     SpeedPos;
var transient string       SpeedUnitString;
var transient int          MeasurementUnits;
var bool                   bTimerVisible;

var bool              bLoadedTimeFromSave;
var int               SkipTicks;

var transient bool    bHasEverStartedNewGame;

var bool              HundredPercentMode;
var bool              ShowBagHUD;

var bool              SoundFix;

// Trainer, macro, speed variables
var vector            CurrentLocation;
var rotator           CurrentRotation;
var float             PlayerSpeed;
var vector            ConvertedLocation, PlayerVelocity;

var float             MaxVelocity, MaxHeight;
var float             LastMaxVelocityUpdateTime, LastMaxHeightUpdateTime;
var float             UpdateInterval;  // Update every 3 seconds

var float             MacroStartTime;
var bool              bIsMacroTimerActive;
var float             MacroFinalElapsedTime;
var name              CurrentMacroType;

var string            TrainerHUDMessageText;
var float             TrainerHUDMessageDisplayTime;
var float             TrainerHUDMessageDuration;

var bool              ShowSpeed;
var bool              ShowTrainerHUDItems;
var bool              ShowMacroFeedback;


event PostBeginPlay()
{
    local DataStoreClient DataStoreManager;
    local string MapName;

    super(TdHUD).PostBeginPlay();
    DataStoreManager = Class'UIInteraction'.static.GetDataStoreClient();
    GameData = UIDataStore_TdGameData(DataStoreManager.FindDataStore('TdGameData'));

    // Speedrun HUD elements
    bTimerVisible = (SaveLoad.LoadData("TimerHUDVisible") == "") ? true : bool(SaveLoad.LoadData("TimerHUDVisible"));
    ShowSpeed = (SaveLoad.LoadData("ShowSpeed") == "") ? false : bool(SaveLoad.LoadData("ShowSpeed"));
    ShowTrainerHUDItems = (SaveLoad.LoadData("ShowTrainerHUDItems") == "") ? false : bool(SaveLoad.LoadData("ShowTrainerHUDItems"));
    ShowMacroFeedback = (SaveLoad.LoadData("ShowMacroFeedback") == "") ? false : bool(SaveLoad.LoadData("ShowMacroFeedback"));

    MapName = WorldInfo.GetMapName();
    
    if (MapName != "TdMainMenu")
    {
        SkipTicks = 3;
    }
    else
    {
        SkipTicks = 0;
    }

    if (SaveLoad == none)
    {
        SaveLoad = new class'SaveLoadHandler';
    }

    CacheMeasurementUnitInfo();

    GameData.TimeAttackClock = 0;

    // Load the flag that indicates if a new game has ever been started for the active game session
    // This stops the timer automatically incrementing in the main menu when we first enable speedrun mode
    bHasEverStartedNewGame = (SaveLoad.LoadData("HasEverStartedNewGame") == "true");

    if (!bHasEverStartedNewGame)
    {
        bHasEverStartedNewGame = true;
        SaveLoad.SaveData("HasEverStartedNewGame", "true");
    }
}

function Tick(float DeltaTime)
{
    local float RealDeltaTime;
    
    super(TdHUD).Tick(DeltaTime);

    if (SkipTicks > 0)
    {
        SkipTicks--;
        return;
    }

    EffectManager.Update(DeltaTime, RealTimeRenderDelta);

    if (SaveLoad == none)
    {
        SaveLoad = new class'SaveLoadHandler';
    }
    
    if (SpeedrunController == none && PlayerOwner != none)
    {
        SpeedrunController = TdPlayerController(PlayerOwner);
    }
    
    if (WorldInfo.TimeDilation > 0)
    {
        RealDeltaTime = DeltaTime / WorldInfo.TimeDilation;
    }
    else
    {
        RealDeltaTime = DeltaTime;
    }
    
    if (ShouldIncrementTimer())
    {
        GameData.TimeAttackClock += RealDeltaTime;
    }
    
    if (IsLevelCompleted())
    {
        SaveLoad.SaveData("TimeAttackClock", string(GameData.TimeAttackClock));
    }
}

function bool ShouldIncrementTimer()
{
    local TdUIScene_LoadIndicator IndicatorScene;

    IndicatorScene = TdUIScene_LoadIndicator(DiskAccessIndicatorInstance);

    if (IndicatorScene != none)
    {
        if (IndicatorScene != none && IndicatorScene.bIsLoadingLevel)
        {
            return false;
        }
    }

    return true;
}

event Destroyed()
{
    if (SaveLoad == none)
    {
         SaveLoad = new class'SaveLoadHandler';
    }
    SaveLoad.SaveData("TimeAttackClock", string(GameData.TimeAttackClock));
    
    super.Destroyed();
}

// DrawLivingHUD & DrawLoadRemovedTimer: HUD rendering
function DrawLivingHUD()
{
    local TdSPTutorialGame Game;
    local float PosY;
    local bool bCheatsActive;
    local bool bIllegalFramerate;

    super(TdTutorialHUD).DrawLivingHUD();

    Game = TdSPTutorialGame(WorldInfo.Game);

    if (Game != none)
    {
        if (bTimerVisible)
        {
            if (ShouldIncrementTimer())
            {
                DrawLoadRemovedTimer(Game, true); 
            }           
            else
            {
                // Briefly alternate display if paused
                if ((WorldInfo.RealTimeSeconds - float(int(WorldInfo.RealTimeSeconds))) < 0.5)
                {
                    DrawLoadRemovedTimer(Game, true); 
                }
                else
                {
                    DrawLoadRemovedTimer(Game, false);
                }
            }
        }
        
        if (ShowSpeed)
        {
            DrawSpeed(PosY);
        }

        DrawTrainerItems();

        bCheatsActive = CheckCheatsTrainerMode();
        bIllegalFramerate = CheckIllegalFramerateLimit();

        if (bCheatsActive || bIllegalFramerate)
        {
            DrawViolationMessages(bCheatsActive, bIllegalFramerate);
        }
    }
}

function DrawLoadRemovedTimer(TdSPTutorialGame Game, bool bBothTimes)
{
    local string TimeString;
    local float RTime;
    local Vector2D pos;
    local float DSOffset;

    if(GameData == none)
    {
        return;
    }

    if(bBothTimes)
    {
        RTime = GameData.TimeAttackClock;
        TimeString = "LRT - " $ GetTimeString(RTime);
        Canvas.Font = MediumFont;
        DSOffset = (MediumFont.GetMaxCharHeight() * MediumFont.GetScalingFactor(float(Canvas.SizeY))) * FontDSOffset;
        DSOffset = FMax(1, DSOffset);
        ComputeHUDPosition(TimerPos.X, TimerPos.Y, 0, 0, pos);
        DrawTextWithOutLine(pos.X, pos.Y, DSOffset, DSOffset, TimeString, WhiteColor);
    }
}

function DrawSpeed(out float PosY)
{
    local float Speed;
    local string SpeedString;
    local Vector2D pos;
    local float ResolutionScaleX, DSOffset;

    ResolutionScaleX = Canvas.ClipX / 1280;

    if(PlayerOwner.Pawn != none)
    {
        Speed = VSize2D(PlayerOwner.Pawn.Velocity) * 0.036;        
    }
    else
    {
        Speed = 0;
    }
    Canvas.Font = MediumFont;
    ComputeHUDPosition(SpeedPos.X, SpeedPos.Y, 0, 0, pos);
    if(MeasurementUnits == 1)
    {
        Speed = Speed / 1.609344;
    }
    DSOffset = (MediumFont.GetMaxCharHeight() * MediumFont.GetScalingFactor(float(Canvas.SizeY))) * FontDSOffset;
    DSOffset = FMax(1, DSOffset);
    SpeedString = GetFormattedTime(int(Speed + 0.5));
    DrawTextWithOutLine(pos.X, pos.Y, DSOffset, DSOffset, SpeedString, WhiteColor);
    DrawTextWithOutLine(pos.X + (float(42) * ResolutionScaleX), pos.Y, DSOffset, DSOffset, SpeedUnitString, WhiteColor);  
}

function CacheMeasurementUnitInfo()
{
    Profile = TdPlayerController(PlayerOwner).GetProfileSettings();
    Profile.GetProfileSettingValueId(255, MeasurementUnits);

    if(MeasurementUnits == 1)
    {
        SpeedUnitString = Localize("TdTimeTrial", "SpeedUnitTextImperial", "TdGameUI");       
    }
    else
    {
        SpeedUnitString = Localize("TdTimeTrial", "SpeedUnitTextMetric", "TdGameUI");
    } 
}

function DrawViolationMessages(bool bCheatsActive, bool bIllegalFramerate)
{
    local float Y, ShadowOffset;
    local string Message;

    ShadowOffset = 2.0;
    Canvas.Font = Class'Engine'.static.GetMediumFont();

    Y = Canvas.SizeY * 0.08;
    Canvas.bCenter = true;

    Message = "";

    if (bCheatsActive)
    {
        Message = "Cheats + Trainer Mode active!";
    }

    if (bIllegalFramerate)
    {
        if (Message != "")
        {
            Message $= "\n";
        }
        Message $= "Illegal framerate! 60-62 framerate limit required.";
    }

    if (Message != "")
    {
        // Draw shadow
        Canvas.SetPos(0 + ShadowOffset, Y + ShadowOffset);
        Canvas.DrawColor = FontDSColor;
        Canvas.DrawColor.A *= Square(FadeAmount);
        Canvas.DrawText(Message, False, 0.60, 0.60);

        // Draw main text
        Canvas.SetPos(0, Y);
        Canvas.DrawColor = RedColor;
        Canvas.DrawColor.A = byte(float(255) * FadeAmount);
        Canvas.DrawText(Message, False, 0.60, 0.60);
    }
}

function bool CheckCheatsTrainerMode()
{
    if (SpeedrunController.CheatClass == Class'MirrorsEdgeTweaksScripts.MirrorsEdgeCheatManager')
    {
        return true;
    }
}

function bool CheckIllegalFramerateLimit()
{
    local float FrameRateLimit;

    FrameRateLimit = class'GameEngine'.default.MaxSmoothedFrameRate;

    if (FrameRateLimit < 60 || FrameRateLimit > 62 || FrameRateLimit <= 0)
    {
        return true;
    }
}

function bool IsLevelCompleted()
{
    local TdSPGame CurrentGame;
    CurrentGame = TdSPGame(WorldInfo.Game);
    if (CurrentGame != none)
    {
        return (CurrentGame.OnLCAsyncHelper.NextLevelName != "");
    }
    return false;
}

function string FormatFloat(float Value)
{
    local int IntPart, DecimalPart;
    local bool bIsNegative;
    local string DecimalPartString;

    bIsNegative = (Value < 0);
    Value = abs(Value);

    IntPart = int(Value);
    DecimalPart = int((Value - IntPart) * 100 + 0.5); // Proper rounding

    DecimalPartString = (DecimalPart < 10) 
                        ? ("0" $ string(DecimalPart))
                        : string(DecimalPart);

    return (bIsNegative ? ("-" $ string(IntPart) $ "." $ DecimalPartString)
                        : (string(IntPart) $ "." $ DecimalPartString));
}

function float RoundToTwoDecimals(float Value)
{
    return float(int(Value * 100 + 0.5)) / 100;
}

function DrawTextWithShadow(string Text, float X, float Y, float ShadowOffset)
{
    // Draw shadow
    Canvas.SetPos(X + ShadowOffset, Y + ShadowOffset);
    Canvas.DrawColor = FontDSColor;
    Canvas.DrawColor.A *= Square(FadeAmount);
    Canvas.DrawText(Text, False, 0.60, 0.60);

    // Draw main text
    Canvas.SetPos(X, Y);
    Canvas.DrawColor = WhiteColor;
    Canvas.DrawColor.A = byte(float(255) * FadeAmount);
    Canvas.DrawText(Text, False, 0.60, 0.60);
}

// Updates a value (for velocity or height) if the new value exceeds the current maximum,
// and resets if the update interval has passed.
function float UpdateMaxValue(float CurrentValue, float NewValue, out float LastUpdateTime, float CurrentTime)
{
    if (NewValue > CurrentValue)
    {
        CurrentValue = NewValue;
        LastUpdateTime = CurrentTime;
    }
    else if (CurrentTime - LastUpdateTime >= UpdateInterval)
    {
        // Reset max value if the interval has elapsed
        CurrentValue = NewValue;
    }
    return CurrentValue;
}

function DrawTrainerItems()
{
    local float CurrentTime;
    local TdPawn PlayerPawn;
    local float X, Y, ShadowOffset;
    local float RoundedX, RoundedY, RoundedZ;
    local float RoundedSpeed, RoundedYaw, RoundedPitch;
    local float RoundedMaxSpeed, RoundedMaxHeight, RoundedLastJumpZ, RoundedZDelta;
    local float Yaw, Pitch;
    local string YawText, PitchText;
    local string HealthText, ReactionTimeEnergyText, MoveStateText, SpeedText;
    local string MaxVelocityText, LocationTextX, LocationTextY, LocationTextZ;
    local string MaxHeightText, LastJumpZText, ZDeltaText;
    local float MacroElapsedTime;
    local EMovement MoveState;
    local float PlayerHealth, ReactionTimeEnergy;
    
    CurrentTime = WorldInfo.TimeSeconds;

    PlayerPawn = TdPawn(PlayerOwner.Pawn);

    if (PlayerPawn != None)
    {
        CurrentLocation = PlayerPawn.Location;
        CurrentRotation = PlayerPawn.Rotation;
        PlayerVelocity = PlayerPawn.Velocity;
        PlayerVelocity.Z = 0;
        PlayerSpeed = VSize(PlayerVelocity);
        PlayerSpeed *= 0.036;

        MaxVelocity = UpdateMaxValue(MaxVelocity, PlayerSpeed, LastMaxVelocityUpdateTime, CurrentTime);
        MaxHeight   = UpdateMaxValue(MaxHeight, CurrentLocation.Z, LastMaxHeightUpdateTime, CurrentTime);

        PlayerHealth = PlayerPawn.Health;
        MoveState = PlayerPawn.MovementState;
        ReactionTimeEnergy = SpeedrunController.ReactionTimeEnergy;

        if (PlayerPawn.Controller != None)
        {
            CurrentRotation.Pitch = PlayerPawn.Controller.Rotation.Pitch;
        }

        ConvertedLocation = CurrentLocation / 100;

        // Convert rotation (from 65536 units to degrees)
        Yaw   = (float(CurrentRotation.Yaw) / 65536.0) * 360.0;
        Pitch = (float(CurrentRotation.Pitch) / 65536.0) * 360.0;
        if (Yaw < 0) Yaw += 360.0;
        if (Pitch > 180.0) Pitch -= 360.0;

        RoundedX = RoundToTwoDecimals(ConvertedLocation.X);
        RoundedY = RoundToTwoDecimals(ConvertedLocation.Y);
        RoundedZ = RoundToTwoDecimals(ConvertedLocation.Z);
        RoundedSpeed = RoundToTwoDecimals(PlayerSpeed);
        RoundedYaw = RoundToTwoDecimals(Yaw);
        RoundedPitch = RoundToTwoDecimals(Pitch);
        RoundedMaxSpeed = RoundToTwoDecimals(MaxVelocity);
        RoundedMaxHeight = RoundToTwoDecimals(MaxHeight / 100);
        RoundedLastJumpZ = RoundToTwoDecimals(PlayerPawn.LastJumpLocation.Z / 100);
        RoundedZDelta = RoundToTwoDecimals((CurrentLocation.Z - PlayerPawn.LastJumpLocation.Z) / 100);

        MacroElapsedTime = (bIsMacroTimerActive) ? (CurrentTime - MacroStartTime) : 0.0;

        HealthText = "H = " $ int(PlayerHealth) $ "%";
        ReactionTimeEnergyText = "RT = " $ int(ReactionTimeEnergy) $ "%";
        MoveStateText = "MS = " $ (Left(string(MoveState), 5) == "MOVE_" ? Mid(string(MoveState), 5) : string(MoveState));
        SpeedText = "V = " $ FormatFloat(RoundedSpeed) $ " km/h";
        MaxVelocityText = "VT = " $ FormatFloat(RoundedMaxSpeed) $ " km/h";
        LocationTextX = "X = " $ FormatFloat(RoundedX);
        LocationTextY = "Y = " $ FormatFloat(RoundedY);
        LocationTextZ = "Z = " $ FormatFloat(RoundedZ);
        MaxHeightText = "ZT = " $ FormatFloat(RoundedMaxHeight);
        LastJumpZText = "SZ = " $ FormatFloat(RoundedLastJumpZ);
        ZDeltaText = "SZD = " $ FormatFloat(RoundedZDelta);
        YawText = "Y = " $ FormatFloat(RoundedYaw) $ " deg";
        PitchText = "P = " $ FormatFloat(RoundedPitch) $ " deg";

        ShadowOffset = 2.0;
        X = 0.8275 * Canvas.SizeX;
        Y = 0.725 * Canvas.SizeY;
        Canvas.Font = Class'Engine'.static.GetMediumFont();

        if (ShowTrainerHUDItems)
        {
            DrawTextWithShadow(HealthText, X, Y - 16 * 25.0, ShadowOffset);
            DrawTextWithShadow(ReactionTimeEnergyText, X, Y - 15 * 25.0, ShadowOffset);
            DrawTextWithShadow(MoveStateText, X, Y - 14 * 25.0, ShadowOffset);
            DrawTextWithShadow(SpeedText, X, Y - 12 * 25.0, ShadowOffset);
            DrawTextWithShadow(MaxVelocityText, X, Y - 11 * 25.0, ShadowOffset);
            DrawTextWithShadow(LocationTextX, X, Y - 9 * 25.0, ShadowOffset);
            DrawTextWithShadow(LocationTextY, X, Y - 8 * 25.0, ShadowOffset);
            DrawTextWithShadow(LocationTextZ, X, Y - 7 * 25.0, ShadowOffset);
            DrawTextWithShadow(MaxHeightText, X, Y - 6 * 25.0, ShadowOffset);
            DrawTextWithShadow(LastJumpZText, X, Y - 5 * 25.0, ShadowOffset);
            DrawTextWithShadow(ZDeltaText, X, Y - 4 * 25.0, ShadowOffset);
            DrawTextWithShadow(YawText, X, Y - 2 * 25.0, ShadowOffset);
            DrawTextWithShadow(PitchText, X, Y - 1 * 25.0, ShadowOffset);
        }

        if (ShowMacroFeedback)
        {
            if (TrainerHUDMessageText != "" && CurrentTime - TrainerHUDMessageDisplayTime <= TrainerHUDMessageDuration)
            {
                X = Canvas.SizeX * 0.25;
                Y = Canvas.SizeY * 0.60;
                Canvas.bCenter = true;
                DrawTextWithShadow(TrainerHUDMessageText, 0, Y, ShadowOffset);
            }
            else
            {
                TrainerHUDMessageText = "";
            }

            if (bIsMacroTimerActive)
            {
                TrainerHUDMessageText = "";
                X = Canvas.SizeX * 0.25;
                Y = Canvas.SizeY * 0.60;
                Canvas.bCenter = true;
                DrawTextWithShadow(CurrentMacroType $ " macro active: " $ FormatFloat(MacroElapsedTime) $ " s", 0, Y, ShadowOffset);
            }
        }
    }
}

exec function StartMacroTimer(name MacroType)
{
    CurrentMacroType = MacroType;
    MacroStartTime = WorldInfo.TimeSeconds;
    bIsMacroTimerActive = true;
}

exec function ResetMacroTimer()
{
    MacroStartTime = WorldInfo.TimeSeconds;
    MacroFinalElapsedTime = 0.0;
    bIsMacroTimerActive = false;
}

exec function DisplayTrainerHUDMessage(string Message)
{
    TrainerHUDMessageText = Message;
    TrainerHUDMessageDisplayTime = WorldInfo.TimeSeconds;
    TrainerHUDMessageDuration = (bIsMacroTimerActive) ? 99999.0 : 1.0;
}

exec function ToggleSoundFix()
{
    SoundFix = !SoundFix;
    SaveLoad.SaveData("SoundFix", string(SoundFix));
}

exec function SetSoundCueMaxPlays(string SoundCueName, int MaxPlays)
{
    local SoundCue MyCue;

    MyCue = SoundCue(DynamicLoadObject(SoundCueName, class'SoundCue'));

    if (MyCue != None)
    {
        MyCue.AbsoluteMaxConcurrentPlayCount = MaxPlays;
        MyCue.MaxConcurrentPlayCount = MaxPlays;
    }
}

exec function SoundFixOn()
{
    SoundFix = true;
    SaveLoad.SaveData("SoundFix", string(SoundFix));
}

exec function SoundFixOff()
{
    SoundFix = false;
    SaveLoad.SaveData("SoundFix", string(SoundFix));
}

exec function ToggleSpeed()
{
    ShowSpeed = !ShowSpeed;
    SaveLoad.SaveData("ShowSpeed", string(ShowSpeed));
}

exec function ToggleTrainerHUD()
{
    ShowTrainerHUDItems = !ShowTrainerHUDItems;
    SaveLoad.SaveData("ShowTrainerHUDItems", string(ShowTrainerHUDItems));
}

exec function ToggleMacroFeedback()
{
    ShowMacroFeedback = !ShowMacroFeedback;
    SaveLoad.SaveData("ShowMacroFeedback", string(ShowMacroFeedback));
}

exec function ToggleBagHUD()
{
    ShowBagHUD = !ShowBagHUD;
    SaveLoad.SaveData("ShowBagHUD", string(ShowBagHUD));
}

exec function BagHUDOn()
{
    ShowBagHUD = true;
    SaveLoad.SaveData("ShowBagHUD", string(ShowBagHUD));
}

exec function BagHUDOff()
{
    ShowBagHUD = false;
    SaveLoad.SaveData("ShowBagHUD", string(ShowBagHUD));
}

exec function TimerOn()
{
    bTimerVisible = true;
    SaveLoad.SaveData("TimerHUDVisible", string(bTimerVisible));
}

exec function TimerOff()
{
    bTimerVisible = false;
    SaveLoad.SaveData("TimerHUDVisible", string(bTimerVisible));
}

exec function SpeedOn()
{
    ShowSpeed = true;
    SaveLoad.SaveData("ShowSpeed", string(ShowSpeed));
}

exec function SpeedOff()
{
    ShowSpeed = false;
    SaveLoad.SaveData("ShowSpeed", string(ShowSpeed));
}

exec function TrainerHUDOn()
{
    ShowTrainerHUDItems = true;
    SaveLoad.SaveData("ShowTrainerHUDItems", string(ShowTrainerHUDItems));
}

exec function TrainerHUDOff()
{
    ShowTrainerHUDItems = false;
    SaveLoad.SaveData("ShowTrainerHUDItems", string(ShowTrainerHUDItems));
}

exec function MacroFeedbackOn()
{
    ShowMacroFeedback = true;
    SaveLoad.SaveData("ShowMacroFeedback", string(ShowMacroFeedback));
}

exec function MacroFeedbackOff()
{
    ShowMacroFeedback = false;
    SaveLoad.SaveData("ShowMacroFeedback", string(ShowMacroFeedback));
}

exec function ModeAnyPercent()
{
    HundredPercentMode = false;
    SaveLoad.SaveData("HundredPercentMode", string(HundredPercentMode));
    ConsoleCommand("disconnect");
}

exec function Mode100Percent()
{
    HundredPercentMode = true;
    SaveLoad.SaveData("HundredPercentMode", string(HundredPercentMode));
    ConsoleCommand("disconnect");
}

defaultproperties
{
    TimerPos=(X=1000,Y=55)
    SpeedPos=(X=1060,Y=605)
}