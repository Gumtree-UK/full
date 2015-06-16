/**
 *  Class for test coverage code of all classes that have prefix "P2P"
 *  @createDate : 21-Jan-2015
 *  @author: Pheaktra Hun
 */
@isTest
public class P2P_UnitTest {
    
    private static User activeUser;
    public static Account acc;
    public static Community community;
    
    public static String imageBase64Prefix = 'data:image/jpeg;base64,';
    public static String base64Str = '/9j/4AAQSk';
    public static String invIdsJsonStr;
    
    //P2P_MyFinancialsController, P2P_MyFinancialsPaymentController, P2P_ExportStatementFilter
    public static void setUpdataTestAll(){
        Profile p=[Select Id From Profile Where Name='System Administrator' or Name='Systemadministrator' Limit 1];
        UserRole r=[Select Id From UserRole Limit 1];
        //activeUser = new User(alias = 'u2', email = 'test@test.com', emailencodingkey = 'UTF-8',
        //                    FirstName = 'test' , lastname='U', languagelocalekey = 'en_US',
        //                    localesidkey = 'en_US', profileid = p.Id, timezonesidkey = 'America/Los_Angeles', CommunityNickname = 'u2',
        //                    isActive = false, username = 'testP2P@test.com', UserRoleId = r.Id);
        //insert activeUser;
        activeUser = [Select Id From User Where Id =: UserInfo.getUserId()];
        
        List<Community>lstCommunities = [Select Id From Community where Name ='Customer Community' and IsActive = true];
        community = lstCommunities.isEmpty() ? null : lstCommunities.get(0);
        
        Account accTest = new Account(Name='testAccHelp', BillingStreet='Street', BillingCity='City', BillingCountry='HT', BillingPostalCode='ZipCode', AccountNumber='3317');
        insert accTest;
        
        //custom setting
        insert new Fiqas_Settings__c(Name='Webservice', Endpoint__c='https://ebayapiuat.billing.nl/adaptapi.asmx/', Key__c='43aa687f7ac4c184f2f1863b8ffbfdbd', User__c='testgumtree', Http_header__c='ebayapiuat.billing.nl', Fiqas_UAT__c='');
        insert new P2P_RequestAdImage__c(Name='Default Ad image', EndPoint__c='https://inbound.gumtree.com', Signature_Algorithm__c='hmacSHA256');
        insert new Gumtree_Settings__c(Name='Webservice', Endpoint__c='http://tapi.qa2.gumtree.com', AccessKey__c='29d7d11814e3ee5157d723e64c5e8566', PrivateKey__c='c467dcc283530c8662f0e81990dfce36');
        
        insert new Config_Settings__c(Name=CustomSettingsManager.GT_HELP_ACCOUNT_ID, Description__c='Test', Checkbox_Value__c=true, Text_Value__c=accTest.Id);
        insert new Config_Settings__c(Name=CustomSettingsManager.OPP_EXPIRY_DATE_TO_CON_TRIG_ENABLED, Description__c='Test', Checkbox_Value__c=true);
        insert new Config_Settings__c(Name=CustomSettingsManager.CREATE_CONTACT_IN_CASE_TRIGGER_ENABLED, Description__c='Test', Checkbox_Value__c=false);
        
        Contact conPrim = new Contact(LastName = 'TestPrimary', FirstName = 'first', Email = 'testPrim@test.com');
        insert conPrim;
        
        acc = new Account(Primary_Contact__c = conPrim.Id, Name='Unit Test', BillingStreet='Street', BillingCity='City', BillingCountry='HT', BillingPostalCode='ZipCode', AccountNumber='3317', Company_Logo__c=imageBase64Prefix+base64Str, BAPI_Key__c='0c12b40391ccdfb890811dfa745466e8', Private_Key__c='e8529cecd22b9e4c1343ab5e7e0a858c');
        insert acc;
        
        insert new P2P_Pricebook2Account__c(Name='Job_Account', Map_2_Pricebook_Name__c='Job_Account');
        insert new P2P_AccGetOppRecTyp__c(Name='Job_Account', OppRecTypName__c='Self-serve initiation (J)');
        
        List<Invoices__c>lstInsertInvs = new List<Invoices__c>();
        for(Integer i=0;i<2;i++){
            lstInsertInvs.add(new Invoices__c(Name='GT'+i, Account__c=acc.Id, Age__c=31));
        }
        insert lstInsertInvs;
        
        invIdsJsonStr = JSON.serialize(new List<String>{lstInsertInvs.get(0).Id, lstInsertInvs.get(1).Id});
        
        Apexpages.currentPage().getParameters().put('id', acc.Id);
    }
    
