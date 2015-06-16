/**
// DART6 Message Production

Change log:
- 2013-12-12 - GTCRM-649 - Populate custom field in DFP with OppOwner Division 
- 2014-02-19 - GTCRM-809 - Upgrade DFP time targeting

- 28-04-2014 - Sochanra-Yos - #3122: Move from Country/City Targeting to Geography Targeting
                            - Applied in both Booking & Forecast
                            
- 29-05-2014 - Sochanra-Yos - #3229: GTCRM-880 - Devices & Connection Targeting
                            - Applied in both Booking & Forecast

- 2014-07-04 - GTCRM-1012 - Opportunity Account Record type to be submitted to Sales team custom field
- 2015-01-06 - GTCRM-1653 - Allow Overbooking When Pushing from SF to DFP

**/


/** Message Request for DFP, not xml as DART but generated apex classes from WSDL */
public with sharing class DART6Message {
  public final static String DART6_WS_ERROR_PATTERN = 'Web service callout failed: WebService returned a SOAP Fault: \\[(.*?)\\] faultcode=soap:Server faultactor=';
  public final static Map<String, String> MAP_TIME_UNITS = new Map<String, String>{
                          'Minutes'=>'MINUTE', 
                          'Hours'=>'HOUR', 
                          'Days'=>'DAY',  
                          'Weeks'=>'WEEK', 
                          'Months'=>'MONTH',
                          'Minute'=>'MINUTE', 
                          'Hour'=>'HOUR', 
                          'Day'=>'DAY', 
                          'Week'=>'WEEK', 
                          'Month'=>'MONTH',
                          'Lifetime'=>'LIFETIME'};
                          
  
  public final static String BILLING_CATE_FIX_PRICE = 'Fix Price';                        
  public final static String LINEITEM_TYPE_NETWORK = 'Network';
  public final static String LINEITEM_TYPE_HOUSE = 'House';
  public final static String LINEITEM_TYPE_AD_EXCHANGE='Ad Exchange';
  public final static String LINEITEM_TYPE_ADSENSE='AdSense';                    
  
  public final static String BREAKDOWN_DAILY = 'Daily';
  public final static String BREAKDOWN_MONTHLY = 'Monthly';
  public final static String DATERANGE_YESTERDAY = 'Yesterday';
  public final static String DATERANGE_LASTMONTH = 'LastMonth';

  
  public DART6Message(){String s;}  
   
  public abstract class AbstractDFPRequest extends AbstractDARTRequest implements HTTPWrapper.IInvoker{
      
  }
  
  /** ----------- DFP Company Request ---------------- */  
  public class DFPCompanyRequest extends AbstractDFPRequest{
    
    DART6_COMPANYSERVICE.Company newCompany;   
    OpportunityLineItem item;
    Account acc;
    
    public DFPCompanyRequest(Account acc, OpportunityLineItem item)
    {
      this.acc = acc;
      this.item = item;
    }
    
    public void invoke()
    {
      
      //String authToken = DARTUtil.getRequestToken(item.PriceBookEntry.Product2.Site__r.Country__c);    old version
      AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6,item.PriceBookEntry.Product2.Site__r.Country__c);
      String authToken = DARTUtil.getAccessToken(login); // new version 201411 
    
      DART6_COMPANYSERVICE.SoapRequestHeader header = new DART6_COMPANYSERVICE.SoapRequestHeader();
      header.applicationName='OrderService';
      header.networkCode=login.Network_ID__c;
      
      Map<String,String> inputHttpHeaders_x = new Map<String, String>();       // new version 201411 
      inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);            // new version 201411
      
      DART6_COMPANYSERVICE.CompanyServiceInterfacePort companyRequest = new DART6_COMPANYSERVICE.CompanyServiceInterfacePort();
      companyRequest.RequestHeader = header;
      companyRequest.inputHttpHeaders_x = inputHttpHeaders_x;     // new version 201411 
        
        DARTObject.DARTAdvertiser dartAdvt = new DARTObject.DARTAdvertiser(acc);
        
        DART6_COMPANYSERVICE.Company com = new DART6_COMPANYSERVICE.Company();
        com.name = dartAdvt.getAccountName();
        com.externalId = dartAdvt.getAccountId();
        DART_Advertiser_Type_Mapper__c custAdvType = DART_Advertiser_Type_Mapper__c.getInstance(dartAdvt.getAccountRectName());
        com.type_x = (custAdvType!=null?custAdvType.DFP_Advertiser_Type__c:'');
        com.creditStatus ='ACTIVE';
      
      
      
      // newCompany = companyRequest.createCompanies(com);  old version
      
      
      List<DART6_COMPANYSERVICE.Company> cmps = companyRequest.createCompanies(new List<DART6_COMPANYSERVICE.Company>{com});
      if(!cmps.isEmpty()) newCompany = cmps.get(0);
      
      invokedMethod = 'Create Company';
      
      System.debug('=====================> newCompany: ' + newCompany);
      
    }
    
    public Object getResponseObject()
    {
      //return DFP object from invoke
      return newCompany;
    }
    
    
  }
  
  
  
   
  /**DFP Order request via apex from WSDL */ 
  
  public class DFPOrderRequest extends AbstractDFPRequest{
    
    DART6_ORDERSERVICE.Order newDartOrder;
    
    Opportunity opp;
    OpportunityLineItem item;  
    Map<String, DARTObject.DARTPerson> mapDartUser;
    Map<String, Advertiser__c> mapAdvertiser;
    
 
    public DFPOrderRequest(Opportunity opp, OpportunityLineItem item, Map<String, DARTObject.DARTPerson> mapDartUser, Map<String, Advertiser__c> mapAdvertiser)
    {
      this.opp = opp; 
      this.item = item;
      this.mapDartUser = mapDartUser;
      this.mapAdvertiser= mapAdvertiser;
    }

    public void invoke()
    {
      
      //Token
      //String authToken = DARTUtil.getRequestToken(item.PriceBookEntry.Product2.Site__r.Country__c);   old version
      AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6,item.PriceBookEntry.Product2.Site__r.Country__c);
      String authToken = DARTUtil.getAccessToken(login); // new version 201411
    
      DART6_ORDERSERVICE.SoapRequestHeader header = new DART6_ORDERSERVICE.SoapRequestHeader();
      header.applicationName='OrderService';
      header.networkCode=login.Network_ID__c;
      
      Map<String,String> inputHttpHeaders_x = new Map<String, String>();       // new version 201411 
      inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);            // new version 201411 
      
      DART6_ORDERSERVICE.OrderServiceInterfacePort orderRequest = new DART6_ORDERSERVICE.OrderServiceInterfacePort();
      orderRequest.RequestHeader = header;
      orderRequest.inputHttpHeaders_x = inputHttpHeaders_x;     // new version 201411 
        
      DARTObject.DARTOrder dartOrder = new DARTObject.DARTOrder(opp);  
        
      // setDartTime Start
      DART6_ORDERSERVICE.Date_x datexStart = new DART6_ORDERSERVICE.Date_x();
      datexStart.day = Integer.valueOf(dartOrder.getStartDay()+'');
      datexStart.month = Integer.valueOf(dartOrder.getStartMonth()+'');
      datexStart.year = Integer.valueOf(dartOrder.getStartYear()+'');
      
      DART6_ORDERSERVICE.DateTime_x dartTimexStart = new DART6_ORDERSERVICE.DateTime_x();
      dartTimexStart.date_x = datexStart;
      dartTimexStart.hour = 0;
      dartTimexStart.minute = 0;
      dartTimexStart.second = 0;
      dartTimexStart.timeZoneID ='BROWSER';
      
      // setDartTime End
      DART6_ORDERSERVICE.Date_x datexEnd = new DART6_ORDERSERVICE.Date_x();
      datexEnd.day = Integer.valueOf(dartOrder.getEndDay()+'');
      datexEnd.month = Integer.valueOf(dartOrder.getEndMonth()+'');
      datexEnd.year = Integer.valueOf(dartOrder.getEndYear()+'');
      
      DART6_ORDERSERVICE.DateTime_x dartTimexEnd = new DART6_ORDERSERVICE.DateTime_x();
      dartTimexEnd.date_x = datexEnd;
      dartTimexEnd.hour = 23;
      dartTimexEnd.minute = 59;
      dartTimexEnd.second = 0;
      dartTimexEnd.timeZoneID ='BROWSER';
      
      // Custom field
      DART6_ORDERSERVICE.TextValue custVal = new DART6_ORDERSERVICE.TextValue();
