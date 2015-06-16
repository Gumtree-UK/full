/**
 NK:14/02/2014: all logic code has been moved from trigger: gumtree_remote_opli_trigger; so we can call it from either trigger itself and BatchOpliTrigger (right after BatchRenewal)

*/

public class GumtreeRemoteOpliController {
    public static void updateOportunityLineItem(list<OpportunityLineItem> lstopliNew,list<OpportunityLineItem> lstopliOld){
        Integer i = 0;
    
         Set<String> setOppId = new Set<String>();
         Set<String> setAccountId = new Set<String>();
         for (OpportunityLineItem oli : lstopliNew) {
           // if(oli.OpportunityId == null ) continue; ????
            setOppId.add(oli.OpportunityId);
         }
        Map<String,Opportunity> mapOpp = new  Map<String,Opportunity>([select ID, AccountID, StageName, RecordTypeId, Payment_Method__c, CC_Reference__c from Opportunity where id In: setOppId ]);
      
        for(Opportunity opp: mapOpp.values()){
            if( opp.AccountId== null ) continue;
            setAccountId.add(opp.AccountId);
        }
         Map<String,Account> mapAccount = new Map<String,Account>([select Id, AccountNumber from Account where id In :setAccountId]);
         list<OpportunityLineItem> lstopliUpdate=new list<OpportunityLineItem>();
        for (OpportunityLineItem oli : lstopliNew) {
            //System.debug('>>>>>>>>>fromBatch:'+BatchAutoRenewal.fromBatch+'>>>>>oli0: '+oli);
            if(!BatchAutoRenewal.fromBatch){
                if (lstopliOld == null || lstopliOld[i] == null || oli.from_Date__c != lstopliOld[i].from_Date__c
                || oli.until_Date__c != lstopliOld[i].until_Date__c
                || oli.Quantity != lstopliOld[i].Quantity
                || oli.Adjusted_credits__c != lstopliOld[i].Adjusted_credits__c) {
                    
                     doProcess(  mapOpp, oli,mapAccount);
                     i++;
                }
            }else{
                    //System.debug('>>>>>>>>>oli1:'+oli);
                    doProcess(  mapOpp, oli,mapAccount);
                    //update AwaitForTriggerProcess
                    oli.AwaitForTriggerProcess__c=false;
                    lstopliUpdate.add(oli);
                    
                }  
            
               // Opportunity op = [select ID, AccountID, StageName, RecordTypeId, Payment_Method__c, CC_Reference__c from Opportunity where id = :oli.OpportunityId];
                
            
        }
        //System.debug('>>>>>>>>>lstopliUpdate:'+lstopliUpdate);
        if(!lstopliUpdate.isEmpty())
        {
             update lstopliUpdate;
        }
    }
    private static void doProcess(  Map<String,Opportunity> mapOpp,OpportunityLineItem oli,Map<String,Account> mapAccount){
                
                Opportunity op = mapOpp.get(oli.OpportunityId);           
                if ((op.StageName == 'Booking' || op.StageName == 'Booking (Auto-renewal)' || op.StageName == 'Booking (Cancelled)') &&
                    (op.RecordTypeId == '01220000000YY7Y' || op.RecordTypeId == '01220000000YY7T'|| op.RecordTypeId == '012w0000000QBzr'|| op.RecordTypeId == '01220000000YaHA'  || op.RecordTypeId == '01220000000YY7J') &&
                    (op.Payment_Method__c != 'Credit/Debit Card' || (op.CC_Reference__c != null && op.CC_Reference__c != ''))       
                ) {
    
                   // Account acc = [select Id, AccountNumber from Account where id = :op.AccountId];
                   Account acc = mapAccount.get(op.AccountId);
    
                    Decimal adjusted_credits = 0;
                    
                    if (oli.Adjusted_credits__c != null)
                            adjusted_credits = oli.Adjusted_credits__c;
    
                    // Even though they are Dates in OpportunityLineItem, somehow, sometimes they become DateTimes...
                    Date fromDate = Date.valueOf(oli.from_Date__c);
                    Date untilDate = Date.valueOf(oli.until_Date__c);
    
                    if (acc.AccountNumber != '' && acc.AccountNumber != null) {
                        GumtreeUtilsInterface utils = GumtreeUtils.getGumtreeUtilsInterface();
                        utils.remote(acc.AccountNumber).assignPackage(
                            acc.id,
                            String.valueOf(oli.Id),
                            String.valueOf(oli.PricebookEntryId),
                            fromDate,
                            untilDate,
                            Math.round(oli.Quantity),
                            Math.round(adjusted_credits)
                        );
                    }
                }
            
    }
    
}