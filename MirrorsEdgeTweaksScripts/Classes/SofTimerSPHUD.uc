class SofTimerSPHUD extends TdSPHUD
    transient
    config(Game)
    hidecategories(Navigation);

var SaveLoadHandlerSTHUD     SaveLoad;
var UIDataStore_TdGameData   GameData;
var TdPlayerController  SpeedrunController;
var TdProfileSettings   Profile;
var(HUDIcons) Vector2D  TimerPos;
var(HUDIcons) Vector2D  SplitPos;
var(HUDIcons) Vector2D  SpeedPos;
var transient string    SpeedUnitString;
var transient int       MeasurementUnits;
var bool                bTimerVisible;

var bool              bLoadedTimeFromSave;
var bool              bUndeclaredLoadActive;
var bool              bDeclaredUnloadActive;
var float             LastDeclaredUnloadTime;
var int               SkipTicks;
var bool              bLevelCompleted;
var float             LastSplitTime;

var transient bool    bHasEverStartedNewGame;
var transient bool    bLoadedTimeFromProfileThisSession;

// Chapter 4 (Subway) variables
var bool              bAfterElevatorCrash;

// Chapter 5 (Mall) variables.
var bool              bRemovedMallUnload;

// Chapter 6 (Factory) variables
var bool              bEnteredLoadingBay;

// Chapter 9 (Scraper) variables.
var bool              bHeliExists;
var bool              bKillBotsFired;
var bool              bHeliReadyForGrab;
var bool              b1PAnimPlayed;
var bool              bTouchedDeathVolume;

// Run completion variables
var bool              bFinalTimeLocked;
var int               RunCompleteLiveSplitASLMarker;
var bool              RunComplete;

// These arrays list the streaming level package names that get loaded and should increment the timer (RTA).
// Any level NOT declared here is assumed to be LRT and is caught by IsLoadingLevel in the ticking function.
var array<string>     DeclaredLoadPackages_Edge;      // Prologue (Edge_p)
var array<string>     DeclaredLoadPackages_Escape;    // Chapter 1 (Escape_p)
// For Chapter 2 (Stormdrain_p) we use two lists: one for gate packages and one for non–gate packages.
var array<string>     DeclaredLoadPackages_StormdrainGate;
var array<string>     DeclaredLoadPackages_Stormdrain;
var array<string>     DeclaredLoadPackages_Cranes;    // Chapter 3 (Cranes_p)
var array<string>     DeclaredLoadPackages_Subway;    // Chapter 4 (Subway_p)
var array<string>     DeclaredLoadPackages_Mall;      // Chapter 5 (Mall_p)
var array<string>     DeclaredLoadPackages_Factory;   // Chapter 6 (Factory_p)
var array<string>     DeclaredLoadPackages_Boat;      // Chapter 7 (Boat_p)
var array<string>     DeclaredLoadPackages_Convoy;    // Chapter 8 (Convoy_p)
var array<string>     DeclaredLoadPackages_Scraper;   // Chapter 9 (Scraper_p)
var array<string>     DeclaredLoadPackages_TdMainMenu;

// These arrays list the streaming level package names that get unloaded and should pause the timer (LRT).
var array<string>     DeclaredUnloadPackages_Edge;      // Prologue (Edge_p)
var array<string>     DeclaredUnloadPackages_Escape;    // Chapter 1 (Escape_p)
var array<string>     DeclaredUnloadPackages_StormdrainGate;
var array<string>     DeclaredUnloadPackages_Stormdrain;
var array<string>     DeclaredUnloadPackages_Cranes;    // Chapter 3 (Cranes_p)
var array<string>     DeclaredUnloadPackages_Subway;    // Chapter 4 (Subway_p)
var array<string>     DeclaredUnloadPackages_Mall;      // Chapter 5 (Mall_p)
var array<string>     DeclaredUnloadPackages_Factory;   // Chapter 6 (Factory_p)
var array<string>     DeclaredUnloadPackages_Boat;      // Chapter 7 (Boat_p)
var array<string>     DeclaredUnloadPackages_Convoy;    // Chapter 8 (Convoy_p)
var array<string>     DeclaredUnloadPackages_Scraper;   // Chapter 9 (Scraper_p)

var bool              HundredPercentMode;
var bool              ShowBagHUD;
var bool              bBagPopUpCalled;
var bool              bWasCinematicMode;

var bool              SoundFix;

// Trainer, macro, speed variables
var vector            CurrentLocation;
var rotator           CurrentRotation;
var float             PlayerSpeed;
var vector            ConvertedLocation, PlayerVelocity;

var float             MaxVelocity, MaxHeight;
var float             LastMaxVelocityUpdateTime, LastMaxHeightUpdateTime;
var float             UpdateInterval;

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


function PreBeginPlay()
{
    super(Actor).PreBeginPlay();
    LinkHUDContent();   
}

