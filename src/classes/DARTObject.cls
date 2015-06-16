/**

Change log:
- 2013-12-12 - GTCRM-649 - Populate custom field in DFP with OppOwner Division 
- 2014-02-19 - GTCRM-809 - Upgrade DFP time targeting
- 2014-07-04 - GTCRM-1012 - Opportunity Account Record type to be submitted to Sales team custom field

**/

public with sharing class DARTObject {
  
  public DARTObject(){}
  
  public interface IValidator
  {
    void checkError(Object o);
    List<String> getListError();
    Boolean isError();
    
  }
  
  public interface IDARTConnector
  {
    void connect();
    List<IDARTGenericObject> getDartObjects();
    
  }
  
  public virtual interface IDARTGenericObject
  {
  }  
      
  public virtual interface IDARTObject extends IDARTGenericObject
  {
    String getDartId();
    String getTempId();
    String getDartName();
    
    void setTempId(String tmpId);
    void setDartName(String dartNme);
    void setDartId(String dartId);
    
    String getAssignAdserver();
    void setAssignAdserver(String assAdserver);
    
    String getDartErrMsg();
    void setDartErrMsg(String errMsg);
  }
  
  /** ----------- Advertiser/Company ------------- */
  public interface IDARTObjectAdvertiser extends IDARTObject
  {
    
    String getAccountId();
    String getAccountName();
    String getAccountRectName();
    
  }
  
  /** ------------------ --------- ------------------------------------------------------ */
  public interface IDARTObjectOrder extends IDARTObject
  {

    String getPONumber();
    
    DARTPerson getPrimaryTrafficker();
    DARTPerson getSalepeople();
     
     void setPrimaryTrafficker(DARTPerson trafficker);
     void setSalePeople(DARTPerson speople);
     
     String getOppID();
     String getOppName();
     String getOwnerId();
     
     String getOrderAvertiserId();
     void setAdvertiserId(String advertiserId);
  
//  2014-07-04 - GTCRM-1012 - Opportunity Account Record type to be submitted to Sales team custom field
//     String getOwnerDivision();
     String getAccountRectName();

  }
  
  /** ---------------- Forecast Interface-------------------*/
  
  public interface IDARTObjectForecast extends IDARTObject
  {
    String getForecastId();
    void setForecastId(String forecastId); 
    
    String getOrderId();
    void setOrderId(String orderId);
    
    String getAvailableUnits();
    void setAvailableUnits(String avalUnit);
    
    String getMatchingUnits();
    void setMatchingUnits(String matchingUnit);
      
    String getShareOfVoice();
      
      
      
      
  }
  /** ------------------ --------- ------------------------------------------------------ */
  public interface IDARTObjectAds extends IDARTObject
  {
    IDARTObjectOrder getOrder();
    void setOrder(IDARTObjectOrder dartOrder);
    
    
    DateTime getStartDateTime();
    DateTime getEndDateTime();
    String getName();
    String getRate();
    String getUnit();
    String getOppItemID();
    String getProductName();
    String getAdId();  
    String getStatus();  
    String getCurrencyCode();
    Integer getPriority();
    String getDartProductType();   
    String getDartWebPropertyAlias();
    String getDartTargetPlatform();
    
    Map<String, String> getMapDayOfWeek();
    Map<String, String> getMapHoursOfDay();
    
    void setMapDayOfWeek(Map<String, String> mapDayOfWeek);
    void setMapHoursOfDay(Map<String, String> mapHoursOfDay);
    
    String getHoursOfDayValue();
    void setHoursOfDayValue(String hodVal);
  }
  
  /** ------------------Delivery------------------------------------------------------ */
  public interface IDARTObjectDelivery extends IDARTGenericObject{
    
    Integer getAdDelivered();
    Integer getImpressionsDelivered();
    Integer getAdClickedLifetime();
    Integer getClicksDelivered();
    Double getAdOSI();
    String getAdId();
    String getOrderId();
  }
  
  /** ------------------LineItemPage------------------------------------------------------ */
  public interface IDARTObjectLineItemPage extends IDARTGenericObject{
    OpportunityLineItem getOppLineItem();
    Targeting__c getTargeting();
    List<TargetingContentAssociation__c> getlTargetingContentAssociation();
    List<TargetingKeyValueAssociation__c > getlTargetingKeyValueAssociation();
    List<TargetingCityAssociation__c > getlTargetingCityAssociation();
    List<TargetingCountryAssociation__c > getlTargetingCountryAssociation();
    List<TargetingGeographyAssociation__c> getlTargetingGeographyAssociation();
    List<TargetingDeviceAssociation__c> getlTargetingDeviceAssociation();
    List<TargetingConnectionAssociation__c> getlTargetingConnectionAssociation();
    DART6_FORECASTSERVICE.CustomCriteriaSet getCustomCriteriaSet();
  }
  
  /** ---------------------- IDARTItem -------------------------------- */
  
  public interface IDARTItem {
    
  String getProductName();
  String getOppItemID();
  String getStartMonth();
  String getStartDay();
  String getStartYear();
  String getEndMonth();
  String getEndDay();
  String getEndYear();
  String getPackage();
  String getPeriod();
  String getQuantity();
  String getFCQty();
  String getFCEvery();
  String getFCAdServedEvery();
  String getFCPeriod();
  String[] getDayOfWeek();
  String[] getHourOfDay();
  Geography__c[] getIncludeGeography();
  AreaCode__c[] getIncludeAreaCode();
  Devices__c[] getIncludeDevice();
  Connection__c[] getIncludeConnection();
  String getDartTargetPlatform();
  String getOS();
  String getWebBrowser();
  Content__c[] getIncludeDartSite();
  Content__c[] getIncludeDartZone();
  Content__c[] getIncludeContentCat();
  String getKeyWKV();
  String getAdSlotH();
  String getAdSlotW();
  String getBillingCat();
  String getAdSlotId();
  String getOpportunityId();
  

  }
  
  
  
  /** Asbstract for all dart controllers*/
  
  public abstract class AbstractDARTController{
    protected String invokedMethod;
    protected List<DARTObject.IDARTGenericObject> listDartObjects;
    
    public virtual List<DARTObject.IDARTGenericObject> getListDart()
    {
      return listDartObjects;
    } 
    
    public String getInvokedMethod()
    {
      return invokedMethod;
    }
  }
  
  /** ------------------ --------- ------------------------------------------------------ */
  /** Abstract of all DARTObjects with shared properties */
  public abstract class AbsractDARTObject implements IDARTObject{
    String dartId;
    String tempId;
    String dartName;
    String assignAdserver;
    String errMsg;
    
    public String getDartId()
    {
      return dartId;
    }
    public String getTempId()
    {
      return tempId;
    }
    public String getDartName()
    {
      return dartName;
    }
    
    public void setTempId(String tmpId)
    {
      tempId = tmpId;
    }
    public void setDartName(String dName)
    {
      dartName = dName;
    }
    public void setDartId(String dartId)
    {
      this.dartId = dartId;
    }
    
    public String getAssignAdserver()
    {
      return assignAdserver;
    }
    public void setAssignAdserver(String assignAdserver)
    {
      this.assignAdserver = assignAdserver;
    }
    
    public String getDartErrMsg()
    {
      return errMsg;
    }
      public void setDartErrMsg(String errMsg)
      {
        this.errMsg = errMsg;
      }
    
  }
  
  /** ------------------ --------- ------------------------------------------------------ */
  /** Object Order */ 
  public class DARTOrder extends AbsractDARTObject implements IDARTObjectOrder{
     
    Opportunity opp;
    String advertiserId;
    String salepeopleId ;
    
    DARTPerson primaryTrafficker;
    DARTPerson salePeople;
    
    // 2014-07-04 - GTCRM-1012 - Opportunity Account Record type to be submitted to Sales team custom field
    String getAccountRectName;
    
    public DARTOrder(Opportunity opp)
    { 
      this.opp = opp;
       
    }
    
    public DARTOrder(String orderId, String advertiserId)
    {
      dartId= orderId;
      this.advertiserId = advertiserId;
    }
    
    public String getOppID()
    {
      return opp.id;
    }
    
    public String getOwnerId()
  {
    return opp.Owner.id;
  }
  
  // 2013-12-12 - GTCRM-649 
    /*public String getOwnerDivision()
   {
    return opp.Owner.Division;
   }
   */
   //  2014-07-04 - GTCRM-1012 - Opportunity Account Record type to be submitted to Sales team custom field
   
   public String getAccountRectName()
    {
      return opp.Account.RecordType.Name;     
    }
    
   /* 
   public String getAccountRecordType()
   {
    return opp.Account.RecordType.Name;
   }
   */
    
    public String getOppName()
    {
    return opp.Campaign_Name__c;
//      return opp.Name;
    }
    public String getPONumber()
    {
      return opp.P_O_Number__c;
    }
    public DARTPerson getPrimaryTrafficker()
    {
      return primaryTrafficker;
    }
    public DARTPerson getSalepeople()
    {
      return salePeople;
    }
   
    public DateTime getDartStartDateTime()
    {
      return opp.Campaign_Start__c;
    }
    public DateTime getDartEndateTime()
    {
      return opp.Campaign_End__c;
    }
    
    public String getStartMonth()
    {
      return opp.Campaign_Start__c==null?'':opp.Campaign_Start__c.month()+'';
    }
    public String getStartDay()
    {
      return opp.Campaign_Start__c==null?'':opp.Campaign_Start__c.day()+'';
    }
    public String getStartYear()
    {
      return opp.Campaign_Start__c==null?'':opp.Campaign_Start__c.year()+'';
    }
    public String getEndMonth()
    {
      return opp.Campaign_End__c==null?'':opp.Campaign_End__c.month()+'';
    }
    public String getEndDay()
    {
      return opp.Campaign_End__c==null?'':opp.Campaign_End__c.day()+'';
    }
    public String getEndYear()
    {
      return opp.Campaign_End__c==null?'':opp.Campaign_End__c.year()+'';
    }

    public void setAdvertiserId(String advertiserId)
    {
      this.advertiserId = advertiserId;
    }
    
    public String getOrderAvertiserId()
    {
      return advertiserId;
    }
    
    public void setSalepeople(DARTPerson salePeople)
    {
      this.salePeople  = salePeople;
    }
    public void setPrimaryTrafficker(DARTPerson primaryTrafficker)
    {
      this.primaryTrafficker = primaryTrafficker;
    }
       
  }
  
  
  /** Object Advertiser/Company */ 
  public class DARTAdvertiser extends AbsractDARTObject implements IDARTObjectAdvertiser{
    
    Account acc;
    public DARTAdvertiser(Account acc)
    {
      this.acc = acc;
    }
    
    public String getAccountId()
    {
      return acc.id;
    }
    
    public String getAccountName()
    {
      return acc.Name;
    }
    
    public String getAccountRectName()
    {
      return acc.RecordType.Name;
    }
    
    
    
  }
  
  
  /** ------------------ --------- ------------------------------------------------------ */
  public class DARTAds extends DARTForecast implements IDARTObjectAds{
    
    IDARTObjectOrder dartOrder;
    
    public DARTAds(OpportunityLineItem item)
    {
      super(item);
    }
     
     public IDARTObjectOrder getOrder()
     {
       return dartOrder;
     }
    public void setOrder(IDARTObjectOrder dartOrder)
    {
      this.dartOrder = dartOrder;
    }
    
     public DateTime getStartDateTime()
      {
        return item.from_Date__c;  
      }
    
    public DateTime getEndDateTime()
    {
      return item.until_Date__c;
    }
     
     public String getName()
     {
       //return item.PriceBookEntry.Product2.Name;
       //NK:09/02/2013
       return item.Ad_Name__c;
     }
     
     public String getRate()
     { 
       return (item.CPM_net_net_net__c!=null?(item.CPM_net_net_net__c*1000000)+'':'0');
//         return (item.Sales_Price_net_net_net__c!=null?item.Sales_Price_net_net_net__c.longValue():0);
     } 
       
     public String getUnit()
     {
      return item.Billing_category__c;
      //D5?: Oppproduct  Billing_category__c  General  Units    If Billing Category=”Fix Price” then “CPD”, else Billing_category__c
      //D6?: Oppproduct  Billing_category__c  General    Type  If Billing Category=”Fix Price” then “Sponsorship”, else “Standard”
      
    }
    
    public String getAdId()
    {
      return item.Ad_Id__c;
    }
  
    public String getStatus()
    {
        return (item.Ad_Id__c==null?'Created':'Updated');
    }
  
    public String getCurrencyCode()
    {
        return (UserInfo.isMultiCurrencyOrganization()?item.get('CurrencyIsoCode')+'':UserInfo.getDefaultCurrency());
    }
    
     public Integer getPriority()
    {
      return DARTUtil.toInteger(item.PriceBookEntry.Product2.Advertising_Medium__r.Dart_Prio__c);
    }
    
    public String getDartProductType()
    {
      return item.PriceBookEntry.Product2.Advertising_Medium__r.DART_ProductType__c;
    }
    
    public String getDartWebPropertyAlias()
    {
      return item.PriceBookEntry.Product2.Advertising_Medium__r.Dart_WebPropertyAlias__c;
    }

       
    
    Map<String, String> mapDayOfWeek;
    Map<String, String> mapHoursOfDay;
 
    public Map<String, String> getMapDayOfWeek()
     {
      return mapDayOfWeek;
     }
    public Map<String, String> getMapHoursOfDay()
     {
      return mapHoursOfDay;
     }
     
    public void setMapDayOfWeek(Map<String, String> mapDayOfWeek)
     {
       this.mapDayOfWeek = mapDayOfWeek;
     }
    public void setMapHoursOfDay(Map<String, String> mapHoursOfDay)
     {
       this.mapHoursOfDay = mapHoursOfDay;
     }
     
    String hodVal;
    public String getHoursOfDayValue()
     {
       return hodVal;
     }
    public void setHoursOfDayValue(String hodVal)
     {
       this.hodVal = hodVal;
     }
   }    
  public class DARTPerson extends AbsractDARTObject{
    
    public DARTPerson(){}
    
      String userEmail;
      
      public String getUserEmail()
      {
        return userEmail;
      }
      public void setUserEmail(String userEmail)
      {
        this.userEmail = userEmail;
      }

  } 
  
  /** ---------------------- Forecast Object -------------------------- */
  
  public virtual class DARTForecast extends AbsractDARTObject implements IDARTItem{
    
    
    final Map<String,String> mapFCPeriod = new Map<String,String>{'Minutes'=>'0','Hours'=>'1','Days'=>'2','Weeks'=>'3',null=>''};
    
    //user input according to the Period: Minutes,Hours,Days,Weeks. Need to convert into second as reqired by DART5. (DART6?)
    final Map<String,Integer> mapFCPeriod2Second = new Map<String,Integer>{
      'Minutes'=>60,'Hours'=>3600,'Days'=>86400,'Weeks'=>604800,'Months'=>2419200,
      'Minute'=>60,'Hour'=>3600,'Day'=>86400,'Week'=>604800,'Month'=>2419200,
       null=>0};
     
    protected OpportunityLineItem item;
    public DARTForecast(OpportunityLineItem item)
    {
      this.item = item;
    }
    public String getOppItemID()
    {
      return item.ID;
      
    }  
    
    public String getOpportunityId()
    {
       return item.OpportunityId;
    }
    
    public String getProductName()
    {
      return item.PriceBookEntry.Product2.Name+'';
    }
    public String getStartMonth()
    {
      return item.from_Date__c==null?'':item.from_Date__c.month()+'';
    }
    public String getStartDay()
    {
      return item.from_Date__c==null?'':item.from_Date__c.day()+'';
    }
    public String getStartYear()
    {
      return item.from_Date__c==null?'':item.from_Date__c.year()+'';
    }
    public String getEndMonth()
    {
      return item.from_Date__c==null?'':item.until_Date__c.month()+'';
    }
    public String getEndDay()
    {
      return item.from_Date__c==null?'':item.until_Date__c.day()+'';
    }
    public String getEndYear()
    {
      return item.from_Date__c==null?'':item.until_Date__c.year()+'';
    }
    public String getPackage()
    {
      return item.Package__c==null?'':item.Package__c+'';
    } 
    public String getLineDesc()
    {
      return item.Description==null?'':item.Description+'';
    }
    public String getPeriod()
    {
      return  item.Period__c==null?'':item.Period__c+'';
    }
    public String getQuantity()
    {
      return item.Quantity==null?'':item.Quantity.intValue()+'';
    }    
    public String getFCQty()
    {
      return item.FC_Quantity__c==null?'':item.FC_Quantity__c.intValue()+'';
    }
    public String getFCEvery()
    {
      //mapFCPeriod2Second DART5 need seconds, DART6?
      Integer tEvery = item.FC_Ad_served_every__c==null?0:item.FC_Ad_served_every__c.intValue();
      Integer timeInSecond = tEvery *  mapFCPeriod2Second.get(item.FC_Period__c);
      
      return timeInSecond+'';
      //return item.FC_Ad_served_every__c==null?'':item.FC_Ad_served_every__c.intValue()+'';
    }
    public String getFCAdServedEvery()
    {
      return item.FC_Ad_served_every__c==null?'':item.FC_Ad_served_every__c.intValue()+'';
    }
    public String getFCPeriod()
    {
      ////idxFreqTimeUnit: 0=Minutes, 1=Hours, 2=Days, 3=Weeks
      return mapFCPeriod.get(item.FC_Period__c);
    }
    public String getFCPeriodDart6()
      {
        return item.FC_Period__c==null?'':item.FC_Period__c;
      }
    public String[] getDayOfWeek()
    {
      //String[] selectedDays = (item.AdDayOfWeek__c+'').split(';'); //multi-pkl
      return (item.AdDayOfWeek__c==null?new List<String>():item.AdDayOfWeek__c.split(';')); //multi-pkl
    }
    public String[] getHourOfDay()
    {
      //String[] selectedHoD = (item.AdHourOfDay__c+'').split(';');
      return (item.AdHourOfDay__c==null?new List<String>():item.AdHourOfDay__c.split(';'));
    }
    
    Geography__c[] geographies;
    public Geography__c[] getIncludeGeography()
    {
      if(item.Targeting__c==null) return new List<Geography__c>();
      if(geographies==null)
      {
        geographies = DARTUtil.getListGeographies(item.Targeting__c);
      }
      return geographies;
      
    }
    
    Devices__c[] devices;
    public Devices__c[] getIncludeDevice()
    {
      if(item.Targeting__c==null) return new List<Devices__c>();
      if(devices==null)
      {
        devices = DARTUtil.getListDevices(item.Targeting__c);
      }
      return devices;
    }
    
    Connection__c[] connections;
    public Connection__c[] getIncludeConnection()
    {
      if(item.Targeting__c==null) return new List<Connection__c>();
      if(connections==null)
      {
        connections = DARTUtil.getListConnections(item.Targeting__c);
      }
      return connections;
    }
   
    AreaCode__c[] areas;
    public AreaCode__c[] getIncludeAreaCode()
    {
      if(item.Targeting__c==null)return new List<AreaCode__c>(); 
      
       if(areas==null)
       {
         areas = DARTUtil.getListAreaCodes(item.Targeting__c);
       }
       return areas; 
    }
    
    public String getOS()
    {
      return  (item.AdOperatingSystems__c==null?';':item.AdOperatingSystems__c);//';' will split into zero size
    }
    public String getWebBrowser()
    {
      return (item.AdWebBrowsers__c==null?';':item.AdWebBrowsers__c);//';' will split into zero size
    }
     
    public String getWebBrowerVersion()
    {
      return '';//'(item.AdBrowser_Version__c==null?'':item.AdBrowser_Version__c);
    } 
     
    public String getWebBrowserSubVersion()
    {
      return '';//' (item.AdBrowser_SubVersion__c==null?'':item.AdBrowser_SubVersion__c);
    } 
     
    public Content__c[] getIncludeDartSite()
    {
      Content__c[] listCont = DARTUtil.getListContents(item.Targeting__c, item.PriceBookEntry.Product2Id);
       
       //NK: 28/02/2013: only include the available sites if “Fixed_Site__c” on product is selected? If it is not selected then it should only pass the selected sites/zones/contentcategory from the tree as above.
       
       if(item.PriceBookEntry.Product2.Fixed_Site__c)
       {
            Content__c[] availSites = DARTUtil.getListAvailSites(item.PriceBookEntry.Product2Id,new Set<String>{'Dart - Zone','Dart - Site'});
            listCont.addAll(availSites);
       }
       
      return listCont;
    }
    
    public Content__c[] getIncludeDartZone()
    {
      return DartUtil.getContentsByTargetType(item.Targeting__c,'Dart - Zone');
    }
    
    public Content__c[] getIncludeContentCat()
    {
      Content__c[] conts =  DartUtil.getContentsByTargetType(item.Targeting__c,'Dart - ContentCategory');// 'Dart - Site'
     
       if(item.PriceBookEntry.Product2.Fixed_Site__c)
       {
             Content__c[] availSites = DARTUtil.getListAvailSites(item.PriceBookEntry.Product2Id,new Set<String>{'Dart - ContentCategory'});
             conts.addAll(availSites);
       }
      
      return conts;
    }
    
    public String getDartTargetPlatform()
    {
      return item.PriceBookEntry.Product2.Advertising_Medium__r.Dart_TargetPlatform__c;
    } 
    
    public String getKeyWKV()
    {
      //NK:12/03/2013
      //return (item.AdKeyWords__c==null?'':item.AdKeyWords__c); // KeyValueString__c
      
      //return (item.KeyValueString__c==null?'':item.KeyValueString__c); // KeyValueString__c
      
      //NK:13/03/2013: if adkeywords__c <> "", adkeywords__c, keyvaluestring__c
      return (item.AdKeyWords__c<>null?item.AdKeyWords__c: (item.KeyValueString__c==null?'':item.KeyValueString__c) );
    }
   
    public String getAdSlotH()
    {
      String adslot = item.PriceBookEntry.Product2.Advertising_Medium__r.DART_AdSlotSize__c;
      return (adslot==null?'':adslot.split('x')[1]);
    }
    public String getAdSlotW()
    {
      String adslot = item.PriceBookEntry.Product2.Advertising_Medium__r.DART_AdSlotSize__c;
      return (adslot==null?'':adslot.split('x')[0]);
    }
    public String getBillingCat()
    {
      return (item.Billing_category__c==null?'':item.Billing_category__c);
    }
    public String getAdSlotId()
    {
      DART_AdSlotMapper__c adsMap = DART_AdSlotMapper__c.getInstance(getAdSlotW()+'x'+getAdSlotH());
      
      return (adsMap==null?null:adsMap.Slot_Id__c);
      //return ADSLOTMAPPING.get(getAdSlotW()+' x '+getAdSlotH());
    }
    String totalUnits;
    //-------------------- Properties of Forecast (DART6)---------------------------
    String availableUnits;
  
    public String getAvailableUnits()
    {
      return availableUnits;
    }
    public void setAvailableUnits(String avalUnit)
    {
      this.availableUnits = avalUnit;
    }
       public String getMatchingUnits()
       {
        return totalUnits;
      }
      public void setMatchingUnits(String matchingUnit){
        totalUnits = matchingUnit;
      }
    
      /** availableUnits / matchingUnits * 100 */
      public String getShareOfVoice(){
              
          Double totalD = DARTUtil.toDouble(totalUnits);
          if(totalD==0)return ''; 
          
          Double availD = DARTUtil.toDouble(availableUnits);
          
          return Decimal.valueOf(availD/totalD*100).setScale(2)+'';
      }

// Bunhor: 17-Feb-14. For:  Time targeting with different hours on different days
      public DTOTimeTargeting[] getListDTOTimeTargeting(){
          
          DTOTimeTargeting[] theList = new List<DTOTimeTargeting>(); 
          
          if(item != null){ 
            if(item.DFP_Time_Monday__c != null){
              theList.add( new DTOTimeTargeting('monday', item.DFP_Time_Monday__c ) );
            }
            if(item.DFP_Time_Tuesday__c != null){
              theList.add( new DTOTimeTargeting('tuesday', item.DFP_Time_Tuesday__c ) );
            }
            if(item.DFP_Time_Wednesday__c != null){
              theList.add( new DTOTimeTargeting('wednesday', item.DFP_Time_Wednesday__c ) );
            }
            if(item.DFP_Time_Thursday__c != null){
              theList.add( new DTOTimeTargeting('thursday', item.DFP_Time_Thursday__c ) );
            }
            if(item.DFP_Time_Friday__c != null){
              theList.add( new DTOTimeTargeting('friday', item.DFP_Time_Friday__c ) );
            }
            if(item.DFP_Time_Saturday__c != null){
              theList.add( new DTOTimeTargeting('saturday', item.DFP_Time_Saturday__c ) );
            }
            if(item.DFP_Time_Sunday__c != null){
              theList.add( new DTOTimeTargeting('sunday', item.DFP_Time_Sunday__c ) );
            } 
          }
           
          return theList;
      }
  }
  
  // Bunhor: 17-Feb-14. For:  Time targeting with different hours on different days
  public class DTOTimeTargeting{
        public String day;
        public String[] hours = new List<String>(); 
          
      public DTOTimeTargeting(String day, String strHours){
        this.day = day; 
        this.hours = getHours(strHours);
      }
      
      // Ex: strHours = '0:00 - 0:59; 1:00 - 1:59; 2:00 - 2:59; 4:00 - 4:59; 21:00 - 21:59; 22:00 - 22:59'
      //     this method will return  (0:00 - 2:59, 4:00 - 4:59, 21:00 - 22:59 )
      private String[] getHours(String strHours){  
        
        String[] hours = new List<String>();
        for( String h : strHours.split(';') ){  
          if( h.trim() != '' )  hours.add(h.trim()); 
        }
        hours.sort(); 
         
        Map<Integer, String> theMap = new Map<Integer, String>();
        for( String hour : hours ){ 
          Integer h = Integer.valueOf(hour.substring(0,hour.indexOf(':')) );
          
          if( theMap.get(h-1) == null ){
            theMap.put(h, hour);
          }else{
            String startHour = theMap.get(h-1).split('-')[0];
            String endHour = hour.split('-')[1];
            theMap.remove(h-1);
            theMap.put(h, startHour + ' - ' + endHour);
          }
        }
         
        return theMap.values();
      } 
      
  }
  
  /** ---------------------- DARTDelivery Object 
   Trying to reduce the script statement to the minimum to ensure that US, 40K Monthly is feasible
  -------------------------- */
  
  public class DARTDelivery  implements IDARTObjectDelivery{
    
    //constructor
    public DARTDelivery()
    {
    }
      Map<Object,Object> mapRecord;
      public DARTDelivery(Map<Object,Object> mapRecord)
      {
        this.mapRecord = mapRecord;
        //System.debug('>>>>>>>>>>>>>>Script111111:  '+Limits.getScriptStatements());
      }
     
      public Integer getAdDelivered()
      {
        return DARTUtil.toInteger(mapRecord.get(DEL_FIELD_ADDELIVERED)+'');
      }
      
      public Integer getImpressionsDelivered()
      {
        return DARTUtil.toInteger(mapRecord.get(DEL_FIELD_IMPRESS_DELIVERED)+'');
      }
      public Integer getAdClickedLifetime()
      {
        return DARTUtil.toInteger(mapRecord.get(DEL_FIELD_ADCLICKED_LIFETIME)+'');
      }
      public Integer getClicksDelivered()
      {
        return DARTUtil.toInteger(mapRecord.get(DEL_FIELD_CLICKS_DELIVERED)+'');
      }
      public Double getAdOSI()
      {
        return DARTUtil.toDouble(mapRecord.get(DEL_FIELD_ADOSI)+'');
      }
      public String getAdId()
      {
        return mapRecord.get(DEL_FIELD_ADID)+'';
      }
      public String getOrderId()
      {
        return mapRecord.get(DEL_FIELD_ORDERID)+'';
      }
      
      public Object getValue(String colname){
        return mapRecord.get(colname);
      }
      
      public String getDateString(){
        return mapRecord.get(DEL_FIELD_DATE_OR_MONTH) + '';
      }
  }
  
  /** ---------------------- LineItemPage Object ---------------*/
  public class DARTLineItemPage implements IDARTObjectLineItemPage{
      //No Dart Id on TargetingXAssociation__c sobjects
      public Targeting__c targeting = new Targeting__c();
      public OpportunityLineItem oppLineItem = new OpportunityLineItem();
      public List<TargetingContentAssociation__c> lTargetingContentAssociation = new List<TargetingContentAssociation__c>();
      public List<TargetingKeyValueAssociation__c > lTargetingKeyValueAssociation = new List<TargetingKeyValueAssociation__c>();
      public List<TargetingCityAssociation__c > lTargetingCityAssociation = new List<TargetingCityAssociation__c>();
      public List<TargetingCountryAssociation__c > lTargetingCountryAssociation = new List<TargetingCountryAssociation__c>();
      public List<TargetingGeographyAssociation__c> lTargetingGeographyAssociation = new List<TargetingGeographyAssociation__c>();
      public List<TargetingDeviceAssociation__c> lTargetingDeviceAssociation = new List<TargetingDeviceAssociation__c>();
      public List<TargetingConnectionAssociation__c> lTargetingConnectionAssociation = new List<TargetingConnectionAssociation__c>();
      public DART6_FORECASTSERVICE.CustomCriteriaSet customCriteriaSet = new DART6_FORECASTSERVICE.CustomCriteriaSet();
      
      public DARTLineItemPage(){}
      
      public OpportunityLineItem getOppLineItem(){
        return oppLineItem;
      }
      
      public Targeting__c getTargeting(){
        return targeting;
      }
      
      public List<TargetingContentAssociation__c> getlTargetingContentAssociation(){
        return lTargetingContentAssociation;
      }
      
      public List<TargetingKeyValueAssociation__c > getlTargetingKeyValueAssociation(){
        return lTargetingKeyValueAssociation;
      }
      
      public List<TargetingCityAssociation__c > getlTargetingCityAssociation(){
        return lTargetingCityAssociation;
      }
      
      public List<TargetingCountryAssociation__c > getlTargetingCountryAssociation(){
        return lTargetingCountryAssociation;
      }
      
      public List<TargetingGeographyAssociation__c> getlTargetingGeographyAssociation(){
        return lTargetingGeographyAssociation;
      }
      
      public List<TargetingDeviceAssociation__c> getlTargetingDeviceAssociation()
      {
        return lTargetingDeviceAssociation;
      }
      
      public List<TargetingConnectionAssociation__c> getlTargetingConnectionAssociation()
      {
        return lTargetingConnectionAssociation;
      }
      
      public DART6_FORECASTSERVICE.CustomCriteriaSet getCustomCriteriaSet(){
        return customCriteriaSet;
      }
  }
  
  public final static String BILLING_CPM = 'CPM';
  public final static String BILLING_CPC = 'CPC';
  public final static String BILLING_CPD = 'CPD';
  
  
  
   public final static String DEL_FIELD_ADDELIVERED = 'AdDelivered';// mergeReservationImpressionsDelivered         //Delivered (Lifetime)
   public final static String DEL_FIELD_ADCLICKED_LIFETIME = 'AdClickedLifetime';//mergeReservationClicksDelivered   //Clicks Recorded (Lifetime)
   public final static String DEL_FIELD_ADOSI = 'AdOSI';//mergeLineItemDeliveryIndicator                  //OSI (Lifetime)
   public final static String DEL_FIELD_ADID = 'AdId';//lineItemId  
   public final static String DEL_FIELD_ORDERID = 'CampaignId';//orderId
   public final static String DEL_FIELD_IMPRESS_DELIVERED = 'ImpressionsDelivered';//mergeReservationImpressionsDelivered  //   Impressions Delivered  
   public final static String DEL_FIELD_CLICKS_DELIVERED = 'ClicksDelivered';//mergeReservationClicksDelivered      //   Clicks Recorded 
   public final static String DEL_FIELD_DATE_OR_MONTH = 'dateormonth'; // date for RSD and month for RS
}