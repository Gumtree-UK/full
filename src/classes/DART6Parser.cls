/** All Parsers for new DFP
*/  
public with sharing class DART6Parser {
    
    public DART6Parser(){}
    
    public virtual interface IDartParser
    {
        void parse();
        List<DARTObject.IDARTGenericObject> getListDartObject();
    } 
    
    public interface IDART6Parser extends IDartParser 
    {
        void setObjectDFP(Object dfpObject);
    }
     
    /**
     * Company parser   
     */ 
    
    public class DFPResponseToCompanyParser implements IDART6Parser{
        
        List<DARTObject.IDARTObjectAdvertiser> lstDartCom;
        DART6_COMPANYSERVICE.Company com;
        Account acc;
        
        public DFPResponseToCompanyParser(Account acc)
        {
            this.acc = acc;
        }
        
        public void setObjectDFP(Object dfpObject)
        {
            this.com = (DART6_COMPANYSERVICE.Company)dfpObject;
        }
        
        public void parse()
        {
            lstDartCom = new List<DARTObject.IDARTObjectAdvertiser>();
            
            DARTObject.DARTAdvertiser drtAdv = new DARTObject.DARTAdvertiser(acc);
            drtAdv.setDartId(com.id+'');
            lstDartCom.add(drtAdv);
            
            
        } 
        
        public List<DARTObject.IDARTObject> getListDartObject()
        {
            return lstDartCom;
        }
        
    }
    
    
    //Parse DFP Order response from WSDL ivoked to our apex DARTObject[] 
    public class DFPResponseToOrderParser implements IDART6Parser{
        
        List<DARTObject.IDARTObjectOrder> listOrder;
        DART6_ORDERSERVICE.Order objOrder;
        Opportunity opp;
        AdServer_Login__c credential;
        
        // Constructor 
        public DFPResponseToOrderParser(Opportunity opp, AdServer_Login__c credential)
        {
              this.opp = opp; 
              this.credential = credential;
        }
        
        public void setObjectDFP(Object dfpObject)
        {   
            this.objOrder = (DART6_ORDERSERVICE.Order)dfpObject;
        }
        
        public void parse()
        {
            listOrder = new List<DARTObject.IDARTObjectOrder>();
            DARTObject.DARTOrder dartOrder = new DARTObject.DARTOrder(opp);
            dartOrder.setDartId(objOrder.id+'');
            dartOrder.setAdvertiserId(objOrder.advertiserId+'');
            dartOrder.setAssignAdserver(credential.Name+' ('+credential.User_Name__c+')');
            listOrder.add(dartOrder);
        }
        
        public List<DARTObject.IDARTObject> getListDartObject()
        {
            return listOrder;
        }
        
    }
    
    
    
    /**
     * Salesperson
     */
    public class DFPResponseToSalespersonParser implements IDART6Parser{
         
        List<DART6_USERSERVICE.User_x> objUsers;
        
        List<DARTObject.DARTPerson> listSalesperson;
        
        
        // Constructor 
        public DFPResponseToSalespersonParser()
        {
               
        }
        
        public void setObjectDFP(Object dfpObject)
        {
            this.objUsers  = (List<DART6_USERSERVICE.User_x>)dfpObject;
        }
        
        public void parse()
        {
            
            System.debug('-----------------> objUser: ' + objUsers);
            
            listSalesperson =  new List<DARTObject.DARTPerson>();
            
            for(DART6_USERSERVICE.User_x u: objUsers)
            {
                DARTObject.DARTPerson objSalesp = new DARTObject.DARTPerson();
                objSalesp.setDartId(u.id+'');
                objSalesp.setDartName(u.name);
                objSalesp.setUserEmail(u.email);
                listSalesperson.add(objSalesp);
            }
            
        }    
        
        public List<DARTObject.IDARTObject> getListDartObject()
        {
            
            return listSalesperson;
        } 
        
    }
    
    /**
     * Availability Forecast
     */
    public class DFPResponseToForecastParser implements IDART6Parser{

        List<DARTObject.DARTForecast> listForecast;
        DART6_FORECASTSERVICE.Forecast forecast;
        OpportunityLineItem item;
        
        /** Constructor */
        public DFPResponseToForecastParser(OpportunityLineItem item)
        {
            this.item = item;   
        }
        
        public void setObjectDFP(Object dfpObject)
        {
            this.forecast  = (DART6_FORECASTSERVICE.Forecast)dfpObject;
        }
        
        public void parse()
        {

            listForecast =  new List<DARTObject.DARTForecast>();
            DARTObject.DARTForecast objForecast = new DARTObject.DARTForecast(item);
            
            objForecast.setAvailableUnits(forecast.availableUnits==null?'':String.valueOf(forecast.availableUnits));
            objForecast.setMatchingUnits(forecast.matchedUnits==null?'':String.valueOf(forecast.matchedUnits));
            
            System.debug('---------------->forecast:'+forecast);
            
            listForecast.add(objForecast); 
             
        }    
        
        public List<DARTObject.DARTForecast> getListDartObject()
        {
            
            return listForecast;
        } 
        
    }
    
    
    /**
     * Ads parser
     */
     public class DFPResponseToAdsParser implements IDART6Parser{
        
        List<DARTObject.IDARTObject> lstDartObjects;
        List<DARTObject.DARTAds> lstAds;
        
        OpportunityLineItem item;
        AdServer_Login__c credential;
        Map<String, Advertiser__c> mapAdvertiser;
        
        DART6_LINEITEMSERVICE.LineItem lineItem;
        
        
        // Constructor
        public DFPResponseToAdsParser(OpportunityLineItem item, AdServer_Login__c credential, Map<String, Advertiser__c> mapAdvertiser)
        {
            this.item = item;
            this.credential = credential;
            this.mapAdvertiser = mapAdvertiser;
            
        }
        
        public void setObjectDFP(Object dfpObject)
        {
            this.lineItem  = (DART6_LINEITEMSERVICE.LineItem)dfpObject;
        }
        
        public void parse()
        {
            lstAds = new List<DARTObject.DARTAds>();
            String dartVer = item.PricebookEntry.Product2.RecordType.Name+'_'+item.PriceBookEntry.Product2.Site__r.Country__c;
            DARTObject.DARTAds objAds = new DARTObject.DARTAds(item);
            objAds.setDartId(lineItem.id+'');
            objAds.setOrder(new DARTObject.DARTOrder(lineItem.orderId+'', (mapAdvertiser.get(dartVer)!=null?mapAdvertiser.get(dartVer).Dart6_Advertiser_Id__c:'')));
            objAds.setAssignAdserver(credential.Name+' ('+credential.User_Name__c+')');
            lstAds.add(objAds);

        } 
        
        public List<DARTObject.IDARTObject> getListDartObject()
        {
            
            return lstAds;
        }
        
    }
    
     
    /**
     * Delivery parser, dart6 and dart5 are simlilar but to reduce script statement we need to create the new Parser
     */
    public class Xml6ToDeliveryParser implements IDART6Parser{
        
        protected List<DARTObject.IDARTGenericObject> listDeliveries; 
        protected String xmlRes;
        protected String sobjType;
        protected DartResponseMsg deliveryResponse;
        
        Integer[] gNums = new Integer[8];
        public Xml6ToDeliveryParser(String sobjType){
            if(sobjType == DeliveryController.SOBJECT_OPPPRODUCT){
                /* NK:02/04/2013: Obsoleted. switched to xmlNode
                dartXMLQueryResPattern ='<Row rowNum=\'.*?\'>'+
                '<Column name=\'orderId\'><Val>(.*?)</Val></Column>'+ 
                '<Column name=\'lineItemId\'><Val>(.*?)</Val></Column>'+ 
                '<Column name=\'lineitemLifetimeMergedImpressions\'><Val>(.*?)</Val></Column>'+ 
                '<Column name=\'lineitemLifetimeMergedClicks\'><Val>(.*?)</Val></Column>'+ 
                '<Column name=\'mergeLineItemDeliveryIndicator\'><Val>(.*?)</Val></Column>'+ 
                '</Row>';*/ 
                gNums[0] = 0; //orderId
                gNums[1] = 1; //lineItemId
                gNums[2] = 2; //lineitemLifetimeMergedImpressions
                gNums[3] = 3; //lineitemLifetimeMergedClicks
                gNums[4] = 4; //mergeLineItemDeliveryIndicator
                gNums[5] = 2; //lineitemLifetimeMergedImpressions
                gNums[6] = 3; //lineitemLifetimeMergedClicks
                gNums[7] = -1; //""
                
            }else if(sobjType == DeliveryController.SOBJECT_REV_SCH2_DAILY){
                /* NK:02/04/2013: Obsoleted. switched to xmlNode
                dartXMLQueryResPattern ='<Row rowNum=\'.*?\'>'+
                '<Column name=\'orderId\'><Val>(.*?)</Val></Column>'+ 
                '<Column name=\'lineItemId\'><Val>(.*?)</Val></Column>'+ 
                '<Column name=\'date\'><Val>(.*?)</Val></Column>'+ 
                '<Column name=\'mergeReservationImpressionsDelivered\'><Val>(.*?)</Val></Column>'+ 
                '<Column name=\'mergeLineItemDeliveryIndicator\'><Val>(.*?)</Val></Column>'+ 
                '<Column name=\'mergeReservationClicksDelivered\'><Val>(.*?)</Val></Column>'+ 
                '</Row>';*/
                /************** DFP version 201208***************/
                //gNums[0] = 0; //orderId
                //gNums[1] = 1; //lineItemId
                //gNums[2] = 3; //mergeReservationImpressionsDelivered
                //gNums[3] = 5; //mergeReservationClicksDelivered
                //gNums[4] = 4; //mergeLineItemDeliveryIndicator
                //gNums[5] = 3; //mergeReservationImpressionsDelivered
                //gNums[6] = 5; //mergeReservationClicksDelivered
                //gNums[7] = 2; //date
                /**************** DFP version 201311 **************/
                gNums[0] = 0; //orderId
                gNums[1] = 1; //lineItemId
                gNums[2] = 3; //mergeReservationImpressionsDelivered
                gNums[3] = 4; //mergeReservationClicksDelivered
                gNums[4] = 5; //mergeLineItemDeliveryIndicator
                gNums[5] = 3; //mergeReservationImpressionsDelivered
                gNums[6] = 4; //mergeReservationClicksDelivered
                gNums[7] = 2; //date
                
                
            }else if(sobjType == DeliveryController.SOBJECT_REV_SCH2){
                /* NK:02/04/2013: Obsoleted. switched to xmlNode
                dartXMLQueryResPattern ='<Row rowNum=\'.*?\'>'+
                '<Column name=\'orderId\'><Val>(.*?)</Val></Column>'+
                '<Column name=\'lineItemId\'><Val>(.*?)</Val></Column>'+
                '<Column name=\'month\'><Val>(.*?)</Val></Column>'+
                '<Column name=\'mergeReservationImpressionsDelivered\'><Val>(.*?)</Val></Column>'+
                '<Column name=\'mergeLineItemDeliveryIndicator\'><Val>(.*?)</Val></Column>'+
                '<Column name=\'mergeReservationClicksDelivered\'><Val>(.*?)</Val></Column>'+
                '</Row>';*/
                /*************** DFP version 201208 ******************/
                //gNums[0] = 0; //orderId
                //gNums[1] = 1; //lineItemId
                //gNums[2] = 3; //mergeReservationImpressionsDelivered
                //gNums[3] = 5; //mergeReservationClicksDelivered
                //gNums[4] = 4; //mergeLineItemDeliveryIndicator
                //gNums[5] = 3; //mergeReservationImpressionsDelivered
                //gNums[6] = 5; //mergeReservationClicksDelivered
                //gNums[7] = 2; //month
                /**
                
                /*************** DFP version 201311 ******************/
                gNums[0] = 0; //orderId
                gNums[1] = 1; //lineItemId
                gNums[2] = 3; //mergeReservationImpressionsDelivered
                gNums[3] = 4; //mergeReservationClicksDelivered
                gNums[4] = 5; //mergeLineItemDeliveryIndicator
                gNums[5] = 3; //mergeReservationImpressionsDelivered
                gNums[6] = 4; //mergeReservationClicksDelivered
                gNums[7] = 2; //month
                
            }
        } 
        
        private void doExtract()
        {
            //try{
                //System.debug('>>>>>>>>>>>>>>>>xmlRes 3/4/13 MM/DD/YY' + xmlRes);
                //Document dCov=new Document(Body=Blob.valueOf(xmlRes), Name='failedbody', Type=' Temporary Document', ContentType='txt',FolderId=Userinfo.getUserId());
                //insert dCov;
                //dCov = null; // same mem
            //}catch(Exception e){}

                 //Integer i = 0;
                 
            //DEL_FIELD_ADDELIVERED => lineitemLifetimeMergedImpressions, mergeReservationImpressionsDelivered, mergeReservationImpressionsDelivered 
            //DEL_FIELD_ADCLICKED_LIFETIME => lineitemLifetimeMergedClicks, mergeReservationClicksDelivered, mergeReservationClicksDelivered
            //DEL_FIELD_ADOSI => mergeLineItemDeliveryIndicator, mergeLineItemDeliveryIndicator, mergeLineItemDeliveryIndicator
            //DEL_FIELD_ADID => lineItemId, lineItemId, lineItemId
            //DEL_FIELD_ORDERID => orderId, orderId, orderId
            //DEL_FIELD_IMPRESS_DELIVERED => lineitemLifetimeMergedImpressions, mergeReservationImpressionsDelivered, mergeReservationImpressionsDelivered
            //DEL_FIELD_CLICKS_DELIVERED => lineitemLifetimeMergedClicks, mergeReservationClicksDelivered, mergeReservationClicksDelivered
            //DEL_FIELD_DATE_OR_MONTH => '', date, month
            //NK: 01/03/2013: for xml doc: regex is too limited. can process more than 2k rows           
            deliveryResponse.doc.getRootElement(); //Report-->ReportData-->DataSet-->Row-->Column
            DOM.XMLNode node = deliveryResponse.doc.getRootElement();
            try{
                    for(Dom.XMLNode child: node.getChildElements()){
                        if(child.getName().equals('ReportData')){
                            for(Dom.XMLNode child2: child.getChildElements()){
                                if(child2.getName().equals('DataSet')){
                                    for(Dom.XMLNode child3: child2.getChildElements()){
                                        if(child3.getName().equals('Row')) {
                                            listDeliveries.add( new DARTObject.DARTDelivery(
                                                new Map<Object,Object>
                                                        {
                                                            DARTObject.DEL_FIELD_ADDELIVERED => child3.getChildElements()[gNums[2]].getChildElements()[0].getText(),
                                                            DARTObject.DEL_FIELD_ADCLICKED_LIFETIME => child3.getChildElements()[gNums[3]].getChildElements()[0].getText(),
                                                            DARTObject.DEL_FIELD_ADOSI => child3.getChildElements()[gNums[4]].getChildElements()[0].getText(), 
                                                            DARTObject.DEL_FIELD_ADID => child3.getChildElements()[gNums[1]].getChildElements()[0].getText(),
                                                            DARTObject.DEL_FIELD_ORDERID => child3.getChildElements()[gNums[0]].getChildElements()[0].getText(),
                                                            DARTObject.DEL_FIELD_IMPRESS_DELIVERED => child3.getChildElements()[gNums[5]].getChildElements()[0].getText(),
                                                            DARTObject.DEL_FIELD_CLICKS_DELIVERED => child3.getChildElements()[gNums[6]].getChildElements()[0].getText(),
                                                            DARTObject.DEL_FIELD_DATE_OR_MONTH => gNums[7] == -1 ? '' : child3.getChildElements()[gNums[7]].getChildElements()[0].getText()
                                                        }
                                                )
                                            );
                                        }
                                    }
                                }
                            }
                        }
                    }   
                    node = null;  
            }catch(Exception ex){
                throw new ExceptionGroup.ParserException(ex.getMessage());
            }
        }
        
        public void parse()
        {
            listDeliveries = new  List<DARTObject.DARTDelivery>();
            deliveryResponse = new DartResponseMsg(xmlRes);
            
            String availImpress='';
            if(deliveryResponse.isError)
            {   
                throw new ExceptionGroup.DARTException(deliveryResponse.errMsg);
            }
            else
            {
                try{
                    doExtract();
                    deliveryResponse = null;
                 }catch(Exception ex)
                 {
                    throw new ExceptionGroup.ParserException(ex.getMessage());
                 }
            }
        }

        public List<DARTObject.IDARTGenericObject> getListDartObject()
        { 
            return  listDeliveries;
        } 
            
        public void setObjectDFP(Object dfpObject){xmlRes = dfpObject +'';}
    }
    
    
    /**
     * LineItem Page parser 
     */ 
    public class DFPResponseToLineItemParser implements IDART6Parser{
        
        List<DARTObject.DARTLineItemPage> lstDartLineItem;
        DART6_LINEITEMSERVICE.LineItemPage reslineItemPage;
        private Map<String, String> minuteToNumber = new Map<String, String>{
            'ZERO' => '00',
            'FIFTEEN' => '15',
            'THIRTY' => '30', 
            'FORTY_FIVE' => '45'
        };
        private List<String> fulldays = new List<String>{'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'}; 
        
        public DFPResponseToLineItemParser()
        {
        
        }
        
        public void setObjectDFP(Object dfpObject)
        {
            reslineItemPage = (DART6_LINEITEMSERVICE.LineItemPage) dfpObject;
        }
        
        public void parse()
        {
            lstDartLineItem = new List<DARTObject.DARTLineItemPage>();
            if(reslineItemPage.results == null) return;
            for(DART6_LINEITEMSERVICE.LineItem lineItem : reslineItemPage.results){
                
                DARTObject.DARTLineItemPage dartObj = new DARTObject.DARTLineItemPage();
                //Set OpportunityLineItem info
                dartObj.oppLineItem.Ad_Id__c = String.valueOf(lineItem.Id);
                dartObj.oppLineItem.From_Date__c = convertDateX(lineItem.startDateTime.date_x);
                dartObj.oppLineItem.Until_Date__c = convertDateX(lineItem.endDateTime.date_x);
                dartObj.oppLineItem.LastUpdatefromDFP__c = convertDateTimeX(lineItem.lastModifiedDateTime);
                dartObj.oppLineItem.Priority__c = lineItem.priority;
                dartObj.oppLineItem.FC_Quantity__c = null;
                dartObj.oppLineItem.FC_Ad_served_Every__c = null;
                dartObj.oppLineItem.FC_Period__c = null;
                if(lineItem.frequencyCaps != null){
                    dartObj.oppLineItem.FC_Quantity__c = lineItem.frequencyCaps[0].maxImpressions;
                    dartObj.oppLineItem.FC_Ad_served_Every__c = lineItem.frequencyCaps[0].numTimeUnits;
                    dartObj.oppLineItem.FC_Period__c = lineItem.frequencyCaps[0].timeUnit;
                }
                dartObj.oppLineItem.DFP_Time_Monday__c = null;
                dartObj.oppLineItem.DFP_Time_Tuesday__c = null;
                dartObj.oppLineItem.DFP_Time_Wednesday__c = null;
                dartObj.oppLineItem.DFP_Time_Thursday__c = null;
                dartObj.oppLineItem.DFP_Time_Friday__c = null;
                dartObj.oppLineItem.DFP_Time_Saturday__c = null;
                dartObj.oppLineItem.DFP_Time_Sunday__c = null;
                if(lineItem.targeting.dayPartTargeting != null){
                    for(DART6_LINEITEMSERVICE.DayPart daypart : lineItem.targeting.dayPartTargeting.dayParts){
                        String day = daypart.dayOfWeek;
                        Long hourStart = daypart.startTime.hour;
                        String minuteStart = daypart.startTime.minute;
                        Long hourEnd = daypart.endTime.hour;
                        String minuteEnd = daypart.endTime.minute;
                        String fieldName = 'DFP_Time_' + day + '__c';
                        dartObj.oppLineItem.put(fieldName, splitTimeToHours(hourStart, minuteStart, hourEnd, minuteEnd));
                    }
                }else{
                    Long hourStart = 0;
                    String minuteStart = 'ZERO';
                    Long hourEnd = 24;
                    String minuteEnd = 'ZERO';
                    for(String day : fulldays){
                        String fieldName = 'DFP_Time_' + day + '__c';
                        dartObj.oppLineItem.put(fieldName, splitTimeToHours(hourStart, minuteStart, hourEnd, minuteEnd));
                    }
                }
                
                dartObj.oppLineItem.AdOperatingSystems__c = '';
                if(lineItem.targeting.technologyTargeting != null && lineItem.targeting.technologyTargeting.operatingSystemTargeting != null && lineItem.targeting.technologyTargeting.operatingSystemTargeting.operatingSystems != null){
                    for(DART6_LINEITEMSERVICE.Technology technology : lineItem.targeting.technologyTargeting.operatingSystemTargeting.operatingSystems){
                        dartObj.oppLineItem.AdOperatingSystems__c += technology.name + '; ';
                    }
                    if(dartObj.oppLineItem.AdOperatingSystems__c != '') dartObj.oppLineItem.AdOperatingSystems__c = dartObj.oppLineItem.AdOperatingSystems__c.substring(0, dartObj.oppLineItem.AdOperatingSystems__c.length() - 2);
                }
                
                dartObj.oppLineItem.AdWebBrowsers__c = '';
                if(lineItem.targeting.technologyTargeting != null && lineItem.targeting.technologyTargeting.browserTargeting != null && lineItem.targeting.technologyTargeting.browserTargeting.browsers != null){
                    for(DART6_LINEITEMSERVICE.Technology technology : lineItem.targeting.technologyTargeting.browserTargeting.browsers){
                        dartObj.oppLineItem.AdWebBrowsers__c += technology.name + '; ';
                    }
                    if(dartObj.oppLineItem.AdWebBrowsers__c != '') dartObj.oppLineItem.AdWebBrowsers__c = dartObj.oppLineItem.AdWebBrowsers__c.substring(0, dartObj.oppLineItem.AdWebBrowsers__c.length() - 2);
                }
                
                //Populate Targeting data
                if(lineItem.targeting.geoTargeting != null && lineItem.targeting.geoTargeting.targetedLocations != null){
                    for(DART6_LINEITEMSERVICE.Location location : lineItem.targeting.geoTargeting.targetedLocations){
                        dartObj.lTargetingGeographyAssociation.add(new TargetingGeographyAssociation__c(TargetGeography__c=String.valueOf(location.id)));
                    }
                }
                if(lineItem.targeting.inventoryTargeting != null){
                    if(lineItem.targeting.inventoryTargeting.targetedAdUnits != null){
                        for(DART6_LINEITEMSERVICE.AdUnitTargeting adUnit : lineItem.targeting.inventoryTargeting.targetedAdUnits){
                            dartObj.lTargetingContentAssociation.add(new TargetingContentAssociation__c(Target_Content_Key__c = adUnit.adUnitId, Exclude__c = !adUnit.includeDescendants));
                        }
                    }
                    if(lineItem.targeting.inventoryTargeting.excludedAdUnits != null){
                        for(DART6_LINEITEMSERVICE.AdUnitTargeting adUnit : lineItem.targeting.inventoryTargeting.excludedAdUnits){
                            dartObj.lTargetingContentAssociation.add(new TargetingContentAssociation__c(Target_Content_Key__c = adUnit.adUnitId, Exclude__c = !adUnit.includeDescendants));
                        }
                    }
                    if (lineItem.targeting.inventoryTargeting.targetedPlacementIds != null){
                        for(Long placementId : lineItem.targeting.inventoryTargeting.targetedPlacementIds){
                            dartObj.lTargetingContentAssociation.add(new TargetingContentAssociation__c(Target_Content_Key__c = String.valueOf(placementId)));
                        }
                    }
                }
                
                if(lineItem.targeting.technologyTargeting != null){
                	// BandwidthGroup
                	if(lineItem.targeting.technologyTargeting.bandwidthGroupTargeting != null){
                		for(DART6_LINEITEMSERVICE.Technology technology : lineItem.targeting.technologyTargeting.bandwidthGroupTargeting.bandwidthGroups)
                		{
                			dartObj.lTargetingConnectionAssociation.add(new TargetingConnectionAssociation__c(TargetConnection__c = String.valueOf(technology.id)));
                		}
                	}
                	// MobileCarrier
                	if(lineItem.targeting.technologyTargeting.mobileCarrierTargeting != null){
                		for(DART6_LINEITEMSERVICE.Technology technology : lineItem.targeting.technologyTargeting.mobileCarrierTargeting.mobileCarriers)
                		{
                			dartObj.lTargetingConnectionAssociation.add(new TargetingConnectionAssociation__c(TargetConnection__c = String.valueOf(technology.id)));
                		}
                	}
                	// Browser
                	if(lineItem.targeting.technologyTargeting.browserTargeting != null)
                	{
                		for(DART6_LINEITEMSERVICE.Technology technology : lineItem.targeting.technologyTargeting.browserTargeting.browsers)
                		{
                			dartObj.lTargetingDeviceAssociation.add(new TargetingDeviceAssociation__c(TargetDevice__c = String.valueOf(technology.id)));
                		}
                	}
                	// BrowserLanguage
                	if(lineItem.targeting.technologyTargeting.browserLanguageTargeting != null)
                	{
                		for(DART6_LINEITEMSERVICE.Technology technology : lineItem.targeting.technologyTargeting.browserLanguageTargeting.browserLanguages)
                		{
                			dartObj.lTargetingDeviceAssociation.add(new TargetingDeviceAssociation__c(TargetDevice__c = String.valueOf(technology.id)));
                		}
                	}
                	// Device capability
                	if(lineItem.targeting.technologyTargeting.deviceCapabilityTargeting != null)
                	{
                		for(DART6_LINEITEMSERVICE.Technology technology : lineItem.targeting.technologyTargeting.deviceCapabilityTargeting.targetedDeviceCapabilities)
                		{
                			dartObj.lTargetingDeviceAssociation.add(new TargetingDeviceAssociation__c(TargetDevice__c = String.valueOf(technology.id)));
                		}
                	}
                	// Device category
                	if(lineItem.targeting.technologyTargeting.deviceCategoryTargeting != null)
                	{
                		for(DART6_LINEITEMSERVICE.Technology technology : lineItem.targeting.technologyTargeting.deviceCategoryTargeting.targetedDeviceCategories)
                		{
                			dartObj.lTargetingDeviceAssociation.add(new TargetingDeviceAssociation__c(TargetDevice__c = String.valueOf(technology.id)));
                		}
                	}
                	// Manufacturer/device
                	if(lineItem.targeting.technologyTargeting.deviceManufacturerTargeting != null)
                	{
                		for(DART6_LINEITEMSERVICE.Technology technology : lineItem.targeting.technologyTargeting.deviceManufacturerTargeting.deviceManufacturers)
                		{
                			dartObj.lTargetingDeviceAssociation.add(new TargetingDeviceAssociation__c(TargetDevice__c = String.valueOf(technology.id)));
                		}
                	}
                	//Operating system
                	if(lineItem.targeting.technologyTargeting.operatingSystemTargeting != null)
                	{
                		for(DART6_LINEITEMSERVICE.Technology technology : lineItem.targeting.technologyTargeting.operatingSystemTargeting.operatingSystems)
                		{
                			dartObj.lTargetingDeviceAssociation.add(new TargetingDeviceAssociation__c(TargetDevice__c = String.valueOf(technology.id)));
                		}
                	}
                	//Operating system version
                	if(lineItem.targeting.technologyTargeting.operatingSystemVersionTargeting != null)
                	{
                		for(DART6_LINEITEMSERVICE.Technology technology : lineItem.targeting.technologyTargeting.operatingSystemVersionTargeting.targetedOperatingSystemVersions)
                		{
                			dartObj.lTargetingDeviceAssociation.add(new TargetingDeviceAssociation__c(TargetDevice__c = String.valueOf(technology.id)));
                		}
                	}
                	
                	//Mobile device
                	if(lineItem.targeting.technologyTargeting.mobileDeviceTargeting != null)
                	{
                		for(DART6_LINEITEMSERVICE.Technology technology : lineItem.targeting.technologyTargeting.mobileDeviceTargeting.targetedMobileDevices)
                		{
                			dartObj.lTargetingDeviceAssociation.add(new TargetingDeviceAssociation__c(TargetDevice__c = String.valueOf(technology.id)));
                		}
                	}
                	
                	//Mobile device submodels
                	if(lineItem.targeting.technologyTargeting.mobileDeviceSubmodelTargeting != null)
                	{
                		for(DART6_LINEITEMSERVICE.Technology technology : lineItem.targeting.technologyTargeting.mobileDeviceSubmodelTargeting.targetedMobileDeviceSubmodels)
                		{
                			dartObj.lTargetingDeviceAssociation.add(new TargetingDeviceAssociation__c(TargetDevice__c = String.valueOf(technology.id)));
                		}
                	}
                	
                	    	
                }
                
                /*
                String debugText = '';
                if(lineItem.targeting.customTargeting != null){
                    DART6_FORECASTSERVICE.CustomCriteriaSet ccs = lineItem.targeting.customTargeting;
                    debugText += 'level 1 \n';
                    debugText += 'ccs.type_x = ' + ccs.type_x  +  '\n';
                    debugText += 'ccs.logicalOperator = ' + ccs.logicalOperator  +  '\n';
                    debugText += 'ccs.audienceSegmentIds = ' + ccs.audienceSegmentIds  +  '\n';
                    debugText += 'ccs.logicalOperator = ' + ccs.logicalOperator  +  '\n';
                    debugText += 'ccs.type_x = ' + ccs.type_x  +  '\n';
                    debugText += 'ccs.keyId = ' + ccs.keyId  +  '\n';
                    debugText += 'ccs.valueIds = ' + ccs.valueIds  +  '\n';
                    debugText += 'ccs.operator = ' + ccs.operator  +  '\n';
                    debugText += 'ccs.CustomCriteriaNode_Type = ' + ccs.CustomCriteriaNode_Type  +  '\n';
                    if(ccs.children == null) continue;
                    for(DART6_FORECASTSERVICE.CustomCriteriaNode node : ccs.children){
                        debugText += 'level 2 \n';
                        debugText += 'node.audienceSegmentIds = ' + node.audienceSegmentIds  +  '\n';
                        debugText += 'node.logicalOperator = ' + node.logicalOperator  +  '\n';
                        debugText += 'node.type_x = ' + node.type_x  +  '\n';
                        debugText += 'node.keyId = ' + node.keyId  +  '\n';
                        debugText += 'node.valueIds = ' + node.valueIds  +  '\n';
                        debugText += 'node.operator = ' + node.operator  +  '\n';
                        debugText += 'node.CustomCriteriaNode_Type = ' + node.CustomCriteriaNode_Type  +  '\n';
                        
                        if(node.children == null) continue;
                        for(DART6_FORECASTSERVICE.CustomCriteriaNode node2 : node.children){
                            debugText += 'level 3 \n';
                            debugText += 'node.audienceSegmentIds = ' + node2.audienceSegmentIds  +  '\n';
                            debugText += 'node.logicalOperator = ' + node2.logicalOperator  +  '\n';
                            debugText += 'node.type_x = ' + node2.type_x  +  '\n';
                            debugText += 'node.keyId = ' + node2.keyId  +  '\n';
                            debugText += 'node.valueIds = ' + node2.valueIds  +  '\n';
                            debugText += 'node.operator = ' + node2.operator  +  '\n';
                            debugText += 'node.CustomCriteriaNode_Type = ' + node2.CustomCriteriaNode_Type  +  '\n';
                            if(node2.children == null) continue;
                            for(DART6_FORECASTSERVICE.CustomCriteriaNode node3 : node2.children){
                                debugText += 'level 4 \n';
                                debugText += 'node.audienceSegmentIds = ' + node3.audienceSegmentIds  +  '\n';
                                debugText += 'node.logicalOperator = ' + node3.logicalOperator  +  '\n';
                                debugText += 'node.type_x = ' + node3.type_x  +  '\n';
                                debugText += 'node.keyId = ' + node3.keyId  +  '\n';
                                debugText += 'node.valueIds = ' + node3.valueIds  +  '\n';
                                debugText += 'node.operator = ' + node3.operator  +  '\n';
                                debugText += 'node.CustomCriteriaNode_Type = ' + node3.CustomCriteriaNode_Type  +  '\n';
                                if(node3.children == null) continue;
                                for(DART6_FORECASTSERVICE.CustomCriteriaNode node4 : node3.children){
                                    debugText += 'level 5 \n';
                                    debugText += 'node.audienceSegmentIds = ' + node4.audienceSegmentIds  +  '\n';
                                    debugText += 'node.logicalOperator = ' + node4.logicalOperator  +  '\n';
                                    debugText += 'node.type_x = ' + node4.type_x  +  '\n';
                                    debugText += 'node.keyId = ' + node4.keyId  +  '\n';
                                    debugText += 'node.valueIds = ' + node4.valueIds  +  '\n';
                                    debugText += 'node.operator = ' + node4.operator  +  '\n';
                                    debugText += 'node.CustomCriteriaNode_Type = ' + node4.CustomCriteriaNode_Type  +  '\n';
                                }
                            }
                        }
                    }
                }
                insert new Document(Name='TestTime', Body=Blob.valueOf(debugText), FolderId=UserInfo.getUserId());*/
                
                if(lineItem.targeting.customTargeting != null){
                    dartObj.customCriteriaSet = lineItem.targeting.customTargeting;
                    DART6_FORECASTSERVICE.CustomCriteriaSet ccs = dartObj.customCriteriaSet;
                    if(ccs.children == null) continue;
                    for(DART6_FORECASTSERVICE.CustomCriteriaNode node : ccs.children){
                        if(node.children == null) continue;
                        for(DART6_FORECASTSERVICE.CustomCriteriaNode node2 : node.children){
                            if(node2.valueIds != null){
                                dartObj.lTargetingKeyValueAssociation.add(new TargetingKeyValueAssociation__c(Operator__c = node2.operator, targetkeyvalue__c = String.valueOf(node2.keyId)));
                                for(Long valueId : node2.valueIds ){
                                    dartObj.lTargetingKeyValueAssociation.add(new TargetingKeyValueAssociation__c(Operator__c = 'OR', targetkeyvalue__c = String.valueOf(valueId)));
                                }
                            }
                            if(node2.audienceSegmentIds != null){
                                for(Long audSegId : node2.audienceSegmentIds ){
                                    dartObj.lTargetingKeyValueAssociation.add(new TargetingKeyValueAssociation__c(Operator__c = node2.operator, targetkeyvalue__c = String.valueOf(audSegId)));
                                }
                            }
                        }
                    }
                }
                lstDartLineItem.add(dartObj);
            }
        }
        
        public List<DARTObject.IDARTGenericObject> getListDartObject()
        {
            return lstDartLineItem;
        }
        
        private String splitTimeToHours(Long startHour, String startMin, Long endHour, String endMin){
            String finalVal = '';
            while(startHour < endHour){
                finalVal +=  startHour + ':' + minuteToNumber.get(startMin) + ' - ' + startHour + ':59' + ';';
                startHour++;
            }
            return finalVal;
        }
        
        private Date convertDateX(DART6_LINEITEMSERVICE.Date_x date_x){
            return Date.newInstance(date_x.year, date_x.month, date_x.day);
        }
      
        private DateTime convertDateTimeX(DART6_LINEITEMSERVICE.DateTime_x datetime_x){
            return DateTime.newInstance(datetime_x.date_x.year, datetime_x.date_x.month, datetime_x.date_x.day, datetime_x.hour, datetime_x.minute, datetime_x.second);
        }
    }
    
    /** prepare the dart5 response message */
    public class DartResponseMsg{
        public Boolean isError {get;set;}
        public DOM.Document doc {get;set;}
        public String errMsg;

        /** constructor */
        public DartResponseMsg(String xmlRes)
        {       
            isError = false;
            doc = new DOM.Document();
            doc.load(xmlRes);    
            DOM.XMLNode node = doc.getRootElement();
            
            if(node.getName().equals('Errors'))
            {
                isError = true;
                errMsg = getStringErrors(node);
            } 
        }
        private String getStringErrors(DOM.XMLNode node) 
        {
              String result = '';
              if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) 
              {
                    if (node.getAttributeCount() > 0) 
                    { 
                        for (Integer i = 0; i< node.getAttributeCount(); i++ ) 
                        {
                            if(node.getAttributeKeyAt(i).equals('message'))
                            {   
                                result +=  node.getName() + '<br/>' +node.getAttribute('message', null)+ '<br/>';
                            }
                        }
                    }
                    for (Dom.XMLNode child: node.getChildElements()) 
                    {
                        result += getStringErrors(child);
                    }
                    return result;
              }
          return '';  //should never reach here
        
        }
        
    }
    
}