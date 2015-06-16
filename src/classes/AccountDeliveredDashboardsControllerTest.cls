/*

Change log; 
- 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level

*/

public class AccountDeliveredDashboardsControllerTest {

    static Account makeNewAccount() {
        Account newAcct = new Account();
        newAcct.Name = 'Test Account 1'; 
        newAcct.BillingStreet = 'Fake Street'; newAcct.BillingCity = 'Fake City';
        newAcct.BillingState = 'London'; newAcct.BillingPostalCode = '123'; newAcct.BillingCountry = 'GB';
        insert newAcct;
        
        Contact con=new Contact();
                        con.LastName='TestContact';
                        con.AccountId=NewAcct.Id;
                        con.Fax='1234567';
                        con.Email='Test@test.com';
                        con.MobilePhone='1346975';

                        insert con;
        
        newAcct.Primary_contact__c = con.id;
        newAcct.Finance_contact__c = con.id;
        update newAcct;
                        
        return newAcct;
    }

    static testMethod void testClosedSalesAmountYoY() {
        Account newAcct = makeNewAccount();
        
        AccountDeliveredDashboardsController addc = new AccountDeliveredDashboardsController(newAcct);
        String beforeString = addc.getClosedSalesAmountYoY();
        
        // Add new oppty - this should change the graph
        Opportunity newOppty = new Opportunity();
        newOppty.Name = 'Test Oppty #1';
        newOppty.AccountId = newAcct.Id;
        newOppty.CloseDate = Date.today();
        newOppty.Amount = 11111;
        newOppty.P_O_Number__c = '123';
        newOppty.StageName = [SELECT MasterLabel FROM OpportunityStage WHERE IsWon = TRUE AND IsActive = TRUE LIMIT 1].MasterLabel;
        // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
        newOppty.Signed_contract_attached__c = true;
        insert newOppty;
        
        // Create test product to add to oppty later
        Product2 newProduct = new Product2();
        newProduct.Name = 'Test Widget';
        newProduct.Family = 'Widgets';
        insert newProduct;

        // Create a pricebook
        //Pricebook2 pb = new Pricebook2();
        //pb.Name = 'Custom Pricebok';
        //pb.IsActive = TRUE;
        //insert pb;
        
        // Create pricebook entry
        PricebookEntry pbe = new PricebookEntry();
        pbe.IsActive = TRUE;
        pbe.Pricebook2Id = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1].Id;
        pbe.Product2Id = newProduct.Id;
        pbe.UnitPrice = 5555;
        pbe.UseStandardPrice = FALSE;
        insert pbe;
        
        OpportunityLineItem newOLI = new OpportunityLineItem();
        newOLI.PricebookEntryId = pbe.Id;
        newOLI.Description= 'Test Oppty #1';
        newOLI.Ad_Name__c = 'abc';
        newOLI.OpportunityId = newOppty.Id;
        newOLI.from_Date__c = Date.today();
        newOLI.until_Date__c = Date.today()+5;
        newOLI.Billing_Category__c = 'CPM';
        newOLI.Quantity = 100000;
        newOLI.UnitPrice = 3;
        newOLI.Net_Net_Net__c = 300;
        insert newOLI;
        
        Revenue2__c newR = new Revenue2__c();
        newR.Billing_Category__c = 'CPM';
        newR.Booked_Quantity__c = 100000;
        newR.Product_Startdate__c = Date.today();
        newR.Product_Enddate__c = Date.today()+5;
        newR.Sales_Price__c = 3;
        newR.Net_Net_Net__c = 300;
        newR.Opportunity__c = newOppty.id;
        insert newR;
               
        newOLI.Revenue2__c = newR.id;
        update newOLI;
        
        Revenue_Schedule2__c newRS = new Revenue_Schedule2__c();
        newRS.Revenue2__c = newR.id;
        newRS.Delivered_AI__c = 100000;
        newRS.Delivered_Sum__c = 100000;
        newRS.Invoice_Quantity__c = 100000;
        newRS.Opportunity__c = newOppty.id;
        insert newRS;
        
