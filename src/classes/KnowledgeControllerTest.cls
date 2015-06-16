/**
    Test class for:
    - KnowledgeController.cls
    
 - 2014-12-04 -GTCRM-Apex classes with Test Code Coverage below 75%

 */

@isTest (seeAllData=true)
private class KnowledgeControllerTest {

   public static void setupTest() {
        Integer num = [ SELECT count() FROM PKBSiteSetup__c WHERE PKBSiteName__c = 'TestPKBSiteSetup' ];
        PKBSiteSetup__c siteSetup;
        if (num == 0) {
            siteSetup = new PKBSiteSetup__c();
        } else {
            siteSetup = [ SELECT id FROM PKBSiteSetup__c ];
        }
        siteSetup.Name = 'test setup';
        siteSetup.PKBSiteName__c = 'TestPKBSiteSetup';
        siteSetup.RootCategoryName__c = 'Root categ';
        siteSetup.CategoryGroupName__c = 'Category Group';

        upsert siteSetup;

        // force IdeaController to requery the static siteSetup
        KnowledgeController.siteSetup = null;
    }


    static testMethod void testParamProperties() {
        setupTest();
         Test.setCurrentPage(Page.knowledgeHome);
        TestKnowledgeController controller = new TestKnowledgeController();
        ApexPages.currentPage().getParameters().put(KnowledgeController.PAGE_NUMBER_PARAMETER_NAME, '2');
        System.assertEquals(2, controller.currentPageNumber);
        ApexPages.currentPage().getParameters().put(KnowledgeController.CATEGORY_PARAMETER_NAME, 'apples');
        System.assertEquals('apples', controller.currentCategory);
        ApexPages.currentPage().getParameters().put(KnowledgeController.KEYWORD_PARAMETER_NAME, 'pears');
        System.assertEquals('pears', controller.currentKeyword);
        ApexPages.currentPage().getParameters().put(KnowledgeController.ARTICLE_TYPE_PARAMETER_NAME, 'bananas');
        System.assertEquals('bananas', controller.currentArticleType);
        ApexPages.currentPage().getParameters().put(KnowledgeController.ARTICLE_TYPE_LABEL_PARAMETER_NAME, 'ananas');
        System.assertEquals('ananas', controller.currentArticleTypeLabel);
         ApexPages.currentPage().getParameters().put(KnowledgeController.P_EMAIL, 'ananas');
        System.assertEquals('ananas', controller.email);
         ApexPages.currentPage().getParameters().put(KnowledgeController.P_SUBJECT, 'ananas');
        System.assertEquals('ananas', controller.Subject);
         ApexPages.currentPage().getParameters().put(KnowledgeController.P_COMMENTS, 'ananas');
        System.assertEquals('ananas', controller.Comments);
         ApexPages.currentPage().getParameters().put(KnowledgeController.P_AD, 'ananas');
        System.assertEquals('ananas', controller.ad);
         ApexPages.currentPage().getParameters().put(KnowledgeController.P_CATEGORY_SUBJECT, 'ananas');
        System.assertEquals('ananas', controller.categorySubject);
         ApexPages.currentPage().getParameters().put(KnowledgeController.ARTICLE_TITLE, 'ananas');
        System.assertEquals('ananas', controller.PageTitle);
        
        // for coverage
        Object ss = controller.categoryParameterName;
        ss = controller.keywordParameterName;
        ss = controller.articleTypeParameterName;
        ss = controller.getURLSitemap();
        ss = controller.articleTypeLabelParameterName;
        ss = controller.pageNumberParameterName;
        ss = controller.getConvertURLString();
        ss = controller.copyEmail;
        ss = controller.contactName;
        ss = controller.getSubjectComments();
        ss = controller.IssueDescription;
        ss = controller.InternetBrowser;
        ss = controller.PhoneNumber;
        ss = controller.currentCategoryName;
        ss = controller.getHomeAdTitle();
        ss = controller.getHomeAdText();
        ss = controller.getCategoryGroupName();
        ss = controller.getCacheMaxAge();
        ss = controller.getHomeUrl();
        ss = controller.getFAQSUrl();
        ss = controller.getArticleUrl();
        ss = controller.getContactUrl();
        ss = controller.getContactOptionsUrl();
        ss = controller.getSafeUrl();
        ss = controller.getFaqUrl();
        ss = controller.getKiUrl();
        ss = controller.getGiUrl();
        ss = controller.getHomePage();
        ss = controller.getThanks();
        ss = controller.getContactPage();
        ss = controller.getFAQSPage();
        ss = controller.getContactOptionsPage();
        ss = controller.getSafePage();
        ss = controller.getFaqPage();
        ss = controller.getGiPage();
        ss = controller.getKiPage();
        ss = controller.getArticlePage();
        ss = controller.getCurrentPageReferenceReplace();
        ss = controller.getIsContactPage2();
        ss = controller.getIsArticlePage();
        ss = controller.getIsSearchContactPage();
        ss = controller.test();
        ss = controller.getCanUserSeeKnowledge(); 
        //ss = controller.preparePhoneTime('test'); 
        //controller.currentIndexPage = 1; 
        //controller.lstDisplayKnowLegde = new List<KnowledgeController.DTO_Knowlegde>();
        //ss = controller.goNext(); 
        //ss = controller.goPrevious(); 
        //KnowledgeArticleVersion kva = new KnowledgeArticleVersion(); 
        //KnowledgeController.DTO_Knowlegde dto = new KnowledgeController.DTO_Knowlegde('test', kva); 
        //ss = dto.knowlegdeArticalId; 
        //ss = dto.knowlegdeArtical; 
        //ss = dto.urlKnowledge;  
        
    }
    
