/**
   Batch process of Booking
   Created Date: 29-01-2013
   
Change log:
- 2013-04-16 - GTCRM-169 - Auto copy adops@gumtree.com in to email
- 2014-07-04 - GTCRM-1012 - Opportunity Account Record type to be submitted to Sales team custom field
 */ 

global class BatchDARTBookingProcess extends BatchAvailabilityForecastProcess implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallOuts{
    
    
    // Mapping dartVersion and order in a network
    Map<String, DARTObject.IDARTObjectOrder> mapNetworkOrder;
    
    // Store Log message for all requests even error or success.
    public List<DARTLogger.LogMessage> lstLogMsg = new List<DARTLogger.LogMessage>();
    
    // Store all ads/lineItems request success
    List<DARTObject.IDARTObjectAds> lstAllAdsSuccess = new List<DARTObject.IDARTObjectAds>();
    // Store all ads/lineItems request failure
    List<DARTObject.IDARTObjectAds> lstAllAdsError = new List<DARTObject.IDARTObjectAds>();
    
    // Store all orders request success
    List<DARTObject.IDARTObjectOrder> lstAllOrderSuccess = new List<DARTObject.IDARTObjectOrder>();
    // Store all Orders request failure
    List<DARTObject.IDARTObjectOrder> lstAllOrderError = new List<DARTObject.IDARTObjectOrder>();
    
    // Store list Advertiser/Company (DART)
    List<DARTObject.IDARTObjectAdvertiser> lstDartAdvertiser = new List<DARTObject.IDARTObjectAdvertiser>();
    
    // Message error when upadate opporturnity failed.
    String msgFailureUpdateOpp='';
    // Message error when update opportunityLineItem failed.
    String msgFailureUpdateOppItem='';
    // Booking emailTemplate
    public final String TEMPLETE_NAME = 'BookingEmailTemplate';
    // Store Order request failure in different network
    Map<String, String> mapOrderErr;
    // Store list Advertiser/Company(SF) 
    List<Advertiser__c> listAdvertiser;
    
    //public Map<String, String> mapAdvertiser;
    Map<String, Advertiser__c> mapAdvertiser;
    
    List<OpportunityLineItem> listItems;
    
    /* Controller1: No/All LineItems selected */
    public BatchDARTBookingProcess(String oppId)
    {  
        super(oppId);
        
    }
    
    /* Controller2: Some of LineItems selected */
    public BatchDARTBookingProcess(String oppId, Set<String> lineItemIds)
    {
        super(oppId, lineItemIds);
    }
    
    public override String getDefaultWhere()
    {
        return  ' WHERE OpportunityId=%1 AND PricebookEntry.Product2.RecordType.Name IN (%2) '+
        ' And Im_AdServer_buchen__c=True';
    }
    
    /* Start batch */ 
    global override Database.QueryLocator start(Database.BatchableContext BC)
    {
        mapAdvertiser = new Map<String, Advertiser__c>();
        mapOrderErr = new Map<String, String>();
        mapNetworkOrder = new Map<String, DARTObject.DARTOrder>();
        listItems = new List<OpportunityLineItem>();
        for(OpportunityLineItem item: [select id,Adserver_ID_Order_ID__c, AdServer_ID__c ,PriceBookEntry.Product2.Site__r.Country__c,PricebookEntry.Product2.RecordType.Name From OpportunityLineItem where opportunityId =: oppId])
        {
            if(item.Adserver_ID_Order_ID__c != null && item.AdServer_ID__c != null)
            {
                DARTObject.DARTOrder ord = new DARTObject.DARTOrder(item.Adserver_ID_Order_ID__c, item.AdServer_ID__c);
                mapNetworkOrder.put(item.PricebookEntry.Product2.RecordType.Name+'_'+item.PriceBookEntry.Product2.Site__r.Country__c,ord);
            }
        }
// 2014-07-04 - GTCRM-1012 - Opportunity Account Record type to be submitted to Sales team custom field
        opp = [Select id, Name, P_O_Number__c, Campaign_Start__c, Campaign_End__c, Owner.Name, Owner.id, Owner.Email, Owner.Division, Opportunity.Account.RecordType.Name,
                Agency__c, AccountId, Campaign_Name__c From Opportunity Where id =: oppId];
            
        
        // Find Advertiser
        listAdvertiser = DARTUtil.getAdvertiser(opp.AccountId, opp.Agency__c);
        for(Advertiser__c adv : listAdvertiser)
        {
            if(adv.Dart6_Advertiser_Id__c != null){
                mapAdvertiser.put(DARTUtil.DART6+'_'+adv.AdServer_Login_Name__c, adv);  
            }
        }        
        System.debug('\n\n=========================> mapAdvertiser: ' + mapAdvertiser);
        System.debug('\n\n=========================> mapNetworkOrder: ' + mapNetworkOrder);
                
        return Database.getQueryLocator(soqlItems);
    }
    
    /* Execute batch */ 
    global override void execute(Database.BatchableContext BC, List<sObject> scope)
    {   
        
       
        String dartMethod;
        for(Sobject sobj : scope)
        {
            OpportunityLineItem oppItem;
            String dartVerCountry;
            

            DARTBookingController bookingCon;

            try{
                oppItem = (OpportunityLineItem)sobj; 
                listItems.add(oppItem);
                bookingCon = new DARTBookingController(opp, oppItem); 
                dartVerCountry = oppItem.PricebookEntry.Product2.RecordType.Name+'_'+oppItem.PriceBookEntry.Product2.Site__r.Country__c;
            }
            catch(Exception ex){if(mapOrderErr.get(dartVerCountry) == null){DARTObject.IDARTObjectOrder orderErr = new DARTObject.DARTOrder(opp);orderErr.setDartErrMsg(ex.getMessage());lstAllOrderError.add(orderErr);mapOrderErr.put(dartVerCountry, 'Error');}break;}
            
            // Advertiser not null 
            //  => If Product recordType=DART6 && Advertiser__c.Dart6_Advertiser_Id__c==null
            //     -> Request to create Advertiser in DFP 6
            //     -> Update field in SF
            // Advertiser = null
            //  => Request to create new Advertiser depend on product recordType
            //  => Create new Advertiser in SF
            
            String dartType = oppItem.PricebookEntry.Product2.RecordType.Name;
            //String prdCountryName = oppItem.PriceBookEntry.Product2.Site__r.Country__c;

                
                        
                    if(mapAdvertiser.get(dartVerCountry) == null)
                    {
                        try{
                            bookingCon.requestCreateAdvertiser();
                            lstDartAdvertiser = bookingCon.getListAdvertiser();
                            Advertiser__c adv = new Advertiser__c();
                            
                            if(dartType.equals(DARTUtil.DART6))
                            {
                                adv.Dart6_Advertiser_Id__c = lstDartAdvertiser.get(0).getDartId();
                            }
                            mapAdvertiser.put(dartVerCountry, adv);
                            
                        }
                        catch(Exception ex){DARTObject.IDARTObjectOrder orderErr = new DARTObject.DARTOrder(opp);orderErr.setDartErrMsg(ex.getMessage());lstAllOrderError.add(orderErr);DARTLogger.LogMessage logMsg = new DARTLogger.LogMessage('' ,DARTLogger.OPPERATION_SUBMIT_COMPANY_ADVERTISER,'',oppItem.PricebookEntry.Product2.RecordType.Name,ex);lstLogMsg.add(logMsg);break;}
                    } 
                if(mapNetworkOrder.get(dartVerCountry) == null) //In each network one order is created
                {
                    List<DARTObject.IDARTObjectOrder> listOrder;
                    try
                        {
                            // Order Request
                            bookingCon.processAndSendOrder(mapAdvertiser); 
                            dartMethod = bookingCon.getInvokedMethod(); 
                            listOrder = bookingCon.getListOrder();
                            lstAllOrderSuccess.addAll(listOrder);
                            
                            // Log messages when Order request success 
                            DARTLogger.LogMessage logMsgOrder = new DARTLogger.LogMessage(
                                                    opp.Id ,DARTLogger.OPPERATION_SUBMIT_ORDER,
                                                    dartMethod,oppItem.PricebookEntry.Product2.RecordType.Name,
                                                    DARTLogger.TYPE_SUCCESS, '', '');
                            
                            lstLogMsg.add(logMsgOrder);
                            mapNetworkOrder.put(dartVerCountry, listOrder.get(0));
                         
                        }// Request Order Error
                        catch(Exception ex){if(mapOrderErr.get(dartVerCountry) == null){DARTObject.IDARTObjectOrder orderErr = new DARTObject.DARTOrder(opp);orderErr.setDartErrMsg(ex.getMessage());lstAllOrderError.add(orderErr);mapOrderErr.put(dartVerCountry, 'Error');}DARTLogger.LogMessage logMsg = new DARTLogger.LogMessage(oppItem.Id ,DARTLogger.OPPERATION_SUBMIT_ORDER,'',oppItem.PricebookEntry.Product2.RecordType.Name,ex);lstLogMsg.add(logMsg); break;}
                        
                        if(listOrder != null)
                        {
                            try
                            {
                                // Ads/LineItem Request
                                bookingCon.processAndSendLineItem(listOrder.get(0), mapAdvertiser);
                                dartMethod = bookingCon.getInvokedMethod();
                                lstAllAdsSuccess.addAll(bookingCon.getListAds()); 
                                
                                // Log messages when Ads request success 
                                DARTLogger.LogMessage logMsgAds = new DARTLogger.LogMessage(
                                                            oppItem.Id ,DARTLogger.OPPERATION_SUBMIT_ADS,
                                                            dartMethod,oppItem.PricebookEntry.Product2.RecordType.Name,
                                                            DARTLogger.TYPE_SUCCESS, '', '');
                                    
                                lstLogMsg.add(logMsgAds);
                            }
                            catch(Exception ex){DARTObject.DARTAds adsErr = new DARTObject.DARTAds(oppItem);adsErr.setDartErrMsg(ex.getMessage());lstAllAdsError.add(adsErr);DARTLogger.LogMessage logMsg = new DARTLogger.LogMessage(oppItem.Id ,DARTLogger.OPPERATION_SUBMIT_ADS,'',oppItem.PricebookEntry.Product2.RecordType.Name,ex);lstLogMsg.add(logMsg);}
                        }
                    } 
                else 
                {
                    try
                    {
                        bookingCon.processAndSendLineItem(mapNetworkOrder.get(dartVerCountry), mapAdvertiser); 
                        dartMethod = bookingCon.getInvokedMethod();
                        lstAllAdsSuccess.addAll(bookingCon.getListAds());
                        
                        // Log messages when request Ads success 
                        DARTLogger.LogMessage logMsg = new DARTLogger.LogMessage(
                                                oppItem.Id ,DARTLogger.OPPERATION_SUBMIT_ADS,
                                                dartMethod,oppItem.PricebookEntry.Product2.RecordType.Name,
                                                DARTLogger.TYPE_SUCCESS, '', '');
                    
                        lstLogMsg.add(logMsg);
                        
                    }
                    catch(Exception ex){DARTObject.DARTAds adsErr = new DARTObject.DARTAds(oppItem);adsErr.setDartErrMsg(ex.getMessage());lstAllAdsError.add(adsErr);DARTLogger.LogMessage logMsg = new DARTLogger.LogMessage(oppItem.Id ,DARTLogger.OPPERATION_SUBMIT_ADS,'',oppItem.PricebookEntry.Product2.RecordType.Name,ex);lstLogMsg.add(logMsg);}
                }
                    
                    
            }   
            

    }
    
    /** Finish batch:
        - Send Email to opp's owner
        - Update opportunity
        - Update OpporutunityLineItem 
     */
    global override void finish(Database.BatchableContext BC)
    {
        List<DARTObject.IDARTObjectOrder> lstAllOrder = new List<DARTObject.IDARTObjectOrder>();
        lstAllOrder.addAll(lstAllOrderSuccess);
        lstAllOrder.addAll(lstAllOrderError);
        
        List<DARTObject.IDARTObjectAds> lstAllAds = new List<DARTObject.IDARTObjectAds>();
        lstAllAds.addAll(lstAllAdsError);
        lstAllAds.addAll(lstAllAdsSuccess);
        System.debug('lstAllAds: >>>>>>>>>>>' + lstAllAds);
        
        try{
            
            //List<Advertiser__c> lstAdvToUpsert = new List<Advertiser__c>();
            Map<String, Advertiser__c> mapAdverUpsert = new Map<String, Advertiser__c>();
            
            String strUpdInsAdv='';
            
            System.debug('\n\n\n====================> mapAdvertiser: ' + mapAdvertiser);
            
            
            for(String str:mapAdvertiser.keySet())
            {
                
                for(OpportunityLineItem item: listItems)
                {
                    String dartVerNetwork=item.PricebookEntry.Product2.RecordType.Name+'_'+item.PriceBookEntry.Product2.Site__r.Country__c;

                    if(str.equals(dartVerNetwork))
                    {
                        Advertiser__c advToUpsert;
                        Advertiser__c adv = mapAdvertiser.get(str);
                        if(adv.Id==null)
                        {
                            strUpdInsAdv= DARTLogger.OPPERATION_CREATE_NEW_ADVERTISER;
                            advToUpsert = new Advertiser__c();
                            advToUpsert.Account__c=opp.AccountId;
                            advToUpsert.Agency__c=opp.Agency__c;
                            advToUpsert.AdServer_Login_Name__c = item.PriceBookEntry.Product2.Site__r.Country__c;
                        }else{
                            strUpdInsAdv=DARTLogger.OPPERATION_UPDATE_ADVERTISER;
                            advToUpsert = new Advertiser__c(id=adv.Id);
                        }
                        
                        if((item.PricebookEntry.Product2.RecordType.Name).equals(DARTUtil.DART6)){
                            advToUpsert.Dart6_Advertiser_Id__c = adv.Dart6_Advertiser_Id__c;
                        }
                        System.debug('----------------> advToUpdate: '+ advToUpsert);
                        
                        //lstAdvToUpsert.add(advToUpsert);
                        mapAdverUpsert.put(str,advToUpsert);
                    }
                }
                
            }
            
            System.debug('\n\n\n====================> mapAdverUpsert: ' + mapAdverUpsert);
            
            
            upsert mapAdverUpsert.values();
            
            // Add log messages
            for(Advertiser__c adv:mapAdverUpsert.values()){
                
                DARTLogger.LogMessage logMsgUpInAdv = new DARTLogger.LogMessage(
                                    adv.id ,'Create/Update Advertiser',
                                    '','',
                                    DARTLogger.TYPE_SUCCESS, '', '');
                             
                            lstLogMsg.add(logMsgUpInAdv);
            }
            
        }catch(Exception ex){DARTLogger.LogMessage logMsg = new DARTLogger.LogMessage('' ,'Update/Insert Advertiser','','',ex);lstLogMsg.add(logMsg);}
        
        
        // Update lineItem (Feild: Adserver_ID_Order_ID__c, AdServer_ID__c)
        if(!mapNetworkOrder.isEmpty())
        {
             BatchAutoRenewal.fromBatch=true;
            List<OpportunityLineItem> lstOppItemToupdateFldOrderID = new List<OpportunityLineItem>();
            for(String ordKey : mapNetworkOrder.keySet())
            {
                //OpportunityLineItem itemupdate;
                for(OpportunityLineItem item: listItems)
                {
                    String networkType = item.PricebookEntry.Product2.RecordType.Name+'_'+item.PriceBookEntry.Product2.Site__r.Country__c;
                    if(networkType.equals(ordKey))
                    {
                        DARTObject.IDARTObjectOrder ord = mapNetworkOrder.get(networkType);
                        item.Adserver_ID_Order_ID__c = (ord==null?'':ord.getDartId());
                        item.AdServer_ID__c = (ord==null?'':ord.getOrderAvertiserId());  
                        lstOppItemToupdateFldOrderID.add(item);
                    }   
                }
            }
            
            update lstOppItemToupdateFldOrderID;
             
        }
        
        // Update opportunityLineItem (Field: Ad_Id__c)
        if(!lstAllAds.isEmpty())    
        {
            
            List<OpportunityLineItem> listOppItemToUpdate = new List<OpportunityLineItem>();
            for(DARTObject.IDARTObjectAds ads : lstAllAds)
            {
                 
                OpportunityLineItem oppItem = new OpportunityLineItem(Id=ads.getOppItemID());
                //DARTObject.IDARTObjectOrder ord = ads.getOrder();
                if(ads.getDartId() != null)
                {
                    //oppItem.Adserver_ID_Order_ID__c = (ord==null?'':ord.getDartId());
                    //if(ord!=null && ord.getOrderAvertiserId()!=null)
                    //{
                    //oppItem.AdServer_ID__c = (ord==null?'':ord.getOrderAvertiserId());    
                    //}
                    System.debug('ad id : >>>>>>>>>> ' + ads.getDartId());
                    oppItem.Ad_Id__c = ads.getDartId();
                    listOppItemToUpdate.add(oppItem); 
                }
            }
             
            DARTLogger.LogMessage logMsgUpdateoppItem;
            
            try
            {
                Database.SaveResult[] results = Database.Update(listOppItemToUpdate, false);
                // Log messages when update oppItem successfully  
                logMsgUpdateoppItem = new DARTLogger.LogMessage(
                                        opp.Id ,DARTLogger.OPPERATION_UPDATE_OPPLINEITEM,
                                        '','',
                                        DARTLogger.TYPE_SUCCESS, '', '');
                
                lstLogMsg.add(logMsgUpdateoppItem);
                
            }
           
            // Log messages when failure to update oppItem  
            catch(Exception ex){logMsgUpdateoppItem = new DARTLogger.LogMessage(opp.Id ,DARTLogger.OPPERATION_UPDATE_OPPLINEITEM,'','',DARTLogger.TYPE_ERROR, ex.getMessage(), '');lstLogMsg.add(logMsgUpdateoppItem); msgFailureUpdateOppItem='Error: failure to update OpportunityLineItem <br/>' +ex.getTypeName() + ' - ' + ex.getCause() + ': ' + ex.getMessage();}    
        }
         BatchAutoRenewal.fromBatch=false;
        
        // Update oppotunity
        DARTLogger.LogMessage logMsgUpdateopp;
        try
        {
            Opportunity oppty = new Opportunity(Id=oppId);
            oppty.Booking_in_Processing__c = false;
            update oppty;
            // Log messages when update opp successfully  
            logMsgUpdateopp = new DARTLogger.LogMessage(
                                    opp.Id ,DARTLogger.OPPERATION_UPDATE_OPP,
                                    '','',
                                    DARTLogger.TYPE_SUCCESS, '', '');
            
            lstLogMsg.add(logMsgUpdateopp);
        }
        // Log messages when exception occur(update failed) 
        catch(Exception ex){logMsgUpdateopp = new DARTLogger.LogMessage(opp.Id ,DARTLogger.OPPERATION_UPDATE_OPP,'','',DARTLogger.TYPE_ERROR, ex.getMessage(), '');lstLogMsg.add(logMsgUpdateopp);msgFailureUpdateOpp = 'Error: failure to update Oppotunity<br/>' +ex.getTypeName() + ' - ' + ex.getCause() + ': ' + ex.getMessage();}
        
        
        // Send Email
        
        List<EmailTemplate> emailTemplate = [select Id, Subject, HtmlValue, Body from EmailTemplate Where Name=:TEMPLETE_NAME limit 1];
        
        System.debug('=============================> Ads SIZE: ' + lstAllAds.size());
        
        if(!emailTemplate.isEmpty())
        {

            String htmlBody='';
            // prepare to send email
            htmlBody = emailTemplate.get(0).HtmlValue;
            htmlBody = htmlBody.replace('@@@', DARTUtil.generateTableCompaigns(lstAllOrder))
                        .replace('###', DARTUtil.generateTableCompaignItems(lstAllAds))
                        .replace('{!opp.Name}', opp.Name)
                        .replace('{!opp.Owner}', opp.Owner.Name+'')
                        .replace('{!opp.Id}', DARTUtil.URL_INSTANCE+'/'+opp.Id)
                        .replace('#$',(lstAllOrder.isEmpty()?'There is no Order request successfully.':''))
                        .replace('msgOppUpdateOppFail', ('').equals(msgFailureUpdateOpp)?'':msgFailureUpdateOpp)
                        .replace('msgOppItemUpdateFail', ('').equals(msgFailureUpdateOppItem)?'':msgFailureUpdateOppItem);
                        
            // Email send to opportunity owner. //sochanra.yos@gaea-sys.com & yos.sochanra@gmail.com
            // DARTUtil.sendMail(new List<String>{'sochanra.yos@gaea-sys.com'}, new List<String>{'yos.sochanra@gmail.com'}, DARTUtil.EMAIL_SUBJECT_BOOKING, 'Opportunity Owner', htmlBody);
            // 2013-04-16 - GTCRM-169 - Auto copy adops@gumtree.com in to booking email
            DARTUtil.sendMail(new List<String>{opp.Owner.Email}, new List<String>{'adops@gumtree.com'}, DARTUtil.EMAIL_SUBJECT_BOOKING, 'Gumtree Robot',htmlBody);
                          
        }    
        else  
        {
            // Email send to opportunity owner if there is no email template found.
            String errMsg = 'Dear ' + opp.Owner.Name + 
                            '<br/><br/> There is no EmailTemplate name '+ TEMPLETE_NAME+ 'found.';
                             
            DARTUtil.sendMail(new List<String>{opp.Owner.Email}, new List<String>{'adops@gumtree.com'},DARTUtil.EMAIL_SUBJECT_BOOKING,
                                               'Gumtree Robot', errMsg);
        }  
           
        //Log the error message(s) -> insert in to attachement file of opportunity.
     
        DARTLogger.getInstance().log(oppId,lstLogMsg);
       
    } 
    

}