event PostBeginPlay()
{
    local DataStoreClient DataStoreManager;
    local string MapName;
    local string SubwayFlagStr;
    local string MallFlagStr;
    local string LoadingBayFlagStr;
    local string FinalTimeFlag;
    local string SavedShowBagHUD;

    super.PostBeginPlay();
    DataStoreManager = Class'UIInteraction'.static.GetDataStoreClient();
    GameData = UIDataStore_TdGameData(DataStoreManager.FindDataStore('TdGameData'));

    MapName = WorldInfo.GetMapName();
    
    // On spawn, skip the next tick to avoid the extra clamped DeltaTime
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
        SaveLoad = new class'SaveLoadHandlerSTHUD';
    }

    // Load the flag that indicates if a new game has ever been started for the active game session
    // This stops the timer automatically incrementing in the main menu when we first enable speedrun mode
    bHasEverStartedNewGame = (SaveLoad.LoadData("HasEverStartedNewGame") == "true");

    if (MapName != "TdMainMenu" && !bHasEverStartedNewGame)
    {
        bHasEverStartedNewGame = true;
        SaveLoad.SaveData("HasEverStartedNewGame", "true");
    }

    if (SpeedrunController == none && PlayerOwner != none)
    {
        SpeedrunController = TdPlayerController(PlayerOwner);
    }
    if (Profile == none && SpeedrunController != none)
    {
        Profile = SpeedrunController.GetProfileSettings();
    }

    // Check if we've already loaded from the profile in this game session
    bLoadedTimeFromProfileThisSession = (SaveLoad.LoadData("bLoadedTimeFromProfileThisSession") == "true");

    // If this is the first time loading a map in this session (and it's not a new game), attempt to load the saved time from the game's save file
    if (Profile != none && MapName != "TdMainMenu" && !bLoadedTimeFromProfileThisSession)
    {
        LoadSavedCheckpointTime();
        
        bLoadedTimeFromProfileThisSession = true;
        SaveLoad.SaveData("bLoadedTimeFromProfileThisSession", "true");

        SaveLoad.SaveData("TimeAttackClock", string(GameData.TimeAttackClock));
    }

    CacheMeasurementUnitInfo();

    // Speedrun settings
    HundredPercentMode = (SaveLoad.LoadData("HundredPercentMode") == "") ? false : bool(SaveLoad.LoadData("HundredPercentMode"));
    SoundFix = (SaveLoad.LoadData("SoundFix") == "") ? false : bool(SaveLoad.LoadData("SoundFix"));

    // Speedrun HUD elements
    bTimerVisible = (SaveLoad.LoadData("TimerHUDVisible") == "") ? true : bool(SaveLoad.LoadData("TimerHUDVisible"));
    ShowSpeed = (SaveLoad.LoadData("ShowSpeed") == "") ? false : bool(SaveLoad.LoadData("ShowSpeed"));
    ShowTrainerHUDItems = (SaveLoad.LoadData("ShowTrainerHUDItems") == "") ? false : bool(SaveLoad.LoadData("ShowTrainerHUDItems"));
    ShowMacroFeedback = (SaveLoad.LoadData("ShowMacroFeedback") == "") ? false : bool(SaveLoad.LoadData("ShowMacroFeedback"));

    SavedShowBagHUD = SaveLoad.LoadData("ShowBagHUD");
    if (SavedShowBagHUD == "")
    {
        ShowBagHUD = HundredPercentMode;
    }
    else
    {
        ShowBagHUD = bool(SavedShowBagHUD);
    }
    bBagPopUpCalled = false;
    bWasCinematicMode = SpeedrunController.bCinematicMode;

    ConsoleCommand("set TdSPHUD PopUpPos (X=96,Y=70)");
    
    // Initialise the max values and timers
    MaxVelocity = 0.0;
    MaxHeight = 0.0;
    LastMaxVelocityUpdateTime = WorldInfo.TimeSeconds;
    LastMaxHeightUpdateTime = WorldInfo.TimeSeconds;
    UpdateInterval = 3.0;

    // --- Initialise level packages for each chapter. Unless otherwise changed by inbounds routes, declared loads are RTA and declared unloads are LRT ---

    if (MapName == "Edge_p")
    {
        // Reset any monitoring from previous runs
        bFinalTimeLocked = false;
        RunCompleteLiveSplitASLMarker = 123456789;
        SaveLoad.SaveData("FinalTimeLocked", "false");

        if (HundredPercentMode)
        {
            SetCollectedBagsCount(0);
        }

        SaveLoad.SaveData("AfterElevatorCrashTriggered", "false");
        SaveLoad.SaveData("MallUnloadRemoved", "false");
        SaveLoad.SaveData("LoadingBayEntered", "false");

        // Prologue packages (Edge_p)   
        DeclaredLoadPackages_Edge.AddItem("Edge_Pt2"); // vent start
        DeclaredLoadPackages_Edge.AddItem("Edge_Pt2_Art");
        DeclaredLoadPackages_Edge.AddItem("Edge_Pt2_Lw");
        DeclaredLoadPackages_Edge.AddItem("Edge_Pt2_Bac");
        DeclaredLoadPackages_Edge.AddItem("Edge_Pt2_Spt");
        DeclaredLoadPackages_Edge.AddItem("Edge_Pt2_Aud"); // vent end
    }

    // Chapter 1 (Escape_p)
    else if (MapName == "Escape_p")
    {
        DeclaredLoadPackages_Escape.AddItem("Escape_Off-R1_Spt"); // after Kate cutscene
        DeclaredLoadPackages_Escape.AddItem("Escape_R1"); // ch1 skip start
        DeclaredLoadPackages_Escape.AddItem("Escape_R1_Art");
        DeclaredLoadPackages_Escape.AddItem("Escape_R1_Aud");
        DeclaredLoadPackages_Escape.AddItem("Escape_R1_Bac");
        DeclaredLoadPackages_Escape.AddItem("Escape_R1_Spt");
        DeclaredLoadPackages_Escape.AddItem("Escape_R1_LW");
        DeclaredLoadPackages_Escape.AddItem("Escape_R1_Lgts"); // ch1 skip end
        DeclaredLoadPackages_Escape.AddItem("Escape_R1-R2_Slc"); // landing pad start
        DeclaredLoadPackages_Escape.AddItem("Escape_R1-R2_Aud");
        DeclaredLoadPackages_Escape.AddItem("Escape_R1-St1_Spt");
        DeclaredLoadPackages_Escape.AddItem("Escape_R1-R2_Slc_lgts");
        DeclaredLoadPackages_Escape.AddItem("Edge_SL01_Mus"); // landing pad end
        DeclaredLoadPackages_Escape.AddItem("Escape_St1-Plaza_Slc"); // plaza elev start
        DeclaredLoadPackages_Escape.AddItem("Escape_St1-Plaza_Spt");
        DeclaredLoadPackages_Escape.AddItem("Escape_St1-Plaza_Aud");
        DeclaredLoadPackages_Escape.AddItem("Escape_St1-Plaza_Slc_Lgts"); // plaza elev end
        DeclaredLoadPackages_Escape.AddItem("Escape_Plaza"); // plaza start
        DeclaredLoadPackages_Escape.AddItem("Escape_Plaza_Spt");
        DeclaredLoadPackages_Escape.AddItem("Escape_Plaza_Art");
        DeclaredLoadPackages_Escape.AddItem("Escape_Plaza_Aud");
        DeclaredLoadPackages_Escape.AddItem("Escape_Plaza_LW");
        DeclaredLoadPackages_Escape.AddItem("Escape_Plaza_Bac");
        DeclaredLoadPackages_Escape.AddItem("Escape_Plaza_Lgts"); // plaza end

        DeclaredUnloadPackages_Escape.AddItem("Escape_Intro"); // office elev start
        DeclaredUnloadPackages_Escape.AddItem("Escape_Intro_Art");
        DeclaredUnloadPackages_Escape.AddItem("Escape_Intro_Aud");
        DeclaredUnloadPackages_Escape.AddItem("Escape_Intro_Bac");
        DeclaredUnloadPackages_Escape.AddItem("Escape_Intro_LW");
        DeclaredUnloadPackages_Escape.AddItem("Escape_Intro_Spt");
        DeclaredUnloadPackages_Escape.AddItem("Escape_Intro_Lgts"); // office elev end
        DeclaredUnloadPackages_Escape.AddItem("Escape_Off_Bac"); // plaza elev start
        DeclaredUnloadPackages_Escape.AddItem("Escape_Off-R1_Bac");
        DeclaredUnloadPackages_Escape.AddItem("Escape_R1");
        DeclaredUnloadPackages_Escape.AddItem("Escape_R1_Art");
        DeclaredUnloadPackages_Escape.AddItem("Escape_R1_Aud");
        DeclaredUnloadPackages_Escape.AddItem("Escape_R1_Bac");
        DeclaredUnloadPackages_Escape.AddItem("Escape_R1_Spt");
        DeclaredUnloadPackages_Escape.AddItem("Escape_R1_LW");
        DeclaredUnloadPackages_Escape.AddItem("Escape_R1_Lgts");
        DeclaredUnloadPackages_Escape.AddItem("Escape_R1-R2_Slc");
        DeclaredUnloadPackages_Escape.AddItem("Escape_R1-R2_Aud");
        DeclaredUnloadPackages_Escape.AddItem("Escape_R1-R2_Slc_lgts");
        DeclaredUnloadPackages_Escape.AddItem("Edge_SB01_Mus"); // plaza elev end
    }

    // Stormdrain (Chapter 2)
    else if (MapName == "Stormdrain_p")
    {
        // Gate packages are RTA but switch to LRT if we pressed either gate button before levels finished loading
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdP"); // sd gate 1 start
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdP_Art");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdP_Aud");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdP_Bac");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdP_Spt");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdP_Lgts");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdP-StdE_slc");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdP-StdE_slc_Spt");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdP-StdE_Aud");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdP-StdE_slc_Lgts"); // sd gate 1 end
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdE"); // sd gate 2 start
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdE_Art");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdE_Aud");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdE_Bac");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdE_Spt");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdE_Lgts");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdE-Out_Blding_slc");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdE_Roof_Bac");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_bac");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_Std_StdE_Bac");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_StdE_Roof_boss_Bac");
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_Ext_Lgts"); 
        DeclaredLoadPackages_StormdrainGate.AddItem("Stormdrain_SB02_Mus"); // sd gate 2 end
        
        // All other normal Stormdrain packages
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_Std"); // sluice start (inbounds)
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_Std_Art");
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_Std_Aud");
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_Std_Bac");
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_Std_Spt");
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_Std_Lgts");
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_Std-StdP_Slc");
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_Std-StdP_Slc_Spt");
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_Std-StdP_Aud");
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_Std-StdP_slc_Lgts"); // sluice end (inbounds)
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_SL01_Mus"); // sd zipline
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_StdE-Out_slc_Spt"); // sd gate 2 close start
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_StdE-Out_Aud");
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_StdE-Out_slc_lgts"); // sd gate 2 close end
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_boss_Slc"); // part of first JK elevator (we remove this if MonitorJKLevelLoadsAfterFirstElevator is true)
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_boss_Slc_spt"); // part of first JK elevator (we remove this if MonitorJKLevelLoadsAfterFirstElevator is true)
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_boss_Slc_Lgts"); // part of first JK elevator (we remove this if MonitorJKLevelLoadsAfterFirstElevator is true)
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_boss"); // part of first JK elevator (we remove this if MonitorJKLevelLoadsAfterFirstElevator is true)
        DeclaredLoadPackages_Stormdrain.AddItem("Stormdrain_boss_Aud"); // part of first JK elevator (we remove this if MonitorJKLevelLoadsAfterFirstElevator is true)

        DeclaredUnloadPackages_Stormdrain.AddItem("Stormdrain_StdP-StdE_slc_Spt"); // sd roof elev start
        DeclaredUnloadPackages_Stormdrain.AddItem("Stormdrain_StdE");
        DeclaredUnloadPackages_Stormdrain.AddItem("Stormdrain_StdE_Art");
        DeclaredUnloadPackages_Stormdrain.AddItem("Stormdrain_StdE_Aud"); // sd roof elev end
        DeclaredUnloadPackages_Stormdrain.AddItem("Stormdrain_StdE-Out_Blding_slc"); // jk elev start
        DeclaredUnloadPackages_Stormdrain.AddItem("Stormdrain_Roof");
        DeclaredUnloadPackages_Stormdrain.AddItem("Stormdrain_Roof_Art");
        DeclaredUnloadPackages_Stormdrain.AddItem("Stormdrain_Roof_Bac");
        DeclaredUnloadPackages_Stormdrain.AddItem("Stormdrain_Roof_spt"); // jk elev end
    }

    // Chapter 3 (Cranes_p)
    else if (MapName == "Cranes_p")
    {
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Off"); // first door start (inbounds)
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Off_Art");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Off_Aud");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Off_Bac");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Off_Spt");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Off_Ropeburn_CS");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Off_Lgts"); // first door end (inbounds)
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Off-Roof_Slc"); // ropeburn office start (inbounds)
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Off-Roof_Spt");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Off-Roof_Slc_Lgts");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Off-Roof_Aud");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Off-Roof_Building"); // ropeburn office end (inbounds)
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Roof"); // broken elev start
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Roof_Art");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Roof_Aud");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Roof_Bac");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Roof_Bac2");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Roof_Spt");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Roof_LW");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Roof-Plaza_Slc");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Roof-Plaza_Spt");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Roof-Plaza_Slc_Lgts");
        DeclaredLoadPackages_Cranes.AddItem("Cranes_Roof-Plaza_Aud"); // broken elev end
        DeclaredLoadPackages_Cranes.AddItem("Cranes_SL01_Mus"); // zipline
        DeclaredLoadPackages_Cranes.AddItem("Cranes_SB02_Mus"); // heli rappel

        DeclaredUnloadPackages_Cranes.AddItem("Cranes_Puzz_Bac2");
        DeclaredUnloadPackages_Cranes.AddItem("Cranes_Off-Roof_Building");
        DeclaredUnloadPackages_Cranes.AddItem("Cranes_Roof");
        DeclaredUnloadPackages_Cranes.AddItem("Cranes_Roof_Art");
        DeclaredUnloadPackages_Cranes.AddItem("Cranes_Roof_Aud");
        DeclaredUnloadPackages_Cranes.AddItem("Cranes_Roof_Bac");
        DeclaredUnloadPackages_Cranes.AddItem("Cranes_Roof_Spt");
        DeclaredUnloadPackages_Cranes.AddItem("Cranes_Roof_LW");
    }

    // Chapter 4 (Subway_p)
    else if (MapName == "Subway_p")
    {
        DeclaredLoadPackages_Subway.AddItem("Subway_Ren"); // renovation start (inbounds)
        DeclaredLoadPackages_Subway.AddItem("Subway_Ren_Spt");
        DeclaredLoadPackages_Subway.AddItem("Subway_Ren_Art");
        DeclaredLoadPackages_Subway.AddItem("Subway_Ren_Spt");
        DeclaredLoadPackages_Subway.AddItem("Subway_Ren_Aud");
        DeclaredLoadPackages_Subway.AddItem("Subway_Ren_Lgts");
        DeclaredLoadPackages_Subway.AddItem("Subway_Ren-RenCo_Slc");
        DeclaredLoadPackages_Subway.AddItem("Subway_Ren-RenCo_Spt");
        DeclaredLoadPackages_Subway.AddItem("Subway_Ren-RenCo_ASlc");
        DeclaredLoadPackages_Subway.AddItem("Subway_Ren-RenCo_Slc_Lgts"); // renovation end (inbounds)
        DeclaredLoadPackages_Subway.AddItem("Subway_RenBuilding"); // gas valve start (inbounds)
        DeclaredLoadPackages_Subway.AddItem("Subway_RenCo");
        DeclaredLoadPackages_Subway.AddItem("Subway_RenCo_Aud");
        DeclaredLoadPackages_Subway.AddItem("Subway_RbMiller_CS");
        DeclaredLoadPackages_Subway.AddItem("Subway_Roof-RenCo_Slc");
        DeclaredLoadPackages_Subway.AddItem("Subway_Roof-RenCo_Spt");
        DeclaredLoadPackages_Subway.AddItem("Subway_Roof-RenCo_ASlc");
        DeclaredLoadPackages_Subway.AddItem("Subway_Bac");
        DeclaredLoadPackages_Subway.AddItem("Subway_BacSub");
        DeclaredLoadPackages_Subway.AddItem("Subway_Ext_Lgts"); // gas valve end (inbounds)
        DeclaredLoadPackages_Subway.AddItem("Subway_RenCo_Door"); // rb miller start (inbounds)
        DeclaredLoadPackages_Subway.AddItem("Subway_Roof"); 
        DeclaredLoadPackages_Subway.AddItem("Subway_Roof_Art");
        DeclaredLoadPackages_Subway.AddItem("Subway_Roof_Aud");
        DeclaredLoadPackages_Subway.AddItem("Subway_Roof_Spt");
        DeclaredLoadPackages_Subway.AddItem("Subway_Roof_LW"); // rb miller end (inbounds)
        DeclaredLoadPackages_Subway.AddItem("Subway_RenCo_Spt"); // after rb death start (inbounds)
        DeclaredLoadPackages_Subway.AddItem("Subway_Elev");
        DeclaredLoadPackages_Subway.AddItem("Subway_Elev_Spt");
        DeclaredLoadPackages_Subway.AddItem("Subway_Elev_Aud");
        DeclaredLoadPackages_Subway.AddItem("Subway_Chase-Stat_Slc");
        DeclaredLoadPackages_Subway.AddItem("Subway_Chase-Stat_Spt");
        DeclaredLoadPackages_Subway.AddItem("Subway_Chase-Stat_ASlc");
        DeclaredLoadPackages_Subway.AddItem("Subway_Chase-Stat_Slc_Lgts"); // after rb death end (inbounds)
        DeclaredLoadPackages_Subway.AddItem("Subway_SL01_Mus"); // elev crash start (inbounds)
        DeclaredLoadPackages_Subway.AddItem("Subway_Stat");
        DeclaredLoadPackages_Subway.AddItem("Subway_Stat_Spt");
        DeclaredLoadPackages_Subway.AddItem("Subway_Stat_Art");
        DeclaredLoadPackages_Subway.AddItem("Subway_Stat_Aud");
        DeclaredLoadPackages_Subway.AddItem("Subway_Stat_Lgts");
        DeclaredLoadPackages_Subway.AddItem("Subway_BacSub"); // elev crash end (inbounds)
        DeclaredLoadPackages_Subway.AddItem("Subway_Plat_Spt");
        DeclaredLoadPackages_Subway.AddItem("Subway_Plat_Art");
        DeclaredLoadPackages_Subway.AddItem("Subway_Plat_Aud");
        DeclaredLoadPackages_Subway.AddItem("Subway_Plat_Lgts");
        DeclaredLoadPackages_Subway.AddItem("Subway_Plat-Tunnel_Slc");
        DeclaredLoadPackages_Subway.AddItem("Subway_Plat-Tunnel_Spt");
        DeclaredLoadPackages_Subway.AddItem("Subway_Plat-Tunnel_ASlc");
        DeclaredLoadPackages_Subway.AddItem("Subway_Plat-Tunnel_Slc_Lgts"); // subway platform end (inbounds)
        DeclaredLoadPackages_Subway.AddItem("Subway_Tunnel"); // subway tunnel start
        DeclaredLoadPackages_Subway.AddItem("Subway_Tunnel_Art");
        DeclaredLoadPackages_Subway.AddItem("Subway_Tunnel_Aud");
        DeclaredLoadPackages_Subway.AddItem("Subway_Tunnel_Spt");
        DeclaredLoadPackages_Subway.AddItem("Subway_Tunnel_Lgts");
        DeclaredLoadPackages_Subway.AddItem("Subway_FanP");
        DeclaredLoadPackages_Subway.AddItem("Subway_FanP_Aud");
        DeclaredLoadPackages_Subway.AddItem("Subway_FanP_Spt");
        DeclaredLoadPackages_Subway.AddItem("Subway_FanP_Lgts"); // subway tunnel end
        DeclaredLoadPackages_Subway.AddItem("Subway_Sky"); // fan room start
        DeclaredLoadPackages_Subway.AddItem("Subway_Train_Spt");
        DeclaredLoadPackages_Subway.AddItem("Subway_Train");
        DeclaredLoadPackages_Subway.AddItem("Subway_Train_Art");
        DeclaredLoadPackages_Subway.AddItem("Subway_Train_Aud");
        DeclaredLoadPackages_Subway.AddItem("Subway_NxtPlat");
        DeclaredLoadPackages_Subway.AddItem("Subway_NxtPlat_Art");
        DeclaredLoadPackages_Subway.AddItem("Subway_NxtPlat_Aud");
        DeclaredLoadPackages_Subway.AddItem("Subway_NxtPlat_Spt"); // fan room end

        DeclaredUnloadPackages_Subway.AddItem("Subway_Sky");
        SubwayFlagStr = SaveLoad.LoadData("AfterElevatorCrashTriggered");
        if (SubwayFlagStr == "true" && !bAfterElevatorCrash)
        {
            if (!IsPackageInList("Subway_Plat", DeclaredLoadPackages_Subway))
            {
                DeclaredLoadPackages_Subway.AddItem("Subway_Plat");
            }
            if (!IsPackageInList("Subway_Stat-Plat_Slc", DeclaredLoadPackages_Subway))
            {
                DeclaredLoadPackages_Subway.AddItem("Subway_Stat-Plat_Slc");
            }
            if (!IsPackageInList("Subway_Stat-Plat_Spt", DeclaredLoadPackages_Subway))
            {
                DeclaredLoadPackages_Subway.AddItem("Subway_Stat-Plat_Spt");
            }
            if (!IsPackageInList("Subway_Stat-Plat_ASlc", DeclaredLoadPackages_Subway))
            {
                DeclaredLoadPackages_Subway.AddItem("Subway_Stat-Plat_ASlc");
            }
            if (!IsPackageInList("Subway_Stat-Plat_Lgts", DeclaredLoadPackages_Subway))
            {
                DeclaredLoadPackages_Subway.AddItem("Subway_Stat-Plat_Lgts");
            }

            RemovePackageIfPresent(DeclaredUnloadPackages_Subway, "Subway_Sky");
            bAfterElevatorCrash = true;
        }
    }

    // Chapter 5 (Mall_p)
    else if (MapName == "Mall_p")
    {
        DeclaredLoadPackages_Mall.AddItem("Mall_R1_Spt"); // before elev
        DeclaredLoadPackages_Mall.AddItem("Mall_R2"); // elev shaft start
        DeclaredLoadPackages_Mall.AddItem("Mall_R2_Art");
        DeclaredLoadPackages_Mall.AddItem("Mall_R2_Aud");
        DeclaredLoadPackages_Mall.AddItem("Mall_R2_Bac");
        DeclaredLoadPackages_Mall.AddItem("Mall_R2_Spt");
        DeclaredLoadPackages_Mall.AddItem("Mall_R2_LW");
        DeclaredLoadPackages_Mall.AddItem("Mall_R2_Lgts");
        DeclaredLoadPackages_Mall.AddItem("Mall_R2-Mall_Slc");
        DeclaredLoadPackages_Mall.AddItem("Mall_R2-Mall_Slc_Spt");
        DeclaredLoadPackages_Mall.AddItem("Mall_R2-Mall_Slc_Building");
        DeclaredLoadPackages_Mall.AddItem("Mall_R2-Mall_Aud");
        DeclaredLoadPackages_Mall.AddItem("Mall_R2-Mall_Slc_Lgts");
        DeclaredLoadPackages_Mall.AddItem("Mall_SL01_Mus"); // elev shaft end
        DeclaredLoadPackages_Mall.AddItem("Mall_SB02_Mus"); // pipe climb
        DeclaredLoadPackages_Mall.AddItem("Mall_Mall_Art_Pt2"); // beamer start
        DeclaredLoadPackages_Mall.AddItem("Mall_Mall_Lgts_Pt2"); // beamer end
        DeclaredLoadPackages_Mall.AddItem("Mall_Mall-Roof_Slc"); // blue room vent start
        DeclaredLoadPackages_Mall.AddItem("Mall_Mall-Roof_Spt");
        DeclaredLoadPackages_Mall.AddItem("Mall_Mall-Roof_Aud");
        DeclaredLoadPackages_Mall.AddItem("Mall_Mall-Roof_Lgts");
        DeclaredLoadPackages_Mall.AddItem("Mall_Roof_Bac"); // blue room vent end
        DeclaredLoadPackages_Mall.AddItem("Mall_Mall_Bac"); // final roof start
        DeclaredLoadPackages_Mall.AddItem("Mall_Mall-Roof_Bac");
        DeclaredLoadPackages_Mall.AddItem("Mall_Roof");
        DeclaredLoadPackages_Mall.AddItem("Mall_Roof_Art");
        DeclaredLoadPackages_Mall.AddItem("Mall_Roof_Aud");
        DeclaredLoadPackages_Mall.AddItem("Mall_Roof_Spt");
        DeclaredLoadPackages_Mall.AddItem("Mall_Roof_Lgts"); // final roof end

        DeclaredUnloadPackages_Mall.AddItem("Mall_HW-R1_Slc"); // first elev start
        DeclaredUnloadPackages_Mall.AddItem("Mall_HW-R1_Aud");
        DeclaredUnloadPackages_Mall.AddItem("Mall_HW-R1_Lgts"); // first elev end
        MallFlagStr = SaveLoad.LoadData("MallUnloadRemoved");
        if (MallFlagStr == "true" && !bRemovedMallUnload)
        {
            RemovePackageIfPresent(DeclaredUnloadPackages_Mall, "Mall_HW-R1_Aud");
            RemovePackageIfPresent(DeclaredUnloadPackages_Mall, "Mall_HW-R1_Lgts");
            bRemovedMallUnload = true;
        }
        DeclaredUnloadPackages_Mall.AddItem("Mall_bac"); // mall elev start
        DeclaredUnloadPackages_Mall.AddItem("Mall_bac");
        DeclaredUnloadPackages_Mall.AddItem("Mall_R1-R2_Slc");
        DeclaredUnloadPackages_Mall.AddItem("Mall_R1-R2_Bac");
        DeclaredUnloadPackages_Mall.AddItem("Mall_R1-R2_Aud");
        DeclaredUnloadPackages_Mall.AddItem("Mall_R1-R2_Lgts");
        DeclaredUnloadPackages_Mall.AddItem("Mall_R2");
        DeclaredUnloadPackages_Mall.AddItem("Mall_R2_Art");
        DeclaredUnloadPackages_Mall.AddItem("Mall_R2_Aud");
        DeclaredUnloadPackages_Mall.AddItem("Mall_R2_Bac");
        DeclaredUnloadPackages_Mall.AddItem("Mall_R2_Spt");
        DeclaredUnloadPackages_Mall.AddItem("Mall_R2_LW");
        DeclaredUnloadPackages_Mall.AddItem("Mall_R2_Lgts"); // mall elev end
    }

    // Chapter 6 (Factory_p)
    else if (MapName == "Factory_p")
    {
        DeclaredLoadPackages_Factory.AddItem("Factory_Roof-Lbay_Slc"); // pole grab start
        DeclaredLoadPackages_Factory.AddItem("Factory_Roof-Lbay_Spt");
        DeclaredLoadPackages_Factory.AddItem("Factory_Roof-Lbay_Aud");
        DeclaredLoadPackages_Factory.AddItem("Factory_Roof-Lbay_Slc_Lgts"); // pole grab end
        DeclaredLoadPackages_Factory.AddItem("Factory_Facto_Art"); // factory skip start
        DeclaredLoadPackages_Factory.AddItem("Factory_Facto_Aud");
        DeclaredLoadPackages_Factory.AddItem("Factory_Facto_Spt");
        DeclaredLoadPackages_Factory.AddItem("Factory_Facto_Lgts");
        DeclaredLoadPackages_Factory.AddItem("Factory_Facto-Arena_Slc");
        DeclaredLoadPackages_Factory.AddItem("Factory_Facto-Arena_Spt");
        DeclaredLoadPackages_Factory.AddItem("Factory_Facto-Arena_Aud");
        DeclaredLoadPackages_Factory.AddItem("Factory_Facto-Arena_Slc_Lgts"); // factory skip end
        DeclaredLoadPackages_Factory.AddItem("Factory_Arena_Slc"); // big elev start
        DeclaredLoadPackages_Factory.AddItem("Factory_Arena_Slc_Spt");
        DeclaredLoadPackages_Factory.AddItem("Factory_Arena_Aud"); // big elev end
        DeclaredLoadPackages_Factory.AddItem("Factory_Arena"); // before pk arena start
        DeclaredLoadPackages_Factory.AddItem("Factory_Arena_Art");
        DeclaredLoadPackages_Factory.AddItem("Factory_Arena_Spt");
        DeclaredLoadPackages_Factory.AddItem("Factory_Arena-Pursu_Slc");
        DeclaredLoadPackages_Factory.AddItem("Factory_Arena-Pursu_Spt");
        DeclaredLoadPackages_Factory.AddItem("Factory_Arena-Pursu_Aud");
        DeclaredLoadPackages_Factory.AddItem("Factory_Arena-Pursu_Slc_Lgts");
        DeclaredLoadPackages_Factory.AddItem("Factory_SB02_Mus"); // before pk arena end

        DeclaredUnloadPackages_Factory.AddItem("Factory_Roof-Lbay_Slc");
        DeclaredUnloadPackages_Factory.AddItem("Factory_Roof-Lbay_Spt");
        DeclaredUnloadPackages_Factory.AddItem("Factory_Roof-Lbay_Aud");
        LoadingBayFlagStr = SaveLoad.LoadData("LoadingBayEntered");
        if (LoadingBayFlagStr == "true" && !bEnteredLoadingBay)
        {
            if (!IsPackageInList("Factory_Lbay", DeclaredLoadPackages_Factory))
            {
                DeclaredLoadPackages_Factory.AddItem("Factory_Lbay");
            }
            if (!IsPackageInList("Factory_Lbay_Art", DeclaredLoadPackages_Factory))
            {
                DeclaredLoadPackages_Factory.AddItem("Factory_Lbay_Art");
            }
            if (!IsPackageInList("Factory_Lbay_Aud", DeclaredLoadPackages_Factory))
            {
                DeclaredLoadPackages_Factory.AddItem("Factory_Lbay_Aud");
            }
            if (!IsPackageInList("Factory_Lbay_Spt", DeclaredLoadPackages_Factory))
            {
                DeclaredLoadPackages_Factory.AddItem("Factory_Lbay_Spt");
            }
            if (!IsPackageInList("Factory_Lbay_Lgts", DeclaredLoadPackages_Factory))
            {
                DeclaredLoadPackages_Factory.AddItem("Factory_Lbay_Lgts");
            }
            if (!IsPackageInList("Factory_Lbay-Facto_Slc", DeclaredLoadPackages_Factory))
            {
                DeclaredLoadPackages_Factory.AddItem("Factory_Lbay-Facto_Slc");
            }
            if (!IsPackageInList("Factory_Lbay-Facto_Spt", DeclaredLoadPackages_Factory))
            {
                DeclaredLoadPackages_Factory.AddItem("Factory_Lbay-Facto_Spt");
            }
            if (!IsPackageInList("Factory_Lbay-Facto_Aud", DeclaredLoadPackages_Factory))
            {
                DeclaredLoadPackages_Factory.AddItem("Factory_Lbay-Facto_Aud");
            }
            if (!IsPackageInList("Factory_Lbay-Facto_Slc_Lgts", DeclaredLoadPackages_Factory))
            {
                DeclaredLoadPackages_Factory.AddItem("Factory_Lbay-Facto_Slc_Lgts");
            }
            if (!IsPackageInList("Factory_Facto", DeclaredLoadPackages_Factory))
            {
                DeclaredLoadPackages_Factory.AddItem("Factory_Facto");
            }

            RemovePackageIfPresent(DeclaredUnloadPackages_Factory, "Factory_Roof-Lbay_Slc");
            RemovePackageIfPresent(DeclaredUnloadPackages_Factory, "Factory_Roof-Lbay_Spt");
            RemovePackageIfPresent(DeclaredUnloadPackages_Factory, "Factory_Roof-Lbay_Aud");

            bEnteredLoadingBay = true;
        }
        DeclaredUnloadPackages_Factory.AddItem("Factory_Arena_Slc"); // pursuit elev start
        DeclaredUnloadPackages_Factory.AddItem("Factory_Arena_Slc_Spt");
        DeclaredUnloadPackages_Factory.AddItem("Factory_Arena");
        DeclaredUnloadPackages_Factory.AddItem("Factory_Arena_Art");
        DeclaredUnloadPackages_Factory.AddItem("Factory_Arena_Aud");
        DeclaredUnloadPackages_Factory.AddItem("Factory_Arena_Spt"); // pursuit elev end
    }

    // Chapter 7 (Boat_p)
    else if (MapName == "Boat_p")
    {
        DeclaredLoadPackages_Boat.AddItem("Boat_PDeck"); // truck ride start
        DeclaredLoadPackages_Boat.AddItem("Boat_PDeck_Art");
        DeclaredLoadPackages_Boat.AddItem("Boat_PDeck_Aud");
        DeclaredLoadPackages_Boat.AddItem("Boat_PDeck_Spt");
        DeclaredLoadPackages_Boat.AddItem("Boat_PDeck_Lgts");
        DeclaredLoadPackages_Boat.AddItem("Boat_PDeck-Deck_Slc");
        DeclaredLoadPackages_Boat.AddItem("Boat_PDeck-Deck_Aud");
        DeclaredLoadPackages_Boat.AddItem("Boat_PDeck-Deck_Lgts");
        DeclaredLoadPackages_Boat.AddItem("Boat_Deck_Spt"); // truck ride end
        DeclaredLoadPackages_Boat.AddItem("Boat_Bac"); // puzzle start
        DeclaredLoadPackages_Boat.AddItem("Boat_Harb");
        DeclaredLoadPackages_Boat.AddItem("Boat_Deck");
        DeclaredLoadPackages_Boat.AddItem("Boat_Deck_Art");
        DeclaredLoadPackages_Boat.AddItem("Boat_Deck_Aud");
        DeclaredLoadPackages_Boat.AddItem("Boat_Deck_Bac");
        DeclaredLoadPackages_Boat.AddItem("Boat_Deck_Lgts");
        DeclaredLoadPackages_Boat.AddItem("Boat_Bac_Lgts"); // puzzle end
        DeclaredLoadPackages_Boat.AddItem("Boat_Deck-Chase_Slc"); // boat deck start
        DeclaredLoadPackages_Boat.AddItem("Boat_Deck-Chase_Aud");
        DeclaredLoadPackages_Boat.AddItem("Boat_Deck-Chase_Spt");
        DeclaredLoadPackages_Boat.AddItem("Boat_Deck-Chase_Lgts");
        DeclaredLoadPackages_Boat.AddItem("Boat_SL01_Mus"); // boat deck end
        DeclaredLoadPackages_Boat.AddItem("Boat_Chase"); // chase start
        DeclaredLoadPackages_Boat.AddItem("Boat_Chase_Art");
        DeclaredLoadPackages_Boat.AddItem("Boat_Chase_Aud");
        DeclaredLoadPackages_Boat.AddItem("Boat_Chase_Spt");
        DeclaredLoadPackages_Boat.AddItem("Boat_Chase_Lgt");
        DeclaredLoadPackages_Boat.AddItem("Boat_End");
        DeclaredLoadPackages_Boat.AddItem("Boat_End_Art");
        DeclaredLoadPackages_Boat.AddItem("Boat_End_Aud");
        DeclaredLoadPackages_Boat.AddItem("Boat_End_Bac");
        DeclaredLoadPackages_Boat.AddItem("Boat_End_Spt");
        DeclaredLoadPackages_Boat.AddItem("Boat_End_LW"); // chase end
    }

    // Chapter 8 (Convoy_p)
    else if (MapName == "Convoy_p")
    {
        DeclaredLoadPackages_Convoy.AddItem("Convoy_SL01_Mus"); // atrium entrance
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Snipe_Bac"); // vents start (inbounds)
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Chase");
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Chase_Art");
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Chase_Aud");
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Chase_Bac");
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Chase_Spt");
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Chase_Lgts");
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Chase-Mall_Slc");
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Chase-Mall_Slc_Lw");
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Chase-Mall_Aud");
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Chase-Mall_Slc_Lgts");
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Mall");
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Mall_Bac");
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Mall_Bac2"); // vents end (inbounds)
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Mall_Spt"); // after crash start
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Mall_Art");
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Mall_Lw");
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Mall_Aud");
        DeclaredLoadPackages_Convoy.AddItem("Convoy_Mall_Lgts"); // after crash end

        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Roof"); // first elev start
        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Roof_Art");
        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Roof_Lw");
        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Roof_Aud");
        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Roof_Bac");
        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Roof_Spt");
        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Snipe_Bac");
        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Chase_Bac");
        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Mall_Bac2"); // first elev end
        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Roof-Conv_slc_Spt"); // atrium elev start
        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Roof-Conv_slc_Building");
        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Conv");
        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Conv_Art");
        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Conv_LW");
        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Conv_Aud");
        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Conv_Bac");
        DeclaredUnloadPackages_Convoy.AddItem("Convoy_Conv_Spt"); // atrium elev end
    }

    // Chapter 9 (Scraper_p)
    else if (MapName == "Scraper_p")
    {
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Deck"); // fire start
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Deck_Spt");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Deck_Art");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Deck_Aud");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Deck_LGTs");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Deck-Lobby_Slc");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Deck-Lobby_Spt");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Deck-Lobby_Aud");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Deck-Lobby_Lgts"); // fire end
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Duct-Roof_Spt"); // bev elev start
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Duct-Roof_Aud"); // bev elev end
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Out_Bac"); // vents start (inbounds)
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Roof");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Roof_Art");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Roof_Spt");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Roof_Aud");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Roof_LW");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Roof_Lgts");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Roof-Mill_Slc");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Roof-Mill_Spt");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Roof-Mill_Aud");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_OnlyTower"); // video surveillance start
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Heli_Lgts");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Heli_Spt");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Heli");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Heli_Art");
        DeclaredLoadPackages_Scraper.AddItem("Scraper_Heli_Aud"); // video surveillance end

        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Out-Deck_Slc"); // first elev start
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Out-Deck_Spt");
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Out-Deck_Spt");
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Out-Deck_Aud");
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Deck");
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Deck_Spt");
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Deck_Art");
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Deck_Aud");
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Deck_LGTs"); // first elev end
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Deck-Lobby_Slc"); // bev elev start
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Deck-Lobby_Spt");
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Deck-Lobby_Aud");
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Lobby");
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Lobby_Art");
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Lobby_Aud");
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Lobby_Spt");
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Lobby_Bac");
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Lobby_Lgts");
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Roof_Buildings");
        DeclaredUnloadPackages_Scraper.AddItem("Scraper_Plaza_Bac"); // bev elev end
    }

    // Main menu
    else
    {
        // If run had finished, lock the final time once returning to main menu
        FinalTimeFlag = SaveLoad.LoadData("FinalTimeLocked");
        if (FinalTimeFlag == "true")
        {
            bFinalTimeLocked = true;
        }

        DeclaredLoadPackages_TdMainMenu.AddItem("TdMainMenu_Images");
        DeclaredLoadPackages_TdMainMenu.AddItem("TdMainMenu_Audio0");
    }
}

