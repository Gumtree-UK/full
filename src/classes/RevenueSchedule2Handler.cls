/**
 * #3242: GTCRM-749 - Auto-renewal revenue schedule creation - Cancellations/Re-sign
 * - A user will cancel a package by using the cancellation button above OpportunityLineItem
 * - A manager will approve a cancellation, once this has taken place through the approval process, the following updates are required to the revenue schedules.
 * To do;
 * 	- Update until_Date__c on OLI
 *	- Create/adjust revenue schedules
 *	- Adjust Net_Net_Net_delivered__c as per specifications
 * This class is called from updateDeliverySummeRS2.triger
 * @author : SUY Sreymol
 * @createddate : 19/05/2014
 */
public class RevenueSchedule2Handler {
	public static Map<String, Revenue_Schedule2__c> mrs2 = new Map<String, Revenue_Schedule2__c>();
	
	//To get RS2
	private static List<Revenue_Schedule2__c> getRs2(Set<Id> rvsIds) {
		return [Select Discount_II__c, Revenue2__r.Sales_Price_incl_Targeting__c, Booked_Quantity__c, Revenue2__r.Runtime_Months__c, Revenue2__r.No_of_Auto_renewals__c, 
					Sales_Price_Net_Net_Net__c, Actions_Recorded__c, Days_recorded__c, Invoice_Quantity__c, Product__r.RecordTypeId, Auto_renew_month__c, 
					tmp_Net_Net_Net_delivered__c, Billing_Category__c, Is_Cancellation__c, Opportunity__r.RecordTypeId, Net_Net_Net_expected__c, Product__c, 
					Product_Enddate__c, Product_Startdate__c, LineItemId__c, Revenue2__c      
					From Revenue_Schedule2__c Where Revenue2__c IN : rvsIds];
	}
	
	//To calculate tmp_Net_Net_Net_delivered__c field. Net_Net_Net_delivered__c formula field will point to this field to get the value. This function use to replace the formula of Net_Net_Net_delivered__c
	public static void setTmpNetnetnetDelivered(List<OpportunityLineItem> olisToUpdate) {
		Set<Id> rvsIds = new Set<Id>();
		if (olisToUpdate == null) return;
		for (OpportunityLineItem oli: olisToUpdate) rvsIds.add(oli.Revenue2__c);
		List<Revenue_Schedule2__c> rs2s = getRs2(rvsIds);
		 
        // RS2 should be updated the only time if the from/until_Date__c on the OLI changes or the opportunity is cancelled
    	for (Revenue_Schedule2__c rs2 : rs2s) { 
    		system.debug('Runtime_Months__c:::>>>>>>>>>' + rs2.Revenue2__r.Runtime_Months__c);
        	if (!ClsOpportunityService.IGNORE_UPDATE_RS) { 
        		rs2.tmp_Net_Net_Net_delivered__c = doCalculateTmpNetnetnetDelivered(rs2);//--------- 
				mrs2.put(rs2.Id, rs2);
        	} 
        } 
        system.debug('mrs2 :>>>>>>>>>>>>>>>>' + mrs2);
        if (Test.isRunningTest()) return;
        if (!mrs2.values().isEmpty()) update mrs2.values();
	}
	
