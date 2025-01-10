class MirrorsEdgeTrainerSPHUD extends TdSPHUD;

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

// Handle CheatMessage
var string CheatMessageText;
var float CheatMessageDisplayTime;
var float CheatMessageDuration;

// Formats floats to two decimal places as a string that properly handles negative values
function string FormatFloat(float Value)
{
    local int IntPart, DecimalPart;
    local bool bIsNegative;
    local string DecimalPartString;

    // Check if the value is negative
    bIsNegative = (Value < 0);

    // Make the value positive for calculation if it's negative
    Value = abs(Value);

    // Get the integer part
    IntPart = int(Value);

    // Get the decimal part (two decimal places)
    DecimalPart = int((Value - IntPart) * 100 + 0.5);  // Adding 0.5 for proper rounding

    // Ensure the decimal part is always two digits by padding with a leading zero if necessary
    if (DecimalPart < 10)
    {
        DecimalPartString = "0" $ string(DecimalPart);  // Add leading zero
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
    local int EstimatedMessageLength;

    // Assign a value to ShadowOffset separately
    ShadowOffset = 2.0;

    // Ensure that max velocity and height tracking variables are initialised
    if (MaxVelocity == 0 && LastMaxVelocityUpdateTime == 0 && MaxHeight == 0 && LastMaxHeightUpdateTime == 0)
    {
        MaxVelocity = 0.0;
        MaxHeight = 0.0;
        LastMaxVelocityUpdateTime = WorldInfo.TimeSeconds;
        LastMaxHeightUpdateTime = WorldInfo.TimeSeconds;
        UpdateInterval = 3.0;  // Set the display duration to 3 seconds
    }

    // Call the parent class to allow any other HUD drawing
    super(TdSPHUD).DrawLivingHUD();

    // Get the current player pawn and cast it to TdPawn
    PlayerPawn = TdPawn(PlayerOwner.Pawn);

    // Get the player controller and cast it to TdPlayerController
    PlayerController = TdPlayerController(PlayerOwner);

    if (PlayerPawn != None)
    {
        // Get the Faith's current location and rotation
        CurrentLocation = PlayerPawn.Location;
        CurrentRotation = PlayerPawn.Rotation;

        // Get the Faith's velocity
        PlayerVelocity = PlayerPawn.Velocity;
        PlayerVelocity.Z = 0;

        // Calculate Faith's horizontal speed (X and Y only)
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
            MaxVelocity = PlayerSpeed;  // Reset the max velocity to current speed
        }

        // Check if the current height (Z) is higher than the max height and update if needed
        if (CurrentLocation.Z > MaxHeight)
        {
            MaxHeight = CurrentLocation.Z;  // Update the max height
            LastMaxHeightUpdateTime = WorldInfo.TimeSeconds;  // Reset the timer when a new top height is achieved
        }

        // If more than 3 seconds have passed since the last top height, reset the max height
        if (WorldInfo.TimeSeconds - LastMaxHeightUpdateTime >= UpdateInterval)
        {
            MaxHeight = CurrentLocation.Z;  // Reset the max height to current Z
        }

        // Get the Faith's health
        PlayerHealth = PlayerPawn.Health;

        // Get the Faith's current movement state from TdPawn
        MoveState = PlayerPawn.MovementState;

        // Get the Faith's ReactionTimeEnergy from TdPlayerController
        ReactionTimeEnergy = PlayerController.ReactionTimeEnergy;

        // Get the pitch from Faith's view rotation (Pitch requires this)
        if (PlayerPawn.Controller != None)
        {
            CurrentRotation.Pitch = PlayerPawn.Controller.Rotation.Pitch;
        }

        // Convert the position by dividing by 100 for display
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

        // Retrieve the last jump location Z value
        RoundedLastJumpZ = float(int((PlayerPawn.LastJumpLocation.Z / 100 * 10000) + 0.5)) / 100.0 / 100.0;

        // Calculate the delta between the current Z and the last jump Z
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

        // Set the fixed height for each line
        LineHeight = 30.0;
        X = 0.8275 * Canvas.SizeX;
        Y = 0.80 * Canvas.SizeY;

        // Set the font
        Canvas.Font = Class'Engine'.static.GetMediumFont();

        // Draw each line
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

        // Check if there's a cheat message to display and the timer hasn't expired
        if (CheatMessageText != "" && WorldInfo.TimeSeconds - CheatMessageDisplayTime <= CheatMessageDuration)
        {
            // Rudimentary way to "center" the text, though it's not really centering. Could be improved
            EstimatedMessageLength = Len(CheatMessageText) * 9;

            // Calculate approximate centered X and Y positions
            X = (Canvas.SizeX - EstimatedMessageLength) * 0.5;
            Y = Canvas.SizeY * 0.60;

            // Draw the cheat message in the center of the screen
            DrawTextWithShadow(CheatMessageText, X, Y, ShadowOffset);
        }
        else
        {
            // Clear the message after the duration has passed
            CheatMessageText = "";
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

// This is used to provide feedback for other cheats, pretty handy
exec function DisplayCheatMessage(string Message)
{
    CheatMessageText = Message;
    CheatMessageDisplayTime = WorldInfo.TimeSeconds;
    CheatMessageDuration = 3.0;  // Duration to display the message in seconds
}

defaultproperties
{
}