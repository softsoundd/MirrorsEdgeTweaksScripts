class PrototypeCheats extends CheatManager within TdPlayerController;

var private Vector P1;
var private Vector P2;
var private Vector oldPos;
var private TdAIController DebugController;
var private Pawn aPawn;
var private Vector OldHitLocation;
var private bool bStefan;
var private bool bShowTestAnimHud;
var private float SlomoSpeed;
var private Vector enemyPos;
var private TdPawn ActiveActor;

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

/* exec function Invisible()
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
        foreach Outer.WorldInfo.AllControllers(Class'TdAIController', P)
        {
            P.PawnFocus.SetFocus(0);
            P.PawnFocus.Outer.SetWantedFocus(0);
            P.myEnemy = none;
            P.Enemy = none;
            P.EnemyVisible = false;
            P.StopFiring();
            P.UpdateCombatState();
            P.Team.CheckedLastSeenLocation = false;
            P.Team.LastSeenLocation = vect(0, 0, 0);
            P.Team.Enemy = none;
            P.Team.ForgetEnemy();
            P.Team.Reset();
            P.TdGotoState('Idle',,,, true);            
        }        
    }
} */

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

/* exec function ToggleAIFocus()
{
    local private TdAIController P;

    foreach Outer.WorldInfo.AllControllers(Class'TdAIController', P)
    {
        if(P.WantedFocus == 2)
        {
            P.SetWantedFocus(0);
            continue;
        }
        P.SetWantedFocus(2);        
    }    
} */

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
        P1 = HitLocation;
        if(DebugController == none)
        {
            SetDebugControllers();
        }
        oldPos = DebugController.Pawn.Location;
        DebugController.Pawn.SetLocation(P1);
        DebugController.MoveTarget = none;
        DebugController.MovePoint = vect(0, 0, 0);
        Outer.ClientMessage("Pathfinding Debug: Position 1 has been set");
        Outer.Pawn.DrawDebugLineTime(P1 - vect(30, 0, 0), P1 + vect(30, 0, 0), 0, byte(255), 0, 1);
        Outer.Pawn.DrawDebugLineTime(P1 - vect(0, 30, 0), P1 + vect(0, 30, 0), 0, byte(255), 0, 1);
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
        P2 = HitLocation;
        MoveGoal = DebugController.Team.GetNearestNavToPoint(P2);
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
            Success = DebugController.SetMovePoint(P2);
            Outer.Pawn.DrawDebugSphereTime(P2, 10, 10, 0, byte(255), 0, 5);
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

exec function Spawn()
{
    Outer.Pawn.SetLocation(vect(-1959, 8909, -200));
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

exec function KillAllButOne()
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
    foreach Outer.WorldInfo.AllPawns(Class'TdBotPawn', P)
    {
        if(P != closest)
        {
            P.TakeDamage(9999, none, vect(0, 0, 0), vect(0, 0, 0), Class'TdDmgType_Melee');
        }        
    }    
}

defaultproperties
{
    SlomoSpeed=1
}