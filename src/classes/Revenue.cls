public without sharing class Revenue {

    public Revenue(){

    } 

    static OpportunityLineItem oli;
//  static Boolean init = false;
    static Map<Id, Id> rev2oli;
    static Set<Id> revIds;
    static List<Revenue_Schedule2__c> revScheds;
    static List<Revenue_Schedule_daily2__c> revSchedsDaily;
    static Boolean isTrigger;
    static List <Revenue_Schedule2__c> monthsToDelete;
    static List <Revenue_Schedule_daily2__c> daysToDelete;
    static List <Revenue_Schedule2__c> monthsToInsert;
    static List <Revenue_Schedule2__c> monthsToUpdate;
    static List <Revenue_Schedule2__c> monthsToUpsert;
    static List <Revenue_Schedule_daily2__c> daysToInsert;
    static List <Revenue_Schedule_daily2__c> daysToUpdate;
    static List <Revenue_Schedule_daily2__c> daysToUpsert;
    static List <Revenue2__c>                revsToUpdate;
    static List <OpportunityLineItem>       olisToUpdate;
    static List <exclusive_Placement__c>    BePlanDelete;
    static List <exclusive_Placement__c>    BePlanInsert;
    static List <exclusive_Placement__c>    BePlanUpdate;
    static List <exclusive_Placement__c>    BePlanUpsert;
    public static List <Error>              errorList;
/*
    public static void setInit(Boolean i) {
        init = i;
    } 
*/  
    // Call revenue creation
    public static void start(List<OpportunityLineItem> ols) {
        start(ols, false);
    }
 
    // Call revenue generation (future)
    @future
    public static void start(Set<Id> olids) {
        OpportunityLineItem[] ols = [select Id from OpportunityLineItem where Id IN : olids];
        start(ols, false);
    }

    // Aufruf Revenue-Erstellung
    public static void start(List<OpportunityLineItem> ols, Boolean t) {

        monthsToDelete  = new List <Revenue_Schedule2__c>();
        daysToDelete    = new List <Revenue_Schedule_daily2__c>();
        monthsToInsert  = new List <Revenue_Schedule2__c>();
        daysToInsert    = new List <Revenue_Schedule_daily2__c>();
        monthsToUpdate  = new List <Revenue_Schedule2__c>();
        daysToUpdate    = new List <Revenue_Schedule_daily2__c>();
        monthsToUpsert  = new List <Revenue_Schedule2__c>();
        daysToUpsert    = new List <Revenue_Schedule_daily2__c>();
        olisToUpdate    = new List <OpportunityLineItem>();
        revsToUpdate    = new List <Revenue2__c>();

        BePlanDelete    = new List <exclusive_Placement__c>();
        BePlanInsert    = new List <exclusive_Placement__c>();
        BePlanUpdate    = new List <exclusive_Placement__c>();
        BePlanUpsert    = new List <exclusive_Placement__c>();
        
        errorList       = new List<Error>();

        isTrigger = (t == false || t == null) ? false : true;
        rev2oli = new Map<Id, Id>();
        revIds = new Set<Id>();
        Map<Id, OpportunityLineItem> oliMap = getLineItems(ols);
        if (oliMap != null) {
            List<OpportunityLineItem> newOlis = new List<OpportunityLineItem>();

            for (OpportunityLineItem ol : oliMap.values()) {
                if (ol.from_Date__c == null || ol.until_Date__c == null) {
                    continue;
                }

                if (ol.Revenue2__c == null) {
                    newOlis.add(ol);
                }
            }

            if (!newOlis.isEmpty()) {
                List<Revenue2__c> r2 = createRevenues(newOlis);

                for (Integer i=0; i < newOlis.size(); i++) {
                    oliMap.get(newOlis.get(i).Id).Revenue2__c = r2.get(i).Id;
                    olisToUpdate.add(newOlis.get(i));
                }
            }

            for (OpportunityLineItem ol : oliMap.values()) {
                if (ol.from_Date__c == null || ol.until_Date__c == null) {
                    continue;
                }

                if (ol.Revenue2__c != null) {
                    rev2oli.put(ol.Revenue2__c, ol.Id);
                    revIds.add(ol.Revenue2__c);
                }
            }

            Map<Id, Revenue2__c> revenueMap                     = new Map<Id, Revenue2__c>();
            Map<Id, List<Revenue_Schedule2__c>> rsMap           = new Map<Id, List<Revenue_Schedule2__c>>();
            Map<Id, List<Revenue_Schedule_daily2__c>> rsdMap    = new Map<Id, List<Revenue_Schedule_daily2__c>>();
            Map<Id, List<exclusive_Placement__c>> bpMap         = new Map<Id, List<exclusive_Placement__c>>();

            if (!revIds.isEmpty()) {
                revenueMap  = getRevenues(revIds);
                //if (!isTrigger) {
                    rsMap       = getRS(revIds);
                    rsdMap      = getRSD(revIds);
                    bpMap        = getBP(revIds);
                //}
            }

            for (OpportunityLineItem ol : oliMap.values()) {
                if (ol.from_Date__c == null || ol.until_Date__c == null) {
                    continue;
                }
                oli = ol;
/*
                system.debug('lineItem: ' + oli);
                system.debug('oli.Id: ' + oli.Id);
                system.debug('revenueMap: ' + revenueMap);
                system.debug('revenueMap.get(oli.Id): ' + revenueMap.get(oli.Id));
*/
                if (!rsMap.containsKey(oli.Id)) {
                    rsMap.put(oli.Id, new List<Revenue_Schedule2__c>());
                }

                if (!rsdMap.containsKey(oli.Id)) {
                    rsdMap.put(oli.Id, new List<Revenue_Schedule_daily2__c>());
                }

                if (!bpMap.containsKey(oli.Id)) {
                    bpMap.put(oli.Id, new List<exclusive_Placement__c>());
                }
                
                if (revenueMap.containsKey(oli.Id)) {
                    updateRevenue(oli, revenueMap.get(oli.Id), rsMap.get(oli.Id), rsdMap.get(oli.Id), bpMap.get(oli.Id));
                }
                else {
                    Error e = new Error('kein Revenue zu LineItem ' + oli.Id, oli);
                    e.objMap = revenueMap;
//                  system.debug(oli.Id + ' -> ' + oli);
//                  system.debug('revenueMap -> ' + revenueMap);
                    errorList.add(e);
                }
            }
        }
        system.debug('updates');
        updateData();
        deleteData();
        //sendMail();
    }
/*
    private static String list2string(Set<Id> ids) {
        String idString = '';
        for (Id id : ids) {
            idString += '\'' + String.valueOf(id) + '\',';
        }
        idString = idString.substring(0,idString.length()-1);
        return idString;
    }
*/

    // Error processing
    public class Error{
        public String errorMsg {get;set;}
        public SObject obj {get;set;}
        public list<SObject> objList {get;set;}
        public map<Id, SObject> objMap {get;set;}

        public Error (String errorMsg, SObject obj) {
            this.errorMsg   = errorMsg;
            this.obj        = obj;
        }

        public Error (String errorMsg, list<SObject> objList) {
            this.errorMsg   = errorMsg;
            this.objList    = objList;
        }

        public Error (String errorMsg, map<Id, SObject> objMap) {
            this.errorMsg   = errorMsg;
            this.objMap     = objMap;
        }
    }

    // Revenues read
    private static Map<Id, Revenue2__c> getRevenues(Set<Id> rIds) {
        Map<Id, Revenue2__c> revMap = new Map<Id, Revenue2__c>();

        for (Revenue2__c rev : [select Id, Product_Startdate__c, Product_Enddate__c from Revenue2__c where Id IN :rIds]) {
            if (rev2oli.containsKey(rev.Id)) {
                revMap.put(rev2oli.get(rev.Id), rev);
            }
        }

        return revMap;
    }

    // RS read
    private static Map<Id, List<Revenue_Schedule2__c>> getRS(Set<Id> rIds) {
        Map<Id, List<Revenue_Schedule2__c>> rsMap = new Map<Id, List<Revenue_Schedule2__c>>();

        for (Revenue_Schedule2__c rs : [select Revenue2__c, Id, Month__c, UniqueKey__c from Revenue_Schedule2__c where Revenue2__c IN :rIds order by Month__c asc ]) {
            if (rev2oli.containsKey(rs.Revenue2__c)) {
                if (!rsMap.containsKey(rev2oli.get(rs.Revenue2__c))) {
                    rsMap.put(rev2oli.get(rs.Revenue2__c), new List<Revenue_Schedule2__c>());
                }
                rsMap.get(rev2oli.get(rs.Revenue2__c)).add(rs);
            }
        }

        return rsMap;
    }

    // RSD read
    private static Map<Id, List<Revenue_Schedule_daily2__c>> getRSD(Set<Id> rIds) {
        Map<Id, List<Revenue_Schedule_daily2__c>> rsdMap = new Map<Id, List<Revenue_Schedule_daily2__c>>();

        for (Revenue_Schedule_daily2__c rsd : [select Revenue2__c, Id, Day__c, UniqueKey__c from Revenue_Schedule_daily2__c where Revenue2__c IN :rIds order by Day__c asc ]) {
            if (rev2oli.containsKey(rsd.Revenue2__c)) {
                if (!rsdMap.containsKey(rev2oli.get(rsd.Revenue2__c))) {
                    rsdMap.put(rev2oli.get(rsd.Revenue2__c), new List<Revenue_Schedule_daily2__c>());
                }
                rsdMap.get(rev2oli.get(rsd.Revenue2__c)).add(rsd);
            }
        }

        return rsdMap;
    }

    // EP read
    private static Map<Id, List<exclusive_Placement__c>> getBP(Set<Id> rIds) {
        Map<Id, List<exclusive_Placement__c>> bpMap = new Map<Id, List<exclusive_Placement__c>>();

        for (exclusive_Placement__c bpd : [select Revenue2__c, Id, Date__c, UniqueKey__c from exclusive_Placement__c where Product__r.exclusive_Placement__c=true and Revenue2__c IN :rIds order by Date__c asc ]) {
            if (rev2oli.containsKey(bpd.Revenue2__c)) {
                if (!bpMap.containsKey(rev2oli.get(bpd.Revenue2__c))) {
                    bpMap.put(rev2oli.get(bpd.Revenue2__c), new List<exclusive_Placement__c>());
                }
                bpMap.get(rev2oli.get(bpd.Revenue2__c)).add(bpd);
            }
        }

        return bpMap;
    }

    // Needed new revenues (stockpiled -> unassigned to oli), create
    public static List<Revenue2__c> createRevenues(List<OpportunityLineItem> olis){
        List<Revenue2__c> r2 = new List<Revenue2__c>();
        for (OpportunityLineItem ol : olis) {
            r2.add(new Revenue2__c());
        }
        insert r2;
        return r2;
    }

    // Call processing, storing the required objects
    public static void updateRevenue(OpportunityLineItem oitem, Revenue2__c rev, List<Revenue_Schedule2__c> rs, List<Revenue_Schedule_daily2__c> rsd, List<exclusive_Placement__c> bpd){
        system.debug('updateRevenue');
        /*
        Revenue2__c revenueObj = rev;
        Revenue2__c revenueObj_old = rev==null ? new Revenue2__c() : rev.clone();

        if (rev == null) {
            system.debug(oitem);
            system.debug(rev);
        }

        revenueObj = setRevenueValues(rev);
        */

        Revenue2__c revenueObj_old = rev.clone();
        Revenue2__c revenueObj = setRevenueValues(rev);

        revsToUpdate.add(revenueObj);
        //if (!isTrigger) {
            updateMonthlyRevenue(revenueObj, rs, revenueObj_old);
            //if (oitem.Opportunity.RecordType.DeveloperName != 'eBay_US') {
                updateDailyRevenue(revenueObj, rsd);
            //}
            updateBelegungsplan(revenueObj, bpd);
        //}
    }

    // Number of days in the RS calculation
    private static Integer getDaysForThisMonth(Revenue2__c revenueObj, Date month) {
        Date start = null;
        Date ende = null;
        system.debug('>>>revenueObj: '+ revenueObj);
// 
        Date endOfMonth = month.addMonths(1).addDays(-1);
        if (revenueObj.Product_Startdate__c >= month) {
            start = revenueObj.Product_Startdate__c;

            if (revenueObj.Product_Enddate__c > endOfMonth) {
                ende = endOfMonth;
            }
            else {
                ende = revenueObj.Product_Enddate__c;
            }
        }
        else {
            start = month;

            if (revenueObj.Product_Enddate__c > endOfMonth) {
                ende = endOfMonth;
            }
            else {
                ende = revenueObj.Product_Enddate__c;
            }
        }

        Integer days = start.daysBetween(ende)+1;
        return days;
    }

    // To be applied, to delete, to change RSD
    private static void updateDailyRevenue(Revenue2__c revenueObj, List<Revenue_Schedule_daily2__c> dailyRevenueList){
//      List<Revenue_Schedule_daily2__c> dailyRevenueList = revenueObj.Revenue_Schedule_dailys__r;
        system.debug('>> dailyRevenueList: ' + dailyRevenueList);

        Map<Date, Revenue_Schedule_daily2__c> rsdByDay = new Map<Date, Revenue_Schedule_daily2__c>();
        for (Revenue_Schedule_daily2__c rsd : dailyRevenueList) {
            rsdByDay.put(rsd.Day__c, rsd);
        }

        Date startDay;
        Date endDay;
        if(dailyRevenueList.isEmpty()) {
            startDay    = oli.from_Date__c;
            endDay      = oli.until_Date__c;
        }
        else {
            startDay    = dailyRevenueList.get(0).Day__c > oli.from_Date__c ? oli.from_Date__c : dailyRevenueList.get(0).Day__c;
            endDay      = dailyRevenueList.get(dailyRevenueList.size()-1).Day__c < oli.until_Date__c ? oli.until_Date__c : dailyRevenueList.get(dailyRevenueList.size()-1).Day__c;
        }

        system.debug('>> startDay: ' + startDay);
        system.debug('>> endDay: ' + endDay);

        system.debug('>> startDay.daysBetween(endDay): ' + startDay.daysBetween(endDay));
        List<Date> daysTotal = new List<Date>();
        Date actualDate = startDay;
        for (Integer m = 0; m <= startDay.daysBetween(endDay); m++) {
            daysTotal.add(actualDate.addDays(m));
        }

        List<Revenue_Schedule_daily2__c> upsertRSD = new List<Revenue_Schedule_daily2__c>();
        List<Revenue_Schedule_daily2__c> deleteRSD = new List<Revenue_Schedule_daily2__c>();

        for (Date d : daysTotal) {
/*
            system.debug('>> d: ' + d);
            system.debug('>> from_Date__c: ' + oli.from_Date__c);
            system.debug('>> until_Date__c: ' + oli.until_Date__c);
*/
            Revenue_Schedule_daily2__c dailyRevenue;
            if (rsdByDay.containsKey(d)) {
                dailyRevenue    = rsdByDay.get(d);
            }
            else {
                dailyRevenue                    = new Revenue_Schedule_daily2__c();
                dailyRevenue.Day__c             = d;
                dailyRevenue.Day_Text__c        = String.valueOf(d);
                dailyRevenue.Opportunity__c     = oli.OpportunityId;
                dailyRevenue.Product__c         = oli.PricebookEntry.Product2Id;
                dailyRevenue.Revenue2__c         = revenueObj.Id;
                dailyRevenue.UniqueKey__c       = revenueObj.Id + String.valueOf(d);
//                dailyRevenue.CurrencyIsoCode    = oli.Opportunity.CurrencyIsoCode;
            }

            if (rsdByDay.containsKey(d)) {
             // if (oli.from_Date__c <= d && oli.until_Date__c >= d) {
               if ((oli.PriceBookEntry.Product2.RecordType.Name == 'DART5' || oli.PriceBookEntry.Product2.RecordType.Name == 'DART6') && oli.from_Date__c <= d && oli.until_Date__c >= d) {
                 //upsertRSD.add(dailyRevenue);
                }
                else {
                    deleteRSD.add(dailyRevenue);
                }
            }
            else {
              //if (oli.from_Date__c <= d && oli.until_Date__c >= d) {
               if ((oli.PriceBookEntry.Product2.RecordType.Name == 'DART5' || oli.PriceBookEntry.Product2.RecordType.Name == 'DART6') && oli.from_Date__c <= d && oli.until_Date__c >= d) {
                    upsertRSD.add(dailyRevenue);
                }
            }
        }

        if (!upsertRSD.isEmpty()) {
            daysToUpsert.addAll(upsertRSD);
        }
        if (!deleteRSD.isEmpty()){
            daysToDelete.addAll(deleteRSD);
        }
    }

    // To be applied, to delete, to change EP
    private static void updateBelegungsplan(Revenue2__c revenueObj, List<exclusive_Placement__c> bpList){

        if (!oli.PricebookEntry.Product2.exclusive_Placement__c) {
            return;
        }

        system.debug('>> bpList: ' + bpList);

        Map<Date, exclusive_Placement__c> bpByDay = new Map<Date, exclusive_Placement__c>();
        for (exclusive_Placement__c bp : bpList) {
            bpByDay.put(bp.Date__c, bp);
        }

        Date startDay;
        Date endDay;
        if(bpList.isEmpty()) {
            startDay    = oli.from_Date__c;
            endDay      = oli.until_Date__c;
        }
        else {
            startDay    = bpList.get(0).Date__c > oli.from_Date__c ? oli.from_Date__c : bpList.get(0).Date__c;
            endDay      = bpList.get(bpList.size()-1).Date__c < oli.until_Date__c ? oli.until_Date__c : bpList.get(bpList.size()-1).Date__c;
        }

        system.debug('>> startDay: ' + startDay);
        system.debug('>> endDay: ' + endDay);

        system.debug('>> startDay.daysBetween(endDay): ' + startDay.daysBetween(endDay));
        List<Date> daysTotal = new List<Date>();
        Date actualDate = startDay;
        for (Integer m = 0; m <= startDay.daysBetween(endDay); m++) {
            daysTotal.add(actualDate.addDays(m));
        }

        List<exclusive_Placement__c> upsertBP = new List<exclusive_Placement__c>();
        List<exclusive_Placement__c> deleteBP = new List<exclusive_Placement__c>();

//      system.debug('>>> bpByDay: ' + bpByDay);

        for (Date d : daysTotal) {
/*
            system.debug('>> d: ' + d);
            system.debug('>> from_Date__c: ' + oli.from_Date__c);
            system.debug('>> until_Date__c: ' + oli.until_Date__c);
*/
            exclusive_Placement__c bp;
//          system.debug('bpByDay.containsKey(d): ' + bpByDay.containsKey(d));
            if (bpByDay.containsKey(d)) {
                bp  = bpByDay.get(d);
            }
            else {
                bp                      = new exclusive_Placement__c();
                bp.Date__c              = d;
                bp.Opportunity__c       = oli.OpportunityId;
                bp.Product__c           = oli.PricebookEntry.Product2Id;
                bp.Revenue2__c           = revenueObj.Id;
                bp.Line_Item_ID__c      = oli.Id;
                bp.UniqueKey__c         = revenueObj.Id + String.valueOf(d);
//                bp.CurrencyIsoCode      = oli.Opportunity.CurrencyIsoCode;
            }

//          system.debug('bpByDay.containsKey(d): ' + bpByDay.containsKey(d));
            if (bpByDay.containsKey(d)) {
                if (oli.from_Date__c <= d && oli.until_Date__c >= d) {
                    //upsertBP.add(bp);
                }
                else {
                    deleteBP.add(bp);
                }
            }
            else {
                if (oli.from_Date__c <= d && oli.until_Date__c >= d && d >= date.today()) {
                    upsertBP.add(bp);
                }
            }
        }

        if (!upsertBP.isEmpty()) {
            BePlanUpsert.addAll(upsertBP);
        }
        if (!deleteBP.isEmpty()){
            BePlanDelete.addAll(deleteBP);
        }
    }

    // To be applied, to delete, to change RS
    private static void updateMonthlyRevenue(Revenue2__c revenueObj, List<Revenue_Schedule2__c> monthlyRevenueList, Revenue2__c revenueObj_old){
//      List<Revenue_Schedule2__c> monthlyRevenueList = revenueObj.Revenue_Schedules__r;
        system.debug('monthlyRevenueList>>>>>>>>>>>' + monthlyRevenueList);
        
        Map<Date, Revenue_Schedule2__c> rsByMonth = new Map<Date, Revenue_Schedule2__c>();
        for (Revenue_Schedule2__c rs : monthlyRevenueList) {
            rsByMonth.put(rs.Month__c, rs);
        }

        Date startMonth;
        Date endMonth;
        if(monthlyRevenueList.isEmpty()) {
            startMonth  = oli.from_Date__c.toStartOfMonth();           
         
            if ((oli.PriceBookEntry.Product2.RecordType.Name == 'DART5' || oli.PriceBookEntry.Product2.RecordType.Name == 'DART6' || oli.Length_Months__c == 0)) {   
                endMonth    = oli.until_Date__c.toStartOfMonth();
            }
// remove the final month as classified products do not run in final month
            else {
                endMonth    = oli.until_Date__c.toStartOfMonth()-1;
            }       
        } else {
            startMonth  = monthlyRevenueList.get(0).Month__c > oli.from_Date__c.toStartOfMonth() ? oli.from_Date__c.toStartOfMonth() : monthlyRevenueList.get(0).Month__c;    
//          endMonth    = monthlyRevenueList.get(monthlyRevenueList.size()-1).Month__c < oli.until_Date__c.toStartOfMonth() ? oli.until_Date__c.toStartOfMonth() : monthlyRevenueList.get(monthlyRevenueList.size()-1).Month__c;
          
            if ((oli.PriceBookEntry.Product2.RecordType.Name == 'DART5' || oli.PriceBookEntry.Product2.RecordType.Name == 'DART6' || oli.Length_Months__c == 0)) {
                endMonth    = monthlyRevenueList.get(monthlyRevenueList.size()-1).Month__c < oli.until_Date__c.toStartOfMonth() ? oli.until_Date__c.toStartOfMonth() : monthlyRevenueList.get(monthlyRevenueList.size()-1).Month__c; 
            } else {
                endMonth   = monthlyRevenueList.get(monthlyRevenueList.size()-1).Month__c < oli.until_Date__c.toStartOfMonth() ? oli.until_Date__c.toStartOfMonth()-1 : monthlyRevenueList.get(monthlyRevenueList.size()-1).Month__c;
            }
        }

        system.debug('>> startMonth: ' + startMonth);
        system.debug('>> endMonth: ' + endMonth);

        List<Date> monthsTotal = new List<Date>();
        Date actualDate = startMonth;
        
        for (Integer m = 0; m <= startMonth.monthsBetween(endMonth); m++) {
//          actualDate = actualDate.addMonths(m);
                 monthsTotal.add(actualDate.addMonths(m));
//            }                                   
        }

        List<Revenue_Schedule2__c> upsertRS = new List<Revenue_Schedule2__c>();
        List<Revenue_Schedule2__c> deleteRS = new List<Revenue_Schedule2__c>();
        for (Date d : monthsTotal) {
/*
            system.debug('>> d: ' + d);
            system.debug('>> from_Date__c: ' + oli.from_Date__c.toStartOfMonth());
            system.debug('>> until_Date__c: ' + oli.until_Date__c.toStartOfMonth());
*/
            Revenue_Schedule2__c monthlyRevenue;
            if (rsByMonth.containsKey(d)) {
                monthlyRevenue  = rsByMonth.get(d);
            }
            else {
                monthlyRevenue  = new Revenue_Schedule2__c();
                monthlyRevenue.Month__c             = d;
                monthlyRevenue.Month_Text__c        = String.valueOf(d);
                monthlyRevenue.Opportunity__c       = oli.OpportunityId;
                monthlyRevenue.Product__c           = oli.PricebookEntry.Product2Id;
                monthlyRevenue.Revenue2__c          = revenueObj.Id;
                monthlyRevenue.UniqueKey__c         = revenueObj.Id + String.valueOf(d);
//              monthlyRevenue.CurrencyIsoCode    = oli.Opportunity.CurrencyIsoCode;

                // Bunhor @06-Jan-14: (from BatchAutoRenewal or Cancelled item approved) new inserting RS price will be token from Rate Card of 3 Months Products
                setPriceFrom3MonthsProductRateCard(oli, monthlyRevenue);
                System.debug('==================monthlyRevenue=='+monthlyRevenue);
            }
            
            if (rsByMonth.containsKey(d)) {
                if (    (oli.from_Date__c.toStartOfMonth() == oli.until_Date__c.toStartOfMonth() && oli.until_Date__c.toStartOfMonth() == monthlyRevenue.Month__c.toStartOfMonth())||
                        (oli.PriceBookEntry.Product2.RecordType.Name != 'DART5' && oli.PriceBookEntry.Product2.RecordType.Name != 'DART6' && oli.from_Date__c.toStartOfMonth() <= d && oli.until_Date__c.toStartOfMonth() > d) ||
                        ((oli.PriceBookEntry.Product2.RecordType.Name == 'DART5' || oli.PriceBookEntry.Product2.RecordType.Name == 'DART6') && oli.from_Date__c.toStartOfMonth() <= d && oli.until_Date__c.toStartOfMonth() >= d)
                    ) {
                    if (revenueObj_old.Product_Startdate__c != oli.from_Date__c || revenueObj_old.Product_Enddate__c != oli.until_Date__c) {
                        monthlyRevenue.Days_delivered_this_Month__c = getDaysForThisMonth(revenueObj, d);
                        upsertRS.add(monthlyRevenue);
                    }
                } else {
                    deleteRS.add(monthlyRevenue);
                }
            } else {
                if (oli.from_Date__c.toStartOfMonth() <= d && (oli.PriceBookEntry.Product2.RecordType.Name == 'DART5' || oli.PriceBookEntry.Product2.RecordType.Name == 'DART6') ? oli.until_Date__c.toStartOfMonth() >= d : oli.until_Date__c.toStartOfMonth() > d || oli.from_Date__c.toStartOfMonth()==oli.until_Date__c.toStartOfMonth()) {
                    monthlyRevenue.Days_delivered_this_Month__c = getDaysForThisMonth(revenueObj, d);
                    upsertRS.add(monthlyRevenue);
                }
            }
        }
        
        if (!upsertRS.isEmpty()) {
            monthsToUpsert.addAll(upsertRS);
        }
        if (!deleteRS.isEmpty()){
            monthsToDelete.addAll(deleteRS);
        }
    }
/*
    // zu l?schende RSD identifizieren und sammeln (ungenutzt??)
    private static void removeDailyRevenue(List<Revenue_Schedule_daily2__c> dailyRevenueList, Date startDate, Date endDate){
        List<Revenue_Schedule_daily2__c> toRemoveDailyRevenueList = new List<Revenue_Schedule_daily2__c>();
        for(Revenue_Schedule_daily2__c actualDay : dailyRevenueList){
            if(actualDay.Day__c.daysBetween(startDate)>0){
                toRemoveDailyRevenueList.add(actualDay);
            }
            if(actualDay.Day__c.daysBetween(endDate)<0){
                toRemoveDailyRevenueList.add(actualDay);
            }
        }
        daysToDelete.addAll(toRemoveDailyRevenueList);
    }

    // zu l?schende RS identifizieren und sammeln (ungenutzt??)
    private static void removeMonthlyRevenue(List<Revenue_Schedule2__c> monthlyRevenueList, Date startDate, Date endDate){
        List<Revenue_Schedule2__c> toRemoveMonthlyRevenueList = new List<Revenue_Schedule2__c>();

        for(Revenue_Schedule2__c actualMonth : monthlyRevenueList){
            if(actualMonth.Month__c.monthsBetween(startDate)>0){
                toRemoveMonthlyRevenueList.add(actualMonth);
            }
            if(actualMonth.Month__c.monthsBetween(endDate)<0){
                toRemoveMonthlyRevenueList.add(actualMonth);
            }
        }
        monthsToDelete.addAll(toRemoveMonthlyRevenueList);
    }
*/
    // Revenue object creating and populating with data
    private static Revenue2__c setRevenueValues(Revenue2__c revenueObj){
        revenueObj.Opportunity__c               = oli.Opportunity.Id;
        revenueObj.Adserver_Id__c               = oli.Ad_Id__c;
        revenueObj.Order_Id__c                  = oli.Adserver_ID_Order_ID__c;
        revenueObj.Ad_Name__c                   = oli.Ad_Name__c;
        revenueObj.Billing_Category__c          = oli.Billing_category__c;
        revenueObj.Booked_Quantity__c           = oli.Quantity;
//        revenueObj.Customer_Order_No__c         = oli.Customer_Order_No__c;
        revenueObj.Discount_I__c                = oli.Rate_Discount_I__c;
        revenueObj.Discount_II__c               = oli.Rate_Discount_II__c;
        revenueObj.Targeting_surcharge__c       = oli.Targeting_surcharge__c ;
        revenueObj.Sales_Price__c               = oli.UnitPrice;
        revenueObj.Sales_Price_incl_Targeting__c = oli.Sales_Price_incl_Targeting__c; 
        revenueObj.Sales_Price_Net__c           = oli.Sales_Price_Net__c;
        revenueObj.Sales_Price_Net_Net__c       = oli.Sales_Price_Net_Net__c;
        revenueObj.Sales_Price_Net_Net_Net__c   = oli.Sales_Price_Net_Net_Net__c;        
//        revenueObj.Price_incl_Targeting__c    = oli.Sales_Price_incl_Targeting__c;
        revenueObj.Product_Enddate__c           = oli.until_Date__c;
        revenueObj.Product_Startdate__c         = oli.from_Date__c;
        revenueObj.Rate_Card_Discount__c        = oli.Rate_Card_Discount_percent__c;
//        revenueObj.Special_Agency_Discount__c   = oli.Special_Agency_Discount_Percent__c;
        revenueObj.Product__c                   = oli.PricebookEntry.Product2Id;
        revenueObj.Line_Description__c          = oli.Description;
        revenueObj.LineItemId__c                = oli.Id;
//        revenueObj.additional_Billing_information_1__c = oli.additional_Billing_information1__c;
//        revenueObj.additional_Billing_information_2__c = oli.additional_Billing_information2__c;
//        revenueObj.CurrencyIsoCode              = oli.Opportunity.CurrencyIsoCode;
        revenueObj.Package_line_item__c         = oli.package_line_item__c;
        revenueObj.Order_Id__c                  = oli.Adserver_ID_Order_ID__c;
        //added additional_Billing_information_1__c and additional Billing Information_2__c
        revenueObj.Net_Net_Net__c               = oli.Opportunity.Pricebook2.Name.startsWith('DE') ? oli.Net_Net_Net__c :oli.Net_Net_Net__c;

        if(oli.AE__c){
            revenueObj.AE__c                    = oli.AE__c == TRUE ? 15 : 15;
        }else{
            revenueObj.AE__c                    = 0;
        }

        return revenueObj;
        
    }

    // LineItems read
    private static Map<Id, OpportunityLineItem> getLineItems(List<OpportunityLineItem> olis){
        Map<Id, OpportunityLineItem> oliMap = new Map<Id, OpportunityLineItem>([
                        select  Id,
                                Notice_Date__c,
                                AE__c,
                                Length_Months__c, 
                                Additional_Time_Days__c, 
                                OpportunityId,  
                                Ad_Name__c, 
                                Description, 
                                Net_Net_Net__c, 
                                UnitPrice,  
                                Rate_Card_Discount_percent__c, 
                                Sales_Price_incl_Targeting__c, 
                                Sales_Price_Net__c, 
                                Sales_Price_Net_Net__c, 
                                Sales_Price_Net_Net_Net__c, 
                                ListPrice, 
                                Adserver_ID_Order_ID__c, 
                                Rate_Discount_II__c, 
                                Rate_Discount_I__c, 
                                Targeting_surcharge__c, 
                                Billing_category__c, 
                                Quantity, 
                                Ad_Id__c, 
                                from_Date__c, 
                                until_Date__c, 
                                package_line_item__c, 
                                Revenue2__c, 
                                Revenue2__r.Id, 
                                Targeting__c, 
                                Opportunity.RecordType.DeveloperName, 
                                Opportunity.Pricebook2.Name,
                                Opportunity.Auto_Renewal__c,
                                PricebookEntry.Product2.RecordType.Name,  
                                PricebookEntry.Product2Id, 
                                PricebookEntry.Product2.exclusive_Placement__c,
                                PricebookEntry.Product2.Site__c
                        from OpportunityLineItem where Id IN :olis]);
// eBay Map<Id, OpportunityLineItem> oliMap = new Map<Id, OpportunityLineItem>([select AE__c, Description, Special_Agency_Discount_Percent__c, Rate_Card_Discount_percent__c, Sales_Price_incl_Targeting__c, Amount_Net__c, Amount_Net_Net_Net__c, ListPrice, Rate_Discount_II__c, Rate_Discount_I__c, Customer_Order_No__c, additional_Billing_information1__c, additional_Billing_information2__c, Billing_category__c, Quantity, Ad_Id__c, from_Date__c, until_Date__c, Adserver_ID_Order_ID__c, package_line_item__c, Revenue2__c, Revenue2__r.Id, Id, OpportunityId, Opportunity.RecordType.DeveloperName, Targeting__c, PricebookEntry.Product2Id, PricebookEntry.Product2.exclusive_Placement__c, Opportunity.CurrencyIsoCode, Opportunity.Pricebook2.Name from OpportunityLineItem where Id IN :olis]);
//      Map<Id, OpportunityLineItem> oliMap = new Map<Id, OpportunityLineItem>([select AE__c, Description, Special_Agency_Discount_Percent__c, Rate_Card_Discount_percent__c, Sales_Price_incl_Targeting__c, Amount_Net_Net_Net__c, ListPrice, Rate_Discount_II__c, Rate_Discount_I__c, Customer_Order_No__c, Billing_category__c, Quantity, Ad_ID__c, from_Date__c, until_Date__c, Revenue2__c, Revenue2__r.Id, Id, OpportunityId, Targeting__c, PricebookEntry.Product2Id, PricebookEntry.Product2.Belegungsplan_aktiviert__c from OpportunityLineItem where Id IN :olis]);
        return oliMap;
    }

    // DMLs
    // alle deletes
    private static void deleteData() {
        if (!monthsToDelete.isEmpty()) {
            delete monthsToDelete;
        }
        if (!daysToDelete.isEmpty()) {
            delete daysToDelete; 
        }
        if (!BePlanDelete.isEmpty()) {
            delete BePlanDelete;
        }
    }

    // All updates/inserts/upserts
    private static void updateData() {

        /*
        if (!daysToInsert.isEmpty()) {
            insert daysToInsert;
        }
        if (!monthsToInsert.isEmpty()) {
            insert monthsToInsert;
        }
        if (!BePlanInsert.isEmpty()) {
            insert BePlanInsert;
        }
*/      system.debug('IGNORE_UPDATE_RS:>>>>>>>>>>' + ClsOpportunityService.IGNORE_UPDATE_RS);
        if (!daysToUpsert.isEmpty()) {
            upsert daysToUpsert UniqueKey__c;
        }
        if (!monthsToUpsert.isEmpty()) {
            upsert monthsToUpsert UniqueKey__c;
        }
        if (!BePlanUpsert.isEmpty()) {
            upsert BePlanUpsert UniqueKey__c;
        }


        if (!revsToUpdate.isEmpty()) {
            update revsToUpdate;
        }

        if (!olisToUpdate.isEmpty()) {
            update olisToUpdate;
        }
    }
 

//===========================================================
    
    /** 
     * Map Site.Id to Product2 and its rate cards
     * @Author Bunhor
     * @CreatedDate 21-Dec-14 
     */
    private static Map<String, Product2> mSiteId2RateCardProduct{
        get{
            if(mSiteId2RateCardProduct==null){
                mSiteId2RateCardProduct = new Map<String, Product2>();
                for(Product2 pp : [ Select id, Length_months__c, Site__c, Site__r.Name,
                                            (Select UnitPrice From PricebookEntries Where UseStandardPrice=true and IsActive=true limit 1) 
                                    From Product2 
                                    Where Rack_Rate__c=true and Rate_Card__c=true and Site__c!=null]){
                    mSiteId2RateCardProduct.put(pp.Site__c, pp);
                }
            }
            return mSiteId2RateCardProduct;
        }
    }
    
    /** Default site name, 'London'*/
    private static final String DEFAULT_SITE = 'London';
    
    /**
     * Getting Product2 by Site.Id. If site is not matched, default site will be used.
     * @Author Bunhor
     * @CreatedDate 21-Dec-14
     * @Param siteId Site.Id
     * @Return Product2 
     */
    private static Product2 getProductBySiteId(String siteId){
        Product2 pro = mSiteId2RateCardProduct.get(siteId); 
        if(pro!=null) return pro;
        
        // take default product
        for(Product2 pp : mSiteId2RateCardProduct.values()){
            if(pp.Site__r.Name == DEFAULT_SITE) return pp;
        } 
        return null;
    } 
    
     
    /**
     * Getting Map of Product2Id+Lenght to list of rate card. 
     * @Author Bunhor
     * @CreatedDate 21-Dec-14 
     */ 
    private static Map<String, List<Rate_Card__c>> mProIdAndLen2RateCards_3MonthsPorducts{
        get{
            if(mProIdAndLen2RateCards_3MonthsPorducts == null){
                Id[] lstProId = new List<Id>();
                for(Product2 pp : mSiteId2RateCardProduct.values()) {
                    lstProId.add(pp.id);
                }
                mProIdAndLen2RateCards_3MonthsPorducts = getMapProIdAndLen2RateCards(lstProId);  
            }
            return mProIdAndLen2RateCards_3MonthsPorducts;
        }
    }
    
    /** Catched whether the RS's price of this Revenue will taking from rate card. */ 
    public static Map<String, Boolean> mapRevId2IsRCprice = new Map<String, Boolean>();     
     
        
     
    /**
     * Logic getting price from Rate_Card__c of 3 months prodoct
     * @Author Bunhor
     * @CreatedDate 31-Dec-14
     * @Param item 
     * @Param rs  
     * @Return void 
     */
    public static void setPriceFrom3MonthsProductRateCard(OpportunityLineItem item, Revenue_Schedule2__c rs){
        Boolean isRCprice = mapRevId2IsRCprice.get(rs.Revenue2__c);
        if(isRCprice==null || isRCprice==false) return; 
        
       // if(item.Opportunity.Auto_Renewal__c==true) return;
         
        Product2 pro = getProductBySiteId(item.PricebookEntry.Product2.Site__c);
        if(pro==null) return;
         
        String key = getProIdAndLenAsKey(pro.id, pro.Length_months__c); 
        Rate_Card__c rc = getRateCard(Integer.valueOf(item.Quantity), mProIdAndLen2RateCards_3MonthsPorducts.get(key));
        System.debug('==================Rate_Card__c rc='+rc); 
        if(rc!=null){
            rs.tmp_Net_Net_Net_delivered__c = rc.Sales_Price__c*item.Quantity/pro.Length_months__c;
            rs.Auto_Renew_Sales_Price__c = rc.Sales_Price__c;
        }else{
            rs.Auto_Renew_Sales_Price__c = pro.PricebookEntries.isEmpty()? 0 : pro.PricebookEntries[0].UnitPrice;
        } 
        rs.Net_Net_Net_Expected_Auto_Renew__c= true; 
        
    }
    
    /** Catched Product2Id+Lenght to list of rate card for getRateCard method */  
    private static Map<String, List<Rate_Card__c>> mProIdAndLen2RateCards;  
    
    /**
     * Getting Rate_Card__c for the OpportunityLineItem
     * @Author Bunhor
     * @CreatedDate 31-Dec-14
     * @Param item 
     * @Param items   
     * @Return Rate_Card__c 
     */
    public static Rate_Card__c getRateCard(OpportunityLineItem item, OpportunityLineItem[] items){
        if(mProIdAndLen2RateCards == null){
            String[] Product2Ids = new List<String>();
            for(OpportunityLineItem li : items){ Product2Ids.add(li.PricebookEntry.Product2Id); }
            mProIdAndLen2RateCards = getMapProIdAndLen2RateCards(Product2Ids);
        }  
        String key = getProIdAndLenAsKey(item.PricebookEntry.Product2Id, item.PricebookEntry.Product2.Length_months__c);
        return getRateCard(Integer.valueOf(item.Quantity), mProIdAndLen2RateCards.get(key)); 
    }
    
     
    /**
     * Getting Product2Id+Lenght to list of rate card. The list must order by Quantity2__c asc
     * @Author Bunhor
     * @CreatedDate 21-Dec-14 
     * @Param Product2Ids for getting its rate cards 
     * @Return Map 
     */
    private static Map<String, List<Rate_Card__c>> getMapProIdAndLen2RateCards(String[] Product2Ids){  
        Map<String, List<Rate_Card__c>> returner = new Map<String, List<Rate_Card__c>>();
        for(Rate_Card__c rc : [ select id, Quantity2__c, Length__c, Product__c, Sales_Price__c from Rate_Card__c where Product__c in :Product2Ids and Active__c = true order by Quantity2__c asc]){
            String key = getProIdAndLenAsKey(rc.Product__c, rc.Length__c);  
            List<Rate_Card__c> tem = returner.get(key); 
            if(tem==null){
                tem = new List<Rate_Card__c>();
                returner.put(key, tem);
            } 
            tem.add(rc);                
        }
        return returner;     
    }
     
    /**
     * Getting Rate_Card__c knowing Quantity.  
     * @Author Bunhor
     * @CreatedDate 21-Dec-14 
     * @Param qty
     * @Param lstRC must order by Quantity2__c asc
     * @Return Rate_Card__c 
     */ 
    private static Rate_Card__c getRateCard(Integer qty , List<Rate_Card__c> lstRC){ 
        System.debug('==================qty='+qty);
        System.debug('==================lstRC='+lstRC);
        if(lstRC!=null && !lstRC.isEmpty()){
            
            if(qty < lstRC[0].Quantity2__c ) return null; 
            
            if(lstRC.size()==1) return lstRC[0];  
            
            if(qty > lstRC[lstRC.size()-1].Quantity2__c) return lstRC[lstRC.size()-1];
            
            for(Integer i=0; i<lstRC.size(); i++){
                if(qty < lstRC[i].Quantity2__c) return lstRC[i-1];
                else if(qty == lstRC[i].Quantity2__c) return lstRC[i];
            }
        }  
        return null;
    }
     
    /**
     * Getting Product2Id and lenMonth as key 
     * @Author Bunhor
     * @CreatedDate 21-Dec-14
     * @Param Product2Id
     * @Param lenMonth
     * @Return String as key 
     */   
    private static String getProIdAndLenAsKey(String Product2Id, Object lenMonth){  
        return  getID15(Product2Id) + (lenMonth==null? '' : ''+Integer.valueOf(lenMonth)); 
    } 
    
    /**
     * Getting id 15 digits
     * @Author Bunhor
     * @CreatedDate 21-Dec-14 
     * @Param id 
     * @Return String id 
     */ 
    private static String getID15(String id){
        return id==null ? '' : id.left(15); 
    }
    
    
    
    
// Test Methods
  static testMethod void RevenuesTest() {
    new Revenue();
    PricebookEntry pbe = null;
    try {
      pbe  = [select Id, Pricebook2Id from PricebookEntry where (NOT Pricebook2.Name like '%Standard%') and Pricebook2.IsActive=true and IsActive=true and Product2.IsActive=true and Product2.exclusive_Placement__c = true limit 1];
    }
    catch (Exception e) {
      pbe  = [select Id, Pricebook2Id from PricebookEntry where (NOT Pricebook2.Name like '%Standard%') and Pricebook2.IsActive=true and IsActive=true and Product2.IsActive=true limit 1];
    }

    Opportunity testOpp = new Opportunity();
    testOpp.Name = 'revenue_test Opp';
    testOpp.StageName = 'test Stage';
    testOpp.CloseDate = Date.newInstance(2009, 3, 4);
    testOpp.P_O_Number__c =' 123';
//    testOpp.Start_of_Campaign__c = Date.newInstance(2009, 3, 5);
//    testOpp.End_of_Campaign__c = Date.newInstance(2011, 3, 5);
//    testOpp.Pre_approved_template__c = false;
    testOpp.Pricebook2Id  = pbe.Pricebook2Id;
//    testOpp.CurrencyIsoCode  = pbe.CurrencyIsoCode;
//    testOpp.Final_Advertiser_Amount__c  = 10;
    insert testOpp;
    OpportunityLineItem testOli = new OpportunityLineItem();
    testOli.OpportunityId = testOpp.Id;
    testOli.from_Date__c = Date.newInstance(2010, 3, 5);
    testOli.until_Date__c = Date.newInstance(2010, 4, 7);

    Date testDate = testOli.from_Date__c;
    testDate = testDate.addMonths(1);

    testOli.Quantity = 10000;
    testOli.TotalPrice = 1000000;
    testOli.PricebookEntryId = pbe.Id;

//    testOli.PricebookEntryId = [Select Id from PricebookEntry where IsActive = true and Product2.exclusive_Placement__c = true limit 1].Id;
    insert testOli;

    Test.startTest();

    List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
    olis.add(testOli);
    Revenue.start(olis);

    testOli.from_Date__c = Date.newInstance(2010, 2, 4);
    testOli.until_Date__c = Date.newInstance(2010, 5, 8);
    update testOli;
    olis.clear();
    olis.add(testOli);
    Revenue.start(olis);
    
    testOli.from_Date__c = Date.newInstance(2010, 5, 6);
    testOli.until_Date__c = Date.newInstance(2010, 3, 10);
    //update testOli;
    Revenue.start(olis);
    
    // getting price from rate card
    testOli =[select id, Quantity, Revenue2__c, Opportunity.Auto_Renewal__c, PricebookEntry.Product2Id, PricebookEntry.Product2.Length_months__c, PricebookEntry.Product2.Site__c from OpportunityLineItem where id =:testOli.id];
    Revenue.mapRevId2IsRCprice.put(testOli.Revenue2__c, true);
    setPriceFrom3MonthsProductRateCard(testOli, new Revenue_Schedule2__c(Revenue2__c=testOli.Revenue2__c));
    Object ob = getRateCard(testOli, new List<OpportunityLineItem>{testOli});
    
    Test.stopTest();
  }
}