public with sharing class pkb_SettingsController {

  /* ***** DEFAULT SETTINGS TO BE USED ELSEWHERE IN APP WHEN CUSTOM SETTINGS FOR CURRENT SITE CANNOT BE FOUND ***** */
  public final static Boolean DEFAULT_DISPLAY_SUMMARY = true;
  public final static Integer DEFAULT_RESULTS_SIZE = 5;
  public final static Integer DEFAULT_POPULAR_SIZE = 3;
  public final static Integer DEFAULT_RELATED_SIZE = 3;
  public final static Boolean DEFAULT_MULTI_LANGUAGE = false;
  public final static Boolean DEFAULT_CREATE_ACCOUNT_CONTACT = false;
  public final static String DEFAULT_LANGUAGE = 'en_US';  

  /* ***** URL PARAM CONSTANTS AND GETTERS ***** */
  private final static String CREATE_SETTINGS_PARAM = 'createSettings';
  private final static String CREATE_SETTINGS_VALUE = '1';
  public String createSettingsParam { get { return CREATE_SETTINGS_PARAM; } }
  public String createSettingsValue { get { return CREATE_SETTINGS_VALUE; } }  
  
  /* ***** STANDARD CONSTRUCTOR (not currently used) ***** */
  public pkb_SettingsController() { }
  
  /* ***** CONSTRUCTOR FOR USE AS VF CONTROLLER EXTENSION ***** */
  public pkb_SettingsController(ApexPages.StandardController sc) {
    theSC = sc;
    theSettings = (PKB__c)theSC.getRecord();
    selectedSettings = theSC.getRecord().Id;

    // if creating new settings, set the defaults for the article size fields
    if (theSettings.Id == null) {
    	theSettings.Popular_Articles_Size__c = DEFAULT_POPULAR_SIZE;
    	theSettings.Related_Articles_Size__c = DEFAULT_RELATED_SIZE;
    	theSettings.Results_Page_Size__c = DEFAULT_RESULTS_SIZE;
    }

    if (!isBlank(theSettings.Selected_Languages__c)) selectedLanguages = theSettings.Selected_Languages__c.split(';');
  }

  /* ***** STANDARD CONTROLLER AND RECORD PROPS ***** */
  public ApexPages.StandardController theSC  { get; set; }
  public PKB__c theSettings                  { get; set; }


  /* ***** GENERAL DISPLAY AND PROCESSING CONDITIONALS ***** */

  public Boolean settingsPicked { get { return selectedSettings != null; } }
  public Boolean settingsExist { get { return !settingsMap.isEmpty(); } }

  // whenever the CREATE_SETTINGS_PARAM has any value, that indicates that the new settings form should be displayed
  public Boolean creatingSettings {
    set;
    get {
      if (creatingSettings == null)  {
        creatingSettings = !isBlank(ApexPages.currentPage().getParameters().get(CREATE_SETTINGS_PARAM));
      }
      return creatingSettings;
    }
  }



  /* ***** PROPS AND METHODS FOR SETTINGS CREATION AND EDITING PROCESSING ***** */

  // stores the selection from the settings options picklist on the page, valid values are values of the Name field for any PKB__c settings collection
  public String selectedSettings { get; set; }

  public PageReference saveSettings() {

    if (getMatchingSite(theSettings.Name) == null) {
      theSettings.Name.addError('The Site Name you entered does not match the name of any existing Site.');
    	return null;
    }
    theSettings.Selected_Languages__c = pkb_Controller.join(selectedLanguages, ';');
    theSC.save();
    PageReference p = Page.pkb_Settings;
    p.getParameters().put('id', theSC.getRecord().Id);
    p.setRedirect(true);
    return p;
  }
  
  // map of all settings collections of type PKB__c, note that the key of this map is the value of the Name field for that collection
  private Map<String,PKB__c> settingsMap { 
    get {
      if (settingsMap == null) settingsMap = PKB__c.getAll();
      return settingsMap;
    }
    private set;
  }
  
  // produces set of picklist options from the settingsMap, uses Id as value and Name as label
  public List<SelectOption> settingsOptions {
    get {
      settingsOptions = new List<SelectOption>();
      settingsOptions.add(new SelectOption('', '---None---'));
      for (String s : settingsMap.keySet()) {
        settingsOptions.add(new SelectOption(settingsMap.get(s).Id, s));          
      }
      return settingsOptions;
    }
    private set;
  }
  
  public List<String> selectedLanguages { get; set; }

  public Integer allLanguageOptionsSize { get { return allLanguageOptions.size(); } }
  public List<SelectOption> allLanguageOptions { get { return pkb_Controller.allLanguageOptions; } }
  
  public static Boolean isBlank(String s) {
    return (s == null || s == '');
  }

  public static Site getMatchingSite(String name) {
    List<Site> sites = [select Id, Name from Site where Name = :name];
    if (!sites.isEmpty()) return sites[0];
    if (sites.isEmpty() && !isRunningTest) return null;
    return new Site();
  }

  public static Boolean isRunningTest {
  	set;
  	get {
  		if (isRunningTest == null) isRunningTest = false;
  		return isRunningTest;
  	}
  }
}