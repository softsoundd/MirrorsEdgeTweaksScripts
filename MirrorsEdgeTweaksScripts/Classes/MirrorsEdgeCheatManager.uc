class MirrorsEdgeCheatManager extends TdCheatManager;

var CheatHelperProxy HelperProxy;
var SaveLoadHandler SaveLoad;
var vector SavedLocation;
var rotator SavedRotation;
var vector SavedVelocity;
var float SavedZVelocity;
var vector SavedLastJumpLocation;
var TdPawn.EMovement SavedMoveState;
var float SavedHealth;
var bool SavedReactionTimeState;
var float SavedReactionTimeEnergy;
var vector TimerLocation;
var bool bInfiniteAmmoEnabled;
var bool bBotOHKOEnabled;
var bool bHoldFireEnabled;
var bool bMonitorFallHeight;
var bool bMonitorNoclip;
var string MeleeState;
var bool bJumpMacroActive;
var bool bInteractMacroActive;
var bool bGrabMacroActive;

// Dolly variables
var bool   bMonitorDolly;
var bool   bIsDollyActive;
var bool   bIsPlayingDolly;
var vector DollyStartPos;
var rotator DollyStartRot;
var float  DollyStartFOV;
var float CurrentFOV;
var float GlobalDollyDuration;
var float GlobalElapsedTime;

struct DollyKeyframe
{
    var vector   Position;
    var rotator  Rotation;
    var float    Duration;
    var float    FOV;
};

var array<DollyKeyframe> Keyframes;

exec function ListCheats()
{
    ClientMessage(" ");
    ClientMessage("Player Attributes and Physics:");
    ClientMessage("\"JumpHeight\" - Sets the height gained from a jump (default value = 630)");
    ClientMessage("\"JumpSpeed\" - Sets the horizontal speed gained from a jump while moving (default value = 100)");
    ClientMessage("\"SpeedCap\" - Sets the speed cap that is applied while in the air (default value = 3500)");
    ClientMessage("\"RollHeight\" - Sets the fall height before a hard landing is triggered and a skill roll is necessary (default value = 530)");
    ClientMessage("\"DeathHeight\" - Sets the fall height before entering the uncontrolled falling state that kills you upon landing (default value = 1000)");
    ClientMessage("\"Gravity\" - Sets the gravity multiplier (default value = 1 | Spaceboots category = 0.125)");
    ClientMessage("\"GameSpeed\" - Sets the game speed multiplier (default value = 1)");
    ClientMessage(" ");
    ClientMessage("Utilities:");
    ClientMessage("\"MaxFPS\" - Sets the max FPS limit (default value = 62). Set to 0 to remove the limiter altogether");
    ClientMessage("\"Resolution [WIDTH] [HEIGHT] [WINDOWED (optional)]\" - Sets the resolution. Also fixes blurry text for resolutions greater than 1080p");
    ClientMessage("\"DollyHelp\" - See dolly camera functions");
    ClientMessage("\"UltraGraphics\" - Sets draw distance and LOD quality to its maximum (only for currently loaded actors). Restarting the level resets these properties");
    ClientMessage("\"ColorScaling [RED] [GREEN] [BLUE]\" - Adjusts individual color channels for the final image (default values = 1, 1, 1)");
    ClientMessage("\"PostProcess Highlights [RED] [GREEN] [BLUE]\" - More granular control compared to ColorScaling. Accepts values 0 to 1");
    ClientMessage("\"PostProcess Midtones [RED] [GREEN] [BLUE]\" - More granular control compared to ColorScaling. Accepts values 0 to 1");
    ClientMessage("\"PostProcess Shadows [RED] [GREEN] [BLUE]\" - More granular control compared to ColorScaling. Accepts values -1 to 1");
    ClientMessage("\"PostProcess Saturation [STRENGTH]\" - Adjusts saturation strength for the final image. Accepts values -1 to 1");
    ClientMessage("\"FreezeFrame\" - Freezes time and hides the crosshair. Set the desired delay value in seconds before it engages (use interact key or pause to exit this mode)");
    ClientMessage("\"FreezeWorld\" - Freezes everything except you");
    ClientMessage("\"StreamLevelIn [MAP PACKAGE]\" - Load the specified map package name and make it active (or all of them with \"All\"). Refer to \"stat levels\" for a list of valid packages");
    ClientMessage("\"OnlyLoadLevel [MAP PACKAGE]\" - Load the specified map package name but keep it inactive (or all of them with \"All\"). Refer to \"stat levels\" for a list of valid packages");
    ClientMessage("\"StreamLevelOut [MAP PACKAGE]\" - Unload the specified map package name (or all of them with \"All\"). Refer to \"stat levels\" for a list of valid packages");
    ClientMessage("\"Bind [KEY] [COMMAND]\" - Custom bind function that improves upon the built in \"setbind\" command. If you want to clear a bind, type \"null\" in the command parameter");
    ClientMessage(" ");
    ClientMessage("Player Cheats:");
    ClientMessage("\"God\" - Toggles \"true\" God mode (doesn't make bots invincible)");
    ClientMessage("\"HarmlessBots\" - Toggles the ability for bots to shoot and perform melee attacks (this may be overridden during scripted sections, just toggle again)");
    ClientMessage("\"FreezeWorld\" - Toggles the movement of bots and all other skeletal meshes besides yourself (this is bugged in Mirror's Edge and also disables interactables)");
    ClientMessage("\"InfiniteAmmo\" - Toggles infinite ammo for weapons");
    ClientMessage("\"ListAllWeapons\" - View a list of all valid weapons to equip");
    ClientMessage("\"DestroyViewedActor\" - Destroys the bot/object currently looked at (some objects are connected to essential world geometry and are excluded)");
    ClientMessage("\"ChangeSize\" - Scale Faith's size by the specified value (breaks quickly beyond a value of 1)");
    ClientMessage("\"BotOHKO\" - One hit knockout - bots immediately die to any form of damage");
    ClientMessage(" ");
    ClientMessage("Movement and Teleportation:");
    ClientMessage("\"Noclip\" - Toggles noclip/fly (equivalent to UE3's Ghost cheat). Q and E sets noclip speed");
    ClientMessage("\"Tp\" - Teleports to manually provided X/Y/Z coordinates and Pitch/Yaw angles");
    ClientMessage("\"CurrentLocation\" - Prints the current player location and rotation to the console");
    ClientMessage("\"SaveLocation\" - Saves the current player location and rotation (useful when added as a bind)");
    ClientMessage("\"TpToSavedLocation | OnRelease TpToSavedLocation_OnRelease\" - Teleports the player to SaveLocation (useful when added as a bind)");
    ClientMessage("\"TpToSurface\" - Teleports to the surface currently looked at");
    ClientMessage("\"SaveTimerLocation\" - Saves the current player location as the checkpoint for the timer in the trainer HUD (useful when added as a bind)");
    ClientMessage("\"LastJumpLocation\" - Sets the Z component of the last jump location (SZ in trainer HUD) - intended for attempting flings anywhere");
    ClientMessage(" ");
}

exec function ListAllWeapons()
{
    ClientMessage("Simply type the listed weapon to equip it:");
    ClientMessage("\"G36C\"");
    ClientMessage("\"MP5K\"");
    ClientMessage("\"Neostead\"");
    ClientMessage("\"M93R\" - Despite the fact that you can't get this weapon in the story, it's complete and fully functional");
    ClientMessage("\"SCARL\"");
    ClientMessage("\"FNMinimi\"");
    ClientMessage("\"M1911\"");
    ClientMessage("\"Glock\" - This weapon appears only once in the story, making it the rarest (accessible) weapon in the game");
    ClientMessage("\"M870\"");
    ClientMessage("\"SteyrTMP\"");
    ClientMessage("\"M95\" - The only weapon that can kill the assassin in The Boat!");
    ClientMessage(" ");
    ClientMessage("Unused:");
    ClientMessage("\"Taser\" - The complete taser model - makes a buzzing sound when firing but deals zero damage and has broken third-person rigging");
    ClientMessage("\"AltTaser\" - Although named as a taser, the model is invisible and acts like a pistol, dealing very little damage (and has a strange firing sound)");
    ClientMessage("\"DE05\" - A semi-automatic version of the Glock. The name suggests this originally may have been planned to be a Desert Eagle (also has a strange firing sound)");
    ClientMessage("\"SmokeGrenade\" - An untextured smoke grenade model that is used with pistol animations. Grenade is unusable but holding down the fire button shows a reload animation");
    ClientMessage("\"FlashbangGrenade\" - An invisible model with otherwise the same properties as the smoke grenade");
    ClientMessage("\"Bag\" - An incomplete implemenation of an equipped runner bag - pressing the fire button removes the bag");
}

exec function DollyHelp()
{
    ClientMessage(" ");
    ClientMessage("\"DollyStart\" - Starts dolly camera mode. Entering this while you're already in dolly mode will clear all keyframes and start over");
    ClientMessage("\"DollyAdd [DURATION]\" - Adds a keyframe for the current camera properties. The duration parameter defines how many seconds it takes to reach the next keyframe");
    ClientMessage("\"DollyUndo\" - Removes the previously added keyframe");
    ClientMessage("\"DollyRoll [DEGREES]\" - Sets the roll of the dolly camera. Alternativey use Left and Right arrow keys");
    ClientMessage("\"DollyFOV [DEGREES]\" - Sets the FOV (zoom) of the dolly camera. Alternativey use Up and Down arrow keys");
    ClientMessage("\"DollySpeed\" - Sets the input movement speed of the dolly camera (e.g. make it slower if you want finer control). Alternativey use Q and E keys");
    ClientMessage("\"DollyPlay\" - Plays the dolly camera sequence. The UI will be forcefully hidden during this, avoid pressing buttons");
    ClientMessage("\"DollyStop\" - Clears all keyframes and exits out of dolly camera mode");
    ClientMessage(" ");
}

// "True" God mode. Todo: see if we can set these variables directly rather than relying on the "set" command. Also if we can avoid doing it via the collision method?
exec function God()
{
    if (bGodMode)
    {
        bGodMode = false;
        ClientMessage("God mode disabled.");
        ConsoleCommand("DisplayTrainerHUDMessage God mode disabled");

        ConsoleCommand("set TdKillVolume CollisionType COLLIDE_CustomDefault");
        ConsoleCommand("set TdKillZoneVolume CollisionType COLLIDE_CustomDefault");
        ConsoleCommand("set TdKillZoneKiller CollisionType COLLIDE_CustomDefault");
        ConsoleCommand("set TdFallHeightVolume CollisionType COLLIDE_CustomDefault");
        ConsoleCommand("set TdBarbedWireVolume CollisionType COLLIDE_CustomDefault");
        ConsoleCommand("set DynamicTriggerVolume CollisionType COLLIDE_CustomDefault");
        
        return;
    }

    bGodMode = true;
    ClientMessage("God mode enabled");
    ConsoleCommand("DisplayTrainerHUDMessage God mode enabled");

    ConsoleCommand("set TdKillVolume CollisionType COLLIDE_NoCollision");
    ConsoleCommand("set TdKillZoneVolume CollisionType COLLIDE_NoCollision");
    ConsoleCommand("set TdKillZoneKiller CollisionType COLLIDE_NoCollision");
    ConsoleCommand("set TdFallHeightVolume CollisionType COLLIDE_NoCollision");
    ConsoleCommand("set TdBarbedWireVolume CollisionType COLLIDE_NoCollision");
    ConsoleCommand("set DynamicTriggerVolume CollisionType COLLIDE_NoCollision");
}