    public static testmethod void testMyFinancial(){
        setUpdataTestAll();
        setupData();
        P2P_MyFinancialsController finanCon = new P2P_MyFinancialsController();
        List<PKB_Status_Message__c>lstMsgs = finanCon.msgErr;
        finanCon.sortByField = 'Invoice_Status__c';
        
        //Financial Payment Test
        Apexpages.currentPage().getParameters().put('selInv', invIdsJsonStr);
        P2P_MyFinancialsPaymentController finanPayment = new P2P_MyFinancialsPaymentController();
        finanPayment.removeIndex = 0;
        
        //Financial Export Excel Test
        Apexpages.currentPage().getParameters().put('acctid', acc.Id);
        new P2P_ExportStatementFilter();
        
        System.runAs(activeUser){
            Test.startTest();
                finanCon.receiveInvoices();
                finanCon.filterChange();
                finanCon.groupCheckChange();
                finanCon.sortInvoice();
                finanCon.onSelectPayment();
                finanCon.requestPDFBody();
                
                finanCon.goToPage();
                finanCon.goNextPage();
                finanCon.goPreviousPage();
                finanCon.getEndIndex();
                finanCon.getTotalResultSize();
                finanCon.getTotalPageSize();
                finanCon.getPrevRequired();
                finanCon.getNextRequired();
                
                finanPayment.removeSelectedInvoice();
                finanPayment.requestPDFBody();
                finanPayment.getInstanceUrl();
            Test.stopTest();
        }
    }   
    
    //P2P_MyCompanyController
    private static void setUpDataTestCompany(){
        insert new Contact(LastName='Primary & Financial Contact', Primary_Contact__c=true, Finance_Contact__c=true, AccountId=acc.Id);
        
        List<Contact>lstInsertCons = new List<Contact>();
        for(Integer i=0;i<10;i++){
            lstInsertCons.add(new Contact(LastName='Contact'+i));
        }
        insert lstInsertCons;
        
        Contact conAdd = new Contact(LastName='test Add Contact', Primary_Contact__c=true, Finance_Contact__c=true, Email='test@gmail.com', Contact_Status__c='Left Company', AccountId=acc.Id);
        insert conAdd;
    }

    public static testmethod void testMyCompany(){
        setUpdataTestAll();
        setUpDataTestCompany();
        P2P_MyCompanyController comCon = new P2P_MyCompanyController();
        List<PKB_Status_Message__c>lstMsgs = comCon.msgErr;
        System.runAs(activeUser){
            Test.startTest();
            
                comCon.addComContact();
                comCon.contactAdd.LastName = 'test Add Contact';
                comCon.contactAdd.Email = 'test@gmail.com';
                comCon.contactAdd.Profile_Photo__c = imageBase64Prefix + base64Str;
                comCon.editedIndex = 0;
                
                comCon.filterChange();
                comCon.editProfile();
                comCon.cancelEditProfile();
                comCon.saveProfile();
                comCon.saveAdImage();
                comCon.uploadAdImage();
                comCon.deleteAdImage();
                comCon.cancelAddComContact();
                comCon.saveNewContact();
                comCon.editedComContact();
                comCon.cancelEditedComContact();
                comCon.saveEditedComContact();
                comCon.getContactType();
                comCon.getContactStatus();
                comCon.getBillingAddressDisplay();
                comCon.getBillingAddress();
                comCon.sortComContact();
                
                comCon.getEndIndex();
                comCon.getTotalResultSize();    
                comCon.getTotalPageSize();
                comCon.goToPage();
                comCon.goNextPage();
                comCon.goPreviousPage();
                comCon.getPrevRequired();
                comCon.getNextRequired();
            
            Test.stopTest();
        }
    }
    
