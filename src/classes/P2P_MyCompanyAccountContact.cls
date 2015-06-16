/**
 * Task #4286: My Company (GTCRM-1295) - "My Company (GIS).docx" - Page 5
 * Trigger on Account
 * @author: CPN
 * @createdDate: 30-Oct-2014
 */
public class P2P_MyCompanyAccountContact{
    /**
     * Check which contact is Primary/Financial
     * Called from trigger P2P_FinancialPrimaryCheck Before insert/update
     */
    public static void checkFinancePrimaryContact(List<Contact> lcontold, List<Contact> lcontnew){
        Set<String> conIds = new Set<String>();
        Map<String, Contact> mPrimaryCon = new Map<String, Contact>();
        Map<String, Contact> mFinancialCon = new Map<String, Contact>();
        for(Contact con : lcontnew){
            conIds.add(con.Id);
            if(con.Primary_Contact__c && con.AccountId != null){
                mPrimaryCon.put(con.AccountId, con);
                //Clean the other primary contacts with same account
                con.Primary_Contact__c = false;
            }
            if(con.Finance_Contact__c && con.AccountId != null){
                mFinancialCon.put(con.AccountId, con);
                //Clean the other Financial contacts with same account
                con.Finance_Contact__c = false;
            }
        }
        
        //Clean the existing primary
        Map<Id, Contact> existCons = new Map<Id, Contact>();
        for(Contact con : [Select Primary_Contact__c, Finance_Contact__c, AccountId From Contact Where (AccountId IN: mPrimaryCon.keySet() Or AccountId IN: mFinancialCon.keySet()) And Id NOT IN: conIds]){
            if(mPrimaryCon.containsKey(con.AccountId) && mPrimaryCon.get(con.AccountId).Id != con.Id && con.Primary_Contact__c){
                if(!existCons.containsKey(con.Id)) existCons.put(con.Id, con);
                con.Primary_Contact__c = false;
            }
            if(mFinancialCon.containsKey(con.AccountId) && mFinancialCon.get(con.AccountId).Id != con.Id && con.Finance_Contact__c){
                if(!existCons.containsKey(con.Id)) existCons.put(con.Id, con);
                con.Finance_Contact__c = false;
            }
        }
        if(!existCons.isEmpty()) update existCons.values();
        //Make sure only one primary contact to one account
        for(String accId : mPrimaryCon.keySet()){
            mPrimaryCon.get(accId).Primary_Contact__c = true;
        }
        //Make sure only one Financial contact to one account
        for(String accId : mFinancialCon.keySet()){
            mFinancialCon.get(accId).Finance_Contact__c = true;
        }
    } 
    
    /**
     * Set which contact is Primary/Financial
     * Called from trigger P2P_FinancialPrimaryCheck After insert/update
     */
    public static void setAccountFinancePrimaryContact(List<Contact> lcontold, List<Contact> lcontnew){
        Integer i = 0;
        Set<Id> resetPrimAcc = new Set<Id>();
        Set<Id> resetFinAcc = new Set<Id>();
        for(Contact con : lcontnew){
            //Refresh primary state on account
            if(lcontold == null && con.AccountId != null){
                resetPrimAcc.add(con.AccountId); 
                resetFinAcc.add(con.AccountId);
            }
            //Refresh primary state to other accounts
            if( lcontold != null && 
                (lcontold[i].AccountId != lcontnew[i].AccountId || lcontold[i].Primary_contact__c != lcontnew[i].Primary_contact__c)
            ){
                if(lcontold[i].AccountId != null){
                    resetPrimAcc.add(lcontold[i].AccountId); 
                }
                if(lcontnew[i].AccountId != null) {
                    resetPrimAcc.add(lcontnew[i].AccountId); 
                }
            }
            //Refresh Financial state to other accounts
            if( lcontold != null && 
                (lcontold[i].AccountId != lcontnew[i].AccountId || lcontold[i].Finance_Contact__c != lcontnew[i].Finance_Contact__c)
            ){
                if(lcontold[i].AccountId != null){
                    resetFinAcc.add(lcontold[i].AccountId); 
                }
                if(lcontnew[i].AccountId != null) {
                    resetFinAcc.add(lcontnew[i].AccountId); 
                }
            }
            i++;
        }
        Map<Id, Account>  resetAcc = new Map<Id, Account>();
        for(Contact con : [Select Id, Primary_Contact__c, Finance_Contact__c, AccountId From Contact Where AccountId IN: resetPrimAcc OR AccountId IN: resetFinAcc]){
            if(!resetAcc.containsKey(con.AccountId)) resetAcc.put(con.AccountId, new Account(Id = con.AccountId, Primary_contact__c = null, Finance_contact__c = null));
            if(con.Primary_Contact__c) resetAcc.get(con.AccountId).Primary_contact__c = con.Id;
            if(con.Finance_Contact__c) resetAcc.get(con.AccountId).Finance_contact__c = con.Id;
        }
        
        if(!resetAcc.isEmpty()) update resetAcc.values();
    }  
}