// Toggle harmless bots. Todo: see if we can set these variables directly rather than relying on the "set" command
exec function HarmlessBots()
{
    local string Command;
    local string GunfireValue;
    local string MeleeValue;
    local string TargetClass;
    local string CombinedMessage;
    
    TargetClass = "TdAIController";

    if (bHoldFireEnabled)
    {
        GunfireValue = "False";
        bHoldFireEnabled = False;
    }
    else
    {
        GunfireValue = "True";
        bHoldFireEnabled = True;
    }

    if (MeleeState == "None")
    {
        MeleeValue = "Melee";
        MeleeState = "Melee";
    }
    else
    {
        MeleeValue = "None";
        MeleeState = "None";
    }

    Command = "set " $ TargetClass $ " bHoldFire " $ GunfireValue;
    ConsoleCommand(Command);

    Command = "set " $ TargetClass $ " MeleeState " $ MeleeValue;
    ConsoleCommand(Command);

    if (!bHoldFireEnabled && MeleeState == "Melee")
    {
        CombinedMessage = "Bots can now shoot and melee attack.";
        ConsoleCommand("DisplayTrainerHUDMessage Bots are now hostile");
    }
    else
    {
        CombinedMessage = "Bots can no longer shoot or melee attack.";
        ConsoleCommand("DisplayTrainerHUDMessage Bots are no longer hostile");
    }

    ClientMessage(CombinedMessage);
}

// Disables all non-player movement
exec function FreezeWorld()
{
	WorldInfo.bPlayersOnly = !WorldInfo.bPlayersOnly;
}

// Sets maximum ammo on all weapons. Todo: see if we can set these variables directly rather than relying on the "set" command
exec function InfiniteAmmo()
{
    local string PropertyName;
    local string Value;
    local string Command;
    local string TargetClass;

    PropertyName = "InfiniteAmmo";
    TargetClass = "TdPlayerController";

    if (bInfiniteAmmoEnabled)
    {
        Value = "False";
        bInfiniteAmmoEnabled = False;
        ClientMessage("Infinite ammo disabled.");
        ConsoleCommand("DisplayTrainerHUDMessage Infinite ammo disabled");
    }
    else
    {
        Value = "True";
        bInfiniteAmmoEnabled = True;
        ClientMessage("Infinite ammo enabled.");
        ConsoleCommand("DisplayTrainerHUDMessage Infinite ammo enabled");
    }

    Command = "set " $ TargetClass $ " " $ PropertyName $ " " $ Value;

    ConsoleCommand(Command);
}

// Destroy bots/objects looked at
exec function DestroyViewedActor()
{
    local Actor HitActor;
    local vector ViewLocation, HitLocation, HitNormal;
    local rotator ViewRotation;
    local string ActorClassName;
    local string ActorName;

    GetPlayerViewPoint(ViewLocation, ViewRotation);

    HitActor = Trace(HitLocation, HitNormal, ViewLocation + 100000 * vector(ViewRotation), ViewLocation, true);

    // Check if the trace hit an actor and that it’s not a part of WorldInfo, as these don't get hidden but still lose collision
    if (HitActor != None && HitActor.Class != class'WorldInfo')
    {
        // Convert the class reference and name of the hit actor for debugging
        ActorClassName = string(HitActor.Class);
        ActorName = string(HitActor.Name);

        // Attempt to destroy the actor
        if (!HitActor.Destroy())
        {
            // If destruction fails, hide the actor instead
            HitActor.SetHidden(true);
            HitActor.SetCollision(false, false);
            ClientMessage("Actor '" $ ActorClassName $ "' named '" $ ActorName $ "' in view was hidden.");
            ConsoleCommand("DisplayTrainerHUDMessage Actor '" $ ActorName $ "' hidden");
        }
        else
        {
            ClientMessage("Actor '" $ ActorClassName $ "' named '" $ ActorName $ "' in view was destroyed.");
            ConsoleCommand("DisplayTrainerHUDMessage Actor '" $ ActorName $ "' destroyed");
        }
    }
    else
    {
        ClientMessage("Nothing in view to destroy, or the actor lacks collision in this area, or it's part of essential world geometry.");
        ConsoleCommand("DisplayTrainerHUDMessage Nothing in view to destroy, or the actor lacks collision in this area, or it's part of essential world geometry");
    }
}

// Scale Faith's size. This is taken from UE3 source, very pointless
exec function ChangeSize(float F)
{
    Pawn.CylinderComponent.SetCylinderSize(Pawn.Default.CylinderComponent.CollisionRadius * F, Pawn.Default.CylinderComponent.CollisionHeight * F);
    Pawn.SetDrawScale(F);
    Pawn.SetLocation(Pawn.Location);
    ClientMessage("Faith's size scaled by: " $ F);
}

// Sets maximum ammo on all weapons. Todo: see if we can set these variables directly rather than relying on the "set" command
// Also make gun damage persistent and not just for the currently loaded bots
exec function BotOHKO()
{
    if (bBotOHKOEnabled)
    {
        bBotOHKOEnabled = False;
        ConsoleCommand("set TdMove_Melee MeleeDamage 33.5");
        ConsoleCommand("set TdMove_MeleeAir MeleeDamage 100");
        ConsoleCommand("set TdMove_MeleeCrouch MeleeDamage 33.5");
        ConsoleCommand("set TdMove_MeleeSlide MeleeDamage 60");
        ConsoleCommand("set TdMove_MeleeWallrun MeleeDamage 80");
        ConsoleCommand("set TdBotPawn DamageMultiplier_Head 1");
        ConsoleCommand("set TdBotPawn DamageMultiplier_Body 1");
        ClientMessage("Bot OHKO disabled.");
        ConsoleCommand("DisplayTrainerHUDMessage Bot OHKO disabled");
    }
    else
    {
        bBotOHKOEnabled = True;
        ConsoleCommand("set TdMove_Melee MeleeDamage 999");
        ConsoleCommand("set TdMove_MeleeAir MeleeDamage 999");
        ConsoleCommand("set TdMove_MeleeCrouch MeleeDamage 999");
        ConsoleCommand("set TdMove_MeleeSlide MeleeDamage 999");
        ConsoleCommand("set TdMove_MeleeWallrun MeleeDamage 999");
        ConsoleCommand("set TdBotPawn DamageMultiplier_Head 999");
        ConsoleCommand("set TdBotPawn DamageMultiplier_Body 999");
        ClientMessage("Bot OHKO enabled.");
        ConsoleCommand("DisplayTrainerHUDMessage Bot OHKO enabled");
    }
}

// Toggle Fly (noclip) mode
exec function Noclip()
{
    local TdPawn PlayerPawn;

    PlayerPawn = TdPawn(Pawn);

    if (bCheatFlying) 
    {
        // Disable noclip
        bCheatFlying = false;
        Outer.GotoState('PlayerWalking');
        Pawn.SetCollision(true, true);
        Pawn.CheatWalk();
        PlayerPawn.bAllowMoveChange = true;
        PlayerPawn.AccelRate = 6144;
        ConsoleCommand("set TdHudEffectManager UncontrolledFallingEffectSpeed 0.5");

        if (PlayerPawn != None)
        {
            // Handle fall height reset
            ConsoleCommand("set TdMove_Landing HardLandingHeight 9999999");
            ConsoleCommand("set TdPawn FallingUncontrolledHeight 9999999");
            bMonitorFallHeight = true; // Start monitoring to see if we have landed yet
            EnsureHelperProxy();
        }

        bMonitorNoclip = false;
        ConsoleCommand("DisplayTrainerHUDMessage Noclip disabled");
    }
    else
    {
        // Enable noclip
        if ((Pawn != None) && Pawn.CheatGhost())
        {
            if (PlayerPawn != None && PlayerPawn.GetStateName() == 'UncontrolledFall')
            {
                PlayerPawn.GotoState('None'); // Exit UncontrolledFall
            }
            
            PlayerPawn.StopAllCustomAnimations(0); // Immediately stop animations played before this function was called
            PlayerPawn.SetMove(MOVE_Walking); // Force walking as certain moves won't allow noclip to function

            bCheatFlying = true;
            Pawn.CheatGhost(); // Previously I didn't include this but turns out it's needed to truly disable collision when activating noclip while jumping
            Outer.GotoState('PlayerFlying');
            PlayerPawn.bAllowMoveChange = false;  // Prevents attack/q turns and other actions from interrupting flying state
            PlayerPawn.AccelRate = 999999;
            ConsoleCommand("set TdHudEffectManager UncontrolledFallingEffectSpeed 0");

            bMonitorFallHeight = false;
            bMonitorNoclip = true; // Enable death monitoring
            EnsureHelperProxy();
            ConsoleCommand("DisplayTrainerHUDMessage Noclip enabled");
        }
        else
        {
            bCollideWorld = false;
        }
    }
}

// Checks if player is still in the air after exiting noclip, and if landed, sets fall values back to default. This is used for the TpToSurface function too
function FallHeightMonitoring()
{
    local TdPawn PlayerPawn;

    if (bMonitorFallHeight && Pawn != None)
    {
        PlayerPawn = TdPawn(Pawn);

        if (PlayerPawn != None)
        {
            if (PlayerPawn.Physics == PHYS_Walking)
            {
                // Reset commands once landed
                ConsoleCommand("set TdMove_Landing HardLandingHeight 530");
                ConsoleCommand("set TdPawn FallingUncontrolledHeight 1000");
                bMonitorFallHeight = false; // Stop monitoring after landing
            }
        }
    }
}

// Keypress and death monitoring while in noclip
function NoclipMonitoring()
{
    local TdPawn PlayerPawn;
    local TdPlayerController PC;

    PlayerPawn = TdPawn(Pawn);
    PC = TdPlayerController(Pawn.Controller);

    if (bMonitorNoclip && Pawn == None) // Check if the player is dead
    {
        PlayerPawn.bAllowMoveChange = true;
        bCheatFlying = false;
        ConsoleCommand("set TdPawn bCollideWorld true");
        Outer.GotoState('PlayerWalking');
        Pawn.SetCollision(true, true);
        Pawn.CheatWalk();
        bMonitorNoclip = false; // Stop monitoring further
    }

    if (PC != None && PC.PlayerInput != None)
    {
        if (PC.PlayerInput.PressedKeys.Find('E') != -1)
        {
            if (PlayerPawn.AirSpeed <= 20000)
            {
                PlayerPawn.AirSpeed += 100;
            }
        }

        if (PC.PlayerInput.PressedKeys.Find('Q') != -1)
        {
            if (PlayerPawn.AirSpeed >= 200)
            {
                PlayerPawn.AirSpeed -= 100;
            }
        }

        if (PC.PlayerInput.PressedKeys.Find('LeftShift') != -1)
        {
            PC.PlayerInput.aUp = -1.0;
        }
        else
        {
            PC.PlayerInput.aUp = 0.0;
        }
    }
}

// Actual function for handling coordinate parameters
function BugItGo(coerce float X, coerce float Y, coerce float Z, coerce int Pitch, coerce int Yaw, coerce int Roll)
{
    local vector TheLocation;
    local rotator TheRotation;

    TheLocation.X = X;
    TheLocation.Y = Y;
    TheLocation.Z = Z;

    TheRotation.Pitch = Pitch;
    TheRotation.Yaw = Yaw;
    TheRotation.Roll = Roll;

    BugItWorker(TheLocation, TheRotation);
}

// Core function that moves the player and sets the desired rotation
function BugItWorker(vector TheLocation, rotator TheRotation)
{
    // Enter Fly mode to avoid collisions when teleporting
    Fly();

    // Set the player's location and rotation
    ViewTarget.SetLocation(TheLocation);
    Pawn.FaceRotation(TheRotation, 0.0f);
    SetRotation(TheRotation);

    // Go back to normal walking mode once done
    Fly();
}