    //P2P_MyMetricsController, P2P_MyMetriceExcelController, P2P_MyMetricsPDFController
    private static Metrics_Dashboard__c md;
    private static void setTestDataMetrics(){
        List<Performance_Metrics__c>lstInsertPMs = new List<Performance_Metrics__c>();
        for(Integer i=1;i<5;i++){
            lstInsertPMs.add(new Performance_Metrics__c(Account__c=acc.Id, Date__c=Date.today().addDays(-i)));
        }
        insert lstInsertPMs;
        
        md = new Metrics_Dashboard__c(Account__c=acc.Id, Chart_Title__c='test', Chart_Description__c='test', Timeframe__c='Month on month', Chart_Type__c='Bar', 
                                        Period__c='Current & previous year', Data_Point_A__c='Live ads', Location_A__c='Nationwide');
        insert md;
    }

    public static testmethod void testMyMetrics(){
        setUpdataTestAll();
        setTestDataMetrics();
        P2P_MyMetricsController metricsCon = new P2P_MyMetricsController();
        List<PKB_Status_Message__c>lstMsgs = metricsCon.msgErr;
        
        metricsCon.deleteAttChart();
        metricsCon.newDashBoard.Data_Point_A__c = 'Live ads';
        metricsCon.newDashBoard.Location_A__c = 'Nationwide';
        metricsCon.pickFromDate = Datetime.now().addDays(-1).format('dd/MM/yyyy');
        metricsCon.pickUtilDate = Datetime.now().format('dd/MM/yyyy');
        metricsCon.saveIndex = 1;
        
        P2P_MyMetricsController.createAttChartImage('gchart1', 'Body', md.Id);
        
        //Excel Test
        Apexpages.currentPage().getParameters().put('accId', acc.Id);
        Apexpages.currentPage().getParameters().put('filter', metricsCon.getJsonStrFilter());
        new P2P_MyMetricsExcelController();
        
        //PDF Test
        new P2P_MyMetricsPDFController();
        
        System.runAs(activeUser){
            Test.startTest();
            
                //Ads Dashboard
                metricsCon.refreshNewChartData();
                metricsCon.saveNewChart();
                metricsCon.saveSortCharts();
                metricsCon.refreshEditChartData();
                metricsCon.cancelSortCharts();
                metricsCon.saveEditChart();
                metricsCon.cancelAddOrEditChart();
                metricsCon.deleteChart();
                
                //Ads Breakdown
                metricsCon.refreshTable();
                
                metricsCon.displayType = 'Quarter';
                metricsCon.refreshTable();
                
                metricsCon.displayType = 'Year';
                metricsCon.refreshTable();
                
                metricsCon.getEndIndex();
                metricsCon.getTotalResultSize();
                metricsCon.getTotalPageSize();
                metricsCon.goToPage();
                metricsCon.goNextPage();
                metricsCon.goPreviousPage();
                metricsCon.getPrevRequired();
                metricsCon.getNextRequired();
                metricsCon.getLocations();
                metricsCon.getDisplayTypePicklist();
                
            Test.stopTest();
        }
    }
    
    //P2P_MySupportController, P2P_Utils, P2P_VoteIdea
    private static Idea idea;
    private static P2P_DtoIdea voteDown;
    private static Set<Id>setKAIDs;
    private static String caseId;
    
    public static void setUpDataMySupport(){
        List<FAQ__kav>lstArtInsert = new List<FAQ__kav>();
        for(Integer i=0;i<13;i++){
            FAQ__kav faq = new FAQ__kav(Title='Test'+i, UrlName='test-addArticle'+i);
            lstArtInsert.add(faq);
        }
        insert lstArtInsert;
        
        setKAIDs = new Set<Id>();
        List<FAQ__DataCategorySelection>lstInsertDataCategories = new List<FAQ__DataCategorySelection>();
        for(FAQ__kav faq : lstArtInsert){
            setKAIDs.add(faq.Id);
            lstInsertDataCategories.add(new FAQ__DataCategorySelection(DataCategoryGroupName='Public_KB', ParentId=faq.Id, DataCategoryName='General'));
        }
        insert lstInsertDataCategories;
        
        Idea ide = new Idea(Title='testIdea', CommunityId=community.Id, Status='New');
        insert ide;
        
        Idea ide1 = new Idea(Title='testIdea1', CommunityId=community.Id, Status='New');
        insert ide1;
        
        //create new case
        Config_Settings__c cs = [Select Checkbox_Value__c From Config_Settings__c Where Name=:CustomSettingsManager.CREATE_CONTACT_IN_CASE_TRIGGER_ENABLED];
        cs.Checkbox_Value__c = false;
        update cs;
        List<RecordType> lstRecords= [Select id From RecordType r where SobjectType='Case' and DeveloperName = 'Customer_Services'];
        Case caseRec = new Case( Status= 'New' , RecordTypeId =lstRecords.get(0).id , Origin= 'Test' ,Posting_Reference__c= 'TestCase' );
        insert caseRec ;
        caseId = caseRec.Id;
    }

