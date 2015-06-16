/**

GTCRM-749 - Auto-renewal/rolling/cancel opportunities

Change log:
    @modified: method updateProductDate()
    @author: SUY Sreymol
    @modified date : 27 May 2014
**/

public with sharing class ClsBookingOppUpdate {
    public static void updateProductDate(List<Opportunity> lstOpp){
        ClsBookingOppUpdate.IGNORE_UNTILDATE_POP=true;
        //Filter only linked_opportunity!=null
        Map<String,String> mOriginalOpp=new map<String,String>();
        for(Opportunity opp:lstOpp){
            if(opp.Opportunity__c==null) continue;
            mOriginalOpp.put(opp.id,opp.Opportunity__c);
        }
        //Loads Opportunity from database
        Map<String,Opportunity> mOpps=new Map<String,Opportunity>();
        for(Opportunity opp:[Select o.id,o.StageName, Auto_Renewal__c,
                                    (select PriceBookEntry.Product2.RecordType.Name, 
                                        Length_months__c, Revenue2__c, 
                                        PricebookEntry.Product2Id, 
                                        OpportunityId, Net_Net_Net__c,
                                        Opportunity.Auto_Renewal__c, 
                                        from_date__c, Cancellation_Date__c,Status__c,id, 
                                        until_Date__c, Gross__c,
                                        PricebookEntry.Product2.Length_months__c,
                                        PricebookEntry.Product2.Site__c ,
                                        Quantity
                                    from OpportunityLineItems) 
                            From Opportunity o where id in:mOriginalOpp.keySet() OR id in:mOriginalOpp.values()]){
            mOpps.put(opp.id,opp);
        }
        
        List<OpportunityLineItem> updatedProducts=new List<OpportunityLineItem>();
        List<Revenue_Schedule2__c> revSchds = new List<Revenue_Schedule2__c>();//SUY Sreymol 27/05/2014- to store created/updated RS
        List<Opportunity> lstOriginalOpp=new List<Opportunity>();
        
        OpportunityLineItem[] cancelledItems = new List<OpportunityLineItem>(); 
        for(String cloneOppID:mOriginalOpp.keySet()){
            //New opportunity: update start date to booking date for each product
            Opportunity cOpp=mOpps.get(cloneOppID);
            if(cOpp!=null && cOpp.Auto_Renewal__c != true) { 
            for(OpportunityLineItem item:cOpp.OpportunityLineItems){
                item.from_Date__c=System.today();
                item.until_Date__c=item.from_date__c;
                if(item.Length_months__c!=null)item.until_Date__c = item.from_date__c.addmonths(integer.ValueOf(item.Length_months__c));
                updatedProducts.add(item);
            }
            }
            //Original opportunity: - update end date to new opp ?booking? date minus 1 day for each product.?
            Opportunity originalOpp=mOpps.get(mOriginalOpp.get(cloneOppID));
            if(originalOpp==null) continue;
             
            originalOpp.StageName = ClsOpportunityService.BOOKING_CANCELLED; //BOOKING_RE_SIGNED;
            originalOpp.Approval_Cancellation__C = false;
            originalOpp.IsCancellationPending__c = false;
            
            lstOriginalOpp.add(originalOpp);
            system.debug('==================originalOpp.OpportunityLineItems== ' + originalOpp.OpportunityLineItems);
            for(OpportunityLineItem item:originalOpp.OpportunityLineItems){
                
                if(item.until_Date__c==null || item.until_Date__c<=System.today().addDays(-1)) continue;
                //@SUY Sreymol 27/05/2014 - add some logic to RS to work same as Cancellation function
                Boolean isDARTProduct = ClsOpportunityService.isDartProduct(item.PriceBookEntry.Product2.RecordType.Name);
                Date origEnddate = item.until_Date__c;
                Date startDate = item.from_Date__c;
                
                item.Cancellation_Reason__c = 'Re-signed';
                item.status__c = 'Cancelled';
                
                if(cOpp.Auto_Renewal__c == true)
                {
                    item.Notice_Date__c =  item.until_Date__c;//System.today();
                    item.Cancellation_Date__c = item.until_Date__c;//System.today();
                }
                else
                {
                    item.until_Date__c = System.today().addDays(-1); 
                    item.Notice_Date__c =  System.today();//item.until_Date__c;
                    item.Cancellation_Date__c = System.today();//item.until_Date__c;
                }
                
                Integer prevLengthMonths = Math.abs(startDate.monthsBetween(origEnddate));
                Decimal newLength = Math.abs(startDate.monthsBetween(item.Cancellation_date__c));
                item.Length_months__c = newLength;
                Decimal netDelivered = 0;
                Decimal grossCostperDay = 0;
                Integer numDays = 0;
                // Number of days = origEnddate - startDate
                numDays = Math.abs(startDate.daysBetween(origEnddate));
                system.debug('numDays : >>>>>>>>>>>>>>> ' + numDays);
                system.debug('grossCostperDay : >>>>>>>>>>>>>>> ' + grossCostperDay);
                system.debug('prevLengthMonths : >>>>>>>>>>>>>>> ' + prevLengthMonths);
                system.debug('newLength : >>>>>>>>>>>>>>> ' + newLength);
                // Gross Price p/day = Gross__c / Number of days
                grossCostperDay = item.Gross__c/numDays;
                ClsOpportunityService.setReveneuSchedule(item, origEnddate, startDate, prevLengthMonths, newLength, netDelivered, grossCostperDay, numDays, isDARTProduct, revSchds);
                //---------------27/05/2014------------------------------------//
                updatedProducts.add(item); 
                cancelledItems.add(item); 
            } 
        } 
        ClsBookingOppUpdate.IGNORE_UPDATE_RS = true; // To ignore update any existing RS that are not related to resign Opportunity (use in updateDeliverySummeRS2)
        ClsBookingOppUpdate.IS_CANCEL_BEFORE_TIME = true; // To ignore update any existing RS that are not related to resign Opportunity (use in LineItemTrigger)
        if(!updatedProducts.isEmpty()) update updatedProducts;
        system.debug('revSchds::>>>>>>>>>>>>>>>>>' + revSchds);
        if (!revSchds.isEmpty()) upsert revSchds UniqueKey__c; //SUY Sreymol 27/05/2014 - to upsert RS
        if(!lstOriginalOpp.isEmpty()) update lstOriginalOpp;
        system.debug('BBBBBBBBBB---->lstOriginalOpp= ' +lstOriginalOpp);
    }
    
    public final static String BOOKING_RE_SIGNED='Booking (Re-signed)'; 
    public final static String ST_BOOKING='Booking'; 
    public static Boolean IGNORE_UNTILDATE_POP=false;
    public static Boolean IGNORE_UPDATE_RS = false;
    public static Boolean IS_CANCEL_BEFORE_TIME = false;
}