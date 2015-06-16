/*
2014-05-12 - GTCRM-793 - Replicate charts on account layout for delivered revenue
*/

public with sharing class AccountDeliveredDashboardsController {

    private final Account acct;
    
    // Default number of years shown on the "Account Sales, Year over Year" report
    static final Integer CLOSED_SALES_AMOUNT_YOY_YEARS_SHOWN = 5;
    
    // Default number of years shown on the "Account Sales, Month over Month" report
    static final Integer CLOSED_SALES_AMOUNT_MOM_YEARS_SHOWN = 3;

    
    public AccountDeliveredDashboardsController (ApexPages.StandardController stdController) {
        this.acct = (Account)stdController.getRecord();
    }

    // For test methods
    public AccountDeliveredDashboardsController (Account acct) {
        this.acct = acct;
    }

    // Controller to generate the data for the "Account Sales, Year over Year" chart
    public String getClosedSalesAmountYoY() {
        String id = this.acct.Id; 
        final Integer firstYear = date.today().year() - CLOSED_SALES_AMOUNT_YOY_YEARS_SHOWN + 1;
    
        AggregateResult[] groupedResults = [SELECT FISCAL_YEAR(Month__c) YearOfSale,    
            SUM(Net_Net_Net_delivered__c) TotalAmount FROM Revenue_Schedule2__c
            WHERE Opportunity__r.AccountId = :id AND FISCAL_YEAR(Month__c) >= :firstYear AND Opportunity__r.IsWon = TRUE
            GROUP BY FISCAL_YEAR(Month__c) ORDER BY FISCAL_YEAR(Month__c) ASC];

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
    
        AggregateResult[] groupedResults = [SELECT FISCAL_MONTH(Month__c) MonthOfSale,
            FISCAL_YEAR(Month__c) YearOfSale,    
            SUM(Net_Net_Net_delivered__c) TotalAmount FROM Revenue_Schedule2__c 
            WHERE Opportunity__r.AccountId = :id AND FISCAL_YEAR(Month__c) >= :firstYear AND Opportunity__r.IsWon = TRUE
            GROUP BY FISCAL_MONTH(Month__c), FISCAL_YEAR(Month__c) 
            ORDER BY FISCAL_MONTH(Month__c), FISCAL_YEAR(Month__c)];

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
    
    
}