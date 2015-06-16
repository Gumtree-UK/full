/**

GTCRM-222 - Automate client reporting for AdSales

Change log:
- Additional column for eCPM in Summary & Daily Reporting - Steve Paul
- GTCRM-748 - Client Reporting Format Tweaks - Report Name Convention - Steve Paul
- GTCRM-957 - Add Line Description to daily automated report - Steve Paul
- 2015-06-03 - GTCRM-2014 - Enhance automated reporting - add gross/net spend and optional eCPM - Steve Paul

**/

public with sharing class ExcelReport {  
   
    //file Name
    public String fileName{get;set;}
    
    //This string is xml spreedsheet init in contractor
    String xml;
       
    public String getxml(){return xml;}//call from ExcelReportEmaill for add attachment.
   
    String oppId; //Oppotunity ID   
     
    //If the report is created manually it shows all possible columns even if not defined in the field “Additional_Columns__c”.
    boolean isFromBtn=false;//isFromBtn=true only button "Excel Report" click. 
    
    //column name as map key (the value of map will be custom label)
    public static final String COL_PRODUCT ='Product',
                   COL_LINE_DESC ='Line Description',
                   COL_START_DATE ='Start Date',
                   COL_END_DATE ='End Date',
                   COL_FREQ ='Frequency Cap',
                   COL_BOOK_AMOUNT ='Booked Amount',
                   COL_DELIV_AMOUNT ='Net Spend',
                   COL_BILL_CAT ='Billing Category',
                   COL_BOOK_QTY ='Booked Quantity',
                   COL_RATE ='Rate',
                   COL_DELIV_IMPR ='Delivered Impressions',
                   COL_DELIV_CLICK ='Delivered Clicks',
                   COL_CLICK_RATE ='Click Rate',
                   COL_DELIV_INDEX ='Delivery Index',
                   COL_DATE ='Date', 
                   // Additional column for eCPM in Daily Reporting               
                   COL_ECPM ='eCPM',
                   // 2015-06-03 - GTCRM-2014 - Enhance automated reporting - add gross/net spend and optional eCPM
                   COL_DELIV_AMOUNT_GROSS = 'Gross Spend';

        
    final String CELL_TYPE_STRING   = 'String',
           CELL_TYPE_DATETIME = 'DateTime',
           CELL_TYPE_NUMBER   = 'Number';
    //column width==========the width value measure in point
    Map<String, Integer> mapColNameColWidth = new Map<String, Integer>{
        COL_PRODUCT=>188,
        COL_LINE_DESC=>376,
        COL_START_DATE=>68,
        COL_END_DATE=>68,
        COL_FREQ=>83,
        COL_BILL_CAT=>90,
        COL_BOOK_QTY=>84,
        COL_RATE=>99,
        COL_BOOK_AMOUNT=>117,
        COL_DELIV_IMPR=>111,
        COL_DELIV_CLICK=>81,
        COL_CLICK_RATE=>53,
        COL_DELIV_INDEX=>78,
        COL_DATE=>106,
        // Additional column for eCPM in Daily Reporting
        COL_ECPM=>99,
        // 2015-06-03 - GTCRM-2014 - Enhance automated reporting - add gross/net spend and optional eCPM
        COL_DELIV_AMOUNT=>95,
        COL_DELIV_AMOUNT_GROSS=>95
    };         
    
    //****NOTE***
    //listTblColumn & mapColumnLabel are almost the same, but we need listTblColumn because it store column in order manner.
    //all items in listTblColumn is all keys of mapColumnLabel. All values of mapColumnLabel are custom labels for language localization.
    
    //for summery sheet=========
    List<String> listTblColumn; //list Column header in summery sheet. Columns are defined by the File and the field “opp.Additional_Columns__c”.   
    public List<Map<String, String>>listMapColumnValue;//map stores 1 record => listMap stores whole table.
    
    //for summery & detail sheet=========
    Map<String, String> mapColumnLabel; // store column name to custom-labels. for Language to be used is determined by the field “opp.Report_Language__c”. 
    Map<String, String> mapColumnType;  // map column name to data-type for each column in excel. data-type eg. number, string, date, ....
    Map<String, String> mapColumnStyle;// map style for each cell in excel. style eg. bold, border, alignment, ....
    Set<String> setRevenueID=new Set<String>();//getting Revenue2__r.Id from each line item for query in Revenue_Schedule_daily2__c 
    
    //for detail sheet=======
    List<String> listTblColumnDetail;
    public List<Map<String, String>>listMapColumnValueDetail;
    

    /** 
    *   Constructor default only from "Excel Report" button
    */
    public ExcelReport(){
        //isFromBtn is only from "Excel Report" button
        isFromBtn=ApexPages.currentPage().getParameters().get('isFromBtn')==null?false:Boolean.valueOf(ApexPages.currentPage().getParameters().get('isFromBtn'));
        oppId=ApexPages.currentPage().getParameters().get('oppId');
        forConstructor();
    }
    
    /** 
    *   Constructor for calling from scheduler-batch and mail
    */
    public ExcelReport(String oppId){
        this.oppId=oppId;
        forConstructor();
    }
    
    /** 
    *   For calling initialize-methods from Constructors
    */
    void forConstructor(){
        xml=ExcelReportHelper.XML;
        //check Does the current Opp have line item(s).
        init_listMapColumnValue();
        init_Column_all();
        init_listMapColumnValueDetail();
        init_XML();
        
    }
  
    /** 
    *   initialize: instance variables (listMapColumnValue)
    *   ==================================================
    *   This method will generate rows for the table in summery sheet based on conditions.
    *   ======Business logic is here=========
    */
    void init_listMapColumnValue(){
        
        listMapColumnValue=new List<Map<String, String>>();
        
        /**
        extend that “Excel Report” shows all data, so no filters are used that are defined for the
        other report. This means the following changes for “Excel Report”:****
        
        - *CPO lines are displayed on summary and detail
        (Billing_category__c=”CPO”)*
        
        - *Lines where Package_line_item__c <> “” are displayed on
        summary and detail*
        */
        
        // Chr: 27/08/2013
        // LineItems to disply in excell should be order by(from_date__c or SortOrder) depend on
        // value of Opportunity fields( LineItems_Sort_Type__c)
        // --> Automatically => Order by from_date__c ASC
        // --> Manually => Order by SortOrder 
        
        Opportunity opty = [Select id,  LineItems_Sort_Type__c From Opportunity Where id=:oppId];
        String strQurOrder = ('Manually'.equals(opty.LineItems_Sort_Type__c) ? ' ORDER BY SortOrder' : ' ORDER BY from_date__c ASC');
         
        String  string_lineItem; 
        if(isFromBtn){
            string_lineItem ='SELECT id, package_line_item__c, Product_Record_Type__c, CPM_net_net_net__c, until_Date__c, from_Date__c, Revenue2__r.Id, Quantity, '+
                                     'PricebookEntry.Name, OSI__c, FC_Quantity__c, FC_Period__c, '+
                                     'FC_Ad_served_every__c, Description, Billing_category__c, Net_Net_Net__c, eCPM__c, Netto_II__c, '+
                                     'delivered_AI_LT__c, delivered_Clicks_LT__c, Turnover_actual_by_delivery__c  '+ 
                                     'FROM OpportunityLineItem '+
                                     'WHERE OpportunityId=:oppId '
                                     + strQurOrder;  
        }else{
            string_lineItem ='SELECT id, package_line_item__c, Product_Record_Type__c, CPM_net_net_net__c, until_Date__c, from_Date__c, Revenue2__r.Id, Quantity, '+
                                     'PricebookEntry.Name, OSI__c, FC_Quantity__c, FC_Period__c, '+
                                     'FC_Ad_served_every__c, Description, Billing_category__c, Net_Net_Net__c, eCPM__c, Netto_II__c, '+
                                     'delivered_AI_LT__c, delivered_Clicks_LT__c, Turnover_actual_by_delivery__c  '+ 
                                     'FROM OpportunityLineItem '+
                                     'WHERE Billing_category__c!=\'{!}\' AND OpportunityId=:oppId AND package_line_item__c=null '
                                     + strQurOrder; 
            string_lineItem = string_lineItem.replace('{!}', ExcelReportHelper.BILL_CAT_CPO);
        }                        
        
        List<OpportunityLineItem> listOppL=Database.query(string_lineItem); // getting all data needed for the table from the oppotunity.
                
        //if(listOppL.isEmpty()){fileName='NoLineItem.xls';return false;}
       
        //getting Revenue2__r.Id from each line item for query in Revenue_Schedule_daily2__c 
        for(OpportunityLineItem li : listOppL){
            setRevenueID.add(li.Revenue2__r.Id);
        }
        
        //data for today, which should not be shown on the report. So the filter for used RSD has to be extended with “Day__c < Today”
        String rsd ='SELECT Revenue2__c, SUM(Delivered_AI__c)deliv, SUM(Clicks_Recorded__c)click '+
                    'FROM Revenue_Schedule_daily2__c '+
                    'WHERE Revenue2__c IN :setRevenueID AND Day__c <'+String.valueOf(System.Today())+
                    ' GROUP BY Revenue2__c';
        AggregateResult[] listAggResult=Database.query(rsd); //getting SUM(Delivered_AI__c) & SUM(Clicks_Recorded__c) for calculation in *4 *5
        
        Map<String, AggregateResult> mapIdAggResult = new  Map<String, AggregateResult>();// for getting AggregateResult by ID
        for(AggregateResult aggr : listAggResult){
            mapIdAggResult.put(String.valueOf(aggr.get('Revenue2__c')), aggr);
        } 
        
        // loop through all line-items
        for(OpportunityLineItem li : listOppL){
           
            String revID =li.Revenue2__r.Id;// create a variable to store id avoid writing more.
            
            Double sumImp=0; 
            Double sumcli=0; 
            Double sumDI=0;
            Double sumNB=0; 
            Double sumGS=0; 
            Double sumNS=0;
            
            Double sumDeliv, sumClick;
            try{
                sumDeliv =(mapIdAggResult.get(revID).get('deliv')==null)?0:(Double.valueOf(mapIdAggResult.get(revID).get('deliv')));
                sumClick =(mapIdAggResult.get(revID).get('click')==null)?0:(Double.valueOf(mapIdAggResult.get(revID).get('click')));
            }catch(Exception e){
                sumDeliv =0;
                sumClick =0;
            }
            
            //*1(Frequency Cap)=FC_Quantity__c & " per " & FC_Ad_served_every__c & FC_Period__c         
            String qty     = (li.FC_Quantity__c==null?'':String.valueOf(li.FC_Quantity__c)),
                 adServer  = (li.FC_Ad_served_every__c==null?'':String.valueOf(li.FC_Ad_served_every__c)),
                 period    = (li.FC_Period__c==null?'':li.FC_Period__c),
                 freq      = qty+' per '+adServer+period;
            freq           = ((freq==' per ')?'':freq); 
            
      String min = String.valueOf(li.Quantity>sumDeliv?sumDeliv:li.Quantity);
            //Table: one line per line item (except Billing_category__c=CPO), Only show lines where Delivered Impressions > 0
            // using continue; to scipt adding this row to the list resulting not display.
            if( (!isFromBtn) && (li.Billing_category__c != ExcelReportHelper.BILL_CAT_CPC) && (min=='' || min=='0')  ){
                continue;
            }
            Map<String, String> mapColmnValue = new Map<String, String>{COL_PRODUCT      => li.PricebookEntry.Name,
                                          COL_LINE_DESC    => li.Description,
                                          COL_START_DATE   => String.valueOf(li.from_Date__c),
                                          COL_END_DATE     => String.valueOf(li.until_Date__c),
                                          COL_BILL_CAT     => String.valueOf(li.Billing_category__c),
                                          COL_BOOK_QTY     => String.valueOf(li.Quantity),
                                          COL_BOOK_AMOUNT  => String.valueOf(li.Net_Net_Net__c),
                                          COL_DELIV_INDEX  => li.OSI__c==null?'':String.valueOf(li.OSI__c.setScale(0)),
                                          // Additional column for eCPM in Daily Reporting
                                          COL_ECPM         => li.eCPM__c==null?'':String.valueOf(li.eCPM__c.setScale(2)),
                                          'pID'            => li.Revenue2__r.Id,
                                          COL_DELIV_IMPR   => min,
                                          COL_FREQ         => freq,
                                          COL_DELIV_CLICK  => isFromBtn?String.valueOf(sumClick):'',
                                          COL_CLICK_RATE   => '',
                                          COL_DELIV_AMOUNT => '',
                                          // GTCRM-2014 - Enhance automated reporting - add gross/net spend and optional eCPM
                                          COL_DELIV_AMOUNT_GROSS => '',
                                          COL_RATE         => ''         };// store a row of the table   
            
            //*4(Delivered Impressions) updated:issues/1551
            //    if BillingCategory = CPM:  MIN((SUM(RSD.Delivered_AI__c) where where RSD.Revenue2__c = LI.Revenue2__c AND RSD.Day__C < Today), Quantity)
            //    if BillingCategory = Fix Price:(SUM(RSD.Delivered_AI__c) where where RSD.Revenue2__c = LI.Revenue2__c AND RSD.Day__C < Today)
            //    if BillingCategory = CPC:       isFromBtn?addddd:empty   
            if(ExcelReportHelper.SET_CMPFIXPRICE.contains(li.Billing_category__c)){
                mapColmnValue.put(   COL_DELIV_IMPR, (li.Billing_category__c==ExcelReportHelper.BILL_CAT_FIXPRICE)?(sumDeliv+''):min   ); // mapColmnValue.put(COL_DELIV_IMPR, min);   
            }else{
                mapColmnValue.put(COL_DELIV_IMPR, isFromBtn?min:''); //isFromBtn? Delivered Impressions it is the same formula for all
            }
            
            //*5(Delivered Clicks)
            //  For BillingCategory= CPM or Fix Price: SUM(RSD.Clicks_Recorded__c) where RSD.Revenue2__c = LI.Revenue2__c AND RSD.Day__C < Today****  
            //  For BillingCategory= CPC: MIN(SUM(RSD.Clicks_Recorded__c) where RSD.Revenue2__c = LI.Revenue2__c AND RSD.Day__C < Today ; Quantity)****
            if(ExcelReportHelper.SET_CMPFIXPRICE.contains(li.Billing_category__c)){
                mapColmnValue.put(COL_DELIV_CLICK,String.valueOf(sumClick));
            }else if(li.Billing_category__c==ExcelReportHelper.BILL_CAT_CPC){
                mapColmnValue.put(COL_DELIV_CLICK,String.valueOf(li.Quantity>sumClick?sumClick:li.Quantity));
            } 
            
            //************Task #832: add value(not formula)
            //*6    For I = CPM or Fix Price: M/L  For I = CPC: empty       
            if(isFromBtn || ExcelReportHelper.SET_CMPFIXPRICE.contains(li.Billing_category__c)){
                mapColmnValue.put(COL_CLICK_RATE,ExcelReportHelper.divisionAsString(mapColmnValue.get(COL_DELIV_CLICK), mapColmnValue.get(COL_DELIV_IMPR)));
            } 
            
            // *2(Delivered Amount)
            //      For BillingCategory = CPM: (Delivered Impressions)/(Booked Quantity)*(Booked amoun)
            //      For BillingCategory = CPC: (Delivered Clicks)/(Booked Quantity)*(Booked amoun)
            //      For BillingCategory = Fix Price: Booked Amount
            // *3(Rate) 
            //      For BillingCategory = CPM or CPC: CPM_net_net_net__c  
            //      For BillingCategory = Fix Price: Booked Amount 
            if(li.Billing_category__c==ExcelReportHelper.BILL_CAT_CPM){
                // GTCRM-2014 - Enhance automated reporting - add gross/net spend and optional eCPM
                mapColmnValue.put(COL_DELIV_AMOUNT_GROSS,ExcelReportHelper.multiAsString(ExcelReportHelper.divisionAsString(mapColmnValue.get(COL_DELIV_IMPR), String.valueOf(li.Quantity)), String.valueOf(li.Netto_II__c)));
                mapColmnValue.put(COL_DELIV_AMOUNT,ExcelReportHelper.multiAsString(ExcelReportHelper.divisionAsString(mapColmnValue.get(COL_DELIV_IMPR), String.valueOf(li.Quantity)), String.valueOf(li.Net_Net_Net__c))); 
                mapColmnValue.put(COL_RATE,String.valueOf(li.CPM_net_net_net__c));
            }else if(li.Billing_category__c==ExcelReportHelper.BILL_CAT_CPC){
                // GTCRM-2014 - Enhance automated reporting - add gross/net spend and optional eCPM
                mapColmnValue.put(COL_DELIV_AMOUNT_GROSS,ExcelReportHelper.multiAsString(ExcelReportHelper.divisionAsString(mapColmnValue.get(COL_DELIV_CLICK), String.valueOf(li.Quantity)), String.valueOf(li.Netto_II__c)));
                mapColmnValue.put(COL_DELIV_AMOUNT,ExcelReportHelper.multiAsString(ExcelReportHelper.divisionAsString(mapColmnValue.get(COL_DELIV_CLICK), String.valueOf(li.Quantity)), String.valueOf(li.Net_Net_Net__c))); 
                mapColmnValue.put(COL_RATE,String.valueOf(li.CPM_net_net_net__c));
            }else if(isFromBtn || li.Billing_category__c==ExcelReportHelper.BILL_CAT_FIXPRICE){
                mapColmnValue.put(COL_DELIV_AMOUNT,String.valueOf(li.Net_Net_Net__c)); 
                // GTCRM-2014 - Enhance automated reporting - add gross/net spend and optional eCPM
                mapColmnValue.put(COL_DELIV_AMOUNT_GROSS,String.valueOf(li.Netto_II__c));
                mapColmnValue.put(COL_RATE,String.valueOf(li.Net_Net_Net__c));
            } 
            
            listMapColumnValue.add(mapColmnValue);
            
              // GTCRM-2014 - Enhance automated reporting - add gross/net spend, totals on summary, optional eCPM - Steve Paul 
              
              // Booked Quantity
              sumImp+=(li.Quantity==null?0:li.Quantity);
              // Delivered Impressions
              sumDI+=(li.delivered_AI_LT__c==null?0:li.delivered_AI_LT__c);
              // Clicks Recorded
              sumcli+=(li.delivered_Clicks_LT__c==null?0:li.delivered_Clicks_LT__c);
              // Booked Net/Net/Net
              sumNB+=(li.Net_Net_Net__c==null?0:li.Net_Net_Net__c);
              // Gross Spend
              sumGS+=(li.Net_Net_Net__c==null?0:li.Net_Net_Net__c);
              // Net Spend
              sumNS+=(li.Turnover_actual_by_delivery__c==null?0:li.Turnover_actual_by_delivery__c);  
               
        }
        //return true;
    }
    
    /** 
    *   initialize: instance variables (listMapColumnValueDetail)
    *   ==================================================
    *   This method will generate rows for the table in Detail sheet.
    */
    void init_listMapColumnValueDetail(){   
        
        listMapColumnValueDetail = new List<Map<String, String>>();     
        
        String query ='Select Revenue2__r.Id, Line_Description__c, Delivered_AI__c, Day__c, Clicks_Recorded__c, eCPM__c '+
                      'From Revenue_Schedule_daily2__c '+
                      'WHERE Revenue2__r.Id IN:setRevenueID AND Delivered_AI__c>0 AND Day__c <'+String.valueOf(System.Today())+
                      ' ORDER BY Day__c';
        
        Map<String, Revenue_Schedule_daily2__c[]> mapLstRSD = new  Map<String, Revenue_Schedule_daily2__c[]>(); 
        for(Revenue_Schedule_daily2__c rsd : Database.query(query)){
          Revenue_Schedule_daily2__c[] lst = mapLstRSD.get(rsd.Revenue2__r.Id)==NULL? (new List<Revenue_Schedule_daily2__c>()):(mapLstRSD.get(rsd.Revenue2__r.Id));
          lst.add(rsd);
          mapLstRSD.put(rsd.Revenue2__r.Id, lst); 
        }
        
    if(mapLstRSD.isEmpty()){return;}
     
        for(Map<String, String> mapColVal:listMapColumnValue){ 
            if(mapLstRSD.get(mapColVal.get('pID'))==null)continue; 
            Double sumImp=0; 
            Double sumcli=0; 
               
            for(Revenue_Schedule_daily2__c rsd: mapLstRSD.get(mapColVal.get('pID'))){
                
                Map<String, String> tem = new Map<String, String>{
                                        COL_DATE            => String.valueOf(rsd.Day__c),
                                        COL_DELIV_IMPR      => String.valueOf(rsd.Delivered_AI__c),
                                        COL_DELIV_CLICK     => String.valueOf(rsd.Clicks_Recorded__c),
                                        COL_CLICK_RATE      => '',
                                        // Additional column for eCPM in Daily Reporting
                                        COL_ECPM            => String.valueOf(rsd.eCPM__c.setScale(2))   };
                                        
                                                                                
                Map<String, String> mapRow = new Map<String, String>();
                mapRow.putAll(mapColVal);
                mapRow.putAll(tem);                            
                
                //************Task #832: add value(not formula)
                //add rate column since we chage this field form fomular to vale fixed.                    
                //*6    For I = CPM or Fix Price: M/L  For I = CPC: empty
                if(ExcelReportHelper.SET_CMPFIXPRICE.contains(mapColVal.get(COL_BILL_CAT))){
                    mapRow.Put(COL_CLICK_RATE,ExcelReportHelper.divisionAsString(mapRow.get(COL_DELIV_CLICK),mapRow.get(COL_DELIV_IMPR)));
                } 
                //***************
                
                listMapColumnValueDetail.add(mapRow);
                 
                //for total of each line item
                sumImp+=(rsd.Delivered_AI__c==null?0:rsd.Delivered_AI__c);
                sumcli+=(rsd.Clicks_Recorded__c==null?0:rsd.Clicks_Recorded__c);
                
            } 
            // for total of each line item 
            Map<String, String> tem = new Map<String, String>{COL_DATE         => 'Total',
                                    COL_DELIV_IMPR   => String.valueOf(sumImp),
                                    COL_DELIV_CLICK  => String.valueOf(sumcli),
                                    COL_CLICK_RATE   => ExcelReportHelper.divisionAsString(String.valueOf(sumcli),String.valueOf(sumImp)) };
            Map<String, String> mapRow = new Map<String, String>();
            mapRow.putAll(mapColVal);
            mapRow.putAll(tem);
            listMapColumnValueDetail.add(mapRow); 
        }  
  } 
     
    /** 
    *   initialize: instance variables (listTblColumn, listTblColumnDetail, mapColumnLabel, mapColumnType, mapColumnStyle)
    */          
    void init_Column_all(){
      
      mapColumnLabel = new Map<String, String>{
                           COL_PRODUCT       => System.Label.excel_col_product,
                           COL_LINE_DESC     => System.Label.excel_col_line_desc,
                           COL_START_DATE    => System.Label.excel_col_start,
                           COL_END_DATE      => System.Label.excel_col_end,
                           COL_FREQ          => System.Label.excel_col_fre,
                           COL_BOOK_AMOUNT   => System.Label.excel_col_booked_amount,
                           COL_DELIV_AMOUNT  => System.Label.excel_col_delivered_amount,
                           // 2015-06-03 - GTCRM-2014 - Enhance automated reporting - add gross/net spend and optional eCPM
                           COL_DELIV_AMOUNT_GROSS => System.label.excel_col_delivered_amount_gross,
                           COL_BILL_CAT      => System.Label.excel_col_billing_category,
                           COL_RATE          => System.Label.excel_col_rate,
                           COL_BOOK_QTY      => System.Label.excel_col_booked_quantity,
                           COL_DELIV_IMPR    => System.Label.excel_col_delivered_impr,
                           COL_DELIV_CLICK   => System.Label.excel_col_delivered_clicks,
                           COL_CLICK_RATE    => System.Label.excel_col_click_rate,
                           COL_DELIV_INDEX   => System.Label.excel_col_delivery_index, 
                           COL_DATE          => System.Label.excel_col_date,
                           // Additional column for eCPM in Daily Reporting
                           COL_ECPM          => System.Label.excel_col_ecpm   };
        
        mapColumnType = new Map<String, String>{
                            COL_PRODUCT        => CELL_TYPE_STRING,
                            COL_LINE_DESC      => CELL_TYPE_STRING,
                            COL_START_DATE     => CELL_TYPE_DATETIME, 
                            COL_END_DATE       => CELL_TYPE_DATETIME,
                            COL_FREQ           => CELL_TYPE_STRING,
                            COL_BOOK_AMOUNT    => CELL_TYPE_NUMBER,
                            COL_DELIV_AMOUNT   => CELL_TYPE_NUMBER,
                            // 2015-06-03 - GTCRM-2014 - Enhance automated reporting - add gross/net spend and optional eCPM
                            COL_DELIV_AMOUNT_GROSS => CELL_TYPE_NUMBER,
                            COL_BILL_CAT       => CELL_TYPE_STRING,
                            COL_RATE           => CELL_TYPE_NUMBER,
                            COL_BOOK_QTY       => CELL_TYPE_NUMBER,
                            COL_DELIV_IMPR     => CELL_TYPE_NUMBER,
                            COL_DELIV_CLICK    => CELL_TYPE_NUMBER,
                            COL_CLICK_RATE     => CELL_TYPE_NUMBER,
                            COL_DELIV_INDEX    => CELL_TYPE_NUMBER,
                            COL_DATE           => CELL_TYPE_DATETIME,
                            // Additional column for eCPM in Daily Reporting
                            COL_ECPM           => CELL_TYPE_NUMBER
                            };
                            
        mapColumnStyle = new Map<String, String>{
                             COL_PRODUCT       => 's39',
                             COL_LINE_DESC     => 's37',
                             COL_START_DATE    => 's71',
                             COL_END_DATE      => 's71',
                             COL_FREQ          => 's72',
                             COL_BOOK_AMOUNT   => 's40',
                             COL_DELIV_AMOUNT  => 's47',
                             // 2015-06-03 - GTCRM-2014 - Enhance automated reporting - add gross/net spend and optional eCPM
                             COL_DELIV_AMOUNT_GROSS => 's48' ,
                             COL_BILL_CAT      => 's73',
                             COL_RATE          => 's42',
                             COL_BOOK_QTY      => 's43',
                             COL_DELIV_IMPR    => 's44',
                             COL_DELIV_CLICK   => 's45',
                             COL_CLICK_RATE    => 's46',
                             COL_DELIV_INDEX   => 's45',
                             COL_DATE          => 's71',
                             // Additional column for eCPM in Daily Reporting
                             COL_ECPM          => 's42',                             
                             
                             COL_DATE+'t'        => 'ss156',
                             COL_PRODUCT+'t'     => 'ss144',
                             COL_LINE_DESC+'t'   => 'ss145',
                             COL_START_DATE+'t'  => 'ss146',
                             COL_END_DATE+'t'    => 'ss146',
                             COL_FREQ+'t'        => 'ss147',
                             COL_BOOK_AMOUNT+'t' => 'ss148',
                             COL_DELIV_AMOUNT+'t'=> 'ss148',
                             COL_BILL_CAT+'t'    => 'ss149',
                             COL_RATE+'t'        => 'ss150',
                             COL_BOOK_QTY+'t'    => 'ss151',
                             COL_DELIV_IMPR+'t'  => 'ss152',
                             COL_DELIV_CLICK+'t' => 'ss153',
                             COL_CLICK_RATE+'t'  => 'ss154',
                             COL_DELIV_INDEX+'t' => 'ss155',
                             // Additional column for eCPM in Daily Reporting
                             COL_ECPM+'t' => 'ss150'}; 
                             
       
        Set<String> setAdditionalField= new Set<String>();
        Opportunity opp =[Select Additional_Columns__c From Opportunity Where id=:oppId];  
        if(opp.Additional_Columns__c!=null){
            setAdditionalField.addAll(String.valueOf(opp.Additional_Columns__c).split(';'));
        }
        //===========adding all except the field not contain in Additional_Columns__c From Opportunity
        listTblColumn = new List<String>{COL_PRODUCT}; 
        
          if(setAdditionalField.contains(COL_LINE_DESC) || isFromBtn) listTblColumn.add(COL_LINE_DESC);  
        listTblColumn.add(COL_START_DATE);  
        listTblColumn.add(COL_END_DATE); 
        if(setAdditionalField.contains(COL_FREQ) || isFromBtn) listTblColumn.add(COL_FREQ);     
        listTblColumn.add(COL_BILL_CAT);  
        listTblColumn.add(COL_BOOK_QTY);   
        if(setAdditionalField.contains(COL_RATE) || isFromBtn)  listTblColumn.add(COL_RATE);    
        if(setAdditionalField.contains(COL_BOOK_AMOUNT) || isFromBtn)  listTblColumn.add(COL_BOOK_AMOUNT);
        listTblColumn.add(COL_DELIV_IMPR);  
        listTblColumn.add(COL_DELIV_CLICK);  
        listTblColumn.add(COL_CLICK_RATE);
        if(setAdditionalField.contains(COL_DELIV_INDEX)  || isFromBtn)  listTblColumn.add(COL_DELIV_INDEX);
        // Additional column for eCPM in Daily Reporting  
        if(setAdditionalField.contains(COL_ECPM) || isFromBtn) listTblColumn.add(COL_ECPM);  
        // 2015-06-03 - GTCRM-2014 - Enhance automated reporting - add gross/net spend and optional eCPM
        listTblColumn.add(COL_DELIV_AMOUNT_GROSS);
        listTblColumn.add(COL_DELIV_AMOUNT);

        listTblColumnDetail = new List<String>{COL_DATE};

        //columns not needed Daily Reporting sheet   
        // GTCRM-957 - Add Line Description to daily automated report
        // Set<String> setHiddenCol = new Set<String>{COL_FREQ, COL_BOOK_AMOUNT, COL_DELIV_AMOUNT, COL_RATE, COL_BOOK_QTY, COL_DELIV_INDEX, COL_LINE_DESC};
        // 2015-06-03 - GTCRM-2014 - Enhance automated reporting - add gross/net spend and optional eCPM
        //Set<String> setHiddenCol = new Set<String>{COL_FREQ, COL_BOOK_AMOUNT, COL_DELIV_AMOUNT, COL_RATE, COL_BOOK_QTY, COL_DELIV_INDEX};
        Set<String> setHiddenCol = new Set<String>{COL_FREQ, COL_BOOK_AMOUNT, COL_DELIV_AMOUNT, COL_RATE, COL_BOOK_QTY, COL_DELIV_INDEX, COL_DELIV_AMOUNT_GROSS};
        for(String col:listTblColumn) {
          if(!setHiddenCol.contains(col)){listTblColumnDetail.add(col);}
        }
    }
    
    /** 
    *   Find & Replace some the string in xml-variable
    */
    void init_XML(){ 
        Opportunity opp =[Select Owner.Name, Owner.Title, Owner.Phone, Owner.Email, OwnerId, Campaign_Name__c, IOnumber__c, Campaign_Start__c, Campaign_End__c, Agency__c, Agency__r.Name, Account.Name From Opportunity Where id=:oppId];
        
        //File name excel file should be: “Gumtree_”&opp.Agency__c&”_”&opp.Account&”_”&opp.Ext_Name_Campaign__c&”_”&opp.Campaign_Start__c&”-“&opp.Campaign_End__c”.xls”
        fileName='Gumtree_'+(opp.Agency__r.Name==null?'':opp.Agency__r.Name)+
                '_'+(opp.Account.Name==null?'':opp.Account.Name)+
                '_'+(opp.Campaign_Name__c==null?'':opp.Campaign_Name__c);

               // GTCRM-748 - Client Reporting Format Tweaks - Report Name Convention
               // '_'+(opp.Campaign_Start__c==null?'':(opp.Campaign_Start__c.format()))+
               // '-'+(opp.Campaign_End__c==null?'':(opp.Campaign_End__c.format())              
        
        //File Naming convention: exclude: " * / : < > ? \ [ ] | 
        //apex:page> contenttype="application/vnd.ms-excel#{!fileName}" that fileName must not contain space.
        Set<String> setUnsupportChar = new Set<String>{' ', '"' ,'*' ,'/' ,':' ,'<' ,'>' ,'?' ,'\\' ,'[' ,']' ,'|', '.', ','};//dot and comma are also added to avoid error of file name.
        for(String cha:setUnsupportChar){
            fileName=fileName.replace(cha, '_');
        }
        fileName=fileName+'.xls';
         
        //Header=========
        xml=xml.replace('{!date}',String.valueOf(System.today()));
        xml=xml.replace('{!campaign}',(opp.Campaign_Name__c==null?'':opp.Campaign_Name__c));
        xml=xml.replace('{!accname}',(opp.Account.Name==null?'':opp.Account.Name));
        xml=xml.replace('{!agency}',(opp.Agency__r.Name==null?'':opp.Agency__r.Name));  
        xml=xml.replace('{!sale}',(opp.Owner.Name==null?'':opp.Owner.Name));
        xml=xml.replace('<Data ss:Type="DateTime">{!start}',(opp.Campaign_Start__c==null?'<Data ss:Type="String">':('<Data ss:Type="DateTime">'+String.valueOf(opp.Campaign_Start__c))));
        xml=xml.replace('<Data ss:Type="DateTime">{!end}',(opp.Campaign_End__c==null?'<Data ss:Type="String">':('<Data ss:Type="DateTime">'+String.valueOf(opp.Campaign_End__c))));
        xml=xml.replace('{!offernum}',(opp.IOnumber__c==null?'':opp.IOnumber__c));
    
        //ColumnHeader==========
        String colWidth='';
        String col='';
        //loop through listTblColumn =but= takes from mapColumnLabel
        for(String colName: listTblColumn){ 
            colWidth+= '<Column ss:Width="'+mapColNameColWidth.get(colName)+'"/>';        
            col+='<Cell ss:StyleID="s147"><Data ss:Type="String">'+mapColumnLabel.get(colName)+'</Data></Cell>';
        }
        
        xml=xml.replace('   <Column ss:Width="188"/>'+
                        '   <Column ss:Width="376"/>'+
                        '   <Column ss:Width="68.25"/>'+
                        '   <Column ss:Width="64.5"/>'+
                        '   <Column ss:Width="83.25"/>'+
                        '   <Column ss:Width="117"/>'+
                        '   <Column ss:Width="95.25"/>'+
                        '   <Column ss:Width="90.75"/>'+
                        '   <Column ss:Width="99.75"/>'+
                        '   <Column ss:Width="84.75"/>'+
                        '   <Column ss:Width="111.75"/>'+
                        '   <Column ss:Width="81.75"/>'+
                        '   <Column ss:Width="53.25"/>'+
                        '   <Column ss:Width="78"/>',colWidth);
                
        xml=xml.replace('<Cell><Data ss:Type="String">{!ColumnHeader}</Data></Cell>',col);
        
        
        //Rows=============
        String rows='';
        
        for(Map<String, String> mapColVal : listMapColumnValue){
            String row='<Row><Cell/>'; 
            
            for(String colName : listTblColumn){
                
                //Delivered Impressions or Click Rate=empty if CPC) from  “Email Excel Report”
                //if from "Excel Report" show the value of CPC
                if(isFromBtn==false && ExcelReportHelper.isCPC(colName, mapColVal.get(COL_BILL_CAT))){
                    row+='<Cell ss:StyleID="'+mapColumnStyle.get(colName)+'"><Data ss:Type="String"></Data></Cell>';
                    continue;
                }
                
                /**not use becuase Click Rate field not ues fomular and use value instead
                //Click Rate=(For CPM or Fix Price: M/L)
                if(ExcelReportHelper.isCpmFixprice(colName, mapColVal.get(COL_BILL_CAT))){
                    row+='<Cell ss:Formula="=IF(ISERR(RC[-1]/RC[-2]),0,RC[-1]/RC[-2])" ss:StyleID="'+mapColumnStyle.get(colName)+'"><Data ss:Type="'+mapColumnType.get(colName)+'"></Data></Cell>';
                    continue;
                }
                */
                //if COL_DELIV_INDEX no value then cell is empty
                if(colName==COL_DELIV_INDEX && mapColVal.get(COL_DELIV_INDEX)==''){
                    row+='<Cell ss:StyleID="'+mapColumnStyle.get(colName)+'"><Data ss:Type="String"></Data></Cell>';
                    continue;
                }
                // Additional column for eCPM in Daily Reporting               
                if(colName==COL_ECPM && mapColVal.get(COL_ECPM)==''){
                    row+='<Cell ss:StyleID="'+mapColumnStyle.get(colName)+'"><Data ss:Type="String"></Data></Cell>';
                    continue;
                }
                
                //add value to each cell(loop throug column) if all "if" above not match.
                row+='<Cell ss:StyleID="'+mapColumnStyle.get(colName)+'"><Data ss:Type="'+mapColumnType.get(colName)+'">'+(mapColVal.get(colName)==null?'':mapColVal.get(colName))+'</Data></Cell>';
            } 
            rows+=row+'</Row>';
        }       
        
        xml=xml.replace('<Row><Cell><Data ss:Type="String">{!rows}</Data></Cell></Row>', rows);
        
        
        //listMapColumnValue=null;
        //###########################----code generate for detail sheet.----############################################################################
         
        //ColumnHeader==========
        colWidth='';
        col='';
        //loop through listTblColumnDetail =but= takes from mapColumnLabel
        for(String colName : listTblColumnDetail){ 
            colWidth+='<Column ss:Width="'+mapColNameColWidth.get(colName)+'"/>';            
            col+='<Cell ss:StyleID="s147"><Data ss:Type="String">'+mapColumnLabel.get(colName)+'</Data></Cell>';
        }
        xml=xml.replace('   <Column ss:Width="106.5"/>'+
                        '   <Column ss:Width="188.00"/>'+
                        '   <Column ss:Width="376.00"/>'+
                        '   <Column ss:Width="60.75"/>'+
                        '   <Column ss:Width="81.75"/>'+
                        '   <Column ss:Width="120"/>'+
                        '   <Column ss:Width="81.75"/>'+
                        '   <Column ss:Width="53.25"/>'+
                        '   <Column ss:Width="67.5"/>',colWidth);
        xml=xml.replace('<Cell><Data ss:Type="String">{!ColumnHeaderDetail}</Data></Cell>',col);
        
        //Rows=============
        rows=''; 
        for(Map<String, String> mapColVal : listMapColumnValueDetail){
            String row='<Row><Cell/>'; 
              for(String colName : listTblColumnDetail){ 
                  
                  //Total row of each line item in detail sheet.===================
                  if(mapColVal.get(COL_DATE)=='Total' && colName==COL_DATE){ 
                          row+='<Cell ss:StyleID="ss156"><Data ss:Type="String">'+System.Label.excel_total+'</Data></Cell>';
                          continue; 
                  }
                  
                  String forStyle=mapColVal.get(COL_DATE)=='Total'?'t':''; //use to concate to column's name to get style's name if it is total row
                    
                  //Delivered Impressions or Click Rate=empty if CPC)
                  if(isFromBtn==false && ExcelReportHelper.isCPC(colName, mapColVal.get(COL_BILL_CAT))){
                      row+='<Cell ss:StyleID="'+mapColumnStyle.get(colName+forStyle)+'"><Data ss:Type="String"></Data></Cell>';
                      continue;
                  }
                  
                  // Additional column for eCPM in Daily Reporting               
                  if(colName==COL_ECPM && mapColVal.get(COL_ECPM)==''){
                      row+='<Cell ss:StyleID="'+mapColumnStyle.get(colName)+'"><Data ss:Type="String"></Data></Cell>';
                      continue;
                  }
                  
                  /**not use becuase Click Rate field not ues fomular and use value instead
                  //Click Rate=(For CPM or Fix Price: M/L)
                  if(ExcelReportHelper.isCpmFixprice(colName, mapColVal.get(COL_BILL_CAT))){
                      row+='<Cell ss:Formula="=IF(ISERR(RC[-1]/RC[-2]),0,RC[-1]/RC[-2])" ss:StyleID="'+mapColumnStyle.get(colName+forStyle)+'"><Data ss:Type="'+mapColumnType.get(colName)+'"></Data></Cell>';
                      continue;
                  } 
                  */ 
                  row+='<Cell ss:StyleID="'+mapColumnStyle.get(colName+forStyle)+'"><Data ss:Type="'+mapColumnType.get(colName)+'">'+(mapColVal.get(colName)==null?'':mapColVal.get(colName))+'</Data></Cell>';
              }  
            rows+= row+'</Row>';
        }
        //System.debug('===========line:582==========Heap=='+ Limits.getHeapSize()); 
      //System.debug('===========line:583====Statements=='+ Limits.getScriptStatements());      
        xml=xml.replace('<Row><Cell><Data ss:Type="String">{!rowsDetail}</Data></Cell></Row>', rows);
        rows='';
        //replace currency
        //'{!@#}' is marked in xml
//        xml=xml.replace('{!@#}', ExcelReportHelper.mapCurrencyCodeSign.get(opp.CurrencyIsoCode)==null?opp.CurrencyIsoCode:ExcelReportHelper.mapCurrencyCodeSign.get(opp.CurrencyIsoCode));
        xml=xml.replace('{!@#}', 'GBP');
        
    }
    
    /** 
    *   For sorting list of OpportunityLineItem 
    *       @param1  list<OpportunityLineItem> that need to sort
    *       If product2.RecordType of a line item is “Package”, then below that line follow all lines where “LI.package_line_item__c” equals the ID of the package line item.
    
    
    list<OpportunityLineItem> sortOpplineItem(list<OpportunityLineItem> listOppL){
       
        list<OpportunityLineItem> listNew = new list<OpportunityLineItem>();
        for(OpportunityLineItem li : listOppL){
            if(li.package_line_item__c==null){
                
                listNew.add(li);
                if(li.Product_Record_Type__c==ExcelReportHelper.PRO_RECORD_TYPE_PACKAGE){
                    for(OpportunityLineItem li2 : listOppL){
                        if(li2.package_line_item__c==li.id){
                            listNew.add(li2);
                        }
                    }
                } 
            }
        }
        return listNew;
    }
    */ 
}