/* Calculates until (date) on opp line item using length (months) & extra (days)
   when product record type is not equal to DART5, DART6 or Daily Deals

Change log:
- GTCRM-749 - Auto-renewal/rolling/cancel opportunities - Update until (Date) to Cancellation Date

*/

trigger calculateExpiryDateOppLineItem on OpportunityLineItem (before insert, before update)      
  {
    set<id>oliids=new set<id>();
    set <id> peid=new set <id>();
      for (OpportunityLineItem oli : trigger.new) {          
        if (!oliids.contains(oli.pricebookentryid)){
          oliids.add(oli.pricebookentryid);
        }
      }     
      //if (!oliids.isempty()){
      if (!oliids.isempty()&& !ClsBookingOppUpdate.IGNORE_UNTILDATE_POP){
         for(pricebookentry pe:[select id from pricebookentry where id in :oliids and product2.RecordTypeId != '01220000000YCi7' and product2.RecordTypeId != '01220000000YahG' and product2.RecordTypeId != '01220000000Dlh0' and product2.RecordTypeId != '01220000000Ya7Y']){
            if (!peid.contains(pe.id)){
                peid.add(pe.id);
            }
         }
      }
     /* for (OpportunityLineItem oli : trigger.new) {          
        if (peid.contains(oli.pricebookentryid) && oli.from_Date__c != null && (oli.Length_Months__c != null || oli.Length_Months__c != 0) && (oli.Additional_Time_Days__c != null || oli.Additional_Time_Days__c == 0)) {  
          oli.until_Date__c = oli.from_Date__c.addMonths(oli.Length_Months__c.intValue());   
          oli.until_Date__c = oli.until_Date__c.addDays(oli.Additional_Time_Days__c.intValue());           
        }   
     }*/
      for (OpportunityLineItem oli : trigger.new) { 
        // End date not updated when start date is changed (Please re-enable this functionality)
        // update until date only when Length_Months__c,until_Date__c and Duration_weeks__c changed
        // if(trigger.isUpdate && !lstUntilDateUpdatedItem.contains(oli.id)) continue;          
        
        if (peid.contains(oli.pricebookentryid) && oli.from_Date__c != null && oli.Length_Months__c != null) {  
          oli.until_Date__c = oli.from_Date__c.addMonths(oli.Length_Months__c.intValue());   
          if(oli.Additional_Time_Days__c!=null)   oli.until_Date__c = oli.until_Date__c.addDays(oli.Additional_Time_Days__c.intValue());           
        }
       /* else if (peid.contains(oli.pricebookentryid) && oli.from_Date__c != null && oli.Duration_weeks__c != null) {  
          oli.until_Date__c = oli.from_Date__c.addDays(Integer.valueof(oli.Duration_weeks__c)*7); 
        } */   
     }   
     
  }