// Friendlier version of BugItGo that accepts "real world" metre coordinates instead of Unreal units, converts pitch/yaw degrees into 16-bit
// and does not require Roll as it's not required in Mirror's Edge
exec function Tp(float X, float Y, float Z, float PitchDegrees, float YawDegrees)
{
    local float ScaledX, ScaledY, ScaledZ;
    local int ScaledPitch, ScaledYaw;

    ScaledX = X * 100;
    ScaledY = Y * 100;
    ScaledZ = Z * 100;

    // Handle negative pitch values: If pitch is negative, add 360 before conversion
    if (PitchDegrees < 0.0)
    {
        PitchDegrees += 360.0;  // Convert negative pitches to positive degrees before scaling
    }

    // Convert Pitch and Yaw from degrees to 16-bit (65536 scale)
    ScaledPitch = int((PitchDegrees / 360.0) * 65536);
    ScaledYaw = int((YawDegrees / 360.0) * 65536);

    BugItGo(ScaledX, ScaledY, ScaledZ, ScaledPitch, ScaledYaw, 0);
}

// Print current location and rotation to the console
exec function CurrentLocation()
{
    local vector CurrentLocation;
    local rotator CurrentRotation;
    local float PitchDegrees, YawDegrees;
    local vector ConvertedLocation;

    CurrentLocation = Pawn.Location;
    CurrentRotation = Pawn.Rotation;

    // Get the pitch from the player's view rotation
    if (Pawn.Controller != None)
    {
        CurrentRotation.Pitch = Pawn.Controller.Rotation.Pitch;
    }

    // Convert the position by dividing by 100 for display
    ConvertedLocation.X = CurrentLocation.X / 100;
    ConvertedLocation.Y = CurrentLocation.Y / 100;
    ConvertedLocation.Z = CurrentLocation.Z / 100;

    // Convert the rotation back to degrees (360 degrees from 65536)
    PitchDegrees = (float(CurrentRotation.Pitch) / 65536.0) * 360.0;
    YawDegrees = (float(CurrentRotation.Yaw) / 65536.0) * 360.0;

    // Adjust the pitch to display negative values for below the horizon
    if (PitchDegrees > 180.0)
    {
        PitchDegrees -= 360.0;  // Convert pitches above 180 to negative values
    }

    ClientMessage("Current Location: X=" $ ConvertedLocation.X $ ", Y=" $ ConvertedLocation.Y $ ", Z=" $ ConvertedLocation.Z $ 
                  " | Rotation: Pitch=" $ PitchDegrees $ ", Yaw=" $ YawDegrees);
}

/**
 *  SaveLocation (save), TpToSavedLocation (load and pause while held), and TpToSavedLocation_OnRelease (resume) functions.
 *
 *  A lot of this needs improvement, especially with the restoration of certain moves, but it's generally ok for what it does. mmultiplayer is a good reference
 *
 */

// Save the current location, rotation, velocity, and move state of the player
exec function SaveLocation()
{
    local vector ConvertedLocation;
    local float PitchDegrees, YawDegrees;
    local TdPawn PlayerPawn;

    // Save the current position, rotation, and velocity
    SavedLocation = Pawn.Location;
    SavedVelocity = Pawn.Velocity;          // Store the current velocity
    SavedZVelocity = Pawn.Velocity.Z;       // Store vertical velocity component
    SavedHealth = Pawn.Health;              // Save the current health
    SavedReactionTimeEnergy = GetReactionTimeEnergy();  // Save reaction time energy
    SavedReactionTimeState = GetReactionTimeState();    // Save reaction time state

    // Save the correct pitch from the Controller's view rotation, not Pawn's rotation
    if (Pawn.Controller != None)
    {
        SavedRotation.Pitch = Pawn.Controller.Rotation.Pitch;  // Capture the actual pitch from the player's view
    }
    SavedRotation.Yaw = Pawn.Rotation.Yaw;            // Capture the yaw from the Pawn's rotation
    SavedRotation.Roll = 0;                           // Roll isn't used, but needs to be set

    // Convert the position by dividing by 100 for ClientMessage display
    ConvertedLocation.X = SavedLocation.X / 100;
    ConvertedLocation.Y = SavedLocation.Y / 100;
    ConvertedLocation.Z = SavedLocation.Z / 100;

    // Convert the rotation back to degrees (360 degrees from 65536) for ClientMessage display
    PitchDegrees = (float(SavedRotation.Pitch) / 65536.0) * 360.0;
    YawDegrees = (float(SavedRotation.Yaw) / 65536.0) * 360.0;

    // Adjust the pitch to display negative values for below the horizon
    if (PitchDegrees > 180.0)
    {
        PitchDegrees -= 360.0;  // Convert pitches above 180 to negative values
    }

    // Save the move state
    PlayerPawn = TdPawn(Pawn); // Cast PlayerOwner.Pawn to TdPawn
    if (PlayerPawn != None)
    {
        SavedLastJumpLocation = PlayerPawn.LastJumpLocation;  // Save LastJumpLocation
        SavedMoveState = PlayerPawn.MovementState;            // Save the move state
    }

    // Display the saved properties
    ClientMessage("Saved Location: X=" $ ConvertedLocation.X $ ", Y=" $ ConvertedLocation.Y $ ", Z=" $ ConvertedLocation.Z $ 
                  " | Saved Rotation: Pitch=" $ PitchDegrees $ ", Yaw=" $ YawDegrees $ " | Saved Move State: " $ SavedMoveState);

    // Initialise SaveLoadHandler
    if (SaveLoad == None)
    {
        SaveLoad = new class'SaveLoadHandler';
    }

    // Save properties using SaveLoadHandler
    SaveLoad.SaveData("SavedLocation", class'SaveLoadHandler'.static.SerialiseVector(SavedLocation));
    SaveLoad.SaveData("SavedVelocity", class'SaveLoadHandler'.static.SerialiseVector(SavedVelocity));
    SaveLoad.SaveData("SavedRotation", class'SaveLoadHandler'.static.SerialiseRotator(SavedRotation));
    SaveLoad.SaveData("SavedHealth", string(SavedHealth));
    SaveLoad.SaveData("SavedReactionTimeEnergy", string(SavedReactionTimeEnergy));
    SaveLoad.SaveData("SavedReactionTimeState", string(SavedReactionTimeState));

    if (PlayerPawn != None)
    {
        SaveLoad.SaveData("SavedLastJumpLocation", class'SaveLoadHandler'.static.SerialiseVector(SavedLastJumpLocation));
        SaveLoad.SaveData("SavedMoveState", EnumToString(PlayerPawn.MovementState));
    }

    // Confirmation message
    ConsoleCommand("DisplayTrainerHUDMessage Player state saved");
}

// Converts the movement enums into a string representation for the SaveLoadHandler class
static function string EnumToString(EMovement MoveState)
{
    switch (MoveState)
    {
        case MOVE_None:               return "MOVE_None";
        case MOVE_Walking:            return "MOVE_Walking";
        case MOVE_Falling:            return "MOVE_Falling";
        case MOVE_Grabbing:           return "MOVE_Grabbing";
        case MOVE_WallRunningRight:   return "MOVE_WallRunningRight";
        case MOVE_WallRunningLeft:    return "MOVE_WallRunningLeft";
        case MOVE_WallClimbing:       return "MOVE_WallClimbing";
        case MOVE_Walking:            return "MOVE_Jump";
        case MOVE_IntoGrab:           return "MOVE_IntoGrab";
        case MOVE_Crouch:             return "MOVE_Crouch";
        case MOVE_Climb:              return "MOVE_Climb";
        case MOVE_ZipLine:            return "MOVE_ZipLine";
        case MOVE_Balance:            return "MOVE_Balance";
        case MOVE_LedgeWalk:          return "MOVE_LedgeWalk";
        case MOVE_RumpSlide:          return "MOVE_RumpSlide";
        case MOVE_WallRun:            return "MOVE_WallRun";
    }
    return "MOVE_Walking"; // Fallback
}

static function EMovement StringToEMovement(string EnumValue)
{
    EnumValue = Locs(EnumValue); // Convert to lowercase to make it case-insensitive, just incase
    EnumValue = Repl(EnumValue, " ", ""); // Remove spaces just incase

    if (EnumValue == "move_none")              return MOVE_None;
    else if (EnumValue == "move_walking")      return MOVE_Walking;
    else if (EnumValue == "move_falling")      return MOVE_Falling;
    else if (EnumValue == "move_grabbing")      return MOVE_Grabbing;
    else if (EnumValue == "move_wallrunningright") return MOVE_WallRunningRight;
    else if (EnumValue == "move_wallrunningleft")  return MOVE_WallRunningLeft;
    else if (EnumValue == "move_wallclimbing") return MOVE_WallClimbing;
    else if (EnumValue == "move_jump")         return MOVE_Jump;
    else if (EnumValue == "move_intograb")     return MOVE_IntoGrab;
    else if (EnumValue == "move_crouch")       return MOVE_Crouch;
    else if (EnumValue == "move_climb")        return MOVE_Climb;
    else if (EnumValue == "move_zipline")      return MOVE_ZipLine;
    else if (EnumValue == "move_balance")      return MOVE_Balance;
    else if (EnumValue == "move_ledgewalk")    return MOVE_LedgeWalk;
    else if (EnumValue == "move_rumpslide")    return MOVE_RumpSlide;
    else if (EnumValue == "move_wallrun")      return MOVE_WallRun;

    return MOVE_Walking; // Fallback
}

