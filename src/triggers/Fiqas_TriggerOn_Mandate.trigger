/*

Change log;
2014-05-14 - GTCRM-807 - Gumtree UK Direct Debit
2014-01-08 - GTCRM-1540-Direct Debit Modulus Checks completed, but no bank checks received - resulting in no invoicing
2015-04-21 - GTCRM-1945 - API send issue with DD Mandates BY PNC

*/

trigger Fiqas_TriggerOn_Mandate on Mandate__c (after update) {
    string[] manDateIds= new string[]{};
    list<Mandate__c> lstMan=new list<Mandate__c>();
    list<Id> mId=new list<Id>();
    Map<Id,Opportunity> mOpp=new Map<Id,Opportunity>();
    List<Opportunity> listOpp=new List<Opportunity>();

    if (Trigger.isupdate) {        
        for ( Mandate__c nMan: Trigger.new) { 
            if(nMan.Fiqas_Mandate_Synced__c != 'NOTSYNCED' && nMan.Fiqas_Mandate_Synced__c != null) continue;
            If(nMan.Opportunity__c!=null && nMan.Modulus_Check_Sales_Ops__c== 'Approved')
            
            // GTCRM-1540-Direct Debit Modulus Checks completed, but no bank checks received - resulting in no invoicing
            listOpp.add(new Opportunity(Id=nMan.Opportunity__c,Payment_Method__c='Direct Debit'));
                                
            //update Account
            if(nMan.Bank_AccountNumber__c != null && nMan.Bank_SortCode__c !=null && nMan.Modulus_Check_Sales_Ops__c== 'Approved'){
                lstMan.add(nMan);
                mId.add(nMan.ID); 
            }
        }
         //&&( nMan.Status__c.equals('rejected') || nMan.Status__c.equals('NOK'))
        for( Opportunity opp:[select Payment_Method__c,StageName,Direct_Debit_Mandate__c,Account.Account_Number_Fiqas__c, IsWon  from Opportunity where Direct_Debit_Mandate__c in:mId]){
           if(opp.Payment_Method__c.equals('Direct Debit') && opp.StageName.equals('Booking') && String.valueOf(opp.Account.Account_Number_Fiqas__c).length()==12){
              manDateIds.add(opp.Direct_Debit_Mandate__c);
            }
        }   
               
        if(!manDateIds.isEmpty() && !Test.isRunningTest() && !FiqasAPIservice.done_Fiqas_TriggerOn_Mandate){
            FiqasAPIservice.insertMandate_BACS(manDateIds);
            FiqasAPIservice.done_Fiqas_TriggerOn_Mandate = true;
        }
        if(!lstMan.isEmpty()) FiqasAPIservice.updateAccounfromMandate(lstMan);
        update listOpp;
    }
    
}