@isTest
private class LineChartOpportunityTestMethod {

   public static testMethod void testLineChartOpportunity(){
            Profile p=[Select Id From Profile Where Name='System Administrator' or Name='Systemadministrator' Limit 1];
             User u=new User(Username='testUser1@boco.com',LastName='testLastName1',Email='testEmail1@boco.com',Alias='test1',CommunityNickname='testCommun1',
                        TimeZoneSidKey='Pacific/kiritimati',LocaleSidKey='ar',EmailEncodingKey='UTF-8',ProfileId=p.Id,LanguageLocaleKey='en_US');
        
             insert u;
             
              System.runAs(u){
                         
                  Account acc = new Account(Name='Test Account RS', BillingStreet='12345', BillingCity='Test', Phone='12456796', BillingCountry='GB', BillingPostalCode='134697', BillingState='test');
                 insert acc;        

                  Opportunity  opp = new Opportunity(name='Test', AccountId = acc.id, closeDate= system.today(), stageName='test');
                  insert opp;
                    
                  Product2  pro = new Product2 (name ='test');
                  insert pro;             
                    
                  PriceBook2 pb2Standard = [select Id from Pricebook2 where isStandard=true];
            
                  PricebookEntry pbe = new PricebookEntry(Pricebook2Id= pb2Standard.Id, Product2Id=pro.Id, UnitPrice=99, isActive=true);
                  insert pbe;
                    
                  OpportunityLineItem oppItem = new OpportunityLineItem( PriceBookEntryId=pbe.Id,OpportunityId=opp.id, Quantity = 1, TotalPrice=100.0, from_Date__c=date.today(), until_Date__c=date.today()+1, Rate_Discount_I__c = 0.0, Rate_Discount_II__c = 0.0);
                  insert oppItem;
                   
                  Revenue2__c re = new Revenue2__c( LineItemId__c =oppItem.id ,Billing_Category__c='CPM', Sales_Price__c = 10 , Discount_I__c = 1, Discount_II__c = 2, Product_Enddate__c = (system.today()+4) , Product_Startdate__c = system.today() );
                  insert re;
                    
                  List<Revenue_Schedule_daily2__c> lstRevenu = new List<Revenue_Schedule_daily2__c>();
                  lstRevenu.add( new Revenue_Schedule_daily2__c(Opportunity__c= opp.id ,  OSI_RSD__c= 25 ,  Invoice_Quantity__c =10 , Revenue2__c=re.id, Product__c = pro.id, Day__c= (system.today()+4) ) );
                  lstRevenu.add( new Revenue_Schedule_daily2__c(Opportunity__c= opp.id ,  OSI_RSD__c= 25 ,  Invoice_Quantity__c =10 , Revenue2__c=re.id,  Product__c = pro.id, Day__c=  (system.today()+4) ));
                  
                  insert lstRevenu;
                  
                  Test.startTest();
                    Apexpages.Standardcontroller setCon = new Apexpages.Standardcontroller( opp );
                    LineChartOpportunityPageController chtterCon =  new LineChartOpportunityPageController(setCon);
                  
                  Test.stopTest();
               
                
              }
   }


}