// Teleport back to the saved location and rotation, but pause velocity until the OnRelease function is executed.
exec function TpToSavedLocation()
{
    local vector ConvertedLocation;
    local float PitchDegrees, YawDegrees;
    local TdPlayerController PlayerController;
    local TdPawn PlayerPawn;
    local string SerialisedVector, SerialisedRotator;

    // Reset the timer to 0 immediately upon teleportation
    ConsoleCommand("ResetHUDTimer");

    // Initialise SaveLoadHandler
    if (SaveLoad == None)
    {
        SaveLoad = new class'SaveLoadHandler';
    }

    // Load properties from SaveLoadHandler
    SerialisedVector = SaveLoad.LoadData("SavedLocation");
    if (SerialisedVector != "")
    {
        SavedLocation = class'SaveLoadHandler'.static.DeserialiseVector(SerialisedVector);
    }

    SerialisedVector = SaveLoad.LoadData("SavedVelocity");
    if (SerialisedVector != "")
    {
        SavedVelocity = class'SaveLoadHandler'.static.DeserialiseVector(SerialisedVector);
    }

    SerialisedRotator = SaveLoad.LoadData("SavedRotation");
    if (SerialisedRotator != "")
    {
        SavedRotation = class'SaveLoadHandler'.static.DeserialiseRotator(SerialisedRotator);
    }

    SavedHealth = float(SaveLoad.LoadData("SavedHealth"));
    SavedReactionTimeEnergy = float(SaveLoad.LoadData("SavedReactionTimeEnergy"));
    SavedReactionTimeState = bool(SaveLoad.LoadData("SavedReactionTimeState"));

    SerialisedVector = SaveLoad.LoadData("SavedLastJumpLocation");
    if (SerialisedVector != "")
    {
        SavedLastJumpLocation = class'SaveLoadHandler'.static.DeserialiseVector(SerialisedVector);
    }

    SerialisedVector = SaveLoad.LoadData("SavedMoveState");
    if (SerialisedVector != "")
    {
        SavedMoveState = StringToEMovement(SerialisedVector);
    }

    // If the saved location is valid, teleport back to it
    if (SavedLocation != vect(0, 0, 0))  // Check if there is a saved location
    {
        // Set velocity to zero and change physics mode to "freeze" the player
        Pawn.Velocity = vect(0, 0, 0);          // Stop movement
        Pawn.SetLocation(SavedLocation);        // Fixate player at saved location
        Pawn.Health = SavedHealth;              // Restore saved health

        // Restore ReactionTimeEnergy and bReactionTime if controller is available
        PlayerController = TdPlayerController(Pawn.Controller);
        if (PlayerController != None)
        {
            WorldInfo.Game.SetGameSpeed(1);
            PlayerController.bReactionTime = SavedReactionTimeState;
        }

        // Override UncontrolledFall state if currently active
        if (TdPawn(Pawn).GetStateName() == 'UncontrolledFall')
        {
            TdPawn(Pawn).GotoState('None');  // Exit the UncontrolledFall state
        }

        // Assign PlayerPawn to restore LastJumpLocation and move state
        PlayerPawn = TdPawn(Pawn);
        if (PlayerPawn != None)
        {
            PlayerPawn.StopAllCustomAnimations(0); // Immediately stop animations played before this function was called
            PlayerPawn.LastJumpLocation = SavedLastJumpLocation;  
            if (SavedMoveState == MOVE_Walking || 
                SavedMoveState == MOVE_Falling || 
                SavedMoveState == MOVE_WallRunningRight ||
                SavedMoveState == MOVE_WallRunningLeft || 
                SavedMoveState == MOVE_WallClimbing || 
                SavedMoveState == MOVE_Jump || 
                SavedMoveState == MOVE_IntoGrab || 
                SavedMoveState == MOVE_Crouch ||
                SavedMoveState == MOVE_Climb || 
                SavedMoveState == MOVE_ZipLine || 
                SavedMoveState == MOVE_Balance ||
                SavedMoveState == MOVE_LedgeWalk || 
                SavedMoveState == MOVE_RumpSlide || 
                SavedMoveState == MOVE_WallRun)
            {
                PlayerPawn.SetMove(SavedMoveState);  // Apply the saved move state only for specified moves
            }
            else if (SavedMoveState == MOVE_Grabbing)
            {
                PlayerPawn.SetMove(MOVE_IntoGrab);  // If we saved while grabbing, set the move to IntoGrab. Todo: this doesn't work well
            }
        }

        Pawn.SetPhysics(PHYS_None);  
        ConsoleCommand("set TdPawn bAllowMoveChange False"); 

        // Convert the saved location for display (divide by 100)
        ConvertedLocation.X = SavedLocation.X / 100;
        ConvertedLocation.Y = SavedLocation.Y / 100;
        ConvertedLocation.Z = SavedLocation.Z / 100;

        // Convert the rotation back to degrees (360 degrees from 65536)
        PitchDegrees = (float(SavedRotation.Pitch) / 65536.0) * 360.0;
        YawDegrees = (float(SavedRotation.Yaw) / 65536.0) * 360.0;

        // Adjust the pitch to display negative values for below the horizon
        if (PitchDegrees > 180.0)
        {
            PitchDegrees -= 360.0;  // Convert pitches above 180 to negative values
        }

        // Display the loaded properties
        ClientMessage("Teleported to Saved Location: X=" $ ConvertedLocation.X $ ", Y=" $ ConvertedLocation.Y $ ", Z=" $ ConvertedLocation.Z $ 
                      " | Rotation: Pitch=" $ PitchDegrees $ ", Yaw=" $ YawDegrees $ " | Move State: " $ SavedMoveState);

        // Teleport to the saved location and rotation
        BugItGo(SavedLocation.X, SavedLocation.Y, SavedLocation.Z, SavedRotation.Pitch, SavedRotation.Yaw, 0);  // Roll is always 0
    }
    else
    {
        ClientMessage("No saved location.");
        ConsoleCommand("DisplayTrainerHUDMessage No saved location");
    }
}

// Function to trigger the timer, restore velocity and movement state upon releasing the teleport key bind
exec function TpToSavedLocation_OnRelease()
{
    local TdPlayerController PlayerController;

    // Start the HUD timer only if TimerLocation has been set
    if (TimerLocation != vect(0,0,0))
    {
        ConsoleCommand("StartHUDTimer");
    }

    ConsoleCommand("set TdPawn bAllowMoveChange True");

    // Restore the saved velocity upon release
    if (SavedLocation != vect(0,0,0)) // Ensure there is a saved location
    {
        // Reapply the saved camera rotation to maintain the saved direction
        if (Pawn.Controller != None)
        {
            Pawn.Controller.SetRotation(SavedRotation);  // Use SetRotation to apply the saved camera rotation
        }

        // Apply falling physics or walking based on Z velocity - Todo: this method is a bit dumb but has the least compromises for now. Needs improvement
        if (SavedVelocity.Z != 0)
        {
            Pawn.SetPhysics(PHYS_Falling);  // Apply falling physics if jumping
            Pawn.Velocity = SavedVelocity;
        }
        else
        {
            Pawn.SetPhysics(PHYS_Walking);  // Regular walking mode if no vertical motion
            Pawn.Velocity = SavedVelocity;
        }

        Pawn.Health = SavedHealth;

        // Restore ReactionTimeEnergy and bReactionTime if controller is available
        PlayerController = TdPlayerController(Pawn.Controller);
        if (PlayerController != None)
        {
            PlayerController.ReactionTimeEnergy = SavedReactionTimeEnergy;

            // Ensure bReactionTime matches the saved state by disabling if needed
            if (PlayerController.bReactionTime != SavedReactionTimeState)
            {
                // If reaction time was saved as off, make sure it’s off
                if (!SavedReactionTimeState)
                {
                    WorldInfo.Game.SetGameSpeed(1);
                    PlayerController.bReactionTime = false;
                }
                else
                {
                    // Enable reaction time if it was saved as active
                    PlayerController.bReactionTime = true;
                }
            }
        }
    }
    else
    {
        return;
    }
}

// Teleport to surface player is looking at
exec function TpToSurface()
{
    local Actor HitActor;
    local vector HitNormal, HitLocation, ConvertedLocation;
    local vector ViewLocation;
    local rotator ViewRotation;
    local TdPawn PlayerPawn;

    PlayerPawn = TdPawn(Pawn);  // Ensure we have the player pawn reference

    // Get the player's current view location and rotation (where the player is looking)
    GetPlayerViewPoint(ViewLocation, ViewRotation);

    // Perform a trace to find the surface the player is looking at, casting a long line from the viewpoint
    HitActor = Trace(HitLocation, HitNormal, ViewLocation + 1000000 * vector(ViewRotation), ViewLocation, true);

    // If we hit something (e.g., a wall, floor, or object)
    if (HitActor != None)
    {
        // Override UncontrolledFall state if currently active
        if (TdPawn(Pawn).GetStateName() == 'UncontrolledFall')
        {
            TdPawn(Pawn).GotoState('None');  // Exit the UncontrolledFall state
        }

        PlayerPawn.StopAllCustomAnimations(0); // Immediately stop animations played before this function was called

        // Start monitoring fall state to dynamically set fall height
        if (PlayerPawn != None)
        {
            // Handle fall height reset
            ConsoleCommand("set TdMove_Landing HardLandingHeight 9999999");
            ConsoleCommand("set TdPawn FallingUncontrolledHeight 9999999");
            bMonitorFallHeight = true;
            EnsureHelperProxy();
        }

        // Adjust the hit location slightly to avoid embedding the player into the surface
        HitLocation += HitNormal * 4.0;

        // Teleport the player to the hit location
        ViewTarget.SetLocation(HitLocation);

        // Convert the hit location to be ClientMessage friendly
        ConvertedLocation.X = HitLocation.X / 100;
        ConvertedLocation.Y = HitLocation.Y / 100;
        ConvertedLocation.Z = HitLocation.Z / 100;

        ClientMessage("Teleported to surface at: X=" $ ConvertedLocation.X $ ", Y=" $ ConvertedLocation.Y $ ", Z=" $ ConvertedLocation.Z);
    }
    else
    {
        ClientMessage("Not looking at surface (or surface lacks collision) - cannot teleport.");
        ConsoleCommand("DisplayTrainerHUDMessage Not looking at surface (or surface lacks collision) - cannot teleport");
    }
}

// Set the location for the trainer HUD timer
exec function SaveTimerLocation()
{
    TimerLocation = Pawn.Location;

    // Use ConsoleCommand to pass the target location to the HUD
    ConsoleCommand("SetHUDTimerLocation " $ TimerLocation.X $ " " $ TimerLocation.Y $ " " $ TimerLocation.Z);

    // Reset the timer and pause it
    ConsoleCommand("ResetHUDTimer");

    ClientMessage("Timer location set: X=" $ (TimerLocation.X / 100) $ ", Y=" $ (TimerLocation.Y / 100) $ ", Z=" $ (TimerLocation.Z / 100));

    ConsoleCommand("DisplayTrainerHUDMessage Timer location set");
}

// Sets the Z component of the LastJumpLocation variable. Todo: see if setting the entire vector behaves any differently for flings, as is the game's default behaviour
exec function LastJumpLocation(float NewZValueInMeters)
{
    local TdPawn PlayerPawn;
    PlayerPawn = TdPawn(Pawn);  // Cast PlayerOwner.Pawn to TdPawn

    if (PlayerPawn != None)
    {
        // Convert the specified Z value from meters to Unreal units by multiplying by 100
        PlayerPawn.LastJumpLocation.Z = NewZValueInMeters * 100;

        ClientMessage("Last Jump Location Z set to: " $ NewZValueInMeters);
    }
    else
    {
        ClientMessage("Failed to set Last Jump Location: PlayerPawn is None.");
    }
}

// Set jump height
exec function JumpHeight(float JumpHeight)
{
    local string PropertyName;
    local string Command;
    local string TargetClass;

    PropertyName = "BaseJumpZ";
    TargetClass = "TdMove_Jump";

    // Construct the "set" console command
    Command = "set " $ TargetClass $ " " $ PropertyName $ " " $ string(JumpHeight);

    // Execute the command
    ConsoleCommand(Command);
}

// Set jump speed
exec function JumpSpeed(float JumpSpeed)
{
    local string PropertyName;
    local string Command;
    local string TargetClass;

    PropertyName = "JumpAddXY";
    TargetClass = "TdMove_Jump";

    // Construct the "set" console command
    Command = "set " $ TargetClass $ " " $ PropertyName $ " " $ string(JumpSpeed);

    // Execute the command
    ConsoleCommand(Command);
}

// Set speed cap in air
exec function SpeedCap(float SpeedCap)
{
    local string PropertyName;
    local string Command;
    local string TargetClass;

    PropertyName = "TerminalVelocity";
    TargetClass = "PhysicsVolume";

    // Construct the "set" console command
    Command = "set " $ TargetClass $ " " $ PropertyName $ " " $ string(SpeedCap);

    // Execute the command
    ConsoleCommand(Command);
}

// Set hard landing height
exec function RollHeight(float RollHeight)
{
    local string PropertyName;
    local string Command;
    local string TargetClass;

    PropertyName = "HardLandingHeight";
    TargetClass = "TdMove_Landing";

    // Construct the "set" console command
    Command = "set " $ TargetClass $ " " $ PropertyName $ " " $ string(RollHeight);

    // Execute the command
    ConsoleCommand(Command);
}

// Set death height
exec function DeathHeight(float DeathHeight)
{
    local string PropertyName;
    local string Command;
    local string TargetClass;

    PropertyName = "FallingUncontrolledHeight";
    TargetClass = "TdPawn";

    // Construct the "set" console command
    Command = "set " $ TargetClass $ " " $ PropertyName $ " " $ string(DeathHeight);

    // Execute the command
    ConsoleCommand(Command);
}

