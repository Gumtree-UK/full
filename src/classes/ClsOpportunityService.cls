/**

GTCRM-749 - Auto-renewal/rolling/cancel opportunities
 
Change log:
    - create new method setReveneuSchedule() to use this logic in another class
     @author : SUY Sreymol 
     @modified date : 27/05/2014
    - update method cloneOpportunity 
     @desciption : to set the Opportonity Owner to Account Owner if original opp is not active
     @author : SUY Sreymol
     @modified date : 10/06/2014
**/
 
global class ClsOpportunityService {   
    
    public final static String ERROR_KEY='Error';
    public final static String BOOKING_CANCELLED = 'Booking (Cancelled)';
    public static Boolean IGNORE_UPDATE_RS = false;
    
    webservice static String cloneOpportunity(String oppID){ 
        if(oppID==null) return ERROR_KEY+': Source Opportunity not found';
        List<Opportunity> lstOpp = [Select o.Opportunity__r.RecordType.Name, o.Type, o.StageName, o.Spotlight_Pixel__c, o.Resubscribed__c, 
                                        o.RecordTypeId, o.Ready_for_invoicing__c, o.Probability, o.Primary_contact_check__c, o.Primary_Contact__c, 
                                        o.Pricebook2Id, o.Performance_Metric__c, o.Payment_Method__c, o.P_O_Number__c, o.OwnerId, o.NextStep, 
                                        o.Net_Net__c, o.Name, o.Lost_Reason__c, o.LeadSource, o.LastModifiedDate, o.LastModifiedById, o.LastActivityDate, 
                                        o.IsWon, o.IsDeleted, o.IsClosed, o.Internal_comments__c, o.Id, o.IOnumber__c, o.HasOpportunityLineItem, 
                                        o.ForecastCategoryName, o.ForecastCategory, o.FiscalYear, o.FiscalQuarter, o.Fiscal, o.Fiqas_VAT_Type__c, 
                                        o.Fiqas_Product_Code__c, o.Description, o.Creative_received__c, o.Creative_due_date__c, o.CreatedDate, o.CreatedById, 
                                        o.CloseDate, o.ClonedFrom__c, o.Campaign_Start__c, o.Campaign_Name__c, o.Campaign_End__c, o.CampaignId, 
                                        o.Booking_in_Processing__c, o.BillingFrequency__c, o.Approval_Status__c, o.Amount, o.Agency__c, o.AccountName__c, 
                                        o.AccountId, Date_To_Renew__c, Account.OwnerId, Owner.IsActive,
                                        (Select Cancellation_Reason__c,Notice_Date__c,Cancellation_Date__c,Status__c 
                                        from OpportunityLineItems)      
                                        From Opportunity o where id =: oppId];
        if(lstOpp.isEmpty())  return ERROR_KEY+': Source Opportunity not found';
        try{
          /*
            Problem 2: locking the Opp Owner field on the page layout does not prevent Autos Management from changing it. I have also removed �modify all� privileges on the Autos Management profile and that does not appear to have helped.
        Solution: the opportunity owner field to be locked at all times, and only modifiable by System Admin
          */
          Set<String> setValidProfile = new Set<String>{'System Administrator','Systemadministrator'}; 
          Profile userProfile = [select name from Profile where id=: UserInfo.getProfileId()]; 
            Opportunity oldOpp = lstOpp.get(0);
            Opportunity cloneOpp = oldOpp.clone(false,true);
            cloneOpp.Opportunity__c = oppID;
            cloneOpp.Name = cloneOpp.Name+' - Re-signed';
            //SUY Sreymol 10/06/2014 - If the opportunity owner is no longer active then in the Clone Opportunity functionality, we set the new opportunity owner as the owner of the account. 
            cloneOpp.OwnerId = setValidProfile.contains( userProfile.name) ?  UserInfo.getUserId() : ((!lstOpp.get(0).Owner.IsActive) ? lstOpp.get(0).Account.OwnerId : cloneOpp.OwnerId);
            //cloneOpp.OwnerId = setValidProfile.contains( userProfile.name)?  UserInfo.getUserId() : cloneOpp.OwnerId;   
            //------------- 10/06/2014 -----------------------//           
            cloneOpp.StageName ='Contract';
            cloneOpp.Type = 'Existing Business';
            cloneOpp.CloseDate = system.today();
            cloneOpp.Approval_Status__c = false;
            cloneOpp.Is_Converted__c=false;
            cloneOpp.Order_ID_Dart__c = null;
            cloneOpp.P_O_Number__c = null;
            cloneOpp.CC_Reference__c = null;
            cloneOpp.Approved_Amount_Net_Net__c = null;
            //system.debug('cloneOpp.OwnerId::::>>>>>>>' + cloneOpp.OwnerId);
            if ( cloneOpp.RecordTypeId == '01220000000YY7JAAW') {cloneOpp.RecordTypeId = '01220000000YY7YAAW';} //Campaign Delivery (J) -->   Sales Management (J)
            else if ( cloneOpp.RecordTypeId == '01220000000YaHAAA0') {cloneOpp.RecordTypeId = '01220000000YaH5AAK';} //Campaign Delivery (H) --> Sales Management (H)
            else if ( cloneOpp.RecordTypeId == '012w0000000QBzrAAG') {cloneOpp.RecordTypeId = '012w0000000QBzsAAG';} //Campaign Delivery (M) --> Sales Management (M)
            else if ( cloneOpp.RecordTypeId == '01220000000Y83PAAS') {cloneOpp.RecordTypeId = '01220000000Y83KAAS';} //Campaign Delivery (D) --> Sales Management (D)
            //now change record type for Autos - approved
            //if(lstOpp.get(0).RecordTypeId == '012e0000000CnoO') cloneOpp.RecordTypeid = '012e0000000Cnw3'; 
            //HCS 12.11.2013
            /*
              Problem 1: the new opp creates with the opp record type �Autos � Approved�. Which means that you don�t need to submit for approval before generating the IO.
        *Solution: * set record type to Autos - Pre-approved
            */
            if(lstOpp.get(0).RecordTypeId == '012g00000004TUS') cloneOpp.RecordTypeid = '012g00000004TUN';
            //end            
            cloneOpp.Probability = 90;
            
            
            //system.debug('cloneOpp::::>>>>>>>' + cloneOpp);
            insert cloneOpp;
            
            
            /*
                https://gaeasys.plan.io/issues/4427
                2) Cancellation Process:

                Condtion 1 : If the customer signed the new opportunity and previous opportunity end date is greater than the New opportunity then do nothing
                
                Condition 2: If the Customer signed the new Opportunity and previous opportunity end date is less than the New opportunity then previous opporutunity should cancel by system and renew the new opportunity.
                
                Cancellation Process:
                
                cancellation Reason : Re-signed
                Notice Date: Today
                Cancellation Date: Today
            */
            
             /*  if(oldOpp.Campaign_End__c != null && cloneOpp.Campaign_End__c != null &&
                oldOpp.Campaign_End__c < cloneOpp.Campaign_End__c){
                List<OpportunityLineItem> oldItems = oldOpp.OpportunityLineItems;
                if(!oldItems.isEmpty()){
                    for(OpportunityLineItem oldItem : oldItems){
                        oldItem.Cancellation_Reason__c = 'Re-signed';
                        oldItem.Notice_Date__c = System.today();
                        oldItem.Cancellation_Date__c = System.today();
                        oldItem.Status__c = 'Cancelled';
                    }
                    update oldItems;
                }
            } */
            
            return cloneOpp.id+'';
        }catch(Exception ex){
            return ERROR_KEY+''+ex;
        }
        
    }
    
    public static Boolean isDartProduct(String prod2Name) {
        return (prod2Name == 'DART5' || prod2Name == 'DART6') ? true : false;
    }

    public static void updateCancelledOpp(List<Opportunity> lstOld,List<Opportunity> lstNew){
        List<Opportunity> lstOpp=new List<Opportunity>();
        for(Integer i=0;i<lstNew.size();i++){
            Opportunity oldItem=lstOld.get(i);
            Opportunity newItem=lstNew.get(i);
            if(!oldItem.IsCancellationPending__c && newItem.IsCancellationPending__c){
                lstOpp.add(newItem);
            } 
        }
        Set<String> sOppID=new Set<String>();
        for(Opportunity opp:lstOpp){
            sOppID.add(opp.id); 
        }
        List<OpportunityLineItem> lstCancelledItem=new List<OpportunityLineItem>();
        List<Revenue_Schedule2__c> revSchds = new List<Revenue_Schedule2__c>();
        Set<String> sNotCompleteOpp=new Set<String>();
        for(Opportunity opp:[select id, (select Opportunity.Auto_Renewal__c, Notice_Date__c, Quantity, PricebookEntry.Product2.Site__c, PriceBookEntry.Product2.RecordType.Name, Length_months__c, Revenue2__c, PricebookEntry.Product2Id, OpportunityId, Net_Net_Net__c, from_date__c, Cancellation_Date__c,Status__c,id, until_Date__c, Gross__c from OpportunityLineItems) from Opportunity where id in:sOppID]){
            Boolean isAllUpdate=true;  
            system.debug('Cancellation_Date__c========'+opp.OpportunityLineItems.get(0).Cancellation_Date__c);            
            for(OpportunityLineItem item:opp.OpportunityLineItems){
                
                if(item.Cancellation_Date__c==null){
                    isAllUpdate=false;
                    sNotCompleteOpp.add(opp.id);
                }else{
                    Boolean isDARTProduct = isDartProduct(item.PriceBookEntry.Product2.RecordType.Name);
                    Date origEnddate = item.until_Date__c;
                    Date startDate = item.from_Date__c;
                    Integer prevLengthMonths = startDate.monthsBetween(origEnddate);
                    //avoid null pointer error @updated date:31/10/2013
                    Decimal NewLength = item.from_date__c.monthsBetween(item.Cancellation_date__c);
                    Decimal DeductRenewAmount=0;
                    if(item.Length_months__c!=null){
                    //   Decimal monthsDiff =   item.Length_months__c - NewLength;         
                    //   DeductRenewAmount = monthsDiff* (item.Netto_II__c/ (item.Length_months__c == 0? 1 :item.Length_months__c) );
                    }
                    //item.until_date__c=item.Cancellation_Date__c;
                    item.status__c='cancelled';
                    item.Length_months__c = NewLength;                   
                   //  item.Auto_Renewal_Amount__c = item.Auto_Renewal_Amount__c == null?0: item.Auto_Renewal_Amount__c - DeductRenewAmount;
                    
                    //SUY Sreymol 12/05/2014: GTCRM-749 - Auto-renewal revenue schedule creation - Cancellations/Re-sign
                    Decimal netDelivered = 0;
                    Decimal grossCostperDay = 0;
                    Integer numDays = 0;
                    // Number of days = origEnddate - startDate
                    numDays = startDate.daysBetween(origEnddate);
                    system.debug('numDays : >>>>>>>>>>>>>>> ' + numDays);
                    // Gross Price p/day = Gross__c / Number of days
                    grossCostperDay = item.Gross__c/numDays;
                    system.debug('grossCostperDay : >>>>>>>>>>>>>>> ' + grossCostperDay);
                    system.debug('Scenario 2 : >>>>>>>>>>>>>>> ' + (item.Cancellation_Date__c < origEnddate));
                    system.debug('Scenario 3 : >>>>>>>>>>>>>>> ' + (item.Cancellation_Date__c > origEnddate && (item.Cancellation_Date__c.month() == origEnddate.month())));
                    system.debug('Scenario 4 : >>>>>>>>>>>>>>> ' + (item.Cancellation_Date__c > origEnddate && (item.Cancellation_Date__c.month() > origEnddate.month())));
                    if (item.Cancellation_Date__c != item.until_Date__c) { // Sreymol 13/05/2014 if line item does not cancel, no need to create RS
                        item.until_date__c=item.Cancellation_Date__c;
                        
                        // Bunhor @06-Jan-14: new inserting RS price will be token from Rate Card of 3 Months Products
                        Revenue.mapRevId2IsRCprice.put(item.Revenue2__c, true); 
                        
                        ClsOpportunityService.setReveneuSchedule(item, origEnddate, startDate, prevLengthMonths, NewLength, netDelivered, grossCostperDay, numDays, isDARTProduct, revSchds);
                    }
                    //---------------- 12/05/2014 -------------//
                    
                    lstCancelledItem.add(item);
                }
            }
        }
        ClsBookingOppUpdate.IGNORE_UNTILDATE_POP=true;
        //System.debug('>>>>>>>>>>>>>lstCancelledItem:'+lstCancelledItem);
        ClsOpportunityService.IGNORE_UPDATE_RS = true;//To avoid update the RS that related to non cancel line item
        //System.debug('revSchds insert :>>>> '+ revSchds);
        if(!lstCancelledItem.isempty()) update lstCancelledItem;
        if (!revSchds.isEmpty()) upsert revSchds UniqueKey__c;
        lstOpp=new List<Opportunity>();
        /*
        for(Integer i=0;i<lstNew.size();i++){
            Opportunity oldItem=lstOld.get(i);
            Opportunity newItem=lstNew.get(i);
            Opportunity item=new Opportunity(id=newItem.id);
            if(!oldItem.IsCancellationPending__c && newItem.IsCancellationPending__c){
                 if(oldItem.StageName!=BOOKING_CANCELLED && newItem.StageName==BOOKING_CANCELLED){
                    if(sNotCompleteOpp.contains(item.id)) {
                        item.StageName=oldItem.StageName;
                    }
                }
                item.IsCancellationPending__c=false;
                lstOpp.add(item);
            }
        }
       */
        // if all items has been cancelled,Opportunity stage is updated to Booking_Cancelled
        System.debug('>>>>>>>>>>>>>sNotCompleteOpp:'+sNotCompleteOpp);
        for(Integer i=0;i<lstNew.size();i++){
            Opportunity oldItem=lstOld.get(i);
            Opportunity newItem=lstNew.get(i);
            Opportunity item=new Opportunity(id=newItem.id);
            System.debug('>>>>>>>>>>>>>>>oldItem.IsCancellationPending__c:'+oldItem.IsCancellationPending__c);
            System.debug('>>>>>>>>>>>>>>>newItem.IsCancellationPending__c:'+newItem.IsCancellationPending__c);
            if(!oldItem.IsCancellationPending__c && newItem.IsCancellationPending__c){
                    if(!sNotCompleteOpp.contains(item.id)) {
                        item.StageName=BOOKING_CANCELLED;
                    }
                item.Approval_Cancellation__C=false;
                item.IsCancellationPending__c=false;
                lstOpp.add(item);
            }
        } 
       
        if(!lstOpp.isempty()) upsert lstOpp;
        
    } 
    
    
    
    //@SUY Sreymol 27/05/2014 - To create/update RS of lineitem. This method is called from ClsBookingOppUpdate too
    public static void setReveneuSchedule(OpportunityLineItem item, Date origEnddate, Date startDate, Integer prevLengthMonths, Decimal NewLength, Decimal netDelivered, Decimal grossCostperDay, Integer numDays, Boolean isDARTProduct, List<Revenue_Schedule2__c> revSchds) {
        
        //Scenario 2: Cancelled before time
        if (item.Cancellation_Date__c < origEnddate) { 
            Revenue_Schedule2__c rs2 = getRS(item, item.until_date__c); 
             System.debug('==================Scenario 2===');
            //Calculate run days past original until_Date__c
            Date cloneStartDate = startDate.addMonths(NewLength.intValue());
            if (cloneStartDate > item.until_date__c) cloneStartDate = cloneStartDate.addMonths(-1);
            Integer runDaysPastOrigEnddate = cloneStartDate.daysBetween(item.until_date__c);
            Integer days = startDate.daysBetween(item.until_date__c);
            
            netDelivered = grossCostperDay*runDaysPastOrigEnddate; 
            rs2.tmp_Net_Net_Net_delivered__c = netDelivered;
            
            revSchds.add(rs2);
            
            item.Additional_Time_Days__c = runDaysPastOrigEnddate;
        } 
        //Scenario 3 : Cancelled after time, In Same Month
        else if (item.Cancellation_Date__c > origEnddate && (item.Cancellation_Date__c.month() == origEnddate.month())) { 
            Date tem = isDARTProduct? origEnddate : origEnddate.addMonths(-1); 
            
            Revenue_Schedule2__c rs2 = getRS(item, tem); 
              
            Decimal autoRenewRSOneMonth = (prevLengthMonths==0 || prevLengthMonths==null)? 0 : item.Gross__c/prevLengthMonths;
            
            // until date + 30 : Auto-renew Revenue_Schedule2__c for one month
            Date autoRenewUntilDate = origEnddate.addMonths(1);
            
            // Days between Auto-renew Revenue_Schedule2__c for one month and until date
            Integer rundaysPastOneMonthAutoRenew = origEnddate.daysBetween(item.until_date__c) < 0 ? -(origEnddate.daysBetween(item.until_date__c)) : origEnddate.daysBetween(item.until_date__c);
            
            // calculate net/net/net delivered
            netDelivered = autoRenewRSOneMonth + (rundaysPastOneMonthAutoRenew*grossCostperDay);
            
            rs2.tmp_Net_Net_Net_delivered__c = netDelivered; 
            
            // Bunhor @06-Jan-14: RS price will be token from Rate Card of 3 Months Products   
            Revenue.setPriceFrom3MonthsProductRateCard(item, rs2);
            System.debug('==================Scenario 3==='+rs2);
             
            
            revSchds.add(rs2);
            
            item.Additional_Time_Days__c = rundaysPastOneMonthAutoRenew;
        } 
        //Scenario 4 : Cancelled after time, In Future Month
        else if (item.Cancellation_Date__c > origEnddate) { //  && (item.Cancellation_Date__c.month() > origEnddate.month()) // Bunhor @31-Dec-14: taking this condition out
            Revenue_Schedule2__c rs2 = getRS(item, origEnddate); 
             
            //tmp_Net_Net_Net_delivered__c is the Full month at Gross Price
            rs2.tmp_Net_Net_Net_delivered__c = item.Gross__c/prevLengthMonths; 
            
            // Bunhor @06-Jan-14: RS price will be token from Rate Card of 3 Months Products 
            Revenue.setPriceFrom3MonthsProductRateCard(item, rs2);
            System.debug('==================Scenario 4===rs2='+rs2);
             
            revSchds.add(rs2);
            
            Integer length = origEnddate.monthsBetween(item.Cancellation_Date__c) == 0 ? 1 : origEnddate.monthsBetween(item.Cancellation_Date__c); // number of month between previous until date and cancellation date
    
            Date autoRenewUntilDate = origEnddate.addMonths(length);
             
            Revenue_Schedule2__c rsForFurturMonth = getRS(item, autoRenewUntilDate); 
             
            // Calculate run days past one full month Auto-renew until_Date__c
            Integer runDaysPastOneFullMonth = autoRenewUntilDate.daysBetween(item.until_date__c + 30) < 0 ? -(autoRenewUntilDate.daysBetween(item.until_date__c + 30)) : autoRenewUntilDate.daysBetween(item.until_date__c + 30);
            
            //Net/Net/Net Delivered
            netDelivered = runDaysPastOneFullMonth*grossCostperDay;
            rsForFurturMonth.tmp_Net_Net_Net_delivered__c = netDelivered;
            
            // Bunhor @06-Jan-14: RS price will be token from Rate Card of 3 Months Products 
            Revenue.setPriceFrom3MonthsProductRateCard(item, rsForFurturMonth);
             
            revSchds.add(rsForFurturMonth);
            
            item.Additional_Time_Days__c = runDaysPastOneFullMonth;
        } 
    }
    
    // Bunhor @ 21-Dec-14: code review and clean
    private static Revenue_Schedule2__c getRS(OpportunityLineItem item, Date endDate){
        Revenue_Schedule2__c rs = new Revenue_Schedule2__c();
        rs.Opportunity__c = item.OpportunityId; 
        rs.Revenue2__c = item.Revenue2__c;
        rs.Product__c = item.PricebookEntry.Product2Id;
        
        rs.Month__c = endDate.toStartOfMonth();
        rs.UniqueKey__c = item.Revenue2__c + String.valueOf(rs.Month__c);
            
        return rs;
    } 
}