public class IOSortOrderExtension {

public IOSortOrderExtension(ApexPages.StandardController stdController) {
}

public List <opportunityLineItem> getsortrecord() {

    RETURN [ SELECT PriceBookEntry.Product2.Name, 
         from_Date__c,
         until_Date__c,
         UnitPrice,
//         Sales_Price_Net__c,
//         Sales_Price_Net_Net__c,
         Discount,
         Billing_Category__c,
         Quantity,
         Net__c,
         Gross__c,
         Net_Net_Net__c,
         Sales_Price_Net_Net_Net__c,
         Sales_Price_incl_Targeting__c,
         Rate_Discount_II__c,
         Description,
         PricebookEntry.Name,
         PriceBookEntry.Product2.Advertising_Medium__r.Dart_AdSlotSize__c,
         PriceBookEntry.Product2.Advertising_Medium__r.Max_file_size__c,
         PriceBookEntry.Product2.Advertising_Medium__r.File_type__c,
         PriceBookEntry.Product2.Advertising_Medium__r.File_type_version__c,
         PriceBookEntry.Product2.Advertising_Medium__r.Notes__c
         FROM OpportunityLineItem 
         WHERE OpportunityId =: ApexPages.currentPage().getParameters().get('id')
         ORDER BY from_Date__c ASC]; } }