// Set gravity multiplier
exec function Gravity(float GravityMultiplier)
{
    local string PropertyName;
    local string Command;
    local string TargetClass;

    PropertyName = "GravityModifier";
    TargetClass = "TdPawn";

    // Construct the "set" console command
    Command = "set " $ TargetClass $ " " $ PropertyName $ " " $ string(GravityMultiplier);

    // Execute the command
    ConsoleCommand(Command);
}

// Set game speed multiplier
exec function GameSpeed(float SpeedMultiplier)
{
    local string PropertyName;
    local string Command;
    local string TargetClass;

    PropertyName = "TimeDilation";
    TargetClass = "WorldInfo";

    // Construct the "set" console command
    Command = "set " $ TargetClass $ " " $ PropertyName $ " " $ string(SpeedMultiplier);

    // Execute the command
    ConsoleCommand(Command);
}

// Sets FPS in a friendlier way
exec function MaxFPS(int FPS)
{
    local string FPSCapValuePropertyName;
    local string FPSCapStatusPropertyName;
    local string Command;
    local string TargetClass;

    FPSCapValuePropertyName = "MaxSmoothedFrameRate";
    FPSCapStatusPropertyName = "bSmoothFrameRate";
    TargetClass = "GameEngine";

    if (FPS > 0)
    {
        Command = "set " $ TargetClass $ " " $ FPSCapStatusPropertyName $ " True";
        ConsoleCommand(Command);

        Command = "set " $ TargetClass $ " " $ FPSCapValuePropertyName $ " " $ string(FPS);
        ConsoleCommand(Command);
        ClientMessage("Max FPS limit set to " $ FPS $ ".");
    }
    else
    {
        Command = "set " $ TargetClass $ " " $ FPSCapStatusPropertyName $ " False";
        ConsoleCommand(Command);
        ClientMessage("Max FPS limit removed.");
    }
}

// Sets "ultra" graphics. Todo: see if we can set these variables directly rather than relying on the "set" command
exec function UltraGraphics()
{
    ConsoleCommand("set DecalComponent bStaticDecal 0");
    ConsoleCommand("set DecalComponent bNeverCull 1");
    ConsoleCommand("set StaticMeshComponent ForcedLODModel 1");
    ConsoleCommand("set SkeletalMeshComponent ForcedLODModel 1");
    ConsoleCommand("set PrimitiveComponent CullDistance 0");
    ClientMessage("Ultra graphics enabled.");
}

// Freezes time and hides crosshair - this too is stolen from UE3 source
exec function FreezeFrame(float delay)
{
	WorldInfo.Game.SetPause(Outer,Outer.CanUnpause);
	WorldInfo.PauseDelay = WorldInfo.TimeSeconds + delay;
}

// Level streaming handler
function SetLevelStreamingStatus(name PackageName, bool bShouldBeLoaded, bool bShouldBeVisible)
{
	local PlayerController PC;
	local int i;

	if (PackageName != 'All')
	{
		foreach WorldInfo.AllControllers(class'PlayerController', PC)
		{
			PC.ClientUpdateLevelStreamingStatus(PackageName, bShouldBeLoaded, bShouldBeVisible, FALSE );
		}
	}
	else
	{
		foreach WorldInfo.AllControllers(class'PlayerController', PC)
		{
			for (i = 0; i < WorldInfo.StreamingLevels.length; i++)
			{
				PC.ClientUpdateLevelStreamingStatus(WorldInfo.StreamingLevels[i].PackageName, bShouldBeLoaded, bShouldBeVisible, FALSE );
			}
		}
	}
}

// Load level and make visible
exec function StreamLevelIn(name PackageName)
{
	SetLevelStreamingStatus(PackageName, true, true);
}

// Load level only
exec function OnlyLoadLevel(name PackageName)
{
	SetLevelStreamingStatus(PackageName, true, false);
}

// Unload level
exec function StreamLevelOut(name PackageName)
{
	SetLevelStreamingStatus(PackageName, false, false);
}

// Core GiveWeapon function with dynamic weapon class loading
exec function Weapon GiveWeapon(String WeaponClassStr)
{
    local Weapon Weap;
    local class<Weapon> WeaponClass;

    // Dynamically load the class for the specified weapon
    WeaponClass = class<Weapon>(DynamicLoadObject(WeaponClassStr, class'Class'));

    // Check if the player already has the weapon in their inventory
    Weap = Weapon(Pawn.FindInventoryType(WeaponClass));

    if (Weap != None)
    {
        // If the weapon is already in the player's inventory, return it
        return Weap;
    }

    // If the weapon is not in the inventory, create it and return the created weapon
    return Weapon(Pawn.CreateInventory(WeaponClass));
}

// Predefined GiveWeapon functions for specific weapons
exec function Weapon G36C()
{
    return GiveWeapon("TdSharedContent.TdWeapon_AssaultRifle_HKG36");
}

exec function Weapon MP5K()
{
    return GiveWeapon("TdSharedContent.TdWeapon_AssaultRifle_MP5K");
}

exec function Weapon Neostead()
{
    return GiveWeapon("TdSharedContent.TdWeapon_Shotgun_Neostead");
}

exec function Weapon M93R()
{
    return GiveWeapon("TdSharedContent.TdWeapon_Pistol_BerettaM93R");
}

exec function Weapon SCARL()
{
    return GiveWeapon("TdSharedContent.TdWeapon_AssaultRifle_FNSCARL");
}

exec function Weapon FNMinimi()
{
    return GiveWeapon("TdSharedContent.TdWeapon_Machinegun_FNMinimi");
}

exec function Weapon M1911()
{
    return GiveWeapon("TdSharedContent.TdWeapon_Pistol_Colt1911");
}

exec function Weapon Glock()
{
    return GiveWeapon("TdSharedContent.TdWeapon_Pistol_Glock18c");
}

exec function Weapon M870()
{
    return GiveWeapon("TdSharedContent.TdWeapon_Shotgun_Remington870");
}

exec function Weapon SteyrTMP()
{
    return GiveWeapon("TdSharedContent.TdWeapon_SMG_SteyrTMP");
}

exec function Weapon M95()
{
    return GiveWeapon("TdSharedContent.TdWeapon_Sniper_BarretM95");
}

exec function Weapon Taser()
{
    return GiveWeapon("TdSharedContent.TdWeapon_Pistol_TaserContent");
}

exec function Weapon AltTaser()
{
    return GiveWeapon("TdGame.TdWeapon_Pistol_Taser");
}

exec function Weapon DE05()
{
    return GiveWeapon("TdSharedContent.TdWeapon_Pistol_DE05");
}

exec function Weapon Bag()
{
    return GiveWeapon("TdMpContent.TdWeapon_Bag");
}

exec function Weapon SmokeGrenade()
{
    return GiveWeapon("TdSharedContent.TdWeapon_SmokeGrenade");
}

exec function Weapon FlashbangGrenade()
{
    return GiveWeapon("TdSharedContent.TdWeapon_FlashbangGrenade");
}

// Custom version of setbind that handles null keys a bit better
exec function Bind(string Key, string Command)
{
    local int i;
    local PlayerInput Input;

    // Directly access the PlayerInput from Outer without casting
    Input = Outer.PlayerInput;

    if (Input != None)
    {
        // Check if the Command is "null" or empty to clear the key binding
        if (Len(Command) == 0 || Command == "null")
        {
            Input.SetBind(name(Key), "");  // Clear the key binding
            ClientMessage("Key " $ Key $ " binding cleared.");
        }
        else
        {
            // Unbind any other keys bound to this command
            for (i = 0; i < Input.Bindings.Length; i++)
            {
                if (Input.Bindings[i].Command == Command)
                {
                    Input.SetBind(Input.Bindings[i].Name, "");  // Clear the existing bind for the same command
                }
            }
            // Set the new key binding
            Input.SetBind(name(Key), Command);
            ClientMessage("Key " $ Key $ " bound to command: " $ Command);
        }
    }
    else
    {
        ClientMessage("Failed to bind key: PlayerInput not found.");
    }
}

// Spam macros (see Todo in MirrorsEdgeMacro class)
exec function JumpMacro()
{
    if (!bJumpMacroActive)
    {
        EnsureHelperProxy();
        bJumpMacroActive = true;
        HelperProxy.LoopFunction(0.002, "MacroJump"); // Start looping at a rate of 2ms
        ConsoleCommand("set UIScene bFlushPlayerInput 0");
        ConsoleCommand("StartMacroTimer Jump");
    }
}

exec function JumpMacro_OnRelease()
{
    if (bJumpMacroActive)
    {
        if (HelperProxy != None)
        {
            HelperProxy.StopTimer();
        }
        bJumpMacroActive = false;
        ConsoleCommand("ResetMacroTimer");
        ConsoleCommand("DisplayTrainerHUDMessage Macro stopped");
    }
}

exec function InteractMacro()
{
    if (!bInteractMacroActive)
    {
        EnsureHelperProxy();
        bInteractMacroActive = true;
        HelperProxy.LoopFunction(0.002, "MacroInteract");
        ConsoleCommand("set UIScene bFlushPlayerInput 0");
        ConsoleCommand("StartMacroTimer Interact");
    }
}

exec function InteractMacro_OnRelease()
{
    if (bInteractMacroActive)
    {
        if (HelperProxy != None)
        {
            HelperProxy.StopTimer();
        }
        bInteractMacroActive = false;
        ConsoleCommand("ResetMacroTimer");
        ConsoleCommand("DisplayTrainerHUDMessage Macro stopped");
    }
}

exec function GrabMacro()
{
    if (!bGrabMacroActive)
    {
        EnsureHelperProxy();
        bGrabMacroActive = true;
        HelperProxy.LoopFunction(0.002, "MacroGrab");
        ConsoleCommand("set UIScene bFlushPlayerInput 0");
        ConsoleCommand("StartMacroTimer Grab");
    }
}

exec function GrabMacro_OnRelease()
{
    if (bGrabMacroActive)
    {
        if (HelperProxy != None)
        {
            HelperProxy.StopTimer();
        }
        bGrabMacroActive = false;
        ConsoleCommand("ResetMacroTimer");
        ConsoleCommand("DisplayTrainerHUDMessage Macro stopped");
    }
}

// Internal functions to simulate the actions of each macro
exec function MacroJump()
{
    ConsoleCommand("Jump");
    ConsoleCommand("StopJump | Axis aUp Speed=1.0  AbsoluteAxis=100 | PrevStaticViewTarget");
}

exec function MacroInteract()
{
    ConsoleCommand("UsePress");
    ConsoleCommand("UseRelease");
}

exec function MacroGrab()
{
    ConsoleCommand("PressedSwitchWeapon");
    ConsoleCommand("ReleasedSwitchWeapon");
}

function float GetReactionTimeEnergy()
{
    local TdPlayerController PlayerController;

    PlayerController = TdPlayerController(Pawn.Controller);
    if (PlayerController != None)
    {
        return PlayerController.ReactionTimeEnergy;
    }
    return 0;  // Return a distinct value if unavailable
}

function bool GetReactionTimeState()
{
    local TdPlayerController PlayerController;

    PlayerController = TdPlayerController(Pawn.Controller);
    if (PlayerController != None)
    {
        return PlayerController.bReactionTime;
    }
    return false;  // Default to false if unavailable
}

