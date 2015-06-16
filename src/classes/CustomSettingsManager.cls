public with sharing class CustomSettingsManager {

    public static String GT_HELP_ACCOUNT_ID = 'GT_HELP_ACCOUNT_ID';
    public static String CREATE_CONTACT_IN_CASE_TRIGGER_ENABLED = 'CREATE_CONTACT_IN_CASE_TRIGGER_ENABLED'; 
    public static String OPP_EXPIRY_DATE_TO_CON_TRIG_ENABLED =  'OPP_EXPIRY_DATE_TO_CON_TRIG_ENABLED';
    
    public static Map<String,Config_Settings__c> getAllConfigSettings()
    {
        return Config_Settings__c.getAll();
    }
    
    public static Boolean getConfigSettingBooleanVal(String settingName)
    {
        return CustomSettingsManager.getConfigSetting(settingName).Checkbox_Value__c;
    }
    
    public static String getConfigSettingStringVal(String settingName)
    {
        return CustomSettingsManager.getConfigSetting(settingName).Text_Value__c;
    }
    
    public static Decimal getConfigSettingNumberVal(String settingName)
    {
        return CustomSettingsManager.getConfigSetting(settingName).Number_Value__c;
    }
    
    public static Config_Settings__c getConfigSetting(String settingName)
    {
        return Config_Settings__c.getAll().get(settingName);
    }
 
    public static TestMethod void testCustomSettingsManager()
    {
        CustomSettingsManager.getAllConfigSettings();
        CustomSettingsManager.getConfigSetting(CustomSettingsManager.GT_HELP_ACCOUNT_ID);
        CustomSettingsManager.getConfigSettingBooleanVal(CustomSettingsManager.GT_HELP_ACCOUNT_ID);
        CustomSettingsManager.getConfigSettingStringVal(CustomSettingsManager.GT_HELP_ACCOUNT_ID);
        CustomSettingsManager.getConfigSettingNumberVal(CustomSettingsManager.GT_HELP_ACCOUNT_ID);
        
        CustomSettingsManager.getConfigSettingBooleanVal(CustomSettingsManager.CREATE_CONTACT_IN_CASE_TRIGGER_ENABLED);
        CustomSettingsManager.getConfigSettingBooleanVal(CustomSettingsManager.OPP_EXPIRY_DATE_TO_CON_TRIG_ENABLED);
    } 
}