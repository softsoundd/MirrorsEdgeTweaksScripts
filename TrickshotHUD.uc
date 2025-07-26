/**
 *  Receives kill notifs from the TrickshotPlayerController class to display hitmarkers.
 */

class TrickshotHUD extends TdSPHUD
    transient
    config(Game)
    hidecategories(Navigation);

var SaveLoadHandlerTSHUD SaveLoad;

var string HitmarkerText;
var float HitmarkerDisplayTime;
var float HitmarkerPersistDuration;
var float HitmarkerFadeDuration;

var bool ShowHitmarker;

function DrawTextWithShadow(string Text, float X, float Y, float ShadowOffset)
{
    local Color ShadowColor, TextColor;
    local float CurrentFade;
    local byte AlphaByte;
    local byte ShadowAlphaByte;

    ShadowColor = FontDSColor;
    TextColor = WhiteColor;

    CurrentFade = FClamp(FadeAmount, 0.0, 1.0);

    AlphaByte = byte(255.0 * CurrentFade);
    ShadowAlphaByte = byte(float(FontDSColor.A) * Square(CurrentFade));

    ShadowColor.A = ShadowAlphaByte;
    TextColor.A = AlphaByte;

    Canvas.SetPos(X + 3, Y - 40);
    Canvas.DrawColor = ShadowColor;
    Canvas.DrawText(Text, False, 1.6, 1.6);

    Canvas.SetPos(X + 1, Y - 39);
    Canvas.DrawColor = ShadowColor;
    Canvas.DrawText(Text, False, 1.6, 1.6);

    Canvas.SetPos(X + 3, Y - 39);
    Canvas.DrawColor = ShadowColor;
    Canvas.DrawText(Text, False, 1.6, 1.6);

    Canvas.SetPos(X + 1, Y - 40);
    Canvas.DrawColor = ShadowColor;
    Canvas.DrawText(Text, False, 1.6, 1.6);

    Canvas.SetPos(X + 2, Y - 35);
    Canvas.DrawColor = TextColor;
    Canvas.DrawText(Text, False, 1.4, 1.4);
}

function PostBeginPlay()
{
    super.PostBeginPlay();

    SaveLoad = new class'SaveLoadHandlerTSHUD';
    if (SaveLoad != None)
    {
        ShowHitmarker = (SaveLoad.LoadData("ShowHitmarker") == "") ? true : bool(SaveLoad.LoadData("ShowHitmarker"));
    }
    else
    {
        ShowHitmarker = true;
    }
}

function Tick(float DeltaTime)
{
    super(TdHUD).Tick(DeltaTime);

    EffectManager.Update(DeltaTime, RealTimeRenderDelta);
}

// Overridden parent function to return early so we cancel the scope black fade.
// This prevents the default screen blink effect when certain actions occur.
exec function TriggerCustomBlink(float InFadeOutTime, float InFadeInTime, optional bool bRealTime, optional delegate<OnMaxFade> InOnMaxFade)
{
    return;
}

function DrawLivingHUD()
{
    super.DrawLivingHUD();
    DrawHitmarker();
}

function DrawHitmarker()
{
    local float CurrentTime, ElapsedTime, Y, ShadowOffset;
    local TdPawn PlayerPawn;

    CurrentTime = WorldInfo.RealTimeSeconds;
    PlayerPawn = TdPawn(PlayerOwner.Pawn);

    if (PlayerPawn != None)
    {
        ShadowOffset = 0.0;
        Canvas.Font = Class'Engine'.static.GetLargeFont();

        if (ShowHitmarker && HitmarkerText != "")
        {
            ElapsedTime = CurrentTime - HitmarkerDisplayTime;

            if (ElapsedTime <= (HitmarkerPersistDuration + HitmarkerFadeDuration))
            {
                if (ElapsedTime <= HitmarkerPersistDuration)
                {
                    FadeAmount = 1.0;
                }
                else
                {
                    FadeAmount = 1.0 - ((ElapsedTime - HitmarkerPersistDuration) / HitmarkerFadeDuration);
                }
                FadeAmount = FClamp(FadeAmount, 0.0, 1.0);

                Y = Canvas.SizeY * 0.50;
                Canvas.bCenter = true;

                DrawTextWithShadow(HitmarkerText, 0, Y, ShadowOffset);
                Canvas.bCenter = false;
            }
            else
            {
                HitmarkerText = "";
                FadeAmount = 0.0;
            }
        }
        else if (HitmarkerText != "")
        {
            HitmarkerText = "";
            FadeAmount = 0.0;
        }
    }
}

exec function DisplayHitmarker()
{
    HitmarkerText = "X";
    HitmarkerDisplayTime = WorldInfo.RealTimeSeconds;
    HitmarkerPersistDuration = 0.10;
    HitmarkerFadeDuration = 0.25;
    FadeAmount = 1.0;
}


exec function ToggleHitmarker()
{
    ShowHitmarker = !ShowHitmarker;
    if (SaveLoad != None)
    {
        SaveLoad.SaveData("ShowHitmarker", string(ShowHitmarker));
    }

    if (!ShowHitmarker)
    {
        HitmarkerText = "";
        FadeAmount = 0.0;
    }
}

defaultproperties
{
    ShowHitmarker = true
    FontDSColor=(B=0,G=0,R=0,A=255)
    FadeAmount=1.0
    HitmarkerPersistDuration = 0.25
    HitmarkerFadeDuration = 0.25
}