// Sets resolution AND fixes UI. Todo: see if we can reference the GetPossibleScreenResolutions function to filter out invalid resolutions
exec function Resolution(int Width, int Height, optional string Windowed)
{
    local float ScalingFactor;
    local int RestestValue;
    local float AspectRatio;
    local string ResolutionCommand;
    local string UIStyleCommand;

    AspectRatio = float(Width) / float(Height);

    // Check if UI needs to be corrected, we only care once the horizontal resolution exceeds 1920 as this is when blurry UI occurs
    if (Width > 1920)
    {
        // Adjust UI for any aspect ratio - note that this does NOT adjust the aspect ratio itself, and I'm not sure if we can override
        // ConstrainedAspectRatio mid-game as DICE has hardcoded it to revert to 16:9 (or what Tweaks has set it to) every tick
        RestestValue = int(float(Height) * (AspectRatio / (16.0 / 9.0)) + 0.5);
        ScalingFactor = float(Height) / 1080.0;
    }
    else
    {
        RestestValue = 1080;
        ScalingFactor = 1.0;
    }

    ResolutionCommand = "setres " $ string(Width) $ "x" $ string(Height) $ "x32f";
    if (Windowed != "")
    {
        ResolutionCommand = "setres " $ string(Width) $ "x" $ string(Height) $ "x32w";
    }
    ConsoleCommand(ResolutionCommand);

    ConsoleCommand("set MultiFont ResolutionTestTable (480,720," $ string(RestestValue) $ ")");

    // Update UI scaling dynamically - this handles the majority of UI fine but certain text that is NOT drawn
    // through UIStyle won't be scaled and will grow smaller the larger the resolution (time trial timer etc.)
    // I really don't know if there's a way to account for all text, Tweaks deals with the same problem
    UIStyleCommand = "set UIStyle_Text Scale (X=" $ string(ScalingFactor) $ ",Y=" $ string(ScalingFactor) $ ")";
    ConsoleCommand(UIStyleCommand);

    ConsoleCommand("RestartLevel");

    ClientMessage("Resolution set to " $ string(Width) $ "x" $ string(Height) $ " and corrected blurry UI");
}

// Persistent ColorScale
exec function ColorScaling(float Red, float Green, float Blue)
{
    local string ColorScaleString;

    ColorScaleString = "(X=" $ Red $ ",Y=" $ Green $ ",Z=" $ Blue $ ")";

    ConsoleCommand("set Camera ColorScale " $ ColorScaleString);

    ConsoleCommand("set WorldInfo DefaultColorScale " $ ColorScaleString);
}

// Special function for setting the struct variables of basic post proccess settings. Can use this as a reference for
// other classes that also use struct variables instead of regular variables
// Todo: see if it can be made persistent. Also, adding support Mirror's Edge specific settings (sun haze/glow, curves???)
exec function PostProcess(string PropertyName, float X, optional float Y, optional float Z)
{
    local PostProcessVolume PPVolume;
    local PlayerController PC;
    local WorldInfo WI;
    local bool bIsPropertyRecognised;
    local bool bIsVectorProperty;
    local vector VecValue;

    // Determine if this property is vector-based
    if (PropertyName == "Highlights" || // Note - highlights act the same as ColorScale
        PropertyName == "highlights" || 
        PropertyName == "Midtones" ||
        PropertyName == "midtones" ||
        PropertyName == "Shadows" ||
        PropertyName == "shadows")
    {
        bIsVectorProperty = true;
    }

    // If it's a vector property, interpret X Y Z as the vector components
    if (bIsVectorProperty)
    {
        VecValue.X = X;
        VecValue.Y = Y;
        VecValue.Z = Z;
    }

    PC = Outer;
    if (PC == None)
    {
        ClientMessage("Error: Could not access PlayerController from Outer.");
        return;
    }

    WI = PC.WorldInfo;
    if (WI == None)
    {
        ClientMessage("Error: Could not access WorldInfo.");
        return;
    }

    // Apply settings to all PostProcessVolumes (usually in door areas)
    foreach AllActors(class'PostProcessVolume', PPVolume)
    {
        if (!bIsVectorProperty)
        {
            if (PropertyName == "Saturation" || PropertyName == "saturation")
            {
                PPVolume.Settings.Scene_Desaturation = -X;
                bIsPropertyRecognised = true;
            }
            else if (PropertyName == "sceneinterpolation")
            {
                PPVolume.Settings.Scene_InterpolationDuration = X;
                bIsPropertyRecognised = true;
            }
        }
        else
        {
            if (PropertyName == "Highlights" || PropertyName == "highlights")
            {
                PPVolume.Settings.Scene_HighLights = VecValue;
                bIsPropertyRecognised = true;
            }
            else if (PropertyName == "Midtones" || PropertyName == "midtones")
            {
                PPVolume.Settings.Scene_MidTones = VecValue;
                bIsPropertyRecognised = true;
            }
            else if (PropertyName == "Shadows" || PropertyName == "shadows")
            {
                PPVolume.Settings.Scene_Shadows = VecValue;
                bIsPropertyRecognised = true;
            }
        }
    }

    // Apply changes to WorldInfo global settings (usually outdoors)
    if (!bIsVectorProperty)
    {
        if (PropertyName == "Saturation" || PropertyName == "saturation")
        {
            WI.DefaultPostProcessSettings.Scene_Desaturation = -X;
            bIsPropertyRecognised = true;
        }
        else if (PropertyName == "sceneinterpolation")
        {
            WI.DefaultPostProcessSettings.Scene_InterpolationDuration = X;
            bIsPropertyRecognised = true;
        }
    }
    else
    {
        if (PropertyName == "Highlights" || PropertyName == "highlights")
        {
            WI.DefaultPostProcessSettings.Scene_HighLights = VecValue;
            bIsPropertyRecognised = true;
        }
        else if (PropertyName == "Midtones" || PropertyName == "midtones")
        {
            WI.DefaultPostProcessSettings.Scene_MidTones = VecValue;
            bIsPropertyRecognised = true;
        }
        else if (PropertyName == "Shadows" || PropertyName == "shadows")
        {
            WI.DefaultPostProcessSettings.Scene_Shadows = VecValue;
            bIsPropertyRecognised = true;
        }
    }

    if (bIsPropertyRecognised)
    {
        if (bIsVectorProperty)
        {
            ClientMessage("Applied " $ PropertyName $ " = (" $ string(X) $ ", " $ string(Y) $ ", " $ string(Z) $ ") to both PostProcessVolumes and WorldInfo.");
        }
        else
        {
            ClientMessage("Applied " $ PropertyName $ " = " $ string(X) $ " to both PostProcessVolumes and WorldInfo.");
        }
    }
    else
    {
        ClientMessage("Property not recognised: " $ PropertyName);
    }
}


// Ensures the helper proxy for the extended Actor class is initialised
function EnsureHelperProxy()
{
    if (HelperProxy == None || HelperProxy.Pawn != TdPawn(Pawn)) // Check if proxy is missing or outdated
    {
        if (HelperProxy != None)
        {
            HelperProxy.Destroy();
        }

        HelperProxy = WorldInfo.Spawn(class'CheatHelperProxy');
        HelperProxy.CheatManagerReference = self; // Reference to the cheat manager
        HelperProxy.Pawn = TdPawn(Pawn); // Explicitly cast Pawn to TdPawn
    }
}

exec function StartTimer(float Duration, bool bLoop)
{
    EnsureHelperProxy();
    HelperProxy.StartTimer(Duration, bLoop);
    ClientMessage("Timer started: Duration = " $ Duration $ " seconds, Loop = " $ bLoop);
}

exec function StopTimer()
{
    if (HelperProxy != None)
    {
        HelperProxy.StopTimer();
        ClientMessage("Timer stopped.");
    }
    else
    {
        ClientMessage("Helper proxy is not active.");
    }
}

exec function StartDelayedFunction(float Delay, string Command)
{
    EnsureHelperProxy();
    HelperProxy.DelayedFunction(Delay, Command);
    ClientMessage("Delayed function started: " $ Command $ " after " $ Delay $ " seconds.");
}

exec function StartLoopFunction(float Interval, string Command)
{
    EnsureHelperProxy();
    HelperProxy.LoopFunction(Interval, Command);
    ClientMessage("Loop function '" $ Command $ "' started with interval = " $ Interval $ " seconds.");
}



function OnTick(float DeltaTime)
{
    local float norm, remapped, globalEffectiveTime;
    local float cumulative, local_t;
    local int segIndex, i;
    local vector newPos, P0, P1, P2, P3;
    local TdPawn PlayerPawn;
    local TdPlayerCamera PlayerCam;
    local float rP0, rP1, rP2, rP3, newPitch, newYaw, newRoll;
    local float fP0, fP1, fP2, fP3, newFOV;

    if (bMonitorFallHeight)
    {
        FallHeightMonitoring();
    }

    if (bMonitorNoclip)
    {
        NoclipMonitoring();
    }

    if (bMonitorDolly)
    {
        DollyMonitoring();
    }

    if (!bIsDollyActive)
        return;

    PlayerPawn = TdPawn(Pawn);
    if (PlayerPawn == none)
        return;

    PlayerCam = TdPlayerCamera(PlayerCamera);
    if (PlayerCam == none)
        return;

    GlobalElapsedTime += DeltaTime;

    if (GlobalElapsedTime >= GlobalDollyDuration)
    {
        PlayerCam.FreeFlightPosition = Keyframes[Keyframes.Length - 1].Position;
        PlayerCam.FreeFlightRotation = Keyframes[Keyframes.Length - 1].Rotation;
        PlayerCam.DefaultFOV = Keyframes[Keyframes.Length - 1].FOV;
        bIsDollyActive = false;
        bIsPlayingDolly = false;
        ConsoleCommand("toggleui");
        ClientMessage("Dolly playback complete.");
        UpdateDollyDebug();
        return;
    }

    norm = GlobalElapsedTime / GlobalDollyDuration;
    remapped = SmootherStep(norm);
    globalEffectiveTime = remapped * GlobalDollyDuration;

    cumulative = 0;
    segIndex = 0;
    for (i = 0; i < Keyframes.Length; i++)
    {
        if (globalEffectiveTime < cumulative + Keyframes[i].Duration)
        {
            segIndex = i;
            break;
        }
        cumulative += Keyframes[i].Duration;
    }

    local_t = (globalEffectiveTime - cumulative) / Keyframes[segIndex].Duration;

    // Position interpolation
    P0 = (segIndex == 0) ? DollyStartPos : Keyframes[Max(segIndex - 1, 0)].Position;
    P1 = Keyframes[Max(segIndex, 0)].Position;
    P2 = Keyframes[Min(segIndex + 1, Keyframes.Length - 1)].Position;
    P3 = Keyframes[Min(segIndex + 2, Keyframes.Length - 1)].Position;
    newPos = BSplineVector(P0, P1, P2, P3, local_t);

    // Pitch
    rP0 = (segIndex == 0) ? DollyStartRot.Pitch : Keyframes[Max(segIndex - 1, 0)].Rotation.Pitch;
    rP1 = Keyframes[Max(segIndex, 0)].Rotation.Pitch;
    rP2 = Keyframes[Min(segIndex + 1, Keyframes.Length - 1)].Rotation.Pitch;
    rP3 = Keyframes[Min(segIndex + 2, Keyframes.Length - 1)].Rotation.Pitch;
    newPitch = BSplineFloat(rP0, rP1, rP2, rP3, local_t);

    // Yaw
    rP0 = (segIndex == 0) ? DollyStartRot.Yaw : Keyframes[Max(segIndex - 1, 0)].Rotation.Yaw;
    rP1 = Keyframes[Max(segIndex, 0)].Rotation.Yaw;
    rP2 = Keyframes[Min(segIndex + 1, Keyframes.Length - 1)].Rotation.Yaw;
    rP3 = Keyframes[Min(segIndex + 2, Keyframes.Length - 1)].Rotation.Yaw;
    newYaw = BSplineFloat(rP0, rP1, rP2, rP3, local_t);

    // Roll
    rP0 = (segIndex == 0) ? DollyStartRot.Roll : Keyframes[Max(segIndex - 1, 0)].Rotation.Roll;
    rP1 = Keyframes[Max(segIndex, 0)].Rotation.Roll;
    rP2 = Keyframes[Min(segIndex + 1, Keyframes.Length - 1)].Rotation.Roll;
    rP3 = Keyframes[Min(segIndex + 2, Keyframes.Length - 1)].Rotation.Roll;
    newRoll = BSplineFloat(rP0, rP1, rP2, rP3, local_t);

    // FOV
    fP0 = (segIndex == 0) ? DollyStartFOV : Keyframes[Max(segIndex - 1, 0)].FOV;
    fP1 = Keyframes[Max(segIndex, 0)].FOV;
    fP2 = Keyframes[Min(segIndex + 1, Keyframes.Length - 1)].FOV;
    fP3 = Keyframes[Min(segIndex + 2, Keyframes.Length - 1)].FOV;
    newFOV = BSplineFloat(fP0, fP1, fP2, fP3, local_t);

    // Apply the interpolated values
    PlayerCam.FreeFlightPosition = newPos;
    PlayerCam.FreeFlightRotation.Pitch = newPitch;
    PlayerCam.FreeFlightRotation.Yaw = newYaw;
    PlayerCam.FreeFlightRotation.Roll = newRoll;
    PlayerCam.DefaultFOV = newFOV;
}

