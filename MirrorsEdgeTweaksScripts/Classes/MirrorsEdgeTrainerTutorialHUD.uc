class MirrorsEdgeTrainerTutorialHUD extends TdTutorialHUD
    transient
    config(Game)
    hidecategories(Navigation);

var SaveLoadHandler SaveLoad;

// Track location and velocity
var vector CurrentLocation;
var rotator CurrentRotation;
var float PlayerSpeed;
var vector ConvertedLocation, PlayerVelocity;

// Track time and maximum velocity
var float MaxVelocity, MaxHeight;
var float LastMaxVelocityUpdateTime, LastMaxHeightUpdateTime;  // Tracks the last time the max velocity was updated
var float UpdateInterval;  // Update every 3 seconds, like mmultiplayer

// Handle TimerLocation
var float TimerStartTime;
var bool bIsTimerActive;
var float FinalElapsedTime;
var vector TimerLocation;

// Handle Macro timer
var float MacroStartTime;
var bool bIsMacroTimerActive;
var float MacroFinalElapsedTime;
var name CurrentMacroType;

// Handle HUD messages
var string TrainerHUDMessageText;
var float TrainerHUDMessageDisplayTime;
var float TrainerHUDMessageDuration;

var bool ShowTrainerHUDItems;
var bool ShowTrainerHUDMessages;

// Formats floats to two decimal places as a string that properly handles negative values
function string FormatFloat(float Value)
{
    local int IntPart, DecimalPart;
    local bool bIsNegative;
    local string DecimalPartString;

    bIsNegative = (Value < 0);

    // Make the value positive for calculation if it's negative
    Value = abs(Value);

    IntPart = int(Value);

    DecimalPart = int((Value - IntPart) * 100 + 0.5);  // Adding 0.5 for proper rounding

    // Ensure the decimal part is always two digits by padding with a leading zero if necessary
    if (DecimalPart < 10)
    {
        DecimalPartString = "0" $ string(DecimalPart);
    }
    else
    {
        DecimalPartString = string(DecimalPart);
    }

    // Format the result, adding the negative sign back if needed
    if (bIsNegative)
    {
        return ("-" $ string(IntPart) $ "." $ DecimalPartString);
    }
    else
    {
        return (string(IntPart) $ "." $ DecimalPartString);
    }
}

// Todo: this mimicks the way drop shadows are done in Mirror's Edge, but probably better to use the game's actual DS function
function DrawTextWithShadow(string Text, float X, float Y, float ShadowOffset)
{
    // Set shadow color
    Canvas.SetDrawColor(0, 80, 130, 128);
    
    // Draw shadow
    Canvas.SetPos(X + ShadowOffset, Y + ShadowOffset);
    Canvas.DrawText(Text, False, 0.70, 0.70);

    // Set actual text color
    Canvas.SetDrawColor(255, 255, 255, 255);
    
    // Draw actual text
    Canvas.SetPos(X, Y);
    Canvas.DrawText(Text, False, 0.70, 0.70);
}

