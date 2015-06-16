/*

Change log;
2015-04-28 - GTCRM-1969 - Display products trying to delete on GT database

*/


public with sharing class OppStage2DeletePackage implements Schedulable, Database.Batchable<sObject>,  Database.AllowsCallouts {
     
    public static final String OPP_STAGE_LOST = 'Lost';
    public static final String OPP_STAGE_BOOKING = 'Booking';
    
    //2015-04-28 - GTCRM-1969 - Display products trying to delete on GT database
    public static final String PRODUCT_RECORD_TYPE = 'DART6';
    
    // For Batch
    private String query;
    
    /* Constructor - Default */
    public OppStage2DeletePackage(){
        //query = 'SELECT Id, OpportunityId, PriceBookEntry.Product2.RecordType.Name FROM OpportunityLineItem WHERE isOppLost__c = true AND Opportunity.StageName = :OPP_STAGE_LOST';
        
        //2015-04-28 - GTCRM-1969 - Display products trying to delete on GT database
        query = 'SELECT Id, OpportunityId, PriceBookEntry.Product2.RecordType.Name FROM OpportunityLineItem WHERE isOppLost__c = true AND Opportunity.StageName = :OPP_STAGE_LOST AND PriceBookEntry.Product2.RecordType.Name != :PRODUCT_RECORD_TYPE';
    }
    
     
    /* Constructor - For Batch Test Class */
    public OppStage2DeletePackage(String lineItemId){
        //query = 'SELECT Id, OpportunityId, PriceBookEntry.Product2.RecordType.Name FROM OpportunityLineItem WHERE isOppLost__c = true AND Opportunity.StageName = :OPP_STAGE_LOST and id = \'' + lineItemId + '\';
        
        //2015-04-28 - GTCRM-1969 - Display products trying to delete on GT database
        query = 'SELECT Id, OpportunityId, PriceBookEntry.Product2.RecordType.Name FROM OpportunityLineItem WHERE isOppLost__c = true AND Opportunity.StageName = :OPP_STAGE_LOST and id = \'' + lineItemId + '\' AND PriceBookEntry.Product2.RecordType.Name != :PRODUCT_RECORD_TYPE';
    }
    
    /* Lock/unlock opp line items from scheduling */ 
    private static void lockOrUnlockItems(OpportunityLineItem[] lstItem, Boolean islock){
         for(OpportunityLineItem i : lstItem) 
         i.isOppLost__c = islock;
         
         //Avoiding this gumtree_remote_opli_trigger to called future method
         BatchAutoRenewal.fromBatch = true; 
         
         update lstItem;
    }
    
    /* Called from Opportunity trigger(after update) */ 
    public static void lock4DeletePackage(Opportunity[] lstNew, Map<Id, Opportunity> mOld){ 
        Set<Id> setOppId = new Set<Id>();
        for(Opportunity newOpp : lstNew){ 
            if(mOld.get(newOpp.Id).StageName == OPP_STAGE_BOOKING && newOpp.StageName == OPP_STAGE_LOST){
                setOppId.add(newOpp.Id);
            }
        }
         
        if(setOppId.size() > 0)  
        lockOrUnlockItems([SELECT id FROM OpportunityLineItem WHERE OpportunityId IN :setOppId], true);
       
    }    
    
    /* Implement interface method for Schedulable */
    public void execute(SchedulableContext sc) {  
        
        // set scope=1 to avoid error: You have uncommitted work pending. Please commit or rollback before calling out
        // since GumtreeAPI.deletePackageNotFuture --> callout then insert.
        Database.executeBatch(new OppStage2DeletePackage(), 1);
    } 
    
    /* Implement interface method for Batchable */
    public Database.QueryLocator start(Database.BatchableContext BC){ 
        return Database.getQueryLocator(query);
    }
    
    /* Implement interface method for Batchable */ 
    public void execute(Database.BatchableContext BC,List<OpportunityLineItem> scope){
         
         for(OpportunityLineItem i : scope){
            if(Test.isRunningTest()) continue;
            GumtreeAPI.deletePackageNotFuture(i.Id);
         } 
         lockOrUnlockItems(scope, false);  
    }
    
    
    /* Implement interface method for Batchable */ 
    public void finish(Database.BatchableContext BC){ }
}