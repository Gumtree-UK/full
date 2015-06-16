@isTest
public class ClsCreateAccontNewEntitlementTest {
	
    static testMethod void TestData(){
        Test.startTest();
        try{
            System.debug('=================================ClsCreateAccountNewEntitlement>Start================================');
            List<Account> accounts = new List<Account>();
            for(Integer i=1;i<=5;i++){
                accounts.add(new Account(Name='test'+i,BillingPostalCode='2321',
                    BillingStreet='sfaddfa',BillingState='fsafaa',
                    BillingCountry='AF:AX:AL:DZ:AS:AD:AO:AI:AQ:AG:AR:AM:',BillingCity='ffdsafsad',Account_Migrated__c=false));
            }
            insert accounts;
            for(Integer i=1;i<=5;i++){
                System.assertEquals('test'+i,accounts.get(i-1).Name);
            }
            List<Id>accountIds = new List<Id>();
            for(Account acc : accounts){
                accountIds.add(acc.Id);
            }
            System.assertEquals(5,accountIds.size());
            
            List<Entitlement> entitlements = [Select Name,StartDate,SlaProcessId,AccountId From Entitlement 
                                                Where AccountId=:accountIds Order By Name];
            System.assertEquals(10,entitlements.size());
            Map<Id,List<Entitlement>> mAccountId_Entitlement = new Map<Id,List<Entitlement>>();
            for(Entitlement entitlement : entitlements){
                if(mAccountId_Entitlement.get(entitlement.AccountId) == null){
                    mAccountId_Entitlement.put(entitlement.AccountId,new List<Entitlement>());
                }
                mAccountId_Entitlement.get(entitlement.AccountId).add(entitlement);
            }
            
            //in case insert 5 Cases
            List<Case> cases = new List<Case>();
            for(Id accId : accountIds){
                List<Entitlement> lstEntitlement = mAccountId_Entitlement.get(accId);
                System.assertEquals(2,lstEntitlement.size());
               // System.assertEquals('Re-open SLA',lstEntitlement.get(0).Name);
                System.assertEquals('SLA',lstEntitlement.get(1).Name);
                
                //create new case
                cases.add(new Case(Subject='Test Subject',AccountId=accId));
            }
           
            //insert custom setting value
            List<Config_Settings__c> lstConfigSetting = new List<Config_Settings__c>();
            lstConfigSetting.add(new Config_Settings__c(Name = CustomSettingsManager.GT_HELP_ACCOUNT_ID,  Text_Value__c = '0012000000D5Aba', Checkbox_Value__c= true));
            lstConfigSetting.add(new Config_Settings__c(Name = CustomSettingsManager.CREATE_CONTACT_IN_CASE_TRIGGER_ENABLED, Checkbox_Value__c= true));
            lstConfigSetting.add(new Config_Settings__c(Name = CustomSettingsManager.OPP_EXPIRY_DATE_TO_CON_TRIG_ENABLED, Checkbox_Value__c= true));
            insert lstConfigSetting;
            
            insert cases;
            
            System.assertEquals(5,cases.size());
            
            Id[] caseIds = new Id[0];
            for(Case c : cases){
                caseIds.add(c.Id);
            }
            cases = [Select AccountId,EntitlementId,Entitlement.Name,Status From Case where Id in:caseIds];
            
            for(Case c : cases){
                Entitlement[] entitlements1 = mAccountId_Entitlement.get(c.AccountId);
                System.assertEquals(entitlements1.get(1).Id,c.EntitlementId);
                System.assertEquals('SLA',c.Entitlement.Name);
            }
            
            //in case update 5 cases above to Status=new(re-open) 
            for(Case c :cases){
                c.Status = 'New (Re-Open)';
            }   
            update cases;
            cases = [Select AccountId,EntitlementId,Entitlement.Name,Status From Case where Id in:caseIds];
            for(Case c : cases){
                Entitlement[] entitlements1 = mAccountId_Entitlement.get(c.AccountId);
               // System.assertEquals(entitlements1.get(0).Id,c.EntitlementId);
                System.assertEquals('Re-open SLA',c.Entitlement.Name);
            }
            
            //in case update 5 cases above to Status=Closed 
            for(Case c :cases){
                c.Status = 'Closed';
                c.SlaStartDate = System.now();
            }
            update cases;
            
            for(CaseMilestone caseMilestone : [Select completionDate, case.SlaStartDate from CaseMilestone Where 
                        caseId In:caseIds]){
                System.assertEquals(System.now().format('yyy-mm-dd'),caseMilestone.completionDate.format('yyyy-mm-dd'));
            }
            
            
            //in case old account without entitlement
            Account acc1 = new Account(Name='test999',BillingPostalCode='2321',
                    BillingStreet='sfaddfa',BillingState='fsafaa',
                    BillingCountry='AF:AX:AL:DZ:AS:AD:AO:AI:AQ:AG:AR:AM:',BillingCity='ffdsafsad',Account_Migrated__c=false);
            insert acc1;
            //delete 2 entitlement from this account
            delete [Select Id from Entitlement where AccountId=:acc1.Id];
            acc1.Name = 'test9999';
            update acc1;
            Entitlement[] ent = [Select Id from Entitlement where AccountId=:acc1.Id];
            System.assertEquals(2,ent.size());          
            
            //test in uncoveraged code
            // Create two accounts, one of which is missing a required field
            for(Account acc : accounts){
                acc.Name = null;
            }
            Database.SaveResult[] saveResult = Database.update(accounts, false);
            ClsCreateAccontNewEntitlement.handleErrorHandling(saveResult,accounts,'Id','Account');
            
            for(Note note : [Select Title,Body from Note Where ParentId in:accountIds]){
                System.assertEquals('Account',note.Title);
                System.assertEquals(saveResult.get(0).getErrors().get(0).getMessage(),note.Body);
            }
            
            
            System.debug('==================================ClsCreateAccountNewEntitlement>End==================================');
        }catch(Exception ex){
            System.debug('>>>>>>>>>>>>>ERROR> ClsCreateAccontNewEntitlement.ClsCreateAccontNewEntitlementTes(): '+ex.getMessage());
        }
        Test.stopTest();
    }
}