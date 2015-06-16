global with sharing class P2P_URLRewriter implements Site.Urlrewriter {
    
    //user friendly urls
    private final String COMPANY_PAGE = '/company';
    private final String FINANCIALS_PAGE = '/financials';
    private final String FINANCIALSPAYMENT_PAGE = '/financialspayment';
    private final String METRICS_PAGE = '/metrics';
    private final String STORE_PAGE = '/store';
    private final String STOREPAYMENT_PAGE = '/storepayment';
    private final String SUPPORT_PAGE = '/support';
    private final String ERROR_PAGE = '/error';
    
    //Salesforce urls
    private final String COMPANY_VISUALFORCE_PAGE = '/p2p_mycompany';
    private final String FINANCIALS_VISUALFORCE_PAGE = '/p2p_myfinancials';
    private final String FINANCIALSPAYMENT_VISUALFORCE_PAGE = '/p2p_myfinancialspayment';
    private final String METRICS_VISUALFORCE_PAGE = '/p2p_mymetrics'; 
    private final String STORE_VISUALFORCE_PAGE = '/p2p_mycheckout';
    private final String STOREPAYMENT_VISUALFORCE_PAGE = '/p2p_mycheckoutpayment';
    private final String SUPPORT_VISUALFORCE_PAGE = '/p2p_mysupport';
    private final String ERROR_VISUALFORCE_PAGE = '/p2p_errorpage';
    
    Map<String, String> mUrl = new Map<String, String>{COMPANY_PAGE => COMPANY_VISUALFORCE_PAGE, 
                                                            FINANCIALSPAYMENT_PAGE => FINANCIALSPAYMENT_VISUALFORCE_PAGE,
                                                            FINANCIALS_PAGE => FINANCIALS_VISUALFORCE_PAGE, 
                                                            METRICS_PAGE => METRICS_VISUALFORCE_PAGE,
                                                            STOREPAYMENT_PAGE => STOREPAYMENT_VISUALFORCE_PAGE,
                                                            STORE_PAGE => STORE_VISUALFORCE_PAGE,
                                                            SUPPORT_PAGE => SUPPORT_VISUALFORCE_PAGE,
                                                            ERROR_PAGE => ERROR_VISUALFORCE_PAGE
                                                        };
     //Convert from friendly Url to salesforce url
     global PageReference mapRequestUrl(PageReference myFriendlyUrl){
        
        String url = myFriendlyUrl.getUrl();
        for(String s : mUrl.keyset()){
            if(url.startsWith(s)){
                return new PageReference(mUrl.get(s));
            }
        }
        return null;
    }
    //Convert from salesforce url to friendly Url
    global List<PageReference> generateUrlFor(List<PageReference> mySalesforceUrls){
        
        List<PageReference> myFriendlyUrls = new List<PageReference>();
                     
        for(PageReference mySalesforceUrl : mySalesforceUrls){
             
             String url=mySalesforceUrl.getUrl();
            
             if(String.isNotEmpty(url) && url.toLowerCase().startsWith(COMPANY_VISUALFORCE_PAGE)){
                
                myFriendlyUrls.add(new PageReference(COMPANY_PAGE));
                
             }else if(String.isNotEmpty(url) && url.toLowerCase().startsWith(FINANCIALSPAYMENT_VISUALFORCE_PAGE)){
                
                myFriendlyUrls.add(new PageReference(FINANCIALSPAYMENT_PAGE));
                
             }else if(String.isNotEmpty(url) && url.toLowerCase().startsWith(FINANCIALS_VISUALFORCE_PAGE)){
                
                myFriendlyUrls.add(new PageReference(FINANCIALS_PAGE));
             
             }else if(String.isNotEmpty(url) && url.toLowerCase().startsWith(METRICS_VISUALFORCE_PAGE)){
                
                myFriendlyUrls.add(new PageReference(METRICS_PAGE));
                
             }else if(String.isNotEmpty(url) && url.toLowerCase().startsWith(STOREPAYMENT_VISUALFORCE_PAGE)){
                
                myFriendlyUrls.add(new PageReference(STOREPAYMENT_PAGE));
                
             }else if(String.isNotEmpty(url) && url.toLowerCase().startsWith(STORE_VISUALFORCE_PAGE)){
                
                myFriendlyUrls.add(new PageReference(STORE_PAGE));
                
             }else if(String.isNotEmpty(url) && url.toLowerCase().startsWith(SUPPORT_VISUALFORCE_PAGE)){
                
                myFriendlyUrls.add(new PageReference(SUPPORT_PAGE));
                
             }else if(String.isNotEmpty(url) && url.toLowerCase().startsWith(ERROR_VISUALFORCE_PAGE)){
                
                myFriendlyUrls.add(new PageReference(ERROR_PAGE));
                
             }else{
                myFriendlyUrls.add(mySalesforceUrl);
             }
             
        }
        //Return the full list of pages
        return myFriendlyUrls;
        //return mySalesforceUrls;
    }
}