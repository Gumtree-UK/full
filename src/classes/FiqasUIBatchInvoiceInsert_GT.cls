/*
Class resides behind the Invoicing VF Page to create and send invoice list to Fiqas.nl Abillity Web system for billing.
It is based on billing frequencies and billing methods on opportunity record types, opportunities, 
opportunity line items and revenue schedules. 

2012.11.20 - updated to revenueschedule2 object for invoicing monthly in arrears across classifieds & banners
2012.11.20 - comment out daily deals functionality
2014-01-06 - Build out opportunity vertical specific record type
2014-05-14 - GTCRM-807 - Gumtree UK 

2014-09-22 - GTCRM-1334 Invoices sent lines for DD appearing in the pending Invoice list
2015-01-14 - GTCRM-1666 - Banners Invoicing - Changes to the tool
2015-02-23 - GTCRM-1793 - Direct Debit invoicing: Part 1 & 2 being displayed in view 'Mandate Last Week'

*/

public class FiqasUIBatchInvoiceInsert_GT {
    
    public list<InvoicesSent__c> InvoicesList; 
    public list<InvoicesSent__c> pageInvoicesListNew; 
    public InvoicesSent__c invDate = new InvoicesSent__c();     
    public set<id> OppRecordTypes;
    public string InvID;     
    
    public string message {get;set;}
    
    public integer InvCount = 0;
    public integer getInvCount() { return InvCount; }
    
    /*Getter and Setter for frequency*/
    public String Frequency = 'Not selected';
    public string getFrequency() { return this.Frequency; } 
    public void setFrequency(String s) {
        this.Frequency = s; 
        setPeriod(Period);
    } 
    
    /*Getter and Setter for period*/
    public String Period = 'Not selected'; 
    public string getPeriod() { return this.Period; }
    
    public void setPeriod (String s) {
        this.Period  = s; 
        InputDates(s);
        //pageNumber = 1;
    }
  
    public date dateEnd {
        
        get {
            date myDate = date.today();
            date weekStart = myDate.toStartofWeek();
            date monthStart= myDate.toStartofMonth();
            if (Period=='ThisM'){
                
                //dateEnd=date.today();old
                //dateEnd =  monthStart.addMonths(1).toStartofMonth().addDays(-1);
               //dateEnd =  weekStart == date.today()?weekStart.addDays(1):date.today();
               // dateEnd =  system.today().addDays(1);
                integer numberOfDays =date.daysInMonth(monthStart.year(),monthStart.month());
                dateEnd =Date.newInstance(monthStart.year(), monthStart.month(), numberOfDays); //added by TH 4/06/2014
            } 
            else if (Period=='ThisW'){
                 
                //dateEnd=date.today();old
               
                //dateEnd = weekStart == date.today()? weekStart.adddays(1):date.today();
                //  dateEnd = system.today().adddays(1);
                 dateEnd = weekStart.adddays(6);
            }
            else if (Period=='PreviousM'){
                dateEnd = date.today().toStartOfMonth() - 1;
            }
            // 2015-01-14 - GTCRM-1666 - Banners Invoicing - Changes to the tool
            else if (Period=='PreviousM2'){
                dateEnd = date.today().toStartOfMonth() - 32;
            }
            else if (Period=='PreviousW'){
                dateEnd = date.today().toStartOfWeek() - 1;
            }
            
/*            else if (Period=='PreviousWdeals'){
                dateEnd = date.today().toStartOfWeek() - 8;
            }  
*/
            else  if (Period == 'Custom') {
            dateEnd = invDate.until_Date__c;
        } 
        
        
            else dateEnd = date.today();
            return dateEnd;
           // return Date.valueOf('2014-04-10 00:00:00');
        }
        set;
    }
    
    public date dateStart {
        get{ 
            if (Period=='PreviousW' || Period=='ThisW' || Period=='PreviousWdeals' ){
            dateStart = dateEnd.toStartOfWeek();
            }
            else  if (dateEnd != null && Period != 'Custom') dateStart = dateEnd.toStartOfMonth(); 
            else  if (Period == 'Custom') {
            dateStart = invDate.from_Date__c;
            } 
            
            return dateStart;
            //return Date.valueOf('2014-04-01 00:00:00');
        
        } 
        set ;
    }
    
    public InvoicesSent__c getDateRange (){
        InputDates(Period);
        //pageNumber = 1;
        if (dateStart != null && dateEnd != null && Period != 'Custom') {
            invDate.from_Date__c = dateStart;
            invDate.until_Date__c = dateEnd;
        } 
        return invDate;
    }
    
    public void  resetPageNumber (){
         PageNumber = 1;
    } 
    
    public boolean getShowCol() {
        boolean ShowCol;
        if (CT != 'DailyDeals') { ShowCol = true; }
//        if (CT == 'DailyDeals') {ShowCol = false; }
        return ShowCol;
    }
    
    public boolean getDDShowCol() {
        boolean ShowCol;
        if (CT != 'DailyDeals') { ShowCol = false; }
//        if (CT == 'DailyDeals') {ShowCol = true; }
        return ShowCol;
    }

    
    public void InputDates (string Range) {
       // system.debug('Rang====='+Range);
        if (Range=='ThisM'){
            dateEnd = date.today();
            dateStart = dateEnd.toStartOfMonth();
            
        } 
        if (Range=='PreviousM') {
            dateEnd = date.today().toStartOfMonth() - 1;
            dateStart = dateEnd.toStartOfMonth();
        }
        // 2015-01-14 - GTCRM-1666 - Banners Invoicing - Changes to the tool
        if (Range=='PreviousM2') {
            dateEnd = date.today().toStartOfMonth() - 32;
            dateStart = dateEnd.toStartOfMonth();
        }
        if (Range=='ThisW'){
            dateStart = date.today().toStartOfWeek();
            dateEnd = dateStart + 6;
        } 
        
        if (Range=='PreviousW') {
            dateEnd = date.today().toStartOfWeek() - 1;
            dateStart = dateEnd - 6;
        }
/*  Daily deals business closed edit 20/11/2012
        if (Range=='PreviousWdeals') {
            dateEnd = date.today().toStartOfWeek() - 8;
            dateStart = dateEnd - 6;
        }
*/
        if (Range=='Not selected') {
            dateEnd = null;
            dateStart = null;
        }
        if (Range == 'Custom') {
            dateEnd = invDate.until_Date__c;
            dateStart = invDate.from_Date__c;
        }
    }
    
    public PageReference setDateRange() {
        dateEnd = invDate.until_Date__c;
        dateStart = invDate.from_Date__c;
            
        return null;
    }
    
    public boolean getDisableDateRange(){
        if (Period != 'Custom') {
            return true;
        }
        else {
            return false;
        }
    }
    