//      custVal.value = dartOrder.getOwnerDivision();
// - GTCRM-1012 - Opportunity Account Record type to be submitted to Sales team custom field
      custVal.value = dartOrder.getAccountRectName();
      custVal.type_x = 'TextValue';
      
      DART6_ORDERSERVICE.CustomFieldValue custFldVal = new DART6_ORDERSERVICE.CustomFieldValue();
      custFldVal.customFieldId =  1510;
      //custFldVal.customFieldId =  12133;  for test
      custFldVal.type_x= 'CustomFieldValue';
      custFldVal.value = custVal; 
         
        // Create new Order 
        DART6_ORDERSERVICE.Order ord = new DART6_ORDERSERVICE.Order();
        ord.poNumber = dartOrder.getPONumber();
        ord.notes = dartOrder.getOppID();
        ord.customFieldValues = new List<DART6_ORDERSERVICE.BaseCustomFieldValue>{custFldVal};
        ord.startDateTime = dartTimexStart;
        ord.endDateTime = dartTimexEnd;
        ord.name = dartOrder.getOppName();
        ord.isArchived = false;
  
          List<OpportunityTeamMember> lstOppTeamMember = DARTUtil.getOpportunityTeamMember(opp.id);
          String trafickerId='';
          if(lstOppTeamMember.size()>0)
          {
                trafickerId = mapDartUser.get(lstOppTeamMember.get(0).User.Name)!=null?mapDartUser.get(lstOppTeamMember.get(0).User.Name).getDartId():'';
          }
          else trafickerId = mapDartUser.get(login.User_Name__c)!=null?mapDartUser.get(login.User_Name__c).getDartId():''; 
            
          //trafickerId = mapDartUser.get(login.User_Name__c)!=null?mapDartUser.get(login.User_Name__c).getDartId():'';

          String salespersonId = mapDartUser.get(opp.Owner.Name)!=null?mapDartUser.get(opp.Owner.Name).getDartId():'';
          System.debug('-----------> trafickerId: ' + trafickerId+'----------> salespersonId: ' + salespersonId);
          String dartVer = item.PricebookEntry.Product2.RecordType.Name+'_'+item.PriceBookEntry.Product2.Site__r.Country__c;
          
          System.debug('=====================> mapAdvertiser: ' + mapAdvertiser);
          
          if(mapAdvertiser.get(dartVer) != null)
          {
            ord.advertiserId = Long.valueOf(mapAdvertiser.get(dartVer).Dart6_Advertiser_Id__c);  // Company ID
          }
          if(!''.equals(salespersonId))
          {
            ord.salespersonId=Long.valueOf(salespersonId);
          }
          if(!''.equals(trafickerId))
          {
            ord.traffickerId = Long.valueOf(trafickerId);
          }
       
       System.debug('============================>>ORDER:\n\n\n'+ ord);
          
          
      //  newDartOrder = orderRequest.createOrder(ord);    old version
      
      //New Version 201411
        List<DART6_ORDERSERVICE.Order>  lstOrdersRq =  orderRequest.createOrders(new List<DART6_ORDERSERVICE.Order>{ord});
        if(!lstOrdersRq.isEmpty()) newDartOrder = lstOrdersRq.get(0);
        
        System.debug('\n\n\n========================> newDartOrder: ' + newDartOrder);
        
        invokedMethod = 'createOrder';
        
      
    }
    // this object returned from the invoke above and target for Parser to parse into our Apex DartObject 
    public Object getResponseObject()
    {
      //return DFP object from invoke
      return newDartOrder;
    }  
  }
  
  // Salesperson depend on User role
  public class DFPSalespersonRequest extends AbstractDFPRequest{
   
    List<DART6_USERSERVICE.User_x> dartUsers;
    OpportunityLineItem oppItem;
    Opportunity opp;
    
    public DFPSalespersonRequest(OpportunityLineItem oppItem, Opportunity opp)
    {
      this.oppItem = oppItem;
      this.opp = opp;
    }
    
    public void Invoke()
    { 
      
      //Token
      //String authToken = DARTUtil.getRequestToken(oppItem.PriceBookEntry.Product2.Site__r.Country__c);   Old Version
      AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6,oppItem.PriceBookEntry.Product2.Site__r.Country__c);
      String authToken = DARTUtil.getAccessToken(login); // new version 201411
          
          DART6_USERSERVICE.SoapRequestHeader userHeader = new DART6_USERSERVICE.SoapRequestHeader();
          userHeader.applicationName = 'UserService';
          userHeader.networkCode= login.Network_ID__c;  
          
          Map<String,String> inputHttpHeaders_x = new Map<String, String>();     // new version 201411
          inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);          // new version 201411
          
          DART6_USERSERVICE.UserServiceInterfacePort userRequest = new DART6_USERSERVICE.UserServiceInterfacePort();
          userRequest.RequestHeader = userHeader;
          userRequest.inputHttpHeaders_x = inputHttpHeaders_x;
          
          // Get User Id (traffickerId) DART User By UserName in Adsever Login
            List<OpportunityTeamMember> lstOppTeamMember = DARTUtil.getOpportunityTeamMember(opp.id);
            System.debug('\n\n ===========> lstOppTeamMember: ' + lstOppTeamMember);
            
            String oppOwnerName =  (opp.Owner.Name).replace('\'', '\'\'').replace('"', '""');

            String querySt = '';
            if(lstOppTeamMember.size()>0)
            {
                String teamMemberName = (lstOppTeamMember.get(0).User.Name+'').replace('\'', '\'\'').replace('"', '""');
                querySt = 'WHERE name = \''+ teamMemberName+'\' OR name =\'' + oppOwnerName + '\'';
            }else querySt = 'WHERE email = \''+ login.User_Name__c+'\' OR name =\'' + oppOwnerName + '\'';
            
            
            // Get User Id (traffickerId) DART User By UserName in Adsever Login
            DART6_USERSERVICE.Statement filterUser  = new DART6_USERSERVICE.Statement();
            filterUser.query = querySt;
            
        
          DART6_USERSERVICE.UserPage userPage = userRequest.getUsersByStatement(filterUser);
      dartUsers = new List<DART6_USERSERVICE.User_x>();
      if (userPage.totalResultSetSize > 0) { 
            for(DART6_USERSERVICE.User_x user : userPage.results ){
              System.debug('USER : >>>>>>> ID : ' + user.id + '>>>>>>> Name: ' + user.name);
              DART6_USERSERVICE.User_x dartuser = new DART6_USERSERVICE.User_x(); 
              dartUser.id = user.id;
              dartUser.name = user.name;
              dartUser.email = user.email;
              dartUsers.add(dartUser);
            }
          }
          
          invokedMethod = 'getCurrentUser';
      
    }
    
    public Object getResponseObject()
    {
      return dartUsers;
    }
  }

  public class DFPAdsRequest extends AbstractDFPRequest{

    DART6_LINEITEMSERVICE.LineItem dfpLineItemResponse;
    OpportunityLineItem item;
    Opportunity opp;   
    DARTObject.IDARTObjectOrder dartOrder;

    public DFPAdsRequest(OpportunityLineItem item, DARTObject.IDARTObjectOrder dartOrder, Opportunity opp)
    {
      this.item = item;
      this.dartOrder = dartOrder;
      this.opp = opp;
    }  
       
    public void Invoke()
    { 
      //Token
      
      DART6_KeyValueController ctrl;
      List<DART6_FORECASTSERVICE.CustomCriteriaSet> listCrit = new List<DART6_FORECASTSERVICE.CustomCriteriaSet>();
      
      //String authToken = DARTUtil.getRequestToken(item.PriceBookEntry.Product2.Site__r.Country__c);   old version
      AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6,item.PriceBookEntry.Product2.Site__r.Country__c);
      String authToken = DARTUtil.getAccessToken(login); // new version 201411
          
      Map<String,String> inputHttpHeaders_x = new Map<String, String>();     // new version 201411
      inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);          // new version 201411
    
      DART6_LINEITEMSERVICE.SoapRequestHeader header = new DART6_LINEITEMSERVICE.SoapRequestHeader();
      header.applicationName='LineItemService';
      header.networkCode=login.Network_ID__c;
      
    
      DART6_LINEITEMSERVICE.LineItemServiceInterfacePort lineItemService = new DART6_LINEITEMSERVICE.LineItemServiceInterfacePort();
      lineItemService.RequestHeader = header;
      lineItemService.inputHttpHeaders_x = inputHttpHeaders_x;            // new version 201411
      
      DARTObject.DARTAds dartAds = new DARTObject.DARTAds(item);
              
      // setDartTime Start
      DART6_LINEITEMSERVICE.Date_x datexStart = new DART6_LINEITEMSERVICE.Date_x();
      datexStart.day = dartAds.getStartDateTime().day();
      datexStart.month = dartAds.getStartDateTime().month();
      datexStart.year = dartAds.getStartDateTime().year();
      
      DART6_LINEITEMSERVICE.DateTime_x dartTimexStart = new DART6_LINEITEMSERVICE.DateTime_x();
      dartTimexStart.date_x = datexStart;
      dartTimexStart.hour = 0;
      dartTimexStart.minute = 0;
      dartTimexStart.second = 0;
      dartTimexStart.timeZoneID ='BROWSER';
        
      // setDartTime End
      DART6_LINEITEMSERVICE.Date_x datexEnd = new DART6_LINEITEMSERVICE.Date_x();
      datexEnd.day = dartAds.getEndDateTime().day();
      datexEnd.month = dartAds.getEndDateTime().month();
      datexEnd.year = dartAds.getEndDateTime().year();
      
      DART6_LINEITEMSERVICE.DateTime_x dartTimexEnd = new DART6_LINEITEMSERVICE.DateTime_x();
      dartTimexEnd.date_x = datexEnd;
      dartTimexEnd.hour = 23;
      dartTimexEnd.minute = 59;
      dartTimexEnd.second = 0;
      dartTimexEnd.timeZoneID ='BROWSER';
      
      // Get placementIds
      List<Long> placementIds = new List<Long>();
          
      for(Content__c cCat : dartAds.getIncludeContentCat())
      {
        placementIds.add(Long.valueOf(cCat.Name+''));
      }
      
      List<DART6_LINEITEMSERVICE.AdUnitTargeting> adUnitTargs = new List<DART6_LINEITEMSERVICE.AdUnitTargeting>();    
      for(Content__c dartSite : dartAds.getIncludeDartSite())
      {
        DART6_LINEITEMSERVICE.AdUnitTargeting adunit = new DART6_LINEITEMSERVICE.AdUnitTargeting();
        adunit.adUnitId = dartSite.Name;
        adUnitTargs.add(adunit);
      }
      for(Content__c dartZone : dartAds.getIncludeDartZone())
      {
        DART6_LINEITEMSERVICE.AdUnitTargeting adunit = new DART6_LINEITEMSERVICE.AdUnitTargeting();
        adunit.adUnitId = dartZone.Name;
        adUnitTargs.add(adunit);
      }
      
      //DART6_FORECASTSERVICE.Location
      List<DART6_LINEITEMSERVICE.Location> lstLocations = new List<DART6_LINEITEMSERVICE.Location>();
      
      for(Geography__c g : dartAds.getIncludeGeography())
      {
        DART6_LINEITEMSERVICE.Location loc = new DART6_LINEITEMSERVICE.Location();
         loc.id = Long.valueOf(g.Dart_ID__c+''); // 2124
         loc.Location_Type = g.Type__c;
         lstLocations.add(loc); 
      }
      
       
       
      
      //DayPart
            List<DART6_LINEITEMSERVICE.DayPart> lstDayParts = new List<DART6_LINEITEMSERVICE.DayPart>();
            
            /* Bunhor : 17-Feb-14. blocked. Use new fields: LI.DFP_Time_Monday__c - LI.DFP_Time_Sunday__c
            // Day of Week
            //ex: sunday; monday
            //ex: 22:00 - 22:59; 23:00 - 23:59
            //-> sunday: 22:00 - 22:59; 23:00 - 23:59
            //-> monday: 22:00 - 22:59; 23:00 - 23:59
                    
            for(String dw : dartAds.getDayOfWeek())
            {

                // Hours of Day
                //(22:00 - 22:59, 23:00 - 23:59,.....)
                //NK:Fixed: 09/02/2013
                String[] hods = dartAds.getHourOfDay();
                hods = !hods.isEmpty()?hods:new String[]{'00:00 - 23:59'}; //all time if time not specified.
                for(String hd : hods)
                { 
                    List<String> lsthd = hd.split('-'); // (22:00, 22:59)
                    List<String> lstTimeStart = lsthd[0].split(':'); //(22, 00)
                    List<String> lstTimeEnd = lsthd[1].split(':'); // (22, 59)
                    
                    DART6_LINEITEMSERVICE.TimeOfDay startTimeOfDay = new DART6_LINEITEMSERVICE.TimeOfDay();
                    startTimeOfDay.hour = Integer.valueOf(lstTimeStart[0].trim()+'');
                    startTimeOfDay.minute ='ZERO';// lstTimeStart[1].trim();
                    
                    DART6_LINEITEMSERVICE.TimeOfDay endTimeOfDay = new DART6_LINEITEMSERVICE.TimeOfDay();
                    
                    //endTimeOfDay.hour = Integer.valueOf(lstTimeEnd[0].trim()+'');
                    //endTimeOfDay.minute ='FORTY_FIVE';// lstTimeEnd[1].trim();
                    
                    endTimeOfDay.hour = Integer.valueOf(lstTimeEnd[0].trim()+'')+1;
                    endTimeOfDay.minute ='ZERO';// lstTimeEnd[1].trim();
                    
                    DART6_LINEITEMSERVICE.DayPart dayPart = new DART6_LINEITEMSERVICE.DayPart();
                    dayPart.dayOfWeek = dw.toUpperCase();
                    dayPart.startTime = startTimeOfDay;
                    dayPart.endTime = endTimeOfDay;
                            
                    lstDayParts.add(dayPart);
                            
                }
             }
                
            */
            //----- Time Targeting --------   
          // Bunhor: 17-Feb-14. For Time Targeting with different hours on different days
            for(DARTObject.DTOTimeTargeting dto : dartAds.getListDTOTimeTargeting() ){
              for(String hour : dto.hours){   // Ex: dto.hours = ('0:00 - 0:59', '1:00 - 1:59')
                List<String> lsthd = hour.split('-'); // (0:00, 0:59)
                    List<String> lstTimeStart = lsthd[0].split(':'); //(0, 00)
                    List<String> lstTimeEnd = lsthd[1].split(':'); // (0, 59)
                
                DART6_LINEITEMSERVICE.TimeOfDay startTimeOfDay = new DART6_LINEITEMSERVICE.TimeOfDay();
                    startTimeOfDay.hour = Integer.valueOf(lstTimeStart[0].trim()+'');
                    startTimeOfDay.minute ='ZERO'; 
                    
                    DART6_LINEITEMSERVICE.TimeOfDay endTimeOfDay = new DART6_LINEITEMSERVICE.TimeOfDay(); 
                    endTimeOfDay.hour = Integer.valueOf(lstTimeEnd[0].trim()+'')+1;
                    endTimeOfDay.minute ='ZERO'; 
                    
                    DART6_LINEITEMSERVICE.DayPart dayPart = new DART6_LINEITEMSERVICE.DayPart();
                    dayPart.dayOfWeek = dto.day.toUpperCase();
                    dayPart.startTime = startTimeOfDay;
                    dayPart.endTime = endTimeOfDay;
                            
                    lstDayParts.add(dayPart);
              }
            }
            
        
          
          
          // GTCRM-880 pushing - Devices & Connection to DFP(Targeting)
          // 29-05-2014
           
           DART6_LINEITEMSERVICE.BandwidthGroupTargeting bandwidthGroupTargeting = null;
           DART6_LINEITEMSERVICE.MobileCarrierTargeting mobileCarrierTargeting = null;
           Set<String> bandWidthParentIds = new Set<String>();
           Set<String> mobileCarParentIds = new Set<String>();
           Set<String> connIds = new Set<String>();
           for(Connection__c c : dartAds.getIncludeConnection())
           {
            
                if(('BandwidthGroup').equals(c.DFP_API_Name__c))
                {
                    bandWidthParentIds.add(c.id);
                }
                else if(('MobileCarrier').equals(c.DFP_API_Name__c))
                {
                    mobileCarParentIds.add(c.id);
                }else connIds.add(c.id);
    
           }
       
           Set<String> mcParids = new Set<String>();
           
           // Bandwidth connection
           List<Connection__c> lstConnBwidth = new List<Connection__c>();
           
           for(Connection__c c : dartAds.getIncludeConnection())
           {
                if(bandWidthParentIds.contains(c.Node_ID__c))
                {
                    lstConnBwidth.add(c);
                }
                else if(mobileCarParentIds.contains(c.Node_ID__c))
                {
                    mcParids.add(c.Id);
                }
           }
       
           //MobileCarrier connection
           List<Connection__c> lstMbCar = new List<Connection__c>();
           for(Connection__c c : dartAds.getIncludeConnection())
           {
                if(mcParids.contains(c.Node_ID__c))
                {
                    lstMbCar.add(c);
                }
           }
           
           DART6_LINEITEMSERVICE.Technology[] listBandWidth = new List<DART6_LINEITEMSERVICE.Technology>();
           // Bandwidth 
           for(Connection__c con : lstConnBwidth)
           {
                DART6_LINEITEMSERVICE.Technology technologyBw = new DART6_LINEITEMSERVICE.Technology();
                technologyBw.id = con.Dart_ID__c.longValue();
                listBandWidth.add(technologyBw);
           }
           
           if(!listBandWidth.isEmpty())
           {
                bandwidthGroupTargeting = new DART6_LINEITEMSERVICE.BandwidthGroupTargeting();
                bandwidthGroupTargeting.bandwidthGroups = listBandWidth;
           }
           
           //MobileCarrier
           DART6_LINEITEMSERVICE.Technology[] techMobileCar = new List<DART6_LINEITEMSERVICE.Technology>();
           for(Connection__c con : lstMbCar)
           {
                DART6_LINEITEMSERVICE.Technology techMb = new DART6_LINEITEMSERVICE.Technology();
                techMb.id = con.Dart_ID__c.longValue();
                techMobileCar.add(techMb);
           }
           
           if(!techMobileCar.isEmpty())
           {
                mobileCarrierTargeting = new DART6_LINEITEMSERVICE.MobileCarrierTargeting();
                mobileCarrierTargeting.mobileCarriers = techMobileCar;
           }
           
           // -------------------------->> Device Targeting <<--------------------------------
           DART6_LINEITEMSERVICE.Technology[] listBrowsing = new List<DART6_LINEITEMSERVICE.Technology>();
           DART6_LINEITEMSERVICE.Technology[] listBrowsingLang = new List<DART6_LINEITEMSERVICE.Technology>();
           DART6_LINEITEMSERVICE.Technology[] listDeviceCap = new List<DART6_LINEITEMSERVICE.Technology>();
           DART6_LINEITEMSERVICE.Technology[] listDeviceCategory = new List<DART6_LINEITEMSERVICE.Technology>();
           DART6_LINEITEMSERVICE.Technology[] listDeviceManufacturer = new List<DART6_LINEITEMSERVICE.Technology>();
           DART6_LINEITEMSERVICE.Technology[] listOpSys = new List<DART6_LINEITEMSERVICE.Technology>();
           DART6_LINEITEMSERVICE.Technology[] listOpSysVersion = new List<DART6_LINEITEMSERVICE.Technology>();
           DART6_LINEITEMSERVICE.Technology[] listMobileDevice = new List<DART6_LINEITEMSERVICE.Technology>();
           DART6_LINEITEMSERVICE.Technology[] listMobileDeviceSubMod = new List<DART6_LINEITEMSERVICE.Technology>();
           for(Devices__c d : dartAds.getIncludeDevice())
           {
                if(('Browser').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techBrw = new DART6_LINEITEMSERVICE.Technology();
                    techBrw.id = d.Dart_ID__c.longValue();
                    listBrowsing.add(techBrw);
                }
                else if(('BrowserLanguage').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techBrwLang = new DART6_LINEITEMSERVICE.Technology();
                    techBrwLang.id = d.Dart_ID__c.longValue();
                    listBrowsingLang.add(techBrwLang);
                }
                else if(('DeviceCapability').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techDevCap = new DART6_LINEITEMSERVICE.Technology();
                    techDevCap.id = d.Dart_ID__c.longValue();
                    listDeviceCap.add(techDevCap);
                }
                else if(('DeviceCategory').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techDevCate = new DART6_LINEITEMSERVICE.Technology();
                    techDevCate.id = d.Dart_ID__c.longValue();
                    listDeviceCategory.add(techDevCate);
                }
                else if(('DeviceManufacturer').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techDevMf = new DART6_LINEITEMSERVICE.Technology();
                    techDevMf.id = d.Dart_ID__c.longValue();
                    listDeviceManufacturer.add(techDevMf);
                } 
                else if(('OperatingSystem').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techOs = new DART6_LINEITEMSERVICE.Technology();
                    techOs.id = d.Dart_ID__c.longValue();
                    listOpSys.add(techOs);
                }
                else if(('OperatingSystemVersion').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techOsVersion = new DART6_LINEITEMSERVICE.Technology();
                    techOsVersion.id = d.Dart_ID__c.longValue();
                    listOpSysVersion.add(techOsVersion);
                }
                else if(('MobileDevice').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techMobileDev = new DART6_LINEITEMSERVICE.Technology();
                    techMobileDev.id = d.Dart_ID__c.longValue();
                    listMobileDevice.add(techMobileDev);
                }
                else if(('MobileDeviceSubmodel').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techMobileDevSubMd = new DART6_LINEITEMSERVICE.Technology();
                    techMobileDevSubMd.id = d.Dart_ID__c.longValue();
                    listMobileDeviceSubMod.add(techMobileDevSubMd);
                }
                
                
                
           }
           /*DART6_LINEITEMSERVICE.Technology t = new DART6_LINEITEMSERVICE.Technology();
           t.id = Long.valueOf('605620');
           listDeviceManufacturer = new List<DART6_LINEITEMSERVICE.Technology>();
           listDeviceManufacturer.add(t);
           */
           // DART6_LINEITEMSERVICE.BrowserTargeting
          DART6_LINEITEMSERVICE.BrowserTargeting browserTargeting = null;
           if(!listBrowsing.isEmpty())
           {
                browserTargeting = new DART6_LINEITEMSERVICE.BrowserTargeting();
                browserTargeting.browsers = listBrowsing;
           }
           
           // DART6_LINEITEMSERVICE.BrowserLanguageTargeting
           DART6_LINEITEMSERVICE.BrowserLanguageTargeting browserLanguageTargeting = null;
           if(!listBrowsingLang.isEmpty())
           {
                browserLanguageTargeting = new DART6_LINEITEMSERVICE.BrowserLanguageTargeting();
                browserLanguageTargeting.browserLanguages = listBrowsingLang;
           }
           
           // DART6_LINEITEMSERVICE.DeviceCapabilityTargeting
           DART6_LINEITEMSERVICE.DeviceCapabilityTargeting deviceCapabilityTargeting = null;
           if(!listDeviceCap.isEmpty())
           {
                deviceCapabilityTargeting = new DART6_LINEITEMSERVICE.DeviceCapabilityTargeting();
                deviceCapabilityTargeting.targetedDeviceCapabilities = listDeviceCap;
           }
           
           //DART6_LINEITEMSERVICE.DeviceCategoryTargeting
           DART6_LINEITEMSERVICE.DeviceCategoryTargeting deviceCategoryTargeting = null;
           if(!listDeviceCategory.isEmpty())
           {
                deviceCategoryTargeting = new DART6_LINEITEMSERVICE.DeviceCategoryTargeting();
                deviceCategoryTargeting.targetedDeviceCategories = listDeviceCategory;
           }
           
           //DART6_LINEITEMSERVICE.DeviceManufacturerTargeting ;
           DART6_LINEITEMSERVICE.DeviceManufacturerTargeting deviceManufacturerTargeting = null;
           if(!listDeviceManufacturer.isEmpty())
           {
                deviceManufacturerTargeting = new DART6_LINEITEMSERVICE.DeviceManufacturerTargeting();
                deviceManufacturerTargeting.deviceManufacturers = listDeviceManufacturer;
           }
           
           //DART6_LINEITEMSERVICE.OperatingSystemTargeting
           DART6_LINEITEMSERVICE.OperatingSystemTargeting OperatingSystemTargeting = null;
           if(!listOpSys.isEmpty())
           {
                OperatingSystemTargeting = new DART6_LINEITEMSERVICE.OperatingSystemTargeting();
                OperatingSystemTargeting.operatingSystems = listOpSys;
           }
           
           //DART6_LINEITEMSERVICE.OperatingSystemVersionTargeting
           DART6_LINEITEMSERVICE.OperatingSystemVersionTargeting operatingSystemVersionTargeting = null;
           if(!listOpSysVersion.isEmpty())
           {
                operatingSystemVersionTargeting = new DART6_LINEITEMSERVICE.OperatingSystemVersionTargeting();
                operatingSystemVersionTargeting.targetedOperatingSystemVersions = listOpSysVersion;
           }
           
           //DART6_LINEITEMSERVICE.MobileDeviceTargeting
           DART6_LINEITEMSERVICE.MobileDeviceTargeting mobileDeviceTargeting = null;
           if(!listMobileDevice.isEmpty())
           {
                mobileDeviceTargeting = new DART6_LINEITEMSERVICE.MobileDeviceTargeting();
                mobileDeviceTargeting.targetedMobileDevices = listMobileDevice;
           }
           
           //DART6_LINEITEMSERVICE.MobileDeviceSubmodelTargeting
           DART6_LINEITEMSERVICE.MobileDeviceSubmodelTargeting mobileDeviceSubmodelTargeting = null;
           if(!listMobileDeviceSubMod.isEmpty())
           {
                mobileDeviceSubmodelTargeting = new DART6_LINEITEMSERVICE.MobileDeviceSubmodelTargeting();
                mobileDeviceSubmodelTargeting.targetedMobileDeviceSubmodels = listMobileDeviceSubMod;
           }
           
           

          //TechnologyTargeting
          DART6_LINEITEMSERVICE.TechnologyTargeting technologyTargeting = new DART6_LINEITEMSERVICE.TechnologyTargeting();
          
          
          if(browserTargeting!=null)
          {
            technologyTargeting.browserTargeting = browserTargeting;
          }
          
          if(bandwidthGroupTargeting!=null)
          {
            technologyTargeting.bandwidthGroupTargeting = bandwidthGroupTargeting;
          }
          
          if(mobileCarrierTargeting!=null)
          {
            technologyTargeting.mobileCarrierTargeting = mobileCarrierTargeting;
          }
          
          if(browserTargeting!=null)
          {
            technologyTargeting.browserTargeting = browserTargeting;
          } 
          
          if(browserLanguageTargeting!=null)
          {
            technologyTargeting.browserLanguageTargeting = browserLanguageTargeting;
          }
          
          if(deviceCapabilityTargeting!=null)
          {
            technologyTargeting.deviceCapabilityTargeting = deviceCapabilityTargeting;
          }
          
          if(deviceCategoryTargeting!=null)
          {
            technologyTargeting.deviceCategoryTargeting = deviceCategoryTargeting;
          }
          
          if(deviceManufacturerTargeting!=null)
          {
            technologyTargeting.deviceManufacturerTargeting = deviceManufacturerTargeting;
          } 
          
          if(OperatingSystemTargeting!=null)
          {
            technologyTargeting.OperatingSystemTargeting = OperatingSystemTargeting; 
          }
          
          if(operatingSystemVersionTargeting!=null)
          {
                technologyTargeting.operatingSystemVersionTargeting = operatingSystemVersionTargeting; 
          }
          
          if(mobileDeviceTargeting!=null)
          {
                technologyTargeting.mobileDeviceTargeting = mobileDeviceTargeting;
          }  
          
          if(mobileDeviceSubmodelTargeting!=null)
          {
                technologyTargeting.mobileDeviceSubmodelTargeting = mobileDeviceSubmodelTargeting;
          }
          
        // Targeting
        DART6_LINEITEMSERVICE.Targeting itemTargeting = new DART6_LINEITEMSERVICE.Targeting();
        
        // InventoryTargeting
        DART6_LINEITEMSERVICE.InventoryTargeting inventoryTargeting = new DART6_LINEITEMSERVICE.InventoryTargeting();
        inventoryTargeting.targetedPlacementIds = placementIds; 
        inventoryTargeting.targetedAdUnits = adUnitTargs;
        
        itemTargeting.inventoryTargeting  = inventoryTargeting;
        
        if(lstLocations.size()>0)
        {
          //DART6_FORECASTSERVICE.GeoTargeting
          DART6_LINEITEMSERVICE.GeoTargeting geoTargeting = new DART6_LINEITEMSERVICE.GeoTargeting();
          geoTargeting.targetedLocations = lstLocations;
          itemTargeting.geoTargeting = geoTargeting;
          
        }
        
        if(lstDayParts.size()>0) // daysParts is not required if it has values, it will be set
        {
          //DART6_FORECASTSERVICE.DayPartTargeting
          DART6_LINEITEMSERVICE.DayPartTargeting dayPartTargeting = new DART6_LINEITEMSERVICE.DayPartTargeting();
          dayPartTargeting.dayParts = lstDayParts;
          dayPartTargeting.timeZone = 'BROWSER';
          itemTargeting.dayPartTargeting = dayPartTargeting;
        }
        
        itemTargeting.technologyTargeting = technologyTargeting;
    
    
    
        ctrl = new DART6_KeyValueController(item.PricebookEntry.Product2.Site__r.Id, dartAds.getKeyWKV(), authToken, login.Network_ID__c);
                    
        
        
        if(ctrl.isNeedToCreate()) 
      {
        ctrl.searchCreateDFPFreeFormValues();
        
      }
        listCrit = (List<DART6_FORECASTSERVICE.CustomCriteriaSet>)ctrl.getListDart();
    
        
        if(listCrit.size()>0)
        {
          itemTargeting.customTargeting = listCrit.get(0);
          
        } 
          
        // Money
        DART6_LINEITEMSERVICE.Money money = new DART6_LINEITEMSERVICE.Money();
        money.currencyCode = dartAds.getCurrencyCode(); //'USD'; 
        system.debug('money.currencyCode >>>>>>>>>>>>>> ' + money.currencyCode);
        money.microAmount = Long.valueOf(dartAds.getRate()+'');//dartAds.getRate();
             
        //LineItem Size
        DART6_LINEITEMSERVICE.Size itemSize = new DART6_LINEITEMSERVICE.Size();
        itemSize.width = (('').equals(dartAds.getAdSlotW())?0:Integer.valueOf(dartAds.getAdSlotW()+''));
        itemSize.height = (('').equals(dartAds.getAdSlotH())?0:Integer.valueOf(dartAds.getAdSlotH()+''));
        itemSize.isAspectRatio = false;
        
        // CreativePlaceholder
        DART6_LINEITEMSERVICE.CreativePlaceholder creativePlc = new DART6_LINEITEMSERVICE.CreativePlaceholder();
        creativePlc.size = itemSize;
            
        /** Create LineItem */
        DART6_LINEITEMSERVICE.LineItem lineItem = new DART6_LINEITEMSERVICE.LineItem();
        if(dartOrder != null)
        {
          lineItem.orderId = Long.valueOf(dartOrder.getDartId()); // Set order id to LineItem
        }   
        
        lineItem.name = dartAds.getName();  
                 if(dartAds.getUnit().equals(BILLING_CATE_FIX_PRICE) || dartAds.getUnit().equals('CPD'))
            {
              lineItem.lineItemType = 'SPONSORSHIP';         
            }else
            {
              //lineItem.lineItemType = 'STANDARD';
        DART_ProductType_Mapper__c custPrdType = DART_ProductType_Mapper__c.getInstance(dartAds.getDartProductType());
        lineItem.lineItemType = (custPrdType!=null?custPrdType.DFP_Product_Type__c:'');
            }

