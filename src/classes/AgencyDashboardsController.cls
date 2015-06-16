/*

Change log; 
- 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level

*/

public with sharing class AgencyDashboardsController {

    private final Account acct;
    
    // Default number of years shown on the "Account Sales, Year over Year" report
    static final Integer CLOSED_SALES_AMOUNT_YOY_YEARS_SHOWN = 5;
    
    // Default number of years shown on the "Account Sales, Month over Month" report
    static final Integer CLOSED_SALES_AMOUNT_MOM_YEARS_SHOWN = 3;

    
    public AgencyDashboardsController(ApexPages.StandardController stdController) {
        this.acct = (Account)stdController.getRecord();
    }

    // For test methods
    public AgencyDashboardsController(Account acct) {
        this.acct = acct;
    }

    // Controller to generate the data for the "Account Sales, Year over Year" chart
    public String getClosedSalesAmountYoY() {
        String id = this.acct.Id; 
        final Integer firstYear = date.today().year() - CLOSED_SALES_AMOUNT_YOY_YEARS_SHOWN + 1;
    
        AggregateResult[] groupedResults = [SELECT FISCAL_YEAR(CloseDate) YearOfSale,    
            SUM(Net_Net__c) TotalAmount FROM Opportunity 
            WHERE Agency__c = :id AND FISCAL_YEAR(CloseDate) >= :firstYear AND IsWon = TRUE
            GROUP BY FISCAL_YEAR(CloseDate) ORDER BY FISCAL_YEAR(CloseDate) ASC];

        Integer dataCount = 0;
        Integer resultCount = 0;
        String resultJS = 'data.addRows(' + CLOSED_SALES_AMOUNT_YOY_YEARS_SHOWN + ');\n';
        
        Map<String, Double> resultMap = new Map<String, Double>();
        for (AggregateResult ar : groupedResults)  {
            resultMap.put(String.valueOf(ar.get('YearOfSale')), (Double)ar.get('TotalAmount'));
        }
  
        // We need to do this so we can fill in blank values with a zero and restrict to the
        // number of years specified in the constant CLOSED_SALES_AMOUNT_YOY_YEARS_SHOWN
        Integer count = 0;
        Integer currentYear = firstYear;

        while (currentYear <= date.today().year()) {
            resultJS += 'data.setValue(' + count + ', 0, \'' +   String.valueOf(currentYear) + '\');\n';
        
            if (resultMap.get(String.valueOf(currentYear)) != null) {
                resultJS += 'data.setValue(' + count + ', 1, ' +  
                    resultMap.get(String.valueOf(currentYear)) + ');\n';

            } else {
                resultJS += 'data.setValue(' + count + ', 1, 0);\n';
            }

            count++;
            currentYear++;
        }
        return resultJS;
    }


    // Controller to generate the data for the "Account Sales, Month over Month" chart
    public String getClosedSalesAmountMoM() {
        String id = this.acct.Id;
        final Integer firstYear = date.today().year() - CLOSED_SALES_AMOUNT_MOM_YEARS_SHOWN + 1;
    
        AggregateResult[] groupedResults = [SELECT FISCAL_MONTH(CloseDate) MonthOfSale,
            FISCAL_YEAR(CloseDate) YearOfSale,    
            SUM(Net_Net__c) TotalAmount FROM Opportunity 
            WHERE Agency__c = :id AND FISCAL_YEAR(CloseDate) >= :firstYear AND IsWon = TRUE
            GROUP BY FISCAL_MONTH(CloseDate), FISCAL_YEAR(CloseDate) 
            ORDER BY FISCAL_MONTH(CloseDate), FISCAL_YEAR(CloseDate)];

        Integer dataCount = 0;
        Integer resultCount = 0;
        
        Map<String, Double> resultMap = new Map<String, Double>();
        for (AggregateResult ar : groupedResults)  {

            resultMap.put(String.valueOf(ar.get('YearOfSale')) + '/' + String.valueOf(ar.get('MonthOfSale')), 
                (Double)ar.get('TotalAmount'));
        }
        
        Map<String, Double> dataMap = new Map<String, Double>();
        Integer currentYear = firstYear;
        Integer currentMonth = 1;

        String resultJS = 'data.addColumn(\'string\', \'Month\');\n';

        while (currentYear <= date.today().year()) {
            resultJS += 'data.addColumn(\'number\', \'' + currentYear + '\');\n';
            currentYear++;
        }

        Boolean isFirstRow = true;
        resultJS += 'data.addRows([';

        // We need to do this so we can fill in blank values with a zero and restrict to the
        // number of years specified in the constant CLOSED_SALES_AMOUNT_MOM_YEARS_SHOWN
        while (currentMonth < 13) {
            currentYear = firstYear;
            Integer yearCount = 1;

            if (isFirstRow == false) {
                resultJS += ',';
            }
            isFirstRow = false;

            resultJS += '\n[\'' + currentMonth + '\'';

            while (currentYear <= date.today().year()) {

                if (resultMap.get(String.valueOf(currentYear) + '/' + String.valueOf(currentMonth)) != null) {
    
                    resultJS += ', ' + resultMap.get(String.valueOf(currentYear) + '/' + String.valueOf(currentMonth));
                } else {
                    resultJS += ', 0';
                }
                
                yearCount++;
                currentYear++;
            }

            resultJS += ']\n';
            currentMonth++;
        }

        resultJS += ']);';

        return resultJS;
    }
    
/*    // Controller to generate the data for the "Sales Amount by Product Family" chart
    public String getSalesAmountByProduct() {
        String id = this.acct.Id;
        String result = '';
        Map<String, Double> salesByProductFamily = new Map<String, Double>();

        // Get all opportunity line items for all Opportunities associated with this account
        // (can't query OpportunityLineItems directly) and tally them up by product family
        for (Opportunity thisOppty : [SELECT Id, Net_Net__c, (SELECT Quantity, TotalPrice, PricebookEntry.product2.Family 
            FROM OpportunityLineItems) FROM Opportunity WHERE Opportunity.Agency__c = :id AND IsWon = TRUE]) {
        
            for (OpportunityLineItem oli : thisOppty.OpportunityLineItems) {
        
                if (salesByProductFamily.get(oli.PricebookEntry.product2.Family) != null) {
                    salesByProductFamily.put(oli.PricebookEntry.product2.Family, 
                        salesByProductFamily.get(oli.PricebookEntry.product2.Family) + oli.TotalPrice);
                } else {
                    salesByProductFamily.put(oli.PricebookEntry.product2.Family, oli.TotalPrice);
                }
            }
        }
        
        result += 'data.addRows(' + salesByProductFamily.keySet().size() + ');\n';
        
        Integer count = 0;
        for (String productFamily : salesByProductFamily.keySet()) {
            result += 'data.setValue(' + count + ', 0, \'' + productFamily + '\');\n';
            result += 'data.setValue(' + count + ', 1, ' + salesByProductFamily.get(productFamily) + ');\n';
            count++;
        }
        
        return result;
    }

    // Controller to generate the data for the "Sales Quantity by Product Family" chart
    public String getSalesQuantityByProduct() {
        String id = this.acct.Id;
        String result = '';
        Map<String, Double> qtyByProductFamily = new Map<String, Double>();

        // Get all opportunity line items for all Opportunities associated with this account
        // (can't query OpportunityLineItems directly) and tally them up by product family
        for (Opportunity thisOppty : [SELECT Id, Net_Net__c, (SELECT Quantity, TotalPrice, PricebookEntry.product2.Family 
            FROM OpportunityLineItems) FROM Opportunity WHERE Opportunity.Agency__c = :id AND IsWon = TRUE]) {
        
            for (OpportunityLineItem oli : thisOppty.OpportunityLineItems) {
        
                if (qtyByProductFamily.get(oli.PricebookEntry.product2.Family) != null) {
                    qtyByProductFamily.put(oli.PricebookEntry.product2.Family, 
                        qtyByProductFamily.get(oli.PricebookEntry.product2.Family) + oli.Quantity);
                } else {
                    qtyByProductFamily.put(oli.PricebookEntry.product2.Family, oli.Quantity);
                }
            }
        }
        
        result += 'data.addRows(' + qtyByProductFamily.keySet().size() + ');\n';
        
        Integer count = 0;
        for (String productFamily : qtyByProductFamily.keySet()) {
            result += 'data.setValue(' + count + ', 0, \'' + productFamily + '\');\n';
            result += 'data.setValue(' + count + ', 1, ' + qtyByProductFamily.get(productFamily) + ');\n';
            count++;
        }
        
        return result;
    }
*/

@isTest (seeAllData=true)
public static void testClosedSalesAmountYoY() {
        Account newAcct = new Account();
        newAcct.Name = 'Test Account Agcy1'; 
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
                                       
        AgencyDashboardsController adc = new AgencyDashboardsController(newAcct);
        String beforeString = adc.getClosedSalesAmountYoY();
        
        // Add new oppty - this should change the graph
        Opportunity newOppty = new Opportunity();
        newOppty.Name = 'Test Oppty #1';
        newOppty.AccountId = newAcct.Id;
        newOppty.Agency__c = newAcct.Id;
        newOppty.CloseDate = Date.today();
        newOppty.Amount = 11111;
        newOppty.P_O_Number__c = '123';
        newOppty.StageName = [SELECT MasterLabel FROM OpportunityStage WHERE IsWon = TRUE AND IsActive = TRUE LIMIT 1].MasterLabel;
        // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
        newOppty.Signed_contract_attached__c = true;
        insert newOppty;
        
        String afterString = adc.getClosedSalesAmountYoY();
        System.assert(!(beforeString.equals(afterString)));
    }

@isTest (seeAllData=true)
    public static void testClosedSalesAmountMoM() {
        Account newAcct = new Account();
        newAcct.Name = 'Test Account Agcy1'; 
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
                               
        AgencyDashboardsController adc = new AgencyDashboardsController(newAcct);
        String beforeString = adc.getClosedSalesAmountMoM();
        
        // Add new oppty - this should change the graph
        Opportunity newOppty = new Opportunity();
        newOppty.Name = 'Test Oppty #2';
        newOppty.AccountId = newAcct.Id;
        newOppty.Agency__c = newAcct.Id;
        newOppty.CloseDate = Date.today();
        newOppty.Amount = 22222;
        newOppty.P_O_Number__c = '123';
        newOppty.StageName = [SELECT MasterLabel FROM OpportunityStage WHERE IsWon = TRUE AND IsActive = TRUE LIMIT 1].MasterLabel;
        // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
        newOppty.Signed_contract_attached__c = true;
        insert newOppty;

        String afterString = adc.getClosedSalesAmountMoM();
        System.assert(!(beforeString.equals(afterString)));
    }

/*
    static testMethod void testProductGraphs() {
        Account newAcct = new Account();
        newAcct.Name = 'Test Account Agcy1'; 
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
        
        AccountDashboardsController adc = new AccountDashboardsController(newAcct);
        String beforeAmtString = adc.getSalesAmountByProduct();
        String beforeQtyString = adc.getSalesQuantityByProduct();
        
        // Add new oppty - this should change the graph
        Opportunity newOppty = new Opportunity();
        newOppty.Name = 'Test Oppty #3';
        newOppty.AccountId = newAcct.Id;
        newOppty.Agency__c = newAcct.Id;
        newOppty.CloseDate = Date.today();
        newOppty.Amount = 33333;
        newOppty.P_O_Number__C = '123';
        newOppty.StageName = [SELECT MasterLabel FROM OpportunityStage WHERE IsWon = TRUE AND IsActive = TRUE LIMIT 1].MasterLabel;
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
*/
}