    public static testmethod void testMySupport(){
        setUpdataTestAll();
        System.runAs(activeUser){
            setUpDataMySupport();
            Apexpages.currentPage().getParameters().put('accId', acc.Id);
            Apexpages.currentPage().getParameters().put('article', 'test-addArticle1');
            ApexPages.currentPage().getHeaders().put('User-Agent', 'windows');
            
            //P2P_MySupportController.PUBLISH_STATUS = 'Draft';
            P2P_MySupportController suppCon = new P2P_MySupportController();
            
            P2P_VoteIdea vIdeaCon = new P2P_VoteIdea();
            vIdeaCon.dtoIdea = new P2P_DtoIdea( new Idea(), 0, false, false, 0);
            vIdeaCon.dtoIdea.voteTotal = 0;
            vIdeaCon.thumbsUp();
            vIdeaCon.thumbsDown();
            
            String attId = P2P_MySupportController.createAttachment('CreateAtt', imageBase64Prefix + base64Str, acc.Id, 'images/png');
            P2P_MySupportController.createChunkAttachment(attId, 'CreateAtt', base64Str, acc.Id, 'images/png');
            
            List<PKB_Status_Message__c>lstMsgs = suppCon.msgErr;
            suppCon.detailCaseId = caseId;
            suppCon.searchTxt = 'Test';
            suppCon.selectedIndex = 0;
        
            Test.startTest();
                //Faq
                suppCon.doSearchArticles();
                suppCon.goBack();
                
                suppCon.goToPageFaq();
                //suppCon.goNextPageFaq();
                //suppCon.goPreviousPageFaq();
                
                //Contact
                suppCon.cancelCreateNewCase();
                suppCon.caseTypeChange();
                suppCon.createNewCase();
                suppCon.submitCase();
                suppCon.submitListChanged();
                suppCon.searchKeyWordCase();
                suppCon.sortCase();
                suppCon.backToListCase();
                suppCon.submitListCaseCommentChanged();
                suppCon.submitCaseComment();
                suppCon.doMarkAsResolved();
                
                suppCon.getEndIndexCase();
                suppCon.gettotalResultSizeCase();
                suppCon.getTotalPageSizeCase();
                suppCon.goToPageCase();
                suppCon.goNextPageCase();
                suppCon.goPreviousPageCase();
                suppCon.goFirstPageCase();
                suppCon.goLastPageCase();
                suppCon.getPrevRequiredCase();
                suppCon.getNextRequiredCase();
                suppCon.getFirstRequiredCase();
                suppCon.getLastRequiredCase();
                
                //Idea
                suppCon.submitListIdeaChanged();
                suppCon.postIdea();
                suppCon.idea.Title = 'testIdea';
                
                suppCon.submitIdea();
                suppCon.showDetail();
                
                suppCon.createIdeaComment();
                suppCon.submitListIdeaCommentChanged();
                suppCon.hideDetail();
                suppCon.cancelPostIdea();
                suppCon.sortIdea();
                
                suppCon.getEndIndexIdea();
                suppCon.gettotalResultSizeIdea();
                suppCon.getTotalPageSizeIdea();
                suppCon.goToPageIdea();
                suppCon.goNextPageIdea();
                suppCon.goPreviousPageIdea();
                suppCon.goFirstPageIdea();
                suppCon.goLastPageIdea();
                suppCon.getPrevRequiredIdea();
                suppCon.getNextRequiredIdea();
                suppCon.getFirstRequiredIdea();
                suppCon.getLastRequiredIdea();
                
            Test.stopTest();
        }
    }
    
