/** Batch process of Availability Forecast.
    AvailForecast allows only single item per request.
    User may select multiple items or all at once to request AvailForecast.   
    Created Date:26/11/2012 
    
Change log:
- 2013-04-16 - GTCRM-169 - Auto copy adops@gumtree.com in to email
- 2013-12-12 - GTCRM-649 - Populate custom field in DFP with OppOwner Division 
- 2014-02-19 - GTCRM-809 - Upgrade DFP time targeting
- 2014-07-04 - GTCRM-1012 - Opportunity Account Record type to be submitted to Sales team custom field
- 2014-08-12 - GTCRM-1213 - Remove copy adops@gumtree.com in to email

*/
Global virtual class BatchAvailabilityForecastProcess implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallOuts{
    
    String currencyCodeField = (UserInfo.isMultiCurrencyOrganization()?' ,CurrencyIsoCode ':'') ;
    
    public String soqlItems ='Select DFP_Time_Monday__c, DFP_Time_Tuesday__c, DFP_Time_Wednesday__c, DFP_Time_Thursday__c, DFP_Time_Friday__c, DFP_Time_Saturday__c, DFP_Time_Sunday__c, ' + 
      'Id,Quantity,Package__c,Pricebook_Name__c,Description,UnitPrice,PriceBookEntry.Product2.Name, '+ 
      'PricebookEntry.Product2.RecordType.Name,OpportunityId,Opportunity.Name,Opportunity.Owner.Name,Availability__c, Share_of_voice__c, Period__c, '+
      'Targeting__c,PriceBookEntry.Product2.Advertising_Medium__r.DART_AdSlotSize__c,from_Date__c,until_Date__c, Last_Availability_Forecast__c, '+
      'FC_Quantity__c,FC_Ad_Served_every__c,FC_Period__c,AdDayofWeek__c,AdHourofDay__c,AdOperatingSystems__c,'+
      'AdWebBrowsers__c,PriceBookEntry.Product2Id,AdKeywords__c, KeyValueString__c, Ad_Id__c,Billing_category__c,PriceBookEntry.Product2.Site__r.Country__c, '+
      'CPM_net_net_net__c, Sales_Price_net_net_net__c, Ad_Name__c,Net_Net_Net__c, PriceBookEntry.Product2.Fixed_Site__c,'+
      'AdBrowsersMajorVersion__c, AdBrowsersMinorVersion__c, PriceBookEntry.Product2.Advertising_Medium__r.Dart_Prio__c,'+
      'PriceBookEntry.Product2.Advertising_Medium__r.DART_ProductType__c, PriceBookEntry.Product2.Advertising_Medium__r.Dart_WebPropertyAlias__c,' +
      'PriceBookEntry.Product2.Advertising_Medium__r.Dart_TargetPlatform__c, Opportunity.Owner.Division, Opportunity.Account.RecordType.Name,' +
      'PricebookEntry.Product2.Site__r.Name, '+
      'PricebookEntry.Product2.Site__r.id '+
      + currencyCodeField + 
      ' From OpportunityLineItem '; 
   
  
    public final String TEMPLETE_NAME = 'ForecastEmailTemplate';    
        
    protected String oppId ;
    protected Opportunity opp;
    
    //Store error with record id if error occurs
    Map<String, Exception> errorMap =  new Map<String, Exception>();
    
    // Store Log message for all requests even error or success.
    List<DARTLogger.LogMessage> lstLogMsg = new List<DARTLogger.LogMessage>();
    
    List<DARTObject.DARTForecast> listForecast = new List<DARTObject.DARTForecast>() ;
    
    // Message error when upadate opporturnity failed.
    String msgFailureUpdateOpp='';
    // Message error when update opportunityLineItem failed.
    String msgFailureUpdateOppItem='';
    
    /**Constructor1: No lineitems selected - considered as 'Select All' eligible items*/
    public BatchAvailabilityForecastProcess(String oppId)
    { 
        this.oppId = oppId; 
        soqlItems+=  getDefaultWhere();
        soqlItems = soqlItems.replace('%1','\''+oppId+'\'').replace('%2', '\''+ DARTUtil.DART6+'\'');
    }
    
    /**Constructor2: Only selected and eligible items to be processed */
    public BatchAvailabilityForecastProcess(String oppId, Set<String> lineItemIds)
    {
        this(oppId);
        soqlItems+= ' AND Id IN '+DARTUtil.generateIds(lineItemIds);
        
    }
    
    public virtual String getDefaultWhere()
    {
        return  ' WHERE OpportunityId=%1 AND PricebookEntry.Product2.RecordType.Name IN (%2) '+
        ' And PricebookEntry.Product2.No_Availability_Forecast__c=False'+
        ' And Check_Inventory__c=True';
    }
    
    global virtual Database.QueryLocator start(Database.BatchableContext BC)
    {
        System.debug('>>>>>>>>>>>soqlItems:'+soqlItems);
        return Database.getQueryLocator(soqlItems);
    }
     
    global virtual void execute(Database.BatchableContext BC, List<sObject> scope)
    {
            
            for(Sobject sobj : scope)
            {
                OpportunityLineItem oppItem = (OpportunityLineItem)sobj; 
                ForecastController forecastCont = new ForecastController(oppItem);
                
                try
                {
                    forecastCont.forecastProcess();
                    String dartMethod = forecastCont.getInvokedMethod();
                    List<DARTObject.DARTForecast> lstFC = forecastCont.getObjectForecast(); 
                    if(lstFC != null)
                    {
                        listForecast.add(lstFC.get(0));
                    }
                     
                    // Log messages when request success //oppItem.OpportunityId
                    DARTLogger.LogMessage logMsg = new DARTLogger.LogMessage(
                                            oppItem.Id ,DARTLogger.OPPERATION_FORECAST,
                                            dartMethod,oppItem.PricebookEntry.Product2.RecordType.Name,
                                            DARTLogger.TYPE_SUCCESS, '','');
                    
                    lstLogMsg.add(logMsg);
                }
                // Log messages when request failure
                catch(Exception ex){errorMap.put(oppItem.Id, ex);DARTLogger.LogMessage logMsg = new DARTLogger.LogMessage(oppItem.Id ,DARTLogger.OPPERATION_FORECAST,'',oppItem.PricebookEntry.Product2.RecordType.Name,ex);lstLogMsg.add(logMsg);} 
            }
             
    }  
    
        
    global virtual void finish(Database.BatchableContext BC){
        
        //TODO1:
        //do update the opportunity field here.....
        //Opportunity opp = new Opportunity(Id=oppId);
        //opp.FieldName = 
        //update opp;
        //TODO2: 
        // do update the OpportunityLineItem
        //TODO3:
        //Send forecast email
        
        opp = [Select Id, Name, Owner.Name, Owner.Email From Opportunity Where id =: oppId];
        
        
        if(!listForecast.isEmpty())
        {
            
            // Update opportunityLineItem
            List<OpportunityLineItem> listOppItemToUpdate = new List<OpportunityLineItem>();
            BatchAutoRenewal.fromBatch=true;
            for(DARTObject.DARTForecast fc : listForecast)
            {
                
                OpportunityLineItem oppItem = new OpportunityLineItem(Id=fc.getOppItemID());
                oppItem.Availability__c = DARTUtil.toDouble(fc.getAvailableUnits());//(fc.getAvailableUnits()==null?0: Double.valueOf(fc.getAvailableUnits()+''));
                oppItem.Share_of_voice__c = DARTUtil.toDouble(fc.getShareOfVoice());
                oppItem.Last_Availability_Forecast__c = DateTime.Now();
                listOppItemToUpdate.add(oppItem);
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
            catch(Exception ex){logMsgUpdateoppItem = new DARTLogger.LogMessage(opp.Id ,DARTLogger.OPPERATION_UPDATE_OPPLINEITEM,'','',DARTLogger.TYPE_ERROR, ex.getMessage(), '');lstLogMsg.add(logMsgUpdateoppItem);msgFailureUpdateOppItem='Error: failure to update OpportunityLineItem <br/>' +ex.getTypeName() + ' - ' + ex.getCause() + ': ' + ex.getMessage();}     
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
        // Email Template
        List<EmailTemplate> emailTemplate = [select Id, Subject, HtmlValue, Body from EmailTemplate Where Name=:TEMPLETE_NAME limit 1];

        if(!emailTemplate.isEmpty())
        {

            String htmlBody='';
            // prepare to send email
            htmlBody = emailTemplate.get(0).HtmlValue;
            htmlBody = htmlBody.replace('###', DARTUtil.generateTableForecast(listForecast))
                        .replace('{!opp.Name}', opp.Name)
                        .replace('{!opp.Owner}', opp.Owner.Name+'')
                        .replace('{!opp.Id}', DARTUtil.URL_INSTANCE+'/'+opp.Id)
                        .replace('$$$', DARTUtil.generateTableForecastError(errorMap))
                        .replace('#$',(listForecast.isEmpty()?'There is no Forecast request successfully.':''))
                        .replace('msgOppUpdateOppFail', ('').equals(msgFailureUpdateOpp)?'':msgFailureUpdateOpp)
                        .replace('msgOppItemUpdateFail', ('').equals(msgFailureUpdateOppItem)?'':msgFailureUpdateOppItem);
                        
            // Email send to opportunity owner. sochanra.yos@gaea-sys.com
            // DARTUtil.sendMail(new List<String>{'sochanra.yos@gaea-sys.com'}, new List<String>{'yos.sochanra@gmail.com'} ,DARTUtil.EMAIL_SUBJECT, 'Opportunity Owner', htmlBody); 
            
            // 2013-04-16 - GTCRM-169 - Auto copy adops@gumtree.com in to email
            // DARTUtil.sendMail(new List<String>{opp.Owner.Email}, new List<String>{'adops@gumtree.com'}, DARTUtil.EMAIL_SUBJECT, 'Gumtree Robot', htmlBody);
            // 2014-08-12 - GTCRM-1213 - Remove copy adops@gumtree.com in to email
               DARTUtil.sendMail(new List<String>{opp.Owner.Email}, new List<String>{'operations@gumtree.com'}, DARTUtil.EMAIL_SUBJECT, 'Gumtree Robot', htmlBody);                                                         
        } 
        else 
        {
            // Email send to opportunity owner if there is no email template found.
            String errMsg = 'Dear ' + opp.Owner.Name + 
                            '<br/><br/> There is no EmailTemplate name '+ TEMPLETE_NAME+ 'found.';

             // 2014-08-12 - GTCRM-1213 - Remove copy adops@gumtree.com in to email                
             //DARTUtil.sendMail(new List<String>{opp.Owner.Email}, new List<String>{'adops@gumtree.com'}, DARTUtil.EMAIL_SUBJECT, 'Opportunity Owner', errMsg);
             DARTUtil.sendMail(new List<String>{opp.Owner.Email}, new List<String>{'operations@gumtree.com'}, DARTUtil.EMAIL_SUBJECT, 'Opportunity Owner', errMsg);
        } 
          
        //Log the error message(s) -> insert in to attachement file of opportunity.
        DARTLogger.getInstance().log(oppId,lstLogMsg);
        
    }
     

}