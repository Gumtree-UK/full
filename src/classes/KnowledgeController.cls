/**
Change log:
- 2013-04-01 - Remove issue/spam functionality
- 2013-06-13 - GTCRM-35 - Web to case workflow
- 2013-06-13 - GTCRM-79 - Help & contact centre rebuild
- 2013-06-23 - GTCRM-351 - Noticeboard type feed on help & contact centre
- 2013-07-12 - GTCRM-399 - Web to case field validation 
- 2013-11-11 - GTCRM-551 - Device tracking on online help form  
- 2014-09-24 - remove check on contact existance, reuse logic in trigger case_before_insert, SF_Gumtree_SOW_001,
- 2014-11-06 GTCRM-1515 -Webform Victim Logic
- 2014-12-03 -GTCRM-562- search field on onsite help isn't working
- 2014-11-18 - GTCRM-1556 - Urgent adjust webform logic - are you a victim
- 2014-12-04 -GTCRM-Apex classes with Test Code Coverage below 75%
- 2014-12-04 -GTCRM-1232 - Update existing help site alerts to only show for Help record type
*/

public abstract class KnowledgeController {

    private static final String PAGE_PREFIX = System.Label.PAGE_PREFIX !='/Help'? '': System.Label.PAGE_PREFIX;
    //private static final String PAGE_PREFIX = ''; 

    public static final String PAGE_HOME = 'knowledgeHome';
    public static final String PAGE_PRODUCT = 'knowledgeProduct';
    public static final String PAGE_FAQS = 'knowledgeFAQs';  // 2013.07.09 - New show all FAQ Page
    public static final String PAGE_SEARCH = 'knowledgeSearch';
    public static final String PAGE_SAFE = 'knowledgeSafe';
    public static final String PAGE_CONTACT = 'knowledgeContact';
    public static final String PAGE_CONTACT2 = 'knowledgeContact2';
    public static final String PAGE_CONTACT_OPTIONS = 'knowledgeContactOptions';
    public static final String PAGE_SEARCH_CONTACT = 'knowledgeContactSearch';
    public static final String PAGE_THANKS = 'knowledgeThanks';
    public static final String PAGE_FAQ = 'KnowledgeFAQ';
    public static final String PAGE_GI = 'KnowledgeGI';
    public static final String PAGE_KI = 'KnowledgeKI';
    public static final String PAGE_ARTICLE = 'KnowledgeArticle';

    public static final String URL_HOME = PAGE_PREFIX + '/' + PAGE_HOME;
    public static final String URL_PRODUCT = PAGE_PREFIX + '/' + PAGE_PRODUCT;
    public static final String URL_FAQS = PAGE_PREFIX + '/' + PAGE_FAQS;  // 2013.07.09 - New show all FAQ Page
    public static final String URL_ARTICLE = PAGE_PREFIX + '/' + PAGE_ARTICLE;
    public static final String URL_SEARCH = PAGE_PREFIX + '/' + PAGE_SEARCH;
    public static final String URL_SAFE = PAGE_PREFIX + '/' + PAGE_SAFE;
    public static final String URL_CONTACT = PAGE_PREFIX + '/' + PAGE_CONTACT;
    public static final String URL_CONTACT2 = PAGE_PREFIX + '/' + PAGE_CONTACT2;
    public static final String URL_CONTACT_OPTIONS = PAGE_PREFIX + '/' + PAGE_CONTACT_OPTIONS;
    public static final String URL_SEARCH_CONTACT = PAGE_PREFIX + '/' + PAGE_SEARCH_CONTACT;
    public static final String URL_THANKS = PAGE_PREFIX + '/' + PAGE_THANKS;
    public static final String URL_FAQ =  PAGE_FAQ;   // Article FAQ page
    public static final String URL_GI =  PAGE_GI;
    public static final String URL_KI =  PAGE_KI;

    public static final String ARTICLE_TYPE_PARAMETER_NAME = 't';
    public static final String CATEGORY_PARAMETER_NAME = 'c';
    public static final String KEYWORD_PARAMETER_NAME = 'k';
    public static final String PAGE_NUMBER_PARAMETER_NAME = 'p';
    public static final String ARTICLE_TYPE_LABEL_PARAMETER_NAME = 'l';
    public static final String P_EMAIL = 'em';
    public static final String P_SUBJECT = 'su';
    public static final String P_COMMENTS = 'co';
    public static final String P_AD = 'ad';
    public static final String P_CATEGORY_TOPIC = 'ct';
    public static final String P_CATEGORY_SUBJECT = 'cs';
    public static final String ARTICLE_TITLE = 'at';

    public String browserName {get; set;}
    public String browserVersion {get; set;}
    public String screenWidth {get; set;}
    public String screenHeight {get; set;}
        
    public String strErrorMessage='';

 
    public String categoryParameterName {
        get {
            return CATEGORY_PARAMETER_NAME;
        }
    }

    public String keywordParameterName {
        get {
            return KEYWORD_PARAMETER_NAME;
        }
    }

    public String articleTypeParameterName {
        get {
            return ARTICLE_TYPE_PARAMETER_NAME;
        }
    }
    
    public String getURLSitemap(){
        return ApexPages.currentPage().getUrl();
    }

    public String articleTypeLabelParameterName {
        get {
            return ARTICLE_TYPE_LABEL_PARAMETER_NAME;
        }
    }

