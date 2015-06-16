/*
 * ExclusivePlacement:
 *  This class provides following methodes:
 *  - check the exclusive_Placement - aka  ExclusivePlacement - of Opportunities, show results in a force-page.
 *
 * It is designed for using with force page.
 *
 * Author:
 *  Benhui.Chen@avendio.de

Change log; 
- 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level

 */
public class ExclusivePlacement {
  
  // Default Site
  private static final String  DEFAULT_SITE = 'gumtree.co.uk';
  
  // Default Placement
  private static final String DEFAULT_PLACEMENT = 'All';
  
  // Default AdvertisingMedium
  private static final String DEFAULT_MEDIUM = 'All';
  
  // Maximal number of days.
  private static final Integer MAX_NUMBER_DAYS = 60;

  // Number of weeks to group.
  private static final Integer NUMBER_WEEK_GROUP = 2;

  // The rum-time Option, use dummy object exclusive_Placement_option__c.
  private exclusivePlacementoption__c optionen      = null;
  private exclusivePlacementoption__c prev_optionen = null;

  // Date related stuff.
  private DateCollection    currDate        = null;
  
  // Website Option/Selection List  
  private  List<SelectOption>  websiteOptionList    = null;
  private  List<String>    websiteSelectedList    = null;

  // Placement Option/Selection List  
  private  List<SelectOption>  placementOptionList    = null;
  private List<String>    placementSelectedList  = null;  

  // AdvertisingMedium Option/Selection List  
  private  List<SelectOption>  mediumOptionList    = null;
  private List<String>    mediumSelectedList    = null;  

  // Results: a list of all Website objects.
  private List<Website>    websiteList        = null;

  // A map to hold WebsiteName, PlacementName, MediumName
  private Map<String, Map<String, Set<String>>>  SitePlacementMediumMap  = null;

  public ExclusivePlacement() {
    system.debug('ExclusivePlacement() >>>>>>>>>>');
    setOptionen();
  }

  public ExclusivePlacement(ApexPages.StandardController controller) {
    system.debug('ExclusivePlacement(...) >>>>>>>>>>');
    setOptionen();
  }

  private void setOptionen() {
    system.debug('setOptionen() >>>>>>>>>>');
    if (optionen == null) {
      optionen = new exclusivePlacementoption__c();
    
      optionen.StartDate__c      = system.today();
      optionen.EndDate__c          = system.today() + 30;
      optionen.Platform__c        = DEFAULT_SITE;
      optionen.Placement__c      = DEFAULT_PLACEMENT;
      optionen.Advertising_Medium__c  = DEFAULT_MEDIUM;
      
      prev_optionen = optionen.clone();

      currDate = new DateCollection(optionen.StartDate__c, optionen.EndDate__c);
    }
  }

  public exclusivePlacementoption__c getOptionen() {
    system.debug('getOptionen() >>>>>>>>>>');
    system.debug('>>>>>>>>>> Optionen:' + optionen);
    return optionen;
  }

  public PageReference updateCW() {
    system.debug('updateCW() >>>>>>>>>>');    
    system.debug('>>>>>>>>>> optionen.StartDate__c: ' + String.valueOf(optionen.StartDate__c));    
    system.debug('>>>>>>>>>> prev_optionen.StartDate__c: ' + String.valueOf(prev_optionen.StartDate__c));    
    system.debug('>>>>>>>>>> optionen.EndDate__c: ' + String.valueOf(optionen.EndDate__c));    
    system.debug('>>>>>>>>>> prev_optionen.EndDate__c: ' + String.valueOf(prev_optionen.EndDate__c));
    
    if (optionen.StartDate__c == null || optionen.EndDate__c== null) {
      currDate  = null;
      websiteList  = null;
    }
    else if (optionen.EndDate__c < optionen.StartDate__c) {
      currDate  = null;
      websiteList  = null;
    }
    else if (optionen.StartDate__c.daysBetween(optionen.EndDate__c) > ExclusivePlacement.MAX_NUMBER_DAYS) {
      currDate  = null;
      websiteList  = null;
    }    
    else if (prev_optionen.StartDate__c != optionen.StartDate__c || prev_optionen.EndDate__c != optionen.EndDate__c) {
      currDate          = null;
      websiteList          = null;
      prev_optionen.StartDate__c = optionen.StartDate__c ;
      prev_optionen.EndDate__c = optionen.EndDate__c ;      

      currDate = new DateCollection(optionen.StartDate__c, optionen.EndDate__c );
    }
    return null;
  }