        String afterString = addc.getClosedSalesAmountYoY();
        System.assert(!(beforeString.equals(afterString)));
    }

    static testMethod void testClosedSalesAmountMoM() {
        Account newAcct = makeNewAccount();
        
        AccountDeliveredDashboardsController addc = new AccountDeliveredDashboardsController(newAcct);
        String beforeString = addc.getClosedSalesAmountMoM();
        
      // Add new oppty - this should change the graph
        Opportunity newOppty = new Opportunity();
        newOppty.Name = 'Test Oppty #1';
        newOppty.AccountId = newAcct.Id;
        newOppty.CloseDate = Date.today();
        newOppty.Amount = 11111;
        newOppty.P_O_Number__c = '123';
        newOppty.StageName = [SELECT MasterLabel FROM OpportunityStage WHERE IsWon = TRUE AND IsActive = TRUE LIMIT 1].MasterLabel;
        // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
        newOppty.Signed_contract_attached__c = true;
        insert newOppty;
        
        // Create test product to add to oppty later
        Product2 newProduct = new Product2();
        newProduct.Name = 'Test Widget';
        newProduct.Family = 'Widgets';
        insert newProduct;

        // Create a pricebook
        //Pricebook2 pb = new Pricebook2();
        //pb.Name = 'Custom Pricebok';
        //pb.IsActive = TRUE;
        //insert pb;
        
        // Create pricebook entry
        PricebookEntry pbe = new PricebookEntry();
        pbe.IsActive = TRUE;
        pbe.Pricebook2Id = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1].Id;
        pbe.Product2Id = newProduct.Id;
        pbe.UnitPrice = 5555;
        pbe.UseStandardPrice = FALSE;
        insert pbe;
        
        OpportunityLineItem newOLI = new OpportunityLineItem();
        newOLI.PricebookEntryId = pbe.Id;
        newOLI.Description= 'Test Oppty #1';
        newOLI.Ad_Name__c = 'abc';
        newOLI.OpportunityId = newOppty.Id;
        newOLI.from_Date__c = Date.today();
        newOLI.until_Date__c = Date.today()+5;
        newOLI.Billing_Category__c = 'CPM';
        newOLI.Quantity = 100000;
        newOLI.UnitPrice = 3;
        newOLI.Net_Net_Net__c = 300;
        insert newOLI;
        
        Revenue2__c newR = new Revenue2__c();
        newR.Billing_Category__c = 'CPM';
        newR.Booked_Quantity__c = 100000;
        newR.Product_Startdate__c = Date.today();
        newR.Product_Enddate__c = Date.today()+5;
        newR.Sales_Price__c = 3;
        newR.Net_Net_Net__c = 300;
        newR.Opportunity__c = newOppty.id;
        insert newR;
               
        newOLI.Revenue2__c = newR.id;
        update newOLI;
        
        Revenue_Schedule2__c newRS = new Revenue_Schedule2__c();
        newRS.Revenue2__c = newR.id;
        newRS.Delivered_AI__c = 100000;
        newRS.Delivered_Sum__c = 100000;
        newRS.Invoice_Quantity__c = 100000;
        newRS.Opportunity__c = newOppty.id;
        insert newRS;

        String afterString = addc.getClosedSalesAmountMoM();
        System.assert(!(beforeString.equals(afterString)));
    }

    static testMethod void testProductGraphs() {
        Account newAcct = makeNewAccount();
        
        AccountDashboardsController adc = new AccountDashboardsController(newAcct);
        String beforeAmtString = adc.getSalesAmountByProduct();
        String beforeQtyString = adc.getSalesQuantityByProduct();
        
        // Add new oppty - this should change the graph
        Opportunity newOppty = new Opportunity();
        newOppty.Name = 'Test Oppty #3';
        newOppty.AccountId = newAcct.Id;
        newOppty.CloseDate = Date.today();
        newOppty.Amount = 33333;
        newOppty.P_O_Number__C = '123';
        newOppty.StageName = [SELECT MasterLabel FROM OpportunityStage WHERE IsWon = TRUE AND IsActive = TRUE LIMIT 1].MasterLabel;
        // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
        newOppty.Signed_contract_attached__c = true;
        insert newOppty;

        // Create test product to add to oppty later
        Product2 newProduct = new Product2();
        newProduct.Name = 'Test Widget';
        newProduct.Family = 'Widgets';
        insert newProduct;

        // Create a pricebook
        //Pricebook2 pb = new Pricebook2();
        //pb.Name = 'Custom Pricebok';
        //pb.IsActive = TRUE;
        //insert pb;
        
        // Create pricebook entry
        PricebookEntry pbe = new PricebookEntry();
        pbe.IsActive = TRUE;
        pbe.Pricebook2Id = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1].Id;
        pbe.Product2Id = newProduct.Id;
        pbe.UnitPrice = 5555;
        pbe.UseStandardPrice = FALSE;
        insert pbe;
        
        // Add product to oppty
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = newOppty.Id;
        oli.PricebookEntryId = pbe.Id;
        oli.Quantity = 5;
        oli.TotalPrice = 5 * 5555;
        insert oli;

        String afterAmtString = adc.getSalesAmountByProduct();
        System.assert(!(beforeAmtString.equals(afterAmtString)));

        String afterQtyString = adc.getSalesQuantityByProduct();
        System.assert(!(beforeQtyString.equals(afterQtyString)));
    }    

}