    //P2P_MyCheckoutController, P2P_MyCheckOutPaymentController
    public static Advertising_Medium__c am;
    private static void testDataCheckout(){
        insert new Pricebook2(Name='Job_Account');
        
        am = new Advertising_Medium__c(Name='test');
        insert am;
        
        Site__c si = new Site__c(Name='test', Active__c=true, Country__c='UK', SortOrder__c=1);
        insert si;
        
        Product2 p2 = new Product2(Name='test', Product_Type__c='Jobs', Advertising_Medium__c=am.Id, Site__c=si.Id);
        insert p2;
        
        Rate_Card__c rc = new Rate_Card__c(Sales_Price__c=0.5, Quantity2__c=2, Product__c=p2.Id, Length__c='1', Active__c=true);
        insert rc;
        
        PricebookEntry pbe = new PricebookEntry(UnitPrice=10, Product2Id=p2.Id, Pricebook2Id=Test.getStandardPricebookId(), IsActive=true);
        insert pbe;
        
        Media_Basket__c mb = new Media_Basket__c(Account_Id__c=acc.Id, Stage__c='New', Product_ID__c=p2.Id, PriceBookEntryIdText__c=pbe.Id, Length_Months__c=1, 
                                                Quantity__c=2,Product_Group_Name__c='test', from_Date__c=Date.today(), Net_Net_Net__c=100, 
                                                Sales_Price_Target__c=10, From_Site__c=true);
        insert mb;
    }
        
    public static testmethod void testMyCheckOut(){
        setUpdataTestAll();
        testDataCheckout();
        Apexpages.currentPage().getParameters().put('id', acc.Id);
        P2P_MyCheckoutController checkOutCon = new P2P_MyCheckoutController();
        List<PKB_Status_Message__c>lstMsgs = checkOutCon.msgErr;
        checkOutCon.indexProGroupSel = 0;
        checkOutCon.indexSubPro = 0;
        checkOutCon.adid = am.Id;
        checkOutCon.lstBasketRows.get(0).selected = false;
        
        P2P_MyCheckOutPaymentController checkOutPay = new P2P_MyCheckOutPaymentController();
        checkOutPay.indexProGroupSel = 0;
        checkOutPay.indexSubPro = 0;
        
        System.runAs(activeUser){
            Test.startTest();
                checkOutCon.getRelatedProducts();
                checkOutCon.doContinue2Checkout();
                checkOutCon.lstBasketRows[0].basketItems[0].startDate = P2P_Utils.dateToStringWithFormat(Date.today(), 'dd/MM/yyyy');
                checkOutCon.calculatePrice();
                checkOutCon.advMedium();
                
                //MyCheckOutPayment
                checkOutPay.lstBasketRows[0].basketItems[0].startDate = P2P_Utils.dateToStringWithFormat(Date.today(), 'dd/MM/yyyy');
                checkOutPay.reCalculateAndUpdateMedia();
                checkOutPay.feedSetupUpdateMB();
                checkOutPay.doPayByCard();
                checkOutPay.doPayByInvoice();
                checkOutPay.doPayByPaypal();
                checkOutPay.validatePromoCode();
                checkOutPay.removeMediabasket();
                
                checkOutCon.removeSubProduct();
                checkOutCon.removeProducts();
            
            Test.stopTest();
        }
    }
    
    //Test P2P_URLRewriter
    public static testMethod void testGenerateUrlFor() {
        setUpdataTestAll();
        P2P_URLRewriter rewriter = new P2P_URLRewriter();
        PageReference pageRef ;//= new PageReference('/p2p_mycompany');
        
        List<PageReference> lsPageRef = new List<PageReference>();
        
        lsPageRef.add(new PageReference('/ads'));
        lsPageRef.add(new PageReference('/p2p_mycompany'));
        lsPageRef.add(new PageReference('/p2p_myfinancials'));
        lsPageRef.add(new PageReference('/p2p_myfinancialspayment'));
        lsPageRef.add(new PageReference('/p2p_mymetrics'));
        lsPageRef.add(new PageReference('/p2p_mycheckout'));
        lsPageRef.add(new PageReference('/p2p_mycheckoutpayment'));
        lsPageRef.add(new PageReference('/p2p_mysupport'));
        
        //System.assert(test == '/company');
        list<Pagereference> test = rewriter.generateUrlFor(lsPageRef);
        // TO DO: implement unit test
    }
    
    
    public static testMethod void testMapNonVipUrl() {
        setUpdataTestAll();
        P2P_URLRewriter rewriter = new P2P_URLRewriter();
        
        String actualResult = rewriter.mapRequestUrl(new PageReference('/company')).getUrl();
        //String expectedResult = '/testUrl';
        System.assert(actualResult == '/p2p_mycompany');
    }
    
    
    /**
     *  Test P2P_PayToBraintree
     *  - P2P_BraintreeServices.cls
     *  - P2P_BraintreeHelper.cls
     *  - P2P_PayToBraintree.cls
     *
     * @author Kakada Khan 
     * @date 16-Feb-2015
     */
    // This variable will be set to any response xml in test method
    public static String response4Test;
    