  public String getCW() {
    system.debug('getCW() >>>>>>>>>>');
    if (currDate == null) {
      if (optionen.StartDate__c == null || optionen.EndDate__c == null) {
        return '';
      }
      else if (optionen.EndDate__c < optionen.StartDate__c) {
        MyException err = new MyException('The End-Date must be after Start-Date.');
        Apexpages.addMessages(err);
        return 'The End-Date must be after Start-Date.';
      }
      else if (optionen.StartDate__c.daysBetween(optionen.EndDate__c) > ExclusivePlacement.MAX_NUMBER_DAYS) {
        MyException err = new MyException('The Date-Range is too big, maximal ' + ExclusivePlacement.MAX_NUMBER_DAYS + ' days are allowed.');
        Apexpages.addMessages(err);
        return 'The Date-Range is too big, maximal ' + ExclusivePlacement.MAX_NUMBER_DAYS + ' days are allowed.';
      }
      return null;
    }
    return currDate.calendarWeekRange;
  }

  public List<String> getCWGroups() {
    system.debug('getCWGroups() >>>>>>>>>>');
    if (currDate == null) {
      return null;
    }
    return currDate.calendarWeekGroup;
  }

  public List<SelectOption> getWebsiteOptionList() {
    system.debug('getWebsiteOptionList() >>>>>>>>>>');
    if (websiteOptionList == null) {
      websiteOptionList = new List<SelectOption>();
      for (Site__c s :[select Id, Name, Active__c, SortOrder__c from Site__c where Active__c = TRUE order by SortOrder__c asc]){
        websiteOptionList.add(new SelectOption(s.Name, s.Name));
      }
    }
    return websiteOptionList;
  }

  public PageReference updateWebsite() {
    system.debug('updateWebsite() >>>>>>>>>>');    
    system.debug('>>>>>>>>>> optionen.Platform__c: ' + optionen.Platform__c);    
    system.debug('>>>>>>>>>> prev_optionen.Platform__c: ' + prev_optionen.Platform__c);
    if (optionen.Platform__c != prev_optionen.Platform__c) {
      websiteList              = null;
      placementOptionList          = null;
      mediumOptionList          = null;
      optionen.Placement__c        = DEFAULT_PLACEMENT;
      optionen.Advertising_Medium__c    = DEFAULT_MEDIUM;
      prev_optionen.Platform__c = optionen.Platform__c;
      prev_optionen.Placement__c      = optionen.Placement__c;
      prev_optionen.Advertising_Medium__c  = optionen.Advertising_Medium__c;
    }
    return null;    
  }  

  public List<SelectOption> getPlacementOptionList() {
    system.debug('getPlacementOptionList() >>>>>>>>>>');
    if (placementOptionList == null) {
      getSitePlacementMediumMap();

      List<String> dummy = new List<String>();
      if (SitePlacementMediumMap.get(optionen.Platform__c) != null) {
        dummy.addAll(SitePlacementMediumMap.get(optionen.Platform__c).keySet());
        dummy.sort();
      }

      placementOptionList = new List<SelectOption>();
      placementOptionList.add(new SelectOption(DEFAULT_PLACEMENT, DEFAULT_PLACEMENT));    
      for (String s : dummy) {
        placementOptionList.add(new SelectOption(s, s));    
      }    
    }
    return placementOptionList;
  }

  public PageReference updatePlacement() {
    system.debug('updatePlacement() >>>>>>>>>>');
    system.debug('>>>>>>>>>> optionen.Placement__c: ' + optionen.Placement__c);    
    system.debug('>>>>>>>>>> prev_optionen.Placement__c: ' + prev_optionen.Placement__c);
    if (optionen.Placement__c != prev_optionen.Placement__c) {
      websiteList              = null;
      mediumOptionList          = null;
      optionen.Advertising_Medium__c    = DEFAULT_MEDIUM;
      prev_optionen.Placement__c      = optionen.Placement__c;
      prev_optionen.Advertising_Medium__c  = optionen.Advertising_Medium__c;
    }
    return null;    
  }  

