/**

GTCRM-222 - Automate client reporting for AdSales

Change log:
- 

**/

@isTest(SeeAllData=true)
private class ExcelReportTest {
    
    static UserRole role1 = new UserRole(Name='UK-test advertising');
    
    static testMethod void myUnitTest() {
        
        User usr = [Select id from User where Id = :UserInfo.getUserId()];
      System.RunAs(usr){
      insert role1;//run DML of setup obj in different context
      }
       
        //create account
        Account acc = new Account(Name='Test Account 1', 
        						  BillingStreet='81 Melton Road,', 
        						  BillingState='Nottingham', 
        						  BillingPostalCode='NG2 6EN', 
        						  BillingCountry='GB', 
        						  BillingCity='West Bridgford');
        insert acc;
        
        //get standard price book========
        Pricebook2 pb = [select id from Pricebook2 where IsStandard = true limit 1];  
        
        
        // create products========== 
        Product2 p1 = new Product2(
            name='Test Product 1',          
//            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
            RecordTypeId=ExcelReportHelper.getRecordTypeId(ExcelReportHelper.PRO_RECORD_TYPE_PACKAGE));
            //packege
        
        insert p1;
        Product2 p2 = new Product2(name='Test Product 2');          
            //urrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR
            //will be sub-item of packege p1
        
        Product2 p3 = new Product2( name='Test Product 3');          
//            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR
            //not sub item
        
        List<Product2>listP = new List<Product2>{p2,p3};
        insert listP; 
        
        // create pricebookentreis==========
        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id=pb.id,
            Product2Id=p1.id,
            UnitPrice=0.9,
            isActive=true);
//            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR
        
        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id=pb.id,
            Product2Id=p2.id,
            UnitPrice=0.9,
            isActive=true);
//            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR
        
        PricebookEntry pbe3 = new PricebookEntry(
            Pricebook2Id=pb.id,
            Product2Id=p3.id,
            UnitPrice=0.9,
            isActive=true);
//            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR
        
        List<PricebookEntry>listPBE = new List<PricebookEntry>{pbe1,pbe2,pbe3};
        insert listPBE; 
        
        //create profile for user===========
        Profile profile = [Select id from Profile limit 1];
        
         
        //create user for opportunity=========
        User user1 =new User(
                Username='user3478test@test.com',
                LastName='user1test',
                Alias='SFDC2',
                CommunityNickname='ktang2test',
                TimeZoneSidKey='Atlantic/Cape_Verde',
                LocaleSidKey='en_GB',
                EmailEncodingKey='ISO-8859-1',
                ProfileId=profile.id, 
                LanguageLocaleKey='de',
                Email='user1@test.com');