    //mengsrorn 2014-04-22
    static testMethod void getOSTest(){
        String userAgentAndroid = 'Mozilla/5.0 (Linux; U; Android 4.0.3; ko-kr; LG-L160L Build/IML74K) AppleWebkit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30';
        String userAgentDesktop = 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; Trident/6.0)';
        String detectOS = '';
        
        Test.startTest();
            Test.setCurrentPage(Page.knowledgeContactSearch);
            TestKnowledgeController knowledgeCon = new TestKnowledgeController();
            
            //android user agent
            detectOS = knowledgeCon.getOS(userAgentAndroid);
            System.assertEquals(detectOS, 'Android');
            
            //desktop user agent
            detectOS = knowledgeCon.getOS(userAgentDesktop);
            System.assertEquals(detectOS, 'Desktop');
            //System.assertEquals(detectOS, 'Windows');
            
            //null user agent
            ApexPages.currentPage().getHeaders().put('HTTP_X_SKYFIRE_PHONE', userAgentAndroid);
            //System.assertEquals(knowledgeCon.getOS(null), 'Android');
            
            //unone device
            System.assertEquals('Unknown',knowledgeCon.getOS('Unknown device'));
            
        Test.stopTest();
    }

/*
    static testMethod void testSiteSetupGetters() {
        setupTest();
        PKBSiteSetup__c siteSetup = [ select id, PKBSiteName__c from PKBSiteSetup__c WHERE PKBSiteName__c = 'knowledgeGumTree' ];
        Integer i = 0;

        siteSetup.RootCategoryName__c = String.valueOf(i++);
        siteSetup.CategoryGroupName__c = String.valueOf(i++);
        siteSetup.CacheMaxAge__c = i++;
        siteSetup.Category1Description__c = String.valueOf(i++);
        siteSetup.Category2Description__c = String.valueOf(i++);
        siteSetup.Category3Description__c = String.valueOf(i++);
        siteSetup.Category4Description__c = String.valueOf(i++);
        siteSetup.Category5Description__c = String.valueOf(i++);
        siteSetup.Category6Description__c = String.valueOf(i++);
        siteSetup.HomeAdText__c = String.valueOf(i++);
        siteSetup.HomeAdTitle__c = String.valueOf(i++);
        update siteSetup;

        TestKnowledgeController controller = new TestKnowledgeController();

        System.assertEquals(siteSetup.PKBSiteName__c, controller.getSiteSetup().PKBSiteName__c);
        System.assertEquals(controller.getRootCategoryName(), siteSetup.RootCategoryName__c);
        System.assertEquals(controller.getCategoryGroupName(), siteSetup.CategoryGroupName__c);
        System.assertEquals(controller.getCacheMaxAge(), siteSetup.CacheMaxAge__c);
        System.assertEquals(controller.getHomeAdTitle(), siteSetup.HomeAdTitle__c);
        System.assertEquals(controller.getHomeAdText(), siteSetup.HomeAdText__c);
        System.assertEquals(controller.getCategoryDescriptions()[0], siteSetup.Category1Description__c);
        System.assertEquals(controller.getCategoryDescriptions()[1], siteSetup.Category2Description__c);
        System.assertEquals(controller.getCategoryDescriptions()[2], siteSetup.Category3Description__c);
        System.assertEquals(controller.getCategoryDescriptions()[3], siteSetup.Category4Description__c);
        System.assertEquals(controller.getCategoryDescriptions()[4], siteSetup.Category5Description__c);
        System.assertEquals(controller.getCategoryDescriptions()[5], siteSetup.Category6Description__c);
        
    }

    static testMethod void testGetUrls() {
        TestKnowledgeController controller = new TestKnowledgeController();
        System.assertEquals(KnowledgeController.URL_HOME, controller.getHomeUrl());
        System.assertEquals(KnowledgeController.URL_SEARCH, controller.getSearchUrl());
        System.assertEquals(KnowledgeController.URL_PRODUCT, controller.getProductUrl());
        
        System.assertEquals(KnowledgeController.URL_SAFE, controller.getSafeUrl());
        System.assertEquals(KnowledgeController.URL_CONTACT, controller.getContactUrl());
        System.assertEquals(KnowledgeController.URL_CONTACT_OPTIONS, controller.getContactOptionsUrl());
        System.assertEquals(KnowledgeController.URL_SEARCH_CONTACT, controller.getSearchUrlContact());
        System.assertEquals(KnowledgeController.URL_THANKS, controller.getThanksUrl());
        System.assertEquals(KnowledgeController.URL_CONTACT2, controller.getSearchUrlContact2());
        
    }


    static testMethod void testGetIsPage() {
        setupTest();

        Test.setCurrentPage(Page.knowledgeHome);
        TestKnowledgeController controller = new TestKnowledgeController();
        System.assert(controller.getIsHomePage());
        System.assert(!controller.getIsProductPage());
        System.assert(!controller.getIsSearchPage());
        System.assert(!controller.getIsExternalPage());       
        System.assert(!controller.getIsThanksPage());
        System.assert(!controller.getIsStaySafePage());
        System.assert(!controller.getIsContactPage());
        System.assert(!controller.getIsContactOptionsPage());        
        System.assert(!controller.getIsContactSearchPage());
        System.assert(!controller.getIsFaqPage());
        System.assert(!controller.getIsKiPage());
        System.assert(!controller.getIsGiPage());
        System.assert(!controller.getIsContactPage2());
        
        
        Test.setCurrentPage(Page.knowledgeProduct);
        controller = new TestKnowledgeController();
        System.assert(!controller.getIsHomePage());
        System.assert(controller.getIsProductPage());
        System.assert(!controller.getIsSearchPage());
        System.assert(!controller.getIsExternalPage());
        System.assert(!controller.getIsThanksPage());
        System.assert(!controller.getIsStaySafePage());
        System.assert(!controller.getIsContactPage());
        System.assert(!controller.getIsContactOptionsPage());                
        System.assert(!controller.getIsContactSearchPage());

        Test.setCurrentPage(Page.knowledgeSearch);
        controller = new TestKnowledgeController();
        System.assert(!controller.getIsHomePage());
        System.assert(!controller.getIsProductPage());
        System.assert(controller.getIsSearchPage());
        System.assert(!controller.getIsExternalPage());
        System.assert(!controller.getIsThanksPage());
        System.assert(!controller.getIsStaySafePage());
        System.assert(!controller.getIsContactPage());
        System.assert(!controller.getIsContactOptionsPage());                
        System.assert(!controller.getIsContactSearchPage());
        
        
         Test.setCurrentPage(Page.knowledgeThanks);
        controller = new TestKnowledgeController();
        System.assert(!controller.getIsHomePage());
        System.assert(!controller.getIsProductPage());
        System.assert(!controller.getIsSearchPage());
        System.debug('*************************currentpage:'+controller.currentPage);
        System.assert(controller.getIsThanksPage());
        System.assert(!controller.getIsStaySafePage());
        System.assert(!controller.getIsContactPage());
        System.assert(!controller.getIsContactOptionsPage());                
        System.assert(!controller.getIsContactSearchPage());
       
        Test.setCurrentPage(Page.knowledgeContact);
        controller = new TestKnowledgeController();
        System.assert(!controller.getIsHomePage());
        System.assert(!controller.getIsProductPage());
        System.assert(!controller.getIsSearchPage());
        System.assert(!controller.getIsStaySafePage());
        System.assert(controller.getIsContactPage());
        System.assert(!controller.getIsContactOptionsPage());                
        System.assert(!controller.getIsContactSearchPage());
        
        Test.setCurrentPage(Page.knowledgeContactSearch);
        controller = new TestKnowledgeController();
        System.assert(!controller.getIsHomePage());
        System.assert(!controller.getIsProductPage());
        System.assert(!controller.getIsSearchPage());
        System.assert(!controller.getIsStaySafePage());
        System.assert(!controller.getIsContactPage());
        System.assert(!controller.getIsContactOptionsPage());                
        System.assert(controller.getIsContactSearchPage());
        
        
        Test.setCurrentPage(Page.knowledgeSafe);
        controller = new TestKnowledgeController();
        System.assert(!controller.getIsHomePage());
        System.assert(!controller.getIsProductPage());
        System.assert(!controller.getIsSearchPage());
        System.assert(controller.getIsStaySafePage());
        System.assert(!controller.getIsContactPage());
        System.assert(!controller.getIsContactOptionsPage());                
        System.assert(!controller.getIsContactSearchPage());
        
        
        Test.setCurrentPage(Page.KnowledgeFAQ);
        controller = new TestKnowledgeController();
        System.assert(!controller.getIsHomePage());
        System.assert(!controller.getIsProductPage());
        System.assert(!controller.getIsSearchPage());
        System.assert(!controller.getIsExternalPage());       
        System.assert(!controller.getIsThanksPage());
        System.assert(!controller.getIsStaySafePage());
        System.assert(!controller.getIsContactPage());
        System.assert(!controller.getIsContactOptionsPage());        
        System.assert(!controller.getIsContactSearchPage());
        System.assert(controller.getIsFaqPage());
        System.assert(!controller.getIsKiPage());
        System.assert(!controller.getIsGiPage());
        System.assert(!controller.getIsContactPage2());
        
        
        Test.setCurrentPage(Page.KnowledgeGI);
        controller = new TestKnowledgeController();
        System.assert(!controller.getIsHomePage());
        System.assert(!controller.getIsProductPage());
        System.assert(!controller.getIsSearchPage());
        System.assert(!controller.getIsExternalPage());       
        System.assert(!controller.getIsThanksPage());
        System.assert(!controller.getIsStaySafePage());
        System.assert(!controller.getIsContactPage());
        System.assert(!controller.getIsContactOptionsPage());                
        System.assert(!controller.getIsContactSearchPage());
        System.assert(!controller.getIsFaqPage());
        System.assert(!controller.getIsKiPage());
        System.assert(controller.getIsGiPage());
        System.assert(!controller.getIsContactPage2());
        
        Test.setCurrentPage(Page.KnowledgeKI);
        controller = new TestKnowledgeController();
        System.assert(!controller.getIsHomePage());
        System.assert(!controller.getIsProductPage());
        System.assert(!controller.getIsSearchPage());
        System.assert(!controller.getIsExternalPage());       
        System.assert(!controller.getIsThanksPage());
        System.assert(!controller.getIsStaySafePage());
        System.assert(!controller.getIsContactPage());
        System.assert(!controller.getIsContactOptionsPage());                
        System.assert(!controller.getIsContactSearchPage());
        System.assert(!controller.getIsFaqPage());
        System.assert(controller.getIsKiPage());
        System.assert(!controller.getIsGiPage());
        System.assert(!controller.getIsContactPage2());
        
        Test.setCurrentPage(Page.KnowledgeContact2);
        controller = new TestKnowledgeController();
        System.assert(!controller.getIsHomePage());
        System.assert(!controller.getIsProductPage());
        System.assert(!controller.getIsSearchPage());
        System.assert(controller.getIsExternalPage());       
        System.assert(!controller.getIsThanksPage());
        System.assert(!controller.getIsStaySafePage());
        System.assert(!controller.getIsContactPage());
        System.assert(!controller.getIsContactOptionsPage());                
        System.assert(!controller.getIsContactSearchPage());
        System.assert(!controller.getIsFaqPage());
        System.assert(!controller.getIsKiPage());
        System.assert(!controller.getIsGiPage());
        System.assert(controller.getIsContactPage2());
    }


    static testMethod void testGetPage() {
        TestKnowledgeController controller = new TestKnowledgeController();
        System.assertEquals('', controller.getPage(''));
        System.assertEquals('', controller.getPage('/'));
        System.assertEquals('', controller.getPage('//'));
        System.assertEquals('', controller.getPage('/?'));
        System.assertEquals('', controller.getPage('/?a=1'));
        System.assertEquals('', controller.getPage('/?a=1&b=2'));
        System.assertEquals('foo', controller.getPage('foo'));
        System.assertEquals('foo', controller.getPage('/foo'));
        System.assertEquals('foo', controller.getPage('//foo'));
        System.assertEquals('foo', controller.getPage('/foo/'));
        System.assertEquals('foo', controller.getPage('//foo//'));
        System.assertEquals('foo', controller.getPage('/apex/foo'));
        System.assertEquals('foo', controller.getPage('/apex/foo/'));
        System.assertEquals('foo', controller.getPage('/foo?'));
        System.assertEquals('foo', controller.getPage('/foo?a=1'));
        System.assertEquals('foo', controller.getPage('/foo?a=1&b=2'));
        System.assertEquals('foo', controller.getPage('/foo/?'));
        System.assertEquals('foo', controller.getPage('/foo/?a=1'));
        System.assertEquals('foo', controller.getPage('/foo/?a=1&b=2'));
        System.assertEquals('foo', controller.getPage('apex/foo/?'));
        System.assertEquals('foo', controller.getPage('apex/foo/?a=1'));
        System.assertEquals('foo', controller.getPage('apex/foo/?a=1&b=2'));
        System.assertEquals('foo', controller.getPage('/apex/foo/?'));
        System.assertEquals('foo', controller.getPage('/apex/foo/?a=1'));
        System.assertEquals('foo', controller.getPage('/apex/foo/?a=1&b=2'));
    }
*/
    static testMethod void testActions() {
        // do search
        setupTest();
        Test.setCurrentPage(Page.knowledgeProduct);
        TestKnowledgeController controller = new TestKnowledgeController();
        controller.currentCategory = 'apples';
        controller.currentKeyword = 'pears';
        PageReference pg = controller.doSearch();
        System.assertEquals('pears', controller.currentKeyword);
        System.assertEquals('apples', controller.currentCategory);
        System.assertEquals(controller.getSearchPage(), controller.getPage(pg.getUrl()));

        // keyword too short
        Test.setCurrentPage(Page.knowledgeProduct);
        controller.currentCategory = 'apples';
        controller.currentKeyword = '1';
        pg = controller.doSearch();
        System.assertEquals('apples', controller.currentCategory);
        System.assertEquals('', controller.currentKeyword);
        System.assertEquals(controller.getProductPage(), controller.getPage(pg.getUrl()));
        
        // clean Keyword
        Test.setCurrentPage(Page.knowledgeSearch);
        controller.currentCategory = 'apples';
        controller.currentKeyword = 'pears';
        pg = controller.cleanKeyword();
        System.assertEquals('apples', controller.currentCategory);
        System.assertEquals('', controller.currentKeyword);
        System.assertEquals(controller.getProductPage(), controller.getPage(pg.getUrl()));
        
        
        //Next
         Test.setCurrentPage(Page.knowledgeContact);
          pg=controller.doSearchContact();
         controller.Subject='apples';
         pg=controller.doSearchContact();
         controller.categorySubject='Help with my paid Job ad/ Job account';
         pg=controller.doSearchContact();
         System.assertEquals('apples', controller.Subject);
         System.assertEquals('Help with my paid Job ad/ Job account', controller.categorySubject);
         System.assertEquals(controller.getContactSearchPage(), controller.getPage(pg.getUrl()));
         
         
         
         //Submit Contact
         Test.setCurrentPage(Page.knowledgeContact);
          pg=controller.doSaveCase();
         controller.Comments='apples';
         pg=controller.doSaveCase();
         controller.email='test@test.com';
         pg=controller.doSaveCase();
         controller.categorySubject='Feedback/ suggestions';
         pg=controller.doSaveCase();
         //System.assertEquals(controller.getThanks(), controller.getPage(pg.getUrl()));
        
         

        //Submit Contact Issue
        /*
         Test.setCurrentPage(Page.knowledgeContact);
          pg=controller.doSaveCaseIssue();
         controller.Comments='apples';
         pg=controller.doSaveCaseIssue();
         controller.email='test@test.com';
         pg=controller.doSaveCaseIssue();
         controller.categorySubject='Feedback/ suggestions';
         pg=controller.doSaveCaseIssue();
         controller.IssueDescription='bla';
          pg=controller.doSaveCaseIssue();
         System.assertEquals(controller.getThanks(), controller.getPage(pg.getUrl()));
        
         DataCategory__c dc=controller.getDc();
         */
         
         //Submit ContactSearch
         Test.setCurrentPage(Page.knowledgeContactSearch);
         pg=controller.doSaveCaseBis();
         controller.Comments='apples';
         pg=controller.doSaveCaseBis();
         controller.email='test@test.com';
         pg=controller.doSaveCaseBis();
         controller.categorySubject='Feedback/ suggestions';
         pg=controller.doSaveCaseBis();
         controller.Subject='apples';
         pg=controller.doSaveCaseBis();
         //System.assertEquals(controller.getThanks(), controller.getPage(pg.getUrl()));
     
         controller.getFinalsOptions();
         controller.getFinalsOptions2();
         controller.getErrorMessage();
         controller.getEmail();
         controller.getSiteSetup();
         controller.getCategoryDescriptions();
         controller.getDC();
         controller.doSearch();
         controller.doSearchContact2();
         controller.browserDetails();
         controller.getAnswer();
         
         //inValidThird
         ApexPages.currentPage().getHeaders().put('HTTP_X_SKYFIRE_PHONE','Mozilla/5.0 (Linux; U; Android 4.0.3; ko-kr; LG-L160L Build/IML74K) AppleWebkit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30');
         controller.categorySubject = 'General Enquiry';
         controller.categoryTopic = 'Question about my Free Ad';
         controller.confirm_email = 'test@gmail.com';
         controller.email = controller.confirm_email;
         System.debug('>>>>>>isValidThird: '+controller.isValidThird());
         System.debug('>>>>strErrorMessage: '+controller.strErrorMessage);
         System.debug('>>>>categorySubject: '+controller.categorySubject);
         controller.doSaveCase();
         
         controller.categorySubject = 'Technical Issue';
         controller.doSaveCase();
         
         controller.categorySubject = 'Featured Ad';
         controller.categoryTopic = 'Question about my Paid Ad';
         controller.doSaveCase();
         
         controller.categorySubject = 'Job Ad';
         controller.doSaveCase();
         
         controller.categorySubject = 'Housing Ad';
         controller.doSaveCase();
         
         controller.categorySubject = 'Business Services Ad';
         controller.doSaveCase();
         
         controller.categorySubject = 'Motors Ad';
         controller.doSaveCase();
         /*
         controller.categorySubject = 'Ad';
         controller.categoryTopic = 'Report Fraud/Scam/Abuse';
         controller.doSaveCase();
         
         controller.categorySubject = 'Reply';
         controller.doSaveCase();
         
         controller.categorySubject = 'Other';
         controller.doSaveCase();
         
         controller.categoryTopic = 'Question about Replying to Ads';
         controller.doSaveCase();
        try{
         controller.categoryTopic = 'General Feedback';
         controller.doSaveCase();
        }catch(Exception e){}
        //isValidSecond
        controller.strErrorMessage = '';
        controller.categorySubject = 'General Enquiry';
        controller.ad = 'dflsafj';
        controller.isSelectedNO = false;
        controller.isIgnoreSubject = 'true';
        System.debug('>>>>>>isValidSecond: '+controller.isValidSecond());
        System.debug('>>>>>>>strErrorMessage: '+controller.strErrorMessage);
         controller.categorySubject = 'General Enquiry';
         controller.categoryTopic = 'Question about my Free Ad';
         controller.doSaveCaseBis();
         
         controller.categorySubject = 'Technical Issue';
         controller.doSaveCaseBis();
         
         controller.categorySubject = 'Featured Ad';
         controller.categoryTopic = 'Question about my Paid Ad';
         controller.doSaveCaseBis();
         
         controller.categorySubject = 'Job Ad';
         controller.doSaveCaseBis();
         
         controller.categorySubject = 'Housing Ad';
         controller.doSaveCaseBis();
         
         controller.categorySubject = 'Business Services Ad';
         controller.doSaveCaseBis();
         
         controller.categorySubject = 'Motors Ad';
         controller.doSaveCaseBis();
         
         controller.categorySubject = 'Ad';
         controller.categoryTopic = 'Report Fraud/Scam/Abuse';
         controller.doSaveCaseBis();
         
         controller.categorySubject = 'Reply';
         controller.doSaveCaseBis();
         
         controller.categorySubject = 'Other';
         controller.doSaveCaseBis();
         
         controller.categoryTopic = 'Question about Replying to Ads';
         controller.doSaveCaseBis();
         
         controller.categoryTopic = 'General Feedback';
         controller.doSaveCaseBis();
         */
         //isValidFirst
         controller.Subject = 'Motors Ad';
         controller.categorySubject = 'test';
         System.debug('>>>>>isValidFirst: '+controller.isValidFirst());
         System.debug('>>>>>>strErrorMessage: '+controller.strErrorMessage);
         controller.doSearchContact();
         controller.doSearchContact2();
         
         
         //isValidFirst = false
         controller.Subject = 'a';
         controller.isValidFirst();
         
         controller.Subject = 'Example: \'I can?t find my ad\'';
         controller.isValidFirst();
         
         controller.Subject = 'fsafsadfaf';
         controller.categoryTopic = 'Question about my paid ad';
         controller.isValidFirst();
         
         controller.categoryTopic = 'Ad';
         controller.isValidFirst();
         
         controller.categoryTopic = 'fdsafafa';
         controller.categorySubject = '';
         controller.isValidFirst();
         
         //isValidSecond = false
         controller.Subject = 'a';
         controller.isValidSecond();
         
         controller.Subject = 'Example: \'I can?t find my ad\'';
         controller.isSelectedNO = true;
         controller.isValidSecond();
         
         controller.Subject = 'fsafsada';
         controller.categoryTopic = 'Question about my paid ad';
         controller.ad = '';
         controller.isValidSecond();
         
         controller.categoryTopic = 'Ad';
         controller.isValidSecond();
         
         controller.categoryTopic = 'fsafsafdsadfa';
         controller.categorySubject = '';
         controller.isIgnoreSubject = 'flasdkfja';
         controller.isValidSecond();
         
         controller.isIgnoreSubject = 'true';
         controller.email = 'test';
         controller.isValidSecond();
         
         controller.email = 'test@gmail.com';
         controller.confirm_email = 'test1@gmail.com';
         controller.isValidSecond();
         
         controller.getIsFaqPage();
         controller.getIsKiPage();
         controller.getIsGiPage();
         controller.getIsThanksPage();
         controller.getIsStaySafePage();
         controller.getIsContactPage();
         controller.getIsContactOptionsPage();
         controller.getIsContactSearchPage();
         
         //isValidThird = false
         controller.Comments = 'a';
         controller.isValidThird();
         
         controller.Comments = 'affsldkafjalsdjfa';
         controller.categorySubject = '';
         controller.isValidThird();
         
         controller.categorySubject = 'fsafasdfsaf';
         controller.email = 'test';
         controller.isValidThird();
         
         controller.email = 'test@gmail.com';
         controller.confirm_email = 'test1@gmail.com';
         controller.isValidThird();
         
         
         Test.setCurrentPage(Page.knowledgeSearch);
         Apexpages.currentPage().getParameters().put('k','test new video');
         try{
            controller = new TestKnowledgeController();
         }catch(Exception e){}
    }

    public class TestKnowledgeController extends KnowledgeController {
        public TestKnowledgeController(){
            super();
        }
    }
}