// On respawn, skip 3 ticks to avoid the extra clamped DeltaTime
function PlayerOwnerRestart()
{
    super.PlayerOwnerRestart();
    SkipTicks = 3;
    bBagPopUpCalled = false;

    if (WorldInfo.GetMapName() == "Scraper_p")
    {
        bTouchedDeathVolume = false;
    }
}

// Tick: Main loop updates timer and saves state when needed
function Tick(float DeltaTime)
{
    local float RealDeltaTime;
    local string SavedTimeStr;
    local string MapName;
    local LevelStreaming LS;
    local bool bFoundUnload;

    super(TdHUD).Tick(DeltaTime);

    // Skip timer update if within the skip period
    if (SkipTicks > 0)
    {
        SkipTicks--;
        return;
    }

    // This stops HUD/post process effects breaking
    EffectManager.Update(DeltaTime, RealTimeRenderDelta);

    if (SaveLoad == none)
    {
        SaveLoad = new class'SaveLoadHandlerSTHUD';
    }

    if (SaveLoad.LoadData("bNewMapSavePending") == "true")
    {
        SaveLoad.SaveData("bNewMapSavePending", "false");
    }

    if (SpeedrunController == none && PlayerOwner != none)
    {
        SpeedrunController = TdPlayerController(PlayerOwner);
    }

    if (!bLoadedTimeFromSave)
    {
        SavedTimeStr = SaveLoad.LoadData("TimeAttackClock");
        if (SavedTimeStr != "")
        {
            GameData.TimeAttackClock = float(SavedTimeStr);
        }
        bLoadedTimeFromSave = true;
    }

    // Make timer ignore time dilation
    if (WorldInfo.TimeDilation > 0)
    {
        RealDeltaTime = DeltaTime / WorldInfo.TimeDilation;
    }
    else
    {
        RealDeltaTime = DeltaTime;
    }

    if (HundredPercentMode && ShowBagHUD)
    {
        if (SpeedrunController.bCinematicMode)
        {
            PopUpDuration = 8;
        }
        else if (PopUpType == PUT_Sniper)
        {
            PopUpDuration = 4;
        }
        else
        {
            PopUpDuration = 999999;
        }

        if (bBagPopUpCalled && PopUpType != PUT_Bag)
        {
            bBagPopUpCalled = false;
        }

        if (!bBagPopUpCalled && !SpeedrunController.bCinematicMode)
        {
            SpeedrunController.CallPopUp(PUT_Bag, 999999);
            bBagPopUpCalled = true;
        }
    }
    else
    {
        if (bBagPopUpCalled)
        {
            SpeedrunController.CallPopUp(PUT_None, 1.0);
            bBagPopUpCalled = false;
        }
    }

    MapName = WorldInfo.GetMapName();

    // Chapter 2-specific monitoring
    if (MapName == "Stormdrain_p")
    {
        if (MonitorJKLevelLoadsAfterFirstElevator())
        {
            // We reached above the ceiling from elevator clip - boss levels should NOT be RTA
            RemovePackageIfPresent(DeclaredLoadPackages_Stormdrain, "Stormdrain_boss_Slc");
            RemovePackageIfPresent(DeclaredLoadPackages_Stormdrain, "Stormdrain_boss_Slc_spt");
            RemovePackageIfPresent(DeclaredLoadPackages_Stormdrain, "Stormdrain_boss_Slc_Lgts");
            RemovePackageIfPresent(DeclaredLoadPackages_Stormdrain, "Stormdrain_boss");
            RemovePackageIfPresent(DeclaredLoadPackages_Stormdrain, "Stormdrain_boss_Aud");
        }

        if (MonitorJKLevelUnloadsBeforeFinalElevator())
        {
            // We quit -> continued before final elevator - add these unloads as LRT
            DeclaredUnloadPackages_Stormdrain.AddItem("Stormdrain_StdE-Out_slc");
            DeclaredUnloadPackages_Stormdrain.AddItem("Stormdrain_StdE-Out_slc_lgts");
            RemovePackageIfPresent(DeclaredLoadPackages_Stormdrain, "Stormdrain_boss_Aud");
        }
    }

    // Chapter 3-specific monitoring
    else if (MapName == "Cranes_p")
    {
        if (MonitorReachedBrokenElevator() && SoundFix)
        {
            // Broken elevator sound fix
            SetSoundCueMaxPlays("A_Props_Interactive.Construction_Elevator.Button_Negative", 1);
            SetSoundCueMaxPlays("A_SP03.BrokenElevator.Spark", 1);
        }
    }

    // Chapter 4-specific monitoring
    else if (MapName == "Subway_p" && bLoadedTimeFromSave && !bAfterElevatorCrash)
    {
        if (MonitorReachedSubwayStation())
        {
            // We reached subway station checkpoint after elevator crash, prepare timer for inbounds handling
            DeclaredLoadPackages_Subway.AddItem("Subway_SB02_Mus");
            DeclaredLoadPackages_Subway.AddItem("Subway_Plat"); // subway gate start (inbounds)
            DeclaredLoadPackages_Subway.AddItem("Subway_Stat-Plat_Slc");
            DeclaredLoadPackages_Subway.AddItem("Subway_Stat-Plat_Spt");
            DeclaredLoadPackages_Subway.AddItem("Subway_Stat-Plat_ASlc");
            DeclaredLoadPackages_Subway.AddItem("Subway_Stat-Plat_Lgts"); // subway gate end

            RemovePackageIfPresent(DeclaredUnloadPackages_Subway, "Subway_Sky");

            bAfterElevatorCrash = true;
            SaveLoad.SaveData("AfterElevatorCrashTriggered", "true");
        }
    }

    // Chapter 5-specific monitoring
    else if (MapName == "Mall_p" && bLoadedTimeFromSave && !bRemovedMallUnload)
    {
        bFoundUnload = false;
        foreach WorldInfo.StreamingLevels(LS)
        {
            if (LS != none && LS.bHasUnloadRequestPending)
            {
                if (string(LS.PackageName) == "Mall_HW-R1_Aud" || string(LS.PackageName) == "Mall_HW-R1_Lgts")
                {
                    bFoundUnload = true;
                    break;
                }
            }
        }
        if (bFoundUnload)
        {
            // Remove the problematic unload packages if we quit -> reloaded or respawned in this area (fixes 5b timer pause bug)
            RemovePackageIfPresent(DeclaredUnloadPackages_Mall, "Mall_HW-R1_Aud");
            RemovePackageIfPresent(DeclaredUnloadPackages_Mall, "Mall_HW-R1_Lgts");
            bRemovedMallUnload = true;
            SaveLoad.SaveData("MallUnloadRemoved", "true");
        }
    }

    // Chapter 6-specific monitoring
    else if (MapName == "Factory_p" && bLoadedTimeFromSave)
    {
        if (!bEnteredLoadingBay && MonitorEnteredLoadingBay())
        {
            // We reached the loading bay entrance checkpoint, prepare timer for inbounds handling
            DeclaredLoadPackages_Factory.AddItem("Factory_Lbay"); // loading bay start (inbounds)
            DeclaredLoadPackages_Factory.AddItem("Factory_Lbay_Art");
            DeclaredLoadPackages_Factory.AddItem("Factory_Lbay_Aud");
            DeclaredLoadPackages_Factory.AddItem("Factory_Lbay_Spt");
            DeclaredLoadPackages_Factory.AddItem("Factory_Lbay_Lgts");
            DeclaredLoadPackages_Factory.AddItem("Factory_Lbay-Facto_Slc");
            DeclaredLoadPackages_Factory.AddItem("Factory_Lbay-Facto_Spt");
            DeclaredLoadPackages_Factory.AddItem("Factory_Lbay-Facto_Aud");
            DeclaredLoadPackages_Factory.AddItem("Factory_Lbay-Facto_Slc_Lgts");
            DeclaredLoadPackages_Factory.AddItem("Factory_Facto"); // loading bay end (inbounds)

            RemovePackageIfPresent(DeclaredUnloadPackages_Factory, "Factory_Roof-Lbay_Slc");
            RemovePackageIfPresent(DeclaredUnloadPackages_Factory, "Factory_Roof-Lbay_Spt");
            RemovePackageIfPresent(DeclaredUnloadPackages_Factory, "Factory_Roof-Lbay_Aud");

            bEnteredLoadingBay = true;
            SaveLoad.SaveData("LoadingBayEntered", "true");
        }

        if (MonitorReachedConveyorInbounds() || MonitorReachedConveyorAnyPercent() && SoundFix)
        {
            SetSoundCueMaxPlays("A_Props_Interactive.Beeps.Conveyor_Alarm", 1);
        }

        if (MonitorReachedBigLift() && SoundFix)
        {
            SetSoundCueMaxPlays("A_SP04.Shaft_Elevator.Shaft_Elevator", 1);
            SetSoundCueMaxPlays("A_Props_Interactive.Beeps.Conveyor_Alarm", 1);
        }

        if (MonitorReachedArenaElevator() && SoundFix)
        {
            SetSoundCueMaxPlays("A_SP06.Elevator.Inside", 1);
        }
    }

    // Chapter 9-specific monitoring
    else if (MapName == "Scraper_p")
    {
        if (MonitorReachedMaintenanceAccess() && SoundFix)
        {
            SetSoundCueMaxPlays("A_SP09.Gas_Event.ExplosionWithGas", 1);
            SetSoundCueMaxPlays("A_SP09.Gas_Event.Explosion", 1);
            SetSoundCueMaxPlays("A_SP09.Gas_Event.BigGas", 1);
            SetSoundCueMaxPlays("A_SP09.Gas_Event.SmallGas", 1);
            SetSoundCueMaxPlays("A_SP09.Gas_Event.BurningGas_01", 1);
            SetSoundCueMaxPlays("A_SP09.Gas_Event.BurningGas_02", 1);
            SetSoundCueMaxPlays("A_Props_Interactive.Valve.First_Turn", 1);
            SetSoundCueMaxPlays("A_Props_Interactive.Valve.Turn", 1);
        }

        if (MonitorShardLevelLoadsAfterFirstElevator())
        {
            // We reached the lobby, add these loads as RTA
            DeclaredLoadPackages_Scraper.AddItem("Scraper_Roof_Buildings");
            DeclaredLoadPackages_Scraper.AddItem("Scraper_Plaza_Bac");
            DeclaredLoadPackages_Scraper.AddItem("Scraper_Roof_Bac");
            DeclaredLoadPackages_Scraper.AddItem("Scraper_Roof_Bac2"); // vents end (inbounds)
        }

        if (MonitorShardLevelLoadsBevElevator())
        {
            // We are inside bev elevator (inbounds) - add these level loads back as LRT
            RemovePackageIfPresent(DeclaredLoadPackages_Scraper, "Scraper_Duct-Roof_Spt");
            RemovePackageIfPresent(DeclaredLoadPackages_Scraper, "Scraper_Duct-Roof_Aud");
        }

        if (MonitorShardLevelUnloadsBeforeFinalElevator())
        {
            // We reached the rooftop snipers checkpoint - add these unloads as LRT
            DeclaredUnloadPackages_Scraper.AddItem("Scraper_OnlyTower"); // final elev start
            DeclaredUnloadPackages_Scraper.AddItem("Scraper_Out_Bac");
            DeclaredUnloadPackages_Scraper.AddItem("Scraper_Duct-Roof_Slc");
            DeclaredUnloadPackages_Scraper.AddItem("Scraper_Duct-Roof_Spt");
            DeclaredUnloadPackages_Scraper.AddItem("Scraper_Duct-Roof_Aud");
            DeclaredUnloadPackages_Scraper.AddItem("Scraper_Roof");
            DeclaredUnloadPackages_Scraper.AddItem("Scraper_Roof_Art");
            DeclaredUnloadPackages_Scraper.AddItem("Scraper_Roof_Spt");
            DeclaredUnloadPackages_Scraper.AddItem("Scraper_Roof_Aud");
            DeclaredUnloadPackages_Scraper.AddItem("Scraper_Roof_LW");
            DeclaredUnloadPackages_Scraper.AddItem("Scraper_Roof_Lgts");
            DeclaredUnloadPackages_Scraper.AddItem("Scraper_SB01_Mus"); // final elev end
        }

        if (MonitorShardLevelLoadsAfterFinalElevator())
        {
            // We reached the server room checkpoint - add this level as RTA
            DeclaredLoadPackages_Scraper.AddItem("Scraper_Heli_Bac"); // video surveillance
        }

        // Run completion
        if (!bFinalTimeLocked && MonitorShardHelipad())
        {
            if (CheckHeliInteractionComplete())
            {
                if (!HundredPercentMode)
                {
                    RunComplete = true;
                }
                else
                {
                    if (Profile.NumBagsFoundTotal() == 30)
                    {
                        RunComplete = true;
                    }
                }

                if (RunComplete)
                {
                    bFinalTimeLocked = true;
                    RunCompleteLiveSplitASLMarker = 987654321;
                    SaveLoad.SaveData("FinalTimeLocked", "true");
                    SpeedrunController.ClientMessage("Final time - " $ GetTimeString(GameData.TimeAttackClock));
                }
            }
        }
    }

    if (IsLevelCompleted())
    {
        bLevelCompleted = true;
    }

    // Update timer if allowed.
    if (!bFinalTimeLocked && ShouldIncrementTimer())
    {
        GameData.TimeAttackClock += RealDeltaTime;
    }
}

