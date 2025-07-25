class SofTimerTimeTrialHUD extends TdTimeTrialHUD
    transient
    config(Game)
    hidecategories(Navigation);

var SaveLoadHandlerSTHUD   SaveLoad;
var UIDataStore_TdGameData GameData;

var float               PrevTimeAttackClock;
var bool                bTimeAttackClockDecrementedSaved;

var bool                bIsRaceTimerActive;
var TdPlayerController  SpeedrunController;
var(HUDIcons) Vector2D  RaceTimerPos;

var bool                bLoadedTimeFromSave;
var int                 SkipTicks;

var int                 RunCompleteLiveSplitASLMarker;
var bool                bFinalTimeLocked;

var string              StartMap;
var string              EndMap;

// Trainer, macro, speed variables
var vector              CurrentLocation;
var rotator             CurrentRotation;
var float               PlayerSpeed;
var vector              ConvertedLocation, PlayerVelocity;

var float               MaxVelocity, MaxHeight;
var float               LastMaxVelocityUpdateTime, LastMaxHeightUpdateTime;
var float               UpdateInterval;

var float               MacroStartTime;
var bool                bIsMacroTimerActive;
var float               MacroFinalElapsedTime;
var name                CurrentMacroType;

var string              TrainerHUDMessageText;
var float               TrainerHUDMessageDisplayTime;
var float               TrainerHUDMessageDuration;

var bool                ShowTrainerHUDItems;
var bool                ShowMacroFeedback;


event PostBeginPlay()
{
    local DataStoreClient DataStoreManager;
    local string MapName;
    local string FinalTimeFlag;

    super(TdHUD).PostBeginPlay();
    DataStoreManager = Class'UIInteraction'.static.GetDataStoreClient();
    GameData = UIDataStore_TdGameData(DataStoreManager.FindDataStore('TdGameData'));

    if (SaveLoad == none)
    {
        SaveLoad = new class'SaveLoadHandlerSTHUD';
    }

    CacheMeasurementUnitInfo();

    ShowTrainerHUDItems = (SaveLoad.LoadData("ShowTrainerHUDItems") == "") ? false : bool(SaveLoad.LoadData("ShowTrainerHUDItems"));
    ShowMacroFeedback = (SaveLoad.LoadData("ShowMacroFeedback") == "") ? false : bool(SaveLoad.LoadData("ShowMacroFeedback"));
    bTimeAttackClockDecrementedSaved = (SaveLoad.LoadData("TimeAttackClockDecremented") == "true");

    MaxVelocity = 0.0;
    MaxHeight = 0.0;
    LastMaxVelocityUpdateTime = WorldInfo.TimeSeconds;
    LastMaxHeightUpdateTime = WorldInfo.TimeSeconds;
    UpdateInterval = 3.0;

    MapName = WorldInfo.GetMapName();

    if (MapName == "TdMainMenu")
    {
        FinalTimeFlag = SaveLoad.LoadData("FinalTimeLocked");
        if (FinalTimeFlag == "true")
        {
            bFinalTimeLocked = true;
            RunCompleteLiveSplitASLMarker = int(SaveLoad.LoadData("RunCompleteLiveSplitASLMarker"));
        }
    }

    StartMap = SaveLoad.LoadData("StartMap");
    if (StartMap == "")
    {
        StartMap = "TT_TutorialA01_p";
    }

    EndMap = SaveLoad.LoadData("EndMap");
    if (EndMap == "")
    {
        EndMap = "TT_ScraperB01_p";
    }

    if (MapName == StartMap)
    {
        GameData.TimeAttackClock = 0;
        bFinalTimeLocked = false;
        SaveLoad.SaveData("FinalTimeLocked", "false");
        RunCompleteLiveSplitASLMarker = 696969;
        SaveLoad.SaveData("RunCompleteLiveSplitASLMarker", "696969");
    }
    
    if (MapName != "TdMainMenu")
    {
        SkipTicks = 3;
    }
    else
    {
        SkipTicks = 0;
    }

    ConsoleCommand("set TdSPTimeTrialGame RaceCountDownTime 3");
    ConsoleCommand("set TdTimeTrialHUD StarRatingPos (X=1000,Y=61)");

    PrevTimeAttackClock = GameData.TimeAttackClock;
}