function OnTimerStart(float Duration, bool bLoop)
{
    // Optional - Handle timer start event
    // ClientMessage("Timer started: Duration = " $ Duration $ " seconds, Loop = " $ bLoop);
}

function OnTimerStop()
{
    // Optional - Handle timer stop event
    // ClientMessage("Timer stopped.");
}

function OnDelayStart(string FunctionName)
{
    // Optional - Handle delayed function start
    // ClientMessage("Delayed function '" $ FunctionName $ "' started.");
}

function OnLoopStart(string FunctionName)
{
    // Optional - Handle loop start
    // ClientMessage("Loop function '" $ FunctionName $ "' started.");
}

function ExecuteCommand(string Command)
{
    // Use ConsoleCommand to dynamically invoke exec functions or native commands
    ConsoleCommand(Command);
}

exec function testmesh()
{
    local TdPawn PlayerPawn;

    PlayerPawn = TdPawn(Pawn);

    PlayerPawn.SetFirstPerson(false);
    PlayerPawn.Mesh.ForceSkelUpdate();  
}


// Dolly camera interpolation functions
function vector BSplineVector(vector P0, vector P1, vector P2, vector P3, float t)
{
    local float t2, t3;
    t2 = t * t;
    t3 = t2 * t;

    return ( (1.0 / 6.0) * ((-t3 + 3 * t2 - 3 * t + 1) * P0 +
                            (3 * t3 - 6 * t2 + 4) * P1 +
                            (-3 * t3 + 3 * t2 + 3 * t + 1) * P2 +
                            (t3) * P3) );
}

function float BSplineFloat(float P0, float P1, float P2, float P3, float t)
{
    local float t2, t3;
    t2 = t * t;
    t3 = t2 * t;

    return ( (1.0 / 6.0) * ((-t3 + 3 * t2 - 3 * t + 1) * P0 +
                            (3 * t3 - 6 * t2 + 4) * P1 +
                            (-3 * t3 + 3 * t2 + 3 * t + 1) * P2 +
                            (t3) * P3) );
}

// SmootherStep: a quintic easing function that maps a normalized value (0–1)
// so that the overall dolly motion eases in at the start and eases out at the end
function float SmootherStep(float t)
{
    if(t < 0.0)
        t = 0.0;
    if(t > 1.0)
        t = 1.0;
    return t * t * t * (t * (6 * t - 15) + 10);
}

function DollyMonitoring()
{
    local TdPlayerController PC;
    local TdPlayerCamera PlayerCam;

    PC = TdPlayerController(Pawn.Controller);
    PlayerCam = TdPlayerCamera(PlayerCamera);

    if (PC != None && PC.PlayerInput != None)
    {
        if (PC.PlayerInput.PressedKeys.Find('E') != -1)
        {
            if (PlayerCam.FreeflightScale <= 5)
            {
                PlayerCam.FreeflightScale += 0.05;
            }
        }

        if (PC.PlayerInput.PressedKeys.Find('Q') != -1)
        {
            if (PlayerCam.FreeflightScale >= 0.1)
            {
                PlayerCam.FreeflightScale -= 0.05;
            }
        }

        if (PC.PlayerInput.PressedKeys.Find('Up') != -1)
        {
            if (PlayerCam.DefaultFOV <= 179)
            {
                PlayerCam.DefaultFOV += 0.5;
            }
        }

        if (PC.PlayerInput.PressedKeys.Find('Down') != -1)
        {
            if (PlayerCam.DefaultFOV >= 1)
            {
                PlayerCam.DefaultFOV -= 0.5;
            }
        }

        if (PC.PlayerInput.PressedKeys.Find('Left') != -1)
        {
            PlayerCam.FreeFlightRotation.Roll -= 100;
        }

        if (PC.PlayerInput.PressedKeys.Find('Right') != -1)
        {
            PlayerCam.FreeFlightRotation.Roll += 100;
        }
    }
}

exec function DollyStart()
{
    local TdPawn PlayerPawn;
    local TdPlayerCamera PlayerCam;

    FlushPersistentDebugLines();
    Keyframes.Length = 0;

    EnsureHelperProxy();

    PlayerPawn = TdPawn(Pawn);
    if (PlayerPawn == none)
    {
        ClientMessage("Player pawn not found.");
        return;
    }

    PlayerCam = TdPlayerCamera(PlayerCamera);
    if (PlayerCam == none)
    {
        ClientMessage("Failed to get TdPlayerCamera.");
        return;
    }

    SetCameraMode('FreeFlight');
    ConsoleCommand("set DOFAndBloomEffect bShowInGame true"); // Freeflight mode disables these effects by default
    PlayerCam.FreeFlightPosition = Pawn.Location;
    PlayerCam.FreeFlightRotation = Pawn.Rotation;
    PlayerPawn.SetIgnoreMoveInput();
    PlayerPawn.SetIgnoreLookInput();
    PlayerPawn.bAllowMoveChange = false;
    PlayerPawn.SetFirstPerson(false);
    PlayerPawn.Mesh.ForceSkelUpdate();

    bMonitorDolly = true;

    ClientMessage("Dolly camera started. Type \"DollyHelp\" for all dolly functions.");
}

exec function DollyStop()
{
    local TdPawn PlayerPawn;

    FlushPersistentDebugLines();
    Keyframes.Length = 0;

    // Get the player pawn.
    PlayerPawn = TdPawn(Pawn);
    if (PlayerPawn == none)
    {
        ClientMessage("Player pawn not found.");
        return;
    }

    SetCameraMode('FirstPerson'); 
    PlayerPawn.StopIgnoreMoveInput();
    PlayerPawn.StopIgnoreLookInput();
    PlayerPawn.SetFirstPerson(true);
    PlayerPawn.bAllowMoveChange = true;

    bMonitorDolly = false;
    
    ClientMessage("Dolly camera mode stopped - all keyframes have been cleared.");
}

exec function DollyAdd(float Duration)
{
    local TdPawn PlayerPawn;
    local TdPlayerCamera PlayerCam;
    local DollyKeyframe NewKey;
    local vector shiftedPos;
    local DollyKeyframe InitKey;
    local int trueKeyframeNumber;
    local float pitchDeg, yawDeg, rollDeg;

    if (Duration <= 0.0)
    {
        ClientMessage("Duration must be greater than 0.");
        return;
    }

    PlayerPawn = TdPawn(Pawn);
    if (PlayerPawn == none)
    {
        ClientMessage("Player pawn not found.");
        return;
    }
    
    PlayerCam = TdPlayerCamera(PlayerCamera);
    if (PlayerCam == none)
    {
        ClientMessage("Failed to get TdPlayerCamera.");
        return;
    }
    
    // If no keyframes exist, automatically add a dummy initial keyframe with duration 0.
    // (this is a workaround to stop the starting keyframe being offset too much due to b-spline math. fix this later)
    if (Keyframes.Length == 0)
    {
        InitKey.Position = PlayerCam.FreeFlightPosition;
        InitKey.Rotation = PlayerCam.FreeFlightRotation;
        InitKey.Duration = 0;
        InitKey.FOV = PlayerCam.DefaultFOV;
        Keyframes.AddItem(InitKey);
    }
    
    // Shift the user's true keyframe position so it doesn't overlap the dummy.
    shiftedPos = PlayerCam.FreeFlightPosition + vect(1, 0, 0);
    
    NewKey.Position = shiftedPos;
    NewKey.Rotation = PlayerCam.FreeFlightRotation;
    NewKey.Duration = Duration;
    NewKey.FOV = PlayerCam.DefaultFOV;
    Keyframes.AddItem(NewKey);
    
    trueKeyframeNumber = Keyframes.Length - 1;

    pitchDeg = NewKey.Rotation.Pitch * (360.0 / 65536.0);
    yawDeg   = NewKey.Rotation.Yaw   * (360.0 / 65536.0);
    rollDeg  = NewKey.Rotation.Roll  * (360.0 / 65536.0);
    
    ClientMessage("Added keyframe #" $ trueKeyframeNumber $ 
                  ": Duration = " $ Duration $ " sec | Position = (X=" 
                  $ (NewKey.Position.X / 100.0) $ ", Y=" $ (NewKey.Position.Y / 100.0) $ ", Z=" $ (NewKey.Position.Z / 100.0) $ 
                  ") | Rotation = (Pitch=" $ pitchDeg $ " deg, Yaw=" $ yawDeg $ " deg , Roll=" $ rollDeg $ " deg) | FOV = " $ NewKey.FOV $ " deg");

    UpdateDollyDebug();
}

exec function DollyUndo()
{
    local int trueKeyCount, LastIndex, removedKeyframeNumber;

    // Count the true keyframes (ignore dummy if it exists).
    if (Keyframes.Length > 0 && Keyframes[0].Duration == 0)
        trueKeyCount = Keyframes.Length - 1;
    else
        trueKeyCount = Keyframes.Length;

    if (trueKeyCount == 0)
    {
        ClientMessage("No keyframes recorded to undo.");
        return;
    }

    // Determine which keyframe number is being removed.
    // If there's a dummy keyframe at index 0, true keyframes start at 1.
    if (Keyframes.Length > 0 && Keyframes[0].Duration == 0)
        removedKeyframeNumber = Keyframes.Length - 1; // Last true keyframe number.
    else
        removedKeyframeNumber = Keyframes.Length;     // Otherwise, it's the last element.

    // If there's only one true keyframe left, remove everything.
    if (trueKeyCount == 1)
    {
        Keyframes.Length = 0;
        ClientMessage("Removed keyframe #" $ removedKeyframeNumber $ ". 0 keyframe(s) remaining.");
    }
    else
    {
        LastIndex = Keyframes.Length - 1;
        Keyframes.Remove(LastIndex, 1);

        if (Keyframes.Length > 0 && Keyframes[0].Duration == 0)
            trueKeyCount = Keyframes.Length - 1;
        else
            trueKeyCount = Keyframes.Length;
        ClientMessage("Removed keyframe #" $ removedKeyframeNumber $ ". " $ trueKeyCount $ " keyframe(s) remaining.");
    }

    UpdateDollyDebug();
}