    /*Getter and Setter for Customer Type*/
    public String CT = '- None -';
    public string getCT() { return this.CT; }
    public void setCT (String s) {
        this.CT  = s;
        if (s == 'Banners'){    
            OppRecordTypes = new set<id>{'01220000000Y83P'};
            //                                                                Banners 
        }
        else if (s == 'Classifieds') {
            OppRecordTypes = new set<id>{'01220000000YY7J', '01220000000YaHA'  };
            //                                                                          Jobs                  Housing           
     }   
     
     
     else if (s == 'Motors') {
            OppRecordTypes = new set<id>{'012w0000000QBzr'};
            //                                                               Motors
        }

  /* else if (s == 'Direct Debits'){
           OppRecordTypes = new set<id>{'012w0000000QBzr', '01220000000YaHA' };
           //                                                               Motors                             Housing
     }
/* Daily deals business closed edit 20/11/2012
        else if (s == 'DailyDeals') {
            OppRecordTypes = new set<id>{'01220000000YZwQ','01220000000Ya08'};
            //                          Daily Deal initiation, Daily Deal delivery 
        }
*/

        this.Frequency = 'Not selected';
    }
    
    /*Getter for the frequency list*/
    public List<SelectOption> getPeriods() {
        List<SelectOption> optionList = new List<SelectOption>();
        optionList.add(new SelectOption('Not selected', '- None -'));
//        if (Frequency == 'Monthly in arrears' && CT != 'DailyDeals') {
        if (Frequency == 'Monthly in arrears') {            
            optionList.add(new SelectOption('ThisM', 'This month'));
            optionList.add(new SelectOption('PreviousM', 'Last month'));
            // 2015-01-14 - GTCRM-1666 - Banners Invoicing - Changes to the tool
            optionList.add(new SelectOption('PreviousM2', 'Previous month'));
            if(PM.equals('DD')){
                 optionList.add(new SelectOption('ThisW', 'Mandate This week')); // 20/05/2014 added This week in period 
                 optionList.add(new SelectOption('PreviousW', 'Mandate Last week'));//request by Sri 16/07/2014
            } 
        } 
        else 
//            if (Frequency == 'One Invoice' && CT != 'DailyDeals') {

              if (Frequency == 'Current Week') {     //TH added arrears Area 23-04-2014    (|| Frequency == 'Weekly in arrears')        
               
                optionList.add(new SelectOption('ThisW', 'This week'));
              }
              if(Frequency == 'One Invoice'){
                     optionList.add(new SelectOption('PreviousW', 'Last week'));
                     optionList.add(new SelectOption('ThisW', 'This week'));
                     optionList.add(new SelectOption('Custom', 'Custom'));// TH added if(Frequency == 'One Invoice')
                }
            
/* Daily deals business closed edit 20/11/2012 
            else
                if (CT == 'DailyDeals') {
                optionList.add(new SelectOption('PreviousWdeals', 'Last week'));
                optionList.add(new SelectOption('Custom', 'Custom'));
                }
*/                
        return optionList;     
    }
    
    public List<SelectOption> getCTs() {
        List<SelectOption> optionList = new List<SelectOption>();
        optionList.add(new SelectOption('Not selected', '- None -'));
        optionList.add(new SelectOption('Banners', 'Banners'));
        optionList.add(new SelectOption('Motors', 'Motors'));
        optionList.add(new SelectOption('Classifieds', 'Classifieds'));
    //    optionList.add(new SelectOption('Direct Debits', 'Direct Debits'));
//        optionList.add(new SelectOption('DailyDeals', 'Daily Deals'));
        return optionList;     
    }
    /*
        Getter for the Patment Method list
    */
    public List<SelectOption> getPMs() {
         List<SelectOption> optionPM = new List<SelectOption>();
         optionPM.add(new SelectOption('NonDD','Non Direct Debit'));
         optionPM.add(new SelectOption('DD','Direct Debit'));
         return optionPM;
    }
    /* getter setter for PM*/
    public String PM{get;set;}
    public List<SelectOption> getFrequencies() {
        List<SelectOption> optionList = new List<SelectOption>();
        optionList.add(new SelectOption('Not selected', '- None -'));
        if (CT == 'Classifieds' || CT == 'Motors' ) {
           
           // if(PM.equals('DD')) optionList.add(new SelectOption('Current Week', 'Current Week')); //20/05/2014 Do not need in frequency
            optionList.add(new SelectOption('Monthly in arrears', 'Monthly in arrears'));
            if(!PM.equals('DD'))optionList.add(new SelectOption('One Invoice', 'One Invoice'));
        
       /* if (!PM.equals('DD'))
             optionList.add(new SelectOption('Weekly in arrears', 'Weekly in arrears'));
        }*/
        }
         if (CT == 'Banners') {
           // if(PM.equals('DD'))optionList.add(new SelectOption('Current Week', 'Current Week'));  // 20/05/2014 Do not need in frequency
            optionList.add(new SelectOption('Monthly in arrears', 'Monthly in arrears'));
            
        }
        
        return optionList;     
    }
    
