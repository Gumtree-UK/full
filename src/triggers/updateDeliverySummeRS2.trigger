/**
 * change log:
 *		- To fixed not update RS2 from importing delivery from DFP 
 * 		- @author : SUY Sreymol
 *		- @modified date : 04/06/2014 
 */
trigger updateDeliverySummeRS2 on Revenue_Schedule2__c (after delete, after insert, after update) {
    Set<Id> rsIds = new Set<Id>();
    List<Revenue_Schedule2__c> rss= new List<Revenue_Schedule2__c>();
    List<Revenue_Schedule2__c> triggerList= new List<Revenue_Schedule2__c>();
    Map<Id, Date> rsDates = new Map<Id, Date>();

    Date today = system.today();

    if (trigger.isDelete) {
      triggerList = trigger.old;
    } else {
      triggerList = trigger.new;
    }
  
    for (Revenue_Schedule2__c rs : triggerList) {
    	Boolean isMap = true; 
      	if (!trigger.isDelete && !trigger.isInsert && rs.Monthly_Quantity__c == trigger.oldMap.get(rs.Id).Monthly_Quantity__c && rs.Billing_Category__c != 'Fix Price' && rs.Billing_Category__c != 'CPO' && rs.Billing_Category__c != null) {
       		isMap = false;
      	} 
      
      //else if (trigger.isDelete && !rsIds.contains(trigger.oldMap.get(rs.Id).Revenue2__c)) {//SUY Sreymol 27/05/2014 - to fixed not update the olds RS2
      if (trigger.isDelete && !rsIds.contains(trigger.oldMap.get(rs.Id).Revenue2__c)) {
          rsIds.add(trigger.oldMap.get(rs.Id).Revenue2__c);
          rsDates.put(trigger.oldMap.get(rs.Id).Revenue2__c, trigger.oldMap.get(rs.Id).Month__c);
      } else if (!trigger.isDelete) {
          if (!rsIds.contains(rs.Revenue2__c)) {
            rsIds.add(rs.Revenue2__c);
          }
          if (trigger.isUpdate && !isMap) continue;
          if (rsDates.get(rs.Revenue2__c) == null || rsDates.get(rs.Revenue2__c) > rs.Month__c) {
            rsDates.put(rs.Revenue2__c, rs.Month__c);
          }
      }
    }
  	system.debug('rsIds::>>>>>>>>' + rsIds);
    if (!rsIds.isEmpty()) {
      	Id former = null;
      	Double summe = 0;
      	Integer i = 0;
      	for (Revenue_Schedule2__c rs : [select Month__c, Id, Booked_Quantity__c, Billing_Category__c, Monthly_Quantity__c, Delivered_Sum__c, Revenue2__c , Discount_II__c, 
                    	Revenue2__r.Sales_Price_incl_Targeting__c, Revenue2__r.Runtime_Months__c, Revenue2__r.No_of_Auto_renewals__c, Sales_Price_Net_Net_Net__c, 
                    	Actions_Recorded__c, Days_recorded__c, Invoice_Quantity__c, Product__r.RecordTypeId, Auto_renew_month__c, tmp_Net_Net_Net_delivered__c, 
                    	Is_Cancellation__c, Opportunity__r.RecordTypeId, Net_Net_Net_expected__c, Ad_Id__c  
                      	from Revenue_Schedule2__c 
                      	where Revenue2__c IN :rsIds order by Revenue2__c, Month__c asc]) 
                      	//where ((((Ad_Id__c != '' and Ad_Id__c != '0') or (Order_Id__c != '' and Order_Id__c != '0'))) or Billing_Category__c = 'Fix Price' or Billing_Category__c = 'CPO') and Revenue2__c IN :rsIds order by Revenue2__c, Month__c asc]) 
      {
	      system.debug('rs::>>>>>>>>' + rs);
	      Boolean changed = false;
	      if (((rs.Ad_Id__c != '' && rs.Ad_Id__c != '0') || (rs.Order_Id__c != '' && rs.Order_Id__c != '0')) || rs.Billing_Category__c == 'Fix Price' || rs.Billing_Category__c == 'CPO') {
        		if (former == null || former != rs.Revenue2__c) {
              		summe = 0;
              		former = rs.Revenue2__c;
            	}
  
            	summe += rs.Monthly_Quantity__c;
        		Boolean isContinue = false;
            	if (rsDates.get(rs.Revenue2__c) != null && rsDates.get(rs.Revenue2__c) > rs.Month__c && !(rs.Billing_Category__c == 'Fix Price' || rs.Billing_Category__c == 'CPO')) {
              		//continue;//SUY Sreymol 27/05/2014- to avoid continue to other rs without recalculating Net/Net/Net Delivered
              		isContinue = true;
            	}
            
        		if (!isContinue) {
              		if (summe != rs.Delivered_Sum__c) {
                		rs.Delivered_Sum__c = summe;
                		changed = true;
              		}
    
              		if ((rs.Billing_Category__c == 'Fix Price' || rs.Billing_Category__c == 'CPO' || rs.Billing_Category__c == null) && rs.Invoice_Quantity__c != 1) {
                		rs.Invoice_Quantity__c = 1;
                		changed = true;
              		}
          
              		if (rs.Billing_Category__c == 'CPA') {
                 		rs.Invoice_Quantity__c = rs.Monthly_Quantity__c;
              		}
    
              		if ((rs.Billing_Category__c == 'CPM' || rs.Billing_Category__c == 'CPC' )) {
                 		if (rs.Booked_Quantity__c >= rs.Delivered_Sum__c) {
                    		if (rs.Invoice_Quantity__c != rs.Monthly_Quantity__c) {
                      			rs.Invoice_Quantity__c = rs.Monthly_Quantity__c;
                        		changed = true;
                    		}
                 	} else if (rs.Booked_Quantity__c >= (rs.Delivered_Sum__c - rs.Monthly_Quantity__c)) {
                    	if (rs.Invoice_Quantity__c != rs.Booked_Quantity__c - (rs.Delivered_Sum__c - rs.Monthly_Quantity__c)) {
                      		rs.Invoice_Quantity__c = rs.Booked_Quantity__c - (rs.Delivered_Sum__c - rs.Monthly_Quantity__c);
                      		changed = true;
                    	}
                 	} else if (rs.Invoice_quantity__c != 0) {
                   	 	rs.Invoice_Quantity__c = 0;
                    	changed = true;
                 	}
              	}
        	}
        }
        
        // Recalculate the field Net/Net/Net Delivered
        Decimal tmpDelivered = 0;
        if (!ClsOpportunityService.IGNORE_UPDATE_RS && !ClsBookingOppUpdate.IGNORE_UPDATE_RS) {
          	tmpDelivered = RevenueSchedule2Handler.doCalculateTmpNetnetnetDelivered(rs);
            if (tmpDelivered != rs.tmp_Net_Net_Net_delivered__c) {
              	rs.tmp_Net_Net_Net_delivered__c = tmpDelivered;
              	changed = true;
            }
        }
        if (changed) rss.add(rs);
      }
    }
    
    system.debug('rss::>>>>>>>>' + rss);
    if (!rss.isEmpty()) {
        update rss;
    }
}