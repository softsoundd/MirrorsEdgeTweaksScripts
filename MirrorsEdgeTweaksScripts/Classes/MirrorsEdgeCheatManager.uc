class MirrorsEdgeCheatManager extends TdCheatManager;

var CheatHelperProxy HelperProxy;
var SaveLoadHandlerMECM SaveLoad;
var vector SavedLocation;
var rotator SavedRotation;
var vector SavedVelocity;
var vector SavedLastJumpLocation;
var TdPawn.EMovement SavedMoveState;
var float SavedHealth;
var bool SavedReactionTimeState;
var float SavedReactionTimeEnergy;
var vector TimerLocation;
var bool bFreeze;
var float CustomTimeDilation;
var bool bInfiniteAmmoEnabled;
var bool bBotOHKOEnabled;
var bool bHoldFireEnabled;
var bool bMonitorFallHeight;
var bool bMonitorNoclip;
var string NoclipFlyFasterKey;
var string NoclipFlySlowerKey;
var string MeleeState;
var bool bUltraGraphicsEnabled;
var bool bJumpMacroActive;
var bool bInteractMacroActive;
var bool bGrabMacroActive;

struct SavedBotInfo
{
    var TdBotPawn BotPawnRef; // Direct reference to the spawned pawn
    var string PawnClassName;
    var string AITemplatePath;
    var vector Location;
    var rotator Rotation;
    var bool bWasGivenAI;
    var string CustomSkeletalMeshIdentifier;
};

var array<SavedBotInfo> ActiveSpawnedBotsData;

// Dolly variables
var bool bMonitorDolly;
var bool bIsDollyActive;
var bool bIsPlayingDolly;
var vector DollyStartPos;
var rotator DollyStartRot;
var float DollyStartFOV;
var float CurrentFOV;
var float GlobalDollyDuration;
var float GlobalElapsedTime;
var transient float DollyLastRealTime;
var transient bool bDollyRealTimeInitialised;
var transient bool bLinearDollyEasing; // True if dolly should use linear start/end easing

struct DollyKeyframe
{
    var vector Position;
    var rotator Rotation;
    var float Duration;
    var float FOV;
};

var array<DollyKeyframe> Keyframes;

// Prototype cheat manager vars
var private Vector pP1;
var private Vector pP2;

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
    ClientMessage("\"UltraGraphics\" - Sets draw distance and LOD quality to its maximum. Restarting the level resets these properties");
    ClientMessage("\"ColorScaling [RED] [GREEN] [BLUE]\" - Adjusts individual color channels for the final image (default values = 1, 1, 1)");
    ClientMessage("\"PostProcess Highlights [RED] [GREEN] [BLUE]\" - More granular control compared to ColorScaling. Accepts values 0 to 1");
    ClientMessage("\"PostProcess Midtones [RED] [GREEN] [BLUE]\" - More granular control compared to ColorScaling. Accepts values 0 to 1");
    ClientMessage("\"PostProcess Shadows [RED] [GREEN] [BLUE]\" - More granular control compared to ColorScaling. Accepts values -1 to 1");
    ClientMessage("\"PostProcess Saturation [STRENGTH]\" - Adjusts saturation strength for the final image. Accepts values -1 to 1");
    ClientMessage("\"FreezeFrame\" - Freezes time and hides the crosshair. Set the desired delay value in seconds before it engages (use interact key or pause to exit this mode)");
    ClientMessage("\"FreezeBots\" - Freezes just bots");
    ClientMessage("\"FreezePlayer\" - Freezes just the player");
    ClientMessage("\"FreezeWorld\" - Freezes everything except the player");
    ClientMessage("\"StreamLevelIn [MAP PACKAGE]\" - Load the specified map package name and make it active (or all of them with \"All\"). Refer to \"stat levels\" for a list of valid packages");
    ClientMessage("\"OnlyLoadLevel [MAP PACKAGE]\" - Load the specified map package name but keep it inactive (or all of them with \"All\"). Refer to \"stat levels\" for a list of valid packages");
    ClientMessage("\"StreamLevelOut [MAP PACKAGE]\" - Unload the specified map package name (or all of them with \"All\"). Refer to \"stat levels\" for a list of valid packages");
    ClientMessage(" ");
    ClientMessage("Player Cheats:");
    ClientMessage("\"God\" - Toggles \"true\" God mode (doesn't make bots invincible)");
    ClientMessage("\"HarmlessBots\" - Toggles the ability for bots to shoot and perform melee attacks (this may be overridden during scripted sections, just toggle again)");
    ClientMessage("\"FreezeWorld\" - Toggles the movement of bots and all other skeletal meshes besides yourself (this is bugged in Mirror's Edge and also disables interactables)");
    ClientMessage("\"InfiniteAmmo\" - Toggles infinite ammo for weapons");
    ClientMessage("\"ListAllWeapons\" - View a list of all valid weapons to equip");
    ClientMessage("\"ListAllBots\" - View a list of all valid bots to spawn");
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
    ClientMessage("Type the listed weapon to spawn it:");
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