  public List<SelectOption> getMediumOptionList() {
    system.debug('getMediumOptionList() >>>>>>>>>>');
    if (mediumOptionList == null) {
      getSitePlacementMediumMap();

      List<String> dummy = new List<String>();
      if (SitePlacementMediumMap.get(optionen.Platform__c) != null &&
          SitePlacementMediumMap.get(optionen.Platform__c).get(optionen.Placement__c) != null)
      {
        dummy.addAll(SitePlacementMediumMap.get(optionen.Platform__c).get(optionen.Placement__c));
        dummy.sort();
      }

      mediumOptionList = new List<SelectOption>();
      mediumOptionList.add(new SelectOption(DEFAULT_MEDIUM, DEFAULT_MEDIUM));    
      for (String s : dummy) {
        mediumOptionList.add(new SelectOption(s, s));    
      }    
    }
    return mediumOptionList;
  }

  public PageReference updateMedium() {
    system.debug('updateMedium() >>>>>>>>>>');
    system.debug('>>>>>>>>>> optionen.Advertising_Medium__c: ' + optionen.Advertising_Medium__c);    
    system.debug('>>>>>>>>>> prev_optionen.Advertising_Medium__c: ' + prev_optionen.Advertising_Medium__c);
    if (optionen.Advertising_Medium__c != prev_optionen.Advertising_Medium__c) {
      websiteList              = null;
      prev_optionen.Advertising_Medium__c  = optionen.Advertising_Medium__c;
    }
    return null;    
  }  

  private Map<String, Map<String, Set<String>>> getSitePlacementMediumMap() {
    system.debug('getSitePlacementMediumMap() >>>>>>>>>>');
    if (SitePlacementMediumMap == null) {
      SitePlacementMediumMap = new Map<String, Map<String, Set<String>>>();
    }
    if (!SitePlacementMediumMap.containsKey(optionen.Platform__c)) {
      
      String query =  'select Site__c, Site__r.Name, Placement__c, Placement__r.Name, Advertising_Medium__c, Advertising_Medium__r.Name ' + 
              'from Product2 ' +
              'where exclusive_Placement__c = true and Site__r.Name in ' + splitValue(optionen.Platform__c) + ' ' +
              'order by Site__r.Name, Placement__r.Name, Advertising_Medium__r.Name asc';  
      
              
                  
      for (Product2 m :Database.query(query)){
        
        if (m.Site__c == null || m.Site__r.Name == null ||
            m.Placement__c == null || m.Placement__r.Name == null ||
            m.Advertising_Medium__c == null || m.Advertising_Medium__r.Name == null)
        {
          continue;
        } 
        
        if (SitePlacementMediumMap.containsKey(m.Site__r.Name)) {
          if (SitePlacementMediumMap.get(m.Site__r.Name).containsKey(m.Placement__r.Name)) {
            SitePlacementMediumMap.get(m.Site__r.Name).get(m.Placement__r.Name).add(m.Advertising_Medium__r.Name);
          } else {
            Set<String> lst = new Set<String>();
            lst.add(m.Advertising_Medium__r.Name);
            SitePlacementMediumMap.get(m.Site__r.Name).put(m.Placement__r.Name, lst);
          }
        } else {
          Set<String> lst = new Set<String>();
          lst.add(m.Advertising_Medium__r.Name);
          Map<String, Set<String>> mp = new Map<String, Set<String>>();
          mp.put(m.Placement__r.Name, lst);
          SitePlacementMediumMap.put(m.Site__r.Name, mp);
        }
      }
    }
    return SitePlacementMediumMap;
  }

  public String getStartDate() {
    if (currDate == null) {
      return null;
    }
    system.debug('getStartDate() >>>>>>>>>>');
    return currDate.startDate_LNK;
  }

