class MirrorsEdgeTrainerTutorialHUD extends TdTutorialHUD
    transient
    config(Game)
    hidecategories(Navigation);

var SaveLoadHandler SaveLoad;

// Tracking variables
var vector CurrentLocation;
var rotator CurrentRotation;
var float PlayerSpeed;
var vector ConvertedLocation, PlayerVelocity;

var float MaxVelocity, MaxHeight;
var float LastMaxVelocityUpdateTime, LastMaxHeightUpdateTime;
var float UpdateInterval;  // Update every 3 seconds

var float TimerStartTime;
var bool bIsTimerActive;
var float FinalElapsedTime;
var vector TimerLocation;

var float MacroStartTime;
var bool bIsMacroTimerActive;
var float MacroFinalElapsedTime;
var name CurrentMacroType;

var string TrainerHUDMessageText;
var float TrainerHUDMessageDisplayTime;
var float TrainerHUDMessageDuration;

var bool ShowTrainerHUDItems;
var bool ShowTrainerHUDMessages;

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

event PostBeginPlay()
{
    local string SerialisedVector;

    super.PostBeginPlay();

    if (SaveLoad == None)
    {
        SaveLoad = new class'SaveLoadHandler';
    }

    // Load HUD config just once
    ShowTrainerHUDItems = (SaveLoad.LoadData("ShowTrainerHUDItems") == "") ? true : bool(SaveLoad.LoadData("ShowTrainerHUDItems"));
    ShowTrainerHUDMessages = (SaveLoad.LoadData("ShowTrainerHUDMessages") == "") ? true : bool(SaveLoad.LoadData("ShowTrainerHUDMessages"));

    SerialisedVector = SaveLoad.LoadData("TimerLocation");
    if (SerialisedVector != "")
    {
        TimerLocation = class'SaveLoadHandler'.static.DeserialiseVector(SerialisedVector);
    }
    
    // Initialise the max values and timers
    MaxVelocity = 0.0;
    MaxHeight = 0.0;
    LastMaxVelocityUpdateTime = WorldInfo.TimeSeconds;
    LastMaxHeightUpdateTime = WorldInfo.TimeSeconds;
    UpdateInterval = 3.0;
}

function Tick(float DeltaTime)
{
    super(TdHUD).Tick(DeltaTime);

    // This stops HUD/post process effects breaking
    EffectManager.Update(DeltaTime, RealTimeRenderDelta);
}

function DrawLivingHUD()
{
    super(TdTutorialHUD).DrawLivingHUD();
    DrawTrainerItems();
}