// ShouldIncrementTimer: Decides whether the timer should run based on streaming/disk access
function bool ShouldIncrementTimer()
{
    local string MapName;
    local TdUIScene_LoadIndicator IndicatorScene;
    local LevelStreaming LS;
    local array<string> DeclaredLoadPackages;
    local array<string> DeclaredUnloadPackages;
    local bool bFoundUndeclared, bFoundDeclared, bFoundDeclaredUnload;
    local bool bStormdrainGateOK;

    MapName = WorldInfo.GetMapName();

    if (MapName == "TdMainMenu" && !bHasEverStartedNewGame)
    {
        return false;
    }

    bFoundUndeclared = false;
    bFoundDeclared = false;
    bFoundDeclaredUnload = false;
    bStormdrainGateOK = true;

    IndicatorScene = TdUIScene_LoadIndicator(DiskAccessIndicatorInstance);
    
    if (IndicatorScene != None && IndicatorScene.bIsLoadingLevel)
    {
        return false;
    }

    if (!SpeedrunController.IsLoadingLevel() && !IsUnloadingAnyLevel())
    {
        bUndeclaredLoadActive = false;
        if (!bDeclaredUnloadActive)
        {
            return true;
        }
    }

    if (MapName == "Edge_p")
    {
        DeclaredLoadPackages = DeclaredLoadPackages_Edge;
        DeclaredUnloadPackages = DeclaredUnloadPackages_Edge;
    }
    else if (MapName == "Escape_p")
    {
        DeclaredLoadPackages = DeclaredLoadPackages_Escape;
        DeclaredUnloadPackages = DeclaredUnloadPackages_Escape;
    }
    else if (MapName == "Stormdrain_p")
    {
        DeclaredLoadPackages = DeclaredLoadPackages_Stormdrain;
        DeclaredUnloadPackages = DeclaredUnloadPackages_Stormdrain;

        bStormdrainGateOK = CheckStormdrainLoading();
    }
    else if (MapName == "Cranes_p")
    {
        DeclaredLoadPackages = DeclaredLoadPackages_Cranes;
        DeclaredUnloadPackages = DeclaredUnloadPackages_Cranes;
    }
    else if (MapName == "Subway_p")
    {
        DeclaredLoadPackages = DeclaredLoadPackages_Subway;
        DeclaredUnloadPackages = DeclaredUnloadPackages_Subway;
    }
    else if (MapName == "Mall_p")
    {
        DeclaredLoadPackages = DeclaredLoadPackages_Mall;
        DeclaredUnloadPackages = DeclaredUnloadPackages_Mall;
    }
    else if (MapName == "Factory_p")
    {
        DeclaredLoadPackages = DeclaredLoadPackages_Factory;
        DeclaredUnloadPackages = DeclaredUnloadPackages_Factory;
    }
    else if (MapName == "Boat_p")
    {
        DeclaredLoadPackages = DeclaredLoadPackages_Boat;
        DeclaredUnloadPackages = DeclaredUnloadPackages_Boat;
    }
    else if (MapName == "Convoy_p")
    {
        DeclaredLoadPackages = DeclaredLoadPackages_Convoy;
        DeclaredUnloadPackages = DeclaredUnloadPackages_Convoy;
    }
    else if (MapName == "Scraper_p")
    {
        DeclaredLoadPackages = DeclaredLoadPackages_Scraper;
        DeclaredUnloadPackages = DeclaredUnloadPackages_Scraper;
    }
    else if (MapName == "TdMainMenu")
    {
        DeclaredLoadPackages = DeclaredLoadPackages_TdMainMenu;
    }

    foreach WorldInfo.StreamingLevels(LS)
    {
        if (LS.bHasLoadRequestPending)
        {
            // Stormdrain gate packages are ignored here – handled above
            if (MapName == "Stormdrain_p"
                && IsPackageInList(string(LS.PackageName), DeclaredLoadPackages_StormdrainGate))
            {
                continue;
            }

            // clear unload‑latch as soon as any load starts
            if (bDeclaredUnloadActive)
            {
                bDeclaredUnloadActive = false;
            }

            if (IsPackageInList(string(LS.PackageName), DeclaredLoadPackages))
            {
                bFoundDeclared = true;
            }
            else
            {
                bFoundUndeclared = true;
            }
        }

        if (LS.bHasUnloadRequestPending)
        {
            // Stormdrain gate packages are ignored here – handled above
            if (MapName == "Stormdrain_p"
                && IsPackageInList(string(LS.PackageName), DeclaredUnloadPackages_StormdrainGate))
            {
                continue;
            }

            if (IsPackageInList(string(LS.PackageName), DeclaredUnloadPackages))
            {
                bFoundDeclaredUnload  = true;
                LastDeclaredUnloadTime = WorldInfo.TimeSeconds;
            }
        }
    }

    // Update generic latches
    if (bFoundUndeclared)
    {
        bUndeclaredLoadActive = true;
    }
    else if (bFoundDeclared)
    {
        bUndeclaredLoadActive = false;
    }

    if (bFoundDeclaredUnload)
    {
        bDeclaredUnloadActive  = true;
        LastDeclaredUnloadTime = WorldInfo.TimeSeconds;
    }

    // Generic latch decision
    if (bUndeclaredLoadActive || bDeclaredUnloadActive)
    {
        return false;
    }

    // Final decision
    return bStormdrainGateOK;
}

