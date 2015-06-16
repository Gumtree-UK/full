public class SalesLeaderBoardController{

    public SalesLeaderBoardController() {

    }

    public Opportunity[] getopps() {
           return [SELECT Id, Account.Id, Name, Net_Net__c, Owner.Name FROM Opportunity
                WHERE Account.id = :ApexPages.currentPage().getParameters().get('id')
                LIMIT 10];
    } 
    public OpportunityLineItem[] getolistandard() {
           return [SELECT Id, Period__c, Quantity, Credits_Used__c, Credit_Burn_Rate__c, Credits_Remaining__c, Package_Status__c, Length_Months__c, Additional_Time_Days__c, Days_remaining__c, Billing_Category__c, Delivered_AI_LT__c, Delivered_Clicks_LT__c, OSI__c, Netto_II__c, from_Date__c, until_Date__c, PriceBookEntry.Name, PricebookEntry.Product2.Product_Subtype__c FROM OpportunityLineItem
                   WHERE Opportunity.Account.id = :ApexPages.currentPage().getParameters().get('id')
                   AND PricebookEntry.Product2.Product_Subtype__c = 'Advertising'
                   AND Package_Status__c != 'Expired'
                   ORDER BY Days_Remaining__c ASC];
      }

}