class SofTimerTutorialHUD extends TdTutorialHUD
    transient
    config(Game)
    hidecategories(Navigation);

var SaveLoadHandler SaveLoad;
var UIDataStore_TdGameData GameData;
var(HUDIcons) Vector2D     TimerPos;
var TdPlayerController     SpeedrunController;
var bool                   bLoadedTimeFromSave;
var int                    SkipTicks;


event PostBeginPlay()
{
    local DataStoreClient DataStoreManager;
    local string MapName;

    super(TdHUD).PostBeginPlay();
    DataStoreManager = Class'UIInteraction'.static.GetDataStoreClient();
    GameData = UIDataStore_TdGameData(DataStoreManager.FindDataStore('TdGameData'));

    MapName = WorldInfo.GetMapName();
    
    if (MapName != "TdMainMenu")
    {
        SkipTicks = 3;
        ConsoleCommand("set DOFAndBloomEffect BloomScale 0.1");
    }
    else
    {
        SkipTicks = 0;
        ConsoleCommand("set DOFAndBloomEffect BloomScale 0");
    }

    GameData.TimeAttackClock = 0;
}

function Tick(float DeltaTime)
{
    local float RealDeltaTime;
    super.Tick(DeltaTime);

    if (SkipTicks > 0)
    {
        SkipTicks--;
        return;
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
    
    if (SaveLoad == none)
    {
        SaveLoad = new class'SaveLoadHandler';
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

event Destroyed()
{
    if (SaveLoad == none)
    {
         SaveLoad = new class'SaveLoadHandler';
    }
    SaveLoad.SaveData("TimeAttackClock", string(GameData.TimeAttackClock));
    
    super.Destroyed();
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

function DrawLivingHUD()
{
    local TdSPTutorialGame Game;

    Game = TdSPTutorialGame(WorldInfo.Game);
    super(TdTutorialHUD).DrawLivingHUD();

    if(Game != none)
    {
        if(ShouldIncrementTimer())
        {
            DrawLoadRemovedTimer(Game, true);            
        }
        else
        {
            if((WorldInfo.TimeSeconds - float(int(WorldInfo.TimeSeconds))) < 0.5)
            {
                DrawLoadRemovedTimer(Game, true);                
            }
            else
            {
                DrawLoadRemovedTimer(Game, false);
            }
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

defaultproperties
{
    TimerPos=(X=1000,Y=55)
}