//                Sales_Team__c='AT'//,
                //UserRoleId=role1.id
                     
        System.RunAs(usr){
          insert user1;
        }
        
        // create an opportunity==========
        Opportunity opp1 = new Opportunity(
            name='Test Opp 1',
            AccountId=acc.id,
            Type='Existing Business',
//            Product_line__c='Adsales (10046)',
//            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
            CloseDate=Date.valueOf('2013-4-13'),
            StageName='Initial Offer (w/o request)',
            Reporting_Active__c=true,
            Internal_Only__c=false,
            Report_Language__c=ExcelReportHelper.REPORT_LANGUAGE_EN,
            Interval__c=ExcelReportHelper.INTERVAL_WEEKLY,
            Weekday__c=ExcelReportHelper.WEEKDAY_TUE,
            Additional_Columns__c=ExcelReportHelper.ADDITIONAL_COL,
            OwnerId=user1.id,
            Final_Reporting__c=false
        );
        Opportunity opp2 = new Opportunity(
            name='Test Opp 2',
            AccountId=acc.id,
            Type='Existing Business',
//            Product_line__c='Adsales (10046)',
//            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
            CloseDate=Date.valueOf('2013-4-13'),
            StageName='Initial Offer (w/o request)',
            Reporting_Active__c=true,
            Internal_Only__c=true,
            Report_Language__c=ExcelReportHelper.REPORT_LANGUAGE_EN,
            Interval__c=ExcelReportHelper.INTERVAL_MONTHLY,
            //Weekday__c=ExcelReportHelper.WEEKDAY_TUE,
            Additional_Columns__c=ExcelReportHelper.ADDITIONAL_COL,
            OwnerId=user1.id,
            Final_Reporting__c=false
        );
        Opportunity opp3 = new Opportunity(
            name='Test Opp 3',
            AccountId=acc.id,
            Type='Existing Business',
//            Product_line__c='Adsales (10046)',
//            CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
            CloseDate=Date.valueOf('2013-4-13'),
            StageName='Initial Offer (w/o request)',
            Reporting_Active__c=true,
            Internal_Only__c=false,
            Report_Language__c=ExcelReportHelper.REPORT_LANGUAGE_EN,
            Interval__c=ExcelReportHelper.INTERVAL_WEEKLY,
            Weekday__c=ExcelReportHelper.WEEKDAY_TUE,
            Additional_Columns__c=ExcelReportHelper.ADDITIONAL_COL,
            OwnerId=user1.id,
            Final_Reporting__c=false
        );
        List<Opportunity> listOpp= new List<Opportunity>{opp1,opp2,opp3};
        insert listOpp;
        
        //trace relation form lineItems to Revenue_Schedule_daily2__c ==================
        Revenue2__c r1 = new Revenue2__c();
        Revenue2__c r2 = new Revenue2__c();
        Revenue2__c r3 = new Revenue2__c();
        Revenue2__c r4 = new Revenue2__c();
        List<Revenue2__c> listR =new List<Revenue2__c>{r1,r2,r3,r4};
        insert listR;
        
        // add line items========================
        OpportunityLineItem oli1 = new OpportunityLineItem(
                            PricebookEntryId = pbe1.id,//contain p1
                            OpportunityId = opp1.id,
                            from_Date__c=Date.valueOf('2013-4-13'),
                            until_Date__c=Date.valueOf('2014-4-13'),
                            Billing_category__c=ExcelReportHelper.BILL_CAT_FIXPRICE,
                            Quantity=555,
                            TotalPrice=999,
                            Revenue2__c=r1.id);
                            //package_line_item__c=ExcelReportHelper.PRO_RECORD_TYPE_PACKAGE //must package because p1 is packege
              
        OpportunityLineItem oli2 = new OpportunityLineItem(
                            PricebookEntryId = pbe2.id,//contain p2
                            OpportunityId = opp1.id,
                            from_Date__c=Date.valueOf('2013-4-13'),
                            until_Date__c=Date.valueOf('2014-8-13'),
                            Billing_category__c=ExcelReportHelper.BILL_CAT_CPC,
                            Quantity=555,
                            TotalPrice=999,
                            Revenue2__c=r2.id);
                            //package_line_item__c=p1.id//must be id of p1 because p2 is sub-item in package p1
         
        OpportunityLineItem oli3 = new OpportunityLineItem(
                            PricebookEntryId = pbe3.id,
                            OpportunityId = opp1.id,
                            from_Date__c=Date.valueOf('2013-4-13'),
                            until_Date__c=System.Today().addDays(-2),
                            Billing_category__c=ExcelReportHelper.BILL_CAT_CPM,
                            Quantity=555,
                            TotalPrice=999,
                            Revenue2__c=r3.id,
                            package_line_item__c=null
        );  
        OpportunityLineItem oli4 = new OpportunityLineItem(
                            PricebookEntryId = pbe3.id,
                            OpportunityId = opp1.id,
                            from_Date__c=Date.valueOf('2013-3-13'),
                            until_Date__c=Date.valueOf('2015-3-19'),
                            Billing_category__c=ExcelReportHelper.BILL_CAT_CPO,
                            Quantity=555,
                            TotalPrice=999,
                            Revenue2__c=r4.id,
                            package_line_item__c=null
        );
        OpportunityLineItem oli5 = new OpportunityLineItem(//for opp2
                            PricebookEntryId = pbe3.id,
                            OpportunityId = opp2.id,
                            from_Date__c=Date.valueOf('2013-4-13'),
                            until_Date__c=Date.valueOf('2013-7-13'),
                            Billing_category__c=ExcelReportHelper.BILL_CAT_CPM,
                            Quantity=555,
                            TotalPrice=999,
                            Revenue2__c=r3.id,
                            package_line_item__c=null
        );             

        List<OpportunityLineItem> listOppLineItem = new List<OpportunityLineItem>{oli1,oli2,oli3,oli4,oli5}; 
        //List<OpportunityLineItem> listOppLineItem = new List<OpportunityLineItem>{oli3,oli4,oli5};
        insert listOppLineItem;
        
        //add contact for OpportunityContactRole==========
        Contact con1=new Contact(
                        LastName='Test Contact 1',
                        Email='test1@test.com');
//                        CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR 
        
        Contact con2=new Contact(
                        LastName='Test Contact 2',
                        Email='test2@test.com');