exec function SetTimeTrialOrder(string Start, string End)
{
    if (SaveLoad == none)
    {
        SaveLoad = new class'SaveLoadHandlerSTHUD';
    }
    SaveLoad.SaveData("StartMap", (Start));
    SaveLoad.SaveData("EndMap", (End));
    StartMap = SaveLoad.LoadData("StartMap");
    EndMap = SaveLoad.LoadData("EndMap");
}

function Tick(float DeltaTime)
{
    local float RealDeltaTime;
    local float OldTimeAttackClock;
    local string SavedTimeStr;
    local string MapName;

    super(TdHUD).Tick(DeltaTime);

    if (SkipTicks > 0)
    {
        SkipTicks--;
        return;
    }

    EffectManager.Update(DeltaTime, RealTimeRenderDelta);

    if (SaveLoad == none)
    {
        SaveLoad = new class'SaveLoadHandlerSTHUD';
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

    MapName = WorldInfo.GetMapName();

    if (!bLoadedTimeFromSave && MapName != StartMap)
    {
        SavedTimeStr = SaveLoad.LoadData("TimeAttackClock");
        if (SavedTimeStr != "")
        {
            GameData.TimeAttackClock = float(SavedTimeStr);
        }
        bLoadedTimeFromSave = true;
    }

    if (MapName == EndMap)
    {
        if (!bFinalTimeLocked && CheckFinalTTCompletion())
        {
            bFinalTimeLocked = true;
            SaveLoad.SaveData("FinalTimeLocked", "true");
            RunCompleteLiveSplitASLMarker = 969696;
            SaveLoad.SaveData("RunCompleteLiveSplitASLMarker", "969696");
            SpeedrunController.ClientMessage("Final time - " $ FormatSpeedrunTime(GameData.TimeAttackClock));
        }
    }

    OldTimeAttackClock = GameData.TimeAttackClock;

    if (!bTimeAttackClockDecrementedSaved && GameData.TimeAttackClock < PrevTimeAttackClock)
    {
        bTimeAttackClockDecrementedSaved = true;
        SaveLoad.SaveData("TimeAttackClockDecremented", "true");
    }
    
    if (!bFinalTimeLocked)
    {
        GameData.TimeAttackClock += RealDeltaTime;
    }

    PrevTimeAttackClock = OldTimeAttackClock;
}

function bool CheckFinalTTCompletion()
{
    local TdSPTimeTrialGame TTGame;

    TTGame = TdSPTimeTrialGame(WorldInfo.Game);

    if (TTGame != None && TTGame.IsInState('RaceFinishLine'))
    {
        return true;
    }

    return false;
}

event PostRender()
{
    local TdSPTimeTrialGame Game;
    local TdGameUISceneClient SceneClient;
    local UIScene ActiveScene;
    local string MapName;

    super.PostRender();

    Game = TdSPTimeTrialGame(WorldInfo.Game);

    MapName = WorldInfo.GetMapName();

    SceneClient = TdGameUISceneClient(Class'UIRoot'.static.GetSceneClient());
    ActiveScene = SceneClient.GetActiveScene();

    if ((MapName == "TdMainMenu") ||
    (ActiveScene != None && ActiveScene.SceneTag == 'TdStartRace' ||
    ActiveScene.SceneTag == 'TdEndOfRace' ||
    ActiveScene.SceneTag == 'TdStarRating' ||
    ActiveScene.SceneTag == 'TdNewRecord'))
    {
        DrawRaceTimer(Game);
        if (Game != none)
        {
            DrawStarRating(Game);
        }
    }
}

function DrawPausedHUD()
{
    local TdSPTimeTrialGame Game;

    Game = TdSPTimeTrialGame(WorldInfo.Game);

    super.DrawPausedHUD();
    
    DrawRaceTimer(Game);
    if (Game != none)
    {
        DrawStarRating(Game);
    }
}

function DrawLivingHUD()
{
    local TdSPTimeTrialGame Game;
    local bool bCheatsActive;
    local bool bIllegalFramerate;
    local bool bLostThreeStar;

    super(TdTimeTrialHUD).DrawLivingHUD();
    Game = TdSPTimeTrialGame(WorldInfo.Game);

    if (WorldInfo.Game != none)
    {
        DrawRaceTimer(Game);
        
        if (Game != none)
        {
            DrawStarRating(Game);

            if (Game.StarRatingTimes[0] > 0)
            {
                bLostThreeStar = Game.GetPlayerTime() >= Game.StarRatingTimes[0];
            }
        }
        
        DrawTrainerItems();

        bCheatsActive = CheckCheatsTrainerMode();
        bIllegalFramerate = CheckIllegalFramerateLimit();
        if (bCheatsActive || bIllegalFramerate || bLostThreeStar || bTimeAttackClockDecrementedSaved)
        {
            DrawWarningMessages(bCheatsActive, bIllegalFramerate, bLostThreeStar);
        }
    }
}

function DrawRaceTimer(TdSPTimeTrialGame Game)
{
    local string TimeString;
    local float RTime;
    local Vector2D pos;
    local float DisplayTime, XL, YL;
    local string LRT;
    local float DSOffset;

    if (WorldInfo.GetMapName() != "TdMainMenu")
    {
        DisplayTime = Game.GetPlayerTime();
        TimeString = "TT - " $ GetTimeString(DisplayTime);
        Canvas.Font = MediumFont;
        DSOffset = (MediumFont.GetMaxCharHeight() * MediumFont.GetScalingFactor(float(Canvas.SizeY))) * FontDSOffset;
        DSOffset = FMax(1, DSOffset);
        ComputeHUDPosition(RaceTimerPos.X, RaceTimerPos.Y, 0, 0, pos);
        DrawTextWithOutLine(pos.X, pos.Y, DSOffset, DSOffset, TimeString, WhiteColor);
    }

    RTime = GameData.TimeAttackClock;
    LRT = "69* - " $ FormatSpeedrunTime(RTime);

    if (WorldInfo.GetMapName() != "TdMainMenu")
    {
        Canvas.TextSize(TimeString, XL, YL);
        Canvas.Font = TinyFont;
        DSOffset = (TinyFont.GetMaxCharHeight() * MediumFont.GetScalingFactor(float(Canvas.SizeY))) * FontDSOffset;
        DSOffset = FMax(1, DSOffset);
        DrawTextWithOutLine(pos.X, pos.Y + (YL * 0.8), DSOffset, DSOffset, LRT, WhiteColor);
    }
    else
    {
        Canvas.Font = MediumFont;
        DSOffset = (MediumFont.GetMaxCharHeight() * MediumFont.GetScalingFactor(float(Canvas.SizeY))) * FontDSOffset;
        DSOffset = FMax(1, DSOffset);
        ComputeHUDPosition(RaceTimerPos.X, RaceTimerPos.Y, 0, 0, pos);
        DrawTextWithOutLine(pos.X, pos.Y, DSOffset, DSOffset, LRT, WhiteColor);
    }
}

function string FormatSpeedrunTime(float TotalTime)
{
    local int Minutes, Seconds, Centiseconds;
    local string MinutesStr, SecondsStr, CentisecondsStr;

    if (TotalTime < 0.0)
    {
        TotalTime = 0.0;
    }

    // Calculate minutes, seconds, and centiseconds by truncating via int cast
    Minutes = int(TotalTime / 60);
    Seconds = int(TotalTime) % 60;
    Centiseconds = int((TotalTime - int(TotalTime)) * 100);

    if (Minutes < 10)
    {
        MinutesStr = "0" $ Minutes;
    }
    else
    {
        MinutesStr = string(Minutes);
    }

    if (Seconds < 10)
    {
        SecondsStr = "0" $ Seconds;
    }
    else
    {
        SecondsStr = string(Seconds);
    }

    if (Centiseconds < 10)
    {
        CentisecondsStr = "0" $ Centiseconds;
    }
    else
    {
        CentisecondsStr = string(Centiseconds);
    }

    return MinutesStr $ ":" $ SecondsStr $ ":" $ CentisecondsStr;
}

function DrawTextWithOutLine(float XPos, float YPos, float OffsetX, float OffsetY, string TextToDraw, Color TextColor)
{
    Canvas.SetPos(XPos + OffsetX, YPos + OffsetY);
    Canvas.DrawColor = FontDSColor;
    //Canvas.DrawColor.A *= Square(FadeAmount);
    Canvas.DrawText(TextToDraw);
    Canvas.SetPos(XPos, YPos);
    Canvas.DrawColor = TextColor;
    //Canvas.DrawColor.A = byte(float(255) * FadeAmount);
    Canvas.DrawText(TextToDraw);
}

function DrawWarningMessages(bool bCheatsActive, bool bIllegalFramerate, bool bThreeStarLost)
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

    if (bThreeStarLost)
    {
        if (Message != "")
        {
            Message $= "\n";
        }
        Message $= "3-star rating no longer achievable!";
    }

    //if (bTimeAttackClockDecrementedSaved)
    //{
    //    if (Message != "") Message $= "\n";
    //    Message $= "Nulaft Timer Fix is active! The timer will be broken.";
    //}

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
    local bool FrameRateLimiter;

    FrameRateLimit = class'GameEngine'.default.MaxSmoothedFrameRate;
    FrameRateLimiter = class'GameEngine'.default.bSmoothFrameRate;

    if (FrameRateLimit < 60 || FrameRateLimit > 62 || FrameRateLimit <= 0 || !FrameRateLimiter)
    {
        return true;
    }
}