  public String getEndDate() {
    if (currDate == null) {
      return null;
    }
    system.debug('getEndDate() >>>>>>>>>>');
    return currDate.endDate_LNK;
  }

  public List<Date> getDays() {
    if (currDate == null) {
      return null;
    }
    system.debug('getDays() >>>>>>>>>>');
    return currDate.days;
  }

  public List<List<String>> getWeekDays() {
    if (currDate == null) {
      return null;
    }
    system.debug('getWeekDays() >>>>>>>>>>');
    return currDate.weekdays;
  }

  public List<Website> getWebsites () {
    if (currDate == null) {
      return null;
    }
    system.debug('getWebsites() >>>>>>>>>>');
    if (websiteList == null) {
      websiteList = new List<Website>();
      
      Website    curr_website  = null;
      Placement  curr_placement  = null;
      Medium    curr_medium    = null;

      for (exclusive_Placement__c bp : getExclusivePlacement()) {
        if (bp.Product__c == null) {
          continue;
        }
        
        // Site
        if (bp.Product__r.Site__c == null || bp.Product__r.Site__r.Name == null) {
          continue;
        }
        if (curr_website == null || bp.Product__r.Site__r.Name != curr_website.name) {
          // New Site.
          curr_website    = new Website();
          
          curr_website.name  = bp.Product__r.Site__r.Name;
          curr_placement    = null;
          curr_medium      = null;
          
          websiteList.add(curr_website);
        }
        
        // Placement, name might be null.
        String plz_name = '';
        if (bp.Product__r.Placement__c != null && bp.Product__r.Placement__r.Name != null) {
          plz_name = bp.Product__r.Placement__r.Name;
        }
        if (curr_placement == null || plz_name != curr_placement.name) {
          // New Placement
          curr_placement    = new Placement();
          
          curr_placement.name  = plz_name;
          curr_medium      = null;

          curr_website.placements.add(curr_placement);
        }
        
        // AdvertisingMedium, name might be null.
        String wf_name = '';
        if (bp.Product__r.Advertising_Medium__c != null && bp.Product__r.Advertising_Medium__r.Name != null) {
          wf_name = bp.Product__r.Advertising_Medium__r.Name;
        }
        if (curr_medium == null || wf_name != curr_medium.name) {
          // New AdvertisingMedium
          curr_medium      = new Medium();
          
          curr_medium.name  = wf_name;

          // Create an ReservationDay for each day.
          for (Integer i = 0; i < currDate.days.size(); i++) {
            ReservationDay bt = new ReservationDay();
            bt.day    = currDate.days.get(i);            
            curr_medium.reservationDays.add(bt);
          }          

          curr_placement.mediums.add(curr_medium);
        }
        
        // Set, Update Counter und probability.
        Integer idx = currDate.days.get(0).daysBetween(bp.Date__c);
        if (idx >= 0 && idx < currDate.days.size()) {
          curr_medium.reservationDays.get(idx).counter += 1;
          if (curr_medium.reservationDays.get(idx).probability < bp.Opportunity__r.Probability) {
            curr_medium.reservationDays.get(idx).probability = bp.Opportunity__r.Probability;
          }          
        }
      }
      system.debug('>>>>>>>>>> websiteList: ' + websiteList);
    }

    return websiteList;
  }

