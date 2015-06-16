global with sharing class ClsConvertAutoDirectOpp {
    
    public final static String ERROR_KEY='Error';
    public final static String BOOKING_CANCELLED_STAGENAME='Booking (Cancelled)';
    public final static String AUTOS_APPROVED_RECORDTYPE='Campaign Delivery (M)';
    public final static String AUTOS_PREAPPROVED_RECORDTYPE='Sales Management (M)';
    public final static String CONTRACT_STAGENAME='Contract';
    public final static String EXISTING_BUSINESS_TYPE='Existing Business';
    public final static String CONVERTED='Converted';
    public final static String KIT_TRANSFER='KIT Transfer';
    
    
    private static Map<String,String> mRecordType;
    public static Map<String,String> getRecordType(){
        if(mRecordType==null){
            mRecordType=new Map<String,String>();
            for(RecordType rec:[Select r.id,r.SobjectType, r.Name From RecordType r where SobjectType='Opportunity' AND (Name=:AUTOS_APPROVED_RECORDTYPE OR Name=:AUTOS_PREAPPROVED_RECORDTYPE)]){
                mRecordType.put(rec.Name,rec.id);
            }
        }
        return mRecordType;
    }
    
   
    
    
        webservice static String cloneOpportunity(String oppID){
       
        //if(oppID==null) return ERROR_KEY+': Source Opportunity not found';
        List<Opportunity> lstOpp=[Select o.Type, o.SystemModstamp, o.StageName, o.RecordTypeId, o.Primary_Contact__c, o.Pricebook2Id, o.Previous_Year_Amount_Net_Net__c, o.P_O_Number__c, o.OwnerId, o.Opportunity_Group__c, o.Name, o.Lost_Reason__c, o.LastModifiedDate, o.LastModifiedById, o.LastActivityDate, o.IsWon, o.IsDeleted, o.IsClosed, o.IsCancellationPending__c, o.Interval__c, o.Id, o.IOnumber__c, o.Description, o.CreatedDate, o.CreatedById, o.CloseDate, o.ClonedFrom__c, o.Campaign_Start__c, o.Campaign_Name__c, o.Campaign_End__c, o.CampaignId, o.Booking_in_Processing__c, o.BillingFrequency__c, o.Approved_Amount_Net_Net__c, o.Approval_Status__c, o.Approval_Cancellation__c, o.Agency__c, o.AccountId From Opportunity  o where id=:oppId];
        if(lstOpp.isEmpty())  return ERROR_KEY+': Source Opportunity not found';
        try{
            Opportunity originalOpp=lstOpp.get(0);
            //System.debug('===============originalOpp.RecordTypeId:'+originalOpp.RecordTypeId);
            //System.debug('===============getRecordType().get(AUTOS_APPROVED_RECORDTYPE)) :'+getRecordType().get(AUTOS_APPROVED_RECORDTYPE));
            if(originalOpp.RecordTypeId!=getRecordType().get(AUTOS_APPROVED_RECORDTYPE)) return ERROR_KEY+': RecordType is invalid';
//            if(originalOpp.Billing_Method__c!='Indirect') return ERROR_KEY+': Billing Method must be Indirect';
            if(originalOpp.Agency__c==null) return ERROR_KEY+': API / Agency can not be blank';
           
            Opportunity cloneOpp=originalOpp.clone(false,true);
            cloneOpp.Opportunity__c=originalOpp.id;
            cloneOpp.Agency__c=null;
            //cloneOpp.Name= cloneOpp.Name+'-' +CONVERTED;
            cloneOpp.ownerID=System.Userinfo.getUserId();
            cloneOpp.StageName=CONTRACT_STAGENAME;
            cloneOpp.RecordTypeId=getRecordType().get(AUTOS_PREAPPROVED_RECORDTYPE);
            cloneOpp.Probability = 90;
            cloneOpp.Type = EXISTING_BUSINESS_TYPE;
            cloneOpp.CloseDate = system.today();
            cloneOpp.BillingFrequency__c='Direct';
            cloneOpp.Payment_Method__c='Invoice';
//            cloneOpp.Billing_Account__c=cloneOpp.AccountId;
            cloneOpp.BillingFrequency__c='Month to Month';
            cloneOpp.Is_Converted__c=true;
//            cloneOpp.OppCreatedFrom__c = 'Convert';
            if (cloneOpp.BillingFrequency__c != 'Indirect')
              cloneOpp.Description = '';
            insert cloneOpp;
            return cloneOpp.id+'';
        }catch(Exception ex){
            return ERROR_KEY+''+ex;
        }
        
    }
    
    
    
    public static void updateProductDate(List<Opportunity> lstOpp){
        ClsBookingOppUpdate.IGNORE_UNTILDATE_POP=true;
        List<OpportunityLineItem> updatedProducts=new List<OpportunityLineItem>();
        List<Opportunity> lstOriginalOpp=new List<Opportunity>();

        //Filter only linked_opportunity!=null
        Map<String,String> mOriginalOpp=new map<String,String>();
        for(Opportunity opp:lstOpp){
            if(opp.Opportunity__c==null) continue;
            mOriginalOpp.put(opp.id,opp.Opportunity__c);
        }
        //Loads Opportunity from database
        Map<String,Opportunity> mOpps=new Map<String,Opportunity>();
        for(Opportunity opp:[Select o.createdDate,o.id,o.StageName,(Select PricebookEntry.Product2Id,from_Date__c,Cancellation_Date__c, Notice_Date__c,until_Date__c, length_months__c From OpportunityLineItems order by from_Date__c) From Opportunity o where id in:mOriginalOpp.keySet() OR id in:mOriginalOpp.values()]){
            mOpps.put(opp.id,opp);
        }
        
        // Here the date has to change according to: CRM-1105
        // Depending on the date that this is triggered.
        Date dNewDate = system.today();
        Date dTwenty = Date.newInstance(dNewDate.year(), dNewDate.month(), 20);
        if (dNewDate >= dTwenty) {
          dNewDate = Date.newInstance(dNewDate.year(), dNewDate.month(), 1).addMonths(2);
        }
        else {
          dNewDate = Date.newInstance(dNewDate.year(), dNewDate.month(), 1).addMonths(1);
        }
          
        
        //Load Month Length from Product
        Map<String,Decimal> mMonthLength=new  Map<String,Decimal>(); 
        for(String cloneOppID:mOriginalOpp.keySet()){
            Opportunity cOpp=mOpps.get(cloneOppID);
            if(cOpp==null) continue;
            for(OpportunityLineItem item:cOpp.OpportunityLineItems){
               mMonthLength.put(item.PricebookEntry.Product2Id,null);
               
               // CRM-1105: Update from_date on new Opp.
               item.from_Date__c = dNewDate;
               if (item.Length_months__c != null)
                  item.until_Date__c = item.from_date__c.addmonths(integer.ValueOf(item.Length_months__c));
               updatedProducts.add(item);
            }
        }
        
        for(Product2 pro:[Select id, p.Length_months__c From Product2 p where id in:mMonthLength.keySet()]){
             mMonthLength.put(pro.id,pro.Length_months__c);
        }
        
        for(String cloneOppID:mOriginalOpp.keySet()){
            //New opportunity: update start date to booking date for each product
            Opportunity cOpp=mOpps.get(cloneOppID);
            if (cOpp==null) continue;
            
            // With CRM-1105, this section is no longer needed.
            //Date startNewOpp;
            //for(OpportunityLineItem item:cOpp.OpportunityLineItems){
            //  if (startNewOpp==null)
            //    startNewOpp=item.from_Date__c;
            //}
           
            
           // Select o.until_Date__c, o.Notice_Date__c, o.Cancellation_Date__c From OpportunityLineItem o
            //Original opportunity: - update end date to new opp “booking” date minus 1 day for each product.”
            Opportunity originalOpp=mOpps.get(mOriginalOpp.get(cloneOppID));
            originalOpp.StageName=BOOKING_CANCELLED_STAGENAME;
            
            lstOriginalOpp.add(originalOpp);
            if (originalOpp==null) continue;
            for (OpportunityLineItem item:originalOpp.OpportunityLineItems){
              //if (startNewOpp==null) continue;
              item.Cancellation_Reason__c=KIT_TRANSFER;
                //if(item.until_Date__c==null || item.until_Date__c>startNewOpp.addDays(-1)){
                item.until_Date__c=dNewDate.addDays(-1);
                     
                //}
                
                //if(item.Notice_Date__c==null || item.Notice_Date__c>startNewOpp.addDays(-1)){
                item.Notice_Date__c=dNewDate.addDays(-1);
                //}
                
                //if(item.Cancellation_Date__c==null || item.Cancellation_Date__c>startNewOpp.addDays(-1)){
                item.Cancellation_Date__c=dNewDate.addDays(-1);
                //}
                
                updatedProducts.add(item);
            }
        }
        
        if (!updatedProducts.isEmpty())
          update updatedProducts;
        if (!lstOriginalOpp.isEmpty())
          update lstOriginalOpp;
    }
    
  
}