    public list<InvoicesSent__c > getInvoicesList() {
        InvoicesList = new list<InvoicesSent__c>();
        if (CT == 'Banners' || CT == 'Classifieds' || CT == 'Motors' ) {//|| CT == 'Direct Debits'
            getBanners();
        } 
/* Daily deals business closed edit 20/11/2012
           else {
            getDailyDeals();
        } 
*/
        InvCount = InvoicesList.size();
        
        //get partial list to display
        paginationExt.totalPageNumber = InvCount / paginationExt.pageSize;
        pageInvoicesListNew = paginationExt.BindData(pageNumber);
        Integer mod = InvCount - (paginationExt.totalPageNumber * paginationExt.pageSize);
        if (mod > 0 ) paginationExt.totalPageNumber++;
        if (paginationExt.totalPageNumber == null || paginationExt.totalPageNumber == 0) paginationExt.totalPageNumber = 1;
        return pageInvoicesListNew;
    }
    
/*Processing for Daily Deals - Daily deals business closed edit 20/11/2012
    public list<InvoicesSent__c> getDailyDeals() {
        list<OpportunityLineItem> InvoicesListD = new list<OpportunityLineItem>();
        list<InvoicesSent__c> InvoicedList;
        set<id> InvoicedDDSet = new set<id>();
        InvoicesList = new list<InvoicesSent__c>();
        if (Period != 'Not selected') {
            //IndID - date InvID__c
            string daySID = string.valueOf(date.today().day());
            if (daySID.length() == 1) daySID = '0' + daySID;
            string monSID = string.valueOf(date.today().month());
            if (monSID.length() == 1) monSID = '0' + monSID;
            string hourSID = string.valueOf(datetime.now().hour());
            if (hourSID.length() == 1) hourSID = '0' + hourSID;
            InvID = String.valueOf(date.today().year()) + monSID + daySID + 
            hourSID + String.valueOf(datetime.now().minute()) + String.valueOf(datetime.now().second());
            
            //exclude invoiced deals
            for (InvoicesSent__c tmpInv:[SELECT OpportunityLineItemId__c 
                                        FROM InvoicesSent__c
                                        WHERE Opportunity__r.Campaign_End__c >= :dateStart
                                        AND Opportunity__r.Campaign_End__c <= :dateEnd
                                        AND Opportunity__r.recordtypeid in :OppRecordTypes]){
                InvoicedDDSet.add(tmpInv.OpportunityLineItemId__c);
            }
            
            InvoicesListD = [SELECT 
                                Opportunity.Account.Account_number_fiqas__c,
                                Opportunity.AccountId,
                                Opportunity.Account.Name,
                                Opportunity.Fiqas_Product_Type__c,
                                PricebookEntry.Product2.Product_Subtype__c,
                                Opportunity.Fiqas_product_code__c,
                                Id, 
                                Opportunity.Name,
                                Quantity,
                                Sales_Price_Net_Net__c,
                                UnitPrice,
                                Net_Net_vendor__c,
                                VAT_Percentage_F__c,
                                Opportunity.Fiqas_VAT_Type__c,
                                from_Date__c,
                                until_Date__c,
                                Fiqas_From_Date__c,
                                Fiqas_Until_Date__c,
                                Opportunityid,
                                Deal_run__c,
                                Opportunity.IONumber__c, 
                                Opportunity.Account.Bank_Account_Holder_Name__c,
                                Opportunity.Account.Bank_BIC_SWIFT_Code__c,
                                Opportunity.Account.Bank_IBAN_Number__c,
                                Opportunity.Account.Bank_Country__c,
                                Vendor_Commission__c
                            FROM OpportunityLineItem
                            WHERE Opportunity.isWon = true
                            AND Deal_run__c = true
                            AND Opportunity.Campaign_End__c >= :dateStart
                            AND Opportunity.Campaign_End__c <= :dateEnd
                            AND Opportunity.recordtypeid in :OppRecordTypes
                            AND id not in :InvoicedDDSet limit 1000
                            ];
                            
            for (OpportunityLineItem tempInv: InvoicesListD) {
                InvoicesSent__c InvExport = new InvoicesSent__c(
                          Account__c = tempInv.Opportunity.Accountid,
                          Account_Name__c = tempInv.Opportunity.Account.name,
                          Account_Number_Fiqas__c = tempInv.Opportunity.Account.Account_number_fiqas__c,
                          Fiqas_Product_type__c = tempInv.Opportunity.Fiqas_Product_Type__c,
                          Fiqas_Product_Subtype__c = tempInv.PricebookEntry.Product2.Product_Subtype__c,
                          Fiqas_product_code__c = tempInv.Opportunity.Fiqas_product_code__c,
                          IOnumber__c = tempInv.Opportunity.IOnumber__c,
                          Fiqas_Invoice_Description__c = tempInv.Opportunity.Name,
                          Unit_Label__c = '',
                          Invoice_Quantity__c = tempInv.Quantity,
                          Sales_Price__c = tempInv.UnitPrice,
                          Invoice_Amount__c = tempInv.Net_Net_Vendor__c,
                          Fiqas_VAT_Percentage__c = tempInv.VAT_Percentage_F__c,
                          Apply_VAT__c = string.valueOf(tempInv.Opportunity.Fiqas_VAT_Type__c),
                          Amount_Paid__c = 0,
                          from_Date__c = tempInv.from_Date__c,
                          until_Date__c = tempInv.until_Date__c, 
                          Fiqas_Start_Date__c = tempInv.Fiqas_from_Date__c,
                          Fiqas_End_Date__c = tempInv.Fiqas_until_Date__c,
                          Opportunity__c = tempInv.Opportunityid,
                          InvoiceExtra1__c = tempInv.Opportunity.Account.Bank_Account_Holder_Name__c,
                          InvoiceExtra2__c = tempInv.Opportunity.Account.Bank_Country__c, 
                          InvoiceExtra3__c = tempInv.Opportunity.Account.Bank_BIC_SWIFT_Code__c,
                          InvoiceExtra4__c = tempInv.Opportunity.Account.Bank_IBAN_Number__c,
                          InvoiceLineExtra1__c = '', //string.valueOf(tempInv.id),
                          InvoiceLineExtra2__c = string.valueOf(tempInv.Vendor_Commission__c),
                          InvoiceLineExtra3__c =  '',   
                          InvID__c = InvID,
                          OpportunityLineItemId__c = tempInv.id
                );
                if (InvExport.InvoiceExtra1__c != null) {
                    InvExport.Selected__c = true;
                }
                else InvExport.Selected__c = false;
                InvoicesList.add(InvExport);
            }
        }
        return InvoicesList;
    }
*/    
    /*Processing for Banners*/
    public list<InvoicesSent__c> getBanners() {
        list<Revenue_Schedule2__c> InvoicesListRS = new list<Revenue_Schedule2__c>();
        list<OpportunityLineItem> InvoicesListOp = new list<OpportunityLineItem>();
        Map<String, List<Revenue_Schedule2__c>> mapOppIdToListRS = new Map<String, List<Revenue_Schedule2__c>>();
        map<string,decimal> InvAmtDelivered;   
        list<InvoicesSent__c> InvoicedList;
        set<id> InvoicedRSSet = new set<id>();  
        set<id> InvoicedOppSet = new set<id>();
        InputDates(Period);
        integer mon = dateEnd.month();
        integer year = dateEnd.year();
        //for string date to compare with FIQAS format date 
        string monS = string.valueOf(mon);
        if (monS.length() == 1) {monS = '0' + monS;}
        string yearS = string.valueOf(year);
        string dateStr = yearS + monS + '01';
       system.debug('Frequency =='+Frequency +'=dateStr+++' +dateStr);
       
        //select Opportunities for which Invoices has already been sent
        InvoicedList = [SELECT InvID__c 
                        FROM InvoicesSent__c
                        WHERE Fiqas_Start_Date__c = :dateStr
                        AND BillingFrequency__c = :Frequency
                        ];
            
        for (InvoicesSent__c inv: InvoicedList) {
            InvoicedRSSet.add(inv.InvID__c);
        }
        //one invoice
        if (Frequency == 'One Invoice' 
            && dateEnd != null 
            && dateStart != null 
            && ((dateStart.daysBetween(dateEnd) <= 7)
            || (Period == 'Custom'))) {
                
                if (CT == 'Banners') {
                    InvoicesListRS = [SELECT id,
                                        Opportunity__r.Accountid,
                                        Opportunity__r.Account.name,
                                        Opportunity__r.Account.BillingStreet, 
                                        Opportunity__r.Account.BillingCity, 
                                        Opportunity__r.Account.BillingCountry ,
                                        Opportunity__r.Account.BillingPostalCode ,  
                                        Opportunity__r.Account.Account_Number_Fiqas__c ,
                                        Opportunity__r.Account.Finance_Contact__r.Email ,
                                        Opportunity__r.Account.Apply_VAT__c,
                                        Opportunity__r.IOnumber__c,
                                        Opportunity__c,
                                        Opportunity__r.name,
                                        Opportunity__r.P_O_Number__c,
                                        Opportunity__r.BillingFrequency__c,
                                        Opportunity__r.Payment_Method__c,
                                        Opportunity__r.Direct_Debit_Mandate__c,
                                        Opportunity__r.Payment_Token__c,
                                        Opportunity__r.CloseDate ,
                                        Opportunity__r.Campaign_Start__c ,
                                        Opportunity__r.Campaign_End__c ,
                                        Opportunity__r.Fiqas_Product_Code__c ,
                                        Opportunity__r.Fiqas_VAT_Type__c,
                                        Opportunity__r.Agency__c ,
                                        Opportunity__r.Agency__r.name ,
                                        Opportunity__r.Agency__r.BillingStreet, 
                                        Opportunity__r.Agency__r.BillingCity, 
                                        Opportunity__r.Agency__r.BillingCountry ,
                                        Opportunity__r.Agency__r.BillingPostalCode , 
                                        Opportunity__r.Agency__r.Finance_Contact__r.Email ,                  
                                        Opportunity__r.Agency__r.Account_Number_Fiqas__c ,
                                        Opportunity__r.Agency__r.Apply_VAT__c,
                                        Product__c,
                                        Product__r.Product_Type__c,
                                        Product__r.Product_SubType__c,
                                        Product__r.Unit_Label__c,
                                        LineItemId__c,
                                        Fiqas_from_Date_Display__c,
                                        Fiqas_until_Date_Display__c,
                                        Invoice_Description__c,
                                        Invoice_Quantity__c,
                                        Sales_Price_Net_Net_Net__c,
                                        Net_Net_Net_Delivered__c,
                                        Net_Net_Net_Paid_inc_VAT__c,
                                        VAT_Percentage_F__c,
                                        Net_Net_Net__c,
                                        Month__c,
                                        Product_Startdate__c,
                                        Product_Enddate__c
                                FROM Revenue_Schedule2__c 
                                WHERE 
                                Opportunity__r.CloseDate >= :dateStart
                                AND Opportunity__r.CloseDate <= :dateEnd
                                //AND Opportunity__r.Account.Account_number_fiqas__c != 'GT'
                                AND Opportunity__r.BillingFrequency__c = :Frequency
                                AND Net_Net_Net_Delivered__c>0
                                AND Opportunity__r.isWon = true
                                AND Opportunity__r.recordtypeid = :OppRecordTypes
                                AND Opportunity__r.Ready_for_invoicing__c = true
                                AND 
                                id not in :InvoicedRSSet limit 1000
                                ];
                        //Banners
                }  else if (CT == 'Classifieds' || CT == 'Motors'  ) {// || CT == 'Direct Debits'
                    //select Opportunities for which Invoices has already been sent
                    InvoicedList = [SELECT InvID__c 
                                    FROM InvoicesSent__c
                                    WHERE Opportunity__r.CloseDate >= :dateStart
                                    AND Opportunity__r.CloseDate <= :dateEnd
                                    //AND Opportunity__r.Account.Account_number_fiqas__c != 'GT'
                                    AND BillingFrequency__c='One Invoice'
                                    ];
                    for (InvoicesSent__c inv: InvoicedList) {
                        InvoicedOppSet.add(inv.InvID__c);
                    }
                    InvoicesListOp = [SELECT id,
                                        Opportunity.Accountid,
                                        Opportunity.Account.name,
                                        Opportunity.Account.BillingStreet, 
                                        Opportunity.Account.BillingCity, 
                                        Opportunity.Account.BillingCountry ,
                                        Opportunity.Account.BillingPostalCode ,  
                                        Opportunity.Account.Account_Number_Fiqas__c ,
                                        Opportunity.Account.Finance_Contact__r.Email ,
                                        Opportunityid,
                                        Opportunity.name,
                                        Opportunity.IOnumber__c,
                                        Opportunity.P_O_Number__c,
                                        Opportunity.BillingFrequency__c,
                                        Opportunity.Payment_Method__c,
                                        Opportunity.Direct_Debit_Mandate__c,
                                        Opportunity.CloseDate ,
                                        Opportunity.Campaign_Start__c ,
                                        Opportunity.Campaign_End__c ,
                                        Opportunity.Fiqas_Product_Code__c , 
                                        Opportunity.Fiqas_Product_Type__c , 
                                        Opportunity.Fiqas_VAT_Type__c,
                                        Opportunity.Agency__c ,
                                        Opportunity.Agency__r.name ,
                                        Opportunity.Agency__r.BillingStreet, 
                                        Opportunity.Agency__r.BillingCity, 
                                        Opportunity.Agency__r.BillingCountry ,
                                        Opportunity.Agency__r.BillingPostalCode , 
                                        Opportunity.Agency__r.Finance_Contact__r.Email , 
                                        Opportunity.Direct_Debit_Mandate__r.Name,
                                        Opportunity.Payment_Token__c,             
                                        Opportunity.Agency__r.Account_Number_Fiqas__c ,
                                        PricebookEntry.Product2.Unit_Label__c, 
                                        PricebookEntry.Product2.Product_SubType__c, 
                                        PricebookEntry.Product2.Product_Type__c, 
                                        Invoice_Description__c,
                                        Quantity,
                                        Sales_Price_Net_Net_Net__c,
                                        Amount_Paid_inc_VAT__c,
                                        VAT_Percentage_F__c, 
                                        Net_Net_Net__c,
                                        Fiqas_from_Date__c,
                                        Fiqas_until_Date__c,
                                        from_Date__c,
                                        until_Date__c,
                                        Length_Months__c
                                FROM OpportunityLineItem 
                                WHERE Opportunity.CloseDate >= :dateStart
                                AND Opportunity.CloseDate <= :dateEnd
                                //AND Opportunity.Account.Account_number_fiqas__c != 'GT'
                                AND Opportunity.BillingFrequency__c = :Frequency
                                AND Opportunity.Net_Net__c>0
                                AND Opportunity.isWon = true
                                AND Opportunity.recordtypeid = :OppRecordTypes
                                AND Opportunity.Ready_for_invoicing__c = true
                                AND id not in :InvoicedOppSet limit 800
                                ];  
                    
                }   //   end not banner  
               system.debug('InvoicesListOp====='+InvoicesListOp)   ;
               if (InvoicesListOp != null && !InvoicesListOp.isEmpty()){ 
                //iterate over all opportunities, which met criteria of frequency and period
                for (OpportunityLineItem tempInvList: InvoicesListOp) {
                    //create new invoice
                    string inExtra1=tempInvList.Opportunity.Payment_Method__c.equals('Direct Debit')?string.valueOf(tempInvList.Opportunity.Direct_Debit_Mandate__r.Name):'';
                    InvoicesSent__c Invoice = new InvoicesSent__c(
                        Fiqas_Start_Date__c = tempInvList.Fiqas_from_Date__c,
                        Fiqas_End_Date__c = tempInvList.Fiqas_until_Date__c,
                        Fiqas_Product_type__c = tempInvList.Opportunity.Fiqas_Product_Type__c,
                        Fiqas_Product_Subtype__c = tempInvList.PricebookEntry.Product2.Product_SubType__c,
                        Fiqas_Product_Code__c = tempInvList.Opportunity.Fiqas_Product_Code__c,
                        Fiqas_VAT_Percentage__c = tempInvList.VAT_Percentage_F__c,
                        Apply_VAT__c = string.valueOf(tempInvList.Opportunity.Fiqas_VAT_Type__c),
                        BillingFrequency__c = tempInvList.Opportunity.BillingFrequency__c,
                        Opportunity__c = tempInvList.Opportunityid,
                        IOnumber__c = tempInvList.Opportunity.IOnumber__c,
                        from_Date__c = tempInvList.from_Date__c,
                        until_Date__c = tempInvList.until_Date__c,
                        Unit_Label__c = tempInvList.PricebookEntry.Product2.Unit_Label__c, //TODO: tempInvList.Product__r.Unit_Label__c,
                        Invoice_Amount__c = tempInvList.Net_Net_Net__c,
                        Fiqas_Invoice_Description__c = tempInvList.Invoice_Description__c,
                        Amount_Paid__c = tempInvList.Amount_Paid_inc_VAT__c,
                        Invoice_Quantity__c = tempInvList.Quantity,
                        Sales_Price__c = tempInvList.Sales_Price_Net_Net_Net__c,
                        InvoiceLineExtra1__c = string.valueOf(tempInvList.Length_Months__c),
                        Primary_contact_FirstName__c = '',
                        Primary_contact_LastName__c = '',
                        Primary_contact_Email__c = '',
                        //2014-08-18 - GTCRM-691 - Direct Debit Invoice Functionality - add field to invoices sent
                        InvoiceExtra1__c = inExtra1,//string.valueOf(tempInvList.Opportunity.Direct_Debit_Mandate__r.Name)
                        InvID__c = tempInvList.id,
                        Mandate__c=tempInvList.Opportunity.Direct_Debit_Mandate__c
// undo                 Mandate__c=tempInvList.Opportunity.Mandate__c//TH 23-04-2014
                        );
                    if (Invoice.Fiqas_Product_type__c == null) Invoice.Fiqas_Product_type__c = 'Gumtree';
                    //Check if opportunity has an agency
                    if (tempInvList.Opportunity.Agency__c != null) {
                        Invoice.Account__c = tempInvList.Opportunity.Agency__c;
                        Invoice.Account_Name__c = tempInvList.Opportunity.Agency__r.name;
                        Invoice.Finance_Contact_Email__c = tempInvList.Opportunity.Agency__r.Finance_Contact__r.Email;
                        Invoice.BillingStreet__c = tempInvList.Opportunity.Agency__r.BillingStreet;
                        Invoice.BillingCity__c = tempInvList.Opportunity.Agency__r.BillingCity;
                        Invoice.BillingPostalCode__c = tempInvList.Opportunity.Agency__r.BillingPostalCode;
                        Invoice.BillingCountry__c = tempInvList.Opportunity.Agency__r.BillingCountry;
                        Invoice.Account_Number_Fiqas__c = tempInvList.Opportunity.Agency__r.Account_Number_Fiqas__c;
                    }
                    else {
                        Invoice.Account__c = tempInvList.Opportunity.Accountid;
                        Invoice.Account_Name__c = tempInvList.Opportunity.Account.name;
                        Invoice.Finance_Contact_Email__c = tempInvList.Opportunity.Account.Finance_Contact__r.Email;
                        Invoice.BillingStreet__c = tempInvList.Opportunity.Account.BillingStreet;
                        Invoice.BillingCity__c = tempInvList.Opportunity.Account.BillingCity;
                        Invoice.BillingPostalCode__c = tempInvList.Opportunity.Account.BillingPostalCode;
                        Invoice.BillingCountry__c = tempInvList.Opportunity.Account.BillingCountry;
                        Invoice.Account_Number_Fiqas__c = tempInvList.Opportunity.Account.Account_Number_Fiqas__c;
                    }
                                       
                    if (Invoice.Finance_Contact_Email__c != null) {
                        Invoice.Selected__c = true;
                    }else Invoice.Selected__c = false;
                    //add created Invoice to the list
                    InvoicesList.add(Invoice);
                 }// end for each element in InvoicesListRS
                
                } // if OPP list is not empty
              //  }//end NOt Banner
            } //Classifieds
      // } // One Invoice
        else {
           
           /* if((Frequency == 'Monthly in arrears'  && (dateStart.daysBetween(dateEnd) > 7)
                || ( Frequency == 'Current Week' && (dateStart.daysBetween(dateEnd) <= 7))
                ) 
                && dateEnd != null 
                && dateStart != null ) {*/
                if(Frequency == 'Monthly in arrears' 
                && dateEnd != null 
                && dateStart != null ) {
                    system.debug('PM =='+PM); 
                     system.debug('Period =='+Period); 
                  
                    if(PM == 'DD'){
                        String condition='';
                        /*string  condition1=' FROM Revenue_Schedule2__c WHERE Net_Net_Net_Delivered__c>0 AND Opportunity__r.isWon = true '+// 
                                     // ' AND (Month__c <= LAST_MONTH OR Month__c = THIS_MONTH)'+// OR Month__c =THIS_MONTH)
                                      ' AND (Month__c <= THIS_MONTH )'+// OR Month__c =THIS_MONTH)
                                     // ' AND Opportunity__r.Direct_Debit_Mandate__r.MandateApprovedDate__c = THIS_WEEK'+//Periods +
                                      ' AND Opportunity__r.Direct_Debit_Mandate__r.MandateApprovedDate__c >= :dateStart  AND Opportunity__r.Direct_Debit_Mandate__r.MandateApprovedDate__c <= :dateEnd'+
                                      ' AND Opportunity__r.Direct_Debit_Mandate__r.Mandate_Status__c = \'OK\' AND Opportunity__r.recordtypeid = :OppRecordTypes'+ 
                                      ' AND  Opportunity__r.Payment_Method__c = \'Direct Debit\'';//Added 4-8-2014
                          if(Period =='ThisW'){
                             
                                condition=condition1+' AND id not in :InvoicedRSSet order by Month__c ASC limit 800' ;  
                          }else if( Period =='previousW'){
                                condition=condition1+' AND id not in :InvoicedRSSet order by Month__c ASC limit 1' ;      
                          }else{
                         
                          condition=' FROM Revenue_Schedule2__c WHERE Month__c >= :dateStart AND Month__c <= :dateEnd AND Opportunity__r.BillingFrequency__c = :Frequency'+
                                 ' AND Net_Net_Net_Delivered__c>0 AND Opportunity__r.recordtypeid = :OppRecordTypes AND Opportunity__r.isWon = true'+
                                 ' AND  Opportunity__r.Payment_Method__c = \'Direct Debit\''+//Added 4-8-2014
                                 ' AND Opportunity__r.Ready_for_invoicing__c = true AND Opportunity__r.Direct_Debit_Mandate__r.Mandate_Status__c = \'OK\' AND id not in :InvoicedRSSet limit 800';
                                     
                                      
                        }*/
                        if(Period !='ThisW' && Period !='previousW'){
                            condition=' FROM Revenue_Schedule2__c WHERE Month__c >= :dateStart AND Month__c <= :dateEnd AND Opportunity__r.BillingFrequency__c = :Frequency'+
                                 ' AND Net_Net_Net_Delivered__c>0 AND Opportunity__r.recordtypeid = :OppRecordTypes AND Opportunity__r.isWon = true'+
                                 ' AND  Opportunity__r.Payment_Method__c = \'Direct Debit\''+//Added 4-8-2014
                                 ' AND Opportunity__r.Account.Account_number_fiqas__c != \'GT\''+
                                 ' AND Opportunity__r.Ready_for_invoicing__c = true AND Opportunity__r.Direct_Debit_Mandate__r.Mandate_Status__c = \'OK\' AND id not in :InvoicedRSSet limit 800';
                        }else{//Mandate Last Week = 'PreviousW'
                         
                            String Periods=Period =='ThisW'?'THIS_WEEK':'LAST_WEEK';
                            
                           condition=' FROM Revenue_Schedule2__c WHERE Net_Net_Net_Delivered__c>0 AND Opportunity__r.isWon = true'+// 
                                     // ' AND (Month__c <= LAST_MONTH OR Month__c = THIS_MONTH)'+// OR Month__c =THIS_MONTH)
                                      ' AND (Month__c <= THIS_MONTH )'+// OR Month__c =THIS_MONTH)
                                     // ' AND Opportunity__r.Direct_Debit_Mandate__r.MandateApprovedDate__c = THIS_WEEK'+//Periods +
                                      ' AND Opportunity__r.Direct_Debit_Mandate__r.MandateApprovedDate__c >= :dateStart  AND Opportunity__r.Direct_Debit_Mandate__r.MandateApprovedDate__c <= :dateEnd'+
                                      ' AND Opportunity__r.Direct_Debit_Mandate__r.Mandate_Status__c = \'OK\' AND Opportunity__r.recordtypeid = :OppRecordTypes'+ 
                                      ' AND  Opportunity__r.Payment_Method__c = \'Direct Debit\''+//Added 4-8-2014
                                      ' AND Opportunity__r.Account.Account_number_fiqas__c != \'GT\''+
                                      ' AND id not in :InvoicedRSSet order by Month__c ASC limit 800' ;
                                     
                                      
                        }//end Period !='ThisW' && Period !='previousW'
                    
                              String query='SELECT id,'+
                                        'Opportunity__r.Accountid,'+
                                       ' Opportunity__r.Account.name,'+
                                        'Opportunity__r.Account.BillingStreet,'+ 
                                        'Opportunity__r.Account.BillingCity, '+
                                       ' Opportunity__r.Account.BillingCountry , '+
                                       ' Opportunity__r.Account.BillingPostalCode , '+
                                       ' Opportunity__r.Account.Account_Number_Fiqas__c ,'+
                                       ' Opportunity__r.Account.Finance_Contact__r.Email ,'+
                                       ' Opportunity__r.Account.Apply_VAT__c,'+
                                       ' Opportunity__c,'+
                                       ' Opportunity__r.IOnumber__c,'+
                                       ' Opportunity__r.name,'+
                                       ' Opportunity__r.P_O_Number__c,'+
                                       ' Opportunity__r.BillingFrequency__c,'+
                                       ' Opportunity__r.Payment_Method__c,'+
                                       ' Opportunity__r.Direct_Debit_Mandate__c,'+
                                       ' Opportunity__r.CloseDate ,'+
                                       ' Opportunity__r.Campaign_Start__c ,'+
                                       ' Opportunity__r.Campaign_End__c ,'+
                                       ' Opportunity__r.Fiqas_Product_Code__c ,'+
                                       ' Opportunity__r.Fiqas_VAT_Type__c,'+
                                       ' Opportunity__r.Agency__c ,'+
                                       ' Opportunity__r.Agency__r.name ,'+
                                       ' Opportunity__r.Agency__r.BillingStreet, '+
                                       ' Opportunity__r.Agency__r.BillingCity, '+
                                        'Opportunity__r.Agency__r.BillingCountry ,'+
                                        'Opportunity__r.Agency__r.BillingPostalCode , '+
                                        'Opportunity__r.Agency__r.Finance_Contact__r.Email ,  '+                
                                       ' Opportunity__r.Agency__r.Account_Number_Fiqas__c ,'+
                                        'Opportunity__r.Agency__r.Apply_VAT__c,'+
                                        'Opportunity__r.Direct_Debit_Mandate__r.Name,'+
                                        'Product__c,'+
                                        'Product__r.Product_Type__c,'+
                                       ' Product__r.Product_SubType__c,'+
                                       ' Product__r.Unit_Label__c,'+
                                       ' Fiqas_from_Date_Display__c,'+
                                       ' Fiqas_until_Date_Display__c,'+
                                       ' Invoice_Description__c,'+
                                       ' Invoice_Quantity__c,'+
                                       ' Sales_Price_Net_Net_Net__c,'+
                                       ' Net_Net_Net_Delivered__c,'+
                                       ' Net_Net_Net_Paid_inc_VAT__c,'+
                                       ' VAT_Percentage_F__c,'+
                                       ' Net_Net_Net__c, '+
                                       'Month__c,'+
                                       
                                       'Product_Startdate__c,'+
                                       'Product_Enddate__c,'+
                                       'Revenue2__c,'+
                                       'Opportunity__r.Direct_Debit_Mandate__r.MandateApprovedDate__c  ';
                               
                               set<String> oppId= new set<String>(); 
                               Map<String,Revenue_Schedule2__c>  mapRs=new Map<String,Revenue_Schedule2__c>();
                               
                               list<Revenue_Schedule2__c> RSS= Database.query(query+condition);
                            
                               
                               Set<String> rsId=new Set<String>();
                               for(Revenue_Schedule2__c rs:RSS){
                                    oppId.add(rs.Opportunity__c);
                                   
                                    rsId.add(rs.Id);
                               }
                               
                               
                               Map<String,OpportunityLineItem> mapOpli=new Map<String,OpportunityLineItem>();
                               for(OpportunityLineItem opli:[select Revenue2__c,from_Date__c, OpportunityId,Id From OpportunityLineItem where OpportunityId in: oppId]){
                                    mapOpli.put(opli.Revenue2__c,opli);
                               } 
                               //CHECK INVOICE SENT
                               map<String,InvoicesSent__c> mapIvsend=new Map<String,InvoicesSent__c>();
                               for(InvoicesSent__c ins:[Select Opportunity__c, Revenue_Schedule2__c From InvoicesSent__c where Revenue_Schedule2__c in: rsId]){
                                   string keys=ins.Opportunity__c+'_'+ins.Revenue_Schedule2__c;
                                   mapIvsend.put(keys,ins);
                               }
                              
                               // use to select the first row of a group revenue
                               Set<Id> sameopps = new Set<Id>();

                               for(Revenue_Schedule2__c rs:RSS){
                                    
                                    string m=string.valueOf(rs.month__c.month());
                                    if(!mapOpli.containsKey(rs.Revenue2__c)) continue;
                                    string itemId=mapOpli.get(rs.Revenue2__c).Id;

                                    string key= rs.Opportunity__c+'_'+m+'_'+itemId;

                                    if(mapRs.containsKey(key)) continue;
                                    if(mapIvsend.containsKey(rs.Opportunity__c+'_'+rs.Id))continue;
                                    
                                    //GTCRM-1793- Direct Debit invoicing: Part 1 & 2 being displayed in view 'Mandate Last Week'
                                    // GTCRM-1334 Invoices sent lines for DD appearing in the pending Invoice list
                                    if (Period =='ThisW' || Period =='previousW') {
                                        //Request by Sri to show all RS of the month 20-11-2014
                                       /* if (sameopps.contains(rs.Opportunity__c)) continue;
                                        else {
                                            sameopps.add(rs.Opportunity__c);
                                        }*/
                                        sameopps.add(rs.Opportunity__c);
                                    }
                                    if(!mapOppIdToListRS.containsKey(rs.Opportunity__c)) mapOppIdToListRS.put(rs.Opportunity__c, new List<Revenue_Schedule2__c>());
                                    mapOppIdToListRS.get(rs.Opportunity__c).add(rs);
                                    
                                    mapRs.put(key,rs);
                               }
                               //InvoicesListRS=Database.query(query+condition);
                               InvoicesListRS = mapRs.values();
                              // system.debug('InvoicesListRS>>>>>>>>>>>'+InvoicesListRS.size());
                    }else{//Not DD
                     InvoicesListRS = [SELECT id,
                                        Opportunity__r.Accountid,
                                        Opportunity__r.Account.name,
                                        Opportunity__r.Account.BillingStreet, 
                                        Opportunity__r.Account.BillingCity, 
                                        Opportunity__r.Account.BillingCountry , 
                                        Opportunity__r.Account.BillingPostalCode , 
                                        Opportunity__r.Account.Account_Number_Fiqas__c ,
                                        Opportunity__r.Account.Finance_Contact__r.Email ,
                                        Opportunity__r.Account.Apply_VAT__c,
                                        Opportunity__c,
                                        Opportunity__r.IOnumber__c,
                                        Opportunity__r.name,
                                        Opportunity__r.P_O_Number__c,
                                        Opportunity__r.BillingFrequency__c,
                                        Opportunity__r.Payment_Method__c,
                                        Opportunity__r.Direct_Debit_Mandate__c,
                                        Opportunity__r.CloseDate ,
                                        Opportunity__r.Campaign_Start__c ,
                                        Opportunity__r.Campaign_End__c ,
                                        Opportunity__r.Fiqas_Product_Code__c ,
                                        Opportunity__r.Fiqas_VAT_Type__c,
                                        Opportunity__r.Agency__c ,
                                        Opportunity__r.Agency__r.name ,
                                        Opportunity__r.Agency__r.BillingStreet, 
                                        Opportunity__r.Agency__r.BillingCity, 
                                        Opportunity__r.Agency__r.BillingCountry ,
                                        Opportunity__r.Agency__r.BillingPostalCode , 
                                        Opportunity__r.Agency__r.Finance_Contact__r.Email ,                  
                                        Opportunity__r.Agency__r.Account_Number_Fiqas__c ,
                                        Opportunity__r.Agency__r.Apply_VAT__c,
                                        Opportunity__r.Direct_Debit_Mandate__r.Name,
                                        Opportunity__r.Payment_Token__c,
                                        Product__c,
                                        Product__r.Product_Type__c,
                                        Product__r.Product_SubType__c,
                                        Product__r.Unit_Label__c,
                                        Fiqas_from_Date_Display__c,
                                        Fiqas_until_Date_Display__c,
                                        Invoice_Description__c,
                                        Invoice_Quantity__c,
                                        Sales_Price_Net_Net_Net__c,
                                        Net_Net_Net_Delivered__c,
                                        Net_Net_Net_Paid_inc_VAT__c,
                                        VAT_Percentage_F__c,
                                        Net_Net_Net__c, 
                                        Month__c,
                                        Product_Startdate__c,
                                        Product_Enddate__c
                                 FROM Revenue_Schedule2__c 
                                 WHERE Month__c >= :dateStart
                                 AND Month__c <= :dateEnd
                                 AND Opportunity__r.BillingFrequency__c = :Frequency
                                 AND Net_Net_Net_Delivered__c>0 
                                 AND Opportunity__r.recordtypeid = :OppRecordTypes
                                 AND Opportunity__r.isWon = true
                                 AND  Opportunity__r.Payment_Method__c != 'Direct Debit'
                                 AND Opportunity__r.Ready_for_invoicing__c = true 
                                 //AND Opportunity__r.Account.Account_number_fiqas__c != 'GT'
                                 AND id not in :InvoicedRSSet limit 800
                                 ];
                        }//end if/else PM
                 }
                
                if (InvoicesListRS != null && !InvoicesListRS.isEmpty()){
            //iterate over all opportunities, which met criteria of frequency and period
                //ignore last RS if have more than one record
                set<String> setRSId = new set<String>();
                for(String k : mapOppIdToListRS.keyset()){
                    if(mapOppIdToListRS.get(k).size()>1 && mapOppIdToListRS.get(k)[(mapOppIdToListRS.get(k).size()-1)].Month__c == date.today().toStartOfMonth()){
                        setRSId.add(mapOppIdToListRS.get(k)[(mapOppIdToListRS.get(k).size()-1)].Id);
                    }
                }
            
                for (Revenue_Schedule2__c tempInvList: InvoicesListRS) {//for (Revenue_Schedule2__c tempInvList: InvoicesListRS) {
                    //create new invoice
                    if(setRSId.contains(tempInvList.Id) && PM == 'DD' && Period == 'previousW') continue;
                     string inExtra=tempInvList.Opportunity__r.Payment_Method__c.equals('Direct Debit')?string.valueOf(tempInvList.Opportunity__r.Direct_Debit_Mandate__r.Name):'';
                    InvoicesSent__c Invoice = new InvoicesSent__c(
                        Revenue_Schedule2__c = tempInvList.id,
                        Fiqas_Start_Date__c = tempInvList.Fiqas_from_Date_Display__c,
                        Fiqas_End_Date__c = tempInvList.Fiqas_until_Date_Display__c,
                        Fiqas_Product_type__c = 'Gumtree',
                        Fiqas_Product_Subtype__c = tempInvList.Product__r.Product_SubType__c,
                        Fiqas_Product_Code__c = tempInvList.Opportunity__r.Fiqas_Product_Code__c,
                        Fiqas_VAT_Percentage__c = tempInvList.VAT_Percentage_F__c,
                        Apply_VAT__c = string.valueOf(tempInvList.Opportunity__r.Fiqas_VAT_Type__c),
                        BillingFrequency__c = tempInvList.Opportunity__r.BillingFrequency__c,
                        Opportunity__c = tempInvList.Opportunity__c,
                        IOnumber__c = tempInvList.Opportunity__r.IOnumber__c,
                        from_Date__c = tempInvList.Product_Startdate__c,
                        until_Date__c = tempInvList.Product_Enddate__c,
                        Unit_Label__c = tempInvList.Product__r.Unit_Label__c,
                        Fiqas_Invoice_Description__c = tempInvList.Invoice_Description__c,
                        Amount_Paid__c = tempInvList.Net_Net_Net_Paid_inc_VAT__c,
                        Invoice_Quantity__c = tempInvList.Invoice_Quantity__c,
                        Sales_Price__c = tempInvList.Sales_Price_Net_Net_Net__c,
                        Primary_contact_FirstName__c = '',
                        Primary_contact_LastName__c = '',
                        Primary_contact_Email__c = '',
                        InvID__c = tempInvList.id,
                        InvoiceExtra1__c =inExtra,// string.valueOf(tempInvList.Opportunity__r.Direct_Debit_Mandate__r.Name),
                        Mandate__c=tempInvList.Opportunity__r.Direct_Debit_Mandate__c
                        );
                    //Check if opportunity has an agency
                    if (tempInvList.Opportunity__r.Agency__c != null) {
                        Invoice.Account__c = tempInvList.Opportunity__r.Agency__c;
                        Invoice.Account_Name__c = tempInvList.Opportunity__r.Agency__r.name;
                        Invoice.Finance_Contact_Email__c = tempInvList.Opportunity__r.Agency__r.Finance_Contact__r.Email;
                        Invoice.BillingStreet__c = tempInvList.Opportunity__r.Agency__r.BillingStreet;
                        Invoice.BillingCity__c = tempInvList.Opportunity__r.Agency__r.BillingCity;
                        Invoice.BillingPostalCode__c = tempInvList.Opportunity__r.Agency__r.BillingPostalCode;
                        Invoice.BillingCountry__c = tempInvList.Opportunity__r.Agency__r.BillingCountry;
                        Invoice.Account_Number_Fiqas__c = tempInvList.Opportunity__r.Agency__r.Account_Number_Fiqas__c;
                    }
                    else {
                        Invoice.Account__c = tempInvList.Opportunity__r.Accountid;
                        Invoice.Account_Name__c = tempInvList.Opportunity__r.Account.name;
                        Invoice.Finance_Contact_Email__c = tempInvList.Opportunity__r.Account.Finance_Contact__r.Email;
                        Invoice.BillingStreet__c = tempInvList.Opportunity__r.Account.BillingStreet;
                        Invoice.BillingCity__c = tempInvList.Opportunity__r.Account.BillingCity;
                        Invoice.BillingPostalCode__c = tempInvList.Opportunity__r.Account.BillingPostalCode;
                        Invoice.BillingCountry__c = tempInvList.Opportunity__r.Account.BillingCountry;
                        Invoice.Account_Number_Fiqas__c = tempInvList.Opportunity__r.Account.Account_Number_Fiqas__c;
                    }
                    
                    //check only Invoices with email
                    if (Invoice.Finance_Contact_Email__c != null) {
                        Invoice.Selected__c = true;
                    }
                    else Invoice.Selected__c = false;
                    //Amount for different Invoices  
                    if (Frequency == 'One Invoice') {
                        Invoice.Invoice_Amount__c = tempInvList.Net_Net_Net__c;
                    } 
                    else if (Frequency == 'Monthly in arrears' && (CT == 'Classifieds' || CT == 'Motors' || CT == 'Direct Debits')){ 
    //                    Invoice.Invoice_Amount__c = tempInvList.Netto_II__c;
                        Invoice.Sales_Price__c = tempInvList.Sales_Price_Net_Net_Net__c;
                        Invoice.Invoice_Amount__c = tempInvList.Net_Net_Net_delivered__c;
            
                    }
                    else if (Frequency == 'Monthly in arrears' && CT == 'Banners') {
                        Invoice.Sales_Price__c = tempInvList.Sales_Price_Net_Net_Net__c;
                        Invoice.Invoice_Amount__c = tempInvList.Net_Net_Net_delivered__c;
                    }
                    //VAT shouldn't be null
                    if (Invoice.Fiqas_VAT_Percentage__c == null) {
                        Invoice.Fiqas_VAT_Percentage__c = 0;
                    }
                    
                //add created Invoice to the list
                InvoicesList.add(Invoice);
            }// end for each element in InvoicesListRS
            } // if list is not empty
        }
        InvoicesListOp.clear();
        InvoicesListRS.clear();
        return InvoicesList;
    }
    
/* Daily deals business closed edit 20/11/2012
    public pageReference InvoiceExport () {
        system.debug('XXXXXXXXXXXXXXXXXXXXXXXXX InvoicesList DD' + InvoicesList);
        insert InvoicesList;
        //return null;
        PageReference pageRef = new PageReference('/apex/InvoiceExport_GT?InvID='+InvID);
        return pageRef;
    }
    
    public pageReference InvoiceSelectedExport () {
        system.debug('XXXXXXXXXXXXXXXXXXXXXXXXX InvoicesList DD' + InvoicesList);
        list<InvoicesSent__c> selectedList = new list<InvoicesSent__c>();
        for (InvoicesSent__c invTemp:InvoicesList) {
            if (invTemp.Selected__c) {
                selectedList.add(invTemp);
            }   
        }
        insert selectedList;
        //return null;
        PageReference pageRef = new PageReference('/apex/InvoiceExport_GT?InvID='+InvID);
        return pageRef;
    }
*/