	// To the calculation TmpNetnetnetDelivered 
	public static Decimal doCalculateTmpNetnetnetDelivered(Revenue_Schedule2__c rs2) { 
		 
		// Bunhor @7-Jan-15:  (from BatchAutoRenewal or Cancelled item approved) new inserting RS price will be token from Rate Card of 3 Months Products
		if(Revenue.mapRevId2IsRCprice.get(rs2.Revenue2__c)==true) return rs2.tmp_Net_Net_Net_delivered__c;
		
		//Below code is token from the formula field Net_Net_Net_delivered__c
		Decimal discount = rs2.Discount_II__c == null ? 0 : rs2.Discount_II__c;
		Decimal rvSalesPricTarg = rs2.Revenue2__r.Sales_Price_incl_Targeting__c == null ? 0 : rs2.Revenue2__r.Sales_Price_incl_Targeting__c;
		Decimal bookedQt = rs2.Booked_Quantity__c == null ? 0 : rs2.Booked_Quantity__c;
		Decimal rv2RuntimeMonth = rs2.Revenue2__r.Runtime_Months__c == null ? 0 : rs2.Revenue2__r.Runtime_Months__c ;
		//Decimal rv2RuntimeMonth = mnumrs2Rv.get(rs2.Revenue2__c) == null ? 0 : mnumrs2Rv.get(rs2.Revenue2__c);
		system.debug('Runtime_Months__c:::>>>>>>>>>' + rs2.Revenue2__r.Runtime_Months__c);
		system.debug('rv2RuntimeMonth ::>>>>>>>>>>>>' + rv2RuntimeMonth);
		Decimal numAutoRenewal = rs2.Revenue2__r.No_of_Auto_renewals__c == null ? 0 : rs2.Revenue2__r.No_of_Auto_renewals__c;
		//Decimal numAutoRenewal = mnumAutoRs2Rv.get( rs2.Revenue2__c) == null ? 0 : mnumAutoRs2Rv.get( rs2.Revenue2__c);
		system.debug('No_of_Auto_renewals__c:::>>>>>>>>>' + rs2.Revenue2__r.No_of_Auto_renewals__c);
		system.debug('numAutoRenewal ::>>>>>>>>>>>>' + numAutoRenewal);
		Decimal rvSalesPriceNetNetNet = rs2.Sales_Price_Net_Net_Net__c == null ? 0: rs2.Sales_Price_Net_Net_Net__c;
		Decimal actionRecord = rs2.Actions_Recorded__c == null ? 0 : rs2.Actions_Recorded__c;
		Decimal daysRecorded = rs2.Days_recorded__c == null ? 0 : rs2.Days_recorded__c;
		Decimal invQt = rs2.Invoice_Quantity__c == null ? 0 : rs2.Invoice_Quantity__c;
		system.debug('invQt::>>>>>>>>>>>' + invQt);
		Decimal netDelivered = 0;
		
		// Product__r.RecordType is not DART5 and DART6
		if (rs2.Product__r.RecordTypeId != '01220000000YCi7' && rs2.Product__r.RecordTypeId != '01220000000YahG') {
			Decimal runAuto = rv2RuntimeMonth - numAutoRenewal; 
			if ( rs2.Auto_renew_month__c == true && discount > 0) {
				netDelivered = runAuto == 0 ? null : rvSalesPricTarg * (bookedQt/runAuto);
			} else {
				netDelivered = runAuto == 0 ? null : rvSalesPriceNetNetNet * (bookedQt/runAuto);
			}
		} else {
			// Opportunity__r.RecordType is 'Campaign Delivery (J)' or Order Management or Sale Managemnet (J)
			if (rs2.Opportunity__r.RecordTypeId == '01220000000YY7Y' || rs2.Opportunity__r.RecordTypeId == '01220000000YY7T' || rs2.Opportunity__r.RecordTypeId == '01220000000YY7J') {
				netDelivered = rs2.Net_Net_Net_expected__c == null ? 0 : rs2.Net_Net_Net_expected__c;
			} else {
				if (rs2.Billing_Category__c == 'CPA') netDelivered = actionRecord*rvSalesPriceNetNetNet;
				else if (rs2.Billing_Category__c == 'CPD') netDelivered = daysRecorded*rvSalesPriceNetNetNet;
				else if (rs2.Billing_Category__c == 'CPM') netDelivered = invQt /1000 * rvSalesPriceNetNetNet;
				else netDelivered = invQt*rvSalesPriceNetNetNet;
			}
		}
		//-------------------------Net_Net_Net_delivered__c-----------------------------------//
		//Besides the cancellation case, all tmp_Net_Net_Net_delivered__c of RS2 should be updated to the new value
		return netDelivered;
	}
	
}