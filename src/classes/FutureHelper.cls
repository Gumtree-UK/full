public without sharing class FutureHelper {
    public static void deleteRevenue_with_Oli(Set<Id> revs) {
        // trigger is inactive => method is unused
    }
    
    @future
    public static void updateRSD (Set<Id> revs) {

        List<Revenue_Schedule_daily2__c> rsds= new List<Revenue_Schedule_daily2__c>();
        Id former = null;
        Double summe = 0;
        Date today = system.today();
         for (Revenue_Schedule_daily2__c rsd : [select Id, Revenue2__c, Day__c, Invoice_Quantity__c, Booked_Quantity__c, Billing_Category__c, Daily_Quantity__c, Delivered_Sum__c from Revenue_Schedule_daily2__c where Ad_ID__c != '' and Ad_ID__c != '0' and Day__c <= :today and Revenue2__c IN :revs order by Revenue2__c, Day__c asc]) {
            if (former == null || former != rsd.Revenue2__c) {
                summe = 0;
                former = rsd.Revenue2__c;
            }

            summe += rsd.Daily_Quantity__c;

            Boolean changed = false;
            if (summe != rsd.Delivered_Sum__c) {
                rsd.Delivered_Sum__c = summe;
                changed = true;
            }

            if ((rsd.Billing_Category__c == 'CPD' || rsd.Billing_Category__c == 'CPO') && rsd.Invoice_Quantity__c != 1) {
                rsd.Invoice_Quantity__c = 1;
                changed = true;
            }
            else if (rsd.Billing_Category__c == 'CPM' || rsd.Billing_Category__c == 'CPC') {
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
            update rsds;
        }
    }
/*
    @future
    public static void copyDiscountsFromOpportunityToLineItems (Set<Id> oppIds) {
        if (!oppIds.isEmpty()) {
            List<OpportunityLineItem> olis = new List<OpportunityLineItem>();

            Map<Id, Opportunity> oppValuesMap = new Map<Id, Opportunity>();

            for (Opportunity opp : [select Id, AE__c, Rate_Card_Discount__c, Rate_Card_Discount_this_Order_new__c, additional_Wallpaper_discount__c, Customer_Discount_override__c, Rate_Special_Agency_Discount__c, Special_Agency_Discount__c from Opportunity where Id IN : oppIds]) {
                oppValuesMap.put(opp.Id, opp);
            }

            for (OpportunityLineItem oli : [select Rate_Discount_I__c, Rate_Discount_II__c, Special_Agency_Discount_Percent__c, Id, Quantity, Sales_Price_incl_Targeting__c, OpportunityId, Opportunity.Account.Wallpaper_Discount__c, Rebate_In_Kind__c, IsWallpaper__c from OpportunityLineItem where OpportunityId IN :oppIds]) {
                system.debug(oppValuesMap.get(oli.OpportunityId).additional_Wallpaper_discount__c);
    
                oli.AE__c                               = oli.Rebate_In_Kind__c                                      ? false : oppValuesMap.get(oli.OpportunityId).AE__c;
                oli.Rate_Card_Discount_percent__c       = oli.Rebate_In_Kind__c || oli.IsWallpaper__c == 'Wallpaper' ? 0     : oppValuesMap.get(oli.OpportunityId).Rate_Card_Discount_this_Order_new__c;
                oli.Rate_Discount_I__c                  = oli.Rebate_In_Kind__c || oli.IsWallpaper__c == 'Wallpaper' ? 0     : oppValuesMap.get(oli.OpportunityId).Customer_Discount_override__c;
                oli.Rate_Discount_II__c                 = oppValuesMap.get(oli.OpportunityId).additional_Wallpaper_discount__c && oli.IsWallpaper__c == 'Wallpaper' ? oli.Opportunity.Account.Wallpaper_Discount__c : oli.IsWallpaper__c == 'Wallpaper' ? 0 : oli.Rate_Discount_II__c;
    
                oli.Rate_Discount_II__c                 = oppValuesMap.get(oli.OpportunityId).additional_Wallpaper_discount__c && oli.IsWallpaper__c == 'Wallpaper' && oppValuesMap.get(oli.OpportunityId).Rate_Discount_II__c > 0 &&  oppValuesMap.get(oli.OpportunityId).CreatedDate < Date.newInstance(2010, 10, 27)? oppValuesMap.get(oli.OpportunityId).Rate_Discount_II__c : oli.Rate_Discount_II__c;
    
                oli.Rate_Discount_II__c                 = oli.Rebate_In_Kind__c                                     ? 100   : oli.Rate_Discount_II__c;
    
                oli.Rate_Discount_II__c                 = oli.Rate_Discount_II__c == null           ? 0 : oli.Rate_Discount_II__c;
                oli.Rate_Card_Discount_percent__c       = oli.Rate_Card_Discount_percent__c == null ? 0 : oli.Rate_Card_Discount_percent__c;
                oli.Wallpaper_Discount__c               = oli.Wallpaper_Discount__c == null         ? 0 : oli.Wallpaper_Discount__c;
                oli.Rate_Discount_I__c                  = oli.Rate_Discount_I__c == null            ? 0 : oli.Rate_Discount_I__c;
    
                Double nnn = 0;
                nnn  = oli.Sales_Price_incl_Targeting__c;
                nnn *= oli.Quantity;
                nnn *= (1 - oli.Rate_Card_Discount_percent__c / 100);
                nnn *= (1 - oli.Special_Agency_Discount_Percent__c / 100);
                nnn *= (1 - oli.Wallpaper_Discount__c / 100);
                nnn *= (1 - oli.Rate_Discount_I__c / 100);
                nnn *= (1 - oli.Rate_Discount_II__c / 100);
                nnn *= oli.AE__c ? 0.85 : 1;
    
                oli.Amount_Net_Net_Net__c = nnn;
                olis.add(oli);
            }
    
            if (!olis.isEmpty()) {
                update olis;
            }
        }
    }
*/
/*
    @future
    public static void deleteRevenue_with_Oli (Set<Id> revs) {
        try {
            Revenue2__c[] rev = [select Id from Revenue2__c where Id IN :revs];
            if (rev != null) {
                delete rev;
            }
        }
        catch(Exception e) {
            system.debug('Error on delete Revenues with LineItem ' + e.getMessage());
        }
    }
*/
    static testMethod void updateRSD() {
        List<Revenue_Schedule_daily2__c> rsds = new List<Revenue_Schedule_daily2__c>();
        Set<Id> revSet = new Set<Id>();

        Account acc = new Account(
        					Name='Die Firma',
        					BillingStreet = 'Test Street',
	                        BillingCity = 'Test City',
	                        BillingState = 'Test State',
	                        BillingPostalCode = '123',
	                        BillingCountry = 'GB',
	                        Country_Code__c='GB',
                            Bank_Country__c = 'GB'
        					);
        insert acc;

        Opportunity opp = new Opportunity(Name='Die Firma - Opportunity', AccountId=acc.Id, StageName='initial Offer', Probability=10, CloseDate=system.today());
        insert opp;

        Revenue2__c rev = new Revenue2__c();
        rev.Booked_Quantity__c = 1000;
        rev.Billing_Category__c = 'CPM';
        rev.AdServer_ID__c = '0815';
        insert rev;
        revSet.add(rev.Id);

        for (Integer i=0; i<=200; i++) {
            Revenue_Schedule_daily2__c rsd = new Revenue_Schedule_daily2__c();
            rsd.Revenue2__c = rev.Id;
            rsd.Opportunity__c = opp.Id;
            rsd.Day__c = system.today() - 170 + i;
            rsd.Delivered_AI__c = i;
            rsd.Delivered_Sum__c = 1000000;
            rsds.add(rsd);
        }

        insert rsds;

        updateRSD(revSet);
    }
/*
    static testMethod void copyDiscountsFromOpportunityToLineItems() {
        Account acc = new Account(
            Name='ApexTestAccount'
        );

        insert acc;

        Product2 prod = new Product2(
            Name='ApexTestProd',
            IsActive=true
        );

        insert prod;
        
        Advertising_Medium__c adm = new Advertising_Medium__c(
            Name    = 'tollstes Wallpaper'
        );
        insert adm;

        Pricebook2 pb = [select Id from Pricebook2 where IsStandard=true limit 1];

        PricebookEntry pbe = new PricebookEntry(
            UseStandardPrice=false,
            Product2Id=prod.Id,
            Pricebook2Id=pb.Id,
            UnitPrice=1.00,
            IsActive=true
        );

        insert pbe;

        Opportunity opp = new Opportunity(
            Name='Test Opp',
            Probability=100,
            StageName='gebucht',
            CloseDate=System.today(),
            Start_of_Campaign__c=System.today(),
            End_of_Campaign__c=System.today(),
            Pre_approved_template__c=true,
            AE__c = false,
            Customer_Discount_override__c=10,            
            Pricebook2Id=pb.Id
        );

        insert opp;

        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for (Integer i=0; i <= 85; i++) {
            OpportunityLineItem oli = new OpportunityLineItem(
                Quantity=100,
                TotalPrice=100.0,
                OpportunityId=opp.Id,
                Billing_category__c='CPM',
                Amount_Net_Net_Net__c=100.0,
                from_Date__c=System.today(),
                until_Date__c=System.today(),
                PricebookEntryId=pbe.Id
            );

            olis.add(oli);
        }
        insert olis;
        Revenue.start(olis);

        opp.AE__c = true;
        update opp;
        
        delete olis;
    }
*/
}