/**

2014-11-19 - GTCRM-1295 - PRO - M5 - 'My Support' module

Change log;


**/

global class P2P_MySupportController {
    
    public String currentAccountId { get; set; }
    /**
     * Constructor
     */
    public P2P_MySupportController(){
        currentAccountId = P2P_Utils.retrieveCommunityAccountId();
        
        //FAQ methods
        try{
            isArticleDetail = false;
            init() ;
        } catch (Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage());
            ApexPages.addMessage(myMsg);
        }  
        
        //Contact methods
        initCaseSelectOptions();
        initCaseSearchFilters();
        defaultPaginationPropertiesCase();
        loadCaseList();
        
        //Idea method
        initIdea();
    }
    
    public String getSitePrefix(){
        return Site.getPathPrefix() == null ? '' : Site.getPathPrefix();
    }
    
    /*========== FAQ SECTION =========*/
    private static final String PAGE_MY_SUPPORT         = 'P2P_MySupport';
    private static final String CATEGORY_GROUP_NAME     = 'Public_KB';
    private static final String CATEGORY_NAME           = 'FAQs';
    private static final String ARTICLE_PARAM           = 'article';
    private static final String CATEGORY_PARAMETER_NAME = 'cate';
    private static final String KAV_LANGUAGE            = 'en_US';
    public static final String CURRENT_TAB              = 'faq';
    public static final String CURRENT_TAB_PARAMETER    = 'tab';
    public static String PUBLISH_STATUS                 = 'Online';
    
    //get/set variable
    public List<String> cateTabs        {get; set;}     //Store the menu level 1
    public Map<String, String> mTabs    {get; set;}     //map name and label of category level 1
    
    public Sobject articleSelected {get; set;}
    public Boolean isArticleDetail  {get; set;} { isArticleDetail = false; }
    public Boolean isSearch         {get; set;} { isSearch = false; }
    
    public String currentCategory { get; set; } { currentCategory = 'General';}
    public String currentTab {get; set;}
    
    /**
     * init
     */
    public void init() {
        cateTabs = new List<String>();
        mTabs = new Map<String, String>();
        getCategories();
        getArticleByCate();
        displayContentArticle();
    }
    
    /**
     * get all the FAQ's categories
     */
    public void getCategories() {
        List<DescribeDataCategoryGroupResult> describeCategoryResult;
        List<DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult;
        
        //get the list of category groups associated
        List<String> objType = new List<String>();
        objType.add('KnowledgeArticleVersion');
        describeCategoryResult = Schema.describeDataCategoryGroups(objType);
     
        //Creating a list of pair objects to use as a parameter for the describe call
        List<DataCategoryGroupSobjectTypePair> pairs = new List<DataCategoryGroupSobjectTypePair>();
     
        //Looping throught the first describe result to create the list of pairs for the second describe call
        for(DescribeDataCategoryGroupResult singleResult : describeCategoryResult){
            DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
            p.setSobject(singleResult.getSobject());
            p.setDataCategoryGroupName(CATEGORY_GROUP_NAME);
            pairs.add(p);
        }
     
        describeCategoryStructureResult = Schema.describeDataCategoryGroupStructures(pairs, false);
        
        //Getting data from the result
        for(DescribeDataCategoryGroupStructureResult singleResult : describeCategoryStructureResult) {
            //Retrieve all the first level of categories, it should be 'All'
            for(DataCategory topLevel : singleResult.getTopCategories()) {
                //Get the list second level of eache categories
                for (DataCategory menu : topLevel.getChildCategories()) {
                    if(menu.getName()!=CATEGORY_NAME) continue;
                    
                    //get the third level of data category
                    for (DataCategory subMenuItem : menu.getChildCategories()) {
                        cateTabs.add(subMenuItem.getName());
                        mTabs.put(subMenuItem.getName(), subMenuItem.getLabel());
                    }
                }
            }
         }
    }
    
    private void resetVariable(){
        isArticleDetail = false;
        isSearch = false;
    }
    
    /**
     * Method get all articles by category
     */
    public List<FAQ__kav> lstArticlesByCate {get; set;} //lst store all article by category
    public void getArticleByCate(){
        resetVariable();
        
        if(currentCategory == null || currentCategory == '' || isSearch || isArticleDetail) {
            lstArticlesByCate = new List<FAQ__kav>();
            return;
        }
        
        Set<ID> knowArtIds = new Set<ID>();
        for(FAQ__DataCategorySelection dataCate : [Select Parent.KnowledgeArticleId, DataCategoryName, Id From FAQ__DataCategorySelection ]){
            //Datacategory cant  be filtered in query
            if(dataCate.DataCategoryName !=currentCategory) continue;
            
            knowArtIds.add(dataCate.Parent.KnowledgeArticleId);
        }
        
        if(knowArtIds.isEmpty()){
            lstArticlesByCate = new List<FAQ__kav>();
        }else{
            lstArticlesByCate = Database.query('Select Title, Id, Description__c, UrlName, Summary, SourceId, PublishStatus, ArticleType, KnowledgeArticleId From FAQ__kav Where KnowledgeArticleId in: knowArtIds AND PublishStatus = \''+ PUBLISH_STATUS +'\'');
        }
    }
    
    public void goBack(){
        getArticleByCate();
    }
    
    /**
     * Method to get content article
     */
    public String knowledgeId   {get; set;}
    private static List<String>artTypes = new List<String>{'FAQ__kav', 'General_Information__kav'};
    public void displayContentArticle(){
        resetVariable();
        knowledgeId = knowledgeId == null ? ApexPages.currentPage().getParameters().get(ARTICLE_PARAM): knowledgeId;
        
        if(knowledgeId == null) return;
        
        List<Sobject>lstResults = new List<Sobject>();
        String qryWhere = knowledgeId.startsWith('kA1') ? 'KnowledgeArticleId=:knowledgeId' : 'UrlName =:knowledgeId';
        qryWhere += ' AND PublishStatus = \'' + PUBLISH_STATUS + '\' AND Language=\''+ KAV_LANGUAGE + '\' limit 1';
        
        for(String artType : artTypes){
            String sql = 'Select Title, Id, Description__c From ' + artType + ' where ' + qryWhere;
            lstResults.addAll(Database.query(sql));
        }
        
        articleSelected = lstResults.isEmpty() ? new FAQ__kav() : lstResults.get(0);
        isArticleDetail = true;
    }
    public String searchTxt     {get; set;}                     //search keyword
    public final static Integer MAX_RECORD = 12;
    public List<DTO_Knowledge> lstDisplayKnowLegde {get;set;}
    public Boolean hasNext {get;set;}
    public Boolean hasRecord {get;set;}
    public Integer currentIndexPage {get;set;}
    public List<Integer> lstOfPage {get;set;}
    
    private List<KnowledgeArticleVersion> lstKnowLegdeArtVer = new List<KnowledgeArticleVersion>();
    private Decimal numberOfPage = 0;
    
    /**
     * Search the article
     * @param : desSearchString, keyword for searching
     * @return : list of DTO_Knowledge
     */
    //for unit test only
    public Set<Id>sKAIds;
    public PageReference doSearchArticles() {
        isSearch = true;
        
        if(searchTxt.length() < 2){
             lstKnowLegdeArtVer = new List<KnowledgeArticleVersion>();
        }else{
            String qryWhere = 'publishStatus=\''+PUBLISH_STATUS+'\' AND Language = \''+ KAV_LANGUAGE + '\'';
            String query = 'find \'*' + searchTxt + '*\' IN ALL FIELDS RETURNING KnowledgeArticleVersion' +  
                            '(Id, UrlName, ArticleType, Title, Summary, SourceId, PublishStatus, KnowledgeArticleId where ' + qryWhere + ')';
            
            
            List<List<Sobject>> lstFinds = Search.query(query);
            lstKnowLegdeArtVer = lstFinds[0];
        }
            
        hasRecord = !lstKnowLegdeArtVer.isEmpty();
        hasNext = (hasRecord && lstKnowLegdeArtVer.size() > MAX_RECORD);
        
        lstDisplayKnowLegde = new List<DTO_Knowledge>();
        currentIndexPage = 1;
        
        numberOfPage = (lstKnowLegdeArtVer == null || lstKnowLegdeArtVer.isEmpty() ? 0: lstKnowLegdeArtVer.size() / MAX_RECORD);
        numberOfPage = numberOfPage.setScale(0, System.Roundingmode.UP);
        lstOfPage = new List<Integer>();
        for(Integer i=1; i<=numberOfPage; i++){
            lstOfPage.add(i);
        }
        if(hasRecord) goToPageFaq();
        
        return null;
    }
    
    /**
     * @description: goto next page
     */
    public PageReference goNextPageFaq() {
        currentIndexPage++;
        if(currentIndexPage >= numberOfPage){
          currentIndexPage = Integer.valueOf(numberOfPage);
        }
        goToPageFaq();
        return null;
    }
    
    /**
     * @description: goto previous page
     */
    public PageReference goPreviousPageFaq() {
        currentIndexPage--;
        if(currentIndexPage <= 1){
          currentIndexPage = 1;
        }
        goToPageFaq();
        return null;
    }
    
    private Integer getStartIndexRec(Integer pageNumber){
        return (pageNumber * MAX_RECORD) - MAX_RECORD;
    }
    
    public PageReference goToPageFaq(){
        lstDisplayKnowLegde.clear();
        Integer startIndex = getStartIndexRec(currentIndexPage);
        
        for(Integer i=startIndex; i<(startIndex + MAX_RECORD); i++){
            if(i < lstKnowLegdeArtVer.size()){
                lstDisplayKnowLegde.add(new DTO_Knowledge(lstKnowLegdeArtVer.get(i).KnowledgeArticleId , lstKnowLegdeArtVer.get(i))); 
            }
        }
        hasNext = currentIndexPage < numberOfPage;
        return null;
    }
    
    class DTO_Knowledge{
        public String knowlegdeArticalId {get;set;}
        public KnowledgeArticleVersion knowlegdeArtical {get;set;}
        public String urlKnowledge {get;set;}
        
        public DTO_Knowledge(String knowlegdeArticalId, KnowledgeArticleVersion knowlegdeArtical){
            this.knowlegdeArtical = knowlegdeArtical;
            this.knowlegdeArticalId = knowlegdeArticalId.substring(0,15);
            String articalType = knowlegdeArtical.ArticleType.replace('__kav', '');
            this.urlKnowledge = '/articles/' + articalType + '/' + knowlegdeArtical.UrlName + '?at=' + knowlegdeArtical.Title;
        }
    }
    /*============= END FAQ ============*/
    
    
    /*============ Contact SECTION===============*/
    //create file upload attachment
    @RemoteAction
    global static String createAttachment(String attName, String base64Body, String parentId, String fileType) {
        String base64info = 'base64,';
        if(base64Body.contains(base64info)) base64Body = base64Body.substring(base64Body.indexOf(base64info)).replace(base64info, '');
        Attachment att = new Attachment(
            Name = attName,
            ParentId = parentId, 
            Body = Encodingutil.base64Decode(base64Body),
            ContentType = fileType
        );
        insert att;
        return att.Id;
    }
    
    //create file upload attachment
    @RemoteAction
    global static String createChunkAttachment(String attId, String attName, String base64Body, String parentId, String fileType) {
        if(!String.isEmpty(attId)){
            Attachment att = [Select Body From Attachment Where Id =: attId];
            att.Body = Encodingutil.base64Decode(Encodingutil.base64Encode(att.Body) + base64Body);
            update att;
        }else{
            attId = createAttachment(attName, base64Body, parentId, fileType);
        }
        return attId;
    }
    
    // getting Record Type Id
    private Id getRecordTypeId(String sObjType, String rTypeName){
        return Schema.getGlobalDescribe().get(sObjType).getDescribe().getRecordTypeInfosByName().get(rTypeName).getRecordTypeId();
    }
    
    // getting primary Contact Id
    private Id getPrimaryContact(String accId){
        if(accId == null) return null;
        return [Select Primary_contact__c From Account Where Id =: accId].Primary_contact__c;
    }
    
    // getting IP of user visiting the page
    public String getIp() {
        return ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
    } 

    // get Device tracking on online help form  
    public String getUA() {
        return ApexPages.currentPage().getHeaders().get('User-Agent');
    } 
    
    // base on user agent to get device os. 
    public String getOS(){
        String userAgent = getUA();
        // some devices use custom headers for the user-agent.
        if (String.isEmpty(userAgent)) userAgent = ApexPages.currentPage().getHeaders().get('HTTP_X_OPERAMINI_PHONE_UA');
        if (String.isEmpty(userAgent)) userAgent = ApexPages.currentPage().getHeaders().get('HTTP_X_SKYFIRE_PHONE');
        // using (?i) case insensitive mode.     
        String deviceReg = '(?i)(iphone|ipod|ipad|blackberry|android|nokia|palm\\s+ce)';
        String desktopReg = '(?i)(windows|linux|macintosh|os\\s+[x9]|solaris|bsd)';
        Matcher m = Pattern.compile(deviceReg).matcher(userAgent);
        if (m.find()){
            return m.group();   
        }else{
            // don't compile the patterns unless required.
            m = Pattern.compile(desktopReg).matcher(userAgent);
            if (m.find()) return 'Desktop';
        }
        return 'Unknown OS';
    }
    
    // Dynamic query with Like Operator 
    private String createLikeCrit(String field, String value){
        return field + ' Like \'%' + value.trim() + '%\'';
    }
    
    /**
     * CreateCase 
     */
    public List<SelectOption> lcaseTypeOptions { get; set; }
    public List<SelectOption> lcaseTopicOptions { get; set; }
    public List<SelectOption> lcaseAnswersOptions { get; set; }
    public String selType { get; set; }
    public String caseTopic { get; set; }
    public String selAnswer { get; set; }
    public Case newCase { get; set; }
    public Boolean inputNewCaseDetails { get; set; } 
    
    private void initCaseSelectOptions(){
        
        lcaseTypeOptions = new List<SelectOption>();
        lcaseTypeOptions.add(new SelectOption('Customer Services', 'Customer Support'));
        lcaseTypeOptions.add(new SelectOption('2 - Finance Support', 'Finance Support'));
        
        /*lcaseTopicOptions = new List<SelectOption>();
        lcaseTopicOptions.add(new SelectOption('', 'None'));
        lcaseTopicOptions.add(new SelectOption('Question about my free ad', 'Question about my Free Ad'));
        lcaseTopicOptions.add(new SelectOption('Question about my paid ad', 'Question about my Paid Ad'));
        lcaseTopicOptions.add(new SelectOption('Report Fraud/Scam/Abuse', 'Report Fraud/Scam/Abuse'));
        lcaseTopicOptions.add(new SelectOption('Question about Replying to Ads', 'Question about Replying to Ads'));
        lcaseTopicOptions.add(new SelectOption('General Feedback', 'General Feedback'));*/
        
        lcaseAnswersOptions = new List<SelectOption>();
        lcaseAnswersOptions.add(new SelectOption('','None'));
        lcaseAnswersOptions.add(new SelectOption('no','No'));
        lcaseAnswersOptions.add(new SelectOption('yes','Yes'));
        lcaseAnswersOptions.add(new SelectOption('unsure','Unsure'));
        
        caseStatusOptions = new List<SelectOption>();
        caseStatusOptions.add(new SelectOption('','All'));
        //caseStatusOptions.addAll(P2P_Utils.getPicklist('Case','Status'));
        caseStatusOptions.add(new SelectOption('Open', 'Open'));
        caseStatusOptions.add(new SelectOption(getNewCaseStatus(), 'New'));
        caseStatusOptions.add(new SelectOption(getWorkingCaseStatus(), 'Working'));
        caseStatusOptions.add(new SelectOption(getAwaitingFeedbackCaseStatus(), 'Awaiting Feedback'));
        caseStatusOptions.add(new SelectOption(getSolvedCaseStatus(), 'Closed'));
    }
    
    private Map<String, String> caseTypeMapping = new Map<String, String>{
        'Customer_Services' => 'Customer',
        'Finance_Support' => 'Finance'
    };
    
    public PageReference cancelCreateNewCase(){
        inputNewCaseDetails = false;
        return null;
    }
    
    /**
     *  Action of Case type picklist 
     *  Assign RecordTypeId to NewCase and rerender topic picklist
     */
    public PageReference caseTypeChange(){
        newCase.Web2Case_Reason__c = '';
        newCase.RecordTypeId = getRecordTypeId('Case', selType);
        return null;
    }
    
    public PageReference createNewCase(){
        selAnswer = '';
        inputNewCaseDetails = true;
        caseTopic = newCase.Web2Case_Reason__c;
        
        newCase = new Case();
        
        newCase.AccountId = currentAccountId;
        newCase.OwnerId = '00520000001Cywv';
        newCase.RecordTypeId = getRecordTypeId('Case', selType);
        newCase.Status = 'New';
        newCase.Type = caseTypeMapping.get(selType);
        newCase.Reason = caseTypeMapping.get(selType);
        newCase.Origin = 'Web (PRO)';
        newCase.ContactId = getPrimaryContact(newCase.AccountId);
        newCase.Web2Case_Reason__c = caseTopic;
        if(newCase.Subject == null) newCase.Subject = newCase.Web2Case_SubReason__c;
        newCase.IP_Address__c = getIp();
        newCase.User_Agent__c = getUA();
        newCase.User_Source__c= getOS();
        return null;
    }
    
    public PageReference submitCase(){
        newCase.Browser_Details__c = newCase.PC_Details__c;
        if(selType == 'Customer Services') followCaseWorkflow();
        insert newCase;
        return null;
    }
    
    /**
     *  Task #4434 : comment #48 attch doc 2015-01-18 - Support - Contact web to case missing requirements.txt
     */
    private void followCaseWorkflow(){
        String categoryTopic = newCase.Web2Case_Reason__c;
        String categorySubject = newCase.Web2Case_SubReason__c;
        String recordTypeId = newCase.RecordTypeId;
        
        if(categoryTopic=='Question about my Free Ad' && categorySubject=='General Enquiry'){
        recordTypeId='01220000000Q9DR';
        newCase.Type='Free CS';
        }
        else if(categoryTopic=='Question about my Free Ad' && categorySubject=='Technical Issue'){
          recordTypeId='01220000000Q9DR';
          newCase.Type='Free Sellers';  
          newcase.Reason='Technical Issue';
        }
        else if(categoryTopic=='Question about my Paid Ad' && categorySubject=='Featured Ad'){
          recordTypeId='01220000000Q9DR';
          newCase.Type='Paid Feature';
        }
        else if(categoryTopic=='Question about my Paid Ad' && categorySubject=='Job Ad'){
          recordTypeId='01220000000Q9DR';
          newCase.Type='Paid Jobs';
        }
        else if(categoryTopic=='Question about my Paid Ad' && categorySubject=='Housing Ad'){
          recordTypeId='01220000000Q9DR';
          newCase.Type='Paid Housing';
        }
        else if(categoryTopic=='Question about my Paid Ad' && categorySubject=='Business Services Ad'){
          recordTypeId='01220000000Q9DR';
          newCase.Type='Paid Services';
        }
        else if(categoryTopic=='Question about my Paid Ad' && categorySubject=='Motors Ad'){
          recordTypeId='01220000000Q9DR';
          newCase.Type='Paid Motors';
        }
        else if(categoryTopic=='Report Fraud/Scam/Abuse' && categorySubject=='Ad'){
          recordTypeId='01220000000Dn8v';
          newCase.Type='Safety Fraud';    
        }
        else if(categoryTopic=='Report Fraud/Scam/Abuse' && categorySubject=='Reply'){
          recordTypeId='01220000000Dn8v';
          newCase.Type='Safety Fraud';
        }
        else if(categoryTopic=='Report Fraud/Scam/Abuse' && categorySubject=='Other'){
          recordTypeId='01220000000Dn8v';
          newCase.Type='Safety Fraud';
        }
        else if(categoryTopic=='Question about Replying to Ads'){
          recordTypeId='01220000000Q9DR';
          newCase.Type='Free Buyers';
        }
        else if(categoryTopic=='General Feedback'){
          recordTypeId='01220000000Q9DR';
          newCase.Type='Free Sellers';
        }
        newCase.RecordTypeId=recordTypeId;
    }
    
    public PageReference submitListChanged(){
        initCaseSearchFilters();
        loadCaseList();
        return null;
    }
    
    /**
     * List Cases
     */
    public String getNewCaseStatus(){
        return 'New';
    }
    public String getWorkingCaseStatus(){
        return 'Working';
    }
    public String getAwaitingFeedbackCaseStatus(){
        return 'Response Sent';
    }
    public String getSolvedCaseStatus(){
        return 'Survey Send';
    }
    public final static String NEW_WORKING_STATUS = 'Open';
    public List<DTOCase> lcase { get; set; }
    public String searchCase { get; set; }
    public String filterType { get; set; }
    public String filterStatus { get; set; }
    public List<SelectOption> caseStatusOptions { get; set; }
    public List<SelectOption> lcaseTypeFilterOptions { get; set; }
    
    /**
     * Button Search Case
     */
    public PageReference searchKeyWordCase(){
        if(!String.isEmpty(searchCase)){
            filterType = '';
            filterStatus = '';
        }
        loadCaseList();
        return null;
    }
    
    /**
     *  Class manage index of list company contact
     */
    class DTOCase{
        public Integer index{get;set;}
        public Case caseinfo{get;set;}
        public Boolean isEdited{get;set;}
        public DTOCase(Integer ind, Case cs){
            this.index = ind;
            this.caseinfo = cs;
            this.isEdited = false;
        }
    }
    
    private void initCaseSearchFilters(){
        lcaseTypeFilterOptions = new List<SelectOption>();
        lcaseTypeFilterOptions.add(new SelectOption('', 'All'));
        lcaseTypeFilterOptions.add(new SelectOption('Customer Services', 'Customer Support'));
        lcaseTypeFilterOptions.add(new SelectOption('Finance Support', 'Finance Support'));
        
        newCase = new Case(RecordTypeId = getRecordTypeId('Case', 'Customer Services'));
        
        inputNewCaseDetails = false;
        selType = lcaseTypeOptions[0].getValue();
        caseTopic = '';
        selAnswer = lcaseAnswersOptions[0].getValue();
        searchCase = '';
        filterType = lcaseTypeFilterOptions[0].getValue();
        filterStatus = NEW_WORKING_STATUS;
        sortByFieldCase = 'CreatedDate';
    }
    
    public PageReference loadCaseList(){
        currentSoredFieldCase = sortByFieldCase;
        isDESCCase = true;
        queryWithSortedList(currentSoredFieldCase, isDESCCase);
        detailCaseMode = false;
        return null;
    }
    
    private List<Case> searchSortedCaseList(String colName, Boolean byDESC){
        String accountCrit = '';
        if(!String.isEmpty(currentAccountId)){
            accountCrit += 'AccountId =: currentAccountId';
        }
        
        String searchCaseCirt = '';
        if(!String.isEmpty(searchCase)){
            searchCaseCirt += '(' + createLikeCrit('CaseNumber ', searchCase); 
            searchCaseCirt += ' OR ' + createLikeCrit('Subject ', searchCase) + ')';
            //searchCaseCirt += ' OR ' + createLikeCrit('Description ', searchCase) + ')';
        }
        
        String typeCrit = '';
        if(!String.isEmpty(filterType)){
            if(filterType == 'Customer Services') typeCrit += '(Recordtype.DeveloperName = \'Customer_Services\' OR Recordtype.DeveloperName = \'Safety_Support\')';
            if(filterType == 'Finance Support') typeCrit += 'Recordtype.DeveloperName = \'Finance_Support\'';
        }else{
            typeCrit += '(Recordtype.DeveloperName = \'Customer_Services\' OR Recordtype.DeveloperName = \'Safety_Support\' OR Recordtype.DeveloperName = \'Finance_Support\')';
        }
        
        String statusCrit = '';
        if(!String.isEmpty(filterStatus)){
            if(filterStatus == NEW_WORKING_STATUS) statusCrit += '(Status = \'New\' OR Status = \'Working\')'; 
            else statusCrit += 'Status = \'' + filterStatus + '\'';
        }
        String allCrits = (searchCaseCirt != '' ? ' And ' + searchCaseCirt : '') + (typeCrit != '' ? ' And ' + typeCrit : '') + (statusCrit != '' ? ' And ' + statusCrit : '') + (accountCrit != '' ? ' And ' + accountCrit : '');
        
        P2P_RequestAdImage__c rdi  = P2P_RequestAdImage__c.getValues('MySupportCaseStartDate');
        Date startDate = null;
        if(rdi != null){
            if(rdi.get('Case_Start_Date__c')!=null)
            startDate = Date.valueOf(rdi.get('Case_Start_Date__c'));
        }
        String createdDateCrit = ((startDate==null)?'':' AND CreatedDate >=:startDate ');
        allCrits += createdDateCrit;
        
        
        String whereClause = 'Where ' + (allCrits != '' ? allCrits.replaceFirst(' And ', ''): ''); 
        
        
        
        String queryStr = 'Select Id From Case ' + (whereClause != 'Where ' ? whereClause : '') + ' order by '+ colName + (byDESC ? ' desc' : ' asc');
        
        //query = queryStr;
        //return new List<Case>();
        return Database.query(queryStr);
    }
    
    public String query {get;set;}
    
    // Search Case fields to use
    private String getCaseFieldQueryWithDetails(Boolean isDetailed){
        String brief = 'Id, CreatedDate, CaseNumber, Subject, Priority, RecordType.Name, RecordType.DeveloperName, Origin, Status';
        String details = brief + ',ContactId, Contact.Profile_Photo__c, Owner.Name, OwnerId, Contact.OwnerId, Contact.Owner.Name, Contact.Phone, Contact.Email, Contact.Fax, Contact.Name, Description ';
        return isDetailed ? details : brief;
    }
    
    /**
     *  Case Records Sorted
     */
    public String sortByFieldCase { get; set; }
    public Boolean isDESCCase { get; set; }
    private String currentSoredFieldCase; 
    
    public PageReference sortCase(){
        if(currentSoredFieldCase == sortByFieldCase){ 
            //Sort on same column
            isDESCCase = !isDESCCase; 
        }else{
            //Sort another column
            currentSoredFieldCase = sortByFieldCase;
            isDESCCase = true;
        }
        queryWithSortedList(currentSoredFieldCase, isDESCCase);
        return null;
    }
    
    private void queryWithSortedList(String colName, Boolean byDESC){
        List<Case> lstCase = searchSortedCaseList(colName, byDESC);
        totalResultSizeCase = lstCase.size();
        pageNumListCase = new List<Integer>();
        mPagingCase = new Map<Integer, List<Id>>();
        
        Integer p = 1;
        for(Case cs : lstCase){
            if(!mPagingCase.containsKey(p)){
                mPagingCase.put(p, new List<Id>());
                pageNumListCase.add(p);
            }
            if(mPagingCase.get(p).size() == listSizeCase){
                p++;
                mPagingCase.put(p, new List<Id>());
                pageNumListCase.add(p);
            }
            mPagingCase.get(p).add(cs.Id);
        }
        
        curPageCase = 1;
        if(mPagingCase.get(curPageCase) == null){
            mPagingCase.put(curPageCase, new List<Id>());
        }
        
        List<Id> pageList = mPagingCase.get(curPageCase);
        createResultRowsListCase(pageList);
    }
    
    private void createResultRowsListCase(List<Id> listIds){
        lcase = new List<DTOCase>();
        String queryWhere = 'Where Id IN: listIds order by ' + currentSoredFieldCase + (isDESCCase ? ' desc' : ' asc');
        List<Case> lstCase = DataBase.query('Select ' + getCaseFieldQueryWithDetails(false) + ' From Case ' + queryWhere);
        
        Integer index = 0;
        for(Case cs : lstCase){
            lcase.add(new DTOCase(index, cs));
            index++;                        
        }
    }
    
    /**
     *  Case Paging
     */
    public Integer listSizeCase{get;set;}
    public List<SelectOption> listSizeOptionsCase { get; set; }
    public Integer curPageCase { get; set; }
    public Map<Integer, List<Id>> mPagingCase { get; set; }
    private Integer totalResultSizeCase = 0;
    public List<Integer> pageNumListCase { get; set;}
    
    private void defaultPaginationPropertiesCase(){
        listSizeCase = 10;
        listSizeOptionsCase = new List<SelectOption>();
        listSizeOptionsCase.add(new SelectOption('10', '10 per page'));
        listSizeOptionsCase.add(new SelectOption('20', '20 per page'));
        listSizeOptionsCase.add(new SelectOption('50', '50 per page'));
    }
    
    public Integer getStartIndexCase() {
        return curPageCase == 0 || curPageCase == 1? curPageCase : ((curPageCase - 1) * listSizeCase) + 1;
    }
    
    public Integer getEndIndexCase() {
        Integer endInd = getStartIndexCase() + listSizeCase - 1;
        return endInd > totalResultSizeCase ? totalResultSizeCase : endInd;
    }
     
    public Integer gettotalResultSizeCase(){
        return totalResultSizeCase;
    }
    
    public Integer getTotalPageSizeCase(){
        return mPagingCase.size();
    }
    
    public PageReference goToPageCase(){
        createResultRowsListCase(mPagingCase.get(curPageCase));
        return null;
    }
    
    public PageReference goNextPageCase() {
        if(totalResultSizeCase > curPageCase * listSizeCase) {
            curPageCase++;
            createResultRowsListCase(mPagingCase.get(curPageCase));
        }
        return null;
    }    
    
    public PageReference goPreviousPageCase() {   
        if(curPageCase > 1){
            curPageCase--;
            createResultRowsListCase(mPagingCase.get(curPageCase));
        }
        return null;
    }
     
    public PageReference goFirstPageCase() {
        curPageCase = 1;
        createResultRowsListCase(mPagingCase.get(curPageCase));
        return null;
    }    
     
    public PageReference goLastPageCase() {   
        curPageCase = mPagingCase.size();
        createResultRowsListCase(mPagingCase.get(curPageCase));
        return null;
    }

    public boolean getPrevRequiredCase() {
        return curPageCase > 1; 
    }
    
    public boolean getNextRequiredCase() {
        return curPageCase * listSizeCase < totalResultSizeCase;
    }
     
    public boolean getFirstRequiredCase() {
        return curPageCase > 1;
    }
    
    public boolean getLastRequiredCase() {
        return curPageCase < mPagingCase.size();
    }
    
    /**
     * Case detail information
     */
    public String detailCaseId { get; set; }
    public Case detailCase { get; set; }
    public List<CaseComment> lcomment { get; set; }
    public List<Attachment> attachCase { get; set; }
    public CaseComment newComment { get; set; }
    public Boolean detailCaseMode { get; set; }
    public Map<String, User> infoUserCase { get; set; }
    public String markedAsResolvedId { get; set; }
    public Boolean markedAsResolved { get; set; }
    
    public String getCaseContactPhoto(){
        return P2P_Utils.attachmentPhoto(detailCase.ContactId);
    }
    
    public PageReference initCaseDetails(){
        detailCaseMode = true;
        //New CaseComment
        newComment = new CaseComment(ParentId = detailCaseId, CommentBody = null, IsPublished = true);
        
        //Parent case
        String queryWhere = 'Where Id =: detailCaseId';
        List<Case> lstCase = DataBase.query('Select ' + getCaseFieldQueryWithDetails(true) + ' From Case ' + queryWhere);
        detailCase = lstCase[0];
        markedAsResolved = detailCase.Status == getSolvedCaseStatus();
        
        attachCase = [Select Id, Name From Attachment Where ParentId =: detailCaseId];
        //Child comments
        lcomment = [Select Id, CreatedById, CommentBody, CreatedDate From CaseComment Where ParentId=: detailCaseId and IsPublished = true order By CreatedDate desc];
        
        Set<String> userIds = new Set<String>();
        userIds.add(detailCase.OwnerId);
        userIds.add(detailCase.Contact.OwnerId);
        for(CaseComment csCom : lcomment){
            userIds.add(csCom.CreatedById);
        }
        infoUserCase = new Map<String, User>([Select SmallPhotoUrl, FullPhotoUrl, Contact.Name, Name From User Where Id IN: userIds ]);
        if(!infoUserCase.containsKey(detailCase.OwnerId)){
            infoUserCase.put(detailCase.OwnerId, new User());
        }
        return null;
    }
    
    public PageReference backToListCase(){
        detailCaseMode = false;
        return null;
    }
    
    public PageReference submitCaseComment(){
        insert newComment;
        return null;
    }
    public PageReference submitListCaseCommentChanged(){
        initCaseDetails();
        return null;
    }
    
    public PageReference doMarkAsResolved(){
        detailCase.Status = getSolvedCaseStatus();
        update detailCase;
        markedAsResolved = true;
        return null;
    }
    
    /*============ End Contact ===============*/
    
    /*============ Idea Section ==============*/
    
    private static final String IDEA_STATUS_NEW = 'New';
    private static final String ZONE_CUSTOMER_COMMUNITY = 'Customer Community';
    public Idea idea {get;set;}
    public Idea_Attachment_Link__c ideaAttachmentLink {get;set;}
    public list<idea> lstIdea {get;set;}
    public String textSearch {get;set;}
    public List<P2P_DtoIdea> lstDtoIdea {get;set;}
    public P2P_DtoIdea dtoIdea {get;set;}
    public List<SelectOption> lstStatus{get;set;}
    public List<SelectOption> lstCategoies{get;set;}
    public String status {get;set;}
    public String category {get;set;}
    public boolean isPostIdea{get;set;}
    public boolean isShowIdeaDetail{get;set;}
    public integer selectedIndex {get;set;}
    public List<IdeaComment> lstIdeaComment {get;set;}
    public List<Attachment> lstAttachment {get;set;}
    public IdeaComment ideaComment {get;set;}
    
    List<Community> lstCommunity {get;set;}
    
    
    public void initIdea(){
        selectedIndex = 0;
        isPostIdea = false;
        isShowIdeaDetail = false;
        
        lstCommunity = [Select Id From Community where Name = :ZONE_CUSTOMER_COMMUNITY and IsActive = true];
        
        if(!lstCommunity.isEmpty()){
            idea = new Idea(CommunityId = lstCommunity.get(0).Id, Status = IDEA_STATUS_NEW);
        }
        
        lstStatus = new List<SelectOption>();
        lstStatus.add(new SelectOption('All', 'All ideas'));
        lstStatus.addAll(P2P_Utils.getPicklist('Idea', 'Status__c'));
        lstCategoies = new List<SelectOption>();
        lstCategoies.add(new SelectOption('All', 'All Categories'));
        lstCategoies.addAll(P2P_Utils.getPicklist('Idea', 'Category'));
        
        initIdeaSearchFilters();
        //searchIdea();
        listSizeOptionsIdea = new List<SelectOption>();
        defaultPaginationPropertiesIdea();
        loadIdeaList();
        
        /*isShowIdeaDetail = true;
        selectedIndex=0;
        showDetail();
        */
    }
    
    public String getIdeaFieldQuery(){
        return 'Id, Body, Title, Status__c, Status, CreatedDate, Category, VoteTotal, CreatorName, Company_Name__c, CreatedById, VoteScore, CreatorSmallPhotoUrl';
    }
    
    public void initIdeaSearchFilters(){
         status = 'All';
        category = 'All';
        isDESCIdea = true;
        sortByFieldIdea = 'CreatedDate';
    }
    
    public PageReference submitListIdeaChanged(){
        isPostIdea = false;
        initIdeaSearchFilters();
        loadIdeaList();
        return null;
    }
    
    public void searchIdea(){
        List<Idea> lstTemp = new List<Idea>(); 
        if(!lstCommunity.isEmpty()){
            
            String condition = '';
            
            if(status != 'All'){
                condition += ' AND Status__c = :status';
            }
            
            if(category != 'All'){
                condition += ' AND Category =: category';
            }
            
            if(!String.isEmpty(textSearch)){
                String query = 'find \'' + textSearch + '*\' IN ALL FIELDS RETURNING idea (Id, Title, Body where ' 
                        + ' CommunityId =\'' + lstCommunity.get(0).Id + '\'';
                
                if(condition != ''){
                    query += condition;
                }   
                query += ')';
               
                List<Idea> lst = (List<Idea>)((List<List<SObject>>)(search.Query(query))).get(0);
                        
                        //remove recod that does not match with search
                        for(Idea i : lst){
                            if((i.Title != null && i.Title.containsIgnoreCase(textSearch)) || (i.Body != null && i.Body.containsIgnoreCase(textSearch))){
                                lstTemp.add(i);
                            }
                        }
                        
            }else{
                string query = 'Select Id from Idea where CommunityId = \'' + lstCommunity.get(0).Id +'\'' ; 
                if(condition != ''){
                    query += condition;
                }
                lstTemp = Database.Query(query) ;
                
            }
        }
        
        //convertListToListDto(lstIdea);
       lstIdea = Database.Query('select Id from Idea where Id in : lstTemp ORDER By '  + currentSoredFieldIdea + (isDESCIdea ? ' desc' : ' asc'));
        
    }
    
    //put list idea to dto
    public void convertListToListDto(List<Idea> lstIdeaPage){
        
        if(!lstIdea.isEmpty()){
            Map<Id, List<Vote>> mVote = getVotes(new Map<Id, Idea>(lstIdeaPage));
            Map<String, Integer> mCommentCount = getCommentCount(new Map<Id, Idea>(lstIdeaPage));
            Map<Id, List<Attachment>> mAttachment = getAttachmentForIdea(new Map<Id, Idea>(lstIdeaPage));
            
            Integer index = 0;
            for(Idea i:lstIdeaPage){
                boolean voteUp = false;
                boolean voteDown = false;
                List<Vote> lstVote = mVote.get(i.Id);
                
                //a user can vote only one time for an idea => list hase only 1 record
                if(lstVote!=null){
                    if(lstVote.get(0).Type == 'Up'){
                        voteUp = true;
                    }else if(lstVote.get(0).Type == 'Down'){
                        voteDown = true;
                    }
                }
                
                lstDtoIdea.add(new P2P_DtoIdea(i, mCommentCount.get(i.Id), voteUp, voteDown, index));
                index++;
            }
        }
    }
    
    public Map<Id, List<Vote>> getVotes(map<Id, Idea> mIdea){
        Map<Id, List<Vote>> mVote = new Map<Id, List<Vote>>();
        for(Vote v:[SELECT id, ParentId, Type FROM vote WHERE Parent.Type = 'Idea' AND ParentId IN :mIdea.keyset()
                            AND CreatedById = :UserInfo.getUserId()]){
            if(mVote.get(v.ParentId) == null){
                mVote.put(v.ParentId, new List<Vote>()); 
            }
            mVote.get(v.ParentId).add(v);
        }
        return mVote;
    }
    
    private Map<String, Integer> getCommentCount(map<Id, Idea> mIdea){
        Map<String, Integer> mCountComment = new Map<String, Integer>();
        for(AggregateResult ar : [SELECT Count(Id) total, IdeaId FROM IdeaComment WHERE IdeaId IN :mIdea.keyset() Group By IdeaId]){
            mCountComment.put(String.valueOf(ar.get('IdeaId')), Integer.valueOf(ar.get('total')));
        }
        return mCountComment;
    }
    
    public Map<Id, List<Attachment>> getAttachmentForIdea(map<Id, Idea> mIdea){
        Map<Id, List<Attachment>> mAttachment = new Map<Id, List<Attachment>>();
        Map<Id,  Idea_Attachment_Link__c> mIdeaAttachmentLink = new Map<Id,  Idea_Attachment_Link__c>([select Id, Idea__c from Idea_Attachment_Link__c where Idea__c in :mIdea.keySet()]);
        
        for(Attachment att : [select Id, ParentId, Name from Attachment where ParentId in :mIdeaAttachmentLink.keySet()]){
            if(mAttachment.get(mIdeaAttachmentLink.get(att.ParentId).Idea__c) == null){
                mAttachment.put(mIdeaAttachmentLink.get(att.ParentId).Idea__c, new List<Attachment>()); 
            }
            mAttachment.get(mIdeaAttachmentLink.get(att.ParentId).Idea__c).add(att);
        }
        
        return mAttachment;
    }
    
    public void submitIdea(){
        insert idea;
        ideaAttachmentLink = new Idea_Attachment_Link__c(Name = idea.Title, Idea__c = idea.Id);
        insert ideaAttachmentLink;
        isPostIdea=false;
        initIdeaSearchFilters();
        searchIdea();
    }
        
    public pageReference postIdea(){
        if(!lstCommunity.isEmpty()){
            idea = new Idea(CommunityId = lstCommunity.get(0).Id, Status = IDEA_STATUS_NEW);
            isPostIdea = true;
        }
        return null;
    }
    
    public PageReference cancelPostIdea(){
        idea = null;
        isPostIdea = false;
        return null;
    }
    
    //get Idea Detail
    public void showDetail(){
        isShowIdeaDetail = true;
        dtoIdea = lstDtoIdea.get(selectedIndex);
        ideaComment = new IdeaComment();
        lstIdeaComment = [SELECT Id, IdeaId, CommentBody, CreatorName, CreatorSmallPhotoUrl, CreatedDate FROM IdeaComment WHERE IdeaId = :dtoIdea.Idea.Id ORDER BY CreatedDate Desc];
        loadListAttachment();
    }
    
    public void hideDetail(){
        dtoIdea.commentCount = lstIdeaComment.size();
        isShowIdeaDetail = false;
        dtoIdea = null;
        ideaComment = null;
        lstIdeaComment = null;
        lstAttachment = null;
    }
    
    public void createIdeaComment(){
        ideaComment.IdeaId= dtoIdea.idea.Id;
        insert ideaComment;
        List<Idea_Attachment_Link__c> lst= [select Id from Idea_Attachment_Link__c where Idea__c = :dtoIdea.idea.Id];
        if(lst.isEmpty()){
            ideaAttachmentLink = new Idea_Attachment_Link__c(Name = idea.Title, Idea__c = dtoIdea.idea.Id);
        }else{
            ideaAttachmentLink = lst.get(0);
        }
        upsert ideaAttachmentLink;
        
        
    }
    
    public void submitListIdeaCommentChanged(){
        loadListAttachment();
        lstIdeaComment = [SELECT Id, IdeaId, CommentBody, CreatorName, CreatorSmallPhotoUrl, CreatedDate FROM IdeaComment WHERE IdeaId = :dtoIdea.Idea.Id ORDER BY CreatedDate Desc];
        ideaComment = new IdeaComment();
    }
    
    private void loadListAttachment(){
        lstAttachment = [select Id, Name from Attachment where ParentId in (select Id from Idea_Attachment_Link__c where Idea__c = :dtoIdea.Idea.Id)];
    }
    
    /**
     *  Idea Records Sorted
     */
    public String sortByFieldIdea { get; set; }
    public Boolean isDESCIdea { get; set; }
    private String currentSoredFieldIdea; 
    
    public PageReference sortIdea(){
        if(currentSoredFieldIdea == sortByFieldIdea){ 
            //Sort on same column
            isDESCIdea = !isDESCIdea; 
        }else{
            //Sort another column
            currentSoredFieldIdea = sortByFieldIdea;
            isDESCIdea = true;
        }
        queryWithSortedListIdea(currentSoredFieldIdea, isDESCIdea);
        return null;
    }
    
    private void queryWithSortedListIdea(String colName, Boolean byDESC){
        //List<Idea> lstIdea = searchSortedIdeaList(colName, byDESC);
        searchIdea();
        totalResultSizeIdea = lstIdea.size();
        pageNumListIdea = new List<Integer>();
        mPagingIdea = new Map<Integer, List<Id>>();
        
        Integer p = 1;
        for(Idea cs : lstIdea){
            if(!mPagingIdea.containsKey(p)){
                mPagingIdea.put(p, new List<Id>());
                pageNumListIdea.add(p);
            }
            if(mPagingIdea.get(p).size() == listSizeIdea){
                p++;
                mPagingIdea.put(p, new List<Id>());
                pageNumListIdea.add(p);
            }
            mPagingIdea.get(p).add(cs.Id);
        }
        
        curPageIdea = 1;
        if(mPagingIdea.get(curPageIdea) == null){
            mPagingIdea.put(curPageIdea, new List<Id>());
        }
        
        List<Id> pageList = mPagingIdea.get(curPageIdea);
        createResultRowsListIdea(pageList);
    }
    
    private void createResultRowsListIdea(List<Id> listIds){
        lstDtoIdea = new List<P2P_DtoIdea>();
        String queryWhere = 'Where Id IN: listIds order by ' + currentSoredFieldIdea + (isDESCIdea ? ' desc' : ' asc');
        List<Idea> lstIdeaPage  = DataBase.query('Select ' + getIdeaFieldQuery() + ' From Idea ' + queryWhere);
        Integer index = 0;
        convertListToListDto(lstIdeaPage);
        
    }
    
    /**
     *  Idea Paging
     */
    public Integer listSizeIdea{get;set;}
    public List<SelectOption> listSizeOptionsIdea { get; set; }
    public Integer curPageIdea { get; set; }
    public Map<Integer, List<Id>> mPagingIdea { get; set; }
    private Integer totalResultSizeIdea = 0;
    public List<Integer> pageNumListIdea { get; set;}
    
    private void defaultPaginationPropertiesIdea(){
        listSizeIdea = 10;
        listSizeOptionsIdea = new List<SelectOption>();
        listSizeOptionsIdea.add(new SelectOption('10', '10 per page'));
        listSizeOptionsIdea.add(new SelectOption('20', '20 per page'));
        listSizeOptionsIdea.add(new SelectOption('50', '50 per page'));
    }
    
    public PageReference loadIdeaList(){
        currentSoredFieldIdea = sortByFieldIdea;
        isDESCIdea = true;
        queryWithSortedListIdea(currentSoredFieldIdea, isDESCIdea);
        return null;
    }
    
    public Integer getStartIndexIdea() {
        return curPageIdea == 0 || curPageIdea == 1? curPageIdea : ((curPageIdea - 1) * listSizeIdea) + 1;
    }
    
    public Integer getEndIndexIdea() {
        Integer endInd = getStartIndexIdea() + listSizeIdea - 1;
        return endInd > totalResultSizeIdea ? totalResultSizeIdea : endInd;
    }
     
    public Integer gettotalResultSizeIdea(){
        return totalResultSizeIdea;
    }
    
    public Integer getTotalPageSizeIdea(){
        return mPagingIdea.size();
    }
    
    public PageReference goToPageIdea(){
        createResultRowsListIdea(mPagingIdea.get(curPageIdea));
        return null;
    }
    
    public PageReference goNextPageIdea() {
        if(totalResultSizeIdea > curPageIdea * listSizeIdea) {
            curPageIdea++;
            createResultRowsListIdea(mPagingIdea.get(curPageIdea));
        }
        return null;
    }    
    
    public PageReference goPreviousPageIdea() {   
        if(curPageIdea > 1){
            curPageIdea--;
            createResultRowsListIdea(mPagingIdea.get(curPageIdea));
        }
        return null;
    }
     
    public PageReference goFirstPageIdea() {
        curPageIdea = 1;
        createResultRowsListIdea(mPagingIdea.get(curPageIdea));
        return null;
    }    
     
    public PageReference goLastPageIdea() {   
        curPageIdea = mPagingIdea.size();
        createResultRowsListIdea(mPagingIdea.get(curPageIdea));
        return null;
    }

    public boolean getPrevRequiredIdea() {
        return curPageIdea > 1; 
    }
    
    public boolean getNextRequiredIdea() {
  
        return curPageIdea * listSizeIdea < totalResultSizeIdea;
    }
     
    public boolean getFirstRequiredIdea() {
        return curPageIdea > 1;
    }
    
    public boolean getLastRequiredIdea() {
        return curPageIdea < mPagingIdea.size();
    }
    
    /*============ End Idea ==================*/
    
    // Alert banner at top of the page - Work in progress by Steve Paul
    public List<PKB_Status_Message__c> msgErr {
        get {
            List<PKB_Status_Message__c> systemMsg = new List<PKB_Status_Message__c>(); 
            for(PKB_Status_Message__c sm: [SELECT MessageText__c, Message_Type__c, Message_Start_DateTime__c, Message_End_DateTime__c, Module__c, Account__c
                                                  FROM PKB_Status_Message__c
                                                 WHERE Status__c = 'Active'
                                                  AND Module__c = 'Support'
                                                  AND (Account__c = :currentAccountId OR Account__c = '')
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
}