    public String pageNumberParameterName {
        get {
            return PAGE_NUMBER_PARAMETER_NAME;
        }
    }

    
    public pageReference convertURL(){
        return new pageReference(ApexPages.currentPage().getUrl().replace('%26','&').replace('%3D','='));
    }


   public String getConvertURLString(){
        return ApexPages.currentPage().getUrl().replace('%26','&');
    }



    protected String paramByParamId(String paramId, String defaultValue) {
        if (convertURL().getParameters() == null) {
            return defaultValue;
        } else {
            String value = convertURL().getParameters().get(paramId);
            return (value == null) ? defaultValue : value;
        }
    }

    protected Integer paramByParamId(String paramId, Integer defaultValue) {
        if (convertURL().getParameters() == null) {
            return defaultValue;
        } else {

            String value = convertURL().getParameters().get(paramId);
            return (value == null) ? defaultValue : Integer.valueOf(value);
        }
    }

    // - 2013-06-13 - GTCRM-79 - Help & contact centre rebuild  - add topic & subject
    public Case ca{get;set;}

    //NK:08/04/2014
    public String ipAddress {get {return ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');}set;}
    
    // getting Record Type Id
    private Id getRecordTypeId(String sObjType, String rTypeName){
        return Schema.getGlobalDescribe().get(sObjType).getDescribe().getRecordTypeInfosByName().get(rTypeName).getRecordTypeId();
    }
    
public KnowledgeController(){
    ca=new Case();
    ca.RecordtypeId = getRecordTypeId('Case', 'Customer Services');  
    //---11-09-2014 kakada khan ---//
    isSelectedNO=true;
    isShowAnswer=false;
    //--------------------------//
    
    if(getIsSearchPage()){
        currentKeyword = Apexpages.currentPage().getParameters().get(KEYWORD_PARAMETER_NAME);
        String query = 'find \'*' + currentKeyword + '*\' IN ALL FIELDS RETURNING KnowledgeArticleVersion ( UrlName, ArticleType, Title, Summary, SourceId, PublishStatus, KnowledgeArticleId where publishStatus=\'online\' and Language=\'en_US\')';
        List<List<Sobject>> lstFinds = Search.query(query);
        lstKnowLegdeArtVer = lstFinds[0];
        hasRecord = !lstKnowLegdeArtVer.isEmpty();
        hasNext = (hasRecord && lstKnowLegdeArtVer.size() > MAX_RECORD);
        
        lstDisplayKnowLegde = new List<DTO_Knowlegde>();
        currentIndexPage = 1;
        
        numberOfPage = (lstKnowLegdeArtVer == null || lstKnowLegdeArtVer.isEmpty() ? 0: lstKnowLegdeArtVer.size() / MAX_RECORD);
        numberOfPage = numberOfPage.setScale(0, System.Roundingmode.UP);
        lstOfPage = new List<Integer>();
        for(Integer i=1; i<=numberOfPage; i++){
            lstOfPage.add(i);
        }
        gotoPage();
    }
}



//- 09-Jul-2013: Sopha: Build pagination by use SOSL
private List<KnowledgeArticleVersion> lstKnowLegdeArtVer = new List<KnowledgeArticleVersion>();
public List<DTO_Knowlegde> lstDisplayKnowLegde {get;set;}
public final static Integer MAX_RECORD = 12;
public Boolean hasNext {get;set;}
public Boolean hasRecord {get;set;}
public Integer currentIndexPage {get;set;}
public List<Integer> lstOfPage {get;set;}
private Decimal numberOfPage =0;
private Integer lastIndex = 0;

/*public Pagereference goNext(){
    lstDisplayKnowLegde.clear();
    Integer index = lastIndex;
    
    for(Integer i=lastIndex; i<lastIndex + MAX_RECORD; i++){
        lstDisplayKnowLegde.add(new DTO_Knowlegde(lstKnowLegdeArtVer.get(i).KnowledgeArticleId , lstKnowLegdeArtVer.get(i)));
        index += 1;
    }
    
    currentIndexPage += 1;
    lastIndex = index;
    
    hasNext = (currentIndexPage < numberOfPage);
    return null;
}

public Pagereference goPrevious(){
    lstDisplayKnowLegde.clear();
    Integer index = lastIndex;
    
    for(Integer i=lastIndex-MAX_RECORD; i<lstKnowLegdeArtVer.size(); i--){
        lstDisplayKnowLegde.add(new DTO_Knowlegde(lstKnowLegdeArtVer.get(i).KnowledgeArticleId , lstKnowLegdeArtVer.get(i)));
        index -= 1;
    }
    
    currentIndexPage -= 1;
    lastIndex = index;
    hasNext = true;
    return null;
}*/
private Integer getStartIndexRec(Integer pageNumber){
    return (pageNumber * MAX_RECORD) - MAX_RECORD;
}
  
public Pagereference gotoPage(){
	
    lstDisplayKnowLegde.clear();
    Integer startIndex = getStartIndexRec(currentIndexPage);
    Integer index = lastIndex;
    
    
    for(Integer i=startIndex; i<(startIndex + MAX_RECORD); i++){
        lstDisplayKnowLegde.add(new DTO_Knowlegde(lstKnowLegdeArtVer.get(i).KnowledgeArticleId , lstKnowLegdeArtVer.get(i)));
    }
    
    hasNext = currentIndexPage < numberOfPage;
    return null;
}
//go next page
  public Pagereference goNext(){
    currentIndexPage++;
    if(currentIndexPage >= numberOfPage){
      currentIndexPage = Integer.valueOf(numberOfPage);
    }
    gotoPage();
    return null;
  }
  
  //go previous Page
  public Pagereference goPrevious(){
    currentIndexPage--;
    if(currentIndexPage <= 1){
      currentIndexPage = 1;
    }
    gotoPage();
    return null;
  }
  
public class DTO_Knowlegde{
    public String knowlegdeArticalId {get;set;}
    public KnowledgeArticleVersion knowlegdeArtical {get;set;}
    public String urlKnowledge {get;set;}
    
    public DTO_Knowlegde(String knowlegdeArticalId, KnowledgeArticleVersion knowlegdeArtical){
        this.knowlegdeArtical = knowlegdeArtical;
        this.knowlegdeArticalId = knowlegdeArticalId.substring(0,15);
        String articalType = knowlegdeArtical.ArticleType.replace('__kav', '');
        this.urlKnowledge = '/articles/' + articalType + '/' + knowlegdeArtical.UrlName + '?at=' + knowlegdeArtical.Title;
    }
}
public List<SelectOption> getFinalsOptions(){
        List<SelectOption> Finalsoptions = new List<SelectOption>();
        Finalsoptions.add(new SelectOption('null','-- Select One --'));
        Schema.DescribeFieldResult Finals = Schema.sObjectType.Case.fields.Web2Case_Reason__c;
        for (Schema.PickListEntry FinalsPickVal : Finals.getPicklistValues()){
            // create a selectoption for each pickval
            Finalsoptions.add(new SelectOption(FinalsPickVal.getValue(),FinalsPickVal.getLabel()));
        }
        return Finalsoptions;
    }

public List<SelectOption> getFinalsOptions2(){
        List<SelectOption> Finalsoptions2 = new List<SelectOption>();
        Finalsoptions2.add(new SelectOption('null','-- Select One --'));
        Schema.DescribeFieldResult Finals2 = Schema.sObjectType.Case.fields.Web2Case_SubReason__c;
        for (Schema.PickListEntry FinalsPickVal2 : Finals2.getPicklistValues()){
            // create a selectoption for each pickval
            Finalsoptions2.add(new SelectOption(FinalsPickVal2.getValue(),FinalsPickVal2.getLabel()));
        }
        return Finalsoptions2;
    }    
     
    public Integer currentPageNumber {
        get {
            if (currentPageNumber == null) {
                currentPageNumber = paramByParamId(PAGE_NUMBER_PARAMETER_NAME, 1);
            }
            return currentPageNumber;
        }
        set;
    }
    
    
   public String getErrorMessage(){
    
    return strErrorMessage;
    
   }
    
    public String Subject {
        get {
            
            if (Subject == null) 
                Subject = paramByParamId(P_SUBJECT, '');
            if(Subject=='')
                Subject='Example: \'I can’t find my ad\'';
                          
            return Subject;
        }
        set;
    }
    

    public String PageTitle {
        get {
            
            PageTitle=paramByParamId(ARTICLE_TITLE, 'Gumtree Help');
            return PageTitle;
        }
        set;
    }
    
    public String copyEmail {
        get {
            if (copyEmail == null) {
                copyEmail='';
            }
            return copyEmail;
        }
        set;
    }
   public String contactName {
        get {
            if (contactName == null) {
                contactName='';
            }
            return contactName;
        }
        set;
    }
    
        public String getSubjectComments() {
      
            return 'Subject: '+Subject+' - Comments: '+Comments;
       
    }
    
    
        public String Comments {
        get {
            if (Comments == null) {
                Comments = paramByParamId(P_COMMENTS,'');
            }
            return Comments;
        }
        set;
    }
    
    public String IssueDescription {
        get {
            if (IssueDescription == null || IssueDescription == '') {
                IssueDescription = 'Please let us know: \n1) on which part of the site you experienced the issue, and \n2) what the issue was.';
            }
            return IssueDescription;
        }
        set;
    }
    
    public String InternetBrowser {
        get {
            if (InternetBrowser == null) {
                InternetBrowser = 'E.g. Internet Explorer 8 or Mozilla Firefox 3';
            }
            return InternetBrowser;
        }
        set;
    }
    public String PhoneNumber {
        get {
            if (PhoneNumber == null) {
                PhoneNumber = 'In case we need to call you to find out more information about the issue.';
            }
            return PhoneNumber;
        }
        set;
    }
    
    public String email {
        get {
            if (email == null) {
                email = paramByParamId(P_EMAIL,'');
            }
            return email;
        }
        set;
    } 
    
    //MS 20-08-2014: Task #3806 -- Webform new field confirm email address
    public String confirm_email{get;set;}
    
   public String getEmail() {
 
           if (email == null) 
           return '';
           else return email;

    }
    
    public String ad {
        get {
            if (ad == null) {
                ad = paramByParamId(P_AD,'');
            }
            return ad;
        }
        set;
    }

// GTCRM-35 - Web to case workflow update    
    public String categoryTopic {
        get {
            if (categoryTopic == null) {
                categoryTopic = paramByParamId(P_CATEGORY_TOPIC,'');
            }
            return categoryTopic;
        }
        set;
    }
    
    public String categorySubject {
        get {
            if (categorySubject == null) {
                categorySubject = paramByParamId(P_CATEGORY_SUBJECT,'');
            }
            return categorySubject;
        }
        set;
    }
      
    public String currentCategory {
        get {
            if (currentCategory == null) {
                currentCategory = paramByParamId(CATEGORY_PARAMETER_NAME, getRootCategoryName());
            }
            return currentCategory;
        }
        set;
    }
    
    public String currentCategoryName {
        get {
            if (currentCategoryName == null) {
                currentCategoryName = paramByParamId(CATEGORY_PARAMETER_NAME, getRootCategoryName()).replace('_',' ');
            }
            return currentCategoryName;
        }
        set;
    }

    public String currentArticleType {
        get {
            if (currentArticleType == null) {
                currentArticleType = paramByParamId(ARTICLE_TYPE_PARAMETER_NAME, '');
            }
            return currentArticleType;
        }
        set;
    }

    public String currentArticleTypeLabel {
        get {
            if (currentArticleTypeLabel == null) {
                currentArticleTypeLabel = paramByParamId(ARTICLE_TYPE_LABEL_PARAMETER_NAME, '');
            }
            return currentArticleTypeLabel;
        }
        set;
    }
    
/*    public void checkSpam(){

        spam=true;  
        
    }
*/
    public String currentKeyword {
        get {
            if (currentKeyword == null) {
                currentKeyword = paramByParamId(KEYWORD_PARAMETER_NAME, '');
            if(currentKeyword=='')
                currentKeyword='Example: \'email alerts\'';
            }
            return currentKeyword;
        }
        set;
    }
    
    public  map<String,DataCategory__c> mapDc =new map<String,DataCategory__c>();

    public static PKBSiteSetup__c siteSetup {
        get {
            if (siteSetup == null) {
                try {
                    String siteName = Site.getName();
                    if (siteName == null || siteName.length()==0) {
                        siteName = 'knowledgeGumTree'; 
                        
                    }
                    siteSetup = [
                       SELECT PKBSiteName__c, RootCategoryName__c, CategoryGroupName__c, CacheMaxAge__c,
                       Category1Description__c, Category2Description__c, Category3Description__c,
                       Category4Description__c, Category5Description__c, Category6Description__c,
                       HomeAdText__c, HomeAdTitle__c
                       FROM PKBSiteSetup__c
                       WHERE PKBSiteName__c = :siteName ];
                             
                } catch (QueryException  e) {
                    // can't throw an exception here in order to prevent tests from failing before creating an PKB Site Setup
                    siteSetup = new PKBSiteSetup__c();
                }
            }
            return siteSetup;
        }
        set;
    }

    public PKBSiteSetup__c getSiteSetup() {
        return siteSetup;
    }


    private String[] categoryDescriptions;

    public String[] getCategoryDescriptions() {
        if (categoryDescriptions == null) {
            categoryDescriptions = new String[]{};
            categoryDescriptions.add(siteSetup.category1Description__c == null ? '' : siteSetup.category1Description__c);
            categoryDescriptions.add(siteSetup.category2Description__c == null ? '' : siteSetup.category2Description__c);
            categoryDescriptions.add(siteSetup.category3Description__c == null ? '' : siteSetup.category3Description__c);
            categoryDescriptions.add(siteSetup.category4Description__c == null ? '' : siteSetup.category4Description__c);
            categoryDescriptions.add(siteSetup.category5Description__c == null ? '' : siteSetup.category5Description__c);
            categoryDescriptions.add(siteSetup.category6Description__c == null ? '' : siteSetup.category6Description__c);
        }
        return categoryDescriptions;
    }
    
    
    public static List<DataCategory__c> getDcStatic(){
        return [select Name,DescriptionToDisplay__c, ShowPhoneContact__c, AvailablePhoneTimes__c, AvailablePhoneNumbers__c  from DataCategory__c];
    }
    
    //MS 22-08-2014 Task #3808:phone number visibility when ShowPhoneContact__c = true
    public String phonetime{get;set;}
    
    public DataCategory__c getDC(){

        if(mapDc==null || mapDc.size()==0){
            
            List<DataCategory__c> lDc=getDcStatic();
                for(DataCategory__c oDc:lDc){
                    mapDC.put(oDc.Name,oDc);
                } 
        }
        if(mapDC.get(currentCategory)!=null){
            phonetime = preparePhoneTime(mapDC.get(currentCategory).AvailablePhoneTimes__c);
            return mapDC.get(currentCategory);
        }
        else{
        	 return mapDC.get('No_Cat');
        }
    } 
    
    public String getHomeAdTitle() {
        return siteSetup.HomeAdTitle__c == null ? '' : siteSetup.HomeAdTitle__c;
    }

    public String getHomeAdText() {
        return siteSetup.HomeAdText__c == null ? '' : siteSetup.HomeAdText__c;
    }

    public String getRootCategoryName() {
        return siteSetup.RootCategoryName__c == null ? '' : siteSetup.RootCategoryName__c;
    }

    public String getCategoryGroupName() {
        return siteSetup.CategoryGroupName__c == null ? '' : siteSetup.CategoryGroupName__c;
    }

    public Long getCacheMaxAge() {
        return siteSetup.CacheMaxAge__c == null ? 0 : Math.roundToLong(siteSetup.CacheMaxAge__c);
    }


    public String getHomeUrl() {
        return URL_HOME;
    }

    public String getProductUrl() {
        return URL_PRODUCT;
    }
    public String getFAQSUrl() {
        return URL_FAQS;
    }
    public String getArticleUrl() {
        return URL_ARTICLE;
    }
    
    public String getContactUrl() {
        return URL_CONTACT;
    }

    public String getContactOptionsUrl() {
        return URL_CONTACT_OPTIONS;
    }
    
    public String getSafeUrl() {
        return URL_SAFE;
    }

    public String getSearchUrl() {
        return URL_SEARCH;
    }
    public String getThanksUrl() {
        return URL_THANKS;
    }
    public String getFaqUrl() {
        return URL_FAQ;
    }
    public String getKiUrl() {
        return URL_KI;
    }
    public String getGiUrl() {
        return URL_GI;
    }
    
    public String getSearchUrlContact() {
        return URL_SEARCH_CONTACT;
    }

    public String getSearchUrlContact2() {
        return URL_CONTACT2;
    }
    public String getHomePage() {
        return PAGE_HOME;
    }
    public String getThanks() {
        return PAGE_THANKS;
    }
    
    public String getContactPage() {
        return PAGE_CONTACT;
    }

    public String getFAQSPage() {
        return PAGE_FAQS;
    }
    public String getContactOptionsPage() {
        return PAGE_CONTACT_OPTIONS;
    }
   public String getContactSearchPage() {
        return PAGE_SEARCH_CONTACT;
    }

    
    public String getSafePage() {
        return PAGE_SAFE;
    }
    
    public String getFaqPage() {
        return PAGE_FAQ;
    }
    
    public String getGiPage() {
        return PAGE_GI;
    }
  
    public String getKiPage() {
        return PAGE_KI;
    }
    public String getProductPage() {
        return PAGE_PRODUCT;
    }
    
    public String getArticlePage() {
        return PAGE_ARTICLE;
    }

    public String getSearchPage() {
        return PAGE_SEARCH;
    }

    public String getPage(String url) {
        if (url.contains('?')) {
            Integer i = url.indexOf('?');
            url = url.substring(0, i);
        }
        while (url.endsWith('/')) {
            url = url.substring(0, url.length()-1);
        }
        if (url.contains('/')) {
            Integer i = url.lastIndexOf('/');
            url = url.substring(i+1);
        }
        return url;
    }


    public PageReference currentPageReference {
        get {
            if (currentPageReference == null) {
                currentPageReference = ApexPages.currentPage();
            }
            return currentPageReference;
        }
        set;
    }
    
    public PageReference getCurrentPageReferenceReplace(){
        return new PageReference( currentPageReference.getUrl().replace('&', '%26'));
    }
    public String currentPage {
        get {
                if (currentPage == null) {
                    currentPage = getPage(currentPageReference.getUrl());
                }
                return currentPage;
            }
            set;
    }

    public Boolean isPage(String pageName) {
        return currentPage.toLowerCase() == (pageName.toLowerCase());
    }

    public Boolean getIsHomePage() {
        return isPage(PAGE_HOME);
    }
    public Boolean getIsFaqPage() {
        return isPage(PAGE_FAQ);
    }
    public Boolean getIsKiPage() {
        return isPage(PAGE_KI);
    }
    public Boolean getIsGiPage() {
        return isPage(PAGE_GI);
    }
    
   public Boolean getIsThanksPage() {
        return isPage(PAGE_THANKS);
    }
   public Boolean getIsStaySafePage() {
        return isPage(PAGE_SAFE);
    }
    
    public Boolean getIsContactPage() {
    System.debug('SFDC '+isPage(PAGE_CONTACT));
        return isPage(PAGE_CONTACT);
    }
    public Boolean getIsContactPage2() {
        return isPage(PAGE_CONTACT2);
    }
    public Boolean getIsContactOptionsPage() {
    System.debug('SFDC '+isPage(PAGE_CONTACT_OPTIONS));
        return isPage(PAGE_CONTACT_OPTIONS);
    }
    public Boolean getIsContactSearchPage() {
        return isPage(PAGE_SEARCH_CONTACT);
    }

    public Boolean getIsProductPage() {
        return isPage(PAGE_PRODUCT);
    }
    public Boolean getIsArticlePage() {
        return isPage(PAGE_ARTICLE);
    }

    public Boolean getIsSearchPage() {
        return isPage(PAGE_SEARCH);
    }
    public Boolean getIsSearchContactPage() {
        return isPage(PAGE_SEARCH_CONTACT);
    }

    public Boolean getIsExternalPage() {
        return !(getIsHomePage() || getIsProductPage() || getIsSearchPage() || getisFaqPage() || getisGiPage() ||getisKiPage() ||getIsArticlePage());
    }

// 2014-12-03 -GTCRM-562- search field on onsite help isn't working
   public PageReference doSearch() {

        if (currentKeyword.length()<2) {
            return cleanKeyword();
        }
        PageReference pg = new PageReference(getSearchUrl());
        pg.getParameters().put(KEYWORD_PARAMETER_NAME, currentKeyword +' ');
        pg.getParameters().put(CATEGORY_PARAMETER_NAME, currentCategory);
        pg.setRedirect(true);
        system.debug('***** pg = '+pg);
        return pg;
   }
   
   public PageReference doSaveCase() {
        strErrorMessage='';  
        if(!isValidThird())         
            return null;

        
        Boolean existant=false;
        String recordTypeId='';
        PageReference pg = new PageReference(getThanksUrl());
        
        String Description='';
        Description=Comments;
              
        Case newCase=new Case();
        newCase.OwnerId='00520000001Cywv';
        newCase.Posting_Reference__c=ad;
        newCase.Description=Description;
//        newCase.Subject=categorysubject;
        newCase.Subject=Subject;
        newCase.IP_Address__c = getIp();
        newCase.User_Agent__c = getUA();
        newCase.PC_Details__c =  'Browser name: ' + browserName + '\n Browser version: ' + browserVersion;
        newCase.Browser_Details__c = screenHeight + 'x' + screenWidth;
        
        //mengsrorn 2014-04-22
        newCase.User_Source__c= getOS(getUA());
        newCase.User_Source_Extra__c = PreChatFormController.populateUserSourceExtra(getUA());
                
        // email supplier, dupe check will handle duplicate
        // the trigger case_before_insert will handle the creation of contact with correct Contact if empty
        // SF_Gumtree_SOW_001.handleCaseBeforeInserts will handle the duplicate contact
         newCase.SuppliedEmail = email;

// - 2013-06-13 - GTCRM-35 - Web to case workflow        
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
        
        /*
        //---11-09-2014 kakada khan---//
       addMoreFields(newCase);
        */
        
        
        System.debug('recordTypeIdAvant->'+newCase.RecordTypeId); 
        insert newCase;
        
        pg.setRedirect(true);
        return pg;
   }
   
   public  Boolean isValidFirst(){
       ApexPages.getMessages().clear();
    
       Boolean valid=true;
              
          if(Subject.length()<2){
             strErrorMessage='Please enter a question string at least 2 characters long';
             valid=false;
          }
           
           if(Subject=='Example: \'I can?t find my ad\'' && valid){
             strErrorMessage='Please enter a question';
             valid= false;
           }
           
           if(categoryTopic == 'Question about my paid ad' || categoryTopic =='Question about my free ad'&& valid){
             strErrorMessage='Please enter your ad reference number';
             valid= false;
           }
           
           if(categoryTopic =='Report Fraud/Scam/Abuse' && categorySubject == 'Ad' && valid){
             strErrorMessage='Please enter your ad reference number';
             valid= false;
           }
           
           if (valid &&((categorySubject=='')||(categorySubject=='-- Select One --')||(categorySubject==null)||(categorySubject=='null'))){ 
            strErrorMessage='Please Select a Subject'; 
            valid=false;    
               
           }
       return valid;
   }
   
   
   public String isIgnoreSubject{get;set;}
   public  PageReference test(){
   
   //---- 11-09-2014------//  
   myViewString = ca.Web2Case_Reason__c; 
   isShowAnswer=false;
   isSelectedNO=true;
   selectType='--None--';   
   if(myViewString == null || myViewString == ''){return null;}   
   if(myViewString.equalsIgnoreCase('Report Fraud/Scam/Abuse')){
     isShowAnswer=true;
   }   
      //-------------------//
      
     return null;
   }
   
    public  Boolean isValidSecond(){
         erMessage='';
         ApexPages.getMessages().clear();
        
         Boolean valid=true;
         Boolean firstMessage=true; 
       
          if(Subject.length()<2){
             strErrorMessage='Please enter a question string at least 2 characters long';
             valid=false;
          }
          
           if(valid && Subject=='Example: \'I can’t find my ad\'' && isSelectedNO){
              strErrorMessage='Please enter a question';
             valid=false;
           }
           
           if((categoryTopic == 'Question about my paid ad' || categoryTopic =='Question about my free ad') && ad=='' && valid){
             strErrorMessage='Please enter your ad reference number';
             valid= false;
           }
           
           if(categoryTopic =='Report Fraud/Scam/Abuse' && categorySubject == 'Ad' && ad=='' && valid  && isSelectedNO){
             strErrorMessage='Please enter your ad reference number';
             valid= false;
           }
           
           if ((valid &&((categorySubject=='')||(categorySubject=='-- Select One --')||(categorySubject==null)||(categorySubject=='null'))) && isIgnoreSubject!='true'){          
             strErrorMessage='Please select a category'; 
            valid=false;    
           }
           
            if(valid && !Pattern.matches('^([0-9a-zA-Z]([-.\\w]*[0-9a-zA-Z])*@([0-9a-zA-Z][-\\w]*[0-9a-zA-Z]\\.)+[a-zA-Z]{2,9})$', email)){     
             strErrorMessage='Please enter a valid email address'; 
             valid=false;       
           }
           
           //MS 20-08-2014: Task #3806 -- Webform new field confirm email address
           if(valid && (email != confirm_email)){
            strErrorMessage='Your emails don\'t match. Please try again.'; 
            valid=false;      
           }
           
           if(!valid) {
                erMessage='Error: '+strErrorMessage;
           }
       
       return valid;
   }
   
   public String erMessage{get;set;}

    public  Boolean isValidThird(){
        
         Boolean valid=true;
         ApexPages.getMessages().clear();

      
                
            if(Comments.length()<2){
              strErrorMessage='Please enter comments';
             valid=false;
          }
           
           if (valid&&((categorySubject=='')||(categorySubject=='-- Select One --')||(categorySubject==null)||(categorySubject=='null'))){ 
             strErrorMessage='Please select a subject'; 
            valid=false;    
           }
           
            if(valid && !Pattern.matches('^([0-9a-zA-Z]([-.\\w]*[0-9a-zA-Z])*@([0-9a-zA-Z][-\\w]*[0-9a-zA-Z]\\.)+[a-zA-Z]{2,9})$', email)){     
                 strErrorMessage='Please enter a valid email address'; 
                valid=false;        
           }
           
           //MS 20-08-2014: Task #3806 -- Webform new field confirm email address
           if(valid && (email != confirm_email)){
            strErrorMessage='Your emails don\'t match. Please try again.'; 
            valid=false;      
           }
   
       return valid;
   }
   
   
      public PageReference doSaveCaseBis() { 
      strErrorMessage='';   
         try{
         categorySubject=ca.Web2Case_SubReason__c;
         categoryTopic=ca.Web2Case_Reason__c;
                 if(!isValidSecond())       
                    return null;
                
                Boolean existant=false;
                String recordTypeId='';
                PageReference pg = new PageReference(getThanksUrl());
               
        
                String Description='';
                Description=Comments;
          
                Case newCase=new Case();
                newCase.OwnerId='00520000001Cywv';
                newCase.Posting_Reference__c=ad;
                newCase.Description=Description;
                newCase.Subject=Subject;
                newCase.IP_Address__c = getIp();
                newCase.User_Agent__c = getUA();
                
                // email supplier, dupe check will handle duplicate
                // the trigger case_before_insert will handle the creation of contact with correct Contact if empty
                // SF_Gumtree_SOW_001.handleCaseBeforeInserts will handle the duplicate contact
                newCase.SuppliedEmail = email;
                
                //mengsrorn 2014-04-22
                newCase.User_Source__c= getOS(getUA());
                newCase.User_Source_Extra__c = PreChatFormController.populateUserSourceExtra(getUA());
                
                newCase.Web2Case_SubReason__c=ca.Web2Case_SubReason__c;
                newCase.Web2Case_Reason__c=ca.Web2Case_Reason__c;
                newCase.Origin='Web';
                newCase.PC_Details__c =  'Browser name: ' + browserName + '\n Browser version: ' + browserVersion;
                newCase.Browser_Details__c = screenHeight + 'x' + screenWidth;
             
                //NK:08/04/2014: fetch and assign geo to Case
                LiveAgentGEO.fetchVisitorGEO(newCase,ipAddress);
                
                
         
            // - 2013-06-13 - GTCRM-35 - Web to case workflow
            System.debug('Start = false');
                if(categoryTopic=='Question about my Free Ad' && categorySubject=='General Enquiry'){
                recordTypeId='01220000000Q9DR';
                newCase.Type='Free CS';
                }
                else if(categoryTopic=='Question about my Free Ad' && categorySubject=='Technical Issue'){
                  recordTypeId='01220000000Q9DR';
                  newCase.Type='Free Sellers';
                  newCase.Reason='Technical Issue';  
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
               
                System.debug('Start = false:'+recordTypeId);
                if(recordTypeId!='') newCase.RecordTypeId=recordTypeId;
                System.debug('recordTypeIdAvant->'+newCase.RecordTypeId);  
 
         
            //---15-09-2014 kakada khan---//
            addMoreFields(newCase);          
 
                insert newCase;
                System.debug('======== new case '+newCase);
                
                pg.setRedirect(true);
                return pg;   
               
         }catch(Exception ex){
            strErrorMessage='Error:'+ex+'';
            erMessage=strErrorMessage;
            return null;
        }
       
        
   }
   
   public PageReference doSearchContact() {
    
        strErrorMessage='';
    
        if(!isValidFirst()){    
            return null;
        }
        PageReference pg = new PageReference(getSearchUrlContact());
        pg.getParameters().put(P_SUBJECT,Subject );
        pg.getParameters().put(P_CATEGORY_SUBJECT, categorySubject );                                   
        pg.setRedirect(true);
        return pg;
   }
   public PageReference doSearchContact2() {
    
        strErrorMessage='';
    
        if(!isValidFirst()){    
            return null;
        }
        PageReference pg = new PageReference(getSearchUrlContact2());
        pg.getParameters().put(P_SUBJECT,Subject );
        pg.getParameters().put(P_CATEGORY_SUBJECT, categorySubject );                                   
        pg.setRedirect(true);
        return pg;
   }
   
   public PageReference cleanKeyword() {
        PageReference pg = new PageReference(getProductUrl());
        pg.getParameters().put(CATEGORY_PARAMETER_NAME, currentCategory);
        pg.getParameters().put(KEYWORD_PARAMETER_NAME, '');
        currentKeyword = '';
        if (getIsExternalPage()) {
            pg.setRedirect(true);
        }
        return pg;
   }

    public Boolean getCanUserSeeKnowledge() {
        //return [select permissionsviewknowledge from profile where id = :UserInfo.getProfileId()].permissionsviewknowledge;
        return [select PermissionsEditKnowledge from profile where id = :UserInfo.getProfileId()].PermissionsEditKnowledge;
        
    } 

// - 2013-06-23 - GTCRM-351 - Noticeboard type feed on help & contact centre      
    public List<PKB_Status_Message__c> msgErr {
        get {
            List<PKB_Status_Message__c> systemMsg = new List<PKB_Status_Message__c>(); 
            for(PKB_Status_Message__c sm: [SELECT MessageText__c, Message_Type__c, Message_Start_DateTime__c, Message_End_DateTime__c 
                                                  FROM PKB_Status_Message__c
                                                 WHERE Status__c = 'Active'
                                                 // - 2014-12-04 - GTCRM-1232 - Update existing help site alerts to only show for Help record type
                                                 AND RecordType.Name = 'Help'
                                                  AND ((Message_Start_DateTime__c < :system.now() AND
                                                        Message_End_DateTime__c   > :system.now())
                                                  OR   (Message_Start_DateTime__c = null AND
                                                        Message_End_DateTime__c   = null)) order by CreatedDate desc
                                                  ]){
                   systemMsg.add(sm);
                 //System.debug('XXXXX sm-->' + sm);
            }
            return systemMsg;
        } 
        set;
    }


  // getting IP of user visiting the page
    public String p { get; set; }
    public String getIp() {
        p = ApexPages.currentPage().getHeaders().get('X-Salesforce-SIP');
        return p;
    } 

  // 2013-11-11 - GTCRM-551 - Device tracking on online help form  
    public String u { get; set; }
    public String getUA() {
        u = ApexPages.currentPage().getHeaders().get('User-Agent');
        return u;
    } 

    public void browserDetails() {
        browserName = Apexpages.currentPage().getParameters().get('name');
        browserVersion = Apexpages.currentPage().getParameters().get('version');
        screenWidth = Apexpages.currentPage().getParameters().get('width');
        screenHeight = Apexpages.currentPage().getParameters().get('height');
    }
    
    //mengsrorn 2014-04-22: base on user agent to get device os.
    public String getOS(String userAgent){
        
        System.debug('>> getOS ' + userAgent);
        
        //& some devices use custom headers for the user-agent.
        if (String.isEmpty(userAgent)){
            userAgent = ApexPages.currentPage().getHeaders().get('HTTP_X_OPERAMINI_PHONE_UA');
        }       
        if (String.isEmpty(userAgent)){
            userAgent = ApexPages.currentPage().getHeaders().get('HTTP_X_SKYFIRE_PHONE');
        }
                 
        //& replace with custom setting - using (?i) case insensitive mode.     
        String deviceReg = '(?i)(iphone|ipod|ipad|blackberry|bb10|blackberry95|blackberry97|blackberry95|playbook|kindle|android|nokia|palm\\s+ce)';
        String desktopReg = '(?i)(windows|linux|macintosh|os\\s+[x9]|solaris|bsd)';
         
        Matcher m = Pattern.compile(deviceReg).matcher(userAgent);
        
        if (m.find()){
        
            return m.group();   
        } 
        else {
            //& don't compile the patterns unless required.
            m = Pattern.compile(desktopReg).matcher(userAgent);
            
            if (m.find()){
                return 'Desktop';
            }
        }
        
        return 'Unknown';
    }
    
    /*
     * MS 21-012015 Task # 4472 - User source extra information -GTCRM-771
     * Called From trigger case_before_insert when user manual create case
     * User_Source = 'Desktop' and User_Source_Extra = 'Desktop'
     */
    public static void updateCaseUserSource(List<Case> lstCase){
        for(Case ca : lstCase){
            if(ca.User_Source__c == null) ca.User_Source__c = 'Unknown';
            if(String.isEmpty(ca.User_Source_Extra__c)) ca.User_Source_Extra__c = 'Unknown';
        }
    }
    
    //MS 22-08-2014 Task #3808:phone number visibility when ShowPhoneContact__c = true
    public String preparePhoneTime(String phonetime){
        String readyPhoneTime = '';
        PhoneTime=(PhoneTime==null)?'':PhoneTime;
        List<String> lstPhoneTime = phonetime.split('\n');
        
        for(String pt : lstPhoneTime){
            readyPhoneTime += pt.trim()+'<br/>';
        }
        return readyPhoneTime;
    }
    
    
    //==== 11/09/2014 Author: Kakada Khan =====//
    //----------- Edit for new fields -----------//
    public String selectType {get;set;}
    public boolean isSelectedNO {get;set;}
    private String myViewString='';  
    public boolean isShowAnswer {get;set;} 
    
    //event change answer
    public Pagereference chengeType(){
      if(selectType.equals('no') || selectType.equals(' ')){
        isSelectedNO=true;
      }    
      else{
        isSelectedNO=false;
      }
      return null;
    }
    
    
    // get item for dropdown list answer
    public List<SelectOption> getAnswer(){
      List<SelectOption> lst = new List<SelectOption>();
      lst.add(new SelectOption(' ','--None--'));
      lst.add(new SelectOption('no','No'));
      lst.add(new SelectOption('yes','Yes'));
      lst.add(new SelectOption('unsure','Unsure'));
      return lst;
    }
    
    
    //add some fields for Case
    private void addMoreFields(Case obj){
      if(isShowAnswer){
        if(selectType.equals(' ')){
        //--- select none---//        
        }
        else if(selectType.equals('no')){
          //--- select no---// 
          obj.Scam__c = 'NO';
          obj.RecordTypeId='012w0000000QN48'; //Victim
        }
        else if(selectType.equals('yes') || selectType.equals('unsure')){
          if(selectType.equals('yes')){
            //--- select yes---//
            obj.Scam__c='YES';
            obj.Scam_Type__c='Fraud Ad';
            //if(categorySubject=='Ad'){
              obj.Reason='User Reporting Ads';
            //}
            //else if(categorySubject=='Reply'){
            //  obj.Reason='User Reporting Replies';
            //}
            //else{
            //  obj.Reason='None Specific/Other';
            //}    
            obj.Safety_Category__c='Not Known';       
          }
          if(selectType.equals('unsure')){
            //--- select unsure---//
         // 2014-11-18 - GTCRM-1556 - Urgent adjust webform logic - are you a victim
            obj.Scam__c='NO';
          }
          
          //more field when yea/unsure        
          obj.RecordTypeId='012w0000000QN48'; //Victim
          obj.Item__c=ca.Item__c;
          obj.Amount_lost__c=ca.Amount_lost__c;
          obj.Payment_Method__c=ca.Payment_Method__c;
          obj.Victim_Postcode__c=ca.Victim_Postcode__c;
          
          //obj.Posting_Reference__c='';
          obj.Subject='';
        }  
      }   
    }
}