/* 
** Fieldmapping class to connect SF fields to Fiqas service

Change log:
- 2013-04-22 - GTCRM-245 - Standard/Premium dunning flow on customer level
- 2013-09-11 - NK: changed to without sharing to fix some users: INSUFFICIENT_ACCESS_OR_READONLY, insufficient access rights on object id: []
- 2014-05-14 - GTCRM-807 - Gumtree UK Direct Debit
- 2015-04-21 - GTCRM-1945 - API send issue with DD Mandates BY PNC
- 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level

*/

public without sharing class FiqasAPIservice {
 
    public static string output = '';
    public static string sync = 'FAILED';
    public static Boolean done_Fiqas_TriggerOn_Mandate = false;
    
    /**
     * ADD 19 March 2014: #1641, PN    
     * Split setting values logic from future
     */
    public static void doCustomerUpsert(Account acc, String accountNumber, Boolean createLog){
        string ResultfromGet = FiqasHTTPpost.CustomerGet(accountNumber);
        if (ResultfromGet =='FAILED'){
            String ResultFromInsert;
            if(createLog){
                ResultFromInsert = FiqasHTTPpost.CustomerInsert(                                              
                        accountNumber,
                        '',
                        '', 
                        ReplaceNull(acc.Fiqas_Customer_Type__c),
                        'Active', // acc.Account_Status__c, //CustStatus
                        acc.Name,
                        '', //fiqas_Customer_extra
                        String.valueOf(acc.Fiqas_ApplyVATYN__c),
                        ReplaceNull(acc.Finance_Contact__r.Email),                          
                        ReplaceNull(acc.Company_VAT_No__c),
                        ReplaceNull(acc.Company_Reg_No__c),
                        String.valueOf(acc.Fiqas_Dunning_Flow__c),   //CustInfo1
                        '', //CustInfo2
                        ReplaceNull(acc.BillingStreet),
                        ReplaceNull(String.valueof(acc.Fiqas_House_number__c)), //required if billingstreet entered
                        '', //Fiqas_house_number_extra
                        ReplaceNull(acc.BillingPostalCode),
                        ReplaceNull(acc.BillingCity), 
                        ReplaceNull(acc.BillingCountry),
                        ReplaceNull(acc.Finance_Contact__r.FirstName),
                        '', //Finance_contact_middlename
                        ReplaceNull(acc.Finance_Contact__r.LastName),                    
                        '',   //finance_contact_Title    
                        '',   //finance_contact_salutation
                        '0',  //String.valueOf(acc.Finance_Contact__r.Sex__c), 
                        ReplaceNull(acc.Fiqas_Payment_Method__c), 
                        '', //PayMethAccountNr
                        '', //PayMethAccountHolder
                        '', //PayMethBankName
                        '', //PayMethBankCity
                        ReplaceNull(acc.Fiqas_Billing_Cycle__c),
                        ReplaceNull(acc.Fiqas_CMRSheet__c));
            }else{
                ResultFromInsert = FiqasHTTPpost.CustomerInsertWithoutLog(                                              
                        accountNumber,
                        '',
                        '', 
                        ReplaceNull(acc.Fiqas_Customer_Type__c),
                        'Active', // acc.Account_Status__c, //CustStatus
                        acc.Name,
                        '', //fiqas_Customer_extra
                        String.valueOf(acc.Fiqas_ApplyVATYN__c),
                        ReplaceNull(acc.Finance_Contact__r.Email),                          
                        ReplaceNull(acc.Company_VAT_No__c),
                        ReplaceNull(acc.Company_Reg_No__c),
                        String.valueOf(acc.Fiqas_Dunning_Flow__c),   //CustInfo1
                        '', //CustInfo2
                        ReplaceNull(acc.BillingStreet),
                        ReplaceNull(String.valueof(acc.Fiqas_House_number__c)), //required if billingstreet entered
                        '', //Fiqas_house_number_extra
                        ReplaceNull(acc.BillingPostalCode),
                        ReplaceNull(acc.BillingCity), 
                        ReplaceNull(acc.BillingCountry),
                        ReplaceNull(acc.Finance_Contact__r.FirstName),
                        '', //Finance_contact_middlename
                        ReplaceNull(acc.Finance_Contact__r.LastName),                    
                        '',   //finance_contact_Title    
                        '',   //finance_contact_salutation
                        '0',  //String.valueOf(acc.Finance_Contact__r.Sex__c), 
                        ReplaceNull(acc.Fiqas_Payment_Method__c), 
                        '', //PayMethAccountNr
                        '', //PayMethAccountHolder
                        '', //PayMethBankName
                        '', //PayMethBankCity
                        ReplaceNull(acc.Fiqas_Billing_Cycle__c),
                        ReplaceNull(acc.Fiqas_CMRSheet__c));
            }
            // set the checkbox on the account    
            If (ResultFromInsert=='OK'){ sync = 'OK';} 
            else{ sync = 'FAILED'; }
        }else if (ResultfromGet =='OK'){
            String ResultFromUpdate;
            if(createLog){
                ResultFromUpdate = FiqasHTTPpost.CustomerUpdate(                                               
                        accountNumber,
                        '',
                        '', 
                        ReplaceNull(acc.Fiqas_Customer_Type__c), 
                        'Active', // acc.Account_Status__c, 
                        acc.Name,
                        '', //fiqas_Customer_extra
                        String.valueOf(acc.Fiqas_ApplyVATYN__c),
                        ReplaceNull(acc.Finance_Contact__r.Email),
                        ReplaceNull(acc.Company_VAT_No__c),
                        ReplaceNull(acc.Company_Reg_No__c),
                        ReplaceNull(acc.Fiqas_Dunning_Flow__c),   //CustInfo1
                        '', //CustInfo2
                        ReplaceNull(acc.BillingStreet),
                        '', //Fiqas_house_number_extra required if billingstreet entered
                        '', //Fiqas_house_number_extra
                        ReplaceNull(acc.BillingPostalCode),
                        ReplaceNull(acc.BillingCity),
                        ReplaceNull(acc.BillingCountry),
                        ReplaceNull(acc.Finance_Contact__r.FirstName),
                        '', //Finance_contact_middlename
                        ReplaceNull(acc.Finance_Contact__r.LastName),                   
                        '',   //finance_contact_Title    
                        '',   //finance_contact_salutation
                        String.valueOf(acc.Finance_Contact__r.Sex__c));  
            }else{
                ResultFromUpdate = FiqasHTTPpost.CustomerUpdateWithoutLog(                                               
                        accountNumber,
                        '',
                        '', 
                        ReplaceNull(acc.Fiqas_Customer_Type__c), 
                        'Active', // acc.Account_Status__c, 
                        acc.Name,
                        '', //fiqas_Customer_extra
                        String.valueOf(acc.Fiqas_ApplyVATYN__c),
                        ReplaceNull(acc.Finance_Contact__r.Email),
                        ReplaceNull(acc.Company_VAT_No__c),
                        ReplaceNull(acc.Company_Reg_No__c),
                        ReplaceNull(acc.Fiqas_Dunning_Flow__c),   //CustInfo1
                        '', //CustInfo2
                        ReplaceNull(acc.BillingStreet),
                        '', //Fiqas_house_number_extra required if billingstreet entered
                        '', //Fiqas_house_number_extra
                        ReplaceNull(acc.BillingPostalCode),
                        ReplaceNull(acc.BillingCity),
                        ReplaceNull(acc.BillingCountry),
                        ReplaceNull(acc.Finance_Contact__r.FirstName),
                        '', //Finance_contact_middlename
                        ReplaceNull(acc.Finance_Contact__r.LastName),                   
                        '',   //finance_contact_Title    
                        '',   //finance_contact_salutation
                        String.valueOf(acc.Finance_Contact__r.Sex__c));     
            }  
            
            // set the checkbox on the account    
            If (ResultFromUpdate=='OK'){ sync = 'OK';} 
            else{ sync = 'FAILED'; }                                   
        }else{
            // set the checkbox on the account 
            sync = 'FAILED';                    
        }
        acc.Fiqas_Account_Synced__c = sync;
    }

    //this is for the Customer Insert And Update http post 
    @future (callout=true)
    public static void Customer_InsUpdate(string[] accountarray) {
        list<Account> Aforupdate = new list<Account>();
        Account[] a = [SELECT Id, Finance_Contact__r.FirstName, Finance_Contact__r.MiddleName__c, 
                                        Finance_Contact__r.LastName, Finance_Contact__r.Email, Finance_Contact__r.Title, 
                                        Finance_Contact__r.Salutation, Finance_Contact__r.Sex__c,
                                        Account_Number_Fiqas__c,
                                        Parent.Name, Name,
                                        Fiqas_Customer_Extra__c,
                                       // Fiqas_ApplyBTWYN__c,
                                        Fiqas_ApplyVATYN__c,
                                        Fiqas_Customer_Type__c,
                                        Company_VAT_No__c,
                                        Company_Reg_No__c,
                                        BillingStreet,
                                        Fiqas_House_number__c,
                                        Fiqas_House_number_extra__c,
                                        BillingPostalCode,
                                        BillingCity,
                                        BillingCountry,
                                        //BTW_Number__c,
                                        //KVK_Number__c,
                                        Fiqas_Payment_Method__c,
                                        Fiqas_Billing_Cycle__c,
                                        Fiqas_CMRSheet__c,
                                        Account_Status__c,
                                        Fiqas_Dunning_Flow__c
                                        FROM Account where ID IN :accountarray]; 
        
 
        for (Account acc: a){ 
            doCustomerUpsert(acc, acc.Account_Number_Fiqas__c, true);
            Account Aupdates = new Account(Id = acc.Id, Fiqas_Account_Synced__c = sync);  
            Aforupdate.add(Aupdates);
        }
        update Aforupdate;        
    }

    // this is a small function that replaces a 'null' string with a '' string'
    public static String ReplaceNull(String input){
        output = input;
        if (input==null){
            output = '';
        }
        return output;
    } 

    // This is for trigger on Mandate send mandate to Fiqas
    // 2014-05-14 - GTCRM-807 - Gumtree UK Direct Debit
    // CPN: 2015-04-21 - GTCRM-1945 - populate Mandate__c.Fiqas_Mandate_Synced__c with the status of the API - OK or FAILED
    // public static boolean ischeck=true; 
    @future (callout=true)
    public static void insertMandate_BACS(string[] manDateId) {
        List<Mandate__c> lupdateStatus = new List<Mandate__c>();
        for(Mandate__c man:[Select m.Account__r.Account_Number_Fiqas__c, m.JPMC_AccountCode__c ,m.Mandate_Reference__c,m.Mandate_Reason__c, m.Id, m.Opportunity__r.Campaign_Start__c, m.Opportunity__r.Campaign_End__c, m.Bank_SortCode__c,m.Bank_Name__c, m.Bank_PostalCode__c,
                             m.JPMC_Account_Number__c, m.Bank_Account_Holder_Name__c,Name From Mandate__c m where id in:manDateId]){
                        //system.debug('insertMandate_BACS==='+man);
                        datetime sDate =man.Opportunity__r.Campaign_Start__c!=null?datetime.newInstance(man.Opportunity__r.Campaign_Start__c.Year(),man.Opportunity__r.Campaign_Start__c.Month(),man.Opportunity__r.Campaign_Start__c.day()):null   ;
                        String startDate=sDate!=null?sDate.format('yyyyMMdd'):'';
                        datetime eDate =man.Opportunity__r.Campaign_End__c!=null?datetime.newInstance(man.Opportunity__r.Campaign_End__c.Year(),man.Opportunity__r.Campaign_End__c.Month(),man.Opportunity__r.Campaign_End__c.day()):null   ;
                        String endDate=eDate!=null?eDate.format('yyyyMMdd'):'';
                        //system.debug('insertMandate_BACS==='+startDate);
                        String ResultFromInsert = FiqasHTTPpost.eBAY_API_BACSMandate_Insert
                        (ReplaceNull(man.Account__r.Account_Number_Fiqas__c)  ,// ReplaceNull(man.Fiqas_Account_Number__c)
                         'BACS DD',
                         startDate,                          
                         '', //endDate,
                         String.valueof(man.JPMC_Account_Number__c),
                         ReplaceNull(man.Bank_Account_Holder_Name__c),
                         String.valueof(man.Mandate_Reference__c),//man.Id
                         String.valueof(man.Bank_SortCode__c),
                         man.JPMC_AccountCode__c , 
                         ''//PayMethStatusReason
                         );  
                         
                         lupdateStatus.add(new Mandate__c(Id = man.Id, Fiqas_Mandate_Synced__c = ResultFromInsert));
                        // system.debug('ResultFromInsert='+ResultFromInsert);
        }
        if(!lupdateStatus.isEmpty()) update lupdateStatus;
    
    }
    //2014-05-14 - GTCRM-807 - Gumtree UK Direct Debit
    //TH 04-04-2014 updated Account when Mapdate updated
    public static void updateAccounfromMandate(list<Mandate__C> lstMandate){
        list<Account> lstAcc=new list<Account>();
        list<String> lstAccId=new list<String>();
        Map<Id,Mandate__c> mapMan=new Map<Id,Mandate__c>();
        for(Mandate__c man:lstMandate){
            lstAccId.add(man.Account__c);
            mapMan.put(man.Account__c,man); 
        }
        for(Account acc:[select Bank_Account_Holder_Name__c,Bank_Account_Number__c,Bank_SortCode__c,Bank_Name__c,Bank_City__c,Bank_Street__c,Bank_PostalCode__c,Bank_Country__c from account where id in :lstAccId]){
            Mandate__c m=mapMan.get(acc.id);
            acc.Bank_Account_Holder_Name__c=m.Bank_Account_Holder_Name__c;
            acc.Bank_Account_Number__c=string.valueOf(m.Bank_AccountNumber__c);
            acc.Bank_SortCode__c=m.Bank_SortCode__c;
            acc.Bank_Name__c=m.Bank_Name__c;
            acc.Bank_City__c=m.Bank_City__c;
            acc.Bank_Street__c=m.Bank_Street__c;
            acc.Bank_PostalCode__c=m.Bank_PostalCode__c; 
            acc.Bank_Country__c=m.Bank_Country__c;
            lstacc.add(acc);
    
        }
        if(!lstacc.isEmpty()) update lstacc;
        
    }   

 @istest(SeeAllData=true)
  static void myTest() {

       
           Account acc = new Account();
                        acc.Name='Test Account_#453';      
                        acc.BillingStreet='12345';
                        acc.BillingCity='Test';
                        acc.Phone='12456796';
                        acc.BillingCountry='NL';
                        acc.BillingPostalCode='134697';
                        acc.BillingState='test';                    
                        acc.Fiqas_Dunning_Flow__c='Standard';
                        insert acc;

        
        // Insert a contact
        Contact contact = new Contact(lastname='testContact', accountID=acc.Id);
        insert contact;   
      
        acc.Finance_contact__c = contact.id;
        update acc; 
   
     AccountContactRole acr = new AccountContactRole(Role='Other',IsPrimary=true, AccountId=acc.Id, ContactId=contact.Id);
        insert acr;     
        
        acc.BillingCity = 'Utrecht';
        update acc;
        
    string[] todo = new string[]{};
    todo.add((string)acc.id); 
    
    Opportunity opp=new Opportunity(Name='test', 
                                    Type='New Business', 
                                    StageName ='Booking' , 
                                    LeadSource = 'JOBS: UK Wide - CC (Mar 10)', 
                                    CloseDate=system.today(), 
                                    BillingFrequency__c ='Monthly in arrears' , 
                                    AccountId = acc.Id,
                                    Payment_Method__c='Direct Debit',
                                    P_O_Number__c = '123',
                                    // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
                                    Signed_contract_attached__c = true);
    insert opp;
    
    Mandate__c man=new Mandate__c(Bank_AccountNumber__c = '12345656'
                                    , Bank_SortCode__c = '123456'
                                    , Modulus_Check_Sales_Ops__c= 'Approved'
                                    , Opportunity__c = opp.Id
                                    , Bank_Street__c = 'london' 
                                    
                                    , Bank_Name__c = 'halifax'
                                    , Bank_Country__c = 'GB'
                                    , Bank_City__c = 'London'
                                    , Bank_Account_Holder_Name__c = 'AccountHolder398'
                                    
                                    , Account__c = acc.Id);
   insert man;
   man=[select Bank_Street__c from Mandate__c where Id=:man.Id ];
   man.Bank_Street__c='Paris';
   update man;  
    
    test.startTest();
  //  FiqasAPIservice.Customer_Insert(todo);
    FiqasAPIservice.Customer_InsUpdate(todo);
    test.stopTest();
    
    
  }
}