  private exclusive_Placement__c[] getExclusivePlacement() {
    system.debug('getExclusivePlacement() >>>>>>>>>>');
    String query  = 'select ' +
              'Id, Product__c, Opportunity__c, Date__c, Opportunity__r.Probability, ' +
              'Product__r.Site__c, Product__r.Placement__c, Product__r.Advertising_Medium__c, ' +
              'Product__r.Site__r.Name, Product__r.Placement__r.Name, Product__r.Advertising_Medium__r.Name ' +
            'from ' +
              'exclusive_Placement__c ' +
            'where ' +
              'Product__r.Site__r.Name in ' + splitValue(optionen.Platform__c) + ' ' +
                    'and Product__r.exclusive_Placement__c = true ' + 
              'and Date__c >= ' + currDate.startDate_SQL + ' and Date__c <= ' + currDate.endDate_SQL + ' ' +
              'and Opportunity__r.Probability >= 25 ' +
              'and (Opportunity__r.StageName = \'Contract\' or Opportunity__r.StageName = \'Booking\') ';
    if (optionen.Placement__c != null && optionen.Placement__c != '' && optionen.Placement__c != DEFAULT_PLACEMENT) {
          query    += 'and Product__r.Placement__r.Name in ' + splitValue(optionen.Placement__c) + ' ';
    }
    if (optionen.Advertising_Medium__c != null && optionen.Advertising_Medium__c != '' && optionen.Advertising_Medium__c != DEFAULT_MEDIUM) {
          query    += 'and Product__r.Advertising_Medium__r.Name in ' + splitValue(optionen.Advertising_Medium__c) + ' ';
    }
    query    +=  'order by Product__r.Site__r.Name, Product__r.Placement__r.Name, Product__r.Advertising_Medium__r.Name, Date__c asc'; 

    return Database.query(query);
  }

  private String splitValue(String val) {
    if(val == null || val == '') return '(\'null\')'; // Bunhor: added on 24-Feb-2014
    val = val.replace('[', '').replace(']', '');
    String res = '(';
    for (String w : val.split(',', 0)) {
      if (res != '(') {
        res += ',';
      }
      res += '\'' + w.trim() + '\'';
    }
    res += ')';
    return res;
  }

  public PageReference generateReport() {
    system.debug('generateReport() >>>>>>>>>>');
    return null;
  }

  public Boolean getReady() {
    system.debug('getReady() >>>>>>>>>>');
    return (currDate != null ? true : false);
  }

  public class DateCollection {
    protected String startDate_SQL           = null;  // Start date, in SQL Query Syntax. 
    protected String endDate_SQL             = null;  // End date, in SQL Query Systax
    protected String startDate_LNK           = null;  // Start date, in SF Link (to Report) Syntax. 
    protected String endDate_LNK             = null;  // End date, in SF Link (to Report) Syntax.
    protected String startWeek               = null;  // CalendarWeek of start date.
    protected String endWeek                 = null;  // CalendarWeek of end date.
    protected String calendarWeekRange       = null;  // A String with Start- und End-CalendarWeek
    protected List<Date> days                = new List<Date>();      // List of days
    protected List<List<String>> weekdays    = new List<List<String>>();  // List of Weekday und date.
    protected List<String> calendarWeeks     = new List<String>();      // List of CalendarWeeks.   
    protected List<String> calendarWeekGroup = new List<String>();      // List of grouped CalendarWeek.   
    
    public DateCollection(Date s, Date e) {
      system.debug('DateCollection() >>>>>>>>>>');
      Time t = Time.newInstance(0,0,0,0);

      Datetime dt = Datetime.newInstance(s, t);
      startDate_SQL = dt.format('yyyy-MM-dd');
      startDate_LNK = dt.format('MM/dd/yyyy');
      startWeek     = String.valueOf(CalendarWeek.getISOWeekNumber(s));
      if (startWeek.length() < 2) {
        startWeek = '0' + startWeek;
      }
      
      dt = Datetime.newInstance(e, t);
      endDate_SQL = dt.format('yyyy-MM-dd');
      endDate_LNK = dt.format('MM/dd/yyyy');
      endWeek     = String.valueOf(CalendarWeek.getISOWeekNumber(e));
      if (endWeek.length() < 2) {
        endWeek = '0' + endWeek;
      }
      
      calendarWeekRange = 'CW ' + startWeek;
      if (endWeek != startWeek) {
        calendarWeekRange += ' - CW ' + endWeek; 
      }
      
      String last_cw = null;
      for (Date d = s; d <= e; d = d.addDays(1)) {
        days.add(d);
        
        dt = Datetime.newInstance(d, t);
        List<String> lst = new List<String>();
        lst.add(dt.format('E'));
        lst.add(dt.format('dd/MM/yyyy'));
        weekdays.add(lst);
        
        String cw = String.valueOf(CalendarWeek.getISOWeekNumber(d));
        if (cw.length() < 2) {
          cw = '0' + endWeek;
        }
        if (cw != last_cw) {
          calendarWeeks.add('CW ' + cw);
          last_cw = cw;
        }
      }
      
      for (Integer i = 0; i < calendarWeeks.size(); ) {
        if ((i + ExclusivePlacement.NUMBER_WEEK_GROUP - 1) < calendarWeeks.size()) {
          calendarWeekGroup.add(calendarWeeks.get(i) + ' - ' + calendarWeeks.get(i + ExclusivePlacement.NUMBER_WEEK_GROUP - 1));
          i += ExclusivePlacement.NUMBER_WEEK_GROUP;
        } else {
          if (i == calendarWeeks.size() - 1) {
            calendarWeekGroup.add(calendarWeeks.get(i));
          } else {
            calendarWeekGroup.add(calendarWeeks.get(i) + ' - ' + calendarWeeks.get(calendarWeeks.size()-1));
          }
          break;
        }
      }
    }
  }

