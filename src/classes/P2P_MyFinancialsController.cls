/**
 * Task #3967: Phase 1 My Financials (GTCRM-1291)
 * @description: attached doc "My Financials Phase 1.docx"
 * @author: CPN
 * @createdDate: Sept-16-2014
 */
global class P2P_MyFinancialsController {
    public Account acc { get; set; }
    public List<Invoices__c> invList { get; set; }
    public Integer totalRecords { get; set; }
    public String jsonSelInv{get;set;}
    
    public String getSitePrefix(){
        return Site.getPathPrefix() == null ? '' : Site.getPathPrefix();
    }
    
    /**
     * Fiqas Invoices should be refreshed in SFDC
     */
    public void receiveInvoices(){
        try{
            P2P_FiqasInvoicesAPI.upsertInvoicesFromAccountFiqas(acc.Id, acc.Account_Number_Fiqas__c, P2P_FiqasInvoicesAPI.convertToString(Date.today().addDays(-1)));
            
        }catch(Exception ex){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Warning, 'Latest invoices have not been received from Fiqas');
            System.debug('Exception receiveInvoices: ' + ex);
            ApexPages.addmessage(myMsg);
        }
        loadInvoice();
    }
    
    public P2P_MyFinancialsController(){
        String currentAccountId = P2P_Utils.retrieveCommunityAccountId();
        acc = [Select Current_Debt_Fiqas__c, Account_Number_Fiqas__c, Outstanding_Debt_Fiqas__c, Balance__c From Account Where Id =: currentAccountId];
        isGroupCheck = false;
        contentDomain = getInstanceUrl().replace('visual.force.com', 'content.force.com');
        defaultPaginationProperties();
        defaultFilters();
    }
    
    public PageReference filterChange(){
        defaultPaginationProperties();
        loadInvoice();
        return null;
    }
    
    /**
     *  Group check action for check/uncheck Current & Overdue invoice
     */
    private static final String CURRENT_OVERDUE_STATUS = 'Current;Overdue;Partially Paid';
    public Boolean isGroupCheck{get;set;}
    public PageReference groupCheckChange(){
        setCheckGroup(!isGroupCheck);
        return null;
    }
    private void setCheckGroup(Boolean isCheck){
        isGroupCheck = isCheck;
        if(mapSelectedInv == null) return;
        for(Invoices__c inv : invList){
            if(CURRENT_OVERDUE_STATUS.contains(inv.Invoice_Status__c)){
                mapSelectedInv.put(inv.Id, isGroupCheck); 
            }
        }
        recalTotalSelectedAmountDue(false);
    }
    
    public PageReference loadInvoice(){
        currentSoredField = sortByField;
        isDESC = true;
        invList = queryWithSortedList(currentSoredField, isDESC);
        makeDefaultSelectedPayment();
        return null;
    }
    
    private List<Invoices__c> createResultRowsList(List<Id> listIds){
        String queryWhere = 'Where Id IN: listIds order by ' + currentSoredField + (isDESC ? ' desc' : ' asc');
        return DataBase.query('Select Name, Invoice_Status__c, Days_since_creation__c, Invoice_Date__c, Period__c, Age__c, Invoice_amount__c, Amount_due__c, Payment_date__c, Paid_in_full__c, Overdue__c, Document_type__c, Payment_Due_Date__c From Invoices__c ' + queryWhere);
    }
    
    /**
     *  Sort Invoice by invoice status priority order
     */
    private static final String INVOICE_STATUS_FIELD = 'Invoice_Status__c';
    private static Set<String>sortOrder = new Set<String>{'Overdue', 'Partially Paid', 'Current', 'Paid in Full', 'Written Off'};
    private List<Invoices__c> sortByPriorStatus(List<Invoices__c>lstInvoices){
        
        //group invoice by invoice status
        Map<String, List<Invoices__c>>mInvoice = new Map<String, List<Invoices__c>>();
        for(Invoices__c inv : lstInvoices){
            
            if(!mInvoice.containsKey(inv.Invoice_Status__c)) mInvoice.put(inv.Invoice_Status__c, new List<Invoices__c>());
            mInvoice.get(inv.Invoice_Status__c).add(inv);
        }
        
        List<Invoices__c>lstSortInvoice = new List<Invoices__c>();
        for(String sOrder : sortOrder){
            if(mInvoice.get(sOrder) != null) lstSortInvoice.addAll(mInvoice.get(sOrder));           
        }
        
        return lstSortInvoice;
    }
    
    //Customer should be able to sort by column headers in the invoice list
    public String sortByField { get; set; }
    public Boolean isDESC { get; set; }
    private String currentSoredField;
    
    public PageReference sortInvoice(){
        if(currentSoredField == sortByField){ 
            //Sort on same column
            isDESC = !isDESC; 
        }else{
            //Sort another column
            currentSoredField = sortByField;
            isDESC = true;
        }
        invList = queryWithSortedList(currentSoredField, isDESC);
        return null;
    }
    
    private List<Invoices__c> queryWithSortedList(String colName, Boolean byDESC){
        String pSearchKey = '';
        if(!String.isEmpty(searchKey)) pSearchKey = '%' + searchKey.trim() + '%';
        //Sorted Result
        String accId = acc.Id;
        //Document_type__c
        String queryWhere = 'Where Account__c =: accId ' ;
        Set<String> statuses = splitFilterValues('&', filterStatus);
        if(!statuses.isEmpty()) queryWhere += ' And Invoice_Status__c IN: statuses ';
        if(!String.isEmpty(pSearchKey)) queryWhere += ' And Name Like: pSearchKey ';
        queryWhere += 'order by '+ colName + (filterStatus == 'Current & Overdue' ? ',Invoice_Status__c': '') + (byDESC ? ' desc' : ' asc');
        List<Invoices__c> invlist = DataBase.query('Select Id, Invoice_Status__c From Invoices__c ' + queryWhere);
        
        //check current sort by invoice status field and call status priority status
        invlist = currentSoredField == INVOICE_STATUS_FIELD ? sortByPriorStatus(invlist) : invlist;
        
        totalRecords = invlist.size();
        //Pagination
        pageNumList = new List<Integer>();
        mPaging = new Map<Integer, List<Id>>();
        Integer p = 1;
        totalResultSize = invlist.size();
        for(Invoices__c inv : invlist){
            if(!mPaging.containsKey(p)){
                mPaging.put(p, new List<Id>());
                pageNumList.add(p);
            }
            if(mPaging.get(p).size() == listSize){
                p++;
                mPaging.put(p, new List<Id>());
                pageNumList.add(p);
            }
            mPaging.get(p).add(inv.Id);
        }
        
        curPage = 1;
        //check if no invoices
        if(mPaging.get(curPage) == null){
            mPaging.put(curPage, new List<Id>());
        }
        
        List<Id> pageList = mPaging.get(curPage);
        return mPaging.isEmpty() ? new List<Invoices__c>() : createResultRowsList(pageList);
    }
    
    //Customer should be able to filter invoice list based on Invoice_Status__c
    public String searchKey {get; set;}
    public String filterStatus { get; set; }
    public List<SelectOption> filterStatusOptions { get; set; }
    
    private void defaultFilters(){
        searchKey = '';
        filterStatus = 'Current & Overdue & Partially Paid';
        filterStatusOptions = new List<SelectOption>();
        filterStatusOptions.add(new SelectOption('', 'All'));
        filterStatusOptions.add(new SelectOption(filterStatus, 'Outstanding'));
        filterStatusOptions.add(new SelectOption('Current', 'Current'));
        filterStatusOptions.add(new SelectOption('Overdue', 'Overdue'));
        filterStatusOptions.add(new SelectOption('Partially Paid', 'Partially Paid'));
        filterStatusOptions.add(new SelectOption('Awaiting Settlement', 'Awaiting Settlement')); 
        filterStatusOptions.add(new SelectOption('Paid in Full', 'Paid in Full'));
        filterStatusOptions.add(new SelectOption('Credit Note', 'Credit Note'));        
        sortByField = 'Age__c';
    }
    
    private Set<String> splitFilterValues(String delimSign, String filterValue){
        Set<String> values = new Set<String>();
        if(filterValue == null) return values;
        List<String> srcValues = filterValue.split(delimSign);
        for(String val : srcValues){
            values.add(val.trim());
        }
        return values;
    }
    
    // We require pagination on the invoice list
    public Integer listSize { get; set; }
    public List<SelectOption> listSizeOptions { get; set; }
    public Integer curPage { get; set; }
    public Map<Integer, List<Id>> mPaging { get; set; }
    private Integer totalResultSize = 0;
    public List<Integer> pageNumList { get; set;}
    
    private void defaultPaginationProperties(){
        listSize = 10;
        listSizeOptions = new List<SelectOption>();
        listSizeOptions.add(new SelectOption('10', '10 per page'));
        listSizeOptions.add(new SelectOption('20', '20 per page'));
        listSizeOptions.add(new SelectOption('50', '50 per page'));
    }
    
    public Integer getStartIndex() {
        return curPage == 0 || curPage == 1? curPage : ((curPage - 1) * listSize) + 1;
    }
    
    public Integer getEndIndex() {
        Integer endInd = getStartIndex() + listSize - 1;
        return endInd > totalResultSize ? totalResultSize : endInd;
    }
     
    public Integer getTotalResultSize(){
        return totalResultSize;
    }
    
    public Integer getTotalPageSize(){
        return mPaging.size();
    }
    
    public PageReference goToPage(){
        invList = createResultRowsList(mPaging.get(curPage));
        return null;
    }
    
    public PageReference goNextPage() {
        if(totalResultSize > curPage * listSize) {
            curPage++;
            invList = createResultRowsList(mPaging.get(curPage));
        }
        return null;
    }    
    
    public PageReference goPreviousPage() {   
        if(curPage > 1){
            curPage--;
            invList = createResultRowsList(mPaging.get(curPage));
        }
        return null;
    }
     
    public boolean getPrevRequired() {
        return curPage > 1; 
    }
    
    public boolean getNextRequired() {
        return curPage * listSize < totalResultSize;
    }
     
    //Customer should be able to download a PDF copy of individual invoice
    public String contentDomain { get; set; }
    public String urldocPdf { get; set; }
    public String invNumber { get; set; }
    
    public PageReference requestPDFBody(){
        urldocPdf =  wsRequestPDFBody(invNumber);
        return null;
    } 
    
    webservice static String wsRequestPDFBody(String invNo){
        FiqasPDFViewController cont = new FiqasPDFViewController(invNo);
        cont.requestPDFBoday();
        return cont.body != null ? 'data:application/pdf;base64,' + cont.body : '';
    }
    
    public String getInstanceUrl(){
       String domain;// = [Select d.Domain From Domain d where DomainType='DNS' Limit 1].Domain; Return site domain
       //if (domain==null){
           domain=URL.getSalesforceBaseURL().getHost();
       //}
       return 'https://'+domain;
    }
    
    //Customer should be able to select and pay for invoices via Braintree
    public Map<String, Boolean> mapSelectedInv { get; set; }
    public Invoices__c totalSelectedAmountDue { get; set; }
    private Set<String> preSelectedStatus = new Set<String>{'Overdue'};
    private static final String PARTIALLY_PAID_STATUS   = 'Partially Paid';
    private static final String CURRENT_INVOICE_STATUS  = 'Current';
    public boolean isInvoiceHaveOverdue {get; set;}
    
    private void makeDefaultSelectedPayment(){
        mapSelectedInv = new Map<String, Boolean>();
        List<Id> invIds = new List<Id>();
        for(Integer p : mPaging.keySet()){
            for(Id invId : mPaging.get(p)){
                mapSelectedInv.put(invId, false);
                invIds.add(invId);
            }
        }
        
        List<Invoices__c> lstInvoice;
        
        //make preselected all invoices when Current Type is selected
        if(filterStatus == CURRENT_INVOICE_STATUS){
            lstInvoice = invList;
        }else{
             lstInvoice = [Select Id From Invoices__c Where Id IN: invIds And Invoice_Status__c IN: preSelectedStatus];
            //include Invoice with status = 'Partially Paid' and Age__c >= 30 to preSelectedStatus
            lstInvoice.addAll([Select Id from Invoices__c where Id IN:invIds And Invoice_Status__c =:PARTIALLY_PAID_STATUS and 
                            (Age__c >= 30 OR Payment_due_date__c < TODAY OR Amount_due__c > 0)]);
        }
        
        isInvoiceHaveOverdue = false;
        for(Invoices__c inv :lstInvoice){
            mapSelectedInv.put(inv.Id, true);
            isInvoiceHaveOverdue = true;
        }
        
        recalTotalSelectedAmountDue(!isInvoiceHaveOverdue);
    }
    
    private void recalTotalSelectedAmountDue(boolean isClearAllSelect){
        List<Id> selectedInv = new List<Id>();
        for(Id invId : mapSelectedInv.keySet()){
            if(mapSelectedInv.get(invId)) selectedInv.add(invId);
        }
        //clear the select from map when list reload
        if(isClearAllSelect){
            for(Id invId : mapSelectedInv.keySet()){
                mapSelectedInv.put(invId, false) ;
            }
        }
        jsonSelInv = JSON.serialize(selectedInv);
        
        AggregateResult agRsl = [Select SUM(Amount_due__c) tAmountDue From Invoices__c Where Id IN: selectedInv];
        totalSelectedAmountDue = new Invoices__c(Invoice_amount__c = (Decimal)agRsl.get('tAmountDue'));
        if(totalSelectedAmountDue.Invoice_amount__c == null) totalSelectedAmountDue.Invoice_amount__c = 0;
    }
    
    public PageReference onSelectPayment(){
        recalTotalSelectedAmountDue(false);
        return null;
    }


// Alert banner at top of the page - Work in progress by Steve Paul
    public List<PKB_Status_Message__c> msgErr {
        get {
            List<PKB_Status_Message__c> systemMsg = new List<PKB_Status_Message__c>(); 
            for(PKB_Status_Message__c sm: [SELECT MessageText__c, Message_Type__c, Message_Start_DateTime__c, Message_End_DateTime__c, Module__c, Account__c
                                                  FROM PKB_Status_Message__c
                                                  WHERE Status__c = 'Active'
                                                  AND Module__c = 'Financials'
                                                  AND (Account__c = :acc.id OR Account__c = '')
                                                  AND ((Message_Start_DateTime__c < :system.now() AND
                                                        Message_End_DateTime__c   > :system.now())
                                                  OR   (Message_Start_DateTime__c = null AND
                                                        Message_End_DateTime__c   = null)) order by CreatedDate desc LIMIT 1
                                                  ]){
                   systemMsg.add(sm);
                  
                 //System.debug('XXXXX sm-->' + sm);
            }
            return systemMsg;
        } 
        set;
    }

// get user agent for Google Analytics tracking
    public String getUA() {
        return ApexPages.currentPage().getHeaders().get('User-Agent');
    } 
    
}