event Destroyed()
{
    if (SaveLoad == none)
    {
        SaveLoad = new class'SaveLoadHandlerSTHUD';
    }
    SaveLoad.SaveData("TimeAttackClock", string(GameData.TimeAttackClock));
    SaveLoad.SaveData("TimeAttackClockDecremented", "false");
    
    super.Destroyed();
}

// Trainer HUD, speed, etc.

function string FormatFloat(float Value)
{
    local int IntPart, DecimalPart;
    local bool bIsNegative;
    local string DecimalPartString;

    bIsNegative = (Value < 0);
    Value = abs(Value);

    IntPart = int(Value);
    DecimalPart = int((Value - IntPart) * 100 + 0.5);  // Proper rounding

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
    local float RoundedYaw, RoundedPitch;
    local float RoundedMaxSpeed, RoundedMaxHeight, RoundedLastJumpZ, RoundedZDelta;
    local float Yaw, Pitch;
    local string YawText, PitchText;
    local string HealthText, MoveStateText;
    local string MaxVelocityText, LocationTextX, LocationTextY, LocationTextZ;
    local string MaxHeightText, LastJumpZText, ZDeltaText;
    local float MacroElapsedTime;
    local EMovement MoveState;
    local float PlayerHealth;
    
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
        RoundedYaw = RoundToTwoDecimals(Yaw);
        RoundedPitch = RoundToTwoDecimals(Pitch);
        RoundedMaxSpeed = RoundToTwoDecimals(MaxVelocity);
        RoundedMaxHeight = RoundToTwoDecimals(MaxHeight / 100);
        RoundedLastJumpZ = RoundToTwoDecimals(PlayerPawn.LastJumpLocation.Z / 100);
        RoundedZDelta = RoundToTwoDecimals((CurrentLocation.Z - PlayerPawn.LastJumpLocation.Z) / 100);

        MacroElapsedTime = (bIsMacroTimerActive) ? (CurrentTime - MacroStartTime) : 0.0;

        HealthText = "H = " $ int(PlayerHealth) $ "%";
        MoveStateText = "MS = " $ (Left(string(MoveState), 5) == "MOVE_" ? Mid(string(MoveState), 5) : string(MoveState));
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
        Y = 0.80 * Canvas.SizeY;
        Canvas.Font = Class'Engine'.static.GetMediumFont();

        if (ShowTrainerHUDItems)
        {
            DrawTextWithShadow(HealthText, X, Y - 14 * 25.0, ShadowOffset);
            DrawTextWithShadow(MoveStateText, X, Y - 13 * 25.0, ShadowOffset);
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

exec function ToggleTrainerHUD()
{
    ShowTrainerHUDItems = !ShowTrainerHUDItems;
    SaveLoad.SaveData("ShowTrainerHUDItems", string(ShowTrainerHUDItems));
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

exec function ToggleMacroFeedback()
{
    ShowMacroFeedback = !ShowMacroFeedback;
    SaveLoad.SaveData("ShowMacroFeedback", string(ShowMacroFeedback));
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

defaultproperties
{
    RaceTimerPos=(X=1000,Y=55)
    RunCompleteLiveSplitASLMarker = 696969
    ShowTrainerHUDItems = false;
    ShowMacroFeedback = false;
}