  public class Website {
    protected String name = '';
    protected List<Placement> placements = new List<Placement>();

    public String getName() {
      system.debug('Website::getName() >>>>>>>>>>');
      return name;
    }

    public String getNameEncoded() {
      system.debug('Website::getNameEncoded() >>>>>>>>>>');
      return EncodingUtil.urlEncode(name, 'UTF-8');
    }

    public List<Placement> getPlacements() {
      system.debug('Website::getPlatzierungGruppen() >>>>>>>>>>');
      return placements;
    }
  }
  
  public class Placement {
    protected String name = '';
    protected List<Medium> mediums = new List<Medium>();

    public String getName() {
      system.debug('Placement::getName() >>>>>>>>>>');
      return name;
    }

    public String getNameEncoded() {
      system.debug('Placement::getNameEncoded() >>>>>>>>>>');
      return EncodingUtil.urlEncode(name, 'UTF-8');
    }

    public List<Medium> getMediums() {
      system.debug('Placement::getMediums() >>>>>>>>>>');
      return mediums;
    }
  }

  public class Medium {
    protected String name = '';
    protected List<ReservationDay> reservationDays = new List<ReservationDay>();

    public String getName() {
      system.debug('Medium::getName() >>>>>>>>>>');
      return name;
    }

    public String getNameEncoded() {
      system.debug('Medium::getNameEncoded() >>>>>>>>>>');
      return EncodingUtil.urlEncode(name, 'UTF-8');
    }

    public List<ReservationDay> getReservationDays() {
      system.debug('Medium::getReservationDays() >>>>>>>>>>');
      return reservationDays;
    }
  }

  public class ReservationDay {
    protected Date    day = null;
    protected Decimal probability = 0;
    protected Integer counter = 0;

    public Date getDay() {
      system.debug('ReservationDay::getDay() >>>>>>>>>>');
      return day;
    }

    public Integer getCount() {
      system.debug('ReservationDay::getCount() >>>>>>>>>>');
      return counter;
    }

    public Decimal getProbability() {
      system.debug('ReservationDay::getProbability() >>>>>>>>>>');
      return probability;
    }

    public String getProbabilityColor() {
      system.debug('ReservationDay::getProbabilityColor() >>>>>>>>>>');
      String color = '#FFFFFF';
      if (probability == 0) {
        color = '#67CC67';
      }
      else if (probability < 10) {
        color = '#67CC67';
      }
      else if (probability < 50) {
        color = '#CDCC67';
      }
      else if (probability < 100) {
        color = '#CD9C67';
      }
      else {
        color = '#CD6767';
      }

      return color;
    }
  }
  

  public class MyException extends Exception {}


