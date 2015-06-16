trigger update_Revenue_DaysDelivered on Revenue2__c (before insert, before update) {
  Date heute = system.today();
  
  for (Revenue2__c r : trigger.new) {
    r.Days_Delivered2__c = r.Product_Enddate__c >= heute && r.Product_Startdate__c <= heute ? r.Product_Startdate__c.daysBetween(heute) : r.Product_Enddate__c < heute ? r.Product_Startdate__c.daysBetween(r.Product_Enddate__c) +1 : 0;
  }
}