    private static final String RES_TOKEN = '<?xml version="1.0" encoding="UTF-8"?>'+
                                           '<client-token>'+
                                              '<value>eyJ2ZX</value>'+
                                           '</client-token>' ;
    
    private static final String RES_CUSTOMER = '<?xml version="1.0" encoding="UTF-8"?>'+
                                               '<customer>' +
                                                      '<id>16681806</id>' + 
                                                      '<credit-cards type="array">' +
                                                            '<credit-card>' + 
                                                              '<bin>450060</bin>'+
                                                              '<default type="boolean">true</default>' +
                                                              '<card-type>Visa</card-type>'+
                                                              '<last-4>0061</last-4>'+
                                                              '<image-url>https://assets.braintreegateway.com/payment_method_logo/visa.png?environment=sandbox</image-url>'+
                                                              '<token>k55x6b</token>' + 
                                                            '</credit-card>' + 
                                                      '</credit-cards>' + 
                                                '</customer>' ;
                                                
    private static final String RES_TRANS = '<?xml version="1.0" encoding="UTF-8"?>'+
                                            '<transaction>'+
                                              '<id>jk4gjy</id>'+
                                              '<status>submitted_for_settlement</status>'+
                                              '<type>sale</type>'+
                                              '<currency-iso-code>USD</currency-iso-code>'+
                                              '<amount>10.00</amount>'+                                           
                                              '<credit-card>'+
                                                '<token>3ksw2w</token>'+
                                                '<bin>411111</bin>'+
                                                '<last-4>1111</last-4>'+
                                                '<card-type>Visa</card-type>'+
                                              '</credit-card>'+         
                                              '<disputes type="array"/>'+
                                              '<payment-instrument-type>credit_card</payment-instrument-type>'+
                                            '</transaction>';
    
    
    private static final String RES_TRANS_Err = '<?xml version="1.0" encoding="UTF-8"?>'+
                                                    '<api-error-response>'+
                                                      '<errors>'+
                                                        '<errors type="array"/>'+
                                                        '<transaction>'+
                                                          '<errors type="array">'+
                                                            '<error>'+
                                                              '<code>81531</code>'+
                                                              '<attribute type="symbol">+amount</attribute>'+
                                                              '<message>Amount must be greater than zero.</message>'+
                                                            '</error>'+
                                                          '</errors>'+
                                                        '</transaction>'+
                                                      '</errors>'+
                                                      '<params>'+
                                                        '<transaction>'+
                                                          '<amount>0</amount>'+
                                                          '<type>sale</type>'+
                                                          '<customer-id>0011100000ezfem</customer-id>'+
                                                          '<payment-method-token>6m5c6w</payment-method-token>'+
                                                          '<options>'+
                                                            '<submit-for-settlement>true</submit-for-settlement>'+
                                                          '</options>'+
                                                        '</transaction>'+
                                                      '</params>'+
                                                      '<message>Amount must be greater than zero.</message>'+
                                                    '</api-error-response>';
    
   
                                                
    private static final String RES_CUSTOMER_Err =  '<?xml version="1.0" encoding="UTF-8"?>'+
                                                    '<api-error-response>'+
                                                      '<errors>'+
                                                        '<errors type="array"><error><code>111</code><message>aaa</message></error></errors>'+
                                                        '<customer>'+
                                                          '<errors type="array">'+
                                                            '<error>'+
                                                              '<code>91609</code>'+
                                                              '<attribute type="symbol">id</attribute>'+
                                                              '<message>Customer ID has already been taken.</message>'+
                                                            '</error>'+
                                                          '</errors>'+
                                                          '<credit-card>'+
                                                            '<errors type="array"><error><code>222</code><message>bbb</message></error></errors>'+
                                                          '</credit-card>'+
                                                        '</customer>'+
                                                      '</errors>'+
                                                    '</api-error-response>';
                                            