  // Test Method
  static testMethod void BP1() {
    RecordType recType = [select Id, Name from RecordType where SobjectType='Account' and IsActive=true and Id != '012200000005MwQ' limit 1];

    Account account = [select Id, BillingState from Account limit 1];
    if (account.BillingState == null) {
      account.BillingState = 'ON';
      update account;
    }

    Pricebook2 pb2 = [select Id from Pricebook2 where IsStandard = true limit 1];
    
    Site__c site = new Site__c(Name='gumtree.co.uk', Active__c = TRUE, SortOrder__c = 1);
    insert site;

    Advertising_Medium__c wForm = new Advertising_Medium__c(Name='Banderole Ad');
    insert wForm;

    Placement__c platz = new Placement__c(Name='Homepage');
    insert platz;

    Placement__c platz2 = new Placement__c(Name='Sport');
    insert platz2;

    Product2 prod = new Product2(Name='Prod1', Site__c=site.Id, Placement__c=platz.Id, Advertising_Medium__c=wForm.Id);
    insert prod;

    Product2 prod2 = new Product2(Name='Prod2', Site__c=site.Id, Placement__c=platz2.Id, Advertising_Medium__c=wForm.Id, exclusive_Placement__c=true);
    insert prod2;

    PricebookEntry pbe = new PricebookEntry(Pricebook2Id=pb2.Id, Product2Id= prod.Id, UnitPrice=10, UseStandardPrice=false, IsActive=true);
    insert pbe;


    Opportunity opp = new Opportunity(Name='TestOpp', 
                                      CloseDate=system.today(), 
                                      AccountId=account.Id, 
                                      Pricebook2Id=pb2.Id, 
                                      Type='Existing Business', 
                                      StageName='Booking', 
                                      Probability=50, 
                                      P_O_Number__c = '123',
                                      // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
                                      Signed_contract_attached__c = true);
    insert opp;

    OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp.Id, PricebookEntryId=pbe.Id, Quantity=1, Unitprice=100, From_Date__c=Date.newInstance(2011,10,1), until_Date__c=Date.newInstance(2011,10,31));
    insert oli;

    
    Revenue2__c rv2 = new Revenue2__c();
    rv2.Opportunity__c = opp.Id;
    rv2.Product__c     = oli.PricebookEntry.Product2Id;
    rv2.LineItemId__c = oli.Id;
    insert rv2;    
    
    
    boolean dummy=true;
    Integer i=0;

    Date day1 = Date.today();
    Date day2 = Date.today().addDays(30);
    List<exclusive_Placement__c> bps = new List<exclusive_Placement__c>();

    for (Date day = day1; day <= day2; day = day.addDays(1)) {
      exclusive_Placement__c bp = new exclusive_Placement__c(Opportunity__c=opp.Id, Revenue2__c=rv2.Id, Product__c=prod.Id, Date__c=day);
      //exclusive_Placement__c bp = new exclusive_Placement__c(Opportunity__c=opp.Id, Product__c=prod.Id, Date__c=day);
      bps.add(bp);
    }
    insert bps;
    
    Test.startTest();
    ApexPages.currentPage().getParameters().put('id',oli.Id);
    ExclusivePlacement bpController = new ExclusivePlacement();

    bpController.updateCW();
    bpController.getCW();
    bpController.getWebsiteOptionList();
    bpController.getOptionen().Platform__c = 'gumtree.co.uk';
    bpController.updateWebsite();
    bpController.getPlacementOptionList();
    bpController.updatePlacement();

    bpController.generateReport();
    bpController.getOptionen();
    bpController.getWeekDays();
    bpController.getStartDate();
    bpController.getEndDate();
    for (Website ws : bpController.getWebsites()) {
      ws.getName();
      ws.getNameEncoded();
      for (Placement plz : ws.getPlacements()) {
        plz.getName();
        plz.getNameEncoded();
        for (Medium wf: plz.getMediums()) {
          wf.getName();
          wf.getNameEncoded();
          for (ReservationDay bt : wf.getReservationDays()) {
            bt.getDay();
            bt.getProbability();
            bt.getProbabilityColor();
            bt.getCount();            
          }
        }
      }
    }
    
    bpController.getReady();
    
    bpController.getOptionen().StartDate__c = bpController.getOptionen().StartDate__c.addDays(-1);
    bpController.updateCW();
    bpController.getCW();
    
    bpController.getOptionen().EndDate__c = bpController.getOptionen().StartDate__c.addDays(90);
    bpController.updateCW();
    bpController.getCW();
    Test.stopTest();
    }

}