function bool IsUnloadingAnyLevel()
{
    local LevelStreaming LS;
    local int i;
    
    for (i = 0; i < WorldInfo.StreamingLevels.Length; ++i)
    {
        LS = WorldInfo.StreamingLevels[i];
        if (LS != None && LS.bHasUnloadRequestPending)
        {
            return true;
        }
    }
    return false;
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

function bool IsPackageInList(string PackageName, array<string> PackageList)
{
    local int i;

    for (i = 0; i < PackageList.Length; i++)
    {
        if (PackageName == PackageList[i])
        {
            return true;
        }
    }
    return false;
}

function RemovePackageIfPresent(out array<string> PackageList, string PackageName)
{
    local int Index;
    
    Index = PackageList.Find(PackageName);
    if (Index != INDEX_NONE)
    {
        PackageList.Remove(Index, 1);
    }
}

// Helper for Chapter 2 to process SD gate level streaming
function bool CheckStormdrainLoading()
{
    local bool bGateButtonPressedNow;
    local bool bFoundUndeclared, bFoundDeclared, bFoundDeclaredUnload;
    local LevelStreaming LS;
    local string Pkg;

    bGateButtonPressedNow = MonitorSDGateButton();
    bFoundUndeclared = false;
    bFoundDeclared = false;
    bFoundDeclaredUnload = false;

    foreach WorldInfo.StreamingLevels(LS)
    {
        Pkg = string(LS.PackageName);

        if (LS.bHasLoadRequestPending)
        {
            // Gate packages
            if (IsPackageInList(Pkg, DeclaredLoadPackages_StormdrainGate))
            {
                if (bGateButtonPressedNow) // button hit early - treat gate loads as LRT
                {
                    bFoundUndeclared = true;
                }
                else // normal case - gate loads are RTA
                {
                    bFoundDeclared = true;
                }

                if (bDeclaredUnloadActive)
                {
                    bDeclaredUnloadActive = false;
                }
            }
        }

        if (LS.bHasUnloadRequestPending)
        {
            // Gate packages
            if (IsPackageInList(Pkg, DeclaredUnloadPackages_StormdrainGate))
            {
                if (bGateButtonPressedNow) // early button hit - treat gate unloads as LRT
                {
                    bFoundDeclaredUnload = true;
                }
                // otherwise ignore – gate unloads are RTA in the normal case
            }
        }
    }

    if (bFoundUndeclared)
    {
        bUndeclaredLoadActive = true;
    }
    else if (bFoundDeclared)
    {
        bUndeclaredLoadActive = false;
    }

    if (bFoundDeclaredUnload)
    {
        bDeclaredUnloadActive = true;
        LastDeclaredUnloadTime = WorldInfo.TimeSeconds;
    }

    if (!SpeedrunController.IsLoadingLevel() && !IsUnloadingAnyLevel())
    {
        bUndeclaredLoadActive = false;

        if (!bDeclaredUnloadActive)
        {
            return true; // safe to run the timer
        }
    }

    if (bUndeclaredLoadActive || bDeclaredUnloadActive)
    {
        return false; // pause the timer
    }

    return true;
}

// Checks for trigger actor events for both stormdrains gate buttons
function bool MonitorSDGateButton()
{
    local Actor A;
    local array<SequenceEvent> FoundEvents;
    local int i;
    local SeqEvent_TdUsed TdUsed;

    foreach AllActors(class'Actor', A)
    {
        // Both gate buttons have the same actor name, just in different levels
        if (A.Name == name("TdTrigger_0"))
        {
            if (A.FindEventsOfClass(class'SeqEvent_TdUsed', FoundEvents, true))
            {
                for (i = 0; i < FoundEvents.Length; i++)
                {
                    TdUsed = SeqEvent_TdUsed(FoundEvents[i]);
                    // Check for regular activation or use glitch
                    if (TdUsed != none &&
                        (TdUsed.bInteract || FoundEvents[i].ActivateCount > 0 || TdUsed.ActivationTime > 0))
                    {
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

function bool IsActiveCheckpoint(string CheckpointName)
{
    local TdCheckpointManager CheckpointManager;

    if (GameData == none)
    {
        return false;
    }

    CheckpointManager = GameData.CheckpointManager;
    if (CheckpointManager == none)
    {
        return false;
    }

    return (CheckpointManager.GetActiveCheckpoint() == CheckpointName);
}

function bool MonitorJKLevelLoadsAfterFirstElevator()
{
    local Vector TargetLocation;
    local float Distance;

    if (SpeedrunController == None || SpeedrunController.Pawn == None)
    {
        return false;
    }

    TargetLocation = vect(1075.81, -3403.87, 4570.00);
    Distance = VSize(SpeedrunController.Pawn.Location - TargetLocation);

    if (Distance < 100.0)
    {
        return true;
    }
}

function bool MonitorJKLevelUnloadsBeforeFinalElevator()
{
    local Vector TargetLocation;
    local float Distance;
    local LevelStreaming LS;
    local bool bEitherUnloaded;

    if (SpeedrunController == None || SpeedrunController.Pawn == None)
    {
        return false;
    }

    TargetLocation = vect(15392.38, 4135.57, 837.15);
    Distance = VSize(SpeedrunController.Pawn.Location - TargetLocation);

    foreach WorldInfo.StreamingLevels(LS)
    {
        if ((string(LS.PackageName) == "Stormdrain_StdE-Out_slc" || string(LS.PackageName) == "Stormdrain_StdE-Out_slc_lgts")
            && LS.LoadedLevel == None)
        {
            bEitherUnloaded = true;
        }
    }

    if (bEitherUnloaded && Distance < 100.0)
    {
        return false;
    }
    else if (!bEitherUnloaded && Distance < 100.0)
    {
        return true;
    }
}

function bool MonitorReachedBrokenElevator()
{
    return IsActiveCheckpoint("SP03_Office_03_slc");
}

function bool MonitorReachedSubwayStation()
{
    return IsActiveCheckpoint("Subway_Station");
}

function bool MonitorEnteredLoadingBay()
{
    return IsActiveCheckpoint("Loading_bay");
}

function bool MonitorReachedConveyorAnyPercent()
{
    return IsActiveCheckpoint("steamroom_puzzle");
}

function bool MonitorReachedConveyorInbounds()
{
    return IsActiveCheckpoint("Conveyor_puzzle");
}

function bool MonitorReachedBigLift()
{
    return IsActiveCheckpoint("after_facto");
}

function bool MonitorReachedArenaElevator()
{
    return IsActiveCheckpoint("TO_arena");
}

function bool MonitorReachedMaintenanceAccess()
{
    return IsActiveCheckpoint("Out_soft");
}

function bool MonitorShardLevelLoadsAfterFirstElevator()
{
    return IsActiveCheckpoint("Lobby");
}

function bool MonitorShardLevelLoadsBevElevator()
{
    local Vector TargetLocation;
    local float Distance;

    if (SpeedrunController == None || SpeedrunController.Pawn == None)
    {
        return false;
    }

    TargetLocation = vect(-5407.70, 8570.85, 13261.15);
    Distance = VSize(SpeedrunController.Pawn.Location - TargetLocation);

    if (Distance < 200.0)
    {
        return true;
    }
}

function bool MonitorShardLevelUnloadsBeforeFinalElevator()
{
    return IsActiveCheckpoint("Rooftops");
}

function bool MonitorShardLevelLoadsAfterFinalElevator()
{
    return IsActiveCheckpoint("Server_room");
}

function bool MonitorShardHelipad()
{
    return IsActiveCheckpoint("End_game");
}

// Check if the heli was actually grabbed and fired the success branch in kismet
function bool CheckHeliInteractionComplete()
{
    local Sequence CurrentSeq, SubSeq;
    local SequenceObject SeqObj;
    local SeqEvent_RemoteEvent RemoteEvent;
    local SeqEvent_Touch TouchEvent;
    local SeqAct_Interp MatineeAction;
    local array<Sequence> SequencesToCheck;
    local int i;
    local Pawn PlayerPawn;
    local SkeletalMeshComponent PlayerMesh;
    local AnimNodeSequence SeqNode;
    local AnimSequence ActiveSequence;

    if (bTouchedDeathVolume)
    {
        return false;
    }

    if (!b1PAnimPlayed && PlayerOwner != None)
    {
        PlayerPawn = PlayerOwner.Pawn;
        if (PlayerPawn != None)
        {
            PlayerMesh = PlayerPawn.Mesh;
            if (PlayerMesh != None)
            {
                foreach PlayerMesh.AllAnimNodes(class'AnimNodeSequence', SeqNode)
                {
                    if (SeqNode != None && SeqNode.bPlaying && SeqNode.NodeTotalWeight > 0.1f)
                    {
                        ActiveSequence = SeqNode.AnimSeq;
                        if (ActiveSequence != None && ActiveSequence.SequenceName == 'jacknife02' && ActiveSequence.Outer.Name == 'AS_CS_SP09_JacknifeDeath_Faith1P')
                        {
                            b1PAnimPlayed = true;
                            break; 
                        }
                    }
                }
            }
        }
    }

    CurrentSeq = WorldInfo.GetGameSequence();
    if (CurrentSeq != None)
    {
        SequencesToCheck.AddItem(CurrentSeq);
        while (SequencesToCheck.Length > 0)
        {
            CurrentSeq = SequencesToCheck[SequencesToCheck.Length - 1];
            SequencesToCheck.Remove(SequencesToCheck.Length - 1, 1);

            for (i = 0; i < CurrentSeq.SequenceObjects.Length; i++)
            {
                SeqObj = CurrentSeq.SequenceObjects[i];
                
                TouchEvent = SeqEvent_Touch(SeqObj);

                if (TouchEvent != None && TouchEvent.ObjName == "Trigger_9 Touch")
                {
                    if (TouchEvent.TouchedList.Length > 0)
                    {
                        // If we touched the death volume, don't allow the timer to stop if we grabbed the heli
                        bTouchedDeathVolume = true;
                        return false;
                    }
                }
                
                RemoteEvent = SeqEvent_RemoteEvent(SeqObj);
                if (RemoteEvent != None)
                {
                    if (RemoteEvent.EventName == 'heli_in_position')
                    {
                        bHeliExists = true;
                    }
                    else if (RemoteEvent.EventName == 'KillBots' && RemoteEvent.TriggerCount > 0)
                    {
                        bKillBotsFired = true;
                    }
                }

                MatineeAction = SeqAct_Interp(SeqObj);
                if (MatineeAction != None && MatineeAction.Name == 'SeqAct_Interp_2' && MatineeAction.bIsPlaying)
                {
                    bHeliReadyForGrab = true;
                }

                SubSeq = Sequence(SeqObj);
                if (SubSeq != None)
                {
                    SequencesToCheck.AddItem(SubSeq);
                }
            }
        }
    }

    return (bHeliExists && bHeliReadyForGrab && bKillBotsFired && b1PAnimPlayed);
}

exec function SetCollectedBagsCount(int NumBagsToSet)
{
    local UIDataStore_OnlinePlayerData PlayerDataStore;
    local UIDataProvider_OnlineProfileSettings ProfileDataProvider;
    local int HiddenBagMaskID;
    local int NewBagMaskValue;
    local int MaxBagsAllowed;

    MaxBagsAllowed = 30; // Based on TdProfileSettings.MAX_BAGS
    SpeedrunController = TdPlayerController(PlayerOwner);

    if (NumBagsToSet < 0)
    {
        NumBagsToSet = 0;
    }
    else if (NumBagsToSet > MaxBagsAllowed)
    {
        NumBagsToSet = MaxBagsAllowed;
    }

    PlayerDataStore = SpeedrunController.OnlinePlayerData;
    if (PlayerDataStore != none)
    {
        ProfileDataProvider = PlayerDataStore.ProfileProvider;
        if (ProfileDataProvider != none)
        {
            Profile = TdProfileSettings(ProfileDataProvider.Profile);
        }
    }

    if (Profile == none)
    {
        return;
    }

    // Bags in Mirror's Edge are bitmask
    if (NumBagsToSet == 0)
    {
        NewBagMaskValue = 0;
    }
    else if (NumBagsToSet == MaxBagsAllowed) 
    {
        NewBagMaskValue = (1 << MaxBagsAllowed) - 1;
        if (MaxBagsAllowed == 31)
        { // Max for a positive signed 32-bit int if all bits are used
            NewBagMaskValue = 0x7FFFFFFF;
        }
        else if (MaxBagsAllowed >= 32)
        {
            NewBagMaskValue = -1;
        }
    }
    else
    {
        NewBagMaskValue = (1 << NumBagsToSet) - 1;
    }

    HiddenBagMaskID = 1020; // TdProfileSettings.TDPID_HiddenBagMask

    if (Profile.SetProfileSettingValueInt(HiddenBagMaskID, NewBagMaskValue))
    {
        if (PlayerDataStore != none)
        {
            PlayerDataStore.SaveProfileData();
            SpeedrunController.CallPopUp(PUT_Bag, 5);
        }
    }
}

exec function LoadSavedCheckpointTime()
{
    local int TargetProfileID;
    local int StretchNumber; // For GetTotalTimeOnlyForStretch
    local float RetrievedTotalTime;
    local bool bSuccess;
    
    if (Profile == none)
    {
        Profile = SpeedrunController.GetProfileSettings();
        if (Profile == none)
        {
            return;
        }
    }

    TargetProfileID = 1204; // TDPID_StretchTime_04

    // Convert ProfileID to 1-based "stretch" number for GetTotalTimeOnlyForStretch
    // TDPID_StretchTime_00 = 1200. So 1204 is (1204 - 1200) + 1 = 5th stretch.
    if (TargetProfileID >= Profile.TDPID_StretchTime_00 && TargetProfileID <= Profile.TDPID_StretchTime_33) 
    {
        StretchNumber = (TargetProfileID - Profile.TDPID_StretchTime_00) + 1;
    }

    bSuccess = Profile.GetTotalTimeOnlyForStretch(StretchNumber, RetrievedTotalTime);

    if (bSuccess)
    {
        GameData.TimeAttackClock = RetrievedTotalTime;
    }
    else
    {
        PlayerOwner.ClientMessage("LoadSavedCheckpointTime: Failed to load time from profile ID " $ TargetProfileID $ ". Timer not changed.", 'Warning');
    }
}


// DrawLivingHUD & DrawLoadRemovedTimer: HUD rendering
function DrawLivingHUD()
{
    local TdSPStoryGame Game;
    local float PosY;
    local bool bCheatsActive;
    local bool bIllegalFramerate;

    super(TdSPHUD).DrawLivingHUD();

    Game = TdSPStoryGame(WorldInfo.Game);

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

function DrawLoadRemovedTimer(TdSPStoryGame Game, bool bBothTimes)
{
    local string TimeString, SplitString, SavedSplit;
    local float RTime;
    local Vector2D pos;
    local float DSOffset;
    local string MapName;

    if(GameData == none)
    {
        return;
    }

    MapName = WorldInfo.GetMapName();

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
    Canvas.Font = TinyFont;
    DSOffset = (TinyFont.GetMaxCharHeight() * TinyFont.GetScalingFactor(float(Canvas.SizeY))) * FontDSOffset;
    DSOffset = FMax(1, DSOffset);

    if (MapName == "Tutorial_p" || MapName == "Edge_p")
    {
        SplitString = "";
    }
    else
    {
        SavedSplit = SaveLoad.LoadData("LastSplitTime");
        if (SavedSplit != "")
        {
            SplitString = "LAST SPLIT - " $ SavedSplit;
        }
        else
        {
            SplitString = "";
        }
    }
    ComputeHUDPosition(SplitPos.X, SplitPos.Y, 0, 0, pos);
    DrawTextWithOutLine(pos.X, pos.Y, DSOffset, DSOffset, SplitString, WhiteColor);
}

// Command for toggling timer visibility
exec function ToggleTimer()
{
    bTimerVisible = !bTimerVisible;
    SaveLoad.SaveData("TimerHUDVisible", bTimerVisible ? "true" : "false");
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

// Save timer values on HUD destruction
event Destroyed()
{
    local string ChapterName;

    if (SaveLoad == none)
    {
        SaveLoad = new class'SaveLoadHandlerSTHUD';
    }

    // If the level was completed, save the final split time too
    if (bLevelCompleted)
    {
        LastSplitTime = GameData.TimeAttackClock;
        SaveLoad.SaveData("LastSplitTime", GetTimeString(LastSplitTime));
        if (WorldInfo.GetMapName() == "Edge_p")
        {
            ChapterName = "Prologue";
        }
        else if (WorldInfo.GetMapName() == "Escape_p")
        {
            ChapterName = "Chapter 1";
        }
        else if (WorldInfo.GetMapName() == "Stormdrain_p")
        {
            ChapterName = "Chapter 2";
        }
        else if (WorldInfo.GetMapName() == "Cranes_p")
        {
            ChapterName = "Chapter 3";
        }
        else if (WorldInfo.GetMapName() == "Subway_p")
        {
            ChapterName = "Chapter 4";
        }
        else if (WorldInfo.GetMapName() == "Mall_p")
        {
            ChapterName = "Chapter 5";
        }
        else if (WorldInfo.GetMapName() == "Factory_p")
        {
            ChapterName = "Chapter 6";
        }
        else if (WorldInfo.GetMapName() == "Boat_p")
        {
            ChapterName = "Chapter 7";
        }
        else if (WorldInfo.GetMapName() == "Convoy_p")
        {
            ChapterName = "Chapter 8";
        }
        SpeedrunController.ClientMessage(ChapterName $ " split - " $ GetTimeString(LastSplitTime));

        SaveLoad.SaveData("bNewMapSavePending", "true");
    }
    else
    {
        SaveLoad.SaveData("bNewMapSavePending", "false");
    }

    SaveLoad.SaveData("TimeAttackClock", string(GameData.TimeAttackClock));
    
    super.Destroyed();
}

// Trainer HUD, speed, etc.

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
        Y = 0.80 * Canvas.SizeY;
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
    SplitPos=(X=1000,Y=88)
    SpeedPos=(X=1060,Y=605)
    RunCompleteLiveSplitASLMarker = 123456789
    bTimerVisible = true
    ShowSpeed = false
    ShowTrainerHUDItems = false
    ShowMacroFeedback = false
    ShowBagHUD = true
    HundredPercentMode = false
}