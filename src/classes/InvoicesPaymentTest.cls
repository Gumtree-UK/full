@isTest
public with sharing class InvoicesPaymentTest {
    static Account acc;
    static List<Invoices__c> lstInv;
    static Braintree_Vault__c btVault;
    
    static void setupdata(){
        Config_Settings__c setting = new Config_Settings__c(Name=CustomSettingsManager.GT_HELP_ACCOUNT_ID);
        insert setting;
        Fiqas_Settings__c fiqas = new Fiqas_Settings__c(Name='Braintree_Webservice');
        insert fiqas; 
        BrainTree__c btSetting = new BrainTree__c(Name='BrainTree_UAT');
        insert btSetting;
         
        acc = new Account(Name='test', BillingStreet = 'Street', BillingCity = 'City', BillingState = 'State', BillingPostalCode = '123', BillingCountry = 'GB', Country_Code__c='GB', Bank_Country__c = 'GB' );
        insert acc;
        
        btVault = new Braintree_Vault__c(Account__c=acc.id);
        insert btVault;
        
        Contact con = new Contact(AccountId=acc.id, LastName='lname', Email='aa@test.com', Phone='123'); 
        insert con;
        
        acc.Primary_contact__c = con.id;
        acc.Finance_contact__c = con.id;
        update acc;
        
        Opportunity opp = new Opportunity(Name='Test', AccountId=acc.id, Campaign_Name__c='Campaign', StageName='StageName', CloseDate=System.today() ); 
        insert opp;
        
        lstInv = new List<Invoices__c>(); 
        for(Integer i=0; i<5; i++){
            Invoices__c inv = new Invoices__c();
            inv.Account__c=acc.Id;
            inv.Opportunity__c=opp.Id;
            inv.Invoice_Amount__c = 100;
            inv.Invoice_Date__c = System.today();
            lstInv.add(inv);
        } 
        insert lstInv;  
    }
    
    static testMethod void testInvoicesPayment(){
        setupdata();
        Pagereference pageRef=Page.InvoicesPayment; 
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', acc.id);
        
        Apexpages.StandardSetcontroller stdSetCon =new ApexPages.StandardSetcontroller(lstInv); 
        stdSetCon.setSelected(lstInv);
        InvoicesPayment contr = new InvoicesPayment(stdSetCon);
        contr.synInvoicesFromFiqas();
        //system.assert(contr.lstDtoInv.isEmpty()==false); // invoices are displayed and use can edit toPay
        contr.lstDtoInv[0].toPay = contr.lstDtoInv[0].inv.Invoice_Amount__c-1; // part pay for the first inv
        contr.gotoPaymentPage();
        
        // for converage
        String tem = contr.lstDtoInv[0].errMsg; 
        contr.lstDtoInv[0].toPay = contr.lstDtoInv[0].inv.Invoice_Amount__c+1; // the pay amount is grater then due amount, invalid.
        contr.gotoPaymentPage();
        ApexPages.currentPage().getParameters().put('invid', contr.lstDtoInv[0].inv.id);
        contr = new InvoicesPayment(stdSetCon); 
    }
    
    static testMethod void testInvoicesPaymentMethodsPopup(){
        setupdata();
        Pagereference pageRef=Page.InvoicesPaymentMethodsPopup; 
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('accId', acc.id);
        ApexPages.currentPage().getParameters().put('refurl', acc.id);
        String strInvsWithPayAmount = lstInv[0].id+'=1,'+lstInv[1].id+'='+lstInv[1].Invoice_Amount__c;
        ApexPages.currentPage().getParameters().put('strInvsWithPayAmount', strInvsWithPayAmount);
         
        InvoicesPaymentMethodsPopup contr = new InvoicesPaymentMethodsPopup(); 
        contr.doPayByCard();
        contr.paymentId = btVault.id;
        contr.doTransaction(); 
        
        Set<String> invIDs = new Set<String>();
        for(InvoicesPayment.DTOInv dto : contr.lstDtoInv) invIDs.add(dto.inv.id);
        ErrorLog__c[] logs = [select id from ErrorLog__c where Related_Id__c in:invIDs];
        system.assertEquals(logs.size(),contr.lstDtoInv.size()); // the logs are created if success or error
        
        try{// in case test, not callout
            contr.doDeletePayment();
        }catch(Exception ex){} 
        string tem = contr.paypal_email;
        
        
    }
}