exec function ListAllBots()
{
    ClientMessage("Type the listed bot to spawn it:");
    ClientMessage("\"Assault\"");
    ClientMessage("\"AssaultHKG36C\"");
    ClientMessage("\"AssaultMP5K\"");
    ClientMessage("\"AssaultNeostead\"");
    ClientMessage("\"PatrolCopRemington\"");
    ClientMessage("\"PatrolCopSteyrTMP\"");
    ClientMessage("\"PatrolCop1\"");
    ClientMessage("\"PatrolCop2\"");
    ClientMessage("\"PatrolCop3\"");
    ClientMessage("\"PatrolCopGlock\"");
    ClientMessage("\"RiotCop\"");
    ClientMessage("\"SniperCop\"");
    ClientMessage("\"Support\"");
    ClientMessage("\"PursuitCop\"");
    ClientMessage("\"CelesteBoss\"");
    ClientMessage("\"CelesteSniper\"");
    ClientMessage("\"Jacknife\"");
    ClientMessage(" ");
    ClientMessage("Optionally, type the following custom skins as a second parameter:");
    ClientMessage("\"Assault\"");
    ClientMessage("\"PatrolCop\"");
    ClientMessage("\"SniperCop\"");             
    ClientMessage("\"Support\"");
    ClientMessage("\"CelesteBoss\"");
    ClientMessage("\"Celeste\"");
    ClientMessage("\"Jacknife\"");
    ClientMessage("\"Mercury\"");
    ClientMessage("\"Ropeburn\"");
    ClientMessage("\"Miller\"");
    ClientMessage("\"Kreeg\"");
    ClientMessage("\"Faith\"");
    ClientMessage("\"Kate\"");
    ClientMessage("\"Rat\"");
    ClientMessage("\"Pigeon\"");
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
    ClientMessage("\"DollyPlay\" - Plays the dolly camera sequence. The UI will be forcefully hidden during this, avoid pressing buttons. \"DollyPlay Linear\" removes interpolation easing from the start keyframe");
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

exec function FreezePlayer()
{
    local TdPlayerPawn Pawn;
    
    bFreeze = !bFreeze;

    if (bFreeze)
    {
        foreach AllActors(Class'TdPlayerPawn', Pawn)
        {
            Pawn.CustomTimeDilation = 0;
        }
    }
    else
    {
        foreach AllActors(Class'TdPlayerPawn', Pawn)
        {
            Pawn.CustomTimeDilation = 1;
        }
    }
}

exec function FreezeBots()
{
    local TdBotPawn Bot;
    local TdVehicle_Helicopter Heli;
    local SkeletalMeshComponent SkelMesh;

    bFreeze = !bFreeze; 

    if (bFreeze)
    {
        foreach AllActors(Class'TdBotPawn', Bot)
        {
            SkelMesh = Bot.Mesh;

            if (SkelMesh != none && SkelMesh.PhysicsAssetInstance != none && SkelMesh.PhysicsWeight > 0.0f)
            {
                Bot.CustomTimeDilation = 0;
                SkelMesh.bUpdateKinematicBonesFromAnimation = false; 
                SkelMesh.PhysicsAssetInstance.SetAllBodiesFixed(true);
                SkelMesh.PutRigidBodyToSleep();
            }

            Bot.CustomTimeDilation = 0;
        }
        foreach AllActors(Class'TdVehicle_Helicopter', Heli)
        {
            Heli.CustomTimeDilation = 0;
        }
    }
    else
    {
        foreach AllActors(Class'TdBotPawn', Bot)
        {
            SkelMesh = Bot.Mesh;
            if (SkelMesh != none && SkelMesh.PhysicsAssetInstance != none) 
            {
                if (SkelMesh.PhysicsWeight > 0.0f)
                {
                    SkelMesh.bUpdateKinematicBonesFromAnimation = true; 
                    SkelMesh.PhysicsAssetInstance.SetAllBodiesFixed(false);
                    SkelMesh.WakeRigidBody();
                }
            }
            Bot.CustomTimeDilation = 1;
        }
        foreach AllActors(Class'TdVehicle_Helicopter', Heli)
        {
            Heli.CustomTimeDilation = 1;
        }
    }
}

// Sets maximum ammo on all weapons. Todo: see if we can set these variables directly rather than relying on the "set" command
exec function InfiniteAmmo()
{
    if(Outer.InfiniteAmmo)
    {
        ClientMessage("Infinite ammo disabled.");
        ConsoleCommand("DisplayTrainerHUDMessage Infinite ammo disabled");       
    }
    else
    {
        ClientMessage("Infinite ammo enabled.");
        ConsoleCommand("DisplayTrainerHUDMessage Infinite ammo enabled");
        if(TdWeapon(Outer.Pawn.Weapon) != none)
        {
            TdWeapon(Outer.Pawn.Weapon).AmmoCount++;
        }
    }
    Outer.InfiniteAmmo = !Outer.InfiniteAmmo;
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
    local TdMove_Landing LandingMove;

    if (bCheatFlying) 
    {
        // Disable noclip
        bCheatFlying = false;
        Outer.GotoState('PlayerWalking');
        Pawn.SetCollision(true, true);
        Pawn.CheatWalk();
        myPawn.bAllowMoveChange = true;
        myPawn.AccelRate = 6144;

        if (myPawn != None)
        {
            LandingMove = TdMove_Landing(myPawn.Moves[20]);
            LandingMove.HardLandingHeight = 9999999;
            myPawn.FallingUncontrolledHeight = 9999999;
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
            if (myPawn != None && myPawn.GetStateName() == 'UncontrolledFall')
            {
                myPawn.GotoState('None'); // Exit UncontrolledFall
            }
            
            myPawn.StopAllCustomAnimations(0); // Immediately stop animations played before this function was called
            myPawn.SetMove(MOVE_Walking); // Force walking as certain moves won't allow noclip to function

            bCheatFlying = true;
            Pawn.CheatGhost(); // Previously I didn't include this but turns out it's needed to truly disable collision when activating noclip while jumping
            Outer.GotoState('PlayerFlying');
            myPawn.bAllowMoveChange = false; // Prevents attack/q turns and other actions from interrupting flying state
            myPawn.AccelRate = 999999;
            ConsoleCommand("set TdHudEffectManager UncontrolledFallingEffectSpeed 0");

            bMonitorFallHeight = false;
            bMonitorNoclip = true;
            EnsureHelperProxy();
            ConsoleCommand("DisplayTrainerHUDMessage Noclip enabled");
        }
        else
        {
            bCollideWorld = false;
        }
    }

    ConsoleCommand("exec TweaksScriptsSettings");
}

exec function SetNoclipFlyFasterKey(string Keybind)
{
    ConsoleCommand("set MirrorsEdgeCheatManager NoclipFlyFasterKey " $  Keybind);
}

exec function SetNoclipFlySlowerKey(string Keybind)
{
    ConsoleCommand("set MirrorsEdgeCheatManager NoclipFlySlowerKey " $  Keybind);
}

// Checks if player is still in the air after exiting noclip, and if landed, sets fall values back to default. This is used for the TpToSurface function too
function FallHeightMonitoring()
{
    local TdMove_Landing LandingMove;
    
    if (bMonitorFallHeight && myPawn != None)
    {
        if (myPawn.Physics == PHYS_Walking && myPawn.Base != none)
        {
            LandingMove = TdMove_Landing(myPawn.Moves[20]);

            LandingMove.HardLandingHeight = 530;
            myPawn.FallingUncontrolledHeight = 1000;
            ConsoleCommand("set TdHudEffectManager UncontrolledFallingEffectSpeed 0.5");
            bMonitorFallHeight = false; // Stop monitoring after landing
        }
    }
}

// Keypress and death monitoring while in noclip
function NoclipMonitoring(float DeltaTime)
{
    local TdPlayerController PC;

    PC = TdPlayerController(Pawn.Controller);

    if (bMonitorNoclip && Pawn == None) // Check if the player is dead
    {
        myPawn.bAllowMoveChange = true;
        bCheatFlying = false;
        ConsoleCommand("set TdPawn bCollideWorld true");
        Outer.GotoState('PlayerWalking');
        Pawn.SetCollision(true, true);
        Pawn.CheatWalk();
        bMonitorNoclip = false; // Stop monitoring further
    }

    myPawn.ReleaseCameraConstraintsAgainstWall();
    ConsoleCommand("set TdMove bUseCameraCollision false");

    if (PC != None && PC.PlayerInput != None)
    {
        if (PC.PlayerInput.PressedKeys.Find(name(NoclipFlyFasterKey)) != -1)
        {
            if (myPawn.AirSpeed <= 20000)
            {
                myPawn.AirSpeed += 2500 * DeltaTime;
            }
        }

        if (PC.PlayerInput.PressedKeys.Find(name(NoclipFlySlowerKey)) != -1)
        {
            if (myPawn.AirSpeed >= 200)
            {
                myPawn.AirSpeed -= 5000 * DeltaTime;
            }
        }

        if (PC.PlayerInput.PressedKeys.Find('LeftShift') != -1)
        {
            PC.PlayerInput.aUp = -50 * DeltaTime;
        }
        else
        {
            PC.PlayerInput.aUp = 0;
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
    local TdPlayerController PlayerController;
    local int i;
    local SavedBotInfo BotEntry;
    local array<SavedBotInfo> LiveBots; // Temp array for currently alive bots

    if (Pawn == None)
    {
        ClientMessage("SaveLocation Error: Player Pawn is None. Cannot save.");
        return;
    }

    PlayerController = TdPlayerController(Pawn.Controller);

    // Save player state
    SavedLocation = Pawn.Location;
    SavedVelocity = Pawn.Velocity;
    SavedHealth = Pawn.Health;
    SavedReactionTimeEnergy = PlayerController.ReactionTimeEnergy;
    SavedReactionTimeState = PlayerController.bReactionTime;

    if (Pawn.Controller != None)
    {
        SavedRotation.Pitch = Pawn.Controller.Rotation.Pitch;
    }
    SavedRotation.Yaw = Pawn.Rotation.Yaw;
    SavedRotation.Roll = 0;

    if (myPawn != None)
    {
        SavedLastJumpLocation = myPawn.LastJumpLocation;
        SavedMoveState = myPawn.MovementState;
    }

    // Client message for player state
    ConvertedLocation.X = SavedLocation.X / 100;
    ConvertedLocation.Y = SavedLocation.Y / 100;
    ConvertedLocation.Z = SavedLocation.Z / 100;
    PitchDegrees = (float(SavedRotation.Pitch) / 65536.0) * 360.0;
    YawDegrees = (float(SavedRotation.Yaw) / 65536.0) * 360.0;
    if (PitchDegrees > 180.0) { PitchDegrees -= 360.0; }
    ClientMessage("Saved Location: X=" $ ConvertedLocation.X $ ", Y=" $ ConvertedLocation.Y $ ", Z=" $ ConvertedLocation.Z $
                  " | Saved Rotation: Pitch=" $ PitchDegrees $ ", Yaw=" $ YawDegrees $ " | Saved Move State: " $ SavedMoveState);

    if (SaveLoad == None)
    {
        SaveLoad = new class'SaveLoadHandlerMECM';
    }

    // Persist player data
    SaveLoad.SaveData("SavedLocation", class'SaveLoadHandlerMECM'.static.SerialiseVector(SavedLocation));
    SaveLoad.SaveData("SavedVelocity", class'SaveLoadHandlerMECM'.static.SerialiseVector(SavedVelocity));
    SaveLoad.SaveData("SavedRotation", class'SaveLoadHandlerMECM'.static.SerialiseRotator(SavedRotation));
    SaveLoad.SaveData("SavedHealth", string(SavedHealth));
    SaveLoad.SaveData("SavedReactionTimeEnergy", string(SavedReactionTimeEnergy));
    SaveLoad.SaveData("SavedReactionTimeState", string(SavedReactionTimeState));

    if (myPawn != None)
    {
        SaveLoad.SaveData("SavedLastJumpLocation", class'SaveLoadHandlerMECM'.static.SerialiseVector(SavedLastJumpLocation));
        SaveLoad.SaveData("SavedMoveState", EnumToString(myPawn.MovementState));
    }

    // Before saving bot data, iterate through our tracked bots to:
    // 1. Remove any bots that have been killed or destroyed.
    // 2. Update the Location and Rotation for bots that are still alive.
    for (i = 0; i < ActiveSpawnedBotsData.Length; i++)
    {
        if (ActiveSpawnedBotsData[i].BotPawnRef != None && !ActiveSpawnedBotsData[i].BotPawnRef.bDeleteMe)
        {
            // Bot is alive, update its state and add it to our list of live bots
            ActiveSpawnedBotsData[i].Location = ActiveSpawnedBotsData[i].BotPawnRef.Location;
            ActiveSpawnedBotsData[i].Rotation = ActiveSpawnedBotsData[i].BotPawnRef.Rotation;
            LiveBots.AddItem(ActiveSpawnedBotsData[i]);
        }
    }
    // The master list now only contains live, tracked bots
    ActiveSpawnedBotsData = LiveBots;

    // Save any bots we have spawned
    SaveLoad.SaveData("SavedBotCount", string(ActiveSpawnedBotsData.Length));

    for (i = 0; i < ActiveSpawnedBotsData.Length; i++)
    {
        BotEntry = ActiveSpawnedBotsData[i];
        SaveLoad.SaveData("SavedBot_" $ i $ "_PawnClass", BotEntry.PawnClassName);
        SaveLoad.SaveData("SavedBot_" $ i $ "_AITemplate", BotEntry.AITemplatePath);
        SaveLoad.SaveData("SavedBot_" $ i $ "_Location", class'SaveLoadHandlerMECM'.static.SerialiseVector(BotEntry.Location));
        SaveLoad.SaveData("SavedBot_" $ i $ "_Rotation", class'SaveLoadHandlerMECM'.static.SerialiseRotator(BotEntry.Rotation));
        SaveLoad.SaveData("SavedBot_" $ i $ "_bWasGivenAI", string(BotEntry.bWasGivenAI));
        SaveLoad.SaveData("SavedBot_" $ i $ "_CustomMeshID", BotEntry.CustomSkeletalMeshIdentifier);

        ClientMessage("Saving Bot " @ i @ ": Class=" @ BotEntry.PawnClassName @ ", MeshID='" @ BotEntry.CustomSkeletalMeshIdentifier @ "'");
    }

    ConsoleCommand("DisplayTrainerHUDMessage Player state saved");
}

// Converts the movement enums into a string representation for the SaveLoadHandlerMECM class
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
        case MOVE_Jump:               return "MOVE_Jump";
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
    local TdPlayerController PlayerControllerRef;
    local string LoadedStringData;
    local int i, NumBotsToLoad;
    local SavedBotInfo BotDataToLoad;
    local TdBotPawn RespawnedBot;

    ConsoleCommand("ResetHUDTimer");

    DestroyAllTrackedBots();

    if (SaveLoad == None)
    {
        SaveLoad = new class'SaveLoadHandlerMECM';
    }

    LoadedStringData = SaveLoad.LoadData("SavedLocation");
    if (LoadedStringData != "") SavedLocation = class'SaveLoadHandlerMECM'.static.DeserialiseVector(LoadedStringData); else SavedLocation = vect(0,0,0);

    LoadedStringData = SaveLoad.LoadData("SavedVelocity");
    if (LoadedStringData != "") SavedVelocity = class'SaveLoadHandlerMECM'.static.DeserialiseVector(LoadedStringData); else SavedVelocity = vect(0,0,0);

    LoadedStringData = SaveLoad.LoadData("SavedRotation");
    if (LoadedStringData != "") SavedRotation = class'SaveLoadHandlerMECM'.static.DeserialiseRotator(LoadedStringData); else SavedRotation = rot(0,0,0);

    LoadedStringData = SaveLoad.LoadData("SavedHealth");
    if (LoadedStringData != "") SavedHealth = float(LoadedStringData); else SavedHealth = 100;

    LoadedStringData = SaveLoad.LoadData("SavedReactionTimeEnergy");
    if (LoadedStringData != "") SavedReactionTimeEnergy = float(LoadedStringData); else SavedReactionTimeEnergy = 0;

    LoadedStringData = SaveLoad.LoadData("SavedReactionTimeState");
    if (LoadedStringData != "") SavedReactionTimeState = (Locs(LoadedStringData) == "true"); else SavedReactionTimeState = false;

    LoadedStringData = SaveLoad.LoadData("SavedLastJumpLocation");
    if (LoadedStringData != "") SavedLastJumpLocation = class'SaveLoadHandlerMECM'.static.DeserialiseVector(LoadedStringData);

    LoadedStringData = SaveLoad.LoadData("SavedMoveState");
    if (LoadedStringData != "") SavedMoveState = StringToEMovement(LoadedStringData); else SavedMoveState = MOVE_Walking;

    LoadedStringData = SaveLoad.LoadData("TimerLocation");
    if (LoadedStringData != "") TimerLocation = class'SaveLoadHandlerMECM'.static.DeserialiseVector(LoadedStringData);


    if (Pawn == None)
    {
        ClientMessage("TpToSavedLocation Error: Player Pawn is None. Cannot restore state.");
    }
    else if (SavedLocation != vect(0,0,0))
    {
        Pawn.Velocity = vect(0,0,0);
        Pawn.SetLocation(SavedLocation);
        Pawn.Health = SavedHealth;

        PlayerControllerRef = TdPlayerController(Pawn.Controller);
        if (PlayerControllerRef != None)
        {
            WorldInfo.Game.SetGameSpeed(1);
            PlayerControllerRef.bReactionTime = SavedReactionTimeState;
            PlayerControllerRef.ReactionTimeEnergy = SavedReactionTimeEnergy;
        }

        if (myPawn.GetStateName() == 'UncontrolledFall')
        {
            myPawn.GotoState('None');
        }

        myPawn.StopAllCustomAnimations(0);
        myPawn.LastJumpLocation = SavedLastJumpLocation;

        if (SavedMoveState == MOVE_Walking || SavedMoveState == MOVE_Falling || SavedMoveState == MOVE_WallRun)
        {
            myPawn.SetMove(SavedMoveState);
        }
        else if (SavedMoveState == MOVE_Grabbing)
        {
            myPawn.SetMove(MOVE_IntoGrab);
        }
        else
        {
            myPawn.SetMove(MOVE_Walking); // Fallback
        }

        Pawn.SetPhysics(PHYS_None);
        ConsoleCommand("set TdPawn bAllowMoveChange False");

        BugItGo(SavedLocation.X, SavedLocation.Y, SavedLocation.Z, SavedRotation.Pitch, SavedRotation.Yaw, 0);
    }

    LoadedStringData = SaveLoad.LoadData("SavedBotCount");
    if (LoadedStringData != "")
    {
        NumBotsToLoad = int(LoadedStringData);

        for (i = 0; i < NumBotsToLoad; i++)
        {
            // Clear struct for new data
            BotDataToLoad.PawnClassName = ""; 
            BotDataToLoad.AITemplatePath = ""; 
            BotDataToLoad.CustomSkeletalMeshIdentifier = "";
            BotDataToLoad.BotPawnRef = None; // Ensure reference is cleared

            // Load bot data from persistence
            BotDataToLoad.PawnClassName = SaveLoad.LoadData("SavedBot_" $ i $ "_PawnClass");
            BotDataToLoad.AITemplatePath = SaveLoad.LoadData("SavedBot_" $ i $ "_AITemplate");

            LoadedStringData = SaveLoad.LoadData("SavedBot_" $ i $ "_Location");
            if (LoadedStringData != "") BotDataToLoad.Location = class'SaveLoadHandlerMECM'.static.DeserialiseVector(LoadedStringData); else continue;

            LoadedStringData = SaveLoad.LoadData("SavedBot_" $ i $ "_Rotation");
            if (LoadedStringData != "") BotDataToLoad.Rotation = class'SaveLoadHandlerMECM'.static.DeserialiseRotator(LoadedStringData); else continue;

            LoadedStringData = SaveLoad.LoadData("SavedBot_" $ i $ "_bWasGivenAI");
            if (LoadedStringData != "") BotDataToLoad.bWasGivenAI = (Locs(LoadedStringData) == "true"); else BotDataToLoad.bWasGivenAI = false;

            BotDataToLoad.CustomSkeletalMeshIdentifier = SaveLoad.LoadData("SavedBot_" $ i $ "_CustomMeshID");

            if (BotDataToLoad.PawnClassName == "" || BotDataToLoad.AITemplatePath == "")
            {
                ClientMessage("Error: Incomplete class/template data for saved bot index " @ i @ ". Skipping.");
                continue;
            }

            // Spawn the bot
            RespawnedBot = SpawnBotInternal(
                BotDataToLoad.PawnClassName,
                BotDataToLoad.AITemplatePath,
                BotDataToLoad.Location,
                BotDataToLoad.Rotation,
                BotDataToLoad.CustomSkeletalMeshIdentifier,
                BotDataToLoad.bWasGivenAI,
                true // Ensure this bot is retracked
            );

            if (RespawnedBot == None)
            {
                ClientMessage("Error: Failed to respawn bot index " @ i @ " with class " @ BotDataToLoad.PawnClassName);
            }
        }
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
    if (SavedLocation != vect(0,0,0))
    {
        if (Pawn.Controller != None)
        {
            Pawn.Controller.SetRotation(SavedRotation);
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

        PlayerController = TdPlayerController(Pawn.Controller);
        if (PlayerController != None)
        {
            PlayerController.ReactionTimeEnergy = SavedReactionTimeEnergy;

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
    local TdMove_Landing LandingMove;

    GetPlayerViewPoint(ViewLocation, ViewRotation);

    HitActor = Trace(HitLocation, HitNormal, ViewLocation + 1000000 * vector(ViewRotation), ViewLocation, true);

    if (HitActor != None)
    {
        if (myPawn.GetStateName() == 'UncontrolledFall')
        {
            myPawn.GotoState('None');
        }

        myPawn.StopAllCustomAnimations(0);

        if (myPawn != None)
        {
            LandingMove = TdMove_Landing(myPawn.Moves[20]);
            LandingMove.HardLandingHeight = 9999999;
            myPawn.FallingUncontrolledHeight = 9999999;
            bMonitorFallHeight = true;
            EnsureHelperProxy();
        }

        // Adjust the hit location slightly to avoid embedding the player into the surface
        HitLocation += HitNormal * 4.0;

        ViewTarget.SetLocation(HitLocation);

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

    if (SaveLoad == None)
    {
        SaveLoad = new class'SaveLoadHandlerMECM';
    }
    SaveLoad.SaveData("TimerLocation", class'SaveLoadHandlerMECM'.static.SerialiseVector(TimerLocation));

    ConsoleCommand("SetHUDTimerLocation " $ TimerLocation.X $ " " $ TimerLocation.Y $ " " $ TimerLocation.Z);

    ConsoleCommand("ResetHUDTimer");

    ClientMessage("Timer location set: X=" $ (TimerLocation.X / 100) $ ", Y=" $ (TimerLocation.Y / 100) $ ", Z=" $ (TimerLocation.Z / 100));

    ConsoleCommand("DisplayTrainerHUDMessage Timer location set");
}

// Sets the Z component of the LastJumpLocation variable. Todo: see if setting the entire vector behaves any differently for flings, as is the game's default behaviour
exec function LastJumpLocation(float NewZValueInMeters)
{
    if (myPawn != None)
    {
        // Convert the specified Z value from meters to Unreal units by multiplying by 100
        myPawn.LastJumpLocation.Z = NewZValueInMeters * 100;

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

    Command = "set " $ TargetClass $ " " $ PropertyName $ " " $ string(JumpHeight);

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

    Command = "set " $ TargetClass $ " " $ PropertyName $ " " $ string(JumpSpeed);

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

    Command = "set " $ TargetClass $ " " $ PropertyName $ " " $ string(SpeedCap);

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

    Command = "set " $ TargetClass $ " " $ PropertyName $ " " $ string(RollHeight);

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

    Command = "set " $ TargetClass $ " " $ PropertyName $ " " $ string(DeathHeight);

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

    Command = "set " $ TargetClass $ " " $ PropertyName $ " " $ string(GravityMultiplier);

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

    Command = "set " $ TargetClass $ " " $ PropertyName $ " " $ string(SpeedMultiplier);

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

exec function UltraGraphics()
{
    EnsureHelperProxy();

    bUltraGraphicsEnabled = !bUltraGraphicsEnabled;

    if (bUltraGraphicsEnabled)
    {
        ConsoleCommand("set DecalComponent bStaticDecal 0");
        ConsoleCommand("set DecalComponent bNeverCull 1");
        HelperProxy.LoopFunction(2, "ApplyUltraGraphics");
        ClientMessage("Ultra graphics enabled.");
    }
    else
    {
        HelperProxy.StopTimer();
        ClientMessage("Ultra graphics disabled.");
    }
}

exec function ApplyUltraGraphics()
{
    local Actor A;
    local StaticMeshComponent StaticMeshComp;
    local SkeletalMeshComponent SkeletalMeshComp;
    local PrimitiveComponent PrimComp;

    ForEach AllActors(class'Actor', A)
    {
        ForEach A.AllOwnedComponents(class'StaticMeshComponent', StaticMeshComp)
        {
            if (StaticMeshComp != none && StaticMeshComp.ForcedLODModel != 1)
            {
                StaticMeshComp.ForcedLODModel = 1;
            }
        }

        ForEach A.AllOwnedComponents(class'SkeletalMeshComponent', SkeletalMeshComp)
        {
            if (SkeletalMeshComp != none && SkeletalMeshComp.ForcedLODModel != 1)
            {
                SkeletalMeshComp.ForcedLODModel = 1;
            }
        }

        ForEach A.AllOwnedComponents(class'PrimitiveComponent', PrimComp)
        {
            if (PrimComp != none && PrimComp.CachedCullDistance != 0.0)
            {
                PrimComp.SetCullDistance(0.0);
            }
        }
    }
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

    WeaponClass = class<Weapon>(DynamicLoadObject(WeaponClassStr, class'Class'));

    Weap = Weapon(Pawn.FindInventoryType(WeaponClass));

    if (Weap != None)
    {
        return Weap;
    }

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

// Spam macros
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
    local TdPlayerInput TdInput;

    TdInput = TdPlayerInput(PlayerInput);
    TdInput.Jump();
    TdInput.StopJump();
}

exec function MacroInteract()
{
    Outer.UsePress();
    Outer.UseRelease();
}

exec function MacroGrab()
{
    ConsoleCommand("PressedSwitchWeapon");
    ConsoleCommand("ReleasedSwitchWeapon");
}

// This function sets the screen resolution, adjusts UI scaling, and verifies that the chosen resolution is valid
exec function Resolution(int Width, int Height, optional string Windowed)
{
    local TdUIScene UI;
    local array<string> ValidResolutions;
    local string CandidateResolution;
    local int i;
    local string Res;
    local bool bIsValid;
    local float ScalingFactor;
    local int RestestValue;
    local float AspectRatio;
    local string ResolutionCommand;
    local string UIStyleCommand;

    if (Windowed == "")
    {
        UI = GetActiveOrDefaultTdUIScene();
        if (UI != none)
        {
            UI.GetPossibleScreenResolutions(ValidResolutions);
            CandidateResolution = string(Width) $ "x" $ string(Height);
            bIsValid = false;
            for (i = 0; i < ValidResolutions.Length; i++)
            {
                if (ValidResolutions[i] == CandidateResolution)
                {
                    bIsValid = true;
                    break;
                }
            }
            if (!bIsValid)
            {
                ClientMessage("Invalid fullscreen resolution: " $ CandidateResolution $ " is not supported in fullscreen - try using the windowed argument instead. Supported fullscreen resolutions for your system:");
                for (i = 0; i < ValidResolutions.Length; i++)
                {
                    Res = ValidResolutions[i];
                    ClientMessage(Res);
                }
                return;
            }
        }
    }

    // Continue with setting the resolution and UI adjustments.
    AspectRatio = float(Width) / float(Height);

    if (Width > 1920)
    {
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
    UIStyleCommand = "set UIStyle_Text Scale (X=" $ string(ScalingFactor) $ ",Y=" $ string(ScalingFactor) $ ")";
    ConsoleCommand(UIStyleCommand);
    ConsoleCommand("RestartLevel");

    ClientMessage("Resolution set to " $ string(Width) $ "x" $ string(Height) $ " and corrected blurry UI");
}

// Helper function to allow utilising the native functions in TdUIScene
function TdUIScene GetActiveOrDefaultTdUIScene()
{
    local TdPlayerController PC;
    local UIInteraction UICont;
    local TdGameUISceneClient SceneClient;
    local UIScene ActiveScene;
    local TdUIScene UI;

    // First, try to retrieve an active UIScene from the UI controller's SceneClient.
    PC = TdPlayerController(Pawn.Controller);
    if (PC != none)
    {
        UICont = LocalPlayer(PC.Player).ViewportClient.UIController;
        if (UICont != none)
        {
            if (UICont.SceneClient != none)
            {
                SceneClient = TdGameUISceneClient(UICont.SceneClient);
                if (SceneClient.ActiveScenes.Length > 0)
                {
                    ActiveScene = SceneClient.ActiveScenes[0];
                    UI = TdUIScene(ActiveScene);
                }
            }
        }
    }
    
    // If no active scene was found, we load a dummy UIScene.
    if (UI == none)
    {
        UI = TdUIScene(class'TdHUDContent'.static.GetUISceneByName('TdLoadIndicator'));
    }
    
    return UI;
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
    local string Property;
    local bool bIsPropertyRecognised;
    local bool bIsVectorProperty;
    local vector VecValue;

    Property = Locs(PropertyName);

    // Determine if this property is vector-based
    if (Property == "highlights" || // Note - highlights act the same as ColorScale
        Property == "midtones" ||
        Property == "shadows")
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
            if (Property == "saturation")
            {
                PPVolume.Settings.Scene_Desaturation = -X;
                bIsPropertyRecognised = true;
            }
            else if (Property == "sceneinterpolation")
            {
                PPVolume.Settings.Scene_InterpolationDuration = X;
                bIsPropertyRecognised = true;
            }
        }
        else
        {
            if (Property == "highlights")
            {
                PPVolume.Settings.Scene_HighLights = VecValue;
                bIsPropertyRecognised = true;
            }
            else if (Property == "midtones")
            {
                PPVolume.Settings.Scene_MidTones = VecValue;
                bIsPropertyRecognised = true;
            }
            else if (Property == "shadows")
            {
                PPVolume.Settings.Scene_Shadows = VecValue;
                bIsPropertyRecognised = true;
            }
        }
    }

    // Apply changes to WorldInfo global settings (usually outdoors)
    if (!bIsVectorProperty)
    {
        if (Property == "saturation")
        {
            WI.DefaultPostProcessSettings.Scene_Desaturation = -X;
            bIsPropertyRecognised = true;
        }
        else if (Property == "sceneinterpolation")
        {
            WI.DefaultPostProcessSettings.Scene_InterpolationDuration = X;
            bIsPropertyRecognised = true;
        }
    }
    else
    {
        if (Property == "highlights")
        {
            WI.DefaultPostProcessSettings.Scene_HighLights = VecValue;
            bIsPropertyRecognised = true;
        }
        else if (Property == "midtones")
        {
            WI.DefaultPostProcessSettings.Scene_MidTones = VecValue;
            bIsPropertyRecognised = true;
        }
        else if (Property == "shadows")
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

exec function SetPhysX(string TimingCategory, string PropertyName, float Value)
{
    local WorldInfo WI;
    local PlayerController PC;
    local bool bIsPropertyRecognised;
    local string boolString;
    local float ConvertedTimeStep;

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

    if (TimingCategory == "primary" || TimingCategory == "primaryscenetiming")
    {
        if (PropertyName == "bfixedtimestep")
        {
            WI.PhysicsTimings.PrimarySceneTiming.bFixedTimeStep = (Value != 0);
            bIsPropertyRecognised = true;
            boolString = WI.PhysicsTimings.PrimarySceneTiming.bFixedTimeStep ? "true" : "false";
            ClientMessage("Applied bFixedTimeStep = " $ boolString $ " to PrimarySceneTiming.");
        }
        else if (PropertyName == "timestep")
        {
            if (Value < 0)
            {
                ClientMessage("Error: Hz value must be greater than zero.");
                return;
            }
            ConvertedTimeStep = 1.0 / Value;
            WI.PhysicsTimings.PrimarySceneTiming.TimeStep = ConvertedTimeStep;
            bIsPropertyRecognised = true;
            ClientMessage("Applied TimeStep = " $ string(ConvertedTimeStep) $ " (from " $ string(Value) $ " Hz) to PrimarySceneTiming.");
        }
        else if (PropertyName == "maxsubsteps")
        {
            WI.PhysicsTimings.PrimarySceneTiming.MaxSubSteps = int(Value);
            bIsPropertyRecognised = true;
            ClientMessage("Applied MaxSubSteps = " $ string(int(Value)) $ " to PrimarySceneTiming.");
        }
    }
    else if (TimingCategory == "rigidbody" || TimingCategory == "compartmenttimingrigidbody")
    {
        if (PropertyName == "bfixedtimestep")
        {
            WI.PhysicsTimings.CompartmentTimingRigidBody.bFixedTimeStep = (Value != 0);
            bIsPropertyRecognised = true;
            boolString = WI.PhysicsTimings.CompartmentTimingRigidBody.bFixedTimeStep ? "true" : "false";
            ClientMessage("Applied bFixedTimeStep = " $ boolString $ " to CompartmentTimingRigidBody.");
        }
        else if (PropertyName == "timestep")
        {
            if (Value < 0)
            {
                ClientMessage("Error: Hz value must be greater than zero.");
                return;
            }
            ConvertedTimeStep = 1.0 / Value;
            WI.PhysicsTimings.CompartmentTimingRigidBody.TimeStep = ConvertedTimeStep;
            bIsPropertyRecognised = true;
            ClientMessage("Applied TimeStep = " $ string(ConvertedTimeStep) $ " (from " $ string(Value) $ " Hz) to CompartmentTimingRigidBody.");
        }
        else if (PropertyName == "maxsubsteps")
        {
            WI.PhysicsTimings.CompartmentTimingRigidBody.MaxSubSteps = int(Value);
            bIsPropertyRecognised = true;
            ClientMessage("Applied MaxSubSteps = " $ string(int(Value)) $ " to CompartmentTimingRigidBody.");
        }
    }
    else if (TimingCategory == "fluid" || TimingCategory == "compartmenttimingfluid")
    {
        if (PropertyName == "bfixedtimestep")
        {
            WI.PhysicsTimings.CompartmentTimingFluid.bFixedTimeStep = (Value != 0);
            bIsPropertyRecognised = true;
            boolString = WI.PhysicsTimings.CompartmentTimingFluid.bFixedTimeStep ? "true" : "false";
            ClientMessage("Applied bFixedTimeStep = " $ boolString $ " to CompartmentTimingFluid.");
        }
        else if (PropertyName == "timestep")
        {
            if (Value < 0)
            {
                ClientMessage("Error: Hz value must be greater than zero.");
                return;
            }
            ConvertedTimeStep = 1.0 / Value;
            WI.PhysicsTimings.CompartmentTimingFluid.TimeStep = ConvertedTimeStep;
            bIsPropertyRecognised = true;
            ClientMessage("Applied TimeStep = " $ string(ConvertedTimeStep) $ " (from " $ string(Value) $ " Hz) to CompartmentTimingFluid.");
        }
        else if (PropertyName == "maxsubsteps")
        {
            WI.PhysicsTimings.CompartmentTimingFluid.MaxSubSteps = int(Value);
            bIsPropertyRecognised = true;
            ClientMessage("Applied MaxSubSteps = " $ string(int(Value)) $ " to CompartmentTimingFluid.");
        }
    }
    else if (TimingCategory == "cloth" || TimingCategory == "compartmenttimingcloth")
    {
        if (PropertyName == "bfixedtimestep")
        {
            WI.PhysicsTimings.CompartmentTimingCloth.bFixedTimeStep = (Value != 0);
            bIsPropertyRecognised = true;
            boolString = WI.PhysicsTimings.CompartmentTimingCloth.bFixedTimeStep ? "true" : "false";
            ClientMessage("Applied bFixedTimeStep = " $ boolString $ " to CompartmentTimingCloth.");
        }
        else if (PropertyName == "timestep")
        {
            if (Value < 0)
            {
                ClientMessage("Error: Hz value must be greater than zero.");
                return;
            }
            ConvertedTimeStep = 1.0 / Value;
            WI.PhysicsTimings.CompartmentTimingCloth.TimeStep = ConvertedTimeStep;
            bIsPropertyRecognised = true;
            ClientMessage("Applied TimeStep = " $ string(ConvertedTimeStep) $ " (from " $ string(Value) $ " Hz) to CompartmentTimingCloth.");
        }
        else if (PropertyName == "maxsubsteps")
        {
            WI.PhysicsTimings.CompartmentTimingCloth.MaxSubSteps = int(Value);
            bIsPropertyRecognised = true;
            ClientMessage("Applied MaxSubSteps = " $ string(int(Value)) $ " to CompartmentTimingCloth.");
        }
    }
    else if (TimingCategory == "softbody" || TimingCategory == "compartmenttimingsoftbody")
    {
        if (PropertyName == "bfixedtimestep")
        {
            WI.PhysicsTimings.CompartmentTimingSoftBody.bFixedTimeStep = (Value != 0);
            bIsPropertyRecognised = true;
            boolString = WI.PhysicsTimings.CompartmentTimingSoftBody.bFixedTimeStep ? "true" : "false";
            ClientMessage("Applied bFixedTimeStep = " $ boolString $ " to CompartmentTimingSoftBody.");
        }
        else if (PropertyName == "timestep")
        {
            if (Value < 0)
            {
                ClientMessage("Error: Hz value must be greater than zero.");
                return;
            }
            ConvertedTimeStep = 1.0 / Value;
            WI.PhysicsTimings.CompartmentTimingSoftBody.TimeStep = ConvertedTimeStep;
            bIsPropertyRecognised = true;
            ClientMessage("Applied TimeStep = " $ string(ConvertedTimeStep) $ " (from " $ string(Value) $ " Hz) to CompartmentTimingSoftBody.");
        }
        else if (PropertyName == "maxsubsteps")
        {
            WI.PhysicsTimings.CompartmentTimingSoftBody.MaxSubSteps = int(Value);
            bIsPropertyRecognised = true;
            ClientMessage("Applied MaxSubSteps = " $ string(int(Value)) $ " to CompartmentTimingSoftBody.");
        }
    }
    else
    {
        ClientMessage("Timing category not recognised: " $ TimingCategory);
        return;
    }

    if (!bIsPropertyRecognised)
    {
        ClientMessage("Property not recognised: " $ PropertyName);
    }
}

// Ensures the helper proxy for the extended Actor class is initialised
function EnsureHelperProxy()
{
    if (HelperProxy == None || HelperProxy.Pawn != TdPawn(Pawn))
    {
        if (HelperProxy != None)
        {
            HelperProxy.Destroy();
        }

        HelperProxy = WorldInfo.Spawn(class'CheatHelperProxy');
        HelperProxy.CheatManagerReference = self;
        HelperProxy.Pawn = TdPawn(Pawn);
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
    if (bMonitorFallHeight)
    {
        FallHeightMonitoring();
    }

    if (bMonitorNoclip)
    {
        NoclipMonitoring(DeltaTime);
    }

    if (bMonitorDolly)
    {
        Dolly(DeltaTime);
        DollyMonitoring();
    }
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

function Dolly(float DeltaTime)
{
    local float norm, remapped, globalEffectiveTime;
    local float cumulative, local_t;
    local int segIndex, i;
    local vector newPos, P0, P1, P2, P3;
    local TdPawn PlayerPawn;
    local TdPlayerCamera PlayerCam;
    local float rP0, rP1, rP2, rP3, newPitch, newYaw, newRoll;
    local float fP0, fP1, fP2, fP3, newFOV;
    local float currentRealWorldTime, realFrameDeltaSeconds;

    if (!bIsDollyActive)
        return;

    PlayerPawn = TdPawn(Pawn);
    if (PlayerPawn == none) return;

    PlayerCam = TdPlayerCamera(PlayerCamera);
    if (PlayerCam == none) return;

    currentRealWorldTime = PlayerPawn.WorldInfo.RealTimeSeconds;
    if (!bDollyRealTimeInitialised)
    {
        realFrameDeltaSeconds = 0.0;
        DollyLastRealTime = currentRealWorldTime;
        bDollyRealTimeInitialised = true;
    }
    else
    {
        realFrameDeltaSeconds = currentRealWorldTime - DollyLastRealTime;
        DollyLastRealTime = currentRealWorldTime;
    }

    if (realFrameDeltaSeconds < 0.0) 
    {
        realFrameDeltaSeconds = 0.0;
    }
    if (realFrameDeltaSeconds > 0.2)
    {
        realFrameDeltaSeconds = 0.2;
    }

    GlobalElapsedTime += realFrameDeltaSeconds;

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
        bDollyRealTimeInitialised = false;
        return;
    }

    if (GlobalDollyDuration > 0.0)
    {
        norm = GlobalElapsedTime / GlobalDollyDuration;
    }
    else
    {
        norm = 0.0;
    }

    if (bLinearDollyEasing)
    {
        globalEffectiveTime = GlobalElapsedTime;
    }
    else
    {
        remapped = SmootherStep(norm);
        globalEffectiveTime = remapped * GlobalDollyDuration;
    }

    cumulative = 0;
    segIndex = 0;
    for (i = 0; i < Keyframes.Length; i++)
    {
        // Check if this keyframe has 0 duration; if so, it might be skipped quickly
        // unless globalEffectiveTime is also 0.
        if (globalEffectiveTime < cumulative + Keyframes[i].Duration || Keyframes[i].Duration == 0 && globalEffectiveTime == cumulative)
        {
            segIndex = i;
            break;
        }
        cumulative += Keyframes[i].Duration;
    }
    
    if (i == Keyframes.Length)
    {
        segIndex = Max(0, Keyframes.Length - 1);
    }

    if (Keyframes[segIndex].Duration > 0.0)
    {
        local_t = (globalEffectiveTime - cumulative) / Keyframes[segIndex].Duration;
    }
    else
    {
        local_t = 0.0;
        if (globalEffectiveTime > cumulative) // If we are "past" the start of a zero-duration segment
        {
            local_t = 1.0;
        }
    }
    local_t = FClamp(local_t, 0.0, 1.0); // Ensure local_t is always valid for B-Spline

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
        if (PC.PlayerInput.PressedKeys.Find('SpaceBar') != -1)
        {
            PlayerCam.FreeFlightPosition.Z += 50.0 * PlayerCam.FreeflightScale;
        }

        if (PC.PlayerInput.PressedKeys.Find('LeftShift') != -1)
        {
            PlayerCam.FreeFlightPosition.Z -= 50.0 * PlayerCam.FreeflightScale;
        }

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
    ConsoleCommand("set SkeletalMeshComponent DepthPriorityGroup SDPG_World");

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
    // If there's a dummy keyframe at index 0, true keyframes start at 1
    if (Keyframes.Length > 0 && Keyframes[0].Duration == 0)
        removedKeyframeNumber = Keyframes.Length - 1; // Last true keyframe number
    else
        removedKeyframeNumber = Keyframes.Length; // Otherwise, it's the last element

    // If there's only one true keyframe left, remove everything
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

    // Determine if the first keyframe is a dummy
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

    for (i = startIndex; i < Keyframes.Length; i++)
    {
        kf = Keyframes[i];
        DrawDebugBox(kf.Position, vect(10, 10, 10), 0, 255, 0, true);
    }

    // Draw debug lines connecting adjacent "true" keyframes
    // Only draw lines if there are at least two true keyframes
    if (trueKeyCount >= 2)
    {
        // If dummy exists, only connect keyframes from index 1 onward
        for (i = startIndex; i < Keyframes.Length - 1; i++)
        {
            DrawDebugLine(Keyframes[i].Position, Keyframes[i + 1].Position, 255, 0, 0, true);
        }
    }
}

exec function DollyPlay(optional string EaseMode)
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
        ClientMessage("No keyframes recorded (or not enough for playback).");
        return;
    }

    // Set easing mode
    if (Caps(EaseMode) == "LINEAR")
    {
        bLinearDollyEasing = true;
    }
    else
    {
        bLinearDollyEasing = false; // Default to SmootherStep
    }

    DollyStartPos = PlayerCam.FreeFlightPosition;
    DollyStartRot = PlayerCam.FreeFlightRotation;
    DollyStartFOV = PlayerCam.DefaultFOV;

    // Compute the global duration: sum the durations of all keyframes.
    GlobalDollyDuration = 0;
    for (i = 0; i < Keyframes.Length; i++)
    {
        GlobalDollyDuration += Keyframes[i].Duration;
    }

    // Check if GlobalDollyDuration is valid
    if (GlobalDollyDuration <= 0.0 && Keyframes.Length > 0)
    {
        ClientMessage("Dolly total duration is zero. Cannot play.");
        bIsDollyActive = false;
        bIsPlayingDolly = false;
        bDollyRealTimeInitialised = false;
        return;
    }


    GlobalElapsedTime = 0.0;
    bDollyRealTimeInitialised = false;

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

// Internal function to handle the actual spawning and setup of a bot.
function TdBotPawn SpawnBotInternal(string PawnClassName, string AITemplatePath, vector NewSpawnLocation, rotator NewSpawnRotation, string InCustomSkeletalMeshIdentifier, bool bGiveAIValue, optional bool bRecordForSaving = true)
{
    local class<Actor> PawnClassRef;
    local TdBotPawn NewBot;
    local TdAIController myController;
    local AITemplate LoadedTemplate;
    local AITeam FoundTeam;
    local int StageResult;
    local bool bSetupFailed;
    local SavedBotInfo BotRecord;
    local string OriginalTemplateMeshPath, ResolvedMeshPath;
    local bool bCustomMeshPathApplied;

    // Load AI template
    if (AITemplatePath != "")
    {
        LoadedTemplate = AITemplate(DynamicLoadObject(AITemplatePath, class'AITemplate'));
        if (LoadedTemplate == None)
        {
            ClientMessage("Error (InternalSpawn): Failed to load AITemplate: " @ AITemplatePath);
            return None;
        }
    }
    else
    {
        ClientMessage("Error (InternalSpawn): AITemplatePath parameter is required.");
        return None;
    }

    // Load bot class
    PawnClassRef = class<Actor>(DynamicLoadObject(PawnClassName, class'Class'));
    if (PawnClassRef == None)
    {
        ClientMessage("Error (InternalSpawn): Failed to load Pawn Class: " @ PawnClassName);
        return None;
    }
    if (!ClassIsChildOf(PawnClassRef, class'TdBotPawn'))
    {
        ClientMessage("Error (InternalSpawn): Class " @ PawnClassName @ " is not a subclass of TdBotPawn.");
        return None;
    }

    // Spawn the bot actor
    NewBot = TdBotPawn(Spawn(PawnClassRef, None, '', NewSpawnLocation, NewSpawnRotation));
    if (NewBot == None)
    {
        ClientMessage("Error (InternalSpawn): Failed to spawn bot actor of class: " @ PawnClassName);
        return None;
    }

    // Handle custom skeletal meshes
    if (InCustomSkeletalMeshIdentifier != "" && LoadedTemplate != None)
    {
        Locs(InCustomSkeletalMeshIdentifier);
        ResolvedMeshPath = InCustomSkeletalMeshIdentifier;

        if (InCustomSkeletalMeshIdentifier == "assault")
        {            
            ResolvedMeshPath = "CH_TKY_Cop_SWAT.CH_TKY_Cop_SWAT"; 
        }
        else if (InCustomSkeletalMeshIdentifier == "patrolcop")
        {           
            ResolvedMeshPath = "CH_TKY_Cop_Patrol.SK_TKY_Cop_Patrol"; 
        }
        else if (InCustomSkeletalMeshIdentifier == "riotcop")
        {           
            ResolvedMeshPath = "CH_TKY_Cop_Patrol.SK_TKY_Cop_Patrol_PK"; 
        }
        else if (InCustomSkeletalMeshIdentifier == "snipercop")
        {           
            ResolvedMeshPath = "CH_TKY_Cop_SWAT.SK_TKY_Cop_Swat_Sniper"; 
        }
        else if (InCustomSkeletalMeshIdentifier == "support")
        {           
            ResolvedMeshPath = "CH_TKY_Cop_Support.SK_TKY_Cop_Support"; 
        }
        else if (InCustomSkeletalMeshIdentifier == "celesteboss")
        {            
            ResolvedMeshPath = "CH_TKY_Cop_Pursuit_Female.SK_TKY_Cop_Pursuit_Female"; 
        }
        else if (InCustomSkeletalMeshIdentifier == "celeste")
        {           
            ResolvedMeshPath = "CH_Celeste.SK_Celeste"; 
        }
        else if (InCustomSkeletalMeshIdentifier == "jacknife")
        {            
            ResolvedMeshPath = "CH_TKY_Crim_Jacknife.SK_TKY_Crim_Jacknife"; 
        }
        else if (InCustomSkeletalMeshIdentifier == "mercury")
        {            
            ResolvedMeshPath = "CH_TKY_Crim_Heavy.SK_TKY_Crim_Heavy"; 
        }
        else if (InCustomSkeletalMeshIdentifier == "ropeburn")
        {            
            ResolvedMeshPath = "CH_TKY_Crim_RB.SK_TKY_Crim_RB"; 
        }
        else if (InCustomSkeletalMeshIdentifier == "miller")
        {            
            ResolvedMeshPath = "CH_Miller.SK_Miller"; 
        }
        else if (InCustomSkeletalMeshIdentifier == "kreeg")
        {            
            ResolvedMeshPath = "CH_Kreeg.SK_Kreeg"; 
        }
        else if (InCustomSkeletalMeshIdentifier == "faith")
        {            
            ResolvedMeshPath = "CH_TKY_Crim_Fixer.SK_TKY_Crim_Fixer"; 
        }
        else if (InCustomSkeletalMeshIdentifier == "kate")
        {            
            ResolvedMeshPath = "CH_TKY_Cop_Patrol_Female.SK_TKY_Cop_Patrol_Female"; 
        }
        else if (InCustomSkeletalMeshIdentifier == "rat")
        {            
            ResolvedMeshPath = "CH_Rat.SK_Rat"; 
        }
        else if (InCustomSkeletalMeshIdentifier == "pigeon")
        {
            ResolvedMeshPath = "CH_Pigeon.SK_Pigeon"; 
        }

        if (ResolvedMeshPath != "")
        {
            OriginalTemplateMeshPath = LoadedTemplate.SkeletalMesh;
            LoadedTemplate.SkeletalMesh = ResolvedMeshPath;
            bCustomMeshPathApplied = true;
        }
    }

    // Setup bot using template
    StageResult = -99;
    bSetupFailed = false;
    while (StageResult < 1 && !bSetupFailed)
    {
        if (NewBot == None || NewBot.bDeleteMe)
        {
            bSetupFailed = true;
            break;
        }
        StageResult = NewBot.SetupTemplate(LoadedTemplate, true);

        if (StageResult == 0 && NewBot.SetupTemplateCount == 0)
        {
            bSetupFailed = true;
        }
    }

    if (bCustomMeshPathApplied && LoadedTemplate != None)
    {
        if (LoadedTemplate.SkeletalMesh == ResolvedMeshPath)
        {
            LoadedTemplate.SkeletalMesh = OriginalTemplateMeshPath;
        }
        else
        {
            ClientMessage("Warning (InternalSpawn): Template mesh path was not as expected before reverting. Current: '"@LoadedTemplate.SkeletalMesh@"', Expected set: '"@ResolvedMeshPath@"' Original: '"@OriginalTemplateMeshPath@"'");
        }
        bCustomMeshPathApplied = false;
    }


    if (bSetupFailed)
    {
        ClientMessage("Error (InternalSpawn): Pawn setup aborted for " @ NewBot.Name);
        if (NewBot != None && !NewBot.bDeleteMe) NewBot.Destroy();
        return None;
    }

    // Spawn controller, assign team, setup controller
    if (NewBot != None && !NewBot.bDeleteMe)
    {
        NewBot.SpawnDefaultController();
        if (bGiveAIValue)
        {
            myController = TdAIController(NewBot.Controller);
            if (myController != None)
            {
                FoundTeam = FindFirstAITeam();
                if (FoundTeam != None)
                {
                    myController.Team = FoundTeam;
                    FoundTeam.AddMember(myController);
                } else {
                    ClientMessage("Warning (InternalSpawn): Could not find an AITeam for " @ NewBot.Name);
                }

                StageResult = -99;
                bSetupFailed = false;
                while (StageResult < 1 && !bSetupFailed)
                {
                    if (myController == None || myController.Pawn == None || myController.Pawn.bDeleteMe) { bSetupFailed = true; break; }
                    StageResult = myController.SetupTemplate(LoadedTemplate);

                    if (StageResult == 0 && myController.SetupTemplateCount == 0) {}
                }

                if (bSetupFailed)
                {
                    ClientMessage("Error (InternalSpawn): Controller setup aborted for " @ myController.Name);
                    if (NewBot != None && !NewBot.bDeleteMe) NewBot.Destroy();
                    return None;
                }
                
                if (FoundTeam == None)
                {
                    ClientMessage("Warning (InternalSpawn): No AITeam found in the level!");
                }

                if (FoundTeam != None)
                {
                    myController.Team = FoundTeam;
                    FoundTeam.AddMember(myController);
                }
                else
                {
                    ClientMessage("CRITICAL: No AITeam found or assigned! This will likely break AI.");
                }

                myController.Initialize();

                if (Pawn != None)
                {
                    if (myController.Enemy == None)
                    {
                        myController.SetEnemy(TdPawn(Pawn));
                    }

                    myController.SetDifficultyLevel(myController.DifficultyLevel);
                }
                else
                {
                    ClientMessage("Error: Player Pawn reference is None. Cannot set AI target.");
                }
            }
            else
            {
                ClientMessage("Error (InternalSpawn): Failed to get TdAIController for " @ NewBot.Name @ " when bGiveAI was true.");
                if (NewBot != None && !NewBot.bDeleteMe) NewBot.Destroy();
                return None;
            }
        }

        // Record bot data
        if (bRecordForSaving)
        {
            BotRecord.BotPawnRef = NewBot; // Store the direct reference
            BotRecord.PawnClassName = PawnClassName;
            BotRecord.AITemplatePath = AITemplatePath;
            BotRecord.Location = NewBot.Location;
            BotRecord.Rotation = NewBot.Rotation;
            BotRecord.bWasGivenAI = bGiveAIValue;
            BotRecord.CustomSkeletalMeshIdentifier = InCustomSkeletalMeshIdentifier;
            ActiveSpawnedBotsData.AddItem(BotRecord);
        }

        return NewBot;
    }

    ClientMessage("Warning (InternalSpawn): Bot disappeared or setup failed before completion for class " @ PawnClassName);
    if (NewBot != None && !NewBot.bDeleteMe) NewBot.Destroy();
    return None;
}


// Spawns a bot using its AITemplate, and optional custom mesh and team assignment
exec function SpawnBot(string PawnClassName, string AITemplatePath, optional string CustomSkeletalMeshIdentifier, optional bool bGiveAIFromExec)
{
    local vector PlayerRelativeSpawnLocation;
    local rotator PlayerRelativeSpawnRotation;
    local TdBotPawn SpawnedBotReference;

    if (Pawn != None)
    {
        PlayerRelativeSpawnLocation = Pawn.Location + Vector(Pawn.Rotation) * 200;
        PlayerRelativeSpawnRotation = Pawn.Rotation;
        //PlayerRelativeSpawnLocation = vect(20389.36, -2804.10, 2525.00);
        //PlayerRelativeSpawnRotation = rot(0,0,0);
    }
    else
    {
        ClientMessage("Error (SpawnBot Exec): Player Pawn not found. Spawning at origin.");
        PlayerRelativeSpawnLocation = vect(0,0,0);
        PlayerRelativeSpawnRotation = rot(0,0,0);
    }

    SpawnedBotReference = SpawnBotInternal(PawnClassName, AITemplatePath, PlayerRelativeSpawnLocation, PlayerRelativeSpawnRotation, CustomSkeletalMeshIdentifier, bGiveAIFromExec, true);

    if (SpawnedBotReference == None)
    {
        ClientMessage("Exec SpawnBot failed for class: " @ PawnClassName);
    }
}

function DestroyAllTrackedBots()
{
    local int i;

    for (i = 0; i < ActiveSpawnedBotsData.Length; i++)
    {
        if (ActiveSpawnedBotsData[i].BotPawnRef != None && !ActiveSpawnedBotsData[i].BotPawnRef.bDeleteMe)
        {
            ActiveSpawnedBotsData[i].BotPawnRef.Destroy();
        }
    }

    // Clear the tracking array
    ActiveSpawnedBotsData.Remove(0, ActiveSpawnedBotsData.Length);
}

// Helper function to find the first available AITeam
function AITeam FindFirstAITeam()
{
    local AITeam T;

    foreach AllActors(class'AITeam', T)
    {
        return T;
    }
    return None;
}

exec function Assault(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_Assault",
        "TdGame.Default__AITemplate_Assault",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function AssaultHKG36C(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_Assault",
        "TdGame.Default__AITemplate_Assault_HKG36C",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function AssaultMP5K(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_Assault",
        "TdGame.Default__AITemplate_Assault_MP5K",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function AssaultNeostead(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_Assault",
        "TdGame.Default__AITemplate_Assault_Neostead",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function PatrolCopRemington(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_PatrolCop",
        "TdGame.Default__AITemplate_PatrolCop_Remington",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function PatrolCopSteyrTMP(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_PatrolCop",
        "TdGame.Default__AITemplate_PatrolCop_SteyrTMP",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function PatrolCop1(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_PatrolCop",
        "TdGame.Default__AITemplate_PatrolCop",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function PatrolCop2(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_PatrolCop",
        "TdGame.Default__AITemplate_PatrolCop2",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function PatrolCop3(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_PatrolCop",
        "TdGame.Default__AITemplate_PatrolCop3",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function PatrolCopGlock(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_PatrolCop",
        "TdGame.Default__AITemplate_PatrolCop_Glock",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function RiotCop(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_RiotCop",
        "TdGame.Default__AITemplate_RiotCop",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function SniperCop(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_SniperCop",
        "TdGame.Default__AITemplate_SniperCop",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function Support(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_Support",
        "TdGame.Default__AITemplate_Support",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function PursuitCop(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_PursuitCop",
        "TdGame.Default__AITemplate_PursuitCop",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function Gunner(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_SupportHelicopterGunner",
        "TdGame.Default__AITemplate_Gunner",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function CelesteBoss(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpBossContent.TdBotPawn_Celeste",
        "TdGame.Default__AITemplate_Celeste",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function CelesteSniper(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpBossContent.TdBotPawn_SniperCeleste",
        "TdGame.Default__AITemplate_SniperCeleste",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function Jacknife(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_JKSniper",
        "TdGame.Default__AITemplate_HeliSniper",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function Celeste(optional string CustomSkeletalMesh, optional bool bGiveAI)
{
    SpawnBot(
        "TdSpContent.TdBotPawn_Dummy",
        "TdGame.Default__AITemplate_Tutorial",
        CustomSkeletalMesh,
        bGiveAI
    );
}

exec function Ragdoll()
{
    local private TdBotPawn P;

    foreach Outer.WorldInfo.AllPawns(Class'TdBotPawn', P)
    {
        P.TakeDamage(9999, none, vect(0, 0, 0), vect(0, 0, 0), Class'TdDmgType_Melee');    
    }    
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

exec function testmesh()
{
    local TdPawn PlayerPawn;

    PlayerPawn = TdPawn(Pawn);

    PlayerPawn.SetFirstPerson(false);
    PlayerPawn.Mesh.ForceSkelUpdate();  
}


////////////////////////////////////
// Prototype cheat manager functions
////////////////////////////////////

function SetDebugControllers()
{
    if(DebugController == none)
    {
        foreach Outer.WorldInfo.AllControllers(Class'TdAIController', DebugController)
        {
            break;            
        }        
    }
    if(aPawn == none)
    {
        foreach Outer.WorldInfo.AllPawns(Class'Pawn', aPawn)
        {
            break;            
        }        
    }
}

exec function DebugDamage()
{
    local private TdAIController C;

    Outer.ClientMessage("Toggle debug damage on all spawned AI pawns.");
    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', C)
    {
        if(C.myPawn != none)
        {
            C.myPawn.bDebugDamage = !C.myPawn.bDebugDamage;
        }        
    }    
}

exec function ToggleRebuilt()
{
    //Outer.WorldInfo.bRemoveRebuildLighting = !Outer.WorldInfo.bRemoveRebuildLighting;
    ConsoleCommand("set WorldInfo bRemoveRebuildLighting 1");
}

exec function SuppressAI()
{
    local private TdAIController C;

    Outer.ClientMessage("Suppress called by player!!!");
    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', C)
    {
        Outer.ClientMessage("Adding suppression");
        C.AddSuppressionFactor(1);        
    }    
}

exec function Difficulty(int Level)
{
    local private TdAIController AIGuy;
    local private TdPlayerController PlayerGrrl;

    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', AIGuy)
    {
        AIGuy.SetDifficultyLevel(Level);        
    }    
    foreach Outer.WorldInfo.AllControllers(Class'TdPlayerController', PlayerGrrl)
    {
        PlayerGrrl.SetDifficultyLevel(Level);        
    }    
}

exec function Ammo()
{
    if(Outer.InfiniteAmmo)
    {
        Outer.ClientMessage("Infinite Ammo off");        
    }
    else
    {
        Outer.ClientMessage("Infinite Ammo on");
        if(TdWeapon(Outer.Pawn.Weapon) != none)
        {
            TdWeapon(Outer.Pawn.Weapon).AmmoCount++;
        }
    }
    Outer.InfiniteAmmo = !Outer.InfiniteAmmo;
}

exec function SeeMe()
{
    local private TdAIController P;

    if((Outer.WorldInfo.NetMode != NM_Standalone) || Outer.Pawn == none)
    {
        return;
    }
    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', P)
    {
        P.HandleEnemySeen(Outer.Pawn);        
    }    
}

exec function Test()
{
    AIGotoState('TestingState_Test', true);
}

exec function Cover()
{
    AIGotoState('TestingState_Cover', true);
}

exec function Run()
{
    AIGotoState('TestingState_Run', false);
}

exec function DebugCover(bool bSelectClosestCover)
{
    local private TdAIController AIController;

    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', AIController)
    {
        if(bSelectClosestCover)
        {
            AIController.TdGotoState('DebugCoverState', 'Begin');
            continue;
        }
        AIController.TdGotoState('DebugCoverState', 'Random');        
    }    
}

exec function ChangeCover(bool bSelectClosestCover)
{
    local private TdAIController AIController;

    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', AIController)
    {
        if(AIController.IsInState('DebugCoverState') == true)
        {
            if(bSelectClosestCover)
            {
                AIController.TdGotoState('DebugCoverChangeCoverState', 'Begin');
                continue;
            }
            AIController.TdGotoState('DebugCoverChangeCoverState', 'Random');
        }        
    }    
}

exec function CoverGoToState(string iState)
{
    local private TdAIController AIController;

    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', AIController)
    {
        AIController.CoverGoToState(iState);        
    }    
}

exec function LLThrowGrenade()
{
    local private TdAIController P;

    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', P)
    {
        P.TdGotoState('ThrowGrenadeState');        
    }    
}

exec function LLRetreat()
{
    local private TdAIController P;

    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', P)
    {
        P.TdGotoState('Retreat', 'Begin',,, true);        
    }    
}

exec function LLTurn()
{
    local private TdAIController P;

    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', P)
    {
        P.myPawn.SetMove(43);        
    }    
}

exec function LLDoFinishAttack()
{
    local private TdAI_Pursuit P;

    foreach Outer.WorldInfo.AllControllers(Class'TdAI_Pursuit', P)
    {
        P.NotifyFinishingMovePossible();        
    }    
}

/* exec function LLDoMeleeDodge()
{
    local private TdAI_Pursuit P;

    foreach Outer.WorldInfo.AllControllers(Class'TdAI_Pursuit', P)
    {
        P.NotifyIncomingMeleeAttack();        
    }    
} */

exec function ToggleSlomo()
{
    SlomoSpeed += 0.3;
    if(SlomoSpeed > 1)
    {
        SlomoSpeed = 0.1;
    }
    SloMo(SlomoSpeed);
}

exec function PlayAnim(name AnimationName)
{
    local private TdBotPawn AiPawn;
    local private TdAIController AIController;
    local private TdMove_AnimationPlayback AnimationPlaybackMove;

    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', AIController)
    {
        AiPawn = AIController.myPawn;
        AnimationPlaybackMove = TdMove_AnimationPlayback(AiPawn.Moves[74]);
        AnimationPlaybackMove.SetAnimationName(AnimationName);
        AnimationPlaybackMove.SetBlendTime(0, 0);
        AnimationPlaybackMove.UseRootMotion(false);
        AnimationPlaybackMove.UseRootRotation(false);
        AnimationPlaybackMove.SetPhysics(1);
        AiPawn.SetMove(74);        
    }    
    bShowTestAnimHud = true;
}

exec function hack1()
{
    local private TdAIController P;

    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', P)
    {
        P.myPawn.bUseLegRotationHack1 = !P.myPawn.bUseLegRotationHack1;
        ClientMessage("bUseLegRotationHack1:" @ string(P.myPawn.bUseLegRotationHack1));        
    }    
    bShowTestAnimHud = true;
}

exec function hack2()
{
    local private TdAIController P;

    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', P)
    {
        P.myPawn.bUseLegRotationHack2 = !P.myPawn.bUseLegRotationHack2;
        ClientMessage("bUseLegRotationHack2:" @ string(P.myPawn.bUseLegRotationHack2));        
    }    
    bShowTestAnimHud = true;
}

exec function Invisible()
{
    local private TdAIController P;
    local private TdAIManager AIManager;

    AIManager = TdSPStoryGame(Outer.WorldInfo.Game).AIManager;
    if(AIManager == none)
    {
        return;
    }
    if(AIManager.bPlayerInvisibleToAI)
    {
        ClientMessage("Making player visible to AI");
        AIManager.bPlayerInvisibleToAI = false;        
    }
    else
    {
        ClientMessage("Making player invisible to AI");
        AIManager.bPlayerInvisibleToAI = true;
        AIManager.CheckedLastSeenLocation = false;
        AIManager.LastSeenLocation = vect(0, 0, 0);
        foreach Outer.WorldInfo.AllControllers(Class'TdAIController', P)
        {
            ConsoleCommand("set TdAIController WantedFocus FT_None");
            ConsoleCommand("HeadFocus False");
            P.myEnemy = none;
            P.Enemy = none;
            P.EnemyVisible = false;
            P.StopFiring();
            P.UpdateCombatState();
            P.Team.Enemy = none;
            P.Team.ForgetEnemy();
            P.Team.Reset();
            P.TdGotoState('Idle',,,, true);            
        }        
    }
}

exec function ToggleAIWalking()
{
    local private TdAIController P;

    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', P)
    {
        if(P.myPawn.GetIsWalkingFlagSet())
        {
            P.myPawn.SetWalking(false);
            ClientMessage("AI Stops Walking");
            continue;
        }
        P.myPawn.SetWalking(true);
        ClientMessage("AI Starts Walking");        
    }    
}

exec function ToggleAICrouching()
{
    local private TdAIController P;

    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', P)
    {
        if(P.myPawn.IsCrouching())
        {
            P.Crouch(false);
            ClientMessage("AI Stops Crouching");
            continue;
        }
        P.Crouch(true);
        ClientMessage("AI Starts Crouching");        
    }    
}

exec function TestCovers()
{
    AIGotoState('TestingState_TestCovers', true);
}

exec function Idle()
{
    AIGotoState('Idle');
}

exec function AIGotoState(name NewState, optional bool onlyFirst)
{
    local private TdAIController P;
    local private bool hasSet;

    onlyFirst = false;
    if((Outer.WorldInfo.NetMode != NM_Standalone) || Outer.Pawn == none)
    {
        return;
    }
    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', P)
    {
        if(!hasSet)
        {
            P.TdGotoState(NewState,,,, true);            
        }
        else
        {
            P.TdGotoState('Error',,,, true);
        }
        if(onlyFirst)
        {
            hasSet = true;
        }        
    }    
}

exec function AIGod()
{
    local private TdAIController P;
    local private bool isGod, Set;

    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', P)
    {
        P.myPawn.bAIGodMode = !P.myPawn.bAIGodMode;
        isGod = P.myPawn.bAIGodMode;
        Set = true;        
    }    
    if(Set)
    {
        if(isGod)
        {
            Outer.ClientMessage("AI is GOD");            
        }
        else
        {
            Outer.ClientMessage("AI is Human");
        }
    }
}

exec function Jesus()
{
    if(Outer.bJesusMode)
    {
        Outer.bJesusMode = false;
        Outer.ClientMessage("Jesus mode off");
        return;
    }
    Outer.bJesusMode = true;
    Outer.ClientMessage("Jesus Mode on");
}

exec function DropMe()
{
    local private Actor HitActor;
    local private Vector HitNormal, HitLocation, ViewLocation;
    local private Rotator ViewRotation;
    local private Vector Extent;

    if(Outer.PlayerCamera.CameraStyle == 'FreeFlight')
    {
        Outer.GetPlayerViewPoint(ViewLocation, ViewRotation);
        ViewRotation.Pitch = 0;
        Extent = vect(2, 2, 2);
        HitActor = Outer.Trace(HitLocation, HitNormal, ViewLocation + (2500 * vect(0, 0, -1)), ViewLocation, true, Extent);
        if(HitActor == none)
        {
            return;
        }
        if((HitNormal Dot vect(0, 0, 1)) < 0.25)
        {
            return;
        }
        HitLocation += (HitNormal * 4);
        Outer.ViewTarget.SetLocation(HitLocation);
        Outer.SetRotation(ViewRotation);
        Outer.Pawn.Velocity = vect(0, 0, 0);
        Outer.Pawn.Acceleration = vect(0, 0, 0);
        if(TdPawn(Outer.Pawn) != none)
        {
            TdPawn(Outer.Pawn).SetMove(1);
            TdPawn(Outer.Pawn).SetCollision(TdPawn(Outer.Pawn).bCollideActors, true);
            TdPawn(Outer.Pawn).bCollideWorld = true;
            TdPawn(Outer.Pawn).SetFirstPerson(true);
        }
        Outer.bIgnoreMoveInput = 0;
        Outer.bIgnoreLookInput = 0;
        Outer.SetCameraMode('FirstPerson');        
    }
    else
    {
        if(!Outer.bGodMode && !Outer.bJesusMode)
        {
            return;
        }
        if(TdPlayerCamera(Outer.PlayerCamera) != none)
        {
            Outer.SetCameraMode('FreeFlight');
            TdPlayerCamera(Outer.PlayerCamera).FreeflightPosition = Outer.Pawn.Location;
            TdPlayerCamera(Outer.PlayerCamera).FreeflightRotation = Outer.Pawn.Rotation;
            Outer.bIgnoreMoveInput = 1;
            Outer.bIgnoreLookInput = 1;
            if(TdPawn(Outer.Pawn) != none)
            {
                TdPawn(Outer.Pawn).SetFirstPerson(false);
            }
        }
    }
}

exec function ShowClosest()
{
    local private TdBotPawn P, closest;
    local private float MinDist;
    local private Vector ViewLocation;
    local private Rotator ViewRotation;

    MinDist = 9999999;
    Outer.GetPlayerViewPoint(ViewLocation, ViewRotation);
    foreach Outer.WorldInfo.AllPawns(Class'TdBotPawn', P)
    {
        if(VSize(ViewLocation - P.Location) < MinDist)
        {
            MinDist = VSize(ViewLocation - P.Location);
            closest = P;
        }        
    }    
    closest.bDebugOutput = true;
    foreach Outer.WorldInfo.AllPawns(Class'TdBotPawn', P)
    {
        if(P != closest)
        {
            P.bDebugOutput = false;
        }        
    }    
}

exec function ShowAll()
{
    local private TdBotPawn P;

    foreach Outer.WorldInfo.AllPawns(Class'TdBotPawn', P)
    {
        P.bDebugOutput = true;        
    }    
}

exec function Cycle()
{
    local private TdBotPawn P, Current, Next;

    foreach Outer.WorldInfo.AllPawns(Class'TdBotPawn', P)
    {
        if(Current == none)
        {
            if(P.bDebugOutput)
            {
                Current = P;
            }
            continue;
        }
        Next = P;
        break;        
    }    
    if(Next == none)
    {
        foreach Outer.WorldInfo.AllPawns(Class'TdBotPawn', P)
        {
            Next = P;
            break;            
        }        
    }
    Current.bDebugOutput = false;
    Next.bDebugOutput = true;
}

exec function pp()
{
    local private Actor HitActor;
    local private Vector HitNormal, HitLocation, ViewLocation;
    local private Rotator ViewRotation;

    Outer.GetPlayerViewPoint(ViewLocation, ViewRotation);
    HitActor = Outer.Trace(HitLocation, HitNormal, ViewLocation + (float(1000000) * vector(ViewRotation)), ViewLocation, true);
    if(HitActor != none)
    {
        HitLocation += (HitNormal * 40);
        enemyPos = HitLocation;
        Outer.ClientMessage("Cover Debug: Enemy pos has been set");
        Outer.Pawn.DrawDebugLineTime(enemyPos - vect(30, 0, 0), enemyPos + vect(30, 0, 0), 0, byte(255), 0, 2);
        Outer.Pawn.DrawDebugLineTime(enemyPos - vect(0, 30, 0), enemyPos + vect(0, 30, 0), 0, byte(255), 0, 2);
    }
}

exec function dc()
{
    local private CoverLink Link;
    local private int idx;
    local private Vector EnemyDir;
    local private Actor HitActor;
    local private Vector HitNormal, botPos, ViewLocation;
    local private Rotator ViewRotation;

    Outer.GetPlayerViewPoint(ViewLocation, ViewRotation);
    if(DebugController == none)
    {
        SetDebugControllers();
    }
    HitActor = Outer.Trace(botPos, HitNormal, ViewLocation + (float(1000000) * vector(ViewRotation)), ViewLocation, true);
    if(HitActor != none)
    {
        botPos += (HitNormal * 40);
        Outer.ClientMessage("Cover Debug: Bot pos has been set");
        Outer.Pawn.DrawDebugLineTime(botPos - vect(30, 0, 0), botPos + vect(30, 0, 0), 0, byte(255), 0, 2);
        Outer.Pawn.DrawDebugLineTime(botPos - vect(0, 30, 0), botPos + vect(0, 30, 0), 0, byte(255), 0, 2);
        Outer.Pawn.DrawDebugLineTime(enemyPos - vect(30, 0, 0), enemyPos + vect(30, 0, 0), byte(255), 0, 0, 2);
        Outer.Pawn.DrawDebugLineTime(enemyPos - vect(0, 30, 0), enemyPos + vect(0, 30, 0), byte(255), 0, 0, 2);
        EnemyDir = Normal(enemyPos - botPos);
        Outer.Pawn.DrawDebugLineTime(botPos, botPos + (EnemyDir * float(300)), 0, 0, byte(255), 2);
        Link = Outer.WorldInfo.CoverList;
        J0x268:

        if(Link != none)
        {
            idx = 0;
            J0x27A:

            if(idx < Link.Slots.Length)
            {
                if(DebugController.CurrentCover.PrototypeIsCoverValid(enemyPos, Link, idx))
                {
                    Outer.Pawn.DrawDebugLineTime(Link.GetSlotLocation(idx), Link.GetSlotLocation(idx) + vect(0, 0, 100), byte(255), 0, 0, 3);
                }
                idx++;
                goto J0x27A;
            }
            Link = Link.NextCoverLink;
            goto J0x268;
        }
    }
}

exec function PS()
{
    local private Actor HitActor;
    local private Vector HitNormal, HitLocation, ViewLocation;
    local private Rotator ViewRotation;

    Outer.GetPlayerViewPoint(ViewLocation, ViewRotation);
    HitActor = Outer.Trace(HitLocation, HitNormal, ViewLocation + (float(1000000) * vector(ViewRotation)), ViewLocation, true);
    if(HitActor != none)
    {
        HitLocation += (HitNormal * 40);
        pP1 = HitLocation;
        if(DebugController == none)
        {
            SetDebugControllers();
        }
        oldPos = DebugController.Pawn.Location;
        DebugController.Pawn.SetLocation(pP1);
        DebugController.MoveTarget = none;
        DebugController.MovePoint = vect(0, 0, 0);
        Outer.ClientMessage("Pathfinding Debug: Position 1 has been set");
        Outer.Pawn.DrawDebugLineTime(pP1 - vect(30, 0, 0), pP1 + vect(30, 0, 0), 0, byte(255), 0, 1);
        Outer.Pawn.DrawDebugLineTime(pP1 - vect(0, 30, 0), pP1 + vect(0, 30, 0), 0, byte(255), 0, 1);
    }
}

exec function pe()
{
    local private Actor HitActor;
    local private Vector HitNormal, HitLocation, ViewLocation;
    local private Rotator ViewRotation;
    local private bool Success;
    local private NavigationPoint MoveGoal;

    if(DebugController == none)
    {
        SetDebugControllers();
    }
    Outer.GetPlayerViewPoint(ViewLocation, ViewRotation);
    HitActor = Outer.Trace(HitLocation, HitNormal, ViewLocation + (float(1000000) * vector(ViewRotation)), ViewLocation, true);
    if(HitActor != none)
    {
        HitLocation += (HitNormal * 40);
        pP2 = HitLocation;
        MoveGoal = DebugController.Team.GetNearestNavToPoint(pP2);
        if(Outer.Pawn.Anchor != none)
        {
            Outer.Pawn.DrawDebugSphereTime(Outer.Pawn.Anchor.Location, 10, 10, byte(255), 0, 0, 5);
        }
        if(MoveGoal != none)
        {
            Success = DebugController.SetMoveGoal(MoveGoal);
            ClientMessage("NearestNavPoint:" @ string(MoveGoal));
            Outer.Pawn.DrawDebugSphereTime(MoveGoal.Location, 10, 10, 0, 0, byte(255), 5);            
        }
        else
        {
            Success = DebugController.SetMovePoint(pP2);
            Outer.Pawn.DrawDebugSphereTime(pP2, 10, 10, 0, byte(255), 0, 5);
        }
        if(Success)
        {
            ClientMessage("Success");            
        }
        else
        {
            ClientMessage("Failed");
        }
    }
}

exec function AiRootRotation()
{
    AIGotoState('RootRotationState', true);
}

exec function GoHere()
{
    local private Actor HitActor;
    local private Vector HitNormal, HitLocation, ViewLocation;
    local private Rotator ViewRotation;

    if(DebugController == none)
    {
        SetDebugControllers();
    }
    Outer.GetPlayerViewPoint(ViewLocation, ViewRotation);
    HitActor = Outer.Trace(HitLocation, HitNormal, ViewLocation + (float(10000) * vector(ViewRotation)), ViewLocation, true);
    if((HitActor != none) && OldHitLocation != HitLocation)
    {
        HitLocation += (HitNormal * 40);
        DebugController.MoveToPos(HitLocation);
        OldHitLocation = HitLocation;
    }
}

exec function GoHereAll()
{
    local private Actor HitActor;
    local private Vector HitNormal, HitLocation, ViewLocation;
    local private Rotator ViewRotation;
    local private TdAIController C;

    if(DebugController == none)
    {
        SetDebugControllers();
    }
    Outer.GetPlayerViewPoint(ViewLocation, ViewRotation);
    HitActor = Outer.Trace(HitLocation, HitNormal, ViewLocation + (float(10000) * vector(ViewRotation)), ViewLocation, true);
    if((HitActor != none) && OldHitLocation != HitLocation)
    {
        HitLocation += (HitNormal * 40);
        foreach Outer.WorldInfo.AllControllers(Class'TdAIController', C)
        {
            C.MoveToPos(HitLocation);            
        }        
        OldHitLocation = HitLocation;
    }
}

exec function MoveStraightHere()
{
    local private Actor HitActor;
    local private Vector HitNormal, HitLocation, ViewLocation;
    local private Rotator ViewRotation;

    if(DebugController == none)
    {
        SetDebugControllers();
    }
    Outer.GetPlayerViewPoint(ViewLocation, ViewRotation);
    HitActor = Outer.Trace(HitLocation, HitNormal, ViewLocation + (float(10000) * vector(ViewRotation)), ViewLocation, true);
    if(HitActor != none)
    {
        HitLocation += (HitNormal * 40);
        if(DebugController.PointReachable(HitLocation))
        {
            DebugController.MoveStraightToPos(HitLocation);
        }
    }
}

exec function RunStraightHere()
{
    local private Actor HitActor;
    local private Vector HitNormal, HitLocation, ViewLocation;
    local private Rotator ViewRotation;

    if(DebugController == none)
    {
        SetDebugControllers();
    }
    Outer.GetPlayerViewPoint(ViewLocation, ViewRotation);
    HitActor = Outer.Trace(HitLocation, HitNormal, ViewLocation + (float(10000) * vector(ViewRotation)), ViewLocation, true);
    if(HitActor != none)
    {
        HitLocation += (HitNormal * 40);
        if(DebugController.PointReachable(HitLocation))
        {
            DebugController.Pawn.SetWalking(false);
            DebugController.MoveStraightToPos(HitLocation);
        }
    }
}

exec function RunHere()
{
    local private Actor HitActor;
    local private Vector HitNormal, HitLocation, ViewLocation;
    local private Rotator ViewRotation;

    if(DebugController == none)
    {
        SetDebugControllers();
    }
    if(true)
    {
        Outer.GetPlayerViewPoint(ViewLocation, ViewRotation);
        HitActor = Outer.Trace(HitLocation, HitNormal, ViewLocation + (float(10000) * vector(ViewRotation)), ViewLocation, true);
        if((HitActor != none) && OldHitLocation != HitLocation)
        {
            HitLocation += (HitNormal * 40);
            DebugController.RunToPos(HitLocation);
            OldHitLocation = HitLocation;
        }
    }
}

exec function HeadFocus(bool State)
{
    local private TdBotPawn IteratedActor;

    foreach Outer.AllActors(Class'TdBotPawn', IteratedActor)
    {
        IteratedActor.myController.HeadFocus.PushEnabled(State);        
    }    
}

exec function SetHeadFocusOnPlayer()
{
    local private TdBotPawn IteratedActor;

    foreach Outer.AllActors(Class'TdBotPawn', IteratedActor)
    {
        IteratedActor.myController.HeadFocus.FocusOnActor(IteratedActor.myController.Enemy, vect(0, 0, 70));
        IteratedActor.myController.HeadFocus.PushEnabled(true);        
    }    
}

exec function MoveAIHere()
{
    local private Actor HitActor;
    local private Vector HitNormal, HitLocation, ViewLocation;
    local private Rotator ViewRotation;

    if(DebugController == none)
    {
        SetDebugControllers();
    }
    Outer.GetPlayerViewPoint(ViewLocation, ViewRotation);
    HitActor = Outer.Trace(HitLocation, HitNormal, ViewLocation + (float(10000) * vector(ViewRotation)), ViewLocation, true);
    if(HitActor != none)
    {
        HitLocation += (HitNormal * 100);
        DebugController.Pawn.SetLocation(HitLocation);
    }
}

exec function ClearScreenLog()
{
    local private TdBotPawn P;

    foreach Outer.WorldInfo.AllPawns(Class'TdBotPawn', P)
    {
        P.myController.ClearScreenLog();        
    }    
}

exec function ScreenLogFilter(name C)
{
    local private TdBotPawn P;

    foreach Outer.WorldInfo.AllPawns(Class'TdBotPawn', P)
    {
        P.myController.ToggleScreenLogFilter(C);        
    }    
}

exec function AILogFilter(name C)
{
    local private TdBotPawn P;

    foreach Outer.WorldInfo.AllPawns(Class'TdBotPawn', P)
    {
        P.myController.ToggleAILogFilter(C);        
    }    
}

exec function TestReachable()
{
    local private Actor HitActor;
    local private Vector HitNormal, HitLocation, ViewLocation;
    local private Rotator ViewRotation;

    if(DebugController == none)
    {
        SetDebugControllers();
    }
    Outer.GetPlayerViewPoint(ViewLocation, ViewRotation);
    HitActor = Outer.Trace(HitLocation, HitNormal, ViewLocation + (float(10000) * vector(ViewRotation)), ViewLocation, true);
    if(HitActor != none)
    {
        DebugController.DrawDebugSphereTime(HitLocation, 10, 10, 0, byte(255), 0, 2);
        HitLocation += (HitNormal * 100);
        if(DebugController.PointReachable(HitLocation))
        {
            ClientMessage("Reachable: YES!!!", 'None');            
        }
        else
        {
            ClientMessage("Reachable: NO!!!", 'None');
        }
    }
}

exec function Roll()
{
    if((ActiveActor != none) && TdBotPawn(ActiveActor) != none)
    {
        ActiveActor.SetMove(56);
    }
}

exec function ResetAI()
{
    local private TdBotPawn IteratedActor;

    foreach Outer.AllActors(Class'TdBotPawn', IteratedActor)
    {
        IteratedActor.myController.ResetAI();        
    }    
}

exec function SpawnAt(Vector pos)
{
    if(!Outer.bGodMode)
    {
        God();
    }
    if(!Outer.IsPaused())
    {
        Outer.WorldInfo.Game.TdPause();
    }
    Outer.Pawn.SetLocation(pos);
}

exec function Training()
{
    SpawnAt(vect(-1959, 8909, -200));
}

exec function Atrium()
{
    SpawnAt(vect(-1607, 23482, 1693));
}

exec function subway()
{
    SpawnAt(vect(2928, -12080, -846));
}

exec function Platform()
{
    SpawnAt(vect(-512, -4736, -1102));
}

exec function Helicopter()
{
    SpawnAt(vect(-19489, -39218, -1540));
}

exec function rb()
{
    SpawnAt(vect(1136, -13503, 5968));
}

exec function Boss(int stage)
{
    local private TdAIController P;

    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', P)
    {
        P.SetBossStage(stage);        
    }    
}

exec function Stefan()
{
    SetDebugControllers();
    ClientMessage(("Stefan:" @ string(bStefan)) @ string(aPawn));
    if(!bStefan)
    {        
        aPawn.ConsoleCommand("SetActiveActor 1");        
        aPawn.ConsoleCommand("SetShowDebug true");        
        aPawn.ConsoleCommand("SetShowAnimTimeLine 1");        
    }
    else
    {        
        aPawn.ConsoleCommand("SetShowDebug false");        
        aPawn.ConsoleCommand("SetShowAnimTimeLine 0");
    }
    bStefan = !bStefan;
}

exec function ShowAIDebug()
{
    SetDebugControllers();    
    aPawn.ConsoleCommand("SetShowDebug true");    
    aPawn.ConsoleCommand("SetShowDebug true AI");    
    aPawn.ConsoleCommand("SetShowDebug true AIText");    
    aPawn.ConsoleCommand("SetShowDebug true AIMisc");
}

exec function TdToggleSlomo()
{
    if((Outer.WorldInfo.TimeDilation != 1) && !Outer.IsPaused())
    {
        Outer.WorldInfo.Game.SetGameSpeed(1);        
    }
    else
    {
        Outer.WorldInfo.Game.SetGameSpeed(0.1);
    }
}

exec function FootPlacement(bool bEnable)
{
    if(ActiveActor == none)
    {
        return;
    }
    ActiveActor.bEnableFootPlacement = bEnable;
}

//exec function LevelCompleted(int Index, float Time)
//{
//    Outer.OnLevelCompleted(Index, Time);
//}

exec function IsLevelUnlocked(int Index)
{
    local private TdProfileSettings Profile;

    Profile = Outer.GetProfileSettings();
    if(Profile != none)
    {
        if(Profile.IsLevelUnlocked(Index))
        {
            ClientMessage(("Level" @ string(Index)) @ "Unlocked");            
        }
        else
        {
            ClientMessage(("Level" @ string(Index)) @ " is not Unlocked");
        }
    }
}

exec function IsBagFound(int Index)
{
    local private TdProfileSettings Profile;

    Profile = Outer.GetProfileSettings();
    if(Profile != none)
    {
        if(Profile.IsHiddenBagFound(Index))
        {
            ClientMessage(("Bag" @ string(Index)) @ "Found");            
        }
        else
        {
            ClientMessage(("Bag" @ string(Index)) @ " is not found!");
        }
    }
}

exec function UnlockTT(int Index)
{
    local private TdProfileSettings Profile;

    Profile = Outer.GetProfileSettings();
    if(Profile != none)
    {
        if(Profile.UnlockTTStretch(Index))
        {
            ClientMessage(("Stretch" @ string(Index)) @ "Unlocked");            
        }
        else
        {
            ClientMessage("Failed To Unlocked Stretch" @ string(Index));
        }
    }
}

exec function CP()
{
    local private TdProfileSettings Profile;
    local private string CP1, CP2;

    Profile = Outer.GetProfileSettings();
    if(Profile != none)
    {
        Profile.GetLastSavedMap(CP1);
        Profile.GetLastSavedCheckpoint(CP2);
        ClientMessage((("LastSavedMap:" @ CP1) @ "LastSavedCP:") @ CP2);
    }
}

exec function IsTTUnlocked(int Index)
{
    local private TdProfileSettings Profile;

    Profile = Outer.GetProfileSettings();
    if(Profile != none)
    {
        if(Profile.IsTTStretchUnlocked(Index))
        {
            ClientMessage(("Stretch" @ string(Index)) @ " is Unlocked");            
        }
        else
        {
            ClientMessage(("Stretch" @ string(Index)) @ " is not Unlocked");
        }
    }
}

exec function WriteTTTime(int Stretch, int NumIntermediateTimes)
{
    local private int idx;
    local private float TotalTime;
    local private array<private float> IntermediateTimes;

    TotalTime = 0;
    IntermediateTimes.Insert(0, NumIntermediateTimes);
    idx = 0;
    J0x1E:

    if(idx < NumIntermediateTimes)
    {
        IntermediateTimes[idx] = FRand() * 10;
        ClientMessage("Creating intermediate time:" @ string(IntermediateTimes[idx]));
        TotalTime += IntermediateTimes[idx];
        idx++;
        goto J0x1E;
    }
    ClientMessage("Creating TotalTime time:" @ string(TotalTime));
    if(Outer.GetProfileSettings().SetTTTimeForStretch(byte(Stretch), TotalTime, IntermediateTimes))
    {
        ClientMessage("Wrote intermediate times");        
    }
    else
    {
        ClientMessage("Failed to write intermediate times");
    }
}

exec function ReadTTTime(int Stretch)
{
    local private int idx;
    local private float TotalTime;
    local private array<private float> IntermediateTimes;

    if(Outer.GetProfileSettings().GetTTTimeForStretch(byte(Stretch), TotalTime, IntermediateTimes))
    {
        ClientMessage("TotalTime=" @ string(TotalTime));
        idx = 0;
        J0x56:

        if(idx < IntermediateTimes.Length)
        {
            ClientMessage((("IntermediateTime" $ string(idx)) $ "=") @ string(IntermediateTimes[idx]));
            idx++;
            goto J0x56;
        }        
    }
    else
    {
        ClientMessage("Failed to get intermediate times");
    }
}

exec function DefaultProfile()
{
    Outer.GetProfileSettings().SetToDefaults();
}

exec function SaveProfile()
{
    Outer.OnlinePlayerData.SaveProfileData();
}

defaultproperties
{
    NoclipFlyFasterKey = "E"
    NoclipFlyslowerKey = "Q"
}