exec function DollyRoll(float RollDegrees)
{
    local TdPawn PlayerPawn;
    local TdPlayerCamera PlayerCam;
    local float ConvertedRoll;
    
    PlayerPawn = TdPawn(Pawn);
    if (PlayerPawn == none)
    {
        ClientMessage("Player pawn not found.");
        return;
    }
    
    PlayerCam = TdPlayerCamera(PlayerCamera);
    if (PlayerCam == none)
    {
        ClientMessage("Failed to get TdPlayerCamera.");
        return;
    }
    
    ConvertedRoll = RollDegrees * (65536.0 / 360.0);
    
    PlayerCam.FreeFlightRotation.Roll = ConvertedRoll;
    
    ClientMessage("Dolly roll set to " $ RollDegrees $ " degrees.");
}

exec function DollyFOV(float FOV)
{
    local TdPawn PlayerPawn;
    local TdPlayerCamera PlayerCam;

    if (FOV <= 0.9 || FOV >= 179.1)
    {
        ClientMessage("FOV must be between 1 and 179.");
        return;
    }
    
    PlayerPawn = TdPawn(Pawn);
    if (PlayerPawn == none)
    {
        ClientMessage("Player pawn not found.");
        return;
    }
    
    PlayerCam = TdPlayerCamera(PlayerCamera);
    if (PlayerCam == none)
    {
        ClientMessage("Failed to get TdPlayerCamera.");
        return;
    }
    
    PlayerCam.DefaultFOV = FOV;
    
    CurrentFOV = FOV;
    
    ClientMessage("Dolly FOV set to " $ FOV $ " degrees.");
}

exec function DollySpeed(float Speed)
{
    local TdPlayerCamera PlayerCam;

    if (Speed <= 0.0)
    {
        ClientMessage("Speed must be greater than 0.");
        return;
    }

    Speed = Speed / 10;
    
    PlayerCam = TdPlayerCamera(PlayerCamera);
    if (PlayerCam == none)
    {
        ClientMessage("Failed to get TdPlayerCamera.");
        return;
    }
    
    PlayerCam.FreeflightScale = Speed;
    ClientMessage("Dolly speed set to: " $ Speed);
}

function UpdateDollyDebug()
{
    local int i;
    local DollyKeyframe kf;
    local int startIndex, trueKeyCount;

    if (bIsPlayingDolly)
    {
        FlushPersistentDebugLines();
        return;
    }

    FlushPersistentDebugLines();

    // Determine if the first keyframe is a dummy.
    if (Keyframes.Length > 0 && Keyframes[0].Duration == 0)
    {
        startIndex = 1;
        trueKeyCount = Keyframes.Length - 1;
    }
    else
    {
        startIndex = 0;
        trueKeyCount = Keyframes.Length;
    }

    // Draw a debug box at each "true" keyframe (using an extent of 10 units on each axis).
    for (i = startIndex; i < Keyframes.Length; i++)
    {
        kf = Keyframes[i];
        DrawDebugBox(kf.Position, vect(10, 10, 10), 0, 255, 0, true);
    }

    // Draw debug lines connecting adjacent "true" keyframes.
    // Only draw lines if there are at least two true keyframes.
    if (trueKeyCount >= 2)
    {
        // If dummy exists, only connect keyframes from index 1 onward.
        for (i = startIndex; i < Keyframes.Length - 1; i++)
        {
            DrawDebugLine(Keyframes[i].Position, Keyframes[i + 1].Position, 255, 0, 0, true);
        }
    }
}

exec function DollyPlay()
{
    local TdPawn PlayerPawn;
    local TdPlayerCamera PlayerCam;
    local int i;
    GlobalDollyDuration = 0;

    PlayerPawn = TdPawn(Pawn);
    if (PlayerPawn == none)
    {
        ClientMessage("Player pawn not found.");
        return;
    }

    PlayerCam = TdPlayerCamera(PlayerCamera);
    if (PlayerCam == none)
    {
        ClientMessage("Failed to get TdPlayerCamera.");
        return;
    }

    if (Keyframes.Length == 0)
    {
        ClientMessage("No keyframes recorded.");
        return;
    }

    DollyStartPos = PlayerCam.FreeFlightPosition;
    DollyStartRot = PlayerCam.FreeFlightRotation;
    DollyStartFOV = PlayerCam.DefaultFOV;

    // Compute the global duration: sum the durations of all keyframes.
    for (i = 0; i < Keyframes.Length; i++)
    {
        GlobalDollyDuration += Keyframes[i].Duration;
    }
    GlobalElapsedTime = 0.0;

    bIsDollyActive = true;
    bIsPlayingDolly = true;

    FlushPersistentDebugLines();

    ClientMessage("Dolly playback started. Global duration: " $ GlobalDollyDuration $ " seconds.");
    ConsoleCommand("toggleui");
}


////////////////////////////////////////
// UNFINISHED AND OTHER RANDOM FUNCTIONS
////////////////////////////////////////

// Rudimentary function to perform a move
// Does not work in all cases, and cannot perform moves which are really just sub-moves/animations i.e. backwards evade rolls. Could be improved to account for these
exec function Move(TdPawn.EMovement DesiredMove)
{
    local TdPawn PlayerPawn;

    // Cast the player's pawn to TdPawn
    PlayerPawn = TdPawn(Pawn);

    // Check if the player pawn is valid and apply the move
    if (PlayerPawn != None)
    {
        // Set the move state to the desired move
        if (PlayerPawn.SetMove(DesiredMove))
        {
            ClientMessage("Move set to: " $ DesiredMove);
        }
        else
        {
            ClientMessage("Failed to set move.");
        }
    }
    else
    {
        ClientMessage("Player pawn is not valid.");
    }
}

// Incomplete bot spawning implementation - todo: needs to replicate the way the TdActorFactory handles it
exec function SpawnBot(string PawnClassName, string MeshPath, string AnimSetPath, optional string AnimTreePath, optional string ControllerClassName)
{
    local class<Actor> PawnClassRef;
    local class<Controller> ControllerClassRef;
    local TdBotPawn NewBot;
    local Controller NewController;
    local vector SpawnLocation;
    local rotator SpawnRotation;
    local SkeletalMesh BotMesh;
    local AnimSet BotAnimSet;
    local AnimTree BotAnimTree;

    // Determine spawn location and rotation from the player pawn
    if (Pawn != None)
    {
        SpawnLocation = Pawn.Location + Vector(Pawn.Rotation) * 200;
        SpawnRotation = Pawn.Rotation;
    }
    else
    {
        ClientMessage("Error: Player Pawn not found. Falling back to world origin.");
        SpawnLocation = vect(0,0,0);
        SpawnRotation = rot(0,0,0);
    }

    // Load the Pawn class
    PawnClassRef = class<Actor>(DynamicLoadObject(PawnClassName, class'Class'));
    if (PawnClassRef == None)
    {
        ClientMessage("Failed to load PawnClassRef from " @ PawnClassName);
        return;
    }

    // Spawn the bot pawn
    NewBot = TdBotPawn(Spawn(PawnClassRef, None, '', SpawnLocation, SpawnRotation));
    if (NewBot == None)
    {
        ClientMessage("Failed to spawn bot of class: " @ PawnClassName);
        return;
    }

    // Load and set the Skeletal Mesh
    if (MeshPath != "")
    {
        BotMesh = SkeletalMesh(DynamicLoadObject(MeshPath, class'SkeletalMesh'));
        if (BotMesh != None && NewBot.Mesh != None)
        {
            NewBot.Mesh.SetSkeletalMesh(BotMesh);
        }
        else
        {
            ClientMessage("Warning: Failed to load or set SkeletalMesh from " @ MeshPath);
        }
    }

    // Load and set the AnimSet
    if (AnimSetPath != "")
    {
        BotAnimSet = AnimSet(DynamicLoadObject(AnimSetPath, class'AnimSet'));
        if (BotAnimSet != None && NewBot.Mesh != None)
        {
            NewBot.Mesh.AnimSets.Length = 1;
            NewBot.Mesh.AnimSets[0] = BotAnimSet;
        }
        else
        {
            ClientMessage("Warning: Failed to load or set AnimSet from " @ AnimSetPath);
        }
    }

    // Load and set the AnimTree (if provided)
    if (AnimTreePath != "")
    {
        BotAnimTree = AnimTree(DynamicLoadObject(AnimTreePath, class'AnimTree'));
        if (BotAnimTree != None && NewBot.Mesh != None)
        {
            NewBot.Mesh.SetAnimTreeTemplate(BotAnimTree);
        }
        else
        {
            ClientMessage("Warning: Failed to load or set AnimTree from " @ AnimTreePath);
        }
    }

    // If a ControllerClassName is provided, load and spawn that controller
    if (ControllerClassName != "")
    {
        ControllerClassRef = class<Controller>(DynamicLoadObject(ControllerClassName, class'Class'));
        if (ControllerClassRef != None)
        {
            NewController = (Spawn(ControllerClassRef));
            if (NewController != None)
            {
                // Possess the pawn with this controller
                NewController.Possess(NewBot, FALSE);
            }
            else
            {
                ClientMessage("Failed to spawn controller: " @ ControllerClassName);
            }
        }
        else
        {
            ClientMessage("Failed to load controller class: " @ ControllerClassName);
        }
    }
    else
    {
        // If no custom controller specified, just spawn the default one
        NewBot.SpawnDefaultController();
    }

    ClientMessage("Spawned bot: " @ PawnClassName @ " at " @ SpawnLocation);
}

exec function SpawnCop()
{
    SpawnBot(
        "TdSpContent.TdBotPawn_PatrolCop",
        "CH_TKY_Cop_Patrol.SK_TKY_Cop_Patrol",
        "AS_AI_PatrolCop_OneHanded.AS_AI_PatrolCop_OneHanded",
        "AT_Cop.AT_Cop"
    );
}

exec function SpawnRiot()
{
    SpawnBot(
        "TdSpContent.TdBotPawn_RiotCop",
        "CH_TKY_Cop_Riot.SK_TKY_Cop_Riot",
        "AS_AI_RiotCop_OneHanded.AS_AI_RiotCop_OneHanded",
        "AT_Cop.AT_Cop"
    );
}

exec function SpawnSniper()
{
    SpawnBot(
        "TdSpContent.TdBotPawn_SniperCop",
        "CH_TKY_Cop_SWAT.SK_TKY_Cop_Swat_Sniper",
        "AS_AI_Assault_TwoHanded.AS_AI_Assault_TwoHanded",
        "AT_Cop.AT_Cop"
    );
}

exec function SpawnSWAT()
{
    SpawnBot(
        "TdSpContent.TdBotPawn_Assault",
        "CH_TKY_Cop_SWAT.CH_TKY_Cop_SWAT",
        "AS_AI_Assault_TwoHanded.AS_AI_Assault_TwoHanded",
        "AT_Cop.AT_Cop"
    );
}

exec function SpawnMerc()
{
    SpawnBot(
        "TdSpContent.TdBotPawn_PatrolCop",
        "CH_TKY_Crim_Heavy.SK_TKY_Crim_Heavy",
        "",
        ""
    );
}

// Rudimentary function for cycling through the view targets of actors of the specified class (i.e. TdBotPawn)
// Todo: see if bot views can be offsetted forwards slightly to avoid head clipping (or removing the head?)
exec function ViewClass(class<actor> aClass)
{
	local actor other, first;
	local bool bFound;
	
	first = None;
	
	ForEach AllActors(aClass, other)
	{
		if (bFound || (first == None))
		{
			first = other;
			if (bFound)
				break;
		}
		if (other == ViewTarget)
			bFound = true;
	}
	
	if (first != None)
	{
		if (Pawn(first) != None)
			ClientMessage(ViewingFrom@First.GetHumanReadableName(), 'Event');
		else
			ClientMessage(ViewingFrom@first, 'Event');
		SetViewTarget(first);
		FixFOV();
	}
	else
		ViewSelf(false);
}


defaultproperties
{
}