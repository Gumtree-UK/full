/**
 * Task #4330: GTCRM-1294 - PRO - M4 - 'My metrics' module - Build
 * @description: attached doc "P2P - Technical specifications - Metrics.docx"
 * @author: Pheaktra Hun
 * @createdDate: 25-Nov-2014

Change log;
- 2015-05-29 - GTCRM-2048 - PRO - Default end date value on metrics ads to current month

 */
global class P2P_MyMetricsController {
    
    private static final String DEFAULT_CHART_LOCATION = 'Nationwide';
    private static List<Metrics_Dashboard__c> defaultCharts = new List<Metrics_Dashboard__c>{
        new Metrics_Dashboard__c(Chart_Title__c='Number of live ads – Nationwide', Chart_Description__c='The chart shows the number of live ads in the period', Timeframe__c='Month on month', Chart_Type__c='Bar', Period__c='Current & previous year', Data_Point_A__c='Live ads'),
        new Metrics_Dashboard__c(Chart_Title__c='Number of new ads posted – Nationwide', Chart_Description__c='The chart shows the number of new ads posted in the period', Timeframe__c='Month on month', Chart_Type__c='Bar', Period__c='Current & previous year', Data_Point_A__c='Ads posted'),
        new Metrics_Dashboard__c(Chart_Title__c='Email replies per ad posted – Nationwide', Chart_Description__c='The chart shows the number of email replies per ad posted in the period', Timeframe__c='Year on year', Chart_Type__c='Line', Period__c='Current & previous 2 years', Data_Point_A__c='Email replies per ad')
    };
    
    public String getSitePrefix(){
        return Site.getPathPrefix() == null ? '' : Site.getPathPrefix();
    }
    
    public Account acc{get;set;}
    public Metrics_Dashboard__c newDashBoard{get;set;}
    public List<Metrics_Dashboard__c>lstDashBoardCharts{get;set;}
    public Integer saveIndex{get;set;}
    public String pickFromDate{get;set;}
    public String pickUtilDate{get;set;}
    
    public String mDBChartsJsonStr{get;set;}
    public String mDateRangeJsonStr{get;set;}
    public String mDateRangeYearOnYearJsonStr{get;set;}
    public String mMonthOnMonthJsonStr{get;set;}
    public String mQuartOnQuartJsonStr{get;set;}
    
    private Map<String, Metrics_Dashboard__c>mDashBoardCharts;
    private Map<String, Double>mMonthOnMonth;
    private Map<String, Double>mQuartOnQuart;
    private Map<String, List<String>>mDateRange;
    private Map<String, List<String>>mDateRangeYearOnYear;
    
    public P2P_MyMetricsController(){
        String currentAccountId = P2P_Utils.retrieveCommunityAccountId();
        acc = new Account(Id = currentAccountId);
        initAdsBreakdown();
    }
    
    public P2P_MyMetricsController(ApexPages.StandardController stdController){
        acc = (Account)stdController.getRecord();
        initAdsBreakdown();
    }
    
    private void initChartMetrics(){
        
        mDashBoardCharts = new Map<String, Metrics_Dashboard__c>();
        mMonthOnMonth = new Map<String, Double>();
        mQuartOnQuart = new Map<String, Double>();
        mDateRange = new Map<String, List<String>>();
        mDateRangeYearOnYear = new Map<String, List<String>>();
        
        lstDashBoardCharts = [Select until_Date__c, from_Date__c, Timeframe__c, Position__c, Period__c, Location_A__c, Data_Point_A__c, 
                            Chart_Type__c, Chart_Title__c, Chart_Description__c From Metrics_Dashboard__c where Account__c =:acc.Id order by Position__c limit 6];
                            
        if(lstDashBoardCharts.isEmpty()){
            for(Integer i=0;i<defaultCharts.size();i++){
                
                Metrics_Dashboard__c md = defaultCharts[i];
                md.Position__c = i+1;
                md.Location_A__c = DEFAULT_CHART_LOCATION;
                md.Account__c = acc.Id;
                setMDFromUtilDate(md);
                
                lstDashBoardCharts.add(md);
            }
            insert lstDashBoardCharts;
        }
        
        for(Metrics_Dashboard__c md : lstDashBoardCharts){
            String mdId = getMDId(md);
            
            mDashBoardCharts.put(mdId, md);
            fetchDataInDateRange(md);
        }
        
        Date fromDate = Date.newInstance(Date.today().year()-1, 1, 1);
        Date utilDate = Date.newInstance(Date.today().year(), 12, 31);
        newDashBoard = new Metrics_Dashboard__c(Position__c=lstDashBoardCharts.size()+1, Chart_Type__c='Bar', Timeframe__c='Month on month', Account__c=acc.Id, 
                                                from_Date__c=fromDate, until_Date__c=utilDate);
        generateJSONData();
    }
    
    private void generateJSONData(){
        mDBChartsJsonStr = JSON.serialize(mDashBoardCharts);
        mDateRangeJsonStr = JSON.serialize(mDateRange);
        mMonthOnMonthJsonStr = JSON.serialize(mMonthOnMonth);
        mQuartOnQuartJsonStr = JSON.serialize(mQuartOnQuart);
        mDateRangeYearOnYearJsonStr = JSON.serialize(mDateRangeYearOnYear);
    }
    
    private String getMDId(Metrics_Dashboard__c md){
        return md.Id == null ? md.Position__c+'' : md.Id;
    }
    
    public Pagereference refreshNewChartData(){
        newDashBoard.Chart_Title__c = newDashBoard.Data_Point_A__c + ' - ' + newDashBoard.Location_A__c;
        refreshMDData(newDashBoard);
        return null;
    }
    
    public Pagereference refreshEditChartData(){
        Metrics_Dashboard__c md = lstDashBoardCharts.get(saveIndex-1);
        refreshMDData(md);
        return null;
    }
    
    private void refreshMDData(Metrics_Dashboard__c md){
        String mdId = getMDId(md);
        clearOldMDData(md);
        
        if(pickFromDate != '') md.from_Date__c = Date.parse(pickFromDate);
        if(pickUtilDate != '') md.until_Date__c = Date.parse(pickUtilDate);
        fetchDataInDateRange(md);
        
        if(!mDashBoardCharts.containsKey(mdId)) mDashBoardCharts.put(mdId, md);
        generateJSONData();
    }
    
    /**
     *  Clear old Date Range(X axis)  
     */
    private void clearOldMDData(Metrics_Dashboard__c md){
        
        String mdId = getMDId(md);
        if(mDateRange.containsKey(mdId)) mDateRange.get(mdId).clear();
        if(mDateRangeYearOnYear.containsKey(mdId)) mDateRangeYearOnYear.get(mdId).clear();
        for(String key : mMonthOnMonth.keySet()){
            if(key.startsWith(mdId)) mMonthOnMonth.remove(key);
        }
        
        for(String key : mQuartOnQuart.keySet()){
            if(key.startsWith(mdId)) mQuartOnQuart.remove(key);
        }
        
    }
    
    public Pagereference saveNewChart(){
        newDashBoard.Chart_Title__c = newDashBoard.Data_Point_A__c + ' - ' + newDashBoard.Location_A__c;
        if(pickFromDate != '') newDashBoard.from_Date__c = Date.parse(pickFromDate);
        if(pickUtilDate != '') newDashBoard.until_Date__c = Date.parse(pickUtilDate);
        insert newDashBoard;
        initChartMetrics();
        return null;
    }
    
    public Pagereference deleteChart(){
        Metrics_Dashboard__c md = lstDashBoardCharts.get(saveIndex-1);
        if(md != null){ 
            delete md;
            lstDashBoardCharts.remove(saveIndex-1);
            reorderPosition();
        }
        initChartMetrics();
        return null;
    }
    
    private void reorderPosition(){
        
        Integer pos = 1;
        for(Metrics_Dashboard__c md : lstDashBoardCharts){
            md.Position__c = pos;
            pos++;
        }
        update lstDashBoardCharts;
        newDashBoard.Position__c = pos;
    }
    
    public Pagereference cancelAddOrEditChart(){
        initChartMetrics();
        return null;
    }
    
    /**
     *  Save Edit Dashboard Chart
     */
    public Pagereference saveEditChart(){
        
        Metrics_Dashboard__c md = lstDashBoardCharts.get(saveIndex-1);
        
        if(pickFromDate != '') md.from_Date__c = Date.parse(pickFromDate);
        if(pickUtilDate != '') md.until_Date__c = Date.parse(pickUtilDate);
        
        upsert md;
        
        initChartMetrics();
        return null;
    }
    
    /**
     *  Save sort charts
     */
    public Pagereference saveSortCharts(){
        update lstDashBoardCharts;
        initChartMetrics();
        return null;
    }
    
    /**
     *  Cancel sort charts
     */
    public Pagereference cancelSortCharts(){
        initChartMetrics();
        return null;
    }
    
    /**
     *  Calculate from_Date__c & until_Date__c of Period__c
     */
    private void setMDFromUtilDate(Metrics_Dashboard__c md){
        
        String periodString = md.Period__c;
        if(periodString == 'Current year'){
            md.from_Date__c = Date.newInstance(Date.today().year(), 1, 1);
            md.until_Date__c = Date.newInstance(Date.today().year(), 12, 31);
        }
        else if(periodString == 'Current & previous year'){
            md.from_Date__c = Date.newInstance(Date.today().addYears(-1).year(), 1, 1);
            md.until_Date__c = Date.newInstance(Date.today().year(), 12, 31);
        }
        else if(periodString == 'Current & previous 2 years'){
            md.from_Date__c = Date.newInstance(Date.today().addYears(-2).year(), 1, 1);
            md.until_Date__c = Date.newInstance(Date.today().year(), 12, 31);
        }
        
    }
    
    /**
     *  Fetch performance data (Y axis)
     */
    private void fetchDataInDateRange(Metrics_Dashboard__c md){
        
        String mdId = getMDId(md);
        
        Date fromDate = md.from_Date__c;
        Date utilDate = md.until_Date__c;
        String accId = acc.Id;
        
        String qryWhere = 'WHERE Account__c=:accId ';
        qryWhere += 'AND Date__c >= :fromDate AND Date__c <= :utilDate order by Date__c';
        
        String fPrefix = getFieldPrefix(md.Location_A__c, md.Data_Point_A__c);
        String fNameA = fPrefix + getFieldSuffix(md.Location_A__c);
        
        for(Performance_Metrics__c pm : Database.query('Select Date__c, ' + fNameA + ' from Performance_Metrics__c ' + qryWhere)){
            
            setDateRange(md, pm.Date__c);
            
            //sum value group by month
            String monthKey = mdId + ' ' + dateToStringWithFormat(pm.Date__c, 'MMM yyyy');
            if(!mMonthOnMonth.containsKey(monthKey)) mMonthOnMonth.put(monthKey, (Double)pm.get(fNameA));
            else mMonthOnMonth.put(monthKey, mMonthOnMonth.get(monthKey) + (Double)pm.get(fNameA));
            
            //sum value group by quarter
            Integer currentQuarter = ((pm.Date__c.month()-1)/3) + 1; 
            String quartKey = mdId + ' Q' + currentQuarter + ' ' + dateToStringWithFormat(pm.Date__c, 'yyyy');
            if(!mQuartOnQuart.containsKey(quartKey)) mQuartOnQuart.put(quartKey, (Double)pm.get(fNameA));
            else mQuartOnQuart.put(quartKey, mQuartOnQuart.get(quartKey) + (Double)pm.get(fNameA));
            
        }
        
    }
    
    /**
     *  Find TimeFrame match from_Date__c and until_Date__c (X axis)
     */
    private void setDateRange(Metrics_Dashboard__c md, Date pfDate){
        
        String mdId = getMDId(md);
        if(!mDateRange.containsKey(mdId)) mDateRange.put(mdId, new List<String>());
        
        Set<String>setDateRange = new Set<String>(mDateRange.get(mdId));
        String dateKey = '';
        if(md.Timeframe__c == 'Month on month'){
            
            dateKey = dateToStringWithFormat(pfDate, 'MMM yyyy');
            
        }else if(md.Timeframe__c == 'Quarter on quarter'){
            
            Integer currentQuarter = ((pfDate.month()-1)/3) + 1;
            dateKey = 'Q' + currentQuarter + ' ' + dateToStringWithFormat(pfDate, 'yyyy');
            
        }else if(md.Timeframe__c == 'Year on year'){
            
            if(!mDateRangeYearOnYear.containsKey(mdId)) mDateRangeYearOnYear.put(mdId, new List<String>());
            Set<String>setYearRange = new Set<String>(mDateRangeYearOnYear.get(mdId));
            
            String yearStr = dateToStringWithFormat(pfDate, 'yyyy');
            dateKey = dateToStringWithFormat(pfDate, 'MMM');
            
            if(!setYearRange.contains(yearStr)) mDateRangeYearOnYear.get(mdId).add(yearStr);
        }
        
        if(!setDateRange.contains(dateKey)) mDateRange.get(mdId).add(dateKey);
    }
    
    public static String dateToStringWithFormat(Date d, String dateFormat){
        
        Datetime dt = Datetime.newInstance(d.year(), d.month(), d.day());
        return dt.format(dateFormat);
    }
    
    private String getFieldPrefix(String location, String dataPoint){
        String prefix = dataPoint.replaceAll(' ', '_');
        prefix = prefix == 'Ads_reposted' ? 'Reposted_Ads' : prefix;
        return location == 'Nationwide' ? prefix : prefix + '_';
    }
    
    private String getFieldSuffix(String location){
        return location == 'Nationwide' ? '__c' : location + '__c';
    }
    
    /**
     * The remote action execute after
     * chart has been draw by P2P_MyMetrics.page
     * @param attName is the attachment name
     * @param body is the body of attachment
     * @param accid is the id of current account
     * @param des is the title and description of chart
     */
    @RemoteAction
    global static void createAttChartImage(String attName, String body, String mdId){
        
        if(String.isEmpty(mdId)) return;
        
        List<Attachment> lstAtt = [SELECT Id FROM Attachment WHERE Name=:attName AND ParentId =: mdId];
        if(!lstAtt.isEmpty())delete lstAtt;
        
        String b = body.replace('data:image/png;base64,','');
        Attachment att = new Attachment();
        att.Name = attName;
        att.Body = Encodingutil.base64Decode(b);
        att.ParentId = mdId;
        insert att;         
    }
    
    /**
     * Delete chart attchment
     */
    public PageReference deleteAttChart(){
        initChartMetrics();
        
        /*List<String> chName = new List<String>{'gchart1','gchart2','gchart3','gchart4','gchart5','gchart6'};
        List<Attachment> lstAtt = [SELECT Id FROM Attachment WHERE Name IN: chName AND ParentId =: acc.Id];
        if(!lstAtt.isEmpty())delete lstAtt;*/
        return null;
    }
    
    
    // Alert banner at top of the page - Work in progress by Steve Paul
    public List<PKB_Status_Message__c> msgErr {
        get {
            List<PKB_Status_Message__c> systemMsg = new List<PKB_Status_Message__c>(); 
            for(PKB_Status_Message__c sm: [SELECT MessageText__c, Message_Type__c, Message_Start_DateTime__c, Message_End_DateTime__c, Module__c, Account__c
                                                  FROM PKB_Status_Message__c
                                                 WHERE Status__c = 'Active'
                                                  AND Module__c = 'Metrics'
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
    
    //---------Ads Breakdown ---------------//
    //@suy sreymol 05/01/15
    public String pmFromDatestr {get;set;}
    public String pmEndDatestr {get;set;}
    public Date pmFromDate {get {return Date.parse(pmFromDatestr);}set;}
    public Date pmEndDate {get{return Date.parse(pmEndDatestr);}set;}
    public String sortFieldName {get;set;}
    public Boolean isSortByASC {get;set;}
    
    public List<PMDto> listPMDto {get;set;}
    public PMDto perMertsSummaryDto {get;set;}
    public String displayType {get;set;}
    public List<String> fieldNames {get;set;}
    public Map<String, String> dataSummaryHeaders {get;set;}
    public Map<String, String> dataSummaryHeadersInfos {get;set;}
    
    public String location{get;set;}
    public String currentSoredField;
    
    //field name
    private static final String FIELD_LIVE_ADS                      = 'Live_ads';
    private static final String FIELD_ADS_POSTED                    = 'Ads_posted';
    private static final String FIELD_NEW_ADS_POSTED                = 'New_ads_posted';
    private static final String FIELD_REPOSTED_ADS                  = 'Reposted_Ads';
    private static final String FIELD_EMAIL_PEPLIES                 = 'Email_replies';
    private static final String FIELD_EMAIL_REPLIES_PER_AD          = 'Email_replies_per_ad';
    
    //list fields name
    private List<String> availableFieldsName = new List<String>{ FIELD_LIVE_ADS, FIELD_ADS_POSTED, FIELD_NEW_ADS_POSTED, FIELD_REPOSTED_ADS, FIELD_EMAIL_PEPLIES, FIELD_EMAIL_REPLIES_PER_AD };
                                               
    //map quater numner and available month of start/end quarter
    private final Map<Integer, List<Integer>> mQuarterMonths = new Map<Integer, List<Integer>>{ 1=>new List<Integer>{1,3}, 2=>new List<Integer>{4,6}, 3=>new List<Integer>{7,9}, 4=>new List<Integer>{10,12} };
    
    //location
    private static final String LOCATION_NATIONWIDE = 'Nationwide';
    private static final String LOCATION_LONDON     = 'London';
    private static final String LOCATION_ROUK       = 'RoUK';
    public List<SelectOption> getLocations() {
        return new List<SelectOption>{
            new SelectOption(LOCATION_NATIONWIDE, LOCATION_NATIONWIDE),
            new SelectOption(LOCATION_LONDON, LOCATION_LONDON),
            new SelectOption(LOCATION_ROUK, 'Outside of London')
        };
    }
    
    //display type string
    private static final String VIEW_TYPE_MONTH     = 'Month';
    private static final String VIEW_TYPE_QUARTER   = 'Quarter';
    private static final String VIEW_TYPE_YEAR      = 'Year';
    public List<SelectOption> getDisplayTypePicklist(){
        return new List<SelectOption>{
            new SelectOption(VIEW_TYPE_MONTH, 'Month on month'),
            new SelectOption(VIEW_TYPE_QUARTER, 'Quarter on quarter'),
            new SelectOption(VIEW_TYPE_YEAR, 'Year on year')
        };
    }
    
    /**
     *  Send all Ads Breakdown filter to Export Excel page
     */
    public String getJsonStrFilter(){
        Map<String, String>mFilter = new Map<String, String>();
        mFilter.put('Location', location);
        mFilter.put('FromDate', pmFromDatestr);
        mFilter.put('EndDate', pmEndDatestr);
        mFilter.put('Display', displayType);
        mFilter.put('SortField', currentSoredField);
        mFilter.put('isSortByASC', isSortByASC+'');
        
        return JSON.serialize(mFilter);
    }
    
    public void initAdsBreakdown() {
        //map the field name and label header of summary table
        dataSummaryHeaders = new Map<String, String>{       FIELD_LIVE_ADS                      =>  'Live Ads:', 
                                                            FIELD_ADS_POSTED                    =>  'Total Ads Posted:', 
                                                            FIELD_NEW_ADS_POSTED                =>  'New Ads Posted:', 
                                                            FIELD_REPOSTED_ADS                  =>  'Ads Reposted:', 
                                                            FIELD_EMAIL_PEPLIES                 =>  'Email Replies:', 
                                                            FIELD_EMAIL_REPLIES_PER_AD          =>  'Email Replies Per Ad:'
                                                    };
                                                    
        //map column name with helper text label
        dataSummaryHeadersInfos = new Map<String, String>{  FIELD_LIVE_ADS                      =>  system.Label.P2P_AdsBreakdown_Col1,
                                                            FIELD_ADS_POSTED                    =>  system.Label.P2P_AdsBreakdown_Col2, 
                                                            FIELD_NEW_ADS_POSTED                =>  system.Label.P2P_AdsBreakdown_Col4, 
                                                            FIELD_REPOSTED_ADS                  =>  system.Label.P2P_AdsBreakdown_Col5, 
                                                            FIELD_EMAIL_PEPLIES                 =>  system.Label.P2P_AdsBreakdown_Col8, 
                                                            FIELD_EMAIL_REPLIES_PER_AD          =>  system.Label.P2P_AdsBreakdown_Col9
                                                        };
        //set default location = All after first opened the page
        location = LOCATION_NATIONWIDE;
        //set defualt display = Month
        displayType = VIEW_TYPE_MONTH;
        //new perMertsSummary to prevent null pointer
        fieldNames = new List<String>();
        //default srt field is Date__c
        sortFieldName = 'Date';
        currentSoredField = sortFieldName;
        //default sort by descendance
        isSortByASC = false;
        //Date range - default to Current Year-1, so start date if customer loads page now would be 01/01/2014 & end date would be 31/1/2015
        pmFromDatestr = dateToStringWithFormat(Date.newInstance(Date.today().year()-1, 1, 1), 'dd/MM/yyyy');
        //pmEndDatestr = dateToStringWithFormat(Date.newInstance(Date.today().year(), 1, 1), 'dd/MM/yyyy');
        
        //GTCRM-2048 - PRO - Default end date value on metrics ads to current month
        Integer numberDays = date.daysInMonth(Date.today().year(), Date.today().month());
        pmEndDatestr = dateToStringWithFormat(Date.newInstance(Date.today().year(), Date.today().month(), numberDays), 'dd/MM/yyyy');
        
        //set data to detail data table when the first load
        getPerfMetrice2Display(); 
    }
    
    private List<Performance_Metrics__c> getPerMetriceRecords(){
        //account id
        String accId = acc.Id;
        Date fromDate2query;
        Date untilDate2query;
        Integer numOfDays;
        
        String query = 'Select Id, Date__c';
        List<String> fieldNames = new List<String>();
        for (String s : availableFieldsName) fieldNames.add(addSuffix(s));
        
        //set field name to query
        for (String fieldname : fieldNames) query += ', ' + fieldname;
        query += ' From Performance_Metrics__c';
        String condition = ' Where Account__c =: accId';
        
        //filter by from date and end date that user have been selected from the page
        if (displayType.equals(VIEW_TYPE_MONTH)) {
            fromDate2query = Date.newInstance(pmFromDate.year(), pmFromDate.month(), 1);
            numOfDays = Date.daysInMonth(pmEndDate.year(), pmEndDate.month());
            untilDate2query = Date.newInstance(pmEndDate.year(), pmEndDate.month(), numOfDays);
        } else if (displayType.equals(VIEW_TYPE_QUARTER)) {
            Integer startQuarter = ((pmFromDate.month() -1) / 3) + 1;
            Integer endQuarter = ((pmEndDate.month() -1) / 3) + 1;
            Integer smonthNum = mQuarterMonths.get(startQuarter)[0];
            Integer emonthNum = mQuarterMonths.get(endQuarter)[1];
            fromDate2query = Date.newInstance(pmFromDate.year(), smonthNum, 1);
            numOfDays = Date.daysInMonth(pmEndDate.year(), emonthNum);
            untilDate2query = Date.newInstance(pmEndDate.year(), emonthNum, numOfDays);
        } else if (displayType.equals(VIEW_TYPE_YEAR)) {
            fromDate2query = Date.newInstance(pmFromDate.year(), 1, 1);
            untilDate2query = Date.newInstance(pmEndDate.year(), 12, 31);
        }
        condition += ' and Date__c >=: fromDate2query and Date__c <=: untilDate2query';
        
        String sortType = isSortByASC ? ' ASC' : ' DESC';
        String orderBy = ' Order By ' + addSuffix(sortFieldName) + sortType;
        query += condition + orderBy;
        
        //get Performance_Metrics__c records to display on the page
        return Database.query(query);
    }
    
    private Map<Integer, PMDto> fetchPMDataByTimeFrame(List<Performance_Metrics__c> perfMets){
        Map<Integer, PMDto> mDtoDatas = new Map<Integer, PMDto>();
        Map<String, Integer> mDtoPos = new Map<String, Integer>();
        Integer positionKey = 0;
        for(Performance_Metrics__c pm : perfMets){
            for (String field : availableFieldsName) {
                String pmField = addSuffix(field);
                //sum value group by month
                if (displayType.equals(VIEW_TYPE_MONTH)) {
                    String monthKey = dateToStringWithFormat(pm.Date__c, 'dd/MM/yyyy');
                    if(!mDtoPos.containsKey(monthKey)) {
                        positionKey++;
                        mDtoDatas.put(positionKey, new PMDto());
                        mDtoPos.put(monthKey, positionKey);
                    }
                    PMDto dto = mDtoDatas.get(positionKey);
                    //get value from Performant_Metrice__c to put in dto
                    Decimal pmVal = (Decimal) pm.get(pmField) == null ? 0 : (Decimal) pm.get(pmField);
                    //put value from Performant_Metrice__c into dto
                    dto.put(field, pmVal);
                    //set date
                    dto.put('Date', monthKey);
                    mDtoDatas.put(positionKey, dto);
                } 
                //sum value group by quarter
                else if (displayType.equals(VIEW_TYPE_QUARTER)) {
                    Integer currentQuarter = ((pm.Date__c.month()-1)/3) + 1; 
                    String quartKey = 'Q' + currentQuarter + ' ' + dateToStringWithFormat(pm.Date__c, 'yyyy');
                    if(!mDtoPos.containsKey(quartKey)) {
                        positionKey++;
                        mDtoDatas.put(positionKey, new PMDto());
                        mDtoPos.put(quartKey, positionKey);
                    }
                    PMDto dto = mDtoDatas.get(positionKey);
                    Decimal dtoVal = dto.get(field) == null ? 0 : dto.get(field);
                    Decimal pmVal = (Decimal) pm.get(pmField) == null ? 0 : (Decimal) pm.get(pmField);
                    dto.put(field, dtoVal+pmVal);
                    dto.put(VIEW_TYPE_QUARTER, quartKey);
                    mDtoDatas.put(positionKey, dto);
                }
                //sum value group by year
                else {
                    String yearKey = dateToStringWithFormat(pm.Date__c, 'yyyy');
                    if(!mDtoPos.containsKey(yearKey)) {
                        positionKey++;
                        mDtoDatas.put(positionKey, new PMDto());
                        mDtoPos.put(yearKey, positionKey);
                    }
                    PMDto dto = mDtoDatas.get(positionKey);
                    Decimal dtoVal = dto.get(field) == null ? 0 : dto.get(field);
                    Decimal pmVal = (Decimal) pm.get(pmField) == null ? 0 : (Decimal) pm.get(pmField);
                    dto.put(field, dtoVal+pmVal);
                    dto.put(VIEW_TYPE_YEAR, yearKey);
                    mDtoDatas.put(positionKey, dto);
                }
            }
        }
        
        return mDtoDatas;
    }
    
    public void getPerfMetrice2Display() {
        //get PM from data base
        List<Performance_Metrics__c> perMerts = getPerMetriceRecords();
        listPMDto = createDTOPMData(perMerts);
        defaultPaginationProperties();
        createPagination(listPMDto);
    }
    
    public void loadPMData(){
        List<Performance_Metrics__c> perMerts = getPerMetriceRecords();
        listPMDto = createDTOPMData(perMerts);
        createPagination(listPMDto);
    }
    
    private List<PMDto> createDTOPMData(List<Performance_Metrics__c> perMerts){
        
        //To store the field name
        fieldNames = new List<String>();
        //To store the summary data 
        perMertsSummaryDto = new PMDto();
        //To store the list of dto Performent Metrice to display in data table
        List<PMDto>listPMData = new List<PMDto>();
        //To map dto field name and their values
        Map<String, Decimal> mFieldCalculated = new Map<String, Decimal>();
        //To map month/quarter/year and available records
        Map<Integer, PMDto> mdtos = fetchPMDataByTimeFrame(perMerts);
        
        //To order the records in detail data table by date desc
        for (Integer pos = 1; pos <= mdtos.values().size(); pos++) listPMData.add(mdtos.get(pos));
        
        //To sum each fields of all records in detailtata table 
        for (PMDto dto : listPMData) {
            for (String field : availableFieldsName) {
                if (!mFieldCalculated.containsKey(field)) mFieldCalculated.put(field, 0);
                Decimal totalVal = mFieldCalculated.get(field);
                Decimal dtoVal = dto.get(field) == null ? 0 : dto.get(field);
                totalVal += dtoVal;
                mFieldCalculated.put(field, totalVal);
            }
        }
        
        //get total number of record
        Integer totalRecords = listPMData.size();
        
        //To get the everage of data summary
        for (String field : availableFieldsName) {
            Decimal totalValue = mFieldCalculated.get(field);
            Decimal endValue = totalRecords == 0 ? 0 : totalValue / totalRecords;
            perMertsSummaryDto.put(field, Math.round(endValue));
        }
        
        //set summary header to list to display on the page
        fieldNames.addAll(availableFieldsName);
        
        return listPMData;
    }
    
    private String removeSuffix(String str) {
        String suffix = '__c';
        str = str.replace(suffix, '');
        if (location.equals(LOCATION_LONDON) || location.equals(LOCATION_ROUK)) str = str.replace('_'+location, '');
        return str;
    }
    
    private String addSuffix(String str) {
        if(str == 'Date') return 'Date__c';
        
        String suffix = '__c';
        if ((location.equals(LOCATION_LONDON) || location.equals(LOCATION_ROUK))) str += '_' + location;
        str += suffix;
        return str;
    }
    
    public Pagereference refreshTable() {
        getPerfMetrice2Display();
        return null;
    }
    
    public void sortPerMetriceDatatable() {
        if(currentSoredField.equals(sortFieldName)){ 
            //Sort on same column
            isSortByASC = !isSortByASC; 
        }else{
            //Sort another column
            currentSoredField = sortFieldName;
            isSortByASC = true;
        }
        loadPMData();
    }
    
    /**
     *  Ads BreakDown tab pagination
     */
    public Integer listSize { get; set; }
    public List<SelectOption> listSizeOptions { get; set; }
    public Integer curPage { get; set; }
    public Map<Integer, List<PMDto>> mPaging { get; set; }
    private Integer totalResultSize = 0;
    public Integer totalRecords { get; set; }
    public List<Integer> pageNumList { get; set;}
    
    private void createPagination(List<PMDto>lstAllPMDatas){
        
        totalRecords = lstAllPMDatas.size();
        
        //Pagination
        pageNumList = new List<Integer>();
        mPaging = new Map<Integer, List<PMDto>>();
        
        Integer p = 1;
        totalResultSize = lstAllPMDatas.size();
        for(PMDto dto : lstAllPMDatas){
            if(!mPaging.containsKey(p)){
                mPaging.put(p, new List<PMDto>());
                pageNumList.add(p);
            }
            if(mPaging.get(p).size() == listSize){
                p++;
                mPaging.put(p, new List<PMDto>());
                pageNumList.add(p);
            }
            mPaging.get(p).add(dto);
        }
        
        curPage = 1;
        //check if no invoices
        if(mPaging.get(curPage) == null){
            mPaging.put(curPage, new List<PMDto>());
        }
        
        listPMDto = mPaging.get(curPage);
    }
    
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
        listPMDto = mPaging.get(curPage);
        return null;
    }
    
    public PageReference goNextPage() {
        if(totalResultSize > curPage * listSize) {
            curPage++;
            listPMDto = mPaging.get(curPage);
        }
        return null;
    }    
    
    public PageReference goPreviousPage() {   
        if(curPage > 1){
            curPage--;
            listPMDto = mPaging.get(curPage);
        }
        return null;
    }
     
    public boolean getPrevRequired() {
        return curPage > 1; 
    }
    
    public boolean getNextRequired() {
        return curPage * listSize < totalResultSize;
    }
    
    public class PMDto {
        public Map<String, Decimal> PerformanceMartice{get;set;}
        public Map<String, String> PerformanceMarticeStr{get;set;}
        public Decimal Live_ads {get {return get(FIELD_LIVE_ADS);} set;}
        public Decimal Ads_posted {get{return get(FIELD_ADS_POSTED);}set;}
        public Decimal New_ads_posted {get{return get(FIELD_NEW_ADS_POSTED);}set;}
        public Decimal Reposted_Ads {get{return get(FIELD_REPOSTED_ADS);}set;}
        public Decimal Email_replies {get{return get(FIELD_EMAIL_PEPLIES);}set;}
        public Decimal Email_replies_per_ad {get{return get(FIELD_EMAIL_REPLIES_PER_AD);}set;}
        public String pmDate {get{return getStr('Date');}set;}
        public String pmQuarter {get{return getStr(VIEW_TYPE_QUARTER);}set;}
        public String pmYear {get{return getStr(VIEW_TYPE_YEAR);}set;}
        
        public PMDto(){
            PerformanceMartice = new Map<String, Decimal>();
            PerformanceMarticeStr = new Map<String, String>();
        }
        
        public void put(String fieldName, Decimal value) {
            PerformanceMartice.put(fieldName, value);
        }
        
        public Decimal get(String fieldName) {
            return PerformanceMartice.get(fieldName) == null ? 0 : PerformanceMartice.get(fieldName);
        }
        
        public void put(String fieldName, String value) {
            PerformanceMarticeStr.put(fieldName, value);
        }
        
        public String getStr(String fieldName) {
            return PerformanceMarticeStr.get(fieldName) == null ? '' : PerformanceMarticeStr.get(fieldName);
        }
    }
    
    // get user agent for Google Analytics tracking
    public String getUA() {
        return ApexPages.currentPage().getHeaders().get('User-Agent');
    } 
}