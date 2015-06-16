/**
*@Author : SPP
*@Date : 14/08/2014
*@Business : 

coming from : EchoSignServices.class


* webservice entry to generate 
* Agreement Template
* PDF
* schedule in 2 minutes the push to echo sign for signature
*/
global class WSEchoSignAuto {
    
    // opp record type : Campaign_Delivery_M,  Campaign Delivery (M)
    //public static String Campaign_Delivery_M ='012g00000004TUSAA2';
    
    webservice static void sendEchoSignEmail(Id oppId){

        // create the mandate and link to the opp
        WSInsertMandate.insertMandate(oppId,'OPP');

        // reselect the opp     
        Opportunity opp =  [Select Id, Campaign_Start__c, Direct_Debit_Mandate__r.I_O_Display__c, Name,IOnumber__c,Approval_Status__c,Primary_Contact__c,Direct_Debit_Mandate__c,
                                Direct_Debit_Mandate__r.Mandate_Status__c, Primary_Contact__r.FirstName, Owner.Firstname, 
                                Owner.Phone, StageName, IsWon, IsClosed, CloseDate, Amount, AccountId, Account.Name, 
                                RecordTypeId, RecordType.DeveloperName, Payment_Method__c,Account.Apply_VAT__c,Total_Discount_Check__c,
                                Owner.Email,Primary_contact_email__c  
                                from Opportunity where Id =: oppId];

        // we only do it for opp with record type 012g00000004TUSAA2
        //if(opp.RecordTypeId == Campaign_Delivery_M){
                                
                //create greeting and attachment
            Id agreementTemplateId = createAgreementAndAttachPDF(opp);
            
    
            //create a scheduled job to run at time "nbOfMinutes" later     
            String jobName = 'Echosign Send Agreement Job_' + oppId;
        
            DateTime d = DateTime.now().addMinutes(1);
            String cronExpression = (d.second()+' '+d.minute()+' '+d.hour()+' '+d.day()+ ' '+d.month()+' ? '+d.year());
            
            if (!Test.isRunningTest()) {
                Id theJobId = System.schedule(jobName, cronExpression, new EchosignAutoScheduler(agreementTemplateId,opp.Id));
            }
    
        //}

        
    }
    
    /**
    * Create the agrement Template
    */
     private static Id createAgreementAndAttachPDF(Opportunity opp)
    {
        if (SF_Gumtree_SOW_001.valueIsNull(opp.Primary_Contact__c))
        {
            return null;
        }
        if (!opp.Approval_Status__c)
        {
            return null;
        }
        
        String pageName = Utils.getPdfPagenameForEchoSign(opp);
        PageReference pdf = new PageReference(pageName);
        
        // Take the PDF content
        // Blob 
        Blob b = null;
        if (CloneOpportunity_GT.IS_TEST)
        {
            b = Blob.valueof('test pdf contents');
        }
        else
        {
            b = pdf.getContent();  
        }
        
       
       	// create the agreement template
        Id agreementTemplateId = Utils.createEchoSignAgreementTemplate(opp);          
       
        Attachment attachment = new Attachment();
        attachment.Description = 'Attachment created from opportunity through VF';
        attachment.ParentId = opp.Id;
        attachment.Body = b;
        attachment.Name = 'Gumtree for Business I/O No. '+ opp.IOnumber__c+'.pdf';
        insert attachment;
        
        return agreementTemplateId;
        
    }
    
    
    @isTest(SeeAllData=true)
    static void test1() {


            // use one existing account
            Account acc = new Account();
            acc.Name = 'Test Account 1'; 
            acc.BillingStreet = 'Fake Street';
            acc.BillingCity = 'Fake City';
            acc.BillingState = 'London';
            acc.BillingPostalCode = '123'; 
            acc.BillingCountry = 'GB';
            insert acc;
        
            // new contact
            Contact con=new Contact();
            con.LastName='TestContact';
            con.AccountId=acc.Id;
            con.Fax='1234567';
            con.Email='Test@test.com';
            con.MobilePhone='1346975';

            insert con;
    
            Product2 prod = new Product2(
                Name='ApexTestProd',
                IsActive=true);
            insert prod;
    
            Pricebook2 pb = [select Id from Pricebook2 where IsStandard=true limit 1];
    
            PricebookEntry pbe = new PricebookEntry(
                UseStandardPrice=false,
                Product2Id=prod.Id,
                Pricebook2Id=pb.Id,
                UnitPrice=1.00,
                IsActive=true);
            insert pbe;
    
            Opportunity opp = new Opportunity(
                Name='Test Opp',
                Probability=100,
                StageName='Contract',
                CloseDate=System.today(),
                Payment_Method__c='Direct Debit',
                //RecordTypeId = '012g00000004TUSAA2',
                Primary_Contact__c = con.Id,
                Approval_Status__c =true,
                Pricebook2Id=pb.Id);
                
            insert opp;
            
            // Start testing
            CloneOpportunity_GT.IS_TEST = true;
            sendEchoSignEmail(opp.Id);

     }
     
      @isTest(SeeAllData=true)
    static void test2() {


            // use one existing account
            Account acc = new Account();
            acc.Name = 'Test Account 1'; 
            acc.BillingStreet = 'Fake Street';
            acc.BillingCity = 'Fake City';
            acc.BillingState = 'London';
            acc.BillingPostalCode = '123'; 
            acc.BillingCountry = 'GB';
            insert acc;
        
            // new contact
            Contact con=new Contact();
            con.LastName='TestContact';
            con.AccountId=acc.Id;
            con.Fax='1234567';
            con.Email='Test@test.com';
            con.MobilePhone='1346975';

            insert con;
    
            Product2 prod = new Product2(
                Name='ApexTestProd',
                IsActive=true);
            insert prod;
    
            Pricebook2 pb = [select Id from Pricebook2 where IsStandard=true limit 1];
    
            PricebookEntry pbe = new PricebookEntry(
                UseStandardPrice=false,
                Product2Id=prod.Id,
                Pricebook2Id=pb.Id,
                UnitPrice=1.00,
                IsActive=true);
            insert pbe;
    
            Opportunity opp = new Opportunity(
                Name='Test Opp',
                Probability=100,
                StageName='Contract',
                CloseDate=System.today(),
               // RecordTypeId = '012g00000004TUSAA2',
                Primary_Contact__c = con.Id,
                Approval_Status__c =true,
                Pricebook2Id=pb.Id);
                
            insert opp;
            
            // Start testing
            CloneOpportunity_GT.IS_TEST = true;
            sendEchoSignEmail(opp.Id);

     }
     
       @isTest(SeeAllData=true)
    static void test3() {


            // use one existing account
            Account acc = new Account();
            acc.Name = 'Test Account 1'; 
            acc.BillingStreet = 'Fake Street';
            acc.BillingCity = 'Fake City';
            acc.BillingState = 'London';
            acc.BillingPostalCode = '123'; 
            acc.BillingCountry = 'GB';
            insert acc;
        
            // new contact
            Contact con=new Contact();
            con.LastName='TestContact';
            con.AccountId=acc.Id;
            con.Fax='1234567';
            con.Email='Test@test.com';
            con.MobilePhone='1346975';

            insert con;
    
            Product2 prod = new Product2(
                Name='ApexTestProd',
                IsActive=true);
            insert prod;
    
            Pricebook2 pb = [select Id from Pricebook2 where IsStandard=true limit 1];
    
            PricebookEntry pbe = new PricebookEntry(
                UseStandardPrice=false,
                Product2Id=prod.Id,
                Pricebook2Id=pb.Id,
                UnitPrice=1.00,
                IsActive=true);
            insert pbe;
    
            Opportunity opp = new Opportunity(
                Name='Test Opp',
                Probability=100,
                StageName='Contract',
                CloseDate=System.today(),
                Payment_Method__c='Direct Debit',
               // RecordTypeId = '012g00000004TUSAA2',
                Primary_Contact__c = con.Id,
                Approval_Status__c =true,
                Pricebook2Id=pb.Id);
                
            insert opp;
            
            // Start testing
            CloneOpportunity_GT.IS_TEST = true;
            sendEchoSignEmail(opp.Id);

     }
    
}