    public list<InvoicesSent__c> SelectedList (list<InvoicesSent__c> inputList){
        list<InvoicesSent__c> SelectedList = new list<InvoicesSent__c>();
        for (InvoicesSent__c inv: inputList){
            if (inv.Selected__c == true){
                SelectedList.add(inv);
            }
        }
        return SelectedList;
    }
    
    public PageReference InvInsertCancel() {
        message = 'No Invoices have been sent.';
        return null;
    }

    public PageReference InvAllInsert() {
        InsertToFiqas(InvoicesList);
        return null;
    }
    public PageReference InvSelectedInsert() {
        InsertToFiqas(SelectedList(pageInvoicesListNew));
        return null;
    }
    
    public void InsertToFiqas(list<InvoicesSent__c> ListToSend) {
        boolean noEmptyFields = true;
        String EmptyAddressList = '';
        set<String> EmptyAddressSet = new set<String>();
        
        if (ListToSend != null && !ListToSend.isEmpty()) {
            for (InvoicesSent__c InvList: ListToSend) {
                //List of Accoutn with not full Address
                if (InvList.BillingStreet__c == null ||
                    InvList.BillingCity__c  == null || 
                    InvList.BillingPostalCode__c  == null || 
                    InvList.BillingCountry__c  == null ||
                    InvList.Finance_Contact_Email__c == null ) {
                    noEmptyFields = false;
                    EmptyAddressSet.add(InvList.Account_Name__c);
                } //at least 1 account has not all fields populated 
            } //go over the InvoicesList
            for (string emptyAcc: EmptyAddressSet) {
                if(EmptyAddressList == '') EmptyAddressList = emptyAcc;
                else EmptyAddressList = EmptyAddressList +', '+emptyAcc;
            }
            if (noEmptyFields) {    
                insert ListToSend;
                System.debug('========ListToSend : ' + ListToSend);
                FiqasBatchInvoiceInsert scriptBatch = new FiqasBatchInvoiceInsert(ListToSend);
                ID batchprocessid = Database.executeBatch(scriptBatch, 1);
                message =  'Number of invoices sent: ' + ListToSend.size() + '.';
            } //Successfully sent invoices
            else { 
                message = 'No invoices has been sent. Check Billing Address and Finance Contact for ' + EmptyAddressList +'.';
            } //Accounts with empty fields
        } //InvoicesList isn't empty
        else {
            message = 'No invoices selected to send.';
        } 
        EmptyAddressSet.clear();
        EmptyAddressList = '';
        InvoicesList.clear();
    }
   
    // ----- Pagination ----- //
    public PaginationExt_GT paginationExt = new PaginationExt_GT (this);
    
    public integer pageNumber = 1;
    
    public Integer getPageNumber(){
        return pageNumber;
    }
    
    public PageReference nextBtnClick() {
        pageNumber++;
        getInvoicesList();
        return null;
    }
    
    public PageReference previousBtnClick() {
        pageNumber--;
        getInvoicesList();
        return null;
    }
    
    public Boolean getPreviousButtonEnabled(){
        return !(pageNumber > 1);
    }
    
    public Boolean getNextButtonDisabled(){
        if (InvoicesList == null) return true;
        else
        
        return ((pageNumber * paginationExt.pageSize) >= InvoicesList.size());
    }
}