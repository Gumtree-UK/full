/**

GTCRM-749 - Auto-renewal/rolling/cancel opportunities

Change log:

**/

public with sharing class CancellationReasonController {
    
    public OpportunityLineItem lineItem{get;set;}
    public String oppID{get;set;}
    public String oppItemsID{get;set;}
    public Boolean isSuccess{get;set;}
    public List<String> lstItemsID{get;set;}
    public CancellationReasonController() {
        lineItem=new OpportunityLineItem();
        lineItem.Notice_Date__c=System.today();
        lineItem.Cancellation_Date__c= lineItem.Notice_Date__c.addDays(30);
        //lineItem.Cancellation_Date__c=Date.newInstance(lineItem.Cancellation_Date__c.year(),lineItem.Cancellation_Date__c.month(),01).addDays(-1);
        oppItemsID=apexPages.currentPage().getParameters().get('pid');
        if(oppItemsID!=null) lstItemsID=oppItemsID.split(',');
        isSuccess=false;
    }
    
    public PageReference saveReason(){
        Try{
            if(lineItem.Cancellation_Reason__c==null) {lineItem.Cancellation_Reason__c.addError('Field is Required');return null;}
            if(lineItem.Notice_Date__c==null) {lineItem.Notice_Date__c.addError('Field is Required');return null;}
            if(lineItem.Cancellation_Date__c==null) {lineItem.Cancellation_Date__c.addError('Field is Required');return null;}
            if(lineItem.Cancellation_Date__c<System.today()) { lineItem.Cancellation_Date__c.addError('Cancellation date cannot be in the past');return null;}
            if(lineItem.Notice_Date__c<System.today()) { lineItem.Notice_Date__c.addError('Notice date cannot be in the past');return null;}
            Date startMonth=System.today();
            startMonth=Date.newInstance(startMonth.year(),startMonth.month(),01);
            //if(lineItem.Notice_Date__c<startMonth) {lineItem.Notice_Date__c.addError('Notice date cannot be in previous month');return null;}
            if(lineItem.Notice_Date__c>lineItem.Cancellation_Date__c) { lineItem.Cancellation_Date__c.addError('Cancellation date cannot be < notice date');return null;}
            //if(lineItem.Notice_Date__c<System.today().addMonths(-2)) { lineItem.Cancellation_Date__c.addError('Notice date cannot be < today minus 2 months');return null;}
            List<OpportunityLineItem> lstLineItem=[Select OpportunityId,PricebookEntry.Product2.Name,o.until_Date__c, o.from_Date__c, o.TotalPrice, o.Notice_Date__c, o.Net__c, o.Cancellation_Reason__c, o.Cancellation_Date__c From OpportunityLineItem o where o.id in:lstItemsID];
            system.debug('lstLineItem<<<<<<<'+lstLineItem);
            for(OpportunityLineItem item:lstLineItem){
                item.Cancellation_Reason__c=lineItem.Cancellation_Reason__c;
                item.Notice_Date__c=lineItem.Notice_Date__c;
                item.Cancellation_Date__c=lineItem.Cancellation_Date__c;
                oppID=item.OpportunityId;
            }
            ClsBookingOppUpdate.IGNORE_UNTILDATE_POP=true;
            system.debug('After ========'+lstLineItem);
            if(!lstLineItem.isEmpty()) update lstLineItem;
            Opportunity p=new Opportunity(id=oppID);
            p.Approval_Cancellation__c= true;
            update p;
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Cancellation Reason: '+lineItem.Cancellation_Reason__c+'');
            req1.setObjectId(p.id);
            List<String> lstApprover=new List<String>();
            for(User usr:[select id from User where LastName='Paul' AND FirstName='Steven']){
                lstApprover.add(usr.id); 
                
            }
            System.debug('Test lstApprover>>>>>>>>'+lstApprover);
            req1.setNextApproverIds(lstApprover);
            Approval.ProcessResult result = Approval.process(req1);
            isSuccess=true;
        }catch(exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex+''));
        }
        return null;
    }
    
    
    
}