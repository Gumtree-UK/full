public with sharing class APIRequestImpl implements APIRequestInterface {

    public static APIRequestInterface getAPIRequestInstance() {
    	if (Test.isRunningTest()) {
    		System.debug('mock api request');
            APIRequestMock mock = new APIRequestMock();
            return mock;
        }
        return new APIRequestImpl();
    }
        
    public static String signUrl(String url) {
        Long timestamp = DateTime.now().getTime();
        url += url.contains('?') ? '&' : '?';
        url += 'apiKey='+GumtreeAPI.ACCESSKEY;
        url += '&timestamp='+timestamp;
        Blob urlBlob = Blob.valueOf(url.toLowerCase());
        Blob privateKeyBlob = Blob.valueOf(GumtreeAPI.PRIVATEKEY);
        Blob mac = Crypto.generateMac('HMacSHA256', urlBlob, privateKeyBlob);
        url += '&signature='+EncodingUtil.urlEncode(EncodingUtil.convertToHex(mac), 'UTF-8');
        return url;             
    }

    public HttpResponse sendRequest(String method, String path, String body) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(GumtreeAPI.APIHOST + signUrl(path));
        request.setMethod(method);
        request.setTimeout(GumtreeAPI.TIMEOUT);
        request.setHeader('Content-Type', 'application/json');
        if (body != null && body.length() > 0) {
            request.setHeader('Content-Length', body.length()+'');
            request.setBody(body);
        }
        System.debug(body);
        return http.send(request); 
    }
    
    static testMethod void testGetAPIRequestInstance() {
    	//test for coverage only
    	APIRequestImpl.getAPIRequestInstance();
    }
    
    static testMethod void testSignUrl() {
    	//test for coverage only
    	APIRequestImpl.setupGumtreeSettings();
    	String url = APIRequestImpl.signUrl('http://www.gumtree.com');
    }
    
    static testMethod void testSendRequest() {
    	//test for coverage only
    	APIRequestImpl.setupGumtreeSettings();
    	APIRequestImpl api = new APIRequestImpl();
    	api.sendRequest('GET', '/api/url', 'test request');
    }
    
    /**
     * Required to avoid nulls when using gumtree settings in tests
     */
    static void setupGumtreeSettings() {
    	if (Gumtree_Settings__c.getInstance('Webservice') == null) {
  			Gumtree_Settings__c settings = new Gumtree_Settings__c(Name = 'Webservice', SetupOwnerId=UserInfo.getOrganizationId());
  			settings.Endpoint__c = 'endpoint';
			settings.AccessKey__c = 'access';
			settings.PrivateKey__c = 'private';
			upsert settings;
    	}
    }
        
}