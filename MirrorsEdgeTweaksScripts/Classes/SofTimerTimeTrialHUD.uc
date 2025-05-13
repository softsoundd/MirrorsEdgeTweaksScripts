class SofTimerTimeTrialHUD extends TdTimeTrialHUD
    transient
    config(Game)
    hidecategories(Navigation);

var SaveLoadHandler     SaveLoad;
var UIDataStore_TdGameData GameData;
var(HUDIcons) Vector2D RaceTimerPos;
var TdPlayerController  SpeedrunController;

var bool              bLoadedTimeFromSave;
var int               SkipTicks;

var int               RunCompleteMarker;
var bool              bFinalTimeLocked;

// Trainer, macro, speed variables
var vector CurrentLocation;
var rotator CurrentRotation;
var float PlayerSpeed;
var vector ConvertedLocation, PlayerVelocity;

var float MaxVelocity, MaxHeight;
var float LastMaxVelocityUpdateTime, LastMaxHeightUpdateTime;
var float UpdateInterval;  // Update every 3 seconds

var float MacroStartTime;
var bool bIsMacroTimerActive;
var float MacroFinalElapsedTime;
var name CurrentMacroType;

var string TrainerHUDMessageText;
var float TrainerHUDMessageDisplayTime;
var float TrainerHUDMessageDuration;

var bool ShowTrainerHUDItems;
var bool ShowMacroFeedback;


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
        SaveLoad = new class'SaveLoadHandler';
    }

    CacheMeasurementUnitInfo();

    ShowTrainerHUDItems = (SaveLoad.LoadData("ShowTrainerHUDItems") == "") ? false : bool(SaveLoad.LoadData("ShowTrainerHUDItems"));
    ShowMacroFeedback = (SaveLoad.LoadData("ShowMacroFeedback") == "") ? false : bool(SaveLoad.LoadData("ShowMacroFeedback"));

    // Initialise the max values and timers
    MaxVelocity = 0.0;
    MaxHeight = 0.0;
    LastMaxVelocityUpdateTime = WorldInfo.TimeSeconds;
    LastMaxHeightUpdateTime = WorldInfo.TimeSeconds;
    UpdateInterval = 3.0;

    MapName = WorldInfo.GetMapName();

    // Lock the final time once returning to main menu
    if (MapName == "TdMainMenu")
    {
        FinalTimeFlag = SaveLoad.LoadData("FinalTimeLocked");
        if (FinalTimeFlag == "true")
        {
            bFinalTimeLocked = true;
        }
    }

    if (MapName == "TT_TutorialA01_p")
    {
        GameData.TimeAttackClock = 0;
        bFinalTimeLocked = false;
        RunCompleteMarker = 696969;
        SaveLoad.SaveData("FinalTimeLocked", "false");
    }
    
    if (MapName != "TdMainMenu")
    {
        SkipTicks = 3;
    }
    else
    {
        SkipTicks = 0;
    }

    ConsoleCommand("set TdTimeTrialHUD StarRatingPos (X=1000,Y=61)");
}

function Tick(float DeltaTime)
{
    local float RealDeltaTime;
    local string SavedTimeStr;
    local string MapName;

    super(TdHUD).Tick(DeltaTime);

    // This stops HUD/post process effects breaking
    EffectManager.Update(DeltaTime, RealTimeRenderDelta);

    if (SkipTicks > 0)
    {
        SkipTicks--;
        return;
    }

    if (SpeedrunController == none && PlayerOwner != none)
    {
        SpeedrunController = TdPlayerController(PlayerOwner);
    }

    if (SaveLoad == none)
    {
        SaveLoad = new class'SaveLoadHandler';
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
    
    if (!bLoadedTimeFromSave && MapName != "TT_TutorialA01_p")
    {
        SavedTimeStr = SaveLoad.LoadData("TimeAttackClock");
        if (SavedTimeStr != "")
        {
            GameData.TimeAttackClock = float(SavedTimeStr);
        }
        bLoadedTimeFromSave = true;
    }

    if (MapName == "TT_ScraperB01_p")
    {
        if (!bFinalTimeLocked && CheckFinalTTCompletion())
        {
            bFinalTimeLocked = true;
            RunCompleteMarker = 969696;
            SaveLoad.SaveData("FinalTimeLocked", "true");
        }
    }
    
    if (!bFinalTimeLocked)
    {
        GameData.TimeAttackClock += RealDeltaTime;
    }
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

// DrawLivingHUD & DrawLoadRemovedTimer: HUD rendering
function DrawLivingHUD()
{
    local TdSPTimeTrialGame Game;

    super(TdTimeTrialHUD).DrawLivingHUD();

    Game = TdSPTimeTrialGame(WorldInfo.Game);

    if (Game != none)
    {
        DrawRaceTimer(Game);
        DrawStarRating(Game);
        DrawTrainerItems();

        if (CheckCheatsTrainerMode())
        {
            DrawCheatsTrainerMessage();
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

    DisplayTime = Game.GetPlayerTime();
    TimeString = "TT - " $ GetTimeString(DisplayTime);
    Canvas.Font = MediumFont;
    DSOffset = (MediumFont.GetMaxCharHeight() * MediumFont.GetScalingFactor(float(Canvas.SizeY))) * FontDSOffset;
    DSOffset = FMax(1, DSOffset);
    ComputeHUDPosition(RaceTimerPos.X, RaceTimerPos.Y, 0, 0, pos);
    DrawTextWithOutLine(pos.X, pos.Y, DSOffset, DSOffset, TimeString, WhiteColor);

    Canvas.TextSize(TimeString, XL, YL);
    Canvas.Font = TinyFont;
    DSOffset = (TinyFont.GetMaxCharHeight() * MediumFont.GetScalingFactor(float(Canvas.SizeY))) * FontDSOffset;
    DSOffset = FMax(1, DSOffset);
    RTime = GameData.TimeAttackClock;
    LRT = "69* - " $ GetTimeString(RTime);
    DrawTextWithOutLine(pos.X, pos.Y + (YL * 0.8), DSOffset, DSOffset, LRT, WhiteColor);
}

function DrawCheatsTrainerMessage()
{
    local float Y, ShadowOffset;

    ShadowOffset = 2.0;
    Canvas.Font = Class'Engine'.static.GetMediumFont();

    Y = Canvas.SizeY * 0.10;
    Canvas.bCenter = true;

    // Draw shadow
    Canvas.SetPos(0 + ShadowOffset, Y + ShadowOffset);
    Canvas.DrawColor = FontDSColor;
    Canvas.DrawColor.A *= Square(FadeAmount);
    Canvas.DrawText("Cheats + Trainer Mode active!", False, 0.60, 0.60);

    // Draw main text
    Canvas.SetPos(0, Y);
    Canvas.DrawColor = RedColor;
    Canvas.DrawColor.A = byte(float(255) * FadeAmount);
    Canvas.DrawText("Cheats + Trainer Mode active!", False, 0.60, 0.60);
}

function bool CheckCheatsTrainerMode()
{
    if (SpeedrunController.CheatClass == Class'MirrorsEdgeTweaksScripts.MirrorsEdgeCheatManager')
    {
        return true;
    }
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
    TrainerHUDMessageDuration = (bIsMacroTimerActive) ? 99999.0 : 3.0;
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

defaultproperties
{
    RaceTimerPos=(X=1000,Y=55)
    RunCompleteMarker = 696969
    ShowTrainerHUDItems = false;
    ShowMacroFeedback = false;
}