function DrawTrainerItems()
{
    local float CurrentTime;
    local TdPawn PlayerPawn;
    local TdPlayerController PlayerController;
    local float X, Y, ShadowOffset;
    local float RoundedX, RoundedY, RoundedZ;
    local float RoundedSpeed, RoundedYaw, RoundedPitch;
    local float RoundedMaxSpeed, RoundedMaxHeight, RoundedLastJumpZ, RoundedZDelta;
    local float Yaw, Pitch;
    local string YawText, PitchText;
    local string HealthText, ReactionTimeEnergyText, MoveStateText, SpeedText;
    local string MaxVelocityText, LocationTextX, LocationTextY, LocationTextZ;
    local string MaxHeightText, LastJumpZText, ZDeltaText;
    local float ElapsedTime, DistanceToTarget, MacroElapsedTime;
    local EMovement MoveState;
    local float PlayerHealth, ReactionTimeEnergy;
    
    CurrentTime = WorldInfo.TimeSeconds;

    PlayerPawn = TdPawn(PlayerOwner.Pawn);
    PlayerController = TdPlayerController(PlayerOwner);

    if (PlayerPawn != None)
    {
        CurrentLocation = PlayerPawn.Location;
        CurrentRotation = PlayerPawn.Rotation;
        PlayerVelocity = PlayerPawn.Velocity;
        PlayerVelocity.Z = 0;
        PlayerSpeed = VSize(PlayerVelocity);
        // Convert from cm/s to km/h (multiplication factor 0.036)
        PlayerSpeed *= 0.036;
        
        // Update max velocity and height using helper function
        MaxVelocity = UpdateMaxValue(MaxVelocity, PlayerSpeed, LastMaxVelocityUpdateTime, CurrentTime);
        MaxHeight   = UpdateMaxValue(MaxHeight, CurrentLocation.Z, LastMaxHeightUpdateTime, CurrentTime);

        PlayerHealth = PlayerPawn.Health;
        MoveState = PlayerPawn.MovementState;
        ReactionTimeEnergy = PlayerController.ReactionTimeEnergy;

        // Use controller rotation for pitch if available
        if (PlayerPawn.Controller != None)
        {
            CurrentRotation.Pitch = PlayerPawn.Controller.Rotation.Pitch;
        }

        // Convert location to meters by dividing by 100
        ConvertedLocation = CurrentLocation / 100;

        // Convert rotation (from 65536 units to degrees)
        Yaw   = (float(CurrentRotation.Yaw) / 65536.0) * 360.0;
        Pitch = (float(CurrentRotation.Pitch) / 65536.0) * 360.0;
        if (Yaw < 0) Yaw += 360.0;
        if (Pitch > 180.0) Pitch -= 360.0;

        // Use helper function to perform rounding to two decimals
        RoundedX = RoundToTwoDecimals(ConvertedLocation.X);
        RoundedY = RoundToTwoDecimals(ConvertedLocation.Y);
        RoundedZ = RoundToTwoDecimals(ConvertedLocation.Z);
        RoundedSpeed = RoundToTwoDecimals(PlayerSpeed);
        RoundedYaw = RoundToTwoDecimals(Yaw);
        RoundedPitch = RoundToTwoDecimals(Pitch);
        RoundedMaxSpeed = RoundToTwoDecimals(MaxVelocity);
        RoundedMaxHeight = RoundToTwoDecimals(MaxHeight / 100);  // Convert back to meters for display

        // Handle jump location and Z delta
        RoundedLastJumpZ = RoundToTwoDecimals(PlayerPawn.LastJumpLocation.Z / 100);
        RoundedZDelta = RoundToTwoDecimals((CurrentLocation.Z - PlayerPawn.LastJumpLocation.Z) / 100);

        // Timer display logic
        if (bIsTimerActive)
        {
            ElapsedTime = CurrentTime - TimerStartTime;
            DistanceToTarget = VSize(PlayerPawn.Location - TimerLocation) / 100.0;
            if (DistanceToTarget <= 1.0)
            {
                bIsTimerActive = false;
                FinalElapsedTime = ElapsedTime;
            }
        }
        else
        {
            ElapsedTime = FinalElapsedTime;
        }

        MacroElapsedTime = (bIsMacroTimerActive) ? (CurrentTime - MacroStartTime) : 0.0;

        // Prepare HUD texts using FormatFloat
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

        // Set text drawing properties
        ShadowOffset = 2.0;
        X = 0.8275 * Canvas.SizeX;
        Y = 0.72 * Canvas.SizeY;
        Canvas.Font = Class'Engine'.static.GetMediumFont();

        // Draw HUD items if enabled
        if (ShowTrainerHUDItems)
        {
            DrawTextWithShadow("T = " $ FormatFloat(ElapsedTime) $ " s", X, Y - 18 * 25.0, ShadowOffset);
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

        // Draw HUD messages if enabled
        if (ShowTrainerHUDMessages)
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

exec function StartHUDTimer()
{
    TimerStartTime = WorldInfo.TimeSeconds;
    bIsTimerActive = true;
}

exec function ResetHUDTimer()
{
    TimerStartTime = WorldInfo.TimeSeconds;
    FinalElapsedTime = 0.0;
    bIsTimerActive = false;
}

exec function SetHUDTimerLocation(float X, float Y, float Z)
{
    TimerLocation.X = X;
    TimerLocation.Y = Y;
    TimerLocation.Z = Z;
    SaveLoad.SaveData("TimerLocation", class'SaveLoadHandler'.static.SerialiseVector(TimerLocation));
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

exec function ToggleHUDMessages()
{
    ShowTrainerHUDMessages = !ShowTrainerHUDMessages;
    SaveLoad.SaveData("ShowTrainerHUDMessages", string(ShowTrainerHUDMessages));
}

defaultproperties
{
    ShowTrainerHUDItems = true;
    ShowTrainerHUDMessages = true;
}