//        lineItem.priority = dartAds.getPriority();
                
        //lineItem.lineItemType = (dartAds.getUnit().equals(BILLING_CATE_FIX_PRICE) || dartAds.getUnit().equals('CPD'))?'SPONSORSHIP':'STANDARD';      
        lineItem.notes = dartAds.getOppItemID();
        lineItem.WebPropertyCode = dartAds.getDartWebPropertyAlias();
        lineItem.targetPlatform = dartAds.getDartTargetPlatform();
        lineItem.costType = dartAds.getUnit().equals(BILLING_CATE_FIX_PRICE)?'CPD':dartAds.getUnit();
        lineItem.startDateTime = dartTimexStart;
        lineItem.endDateTime = dartTimexEnd;
        lineItem.targeting = itemTargeting;
        
//      2015-01-06 - GTCRM-1653 - Allow Overbooking When Pushing from SF to DFP
        lineItem.allowOverbook = TRUE;
        
        // LineItem Custom field
        DART6_LINEITEMSERVICE.TextValue custVal = new DART6_LINEITEMSERVICE.TextValue();
//        custVal.value = opp.owner.Division;
// - GTCRM-1012 - Opportunity Account Record type to be submitted to Sales team custom field
        custVal.value = opp.Account.RecordType.Name;
        custVal.type_x = 'TextValue'; 
          
        DART6_LINEITEMSERVICE.CustomFieldValue custFldVal = new DART6_LINEITEMSERVICE.CustomFieldValue();
        custFldVal.customFieldId =  1630;
        //custFldVal.customFieldId =  11893;   for test
        custFldVal.type_x= 'CustomFieldValue';
        custFldVal.value = custVal;
        
        System.debug('---------------->>custFldVal:' + custFldVal);
        
        lineItem.customFieldValues = new List<DART6_LINEITEMSERVICE.BaseCustomFieldValue>{custFldVal};
        
        if(!dartAds.getQuantity().equals(''))
        {
            DART6_LINEITEMSERVICE.Goal gl = new DART6_LINEITEMSERVICE.Goal();    //new version 2014
            
            if(dartAds.getUnit().equals(BILLING_CATE_FIX_PRICE) || dartAds.getUnit().equals('CPD') 
              || (LINEITEM_TYPE_NETWORK).equals(dartAds.getDartProductType()) || (LINEITEM_TYPE_HOUSE).equals(dartAds.getDartProductType()))
            {
              //  lineItem.unitsBought = 100;   old version
                  gl.units = 100;
                  lineItem.primaryGoal = gl;
            }else
            {
               // lineItem.unitsBought = Long.valueOf(dartAds.getQuantity()+''); old version
                  gl.units = Long.valueOf(dartAds.getQuantity()+'');
                  lineItem.primaryGoal = gl;
            }
          
        }

        
        // If line item start date is today then set StartDateTimeType to ONE_HOUR_FROM_NOW
    if(dartAds.getStartDateTime().isSameDay(System.today()))
    {
      lineItem.startDateTimeType = 'ONE_HOUR_FROM_NOW';
    }
        
        lineItem.costPerUnit = money;
        lineItem.creativePlaceholders = new DART6_LINEITEMSERVICE.CreativePlaceholder[]{creativePlc};
        
        
        if(!''.equals(dartAds.getFCPeriodDart6()))
        {
          // FrequencyCap
          DART6_LINEITEMSERVICE.FrequencyCap freqCap = new DART6_LINEITEMSERVICE.FrequencyCap();
          freqCap.numTimeUnits = DARTUtil.toInteger(dartAds.getFCAdServedEvery());
          freqCap.maxImpressions = DARTUtil.toInteger(dartAds.getFCQty());
          freqCap.timeUnit = MAP_TIME_UNITS.get(dartAds.getFCPeriodDart6()); 
        
          lineItem.frequencyCaps = new DART6_LINEITEMSERVICE.FrequencyCap[]{freqCap};
        }
         
        try{
            system.debug('ad Id :>>>>>>>>>>>>> ' + dartAds.getAdId());
          if(dartAds.getAdId()==null) // if Ad_Id__c=null => Create new LineItem
          {
            //dfpLineItemResponse = lineItemService.createLineItem(lineItem);   old version
            
            List<DART6_LINEITEMSERVICE.LineItem> lstItemResp = lineItemService.createLineItems(new List<DART6_LINEITEMSERVICE.LineItem>{lineItem});
            if(!lstItemResp.isEmpty()) dfpLineItemResponse = lstItemResp.get(0);
                        
            invokedMethod = 'Create LineItem/Ads';
            
          }
          else // Update LineItem  
          {
            lineItem.id = Long.valueOf(dartAds.getAdId());
            //dfpLineItemResponse = lineItemService.updateLineItem(lineItem);  old version
            List<DART6_LINEITEMSERVICE.LineItem> lstItemResp = lineItemService.updateLineItems(new List<DART6_LINEITEMSERVICE.LineItem>{lineItem});
            if(!lstItemResp.isEmpty()) dfpLineItemResponse = lstItemResp.get(0);
            
            invokedMethod = 'Update LineItem/Ads';
          }
          
          if(listCrit.size()>0)
        {
                ctrl.updateDart6ValueIds();
        }
          //System.debug('++++++++++++++++++++++++++++=> CreateNew: ' + ctrl.isCreateNewKv());
         if(ctrl.isCreateNewKv())
        {
           ctrl.createObjectKeyVal();
        }
          System.debug('======================== dfpLineItemResponse: ' + dfpLineItemResponse);
          
        }
        catch(System.CalloutException cex){
          throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
        }  
        catch(Exception ex){
          throw new ExceptionGroup.DARTException('' + ex.getMessage());
        }    

            
    }
    
    public Object getResponseObject()
    {
      return dfpLineItemResponse;
    }
    
  }
  
  
  
  
  /**
   * Forecast Request
   */

  public class DFPForecastRequest extends AbstractDFPRequest{
    
    List<String> adIds;
    OpportunityLineItem oppItem;
    
    DARTObject.DARTForecast dartObjForecast;
    
    public DART6_FORECASTSERVICE.Forecast forecast;
    
    public DFPForecastRequest(OpportunityLineItem oppItem)
    {
      this.oppItem = oppItem;
    }
    
    public void invoke()
    {
  
    DART6_KeyValueController ctrl;
    List<DART6_FORECASTSERVICE.CustomCriteriaSet> listCrit = new List<DART6_FORECASTSERVICE.CustomCriteriaSet>();
        
      //String authToken = DARTUtil.getRequestToken(oppItem.PriceBookEntry.Product2.Site__r.Country__c);  old version


      AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6,oppItem.PriceBookEntry.Product2.Site__r.Country__c);
      String authToken = DARTUtil.getAccessToken(login); // new version 201411
      
      DART6_FORECASTSERVICE.SoapRequestHeader header = new DART6_FORECASTSERVICE.SoapRequestHeader();
        
      header.applicationName='ForecastService';
      header.networkCode= login.Network_ID__c;
      
      Map<String,String> inputHttpHeaders_x = new Map<String, String>();      // new version 201411
      inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);           // new version 201411
    
      DART6_FORECASTSERVICE.ForecastServiceInterfacePort forecastService = new DART6_FORECASTSERVICE.ForecastServiceInterfacePort();
      forecastService.RequestHeader = header;
      forecastService.inputHttpHeaders_x = inputHttpHeaders_x;               // new version 201411
      
      if(oppItem != null)
      {
        String strFCErr = '';
        
        //if(oppItem.Ad_Id__c != null) // An oppItem already has Ad's Id From Dart6
        //{
        //  forecast  =  forecastService.getForecastById(Long.valueOf(oppItem.Ad_Id__c));
        //  invokedMethod = 'getForecastById';
        //  
        //}
        //else
        //{
          dartObjForecast = new DARTObject.DARTForecast(oppItem);
          
          // setDartTime Start
          DART6_FORECASTSERVICE.Date_x datexStart = new DART6_FORECASTSERVICE.Date_x();
          datexStart.day = Integer.valueOf(dartObjForecast.getStartDay()+'');
          datexStart.month = Integer.valueOf(dartObjForecast.getStartMonth()+'');
          datexStart.year = Integer.valueOf(dartObjForecast.getStartYear()+'');
          
          DART6_FORECASTSERVICE.DateTime_x dartTimexStart = new DART6_FORECASTSERVICE.DateTime_x();
          dartTimexStart.date_x = datexStart;
          dartTimexStart.hour = 0;
          dartTimexStart.minute = 0;
          dartTimexStart.second = 0;
          dartTimexStart.timeZoneID ='BROWSER';
          
          // setDartTime End
          DART6_FORECASTSERVICE.Date_x datexEnd = new DART6_FORECASTSERVICE.Date_x();
          datexEnd.day = Integer.valueOf(dartObjForecast.getEndDay()+'');
          datexEnd.month = Integer.valueOf(dartObjForecast.getEndMonth()+'');
          datexEnd.year = Integer.valueOf(dartObjForecast.getEndYear()+'');
          
          DART6_FORECASTSERVICE.DateTime_x dartTimexEnd = new DART6_FORECASTSERVICE.DateTime_x();
          dartTimexEnd.date_x = datexEnd;
          dartTimexEnd.hour = 23;
          dartTimexEnd.minute = 59;
          dartTimexEnd.second = 0;
          dartTimexEnd.timeZoneID ='BROWSER';
          
          // Get placement Ids
          //NK:20/01/2013
          //  If Content.Type__c = “DART – ContentCategory”, it should be mapped to PlacementId
          //  If Content.Type__c = “DART – Site” or “DART – Zone”, it should be mapped to AdUnitId
           
          List<Long> placementIds = new List<Long>();
          for(Content__c cCat : dartObjForecast.getIncludeContentCat())
          {
            placementIds.add(Long.valueOf(cCat.Name+''));
          }
          
          //customTargeting
          //DART6_FORECASTSERVICE.CustomCriteriaSet customCriteriaSet = new DART6_FORECASTSERVICE.CustomCriteriaSet();
          //customCriteriaSet.logicalOperator = dartObjForecast.getKeyWKV();
          
          
          
          ctrl = new DART6_KeyValueController(oppItem.PricebookEntry.Product2.Site__r.Id, dartObjForecast.getKeyWKV(), authToken, login.Network_ID__c);
                    
          
        
          if(ctrl.isNeedToCreate()) 
        {
          ctrl.searchCreateDFPFreeFormValues();
        }
          listCrit = (List<DART6_FORECASTSERVICE.CustomCriteriaSet>)ctrl.getListDart();
          
          //targetedAdUnits 
          List<DART6_FORECASTSERVICE.AdUnitTargeting> adUnitTargs = new List<DART6_FORECASTSERVICE.AdUnitTargeting>();
          
          for(Content__c dartSite : dartObjForecast.getIncludeDartSite())
          {
            DART6_FORECASTSERVICE.AdUnitTargeting adunit = new DART6_FORECASTSERVICE.AdUnitTargeting();
            adunit.adUnitId = dartSite.Name;
            adUnitTargs.add(adunit);
          }
          for(Content__c dartZone : dartObjForecast.getIncludeDartZone())
          {
            DART6_FORECASTSERVICE.AdUnitTargeting adunit = new DART6_FORECASTSERVICE.AdUnitTargeting();
            adunit.adUnitId = dartZone.Name;
            adUnitTargs.add(adunit);
          }
          
          
              //DART6_FORECASTSERVICE.Location
             List<DART6_FORECASTSERVICE.Location> lstLocations = new List<DART6_FORECASTSERVICE.Location>();
             
             for(Geography__c g : dartObjForecast.getIncludeGeography())
             {
                DART6_FORECASTSERVICE.Location loc = new DART6_FORECASTSERVICE.Location();
                 loc.id = Long.valueOf(g.Dart_ID__c+''); 
                 loc.Location_Type = g.Type__c;
                 lstLocations.add(loc); 
             }
         
         
  
          //DART6_FORECASTSERVICE.GeoTargeting
          DART6_FORECASTSERVICE.GeoTargeting geoTargeting = new DART6_FORECASTSERVICE.GeoTargeting();
          geoTargeting.targetedLocations = lstLocations;      
          
          // GTCRM-880 pushing - Devices & Connection to DFP(Targeting)
          // 09-06-2014
           
            DART6_FORECASTSERVICE.BandwidthGroupTargeting bandwidthGroupTargeting = null;
            DART6_FORECASTSERVICE.MobileCarrierTargeting mobileCarrierTargeting = null;
            Set<String> bandWidthParentIds = new Set<String>();
            Set<String> mobileCarParentIds = new Set<String>();
            Set<String> connIds = new Set<String>();
            for(Connection__c c : dartObjForecast.getIncludeConnection())
            {

                if(('BandwidthGroup').equals(c.DFP_API_Name__c))
                {
                    bandWidthParentIds.add(c.id);
                }
                else if(('MobileCarrier').equals(c.DFP_API_Name__c))
                {
                    mobileCarParentIds.add(c.id);
                }else connIds.add(c.id);
            }

            Set<String> mcParids = new Set<String>();

            // Bandwidth connection
            List<Connection__c> lstConnBwidth = new List<Connection__c>();

            for(Connection__c c : dartObjForecast.getIncludeConnection())
            {
                if(bandWidthParentIds.contains(c.Node_ID__c))
                {
                    lstConnBwidth.add(c);
                }
                else if(mobileCarParentIds.contains(c.Node_ID__c))
                {
                    mcParids.add(c.Id);
                }
            }

            //MobileCarrier connection
            List<Connection__c> lstMbCar = new List<Connection__c>();
            for(Connection__c c : dartObjForecast.getIncludeConnection())
            {
                if(mcParids.contains(c.Node_ID__c))
                {
                    lstMbCar.add(c);
                }
            }

            DART6_FORECASTSERVICE.Technology[] listBandWidth = new List<DART6_FORECASTSERVICE.Technology>();
            // Bandwidth 
            for(Connection__c con : lstConnBwidth)
            {
                DART6_FORECASTSERVICE.Technology technologyBw = new DART6_FORECASTSERVICE.Technology();
                technologyBw.id = con.Dart_ID__c.longValue();
                listBandWidth.add(technologyBw);
            }

            if(!listBandWidth.isEmpty())
            {
                bandwidthGroupTargeting = new DART6_FORECASTSERVICE.BandwidthGroupTargeting();
                bandwidthGroupTargeting.bandwidthGroups = listBandWidth;
            }

            //MobileCarrier
            DART6_FORECASTSERVICE.Technology[] techMobileCar = new List<DART6_FORECASTSERVICE.Technology>();
            for(Connection__c con : lstMbCar)
            {
                DART6_FORECASTSERVICE.Technology techMb = new DART6_FORECASTSERVICE.Technology();
                techMb.id = con.Dart_ID__c.longValue();
                techMobileCar.add(techMb);
            }

            if(!techMobileCar.isEmpty())
            {
                mobileCarrierTargeting = new DART6_FORECASTSERVICE.MobileCarrierTargeting();
                mobileCarrierTargeting.mobileCarriers = techMobileCar;
            }

            // -------------------------->> Device Targeting <<--------------------------------
            DART6_FORECASTSERVICE.Technology[] listBrowsing = new List<DART6_FORECASTSERVICE.Technology>();
            DART6_FORECASTSERVICE.Technology[] listBrowsingLang = new List<DART6_FORECASTSERVICE.Technology>();
            DART6_FORECASTSERVICE.Technology[] listDeviceCap = new List<DART6_FORECASTSERVICE.Technology>();
            DART6_FORECASTSERVICE.Technology[] listDeviceCategory = new List<DART6_FORECASTSERVICE.Technology>();
            DART6_FORECASTSERVICE.Technology[] listDeviceManufacturer = new List<DART6_FORECASTSERVICE.Technology>();
            DART6_FORECASTSERVICE.Technology[] listOpSys = new List<DART6_FORECASTSERVICE.Technology>();
            DART6_FORECASTSERVICE.Technology[] listOpSysVersion = new List<DART6_FORECASTSERVICE.Technology>();
            DART6_FORECASTSERVICE.Technology[] listMobileDevice = new List<DART6_FORECASTSERVICE.Technology>();
            DART6_FORECASTSERVICE.Technology[] listMobileDeviceSubMod = new List<DART6_FORECASTSERVICE.Technology>();
            

            for(Devices__c d : dartObjForecast.getIncludeDevice())
            {
                if(('Browser').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techBrw = new DART6_FORECASTSERVICE.Technology();
                    techBrw.id = d.Dart_ID__c.longValue();
                    listBrowsing.add(techBrw);
                }
                else if(('BrowserLanguage').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techBrwLang = new DART6_FORECASTSERVICE.Technology();
                    techBrwLang.id = d.Dart_ID__c.longValue();
                    listBrowsingLang.add(techBrwLang);
                }
                else if(('DeviceCapability').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techDevCap = new DART6_FORECASTSERVICE.Technology();
                    techDevCap.id = d.Dart_ID__c.longValue();
                    listDeviceCap.add(techDevCap);
                }
                else if(('DeviceCategory').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techDevCate = new DART6_FORECASTSERVICE.Technology();
                    techDevCate.id = d.Dart_ID__c.longValue();
                    listDeviceCategory.add(techDevCate);
                }
                else if(('DeviceManufacturer').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techDevMf = new DART6_FORECASTSERVICE.Technology();
                    techDevMf.id = d.Dart_ID__c.longValue();
                    listDeviceManufacturer.add(techDevMf);
                } 
                else if(('OperatingSystem').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techOs = new DART6_FORECASTSERVICE.Technology();
                    techOs.id = d.Dart_ID__c.longValue();
                    listOpSys.add(techOs);
                }
                else if(('OperatingSystemVersion').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techOsVersion = new DART6_FORECASTSERVICE.Technology();
                    techOsVersion.id = d.Dart_ID__c.longValue();
                    listOpSysVersion.add(techOsVersion);
                }
                
                else if(('MobileDevice').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techMobileDev = new DART6_FORECASTSERVICE.Technology();
                    techMobileDev.id = d.Dart_ID__c.longValue();
                    listMobileDevice.add(techMobileDev);
                }
                else if(('MobileDeviceSubmodel').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techMobileDevSubMd = new DART6_FORECASTSERVICE.Technology();
                    techMobileDevSubMd.id = d.Dart_ID__c.longValue();
                    listMobileDeviceSubMod.add(techMobileDevSubMd);
                }
                
            }

            // DART6_FORECASTSERVICE.BrowserTargeting
            DART6_FORECASTSERVICE.BrowserTargeting browserTargeting = null;
            if(!listBrowsing.isEmpty())
            {
                browserTargeting = new DART6_FORECASTSERVICE.BrowserTargeting();
                browserTargeting.browsers = listBrowsing;
            }

            // DART6_FORECASTSERVICE.BrowserLanguageTargeting
            DART6_FORECASTSERVICE.BrowserLanguageTargeting browserLanguageTargeting = null;
            if(!listBrowsingLang.isEmpty())
            {
                browserLanguageTargeting = new DART6_FORECASTSERVICE.BrowserLanguageTargeting();
                browserLanguageTargeting.browserLanguages = listBrowsingLang;
            }

            // DART6_FORECASTSERVICE.DeviceCapabilityTargeting
            DART6_FORECASTSERVICE.DeviceCapabilityTargeting deviceCapabilityTargeting = null;
            if(!listDeviceCap.isEmpty())
            {
                deviceCapabilityTargeting = new DART6_FORECASTSERVICE.DeviceCapabilityTargeting();
                deviceCapabilityTargeting.targetedDeviceCapabilities = listDeviceCap;
            }

            //DART6_FORECASTSERVICE.DeviceCategoryTargeting
            DART6_FORECASTSERVICE.DeviceCategoryTargeting deviceCategoryTargeting = null;
            if(!listDeviceCategory.isEmpty())
            {
                deviceCategoryTargeting = new DART6_FORECASTSERVICE.DeviceCategoryTargeting();
                deviceCategoryTargeting.targetedDeviceCategories = listDeviceCategory;
            }

            //DART6_FORECASTSERVICE.DeviceManufacturerTargeting ;
            DART6_FORECASTSERVICE.DeviceManufacturerTargeting deviceManufacturerTargeting = null;
            if(!listDeviceManufacturer.isEmpty())
            {
                deviceManufacturerTargeting = new DART6_FORECASTSERVICE.DeviceManufacturerTargeting();
                deviceManufacturerTargeting.deviceManufacturers = listDeviceManufacturer;
            }

            //DART6_FORECASTSERVICE.OperatingSystemTargeting
            DART6_FORECASTSERVICE.OperatingSystemTargeting OperatingSystemTargeting = null;
            if(!listOpSys.isEmpty())
            {
                OperatingSystemTargeting = new DART6_FORECASTSERVICE.OperatingSystemTargeting();
                OperatingSystemTargeting.operatingSystems = listOpSys;
            }

            //DART6_FORECASTSERVICE.OperatingSystemVersionTargeting
            DART6_FORECASTSERVICE.OperatingSystemVersionTargeting operatingSystemVersionTargeting = null;
            if(!listOpSysVersion.isEmpty())
            {
                operatingSystemVersionTargeting = new DART6_FORECASTSERVICE.OperatingSystemVersionTargeting();
                operatingSystemVersionTargeting.targetedOperatingSystemVersions = listOpSysVersion;
            }
            
            //DART6_FORECASTSERVICE.MobileDeviceTargeting
            DART6_FORECASTSERVICE.MobileDeviceTargeting mobileDeviceTargeting = null;
            if(!listMobileDevice.isEmpty())
            {
                mobileDeviceTargeting = new DART6_FORECASTSERVICE.MobileDeviceTargeting();
                mobileDeviceTargeting.targetedMobileDevices = listMobileDevice;
            }
           
            //DART6_FORECASTSERVICE.MobileDeviceSubmodelTargeting
            DART6_FORECASTSERVICE.MobileDeviceSubmodelTargeting mobileDeviceSubmodelTargeting = null;
            if(!listMobileDeviceSubMod.isEmpty())
            {
                mobileDeviceSubmodelTargeting = new DART6_FORECASTSERVICE.MobileDeviceSubmodelTargeting();
                mobileDeviceSubmodelTargeting.targetedMobileDeviceSubmodels = listMobileDeviceSubMod;
            }
            
            //TechnologyTargeting
            DART6_FORECASTSERVICE.TechnologyTargeting technologyTargeting = new DART6_FORECASTSERVICE.TechnologyTargeting();


            if(browserTargeting!=null)
            {
                technologyTargeting.browserTargeting = browserTargeting;
            }

            if(bandwidthGroupTargeting!=null)
            {
                technologyTargeting.bandwidthGroupTargeting = bandwidthGroupTargeting;
            }

            if(mobileCarrierTargeting!=null)
            {
                technologyTargeting.mobileCarrierTargeting = mobileCarrierTargeting;
            }

            if(browserTargeting!=null)
            {
                technologyTargeting.browserTargeting = browserTargeting;
            } 

            if(browserLanguageTargeting!=null)
            {
                technologyTargeting.browserLanguageTargeting = browserLanguageTargeting;
            }

            if(deviceCapabilityTargeting!=null)
            {
                technologyTargeting.deviceCapabilityTargeting = deviceCapabilityTargeting;
            }

            if(deviceCategoryTargeting!=null)
            {
                technologyTargeting.deviceCategoryTargeting = deviceCategoryTargeting;
            }

            if(deviceManufacturerTargeting!=null)
            {
                technologyTargeting.deviceManufacturerTargeting = deviceManufacturerTargeting;
            } 

            if(OperatingSystemTargeting!=null)
            {
                technologyTargeting.OperatingSystemTargeting = OperatingSystemTargeting; 
            }

            if(operatingSystemVersionTargeting!=null)
            {
                technologyTargeting.operatingSystemVersionTargeting = operatingSystemVersionTargeting; 
            }
            
            if(mobileDeviceTargeting!=null)
            {
                technologyTargeting.mobileDeviceTargeting = mobileDeviceTargeting;
            }  
          
            if(mobileDeviceSubmodelTargeting!=null)
            {
                technologyTargeting.mobileDeviceSubmodelTargeting = mobileDeviceSubmodelTargeting;
            }
          
          
         
          
      //NK:29/01/2013------------------------------------------------------------------------------------------------------
          
      //DayPart
                    List<DART6_FORECASTSERVICE.DayPart> lstDayParts = new List<DART6_FORECASTSERVICE.DayPart>();
                   
                    /* Bunhor : 17-Feb-14. blocked. Use new fields: LI.DFP_Time_Monday__c - LI.DFP_Time_Sunday__c
                    // Day of Week
                    //ex: sunday; monday
                    //ex: 22:00 - 22:59; 23:00 - 23:59
                    //-> sunday: 22:00 - 22:59; 23:00 - 23:59
                    //-> monday: 22:00 - 22:59; 23:00 - 23:59
                    
                    for(String dw : dartObjForecast.getDayOfWeek())
                    {

                        // Hours of Day
                        //(22:00 - 22:59, 23:00 - 23:59,.....)
                        //NK:Fixed: 09/02/2013
                        String[] hods = dartObjForecast.getHourOfDay();
                        hods = !hods.isEmpty()?hods:new String[]{'00:00 - 23:59'}; //all time if time not specified.
                        for(String hd : hods)
                        {
                            List<String> lsthd = hd.split('-'); // (22:00, 22:59)
                            List<String> lstTimeStart = lsthd[0].split(':'); //(22, 00)
                            List<String> lstTimeEnd = lsthd[1].split(':'); // (22, 59)
                            
                            DART6_FORECASTSERVICE.TimeOfDay startTimeOfDay = new DART6_FORECASTSERVICE.TimeOfDay();
                            startTimeOfDay.hour = Integer.valueOf(lstTimeStart[0].trim()+'');
                            startTimeOfDay.minute ='ZERO';// lstTimeStart[1].trim();
                            
                            DART6_FORECASTSERVICE.TimeOfDay endTimeOfDay = new DART6_FORECASTSERVICE.TimeOfDay();
                            
                            //endTimeOfDay.hour = Integer.valueOf(lstTimeEnd[0].trim()+'');
                            //endTimeOfDay.minute ='FORTY_FIVE';// lstTimeEnd[1].trim();
                            
                            endTimeOfDay.hour = Integer.valueOf(lstTimeEnd[0].trim()+'')+1;
                            endTimeOfDay.minute ='ZERO';// lstTimeEnd[1].trim();
                            
                            DART6_FORECASTSERVICE.DayPart dayPart = new DART6_FORECASTSERVICE.DayPart();
                            dayPart.dayOfWeek = dw.toUpperCase();
                            dayPart.startTime = startTimeOfDay;
                            dayPart.endTime = endTimeOfDay;
                            
                            lstDayParts.add(dayPart);
                            
                        }
                    }
                    */
                    
                    // Bunhor: 17-Feb-14. For Time Targeting with different hours on different days
                    for(DARTObject.DTOTimeTargeting dto : dartObjForecast.getListDTOTimeTargeting() ){
                      for(String hour : dto.hours){   // Ex: dto.hours = ('0:00 - 0:59', '1:00 - 1:59')
                        List<String> lsthd = hour.split('-'); // (0:00, 0:59)
                            List<String> lstTimeStart = lsthd[0].split(':'); //(0, 00)
                            List<String> lstTimeEnd = lsthd[1].split(':'); // (0, 59)
                        
                        DART6_FORECASTSERVICE.TimeOfDay startTimeOfDay = new DART6_FORECASTSERVICE.TimeOfDay();
                            startTimeOfDay.hour = Integer.valueOf(lstTimeStart[0].trim()+'');
                            startTimeOfDay.minute ='ZERO'; 
                            
                            DART6_FORECASTSERVICE.TimeOfDay endTimeOfDay = new DART6_FORECASTSERVICE.TimeOfDay(); 
                            endTimeOfDay.hour = Integer.valueOf(lstTimeEnd[0].trim()+'')+1;
                            endTimeOfDay.minute ='ZERO'; 
                            
                            DART6_FORECASTSERVICE.DayPart dayPart = new DART6_FORECASTSERVICE.DayPart();
                            dayPart.dayOfWeek = dto.day.toUpperCase();
                            dayPart.startTime = startTimeOfDay;
                            dayPart.endTime = endTimeOfDay;
                            
                            lstDayParts.add(dayPart);
                      }
                    }
                    
                    
          // Targeting
          DART6_FORECASTSERVICE.Targeting itemTargeting = new DART6_FORECASTSERVICE.Targeting();
          
          // InventoryTargeting
          DART6_FORECASTSERVICE.InventoryTargeting inventoryTargeting = new DART6_FORECASTSERVICE.InventoryTargeting();
          inventoryTargeting.targetedPlacementIds = placementIds; //new Long[]{Long.valueOf('2083573')} ; //2083573 placementId
          inventoryTargeting.targetedAdUnits = adUnitTargs;
          
          itemTargeting.inventoryTargeting  = inventoryTargeting;
          itemTargeting.geoTargeting = geoTargeting;
          
          if(lstDayParts.size() > 0)
          {
            //DART6_FORECASTSERVICE.DayPartTargeting
            DART6_FORECASTSERVICE.DayPartTargeting dayPartTargeting = new DART6_FORECASTSERVICE.DayPartTargeting();
            dayPartTargeting.dayParts = lstDayParts;
            dayPartTargeting.timeZone = 'BROWSER';
            itemTargeting.dayPartTargeting = dayPartTargeting;
          }

          itemTargeting.technologyTargeting = technologyTargeting;
          if(listCrit.size()>0)
          {
              itemTargeting.customTargeting = listCrit.get(0);
          }
          
          //LineItem Size
          DART6_FORECASTSERVICE.Size itemSize = new DART6_FORECASTSERVICE.Size();
          itemSize.width = (('').equals(dartObjForecast.getAdSlotW())?0:Integer.valueOf(dartObjForecast.getAdSlotW()+''));
          itemSize.height = (('').equals(dartObjForecast.getAdSlotH())?0:Integer.valueOf(dartObjForecast.getAdSlotH()+''));
          itemSize.isAspectRatio = false;
          
          // CreativePlaceholder
          DART6_FORECASTSERVICE.CreativePlaceholder creativePlc = new DART6_FORECASTSERVICE.CreativePlaceholder();
          creativePlc.size = itemSize;
            
          DART6_FORECASTSERVICE.LineItem lineItem =  new DART6_FORECASTSERVICE.LineItem();
          //lineItem.lineItemType = 'STANDARD';
          //lineItem.costType = dartObjForecast.getBillingCat();
          //NK:12/03/2013
          
          //@Vitou 18-12-2014
          DART6_FORECASTSERVICE.Goal gl = new DART6_FORECASTSERVICE.Goal();
          lineItem.primaryGoal = gl;
          //18-12-2014
                    
          lineItem.lineItemType = (dartObjForecast.getBillingCat().equals(BILLING_CATE_FIX_PRICE) || dartObjForecast.getBillingCat().equals('CPD'))?'SPONSORSHIP':'STANDARD';
          lineItem.costType = dartObjForecast.getBillingCat().equals(BILLING_CATE_FIX_PRICE)?'CPD':dartObjForecast.getBillingCat();
        
          lineItem.startDateTime = dartTimexStart;
          lineItem.endDateTime = dartTimexEnd;
          lineItem.targeting = itemTargeting;
          lineItem.targetPlatform = dartObjForecast.getDartTargetPlatform();
          
          Date dtFc = date.newinstance(Integer.valueOf(dartObjForecast.getStartYear()+''), Integer.valueOf(dartObjForecast.getStartMonth()+''), Integer.valueOf(dartObjForecast.getStartDay()+''));
          // If line item start date is today then set StartDateTimeType to ONE_HOUR_FROM_NOW
          if(dtFc.isSameDay(System.today()))
          {
            lineItem.startDateTimeType = 'IMMEDIATELY';
          }
          
          
          if(!''.equals(dartObjForecast.getFCPeriodDart6()))
          {
            // FrequencyCap
            DART6_FORECASTSERVICE.FrequencyCap freqCap = new DART6_FORECASTSERVICE.FrequencyCap();
            freqCap.numTimeUnits = DARTUtil.toInteger(dartObjForecast.getFCAdServedEvery());
            freqCap.maxImpressions = DARTUtil.toInteger(dartObjForecast.getFCQty());
            freqCap.timeUnit = MAP_TIME_UNITS.get(dartObjForecast.getFCPeriodDart6()); 
          
            lineItem.frequencyCaps = new DART6_FORECASTSERVICE.FrequencyCap[]{freqCap};
          }
          lineItem.creativePlaceholders = new DART6_FORECASTSERVICE.CreativePlaceholder[]{creativePlc};

          try
          {
            forecast  =  forecastService.getForecast(lineItem);
            invokedMethod = 'getForecast';
            
            if(listCrit.size()>0) 
            {
              ctrl.updateDart6ValueIds();
            }
        
            
             if(ctrl.isCreateNewKv())
             {
                 ctrl.createObjectKeyVal();
             }
        
          }
          catch(System.CalloutException cex){
            throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
          }  
          catch(Exception ex){
            throw new ExceptionGroup.DARTException('' + ex.getMessage());
          }  
      }
    }
    
    
    
    
    public Object getResponseObject()
    {
      return forecast; 
      
    }
    
  }
  
  /**
   * Delivery Request
   * AdServer_Login__c login = DARTUtil.getCredential('DART5','UK');
   */  
  public class DeliveryRequest extends AbstractDFPRequest{
    private DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService;
    private Long reportjobId;
    private String xmlBody;
    private AdServer_Login__c credential;
    
    public DeliveryRequest(AdServer_Login__c credential, Long reportjobId, DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService){
      this.reportjobId = reportjobId;
      this.reportService = reportService;
      this.credential = credential;
    }
    
    /** 
    * Download report from url when running completed
    */  
    public void invoke(){ 
      DART6_REPORTSERVICE.ReportDownloadOptions reportOptions = new DART6_REPORTSERVICE.ReportDownloadOptions();
       reportOptions.exportFormat = 'XML';
          reportOptions.includeReportProperties = false;
          reportOptions.includeTotalsRow = false;
          reportOptions.useGzipCompression = false;
       String downloadUrl = reportService.getReportDownloadUrlWithOptions(reportjobId, reportOptions);
       HTTPWrapper.IRequest downloadxmlReq = new DART6Message.DART6ReportDownloadRequest(credential, downloadUrl);
      DART6Message.GenericResponse downloadxmlResponse = new DART6Message.GenericResponse(downloadxmlReq);
      xmlBody = downloadxmlResponse.getResBody(); 
      System.debug('>>>>>>>>>>>>>>> xmlBody:'+xmlBody);
    }

    /**
    * Get XML Boby for passer
    */ 
    public Object getResponseObject(){
      return xmlBody; 
    }
  }
  
  public class DART6ReportDownloadRequest extends AbstractDART6Request{
    
    public DART6ReportDownloadRequest(AdServer_Login__c credential, String url)
    {
      super(credential);
      endPoint = url;
      method = 'GET';
      mapHeader.put('Content-type', 'text/xml');
      
      constructBody();
    }
    protected override void composeHeader(){ }
    public override void constructBody(){}    
  }
  
  public class DART6TokenRequest extends AbstractDART6Request{
    
    public DART6TokenRequest(AdServer_Login__c credential)
    {
      super(credential);
      endPoint = DARTUtil.CLIENT_AUTH_URL;
      
      mapHeader.put('Content-type', 'application/x-www-form-urlencoded');
      
      constructBody();
    }
    
    public override void constructBody()
    {
      System.debug('>>>>>>>>>>>>> ' + credential.User_Name__c + '  ' + credential.Password__c);
      reqBody = 'service=gam&accountType=GOOGLE&' + 'Email=' + credential.User_Name__c + '&Passwd=' + credential.Password__c;
    }    
  }
  
  public abstract class AbstractDARTRequest implements HTTPWrapper.IGenericRequest{
        protected String invokedMethod = '';
        
        /** what dart method has been invoked */  
        public String getInvokedMethod()
        {
            return invokedMethod;
        }
    }
  
  /** ------------------------------------------------------------ */  
    public abstract class AbstractDART6Request extends AbstractDARTRequest implements HTTPWrapper.IRequest{
        protected Map<String,String> mapHeader;
        protected String reqBody  = '';
        protected String endPoint = '';
        protected String method   = 'POST'; 
        
        protected AdServer_Login__c credential;
        
        public AbstractDART6Request(AdServer_Login__c credential){
            this.credential = credential;
            endPoint = credential.Login_URL__c;
            mapHeader = new Map<String,String>();
            composeHeader();
        }
        
        protected virtual void composeHeader()
        {  
            mapHeader.put('Cookie','');
            mapHeader.put('Content-type','text/xml');
            mapHeader.put('Accept-Encoding','gzip, deflate');
            mapHeader.put('User-Agent','API_VERSION_DARTAPI_13.6.9 JRE_1.6.0_25');
            String authsss = DARTUtil.composeDigestAuthorizationHeader(credential.User_Name__c,credential.Password__c,'/xmlserver/','POST');
            mapHeader.put('Authorization',authsss);
        } 
        
        abstract void constructBody();
         
        public String getEndPoint()
        {
            return endPoint;
        }
        public Map<String,String> getHeader()
        {
            return mapHeader;
        }
        public String getBody()
        {
            return reqBody;
        }
        public String getMethod()
        {
            return method;
        }
        
    }
    
    /** ----------- DFP LineItem by statement Request ---------------- */  
    public class DFPLineItemPageRequest extends AbstractDFPRequest{
        
        DART6_LINEITEMSERVICE.LineItemPage lineItemPage;
        AdServer_Login__c login;
        String filterQuery;
        
        public DFPLineItemPageRequest(AdServer_Login__c credential, String fQuery){
          login = credential;
          filterQuery = fQuery;
        }
        
        public void invoke(){
            
         // String authToken = DARTUtil.getRequestToken(login.Name);  old Version
          String authToken = DARTUtil.getAccessToken(login); // new version 201411
          
          DART6_LINEITEMSERVICE.SoapRequestHeader header = new DART6_LINEITEMSERVICE.SoapRequestHeader();
          header.applicationName='LineItemService';
          header.networkCode=login.Network_ID__c;
          
          Map<String,String> inputHttpHeaders_x = new Map<String, String>();       // new version 201411 
          inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);            // new version 201411
          
          DART6_LINEITEMSERVICE.LineItemServiceInterfacePort request = new DART6_LINEITEMSERVICE.LineItemServiceInterfacePort();
          request.RequestHeader = header;
          request.inputHttpHeaders_x = inputHttpHeaders_x;     // new version 201411
          
          //Create filter for lastModifiedDateTime = today
          DART6_LINEITEMSERVICE.Statement filterStatement = new DART6_LINEITEMSERVICE.Statement();
          filterStatement.query = filterQuery;
          filterStatement.values = new List<DART6_LINEITEMSERVICE.String_ValueMapEntry>{new DART6_LINEITEMSERVICE.String_ValueMapEntry()};
          
          lineItemPage = request.getLineItemsByStatement(filterStatement);
          invokedMethod = 'getLineItemsByStatement';
          
        }
        
        public Object getResponseObject(){
          //return DFP object from invoke
          return lineItemPage;
        }
      }
  
  /** ------------------------------------------------------------ */  
    public class GenericResponse extends HTTPWrapper.AbstractResponse{
        
        public GenericResponse(IRequest req)
        {
            super(req);
            excecute();
        }
        public override String getMockedBody()
        {
          return DARTMockUp.generateDart5Response(request);
        }   
    }  
  
}