//                        CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR 
        
        List<Contact> listContact = new List<Contact>{con1,con2}; 
        insert listContact;
        
        //add OpportunityContactRole============
        OpportunityContactRole ocr1 = new OpportunityContactRole(
                                            OpportunityId=opp1.id,
                                            ContactId=con1.id,
                                            Role=ExcelReportHelper.CONTACT_ROLE_REPORT_RECEIVER,
                                            IsPrimary=false
        );
        OpportunityContactRole ocr2 = new OpportunityContactRole(
                                            OpportunityId=opp1.id,
                                            ContactId=con2.id,
                                            Role=ExcelReportHelper.CONTACT_ROLE_OTHER,
                                            IsPrimary=true
        );
        OpportunityContactRole ocr3 = new OpportunityContactRole(//for opp2
                                            OpportunityId=opp2.id,
                                            ContactId=con2.id,
                                            Role=ExcelReportHelper.CONTACT_ROLE_OTHER,
                                            IsPrimary=true
        );
        OpportunityContactRole ocr4 = new OpportunityContactRole(//for opp2
                                            OpportunityId=opp3.id,
                                            ContactId=con2.id,
                                            Role=ExcelReportHelper.CONTACT_ROLE_OTHER,
                                            IsPrimary=true
        );
        List<OpportunityContactRole> listContRole = new List<OpportunityContactRole>{ocr1,ocr2,ocr3,ocr4};
        insert listContRole;
        
        //add RSD2 ===============================
        Revenue_Schedule_daily2__c rsd1 = new Revenue_Schedule_daily2__c(
                                    Opportunity__c=opp1.id,
                                    Revenue2__c=r1.id,
//                                    CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
                                    Delivered_AI__c=1,
                                    Clicks_Recorded__c=1,
                                    Day__c=Date.valueOf('2013-4-13')
        );
        Revenue_Schedule_daily2__c rsd2 = new Revenue_Schedule_daily2__c(
                                    Opportunity__c=opp1.id,
                                    Revenue2__c=r2.id,
//                                    CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
                                    Delivered_AI__c=1,
                                    Clicks_Recorded__c=1,
                                    Day__c=Date.valueOf('2013-4-13')
        );
        Revenue_Schedule_daily2__c rsd3 = new Revenue_Schedule_daily2__c(
                                    Opportunity__c=opp1.id,
                                    Revenue2__c=r3.id,
//                                    CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
                                    Delivered_AI__c=1,
                                    Clicks_Recorded__c=1,
                                    Day__c=Date.valueOf('2013-4-13')
        );
        Revenue_Schedule_daily2__c rsd4 = new Revenue_Schedule_daily2__c(
                                    Opportunity__c=opp1.id,
                                    Revenue2__c=r4.id,
//                                    CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
                                    Delivered_AI__c=1,
                                    Clicks_Recorded__c=1,
                                    Day__c=Date.valueOf('2013-4-13')
        );
        Revenue_Schedule_daily2__c rsd5 = new Revenue_Schedule_daily2__c( //for opp2
                                    Opportunity__c=opp2.id,
                                    Revenue2__c=r4.id,
//                                    CurrencyIsoCode=ExcelReportHelper.CURRENCY_ISO_EUR,
                                    Delivered_AI__c=1,
                                    Clicks_Recorded__c=1,
                                    Day__c=Date.valueOf('2013-4-13')
        );
        List<Revenue_Schedule_daily2__c> listRSD = new List<Revenue_Schedule_daily2__c>{rsd1,rsd2,rsd3,rsd4,rsd5};
        insert listRSD;  
        
        
        
        Test.startTest();//============Start test================
        
        
          //Case:=====3.1. Manual Execution Report=============
          ExcelReport excel = new ExcelReport(opp1.id);
          system.assertEquals(3, excel.listMapColumnValue.size());//number of row in summery sheet (OpportunityLineItem oli3)  ----1--
          system.assertEquals(6, excel.listMapColumnValueDetail.size());//number of row in summery sheet (1 record + 1 Total row =2)  ----2---
          
          
          //Case:=====3.2. Manual Execution Mail and Report=============
          //opp1
          ExcelReportEmail mail1 = new ExcelReportEmail(opp1.id);
          system.assertEquals('test1@test.com', mail1.toAddress);//this user's role is report reveiver
          system.assertEquals('user1@test.com', mail1.ccAddress);//this user is opp owner
          system.assertNotEquals(null, mail1.bodyEmail);
          mail1.sendMail();
          //opp2
          ExcelReportEmail mail2 = new ExcelReportEmail(opp2.id);//report=internal_only, language=EN, interval=monthly
          system.assertEquals('user1@test.com', mail2.toAddress);//To address is sent to opp owner
          mail2.sendMail();
          
          ExcelReportEmail mail3 = new ExcelReportEmail(opp3.id);
          
          //Case:=====3.3. Automatic Execution=============
          ExcelReportScheduler schedule = new ExcelReportScheduler();
          SchedulableContext SC;
          schedule.execute(SC); 
          
        
        Test.stopTest();//============Stop test=================
    } 
   
}