global class RevenueCopyDelivery implements Database.Batchable<SObject>{

    private string limitSQL = '';
    private string whereSQL = '';

    public void setTest(Boolean b) {
        limitSQL = ' limit 10';
    }

    public void setWhere(String whereQuery) {
        whereSQL = ' ' + whereQuery;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'select Id, Revenue2__c from OpportunityLineItem where Revenue2__c != \'\'' + whereSQL + limitSQL;
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List<OpportunityLineItem> olis = (List<OpportunityLineItem>) scope;
        for (OpportunityLineItem oli :olis) {

            Map<Date, Revenue_Schedule_daily2__c> revMapDay  = new Map<Date, Revenue_Schedule_daily2__c>();
            Map<Date, Revenue_Schedule2__c> revMapMon        = new Map<Date, Revenue_Schedule2__c>();
            List<Revenue_Schedule_daily2__c> rsds           = new List<Revenue_Schedule_daily2__c>();
            List<Revenue_Schedule2__c> rss                  = new List<Revenue_Schedule2__c>();

            // Daylies
            for (Revenue_Schedule_daily2__c rsd : [select Id, Day__c, Invoice_Quantity__c, Delivered_AI__c, Delivered_AI_Lifetime__c, Clicks_Recorded__c, Clicks_Recorded_Lifetime__c from Revenue_Schedule_daily2__c where Revenue2__c = :oli.Revenue2__c and Day__c <= TODAY]) {
                revMapDay.put(rsd.Day__c, rsd);
            }

            for (Revenue_Schedule_daily2__c rsd : [select Id, Day__c, Billing_Category__c, Invoice_Quantity__c, Delivered_AI__c, Delivered_AI_Lifetime__c, Clicks_Recorded__c, Clicks_Recorded_Lifetime__c from Revenue_Schedule_daily2__c where Revenue2__c = :oli.Revenue2__c and Delivered_AI__c=null and Clicks_Recorded__c=null and Day__c <= TODAY]) {
                if (revMapDay.containsKey(rsd.Day__c)) {
                    Revenue_Schedule_daily2__c orgRSD    = revMapDay.get(rsd.Day__c);
                    rsd.Delivered_AI__c                 = orgRSD.Delivered_AI__c;
                    rsd.Delivered_AI_Lifetime__c        = orgRSD.Delivered_AI_Lifetime__c;
                    rsd.Clicks_Recorded__c              = orgRSD.Clicks_Recorded__c;
                    rsd.Clicks_Recorded_Lifetime__c     = orgRSD.Clicks_Recorded_Lifetime__c;
                    if (rsd.Billing_Category__c=='CPA') {
                        rsd.Invoice_Quantity__c         = orgRSD.Invoice_Quantity__c;
                    }
                    rsds.add(rsd);
                }
            }

            if (!rsds.isEmpty()) {
                update rsds;
            }

            // Monthlys
            for (Revenue_Schedule2__c rs : [select Id, Month__c, Invoice_Quantity__c, Delivered_AI__c, Delivered_AI_Lifetime__c, Clicks_Recorded__c, Clicks_Recorded_Lifetime__c from Revenue_Schedule2__c where Revenue2__c = :oli.Revenue2__c and Month__c <= TODAY]) {
                revMapMon.put(rs.Month__c, rs);
            }

            for (Revenue_Schedule2__c rs : [select Id, Month__c, Billing_Category__c, Delivered_AI__c, Delivered_AI_Lifetime__c, Clicks_Recorded__c, Clicks_Recorded_Lifetime__c from Revenue_Schedule2__c where Revenue2__c = :oli.Revenue2__c and Delivered_AI__c=null and Clicks_Recorded__c=null and Month__c <= TODAY]) {
                if (revMapMon.containsKey(rs.Month__c)) {
                    Revenue_Schedule2__c orgRS       = revMapMon.get(rs.Month__c);
                    rs.Delivered_AI__c              = orgRS.Delivered_AI__c;
                    rs.Delivered_AI_Lifetime__c     = orgRS.Delivered_AI_Lifetime__c;
                    rs.Clicks_Recorded__c           = orgRS.Clicks_Recorded__c;
                    rs.Clicks_Recorded_Lifetime__c  = orgRS.Clicks_Recorded_Lifetime__c;
                    if (rs.Billing_Category__c=='CPA') {
                        rs.Invoice_Quantity__c          = orgRS.Invoice_Quantity__c;
                    }
                    rss.add(rs);
                }
            }

            if (!rss.isEmpty()) {
                update rss;
            }
        }
    }

    global void finish(Database.BatchableContext BC){
    }

    // Test Method
    static testMethod void testRevenueCopyDelivery() {
        Test.startTest();
        RevenueCopyDelivery p = new RevenueCopyDelivery();
        p.setWhere('');
        p.setTest(true);
        Database.executeBatch(p);
        Test.StopTest();
    }
}