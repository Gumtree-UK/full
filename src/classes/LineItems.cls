public without sharing class LineItems {

    /****
         updateRevenues                          - create or update Revenues
         checkQuantity                           - calc package Quantity
         deleteRevenues(-Future)                 - deletes RevenueObject linked to deleted LineItems
         setPricesCPM                            - calc n/n/n for CPM based Prices
         copyDiscountsFromOpportunityToLineItem  - copy Discounts from Opp and calc n/n/n
         calcAmountByDelivery                    - calc Amount by Delivery
//       setAdName                               - set Ad-Name (Opportunity.Name & "_" & Description & "_" & PricebookEntry.Product2.Advertising_Medium__r.Name)
         setAdName (GTCRM-205)                   - set Ad-Name (Opportunity.Name & "_" & Description & "_" & PricebookEntry.Product2.Name)
    ****/

    public static void updateRevenues (List<OpportunityLineItem> triggerNew, List<OpportunityLineItem> triggerOld, Map<Id, OpportunityLineItem> triggerOldMap, Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUnDelete) {
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

        map<Id, String> pbNameByOppId   = new map<Id, String>();
        set<Id> oppIds                  = new set<Id>();

        if (!isBefore) {
/*
            system.debug('isBefore: ' + isBefore);
            system.debug('isInsert: ' + isInsert);
            system.debug('isUpdate: ' + isUpdate);
*/

            if (isInsert || isUpdate) {

                for (OpportunityLineItem oli : triggerNew) {
                    oppIds.add(oli.OpportunityId);
                }
    
                if (!oppIds.isEmpty()) {
                    for (Opportunity opp : [select Id, Pricebook2.Name from Opportunity where Id IN :oppIds]) {
                        pbNameByOppId.put(opp.Id, opp.Pricebook2.Name);
                    }
                }
            }

            if (isInsert) {
                for (OpportunityLineItem oli : triggerNew) {
                    if (pbNameByOppId.containsKey(oli.OpportunityId) && pbNameByOppId.get(oli.OpportunityId) != null && !pbNameByOppId.get(oli.OpportunityId).startsWith('US')) {
                        olis.add(oli);
                    }
                }
            }
            if (isUpdate) {
                for (OpportunityLineItem oli : triggerNew) {
                    if (oli.Ad_Id__c                            != triggerOldMap.get(oli.Id).Ad_Id__c  ||
//                        oli.CurrencyIsoCode                   != triggerOldMap.get(oli.Id).CurrencyIsoCode ||
                        oli.Ad_Name__c                          != triggerOldMap.get(oli.Id).Ad_Name__c ||
                        oli.Billing_category__c                 != triggerOldMap.get(oli.Id).Billing_category__c ||
                        oli.Quantity                            != triggerOldMap.get(oli.Id).Quantity ||
                        oli.UnitPrice                           != triggerOldMap.get(oli.Id).UnitPrice ||                        
                        oli.AE__c                               != triggerOldMap.get(oli.Id).AE__c ||                   
                        oli.Targeting_surcharge__c              != triggerOldMap.get(oli.Id).Targeting_surcharge__c ||
                        oli.Rate_Discount_I__c                  != triggerOldMap.get(oli.Id).Rate_Discount_I__c ||
                        oli.Rate_Discount_II__c                 != triggerOldMap.get(oli.Id).Rate_Discount_II__c ||                        
//                      oli.Customer_Order_No__c              != triggerOldMap.get(oli.Id).Customer_Order_No__c ||
                        oli.Net_Net_Net__c.setScale(2)          != triggerOldMap.get(oli.Id).Net_Net_Net__c.setScale(2) ||
                        oli.Sales_Price_incl_Targeting__c       != triggerOldMap.get(oli.Id).Sales_Price_incl_Targeting__c ||
                        oli.Rate_Card_Discount_percent__c       != triggerOldMap.get(oli.Id).Rate_Card_Discount_percent__c ||
//                        oli.Special_Agency_Discount_Percent__c  != triggerOldMap.get(oli.Id).Special_Agency_Discount_Percent__c ||
                        oli.Description                         != triggerOldMap.get(oli.Id).Description ||
//                        oli.additional_Billing_information1__c  != triggerOldMap.get(oli.Id).additional_Billing_information1__c ||
//                        oli.additional_Billing_information2__c  != triggerOldMap.get(oli.Id).additional_Billing_information2__c ||
                        oli.package_line_item__c                != triggerOldMap.get(oli.Id).package_line_item__c ||
                        oli.Adserver_ID_Order_ID__c             != triggerOldMap.get(oli.Id).Adserver_ID_Order_ID__c ||
                        oli.until_Date__c                       != triggerOldMap.get(oli.Id).until_Date__c ||
                        oli.from_Date__c                        != triggerOldMap.get(oli.Id).from_Date__c) {
                            system.debug('>>>>>>***');
/*
                         system.debug('AdServer_ID__c: ' + oli.AdServer_ID__c + ' ==> ' + triggerOldMap.get(oli.Id).AdServer_ID__c);
                         system.debug('CurrencyIsoCode: ' + oli.CurrencyIsoCode + ' ==> ' + triggerOldMap.get(oli.Id).CurrencyIsoCode);
                         system.debug('Billing_category__c: ' + oli.Billing_category__c + ' ==> ' + triggerOldMap.get(oli.Id).Billing_category__c);
                         system.debug('Quantity: ' + oli.Quantity + ' ==> ' + triggerOldMap.get(oli.Id).Quantity);
                         system.debug('Customer_Order_No__c: ' + oli.Customer_Order_No__c + ' ==> ' + triggerOldMap.get(oli.Id).Customer_Order_No__c);
                         system.debug('Amount_Net_Net_Net__c: ' + oli.Amount_Net_Net_Net__c.setScale(2) + ' ==> ' + triggerOldMap.get(oli.Id).Amount_Net_Net_Net__c.setScale(2));
                         system.debug('Sales_Price_incl_Targeting__c: ' + oli.Sales_Price_incl_Targeting__c + ' ==> ' + triggerOldMap.get(oli.Id).Sales_Price_incl_Targeting__c);
                         system.debug('Rate_Card_Discount_percent__c: ' + oli.Rate_Card_Discount_percent__c + ' ==> ' + triggerOldMap.get(oli.Id).Rate_Card_Discount_percent__c);
                         system.debug('Special_Agency_Discount_Percent__c: ' + oli.Special_Agency_Discount_Percent__c + ' ==> ' + triggerOldMap.get(oli.Id).Special_Agency_Discount_Percent__c);
                         system.debug('Description: ' + oli.Description + ' ==> ' + triggerOldMap.get(oli.Id).Description);
                         system.debug('additional_Billing_information1__c: ' + oli.additional_Billing_information1__c + ' ==> ' + triggerOldMap.get(oli.Id).additional_Billing_information1__c);
                         system.debug('additional_Billing_information2__c: ' + oli.additional_Billing_information2__c + ' ==> ' + triggerOldMap.get(oli.Id).additional_Billing_information2__c);
                         system.debug('package_line_item__c: ' + oli.package_line_item__c + ' ==> ' + triggerOldMap.get(oli.Id).package_line_item__c);
                         system.debug('Adserver_ID_Order_ID__c: ' + oli.Adserver_ID_Order_ID__c + ' ==> ' + triggerOldMap.get(oli.Id).Adserver_ID_Order_ID__c);
                         system.debug('until_Date__c: ' + oli.until_Date__c + ' ==> ' + triggerOldMap.get(oli.Id).until_Date__c);
                         system.debug('from_Date__c: ' + oli.from_Date__c + ' ==> ' + triggerOldMap.get(oli.Id).from_Date__c);
*/
                        if (pbNameByOppId.containsKey(oli.OpportunityId) && pbNameByOppId.get(oli.OpportunityId) != null && !pbNameByOppId.get(oli.OpportunityId).startsWith('US')) {
                            olis.add(oli);
                        }
                    }
                }
            }
        }

//      system.debug(olis);
        if (!olis.isEmpty()) {
            Revenue.start(olis, true);
        }
    }

  public static void checkQuantity (List<OpportunityLineItem> triggerNew, List<OpportunityLineItem> triggerOld, Map<Id, OpportunityLineItem> triggerOldMap, Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUnDelete) {

        List<OpportunityLineItem> triggerItems = null;

        if (isBefore && isDelete) {
            triggerItems = triggerOld;
        } else if (!isBefore && (isInsert || isUnDelete || isUpdate)) {
            triggerItems = triggerNew;
        }

        if (triggerItems != null) {
            // Check the quantity of package item.
            Set<Id> packageIds = new Set<Id>();

            for (OpportunityLineItem oli : triggerItems) {
                System.debug('\n\nOpportunityLineItem: ' + oli + '\n\n');
                if (oli.package_line_item__c != null && oli.Billing_category__c != 'Fix Price') {
                    if (isUpdate) {
                        if (oli.Quantity != triggerOldMap.get(oli.id).Quantity ||
                            oli.package_line_item__c != triggerOldMap.get(oli.id).package_line_item__c)
                        {
                            packageIds.add(oli.package_line_item__c);
                        }
                    } else {
                        packageIds.add(oli.package_line_item__c);
                    }
                }
            }

            if (!packageIds.isEmpty()) {
                Map<Id, OpportunityLineItem> packageItems = new Map<Id, OpportunityLineItem>();
                Map<Id, Decimal> packageQuantity = new Map<Id, Decimal>();
                for (OpportunityLineItem oli : [select Id, package_line_item__c, Billing_category__c, Quantity, Quantity_discrepancy__c, PricebookEntry.Product2.RecordType.Name from OpportunityLineItem where (Id IN :packageIds or package_line_item__c IN :packageIds) order by package_line_item__c nulls first]) {
                    if (oli.package_line_item__c != null && oli.Billing_category__c != 'Fix Price') {
                        if (packageQuantity.get(oli.package_line_item__c) != null) {
                            packageQuantity.put(oli.package_line_item__c, oli.Quantity + packageQuantity.get(oli.package_line_item__c));
                        } else {
                            packageQuantity.put(oli.package_line_item__c, oli.Quantity);
                        }
                        System.debug('\n\nComponentLineItem: ' + oli + '\n\n');
                        System.debug('\n\nPackageQuantity: ' + packageQuantity + '\n\n');
                    } else if (oli.package_line_item__c == null && oli.Billing_category__c != 'Fix Price' && oli.PricebookEntry.Product2.RecordType.Name == 'Package') {
                        packageItems.put(oli.Id, oli);
                    }
                }

                System.debug('\n\nPackageQuantity: ' + packageQuantity + '\n\n');
                System.debug('\n\nPackageItems: ' + packageItems + '\n\n');

                List<OpportunityLineItem> updOlis = new List<OpportunityLineItem>();
                for (OpportunityLineItem oli :packageItems.values()) {
                    if (packageQuantity.containsKey(oli.Id) && (packageQuantity.get(oli.Id) != oli.Quantity || oli.Quantity_discrepancy__c != Math.abs(oli.Quantity - packageQuantity.get(oli.Id)))) {
                        oli.Quantity_discrepancy__c = Math.abs(oli.Quantity - packageQuantity.get(oli.Id));
                        System.debug('\n\nPackageLineItem: ' + oli + '\n\n');
                        updOlis.add(oli);
                    }
                }
                if (!updOlis.isEmpty()) {
                    update updOlis;
                }
            }
        }
    }

    public static void deleteReveues (List<OpportunityLineItem> triggerOld, Boolean isBefore, Boolean isDelete) {
        if (isBefore && isDelete) {
            Set<Id> rev_ids = new Set<Id>();
            Set<Id> rev2_ids = new Set<Id>();

            for (OpportunityLineItem oli : triggerOld) {
                if (oli.Revenue2__c!=null) {
                    rev_ids.add(oli.Revenue2__c);
                }
                if (oli.Revenue2__c!=null) {
                    rev2_ids.add(oli.Revenue2__c);
                }
            }

            try {

                Integer countRSD = [select count() from Revenue_Schedule_daily2__c where Revenue2__c IN :rev_ids limit 100];
                Integer countRSD2 = [select count() from Revenue_Schedule_daily2__c where Revenue2__c IN :rev2_ids limit 100];

                if (countRSD >= 100) {
                    deleteRevenueFuture(rev_ids, 'Revenue');
                }
                else {
                    delete [select Id from Revenue2__c where Id IN :rev_ids];
                }

                if (countRSD2 >= 100) {
                    deleteRevenueFuture(rev2_ids, 'Revenue2');
                }
                else {
                    delete [select Id from Revenue2__c where Id IN :rev2_ids];
                }
            }
            catch(Exception e) {
                system.debug('Error on delete Revenues with LineItem ' + e.getMessage());
            }
        }
    }

    @future
    private static void deleteRevenueFuture (Set<Id> revs, String obj) {
        try {
            if (obj == 'Revenue') {
                delete [select Id from Revenue_Schedule_daily2__c where Revenue2__c IN :revs];
                delete [select Id from Revenue2__c where Id IN :revs];
            }
            else if (obj == 'Revenue2') {
                delete [select Id from Revenue_Schedule_daily2__c where Revenue2__c IN :revs];
                delete [select Id from Revenue2__c where Id IN :revs];
            }
        }
        catch(Exception e) {
            system.debug('Error on delete Revenues with LineItem ' + e.getMessage());
        }
    }



    public static void setPricesCPM (List<OpportunityLineItem> triggerNew, List<OpportunityLineItem> triggerOld, Map<Id, OpportunityLineItem> triggerOldMap, Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUnDelete) {

        if (isBefore && (isInsert || isUpdate)) {
            for (OpportunityLineItem oli : triggerNew) {
                // Berechnungen der Werte für Ebay-Units, die CPM basierte Preise angeben
                if (oli.CPM_Sales_Price__c != null) {
                    // UnitPrice setzen
                     if (oli.Billing_category__c == 'CPM') {
                         oli.CPM_Sales_Price__c = oli.Sales_Price_Net_Net_Net__c / 1000;
                          }
                    else {
                        oli.CPM_Sales_Price__c = oli.Sales_Price_Net_Net_Net__c;
                        }
                    // Rabatte setzen wenn nötig
                    if (oli.Rate_Discount_I__c == null) {
                        oli.Rate_Discount_I__c = 0;
                    }
                    if (oli.Rate_Discount_II__c == null) {
                        oli.Rate_Discount_II__c = 0;
                    }
                    
                    if (oli.CPM_Sales_Price__c == null) {
                        oli.CPM_Sales_Price__c = 0;
                    }
                    
                    // Net/Net/Net setzen
                    Decimal net = (oli.CPM_Sales_Price__c * oli.Quantity);
/*                  if (oli.AE__c) {
                        if ((oli.Pricebook_Name__c != null) && (oli.Pricebook_Name__c.substring(0,15)=='01s200000001nI6' || oli.Pricebook_Name__c.substring(0,15)=='01s200000001nIB') ) { // AU Standard Contract Price Book // AU Individual Contract Price Book
                        net = net *  0.85;
                        }
                    else {
                        net = net *  0.85;
                            }
                        }
*/
                    system.debug(net);
                    oli.Net_Net_Net__c = net;
                }
            }
        }
    }



    public static void copyDiscountsFromOpportunityToLineItem (List<OpportunityLineItem> triggerNew, List<OpportunityLineItem> triggerOld, Map<Id, OpportunityLineItem> triggerOldMap, Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUnDelete) {

        if (isBefore && (isInsert || isUpdate)) {
            Set<Id> oppIds = new Set<Id>();
            Map<Id, Opportunity> oppValuesMap = new Map<Id, Opportunity>();

            for (OpportunityLineItem oli : triggerNew) {
                
                if (isUpdate &&
                    oli.Billing_Category__c                 != triggerOldMap.get(oli.Id).Billing_Category__c &&
                    oli.CPM_Sales_Price__c                  != triggerOldMap.get(oli.Id).CPM_Sales_Price__c &&
                    oli.AE__c                               != triggerOldMap.get(oli.Id).AE__c &&
                    oli.Rebate_In_Kind__c                   != triggerOldMap.get(oli.Id).Rebate_In_Kind__c &&
//                    oli.Rate_Card_Discount_percent__c       != triggerOldMap.get(oli.Id).Rate_Card_Discount_percent__c &&
                    oli.Targeting_surcharge__c              != triggerOldMap.get(oli.Id).Targeting_surcharge__c &&
                    oli.Rate_Discount_I__c                  != triggerOldMap.get(oli.Id).Rate_Discount_I__c &&
                    oli.Rate_Discount_II__c                 != triggerOldMap.get(oli.Id).Rate_Discount_II__c &&
//                    oli.Special_Agency_Discount_Percent__c  != triggerOldMap.get(oli.Id).Special_Agency_Discount_Percent__c &&
                    oli.Sales_Price_incl_Targeting__c       != triggerOldMap.get(oli.Id).Sales_Price_incl_Targeting__c &&
                    oli.Quantity                            != triggerOldMap.get(oli.Id).Quantity) { // keine Änderung wenn sich nix tut
                    continue;
                }
                
                if (oli.Rate_Discount_II__c == null) {
                    oli.Rate_Discount_II__c = 0;
                }

                if (!oppIds.contains(oli.OpportunityId)) {
                    oppIds.add(oli.OpportunityId);
                }
            }

            if (!oppIds.isEmpty()) {
                for (Opportunity opp : [select Id, Rate_Discount_I__c, Rate_Discount_II__c, AE__c, CreatedDate from Opportunity where Id IN : oppIds]) {
                    oppValuesMap.put(opp.Id, opp);
                }
 /* copy discounts from line item 
     if (!oppIds.isEmpty()) {
        for (Opportunity opp : [select Id, Rate_Discount_II__c, AE__c, Rate_Card_Discount_this_Order_new__c, Customer_Discount_override__c, CreatedDate from Opportunity where Id IN : oppIds]) {
          oppValuesMap.put(opp.Id, opp);
        }
*/

                for (OpportunityLineItem oli : triggerNew) {
/*
                    system.debug(oppValuesMap);
                    system.debug('oppValuesMap.get(oli.OpportunityId).AE__c: ' + oppValuesMap.get(oli.OpportunityId).AE__c);
                    system.debug('oli.Rebate_In_Kind__c: ' + oli.Rebate_In_Kind__c);
                    system.debug('oppValuesMap.get(oli.OpportunityId).Rate_Card_Discount_this_Order_new__c: ' + oppValuesMap.get(oli.OpportunityId).Rate_Card_Discount_this_Order_new__c);
                    system.debug('oppValuesMap.get(oli.OpportunityId).Customer_Discount_override__c: ' + oppValuesMap.get(oli.OpportunityId).Customer_Discount_override__c);
                    system.debug('oli.AE__c: ' + oli.AE__c);
*/
                  if (!oppValuesMap.containsKey(oli.OpportunityId)) {
                        continue;
                    }

//                    oli.AE__c                           = oli.Rebate_In_Kind__c ? false : oppValuesMap.get(oli.OpportunityId).AE__c;
//                    oli.Rate_Card_Discount_percent__c   = oli.Rebate_In_Kind__c ? 0     : oppValuesMap.get(oli.OpportunityId).Rate_Card_Discount_II__c;
//                    oli.Rate_Discount_I__c              = oli.Rebate_In_Kind__c ? 0     : oppValuesMap.get(oli.OpportunityId).Customer_Discount_override__c;
                    // ebay comment out oli.Rate_Discount_II__c               = oppValuesMap.get(oli.OpportunityId).Rate_Discount_II__c > 0   ? oppValuesMap.get(oli.OpportunityId).Rate_Discount_II__c : oli.Rate_Discount_II__c;
                    oli.Rate_Discount_II__c             = oli.Rebate_In_Kind__c                                         ? 100       : oli.Rate_Discount_II__c;
                    oli.Rate_Discount_II__c             = oli.Rate_Discount_II__c == null                               ? 0         : oli.Rate_Discount_II__c;
                    oli.Rate_Card_Discount_percent__c   = oli.Rate_Card_Discount_percent__c == null                     ? 0         : oli.Rate_Card_Discount_percent__c;
                    oli.Rate_Discount_I__c              = oli.Rate_Discount_I__c == null                                ? 0         : oli.Rate_Discount_I__c;
/*
                    system.debug('oppValuesMap.get(oli.OpportunityId).AE__c: ' + oppValuesMap.get(oli.OpportunityId).AE__c);
                    system.debug('oli.Rebate_In_Kind__c: ' + oli.Rebate_In_Kind__c);
                    system.debug('oli.Rate_Card_Discount_percent__c: ' + oli.Rate_Card_Discount_percent__c);
                    system.debug('oli.IsWallpaper__c: ' + oli.IsWallpaper__c);
                    system.debug('oli.Rate_Discount_I__c: ' + oli.Rate_Discount_I__c);
                    system.debug('oli.AE__c: ' + oli.AE__c);
*/

                  if (oli.Billing_Category__c == null || oli.CPM_Sales_Price__c == null) { // else method setPricesCPM is usesd
                        Double nnn = 0;
                        nnn = oli.Sales_Price_incl_Targeting__c;
                        nnn *= oli.Quantity;
//                        nnn *= (1 - oli.Rate_Card_Discount_percent__c / 100);
//                        nnn *= (1 - oli.Special_Agency_Discount_Percent__c / 100);
                        nnn *= (1 - oli.Rate_Discount_I__c / 100);
                        nnn *= (1 - oli.Rate_Discount_II__c / 100);
                        nnn *= oli.AE__c ? 0.85 : 1;

                        oli.Net_Net_Net__c = nnn;
                    }
                }
            }
        }
    }


 public static void calcAmountByDelivery (List<OpportunityLineItem> triggerNew, List<OpportunityLineItem> triggerOld, Map<Id, OpportunityLineItem> triggerOldMap, Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUnDelete) {
    if (isBefore && isUpdate) {
      /* Old definition.
      for (OpportunityLineItem oli : triggerNew) {
        Decimal delivered = 0.0;

        if (oli.Amount_Net_Net_Net__c == null) {
          oli.Amount_Net_Net_Net__c = 0.0;
        }

        if ((oli.Delivered_Impressions__c != null && oli.Delivered_Impressions__c > 0) && (oli.Billing_category__c == 'CPM' || oli.Billing_category__c == 'Fix Price')) {
          delivered = (100 / oli.Quantity * oli.Delivered_Impressions__c) / 100 * oli.Amount_Net_Net_Net__c;
        }
        else if ((oli.Delivered_Clicks__c != null && oli.Delivered_Clicks__c > 0) && (oli.Billing_category__c == 'CPC')) {
          delivered = (100 / oli.Quantity * oli.Delivered_Clicks__c) / 100 * oli.Amount_Net_Net_Net__c;
        }

        if (oli.Amount_Net_Net_Net__c >= delivered) {
          oli.Turnover_actual_by_delivery__c = delivered;
        }
        else {
          oli.Turnover_actual_by_delivery__c = oli.Amount_Net_Net_Net__c;
        }
      }
      */
      /*
       * 2012-01-27:
       * New definition (KV-00026360):
       *  IF (TODAY() > from_Date__c , 
             *      (CASE 
             *       (Billing_category__c, 
             *        "CPM", IF ( Quantity > Delivered_Impressions__c , Delivered_Impressions__c * TKP_net_net_net__c /1000, Amount_Net_Net_Net__c), 
             *        "CPC", IF ( Quantity > Delivered_Clicks__c, Delivered_Clicks__c * TKP_net_net_net__c, Amount_Net_Net_Net__c ), 
             *        "CPO", IF (TODAY() > until_Date__c, Amount_Net_Net_Net__c, (TODAY() - from_Date__c + 1 )/( until_Date__c - from_Date__c + 1) * Amount_Net_Net_Net__c ) , 
             *        "Fix Price", Amount_Net_Net_Net__c, 
             *        0)),
             *      0)
       */
      Date now = Date.today();
      for (OpportunityLineItem oli : triggerNew) {
        if (now > oli.from_Date__c) {
          if (oli.Billing_category__c == 'CPM') {
            Decimal q = oli.Quantity == null ? 0 : oli.Quantity;
            Decimal v = oli.delivered_AI_LT__c == null ? 0 : oli.delivered_AI_LT__c;
            if (q > v) {
              oli.Turnover_actual_by_delivery__c = oli.TKP_net_net_net__c == null ? 0 : v * oli.TKP_net_net_net__c / 1000;
            } else {
              oli.Turnover_actual_by_delivery__c = oli.Net_Net_Net__c;
            }
          } else if (oli.Billing_category__c == 'CPC') {
            Decimal q = oli.Quantity == null ? 0 : oli.Quantity;
            Decimal v = oli.delivered_Clicks_LT__c == null ? 0 : oli.delivered_Clicks_LT__c;
            if (q > v) {
              oli.Turnover_actual_by_delivery__c = oli.TKP_net_net_net__c == null ? 0 : v * oli.TKP_net_net_net__c;
            } else {
              oli.Turnover_actual_by_delivery__c = oli.Net_Net_Net__c;
            }
          } else if (oli.Billing_category__c == 'CPO') {
            if (now > oli.until_Date__c) {
              oli.Turnover_actual_by_delivery__c = oli.Net_Net_Net__c;
            } else {
              
              if (oli.from_Date__c != null && oli.until_Date__c != null && oli.from_Date__c <= oli.until_Date__c) {
                Double n1 = Double.valueOf(oli.from_Date__c.daysBetween(now)) + 1;
                Double n2 = Double.valueOf(oli.from_Date__c.daysBetween(oli.until_Date__c)) + 1;
                
                oli.Turnover_actual_by_delivery__c = (oli.Net_Net_Net__c == null) ? 0 : (n1 / n2 * oli.Net_Net_Net__c);
              } else {
                oli.Turnover_actual_by_delivery__c = 0;
              }
            }
          } else if (oli.Billing_category__c == 'CPD') {
            oli.Turnover_actual_by_delivery__c = oli.Net_Net_Net__c;
          } else {
            oli.Turnover_actual_by_delivery__c = 0;
          }
        } else {
          oli.Turnover_actual_by_delivery__c = 0;  
        }
      }
    }
  }
    
    public static void setAdName (List<OpportunityLineItem> triggerNew, List<OpportunityLineItem> triggerOld, Map<Id, OpportunityLineItem> triggerOldMap, Boolean isBefore, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUnDelete) {
        if(!(isBefore && (isUpdate || isInsert))) return;
        List<OpportunityLineItem> filterList = triggerNew;
        Set<Id> oppIds = new Set<Id>();
        Set<Id> pbeIds = new Set<Id>();
        for(OpportunityLineItem oppitem : filterList){
            oppIds.add(oppitem.OpportunityId);
            pbeIds.add(oppitem.PricebookEntryId);
        }
        Map<Id, Opportunity> mopp = new Map<Id, Opportunity>([Select Name From Opportunity Where Id IN: oppIds]); 
//        Map<Id, PricebookEntry> mpbe = new Map<Id, PricebookEntry>([Select Product2.Advertising_Medium__r.Name From PricebookEntry Where Id IN: pbeIds]); 
        Map<Id, PricebookEntry> mpbe = new Map<Id, PricebookEntry>([Select Product2.Name From PricebookEntry Where Id IN: pbeIds]); 
        String spliter = '_';
        for(OpportunityLineItem lineitem : filterList){
//            String adName = mpbe.get(lineitem.PricebookEntryId).Product2.Advertising_Medium__r.Name;
            String adName = mpbe.get(lineitem.PricebookEntryId).Product2.Name;
            String oppName = mopp.get(lineitem.OpportunityId).Name;
            lineitem.Ad_Name__c = (oppName == null ? '' : oppName) + (lineitem.Description != null ? spliter : '') + (lineitem.Description == null ? '' : lineitem.Description) + (adName != null ? spliter : '') + (adName == null ? '' : adName);
        }
    } 
}