function DrawLivingHUD()
{
    local string LocationTextX, LocationTextY, LocationTextZ, YawText, PitchText, SpeedText, HealthText, MoveStateText, MaxVelocityText, MaxHeightText, LastJumpZText, ZDeltaText, ReactionTimeEnergyText;
    local float X, Y;
    local float RoundedX, RoundedY, RoundedZ, RoundedYaw, RoundedPitch, RoundedSpeed, RoundedMaxSpeed, RoundedMaxHeight, RoundedLastJumpZ, RoundedZDelta;
    local float LineHeight;
    local float Yaw, Pitch;
    local float ShadowOffset;
    local float PlayerHealth;
    local float ReactionTimeEnergy;
    local TdPawn PlayerPawn;
    local TdPlayerController PlayerController;
    local EMovement MoveState;
    local float ZDelta;
    local float ElapsedTime;
    local float DistanceToTarget;
    local float MacroElapsedTime;
    local string LoadedHUDItems;
    local string LoadedHUDMessages;

    // Initialise SaveLoadHandler
    if (SaveLoad == None)
    {
        SaveLoad = new class'SaveLoadHandler';
    }

    LoadedHUDItems = SaveLoad.LoadData("ShowTrainerHUDItems");
    if (LoadedHUDItems == "")
    {
        ShowTrainerHUDItems = true;
    }
    else
    {
        ShowTrainerHUDItems = bool(SaveLoad.LoadData("ShowTrainerHUDItems"));
    }
    
    LoadedHUDMessages = SaveLoad.LoadData("ShowTrainerHUDMessages");
    if (LoadedHUDMessages == "")
    {
        ShowTrainerHUDMessages = true;
    }
    else
    {
        ShowTrainerHUDMessages = bool(SaveLoad.LoadData("ShowTrainerHUDMessages"));
    }

    ShadowOffset = 2.0;

    // Ensure that max velocity and height tracking variables are initialised
    if (MaxVelocity == 0 && LastMaxVelocityUpdateTime == 0 && MaxHeight == 0 && LastMaxHeightUpdateTime == 0)
    {
        MaxVelocity = 0.0;
        MaxHeight = 0.0;
        LastMaxVelocityUpdateTime = WorldInfo.TimeSeconds;
        LastMaxHeightUpdateTime = WorldInfo.TimeSeconds;
        UpdateInterval = 3.0;
    }

    // Call the parent class to allow any other HUD drawing
    super(TdTutorialHUD).DrawLivingHUD();

    PlayerPawn = TdPawn(PlayerOwner.Pawn);

    PlayerController = TdPlayerController(PlayerOwner);

    if (PlayerPawn != None)
    {
        CurrentLocation = PlayerPawn.Location;
        CurrentRotation = PlayerPawn.Rotation;

        PlayerVelocity = PlayerPawn.Velocity;
        PlayerVelocity.Z = 0;

        PlayerSpeed = VSize(PlayerVelocity);  
        PlayerSpeed = (PlayerSpeed / 100) * 3.6;  // Convert to km/h

        // Check if the current speed is higher than the max velocity and update if needed
        if (PlayerSpeed > MaxVelocity)
        {
            MaxVelocity = PlayerSpeed;
            LastMaxVelocityUpdateTime = WorldInfo.TimeSeconds;  // Reset the timer when a new top speed is achieved
        }

        // If more than 3 seconds have passed since the last top speed, reset the max velocity
        if (WorldInfo.TimeSeconds - LastMaxVelocityUpdateTime >= UpdateInterval)
        {
            MaxVelocity = PlayerSpeed;
        }

        // Check if the current height (Z) is higher than the max height and update if needed
        if (CurrentLocation.Z > MaxHeight)
        {
            MaxHeight = CurrentLocation.Z;
            LastMaxHeightUpdateTime = WorldInfo.TimeSeconds;  // Reset the timer when a new top height is achieved
        }

        // If more than 3 seconds have passed since the last top height, reset the max height
        if (WorldInfo.TimeSeconds - LastMaxHeightUpdateTime >= UpdateInterval)
        {
            MaxHeight = CurrentLocation.Z;
        }

        PlayerHealth = PlayerPawn.Health;

        MoveState = PlayerPawn.MovementState;

        ReactionTimeEnergy = PlayerController.ReactionTimeEnergy;

        // Get the pitch from Faith's view rotation (Pitch requires this)
        if (PlayerPawn.Controller != None)
        {
            CurrentRotation.Pitch = PlayerPawn.Controller.Rotation.Pitch;
        }

        ConvertedLocation.X = CurrentLocation.X / 100;
        ConvertedLocation.Y = CurrentLocation.Y / 100;
        ConvertedLocation.Z = CurrentLocation.Z / 100;

        // Convert the rotation back to degrees (360 degrees from 65536)
        Yaw = (float(CurrentRotation.Yaw) / 65536.0) * 360.0;
        Pitch = (float(CurrentRotation.Pitch) / 65536.0) * 360.0;

        // Ensure Yaw is always between 0 and 360 degrees
        if (Yaw < 0)
        {
            Yaw += 360.0;
        }

        // Adjust Pitch to display negative values for below the horizon
        if (Pitch > 180.0)
        {
            Pitch -= 360.0;  
        }

        // Manually round values to two decimal places and better handle floating-point variations
        RoundedX = float(int((ConvertedLocation.X * 10000) + 0.5)) / 100.0 / 100.0;
        RoundedY = float(int((ConvertedLocation.Y * 10000) + 0.5)) / 100.0 / 100.0;
        RoundedZ = float(int((ConvertedLocation.Z * 10000) + 0.5)) / 100.0 / 100.0;
        RoundedSpeed = float(int(PlayerSpeed * 100 + 0.5)) / 100;
        RoundedYaw = float(int(Yaw * 100 + 0.5)) / 100;
        RoundedPitch = float(int(Pitch * 100 + 0.5)) / 100;
        RoundedMaxSpeed = float(int(MaxVelocity * 100 + 0.5)) / 100;
        RoundedMaxHeight = float(int((MaxHeight / 100 * 10000) + 0.5)) / 100.0 / 100.0;

        RoundedLastJumpZ = float(int((PlayerPawn.LastJumpLocation.Z / 100 * 10000) + 0.5)) / 100.0 / 100.0;

        ZDelta = CurrentLocation.Z - PlayerPawn.LastJumpLocation.Z;
        RoundedZDelta = float(int((ZDelta / 100 * 10000) + 0.5)) / 100.0 / 100.0;

        // Timer display logic
        if (bIsTimerActive)
        {
            // Calculate elapsed time if the timer is active
            ElapsedTime = WorldInfo.TimeSeconds - TimerStartTime;

            // Calculate the distance to the target location in meters
            DistanceToTarget = VSize(PlayerOwner.Pawn.Location - TimerLocation) / 100.0;

            // Check if Faith is within 1 meter of the target location to stop the timer, this is how it's done in mmultiplayer
            if (DistanceToTarget <= 1.0)
            {
                bIsTimerActive = false;  // Pause the timer
                FinalElapsedTime = ElapsedTime;  // Store the final elapsed time
            }
        }
        else
        {
            // Use the stored final elapsed time if the timer is paused
            ElapsedTime = FinalElapsedTime;
        }

        if (bIsMacroTimerActive)
        {
            MacroElapsedTime = WorldInfo.TimeSeconds - MacroStartTime;
        }
        else
        {
            MacroElapsedTime = 0;
        }

        // Format the text to display on the HUD with exactly two decimal places
        HealthText = "H = " $ int(PlayerHealth) $ "%";
        ReactionTimeEnergyText = "RT = " $ int(ReactionTimeEnergy) $ "%";
        MoveStateText = string(MoveState);
        if (Left(MoveStateText, 5) == "MOVE_")
        {
            MoveStateText = Mid(MoveStateText, 5);  // Remove the first 5 characters from the enum ("MOVE_")
        }
        MoveStateText = "MS = " $ MoveStateText;
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

        LineHeight = 25.0;
        X = 0.8275 * Canvas.SizeX;
        Y = 0.80 * Canvas.SizeY;

        Canvas.Font = Class'Engine'.static.GetMediumFont();

        if (ShowTrainerHUDItems)
        {
            DrawTextWithShadow("T = " $ FormatFloat(ElapsedTime) $ " s", X, Y - 18 * LineHeight, ShadowOffset);
            DrawTextWithShadow(HealthText, X, Y - 16 * LineHeight, ShadowOffset);
            DrawTextWithShadow(ReactionTimeEnergyText, X, Y - 15 * LineHeight, ShadowOffset);
            DrawTextWithShadow(MoveStateText, X, Y - 14 * LineHeight, ShadowOffset);
            DrawTextWithShadow(SpeedText, X, Y - 12 * LineHeight, ShadowOffset);
            DrawTextWithShadow(MaxVelocityText, X, Y - 11 * LineHeight, ShadowOffset);
            DrawTextWithShadow(LocationTextX, X, Y - 9 * LineHeight, ShadowOffset);
            DrawTextWithShadow(LocationTextY, X, Y - 8 * LineHeight, ShadowOffset);
            DrawTextWithShadow(LocationTextZ, X, Y - 7 * LineHeight, ShadowOffset);
            DrawTextWithShadow(MaxHeightText, X, Y - 6 * LineHeight, ShadowOffset);
            DrawTextWithShadow(LastJumpZText, X, Y - 5 * LineHeight, ShadowOffset);
            DrawTextWithShadow(ZDeltaText, X, Y - 4 * LineHeight, ShadowOffset);
            DrawTextWithShadow(YawText, X, Y - 2 * LineHeight, ShadowOffset);
            DrawTextWithShadow(PitchText, X, Y - LineHeight, ShadowOffset);
        }

        if (ShowTrainerHUDMessages)
        {
            // Check if there's a cheat message to display and the timer hasn't expired
            if (TrainerHUDMessageText != "" && WorldInfo.TimeSeconds - TrainerHUDMessageDisplayTime <= TrainerHUDMessageDuration)
            {
                X = Canvas.SizeX * 0.25;
                Y = Canvas.SizeY * 0.60;

                Canvas.bCenter = true;

                DrawTextWithShadow(TrainerHUDMessageText, 0, Y, ShadowOffset);
            }
            else
            {
                // Clear the message after the duration has passed
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

// This is used to provide feedback, pretty handy
exec function DisplayTrainerHUDMessage(string Message)
{
    TrainerHUDMessageText = Message;
    TrainerHUDMessageDisplayTime = WorldInfo.TimeSeconds;
    TrainerHUDMessageDuration = 3.0;

    if (bIsMacroTimerActive)
    {
        TrainerHUDMessageDuration = 99999.0;
    }
    else
    {
        TrainerHUDMessageDuration = 3.0;
    }
}

exec function ToggleTrainerHUD()
{
    if (ShowTrainerHUDItems == true)
    {
        ShowTrainerHUDItems = false;
    }
    else
    {
        ShowTrainerHUDItems = true;
    }

    SaveLoad.SaveData("ShowTrainerHUDItems", string(ShowTrainerHUDItems));
}

exec function ToggleHUDMessages()
{
    if (ShowTrainerHUDMessages == true)
    {
        ShowTrainerHUDMessages = false;
    }
    else
    {
        ShowTrainerHUDMessages = true;
    }

    SaveLoad.SaveData("ShowTrainerHUDMessages", string(ShowTrainerHUDMessages));
}

defaultproperties
{
    ShowTrainerHUDItems = true;
    ShowTrainerHUDMessages = true;
}