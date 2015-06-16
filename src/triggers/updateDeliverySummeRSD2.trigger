trigger updateDeliverySummeRSD2 on Revenue_Schedule_daily2__c (after delete, after insert, after update) {

    Set<Id> rsdIds = new Set<Id>();
    List<Revenue_Schedule_daily2__c> rsds= new List<Revenue_Schedule_daily2__c>();
    List<Revenue_Schedule_daily2__c> triggerList= new List<Revenue_Schedule_daily2__c>();
    Map<Id, Date> rsdDates = new Map<Id, Date>();
    Map<Id, Integer> rsdDeliveries = new Map<Id, Integer>();
    Date today = system.today();
    Date minimumDay = today;

    if (trigger.isDelete) {
        triggerList = trigger.old;
    }
    else {
        triggerList = trigger.new;
    }

    for (Revenue_Schedule_daily2__c rsd : triggerList) {
        if ((!trigger.isDelete && !trigger.isInsert && rsd.Daily_Quantity__c == trigger.oldMap.get(rsd.Id).Daily_Quantity__c && rsd.Billing_Category__c != 'Fix Price' && rsd.Billing_Category__c != 'CPO') || rsd.Billing_Category__c == 'CPA') {
        }
        else if (trigger.isDelete && !rsdIds.contains(trigger.oldMap.get(rsd.Id).Revenue2__c)) {
            rsdIds.add(trigger.oldMap.get(rsd.Id).Revenue2__c);
            rsdDates.put(trigger.oldMap.get(rsd.Id).Revenue2__c, trigger.oldMap.get(rsd.Id).Day__c);
        }
        else if (!trigger.isDelete) {
            if (!rsdIds.contains(rsd.Revenue2__c)) {
                rsdIds.add(rsd.Revenue2__c);
            }
            if (rsdDates.get(rsd.Revenue2__c) == null || rsdDates.get(rsd.Revenue2__c) > rsd.Day__c) {
                rsdDates.put(rsd.Revenue2__c, rsd.Day__c);
            }
        }
        if (rsd.Day__c < minimumDay) {
            minimumDay = rsd.Day__c;
        }
    }

    if (!rsdIds.isEmpty()) {
        Id former = null;
        Double summe = 0;
        
        for (AggregateResult ar : [select Revenue2__c, sum(Daily_Quantity__c) dqSumme from Revenue_Schedule_daily2__c where ((Ad_Id__c != '' and Ad_Id__c != '0') or (Order_Id__c != '' and Order_Id__c != '0')) and Billing_Category__c != 'Fix Price' and Billing_Category__c != 'CPO' and Billing_Category__c != 'CPA' and Day__c < :minimumDay and Day__c < :today and Revenue2__c IN :rsdIds group by Revenue2__c]) {
            rsdDeliveries.put(String.valueOf(ar.get('Revenue2__c')), Decimal.valueOf(String.valueOf(ar.get('dqSumme'))).intValue());
        }
        
        for (Revenue_Schedule_daily2__c rsd : [select Id, Revenue2__c, Day__c, Booked_Quantity__c, Billing_Category__c, Daily_Quantity__c, Delivered_Sum__c, Invoice_Quantity__c from Revenue_Schedule_daily2__c where (((Ad_Id__c != '' and Ad_Id__c != '0') or (Order_Id__c != '' and Order_Id__c != '0')) or Billing_Category__c = 'Fix Price' or Billing_Category__c = 'CPO') and Billing_Category__c != 'CPA' and Day__c >= :minimumDay and Day__c <= :today and Revenue2__c IN :rsdIds order by Revenue2__c, Day__c asc]) {

            if (former == null || former != rsd.Revenue2__c) {
                if (rsdDeliveries.containsKey(rsd.Revenue2__c)) {
                    summe = rsdDeliveries.get(rsd.Revenue2__c);
                }
                else {
                    summe = 0;
                }
                former = rsd.Revenue2__c;
            }

            summe += rsd.Daily_Quantity__c;

            if (rsdDates.get(rsd.Revenue2__c) != null && rsdDates.get(rsd.Revenue2__c) > rsd.Day__c && !(rsd.Billing_Category__c == 'Fix Price' || rsd.Billing_Category__c == 'CPO')) {
              continue;
            }

            Boolean changed = false;

            if (summe != rsd.Delivered_Sum__c) {
                rsd.Delivered_Sum__c = summe;
                changed = true;
            }

            if ((rsd.Billing_Category__c == 'Fix Price' || rsd.Billing_Category__c == 'CPO') && rsd.Invoice_Quantity__c != 1) {
                rsd.Invoice_Quantity__c = 1;
                changed = true;
            }
 
            if (rsd.Billing_Category__c == 'CPA') {
                rsd.Invoice_Quantity__c = rsd.Daily_Quantity__c;
            }

            if (rsd.Billing_Category__c == 'CPM' || rsd.Billing_Category__c == 'CPC') {
                if (rsd.Booked_Quantity__c >= rsd.Delivered_Sum__c) {
                    if (rsd.Invoice_Quantity__c != rsd.Daily_Quantity__c) {
                        rsd.Invoice_Quantity__c = rsd.Daily_Quantity__c;
                        changed = true;
                    }
                }
                else if (rsd.Booked_Quantity__c >= (rsd.Delivered_Sum__c - rsd.Daily_Quantity__c)) {
                    if (rsd.Invoice_Quantity__c != rsd.Booked_Quantity__c - (rsd.Delivered_Sum__c - rsd.Daily_Quantity__c)) {
                        rsd.Invoice_Quantity__c = rsd.Booked_Quantity__c - (rsd.Delivered_Sum__c - rsd.Daily_Quantity__c);
                        changed = true;
                    }
                }
                else if (rsd.Invoice_Quantity__c != 0) {
                    rsd.Invoice_Quantity__c = 0;
                    changed = true;
                }
            }
    
            if (changed) {
                rsds.add(rsd);
            }
        }

        if (!rsds.isEmpty()) {
            if (rsds.size() > (100 * triggerList.size())) { // Update mit @Future
                system.debug(rsds.size() + ' / ' + 100 * triggerList.size() + ' DML Rows expected');
                FutureHelper.updateRSD(rsdIds);
            }
            else {
                system.debug(rsds);
                update rsds;
            }
        }
    }
}