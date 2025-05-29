class TdProfileSettingsExtended extends TdProfileSettings
    native;

// Define a constant for our new test ID for clarity
const TDPID_SpeedrunTime = 1234;

defaultproperties
{
    //ProfileSettingIds.Add((124: 1234))
    DefaultSettings.Add((Owner=OPPO_Game,ProfileSetting=(PropertyId=1234,Data=(Type=SDT_Int32,Value1=1024))))
    //ProfileMappings.Add(((Id=1234,Name="SpeedrunTime")))
}