    private static final String RES_CREDITCARD_Err = '<?xml version="1.0" encoding="UTF-8"?>'+
                                                    '<api-error-response>'+
                                                          '<errors>'+
                                                                '<errors type="array"/>'+
                                                                '<credit-card>'+
                                                                      '<errors type="array">'+
                                                                            '<error>'+
                                                                                  '<code>81713</code>'+
                                                                                  '<attribute type="symbol">expiration_year</attribute>'+
                                                                                  '<message>Expiration year is invalid.</message>'+
                                                                            '</error>'+
                                                                            '<error>'+
                                                                                  '<code>81712</code>'+
                                                                                  '<attribute type="symbol">expiration_month</attribute>'+
                                                                                  '<message>Expiration month is invalid.</message>'+
                                                                            '</error>'+ 
                                                                      '</errors>'+
                                                                '</credit-card>'+
                                                          '</errors>'+ 
                                                    '</api-error-response>' ; 
     
    private static Account accBT;
    
    private static void setupData(){
        BrainTree__c a = new BrainTree__c();
        a.MerchantId__c = 'fksrgrthtxvv6r35';
        a.PublicKey__c = 'qp58y3rx4fbxhqgr';
        a.PrivateKey__c = '16b6513fff5c5f7a2ce40d641c0e7428';
        a.MerchantAccountID__c = 'test';
        a.EnvURL__c = 'https://api.braintreegateway.com';
        a.Name = 'BrainTree_UAT';
        insert a;
            
        BrainTree__c b = new BrainTree__c();
        b.MerchantId__c = 'fksrgrthtxvv6r35';
        b.PublicKey__c = 'qp58y3rx4fbxhqgr';
        b.PrivateKey__c = '16b6513fff5c5f7a2ce40d641c0e7428';
        b.MerchantAccountID__c = 'test';
        b.EnvURL__c = 'https://api.sandbox.braintreegateway.com';
        b.Name = 'BrainTree_Connection';
        insert b;
        
        Contact c= new Contact();
        c.FirstName='first';
        c.LastName='last';
        c.Email= c.FirstName + c.LastName +'@test.com';
        insert c;
        
        accBT = new Account(Name = 'TestAcc',                        
                        BillingStreet = 'DFP Fake Street',
                        BillingCity = 'DFP Fake City',
                        BillingState = 'DFP Fake State',
                        BillingPostalCode = '123',
                        BillingCountry = 'GB',
                        Country_Code__c='GB',
                        Bank_Country__c = 'GB',
                        Primary_contact__c=c.id
                        
                        ); // <id>16681806</id>
        insert accBT;
    }
   
    private static testMethod void testP2P_PayToBraintree() {
        setUpdataTestAll();
        setupData();
        
        Test.setCurrentPageReference(Page.P2P_PayToBraintree);
        ApexPages.CurrentPage().getparameters().put(P2P_PayToBraintree.PARAM_ACCID, accBT.id);
        ApexPages.CurrentPage().getparameters().put(P2P_PayToBraintree.PARAM_ERR, '111 - aaa');
        
        // The page first load to get client token
        P2P_PayToBraintree con = new P2P_PayToBraintree();
        response4Test = RES_TOKEN;
        con.actionMethod();
        
        // The page second load after click save button
        ApexPages.CurrentPage().getparameters().put('payment_method_nonce', 'test none');
        ApexPages.CurrentPage().getparameters().put('holderName', 'test name');
        response4Test = RES_CUSTOMER;
        con.actionMethod();       
        P2P_BraintreeServices btServices = new P2P_BraintreeServices();
        P2P_BraintreeServices.CustomerParser cuParser = btServices.getCustomer('0011100000ezfem');  
        String paymentToken = cuParser.defaultPaymentMethodToken;
        String pURL = cuParser.paymentURL;
        String mask = cuParser.masked;
        Boolean def = cuParser.defaultToken;
        String cardType = cuParser.cardType;
        
        // Test create customer error then create credit card
        response4Test = RES_CUSTOMER_Err;
        con.actionMethod();
        response4Test = RES_CREDITCARD_Err;
        con.actionMethod();
        
        response4Test = RES_TRANS;
        con.actionMethod();
        
        P2P_BraintreeServices.TransactionParser trParser = btServices.createTransaction('0011100000ezfem','38ds8d', '10.00');
        String err = cuParser.errorMsg;
        err = trParser.errorMsg;
        
        response4Test = RES_TRANS_Err;
        con.actionMethod();
    }    
}