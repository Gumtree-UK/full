/**
 *  @Author : SPP
 *  @Date : 02/09/2015
 *  @Description :  Utility class to sign relative url request in order to access Gumtree BAPI System
 *                  Task #4849 : GTCRM-1292- PRO - M3 - 'My Company' module - Default ad image & packages via Gumtree BAPI
 *  @Change log : 
 *                  11-02-2015 modified by Pheaktra Hun  

- 2015-05-06 - GTCRM-1886 - Credits remaining don't tally with Salesforce - calculate total credits on the fly - Steve Paul

 */
public without sharing class P2P_GumtreeBAPI {

    public static final String ACCESS_KEY = 'apiKey';
    public static final String TIMESTAMP = 'timestamp';
    public static final String SIGNATURE = 'signature';
    public static final String AUTHENTICATION_ENABLED = 'authentication';
    private static P2P_RequestAdImage__c adImageSetting = P2P_RequestAdImage__c.getValues('Default Ad image');
    
    //*************  Packages  - Get from Gumtree BAPI ****************
    public static final String uploadbyurl_service = '/api/images/byurl';
    public static final String defaultimage_service = '/api/accounts/$accountid$/defaultImage';
    
    /**
     *  Sign service url
     */
    public static String createApiRequestSignature(String serviceurl, String private_key, String bapi_key)  {
        // params are ordered
        String newserviceurl = serviceurl + '?' + 'apiKey=' + bapi_key + '&timestamp=' + System.currentTimeMillis();
        
        // now we sign the relative - lower case 
        String urlsigned = generateHmacSHA256Signature(newserviceurl.tolowercase(), private_key);
        
        return newserviceurl + '&signature=' + urlsigned;
    }
    
    private static String generateHmacSHA256Signature(String urltoencode, String pk) {
        Blob hmacData = Crypto.generateMac(adImageSetting.Signature_Algorithm__c, Blob.valueOf(urltoencode), Blob.valueOf(pk));
        return EncodingUtil.convertToHex(hmacData);
    }
    
    /**
     *  Request default ad image for account
     */
    public static void getDefaultImage(String accountNumber, GumtreeImage gm, String private_key, String bapi_key) {
        if(accountNumber == null) return;
        
        String method       = 'GET';
        String url          = defaultimage_service.replace('$accountid$', accountNumber);
        String endpoint     = adImageSetting.EndPoint__c + createApiRequestSignature(url, private_key, bapi_key);
        String body         = null;
        String contentType  = null;
        
        //{"id":332672253,"url":"http://i.ebayimg.com/00/s/OTdYMjIw/z/m-YAAOSwe-FU2deP/$_1.JPG"}
        sendRequest(method, endpoint, body, contentType, gm);
        gm.isSuccess = true;
    }
    
    /**
     *  Upload image to Gumtree site get id
     */
    public static void uploadImageByUrl(String imageurl, GumtreeImage gm, String private_key, String bapi_key) {
        
        JSONGenerator generator = JSON.createGenerator(true);   //instantiation of the generator
        generator.writeStartObject();               //Writes the starting marker of a JSON object '{'
        generator.writeStringField('image_url', imageurl);   
        generator.writeEndObject();                 //Writes the ending marker of a JSON object '}'
        
        String method       = 'POST';
        String endpoint     = adImageSetting.EndPoint__c + createApiRequestSignature(uploadbyurl_service, private_key, bapi_key);
        String body         = generator.getAsString();
        String contentType  = 'application/json;charset=UTF-8';
        
        //{"id":333127998,"url":"http://i.ebayimg.com/00/s/MzAwWDQwMA==/z/b2QAAOSwNSxU2zDJ/$_1.JPG"}
        sendRequest(method, endpoint, body, contentType, gm);
    }
    
    /**
     *  Set the image have uploaded as default ad image for account
     */
    public static void setDefaultImage(String accountNumber, GumtreeImage gm, String private_key, String bapi_key) {
        
        JSONGenerator generator = JSON.createGenerator(true);   //instantiation of the generator
        generator.writeStartObject(); // Writes the starting marker of a JSON object '{'
        generator.writeStringField('image_id', gm.imageId);   
        generator.writeEndObject(); //Writes the ending marker of a JSON object '}'
        
        String method       = 'PUT';
        String url          = defaultimage_service.replace('$accountid$', accountNumber);
        String endpoint     = adImageSetting.EndPoint__c + createApiRequestSignature(url, private_key, bapi_key);
        String body         = generator.getAsString();
        String contentType  = 'application/json;charset=UTF-8';
        
        //{"account":{"id":3317,"name":"Gumtree.com (Jobs)","description":"Salesforce Account","address1":"Whittaker House, Whittaker Avenue","postcode":"TW9 1EH","city":"Richmond","county":"Surrey","country":"GB","status":"ACTIVE","default_image":{"id":332672253,"url":"http://i.ebayimg.com/00/s/OTdYMjIw/z/m-YAAOSwe-FU2deP/$_79.JPG","thumbnail_url":"http://i.ebayimg.com/00/s/OTdYMjIw/z/m-YAAOSwe-FU2deP/$_77.JPG"},"usernames":["info@jobmate.co.uk","stevenjpaul7@gmail.com"],"force_post_as_agency":false,"pro":true}}
        sendRequest(method, endpoint, body, contentType, gm);
    }
    
    /**
     *  Delete the default ad image
     */
    public static void deleteDefaultImage(String accountNumber, GumtreeImage gm, String private_key, String bapi_key) {
        
        String method       = 'PUT';
        String url          = defaultimage_service.replace('$accountid$', accountNumber);
        String endpoint     = adImageSetting.EndPoint__c + createApiRequestSignature(url, private_key, bapi_key);
        String body         = '{}';
        String contentType  = 'application/json;charset=UTF-8';
        
        //{"account":{"id":3317,"name":"Gumtree.com (Jobs)","description":"Salesforce Account","address1":"Whittaker House, Whittaker Avenue","postcode":"TW9 1EH","city":"Richmond","county":"Surrey","country":"GB","status":"ACTIVE","usernames":["info@jobmate.co.uk","stevenjpaul7@gmail.com"],"force_post_as_agency":false,"pro":true}}
        sendRequest(method, endpoint, body, contentType, gm);
    }
    
    private static void sendRequest(String method, String endpoint, String body, String contentType, Object obj){
        
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        req.setEndpoint(endpoint);
        if(body != null) req.setBody(body);
        if(contentType != null) req.setHeader('Content-Type', contentType);
        
        Http http = new Http();
        HTTPResponse res = Test.isRunningTest() ? P2P_GumtreeBAPIMock.getResponseMockCallout(req) : http.send(req);
        
        if(obj instanceof GumtreeImage) parseResponseGumtreeImage(res, (GumtreeImage)obj);
        else parseResponseGumtreePackage(res, (List<GumtreePackage>)obj);
    }
    
    /**
     *  Parse HttpResponse body success or error
     */
    private static void parseResponseGumtreeImage(HTTPResponse res, GumtreeImage gm){
        
        //success response body
        if(res.getStatusCode() == 200 || res.getStatusCode() == 201){
            gm.isSuccess = true;
            
            Map<String, Object> mResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if(mResponse.containsKey('id')) gm.imageId = (Integer)mResponse.get('id') + '';
            if(mResponse.containsKey('url')) gm.imageURL = (String)mResponse.get('url');
        //error
        }else{
            gm.isSuccess = false;
            gm.errMsg = 'Request Error : ' + res.getBody();
        }
    }
    
    public class GumtreeImage{
        public String imageId{get;set;}
        public String imageURL{get;set;}
        public Boolean isSuccess{get;set;}
        public String errMsg{get;set;}
    }
    
    //*************  Packages  - Get from Gumtree BAPI ****************
    public static final String PULLING_PACKAGES_SERVICE = '/api/accounts/$accountid$/packages';
    
    /**
     *  Request package from gumtree
     */
    public static void retrievePackagesList(String accountNumber, List<GumtreePackage> lgpkg, String private_key, String bapi_key) {
        if(accountNumber == null) return;
        
        String method       = 'GET';
        String url          = PULLING_PACKAGES_SERVICE.replace('$accountid$', accountNumber);
        String endpoint     = adImageSetting.EndPoint__c + createApiRequestSignature(url, private_key, bapi_key);
        String body         = null;
        String contentType  = null;
        
        sendRequest(method, endpoint, body, contentType, lgpkg);
    }
    
    /**
     * Parse Package service response
     */
    private static void parseResponseGumtreePackage(HTTPResponse res, List<GumtreePackage> lgpkg){
        
        //String mockTest='{"packages":[{"id":5437037,"package_type_id":1,"account_id":3317,"salesforce_id":"00kw000000SgQT8AAN","start_date":"2014-08-26T00:00:00Z","end_date":"2014-09-27T00:00:00Z","initial_credits":10,"adjusted_credits":0,"used_credits":2,"name":"Standard ad in Jobs, London","unlimited":false},{"id":3862630,"package_type_id":1,"account_id":3317,"salesforce_id":"00kw000000PuyBnAAJ","start_date":"2013-11-08T00:00:00Z","end_date":"2014-02-09T00:00:00Z","initial_credits":15,"adjusted_credits":0,"used_credits":12,"name":"Standard ad in Jobs, London","unlimited":false},{"id":4205778,"package_type_id":17,"account_id":3317,"salesforce_id":"00kw000000QWfxrAAD","start_date":"2014-01-09T00:00:00Z","end_date":"2014-07-10T00:00:00Z","initial_credits":10,"adjusted_credits":0,"used_credits":0,"name":"Unlimited 6-month subscription in Rentals","unlimited":true},{"id":4205777,"package_type_id":17,"account_id":3317,"salesforce_id":"00kw000000QAFTmAAP","start_date":"2014-01-09T00:00:00Z","end_date":"2014-07-10T00:00:00Z","initial_credits":10,"adjusted_credits":0,"used_credits":0,"name":"Unlimited 6-month subscription in Rentals","unlimited":true},{"id":3862631,"package_type_id":3,"account_id":3317,"salesforce_id":"00kw000000PuyBoAAJ","start_date":"2013-11-08T00:00:00Z","end_date":"2013-11-09T00:00:00Z","initial_credits":10,"adjusted_credits":0,"used_credits":1,"name":"7-day featured ad in Jobs, London","unlimited":false},{"id":3527918,"package_type_id":9,"account_id":3317,"salesforce_id":"00kw000000OtQLKAA3","start_date":"2013-08-06T00:00:00Z","end_date":"2013-10-07T00:00:00Z","initial_credits":1,"adjusted_credits":0,"used_credits":2,"name":"Standard ad in Jobs outside London","unlimited":false},{"id":3527917,"package_type_id":1,"account_id":3317,"salesforce_id":"00kw000000OtQLLAA3","start_date":"2013-08-06T00:00:00Z","end_date":"2013-10-07T00:00:00Z","initial_credits":1,"adjusted_credits":0,"used_credits":2,"name":"Standard ad in Jobs, London","unlimited":false},{"id":3478972,"package_type_id":1,"account_id":3317,"salesforce_id":"00k2000000OqffhAAB","start_date":"2013-07-10T00:00:00Z","end_date":"2013-07-18T00:00:00Z","initial_credits":5,"adjusted_credits":0,"used_credits":1,"name":"Standard ad in Jobs, London","unlimited":false},{"id":553929,"package_type_id":9,"account_id":3317,"salesforce_id":"00k2000000Ifce1AAB","start_date":"2012-06-15T00:00:00Z","end_date":"2013-06-16T00:00:00Z","initial_credits":5,"adjusted_credits":0,"used_credits":15,"name":"Standard ad in Jobs outside London","unlimited":false},{"id":685586,"package_type_id":9,"account_id":3317,"salesforce_id":"00k2000000LaagYAAR","start_date":"2012-12-05T00:00:00Z","end_date":"2013-02-06T00:00:00Z","initial_credits":2,"adjusted_credits":0,"used_credits":9,"name":"Standard ad in Jobs outside London","unlimited":false},{"id":685582,"package_type_id":12,"account_id":3317,"salesforce_id":"00k2000000LaagTAAR","start_date":"2012-12-05T00:00:00Z","end_date":"2013-02-06T00:00:00Z","initial_credits":2,"adjusted_credits":0,"used_credits":8,"name":"14-day featured ad in Jobs outside London","unlimited":false},{"id":456556,"package_type_id":1,"account_id":3317,"salesforce_id":"00k2000000Hclh6AAB","start_date":"2012-03-14T00:00:00Z","end_date":"2012-12-15T00:00:00Z","initial_credits":5,"adjusted_credits":0,"used_credits":8,"name":"Standard ad in Jobs, London","unlimited":false},{"id":456557,"package_type_id":4,"account_id":3317,"salesforce_id":"00k2000000Hclh5AAB","start_date":"2012-03-14T00:00:00Z","end_date":"2012-12-15T00:00:00Z","initial_credits":5,"adjusted_credits":0,"used_credits":1,"name":"14-day featured ad in Jobs, London","unlimited":false},{"id":685585,"package_type_id":14,"account_id":3317,"salesforce_id":"00k2000000LaagXAAR","start_date":"2012-12-05T00:00:00Z","end_date":"2013-02-06T00:00:00Z","initial_credits":2,"adjusted_credits":0,"used_credits":0,"name":"Urgent feature in Jobs outside London","unlimited":false},{"id":685584,"package_type_id":10,"account_id":3317,"salesforce_id":"00k2000000LaagUAAR","start_date":"2012-12-05T00:00:00Z","end_date":"2013-02-06T00:00:00Z","initial_credits":2,"adjusted_credits":0,"used_credits":0,"name":"3-day featured ad in Jobs outside London","unlimited":false},{"id":685583,"package_type_id":13,"account_id":3317,"salesforce_id":"00k2000000LaagWAAR","start_date":"2012-12-05T00:00:00Z","end_date":"2013-02-06T00:00:00Z","initial_credits":2,"adjusted_credits":0,"used_credits":1,"name":"Homepage spotlight feature in Jobs outside London","unlimited":false},{"id":685581,"package_type_id":11,"account_id":3317,"salesforce_id":"00k2000000LaagVAAR","start_date":"2012-12-05T00:00:00Z","end_date":"2013-02-06T00:00:00Z","initial_credits":2,"adjusted_credits":0,"used_credits":0,"name":"7-day featured ad in Jobs outside London","unlimited":false},{"id":644882,"package_type_id":3,"account_id":3317,"salesforce_id":"00kW0000003B9vrIAC","start_date":"2012-09-03T00:00:00Z","end_date":"2012-10-04T00:00:00Z","initial_credits":1,"adjusted_credits":0,"used_credits":0,"name":"7-day featured ad in Jobs, London","unlimited":false},{"id":644881,"package_type_id":4,"account_id":3317,"salesforce_id":"00kW0000003B9vnIAC","start_date":"2012-09-03T00:00:00Z","end_date":"2012-10-04T00:00:00Z","initial_credits":1,"adjusted_credits":0,"used_credits":0,"name":"14-day featured ad in Jobs, London","unlimited":false},{"id":644880,"package_type_id":1,"account_id":3317,"salesforce_id":"00kW0000003B9w4IAC","start_date":"2012-09-03T00:00:00Z","end_date":"2012-09-04T00:00:00Z","initial_credits":1,"adjusted_credits":0,"used_credits":0,"name":"Standard ad in Jobs, London","unlimited":false},{"id":644879,"package_type_id":1,"account_id":3317,"salesforce_id":"00kW0000003B9vwIAC","start_date":"2012-09-03T00:00:00Z","end_date":"2012-10-04T00:00:00Z","initial_credits":1,"adjusted_credits":0,"used_credits":0,"name":"Standard ad in Jobs, London","unlimited":false},{"id":641814,"package_type_id":5,"account_id":3317,"salesforce_id":"00kW0000003B9EPIA0","start_date":"2012-08-31T00:00:00Z","end_date":"2012-10-01T00:00:00Z","initial_credits":1500,"adjusted_credits":0,"used_credits":0,"name":"Homepage spotlight feature in Jobs, London","unlimited":false},{"id":641813,"package_type_id":10,"account_id":3317,"salesforce_id":"00kW0000003B9EOIA0","start_date":"2012-08-31T00:00:00Z","end_date":"2012-10-01T00:00:00Z","initial_credits":1000,"adjusted_credits":0,"used_credits":0,"name":"3-day featured ad in Jobs outside London","unlimited":false},{"id":641811,"package_type_id":12,"account_id":3317,"salesforce_id":"00kW0000003B9ENIA0","start_date":"2012-08-31T00:00:00Z","end_date":"2012-10-01T00:00:00Z","initial_credits":1000,"adjusted_credits":0,"used_credits":0,"name":"14-day featured ad in Jobs outside London","unlimited":false},{"id":641810,"package_type_id":4,"account_id":3317,"salesforce_id":"00kW0000003B9EMIA0","start_date":"2012-08-31T00:00:00Z","end_date":"2012-10-01T00:00:00Z","initial_credits":1000,"adjusted_credits":0,"used_credits":0,"name":"14-day featured ad in Jobs, London","unlimited":false},{"id":641806,"package_type_id":4,"account_id":3317,"salesforce_id":"00kW0000003B9ELIA0","start_date":"2012-08-31T00:00:00Z","end_date":"2012-10-01T00:00:00Z","initial_credits":1000,"adjusted_credits":0,"used_credits":0,"name":"14-day featured ad in Jobs, London","unlimited":false},{"id":456555,"package_type_id":5,"account_id":3317,"salesforce_id":"00k2000000Hclh4AAB","start_date":"2012-03-14T00:00:00Z","end_date":"2012-04-15T00:00:00Z","initial_credits":20,"adjusted_credits":0,"used_credits":1,"name":"Homepage spotlight feature in Jobs, London","unlimited":false},{"id":456554,"package_type_id":4,"account_id":3317,"salesforce_id":"00k2000000HclgyAAB","start_date":"2012-03-14T00:00:00Z","end_date":"2012-04-15T00:00:00Z","initial_credits":20,"adjusted_credits":0,"used_credits":1,"name":"14-day featured ad in Jobs, London","unlimited":false},{"id":456552,"package_type_id":11,"account_id":3317,"salesforce_id":"00k2000000Hclh3AAB","start_date":"2012-03-14T00:00:00Z","end_date":"2012-04-15T00:00:00Z","initial_credits":20,"adjusted_credits":0,"used_credits":0,"name":"7-day featured ad in Jobs outside London","unlimited":false},{"id":456553,"package_type_id":2,"account_id":3317,"salesforce_id":"00k2000000Hclh0AAB","start_date":"2012-03-14T00:00:00Z","end_date":"2012-04-15T00:00:00Z","initial_credits":20,"adjusted_credits":0,"used_credits":0,"name":"3-day featured ad in Jobs, London","unlimited":false},{"id":456551,"package_type_id":9,"account_id":3317,"salesforce_id":"00k2000000HclgxAAB","start_date":"2012-03-14T00:00:00Z","end_date":"2012-04-15T00:00:00Z","initial_credits":20,"adjusted_credits":0,"used_credits":1,"name":"Standard ad in Jobs outside London","unlimited":false},{"id":456550,"package_type_id":10,"account_id":3317,"salesforce_id":"00k2000000Hclh1AAB","start_date":"2012-03-14T00:00:00Z","end_date":"2012-04-15T00:00:00Z","initial_credits":20,"adjusted_credits":0,"used_credits":0,"name":"3-day featured ad in Jobs outside London","unlimited":false},{"id":456549,"package_type_id":12,"account_id":3317,"salesforce_id":"00k2000000HclgzAAB","start_date":"2012-03-14T00:00:00Z","end_date":"2012-04-15T00:00:00Z","initial_credits":20,"adjusted_credits":0,"used_credits":0,"name":"14-day featured ad in Jobs outside London","unlimited":false},{"id":456548,"package_type_id":3,"account_id":3317,"salesforce_id":"00k2000000Hclh2AAB","start_date":"2012-03-14T00:00:00Z","end_date":"2012-04-15T00:00:00Z","initial_credits":20,"adjusted_credits":0,"used_credits":0,"name":"7-day featured ad in Jobs, London","unlimited":false},{"id":456547,"package_type_id":1,"account_id":3317,"salesforce_id":"00k2000000HclgwAAB","start_date":"2012-03-14T00:00:00Z","end_date":"2012-04-15T00:00:00Z","initial_credits":20,"adjusted_credits":0,"used_credits":1,"name":"Standard ad in Jobs, London","unlimited":false},{"id":424020,"package_type_id":1,"account_id":3317,"salesforce_id":"00k2000000H5GlBAAV","start_date":"2012-02-14T00:00:00Z","end_date":"2012-03-15T00:00:00Z","initial_credits":5,"adjusted_credits":0,"used_credits":2,"name":"Standard ad in Jobs, London","unlimited":false},{"id":390621,"package_type_id":2,"account_id":3317,"salesforce_id":"00k2000000GK5ITAA1","start_date":"2012-01-12T00:00:00Z","end_date":"2012-02-13T00:00:00Z","initial_credits":5,"adjusted_credits":0,"used_credits":0,"name":"3-day featured ad in Jobs, London","unlimited":false},{"id":390620,"package_type_id":1,"account_id":3317,"salesforce_id":"00k2000000GK5IUAA1","start_date":"2012-01-12T00:00:00Z","end_date":"2012-02-13T00:00:00Z","initial_credits":5,"adjusted_credits":0,"used_credits":0,"name":"Standard ad in Jobs, London","unlimited":false},{"id":390619,"package_type_id":9,"account_id":3317,"salesforce_id":"00k2000000GK5HfAAL","start_date":"2012-01-12T00:00:00Z","end_date":"2012-02-13T00:00:00Z","initial_credits":5,"adjusted_credits":0,"used_credits":3,"name":"Standard ad in Jobs outside London","unlimited":false},{"id":388607,"package_type_id":1,"account_id":3317,"salesforce_id":"00k2000000Gk2TqAAJ","start_date":"2012-01-10T00:00:00Z","end_date":"2012-02-11T00:00:00Z","initial_credits":1,"adjusted_credits":0,"used_credits":0,"name":"Standard ad in Jobs, London","unlimited":false},{"id":107226,"package_type_id":3,"account_id":3317,"salesforce_id":"00k2000000CbiSMAAZ","start_date":"2011-04-07T00:00:00Z","end_date":"2011-09-08T00:00:00Z","initial_credits":20,"adjusted_credits":0,"used_credits":0,"name":"7-day featured ad in Jobs, London","unlimited":false},{"id":2276,"package_type_id":14,"account_id":3317,"salesforce_id":"00k2000000BLTJrAAP","start_date":"2011-02-09T00:00:00Z","end_date":"2011-08-10T00:00:00Z","initial_credits":22,"adjusted_credits":0,"used_credits":0,"name":"Urgent feature in Jobs outside London","unlimited":false},{"id":2275,"package_type_id":13,"account_id":3317,"salesforce_id":"00k2000000BLTJpAAP","start_date":"2011-02-05T00:00:00Z","end_date":"2011-05-06T00:00:00Z","initial_credits":15,"adjusted_credits":0,"used_credits":0,"name":"Homepage spotlight feature in Jobs outside London","unlimited":false},{"id":2274,"package_type_id":12,"account_id":3317,"salesforce_id":"00k2000000BLTJPAA5","start_date":"2011-02-03T00:00:00Z","end_date":"2011-04-04T00:00:00Z","initial_credits":20,"adjusted_credits":0,"used_credits":3,"name":"14-day featured ad in Jobs outside London","unlimited":false},{"id":2273,"package_type_id":6,"account_id":3317,"salesforce_id":"00k2000000BLTJqAAP","start_date":"2011-02-07T00:00:00Z","end_date":"2011-06-08T00:00:00Z","initial_credits":20,"adjusted_credits":0,"used_credits":5,"name":"Urgent feature in Jobs, London","unlimited":false},{"id":2272,"package_type_id":5,"account_id":3317,"salesforce_id":"00k2000000BLTJoAAP","start_date":"2011-02-05T00:00:00Z","end_date":"2011-04-06T00:00:00Z","initial_credits":10,"adjusted_credits":0,"used_credits":4,"name":"Homepage spotlight feature in Jobs, London","unlimited":false},{"id":2271,"package_type_id":4,"account_id":3317,"salesforce_id":"00k2000000BLTJAAA5","start_date":"2011-02-03T00:00:00Z","end_date":"2011-04-04T00:00:00Z","initial_credits":20,"adjusted_credits":0,"used_credits":7,"name":"14-day featured ad in Jobs, London","unlimited":false},{"id":2270,"package_type_id":1,"account_id":3317,"salesforce_id":"00k2000000BLTJCAA5","start_date":"2011-02-03T00:00:00Z","end_date":"2011-05-04T00:00:00Z","initial_credits":5,"adjusted_credits":0,"used_credits":50,"name":"Standard ad in Jobs, London","unlimited":false},{"id":2269,"package_type_id":2,"account_id":3317,"salesforce_id":"00k2000000BLTJFAA5","start_date":"2011-02-03T00:00:00Z","end_date":"2011-08-04T00:00:00Z","initial_credits":7,"adjusted_credits":0,"used_credits":2,"name":"3-day featured ad in Jobs, London","unlimited":false},{"id":2268,"package_type_id":3,"account_id":3317,"salesforce_id":"00k2000000BLTJBAA5","start_date":"2011-02-03T00:00:00Z","end_date":"2011-03-04T00:00:00Z","initial_credits":10,"adjusted_credits":0,"used_credits":0,"name":"7-day featured ad in Jobs, London","unlimited":false}]}';
        String mockTest = '';
        //success response body
        if(res.getStatusCode() == 200 || res.getStatusCode() == 201 || mockTest != ''){
            Map<String, Object> mResponseAll = (Map<String, Object>) JSON.deserializeUntyped(mockTest != '' ? mockTest : res.getBody());
            List<Object> mResponseList = (List<Object>) mResponseAll.get('packages');
            for(Object mResponseObj: mResponseList){
                Map<String, Object> mResponse = (Map<String, Object>) mResponseObj;
                GumtreePackage gpkg = new GumtreePackage();
                gpkg.sfId = mResponse.get('salesforce_id') != null ? mResponse.get('salesforce_id') + '' : '';
                gpkg.pkgId = mResponse.get('id') != null ? mResponse.get('id') + '' : '';
                gpkg.package_type_id = mResponse.get('package_type_id') != null ? mResponse.get('package_type_id') + '' : '';
                gpkg.gaccount_id = mResponse.get('account_id') != null ? mResponse.get('account_id') + '' : '';
                gpkg.start_date = mResponse.get('start_date') != null ? Date.valueOf(mResponse.get('start_date')+'') : null;
                gpkg.end_date = mResponse.get('end_date') != null ? Date.valueOf(mResponse.get('end_date')+'') : null;
                gpkg.initial_credits = mResponse.get('initial_credits') != null ? Integer.valueOf(mResponse.get('initial_credits')+'') : 0;
                gpkg.adjusted_credits = mResponse.get('adjusted_credits') != null ? Integer.valueOf(mResponse.get('adjusted_credits')+'') : 0;
                gpkg.used_credits = mResponse.get('used_credits') != null ? Integer.valueOf(mResponse.get('used_credits')) : 0;
                gpkg.pkgName = mResponse.get('name') != null ? mResponse.get('name') + '' : '';
                gpkg.unlimited = (mResponse.get('unlimited') + '') == 'true';

                gpkg.isSuccess = true;
                gpkg.errMsg = '';
                lgpkg.add(gpkg);
                
                System.debug('SF Id:' + gpkg.sfId); 
                System.debug('Package Id:' + gpkg.pkgId); 
                System.debug('Package Type Id:' + gpkg.package_type_id);
                System.debug('Account Id:' + gpkg.gaccount_id ); 
                System.debug('Start date: ' + gpkg.start_date);
                System.debug('End date: ' + gpkg.end_date);                
                System.debug('Initial credits: ' + gpkg.initial_credits);
                System.debug('Adjusted credits: ' + gpkg.adjusted_credits); 
                System.debug('Used credits: ' + gpkg.used_credits); 
                System.debug('Package name: ' + gpkg.pkgName); 
                System.debug('Unlimited: ' + gpkg.unlimited);                 
 
            }
        //error
        }else{
            GumtreePackage gpkg = new GumtreePackage();
            gpkg.isSuccess = false;
            gpkg.errMsg = 'We can not load packages from server just now.';
            //gpkg.errMsg = 'Request Error : ' + res.getBody();
            lgpkg.add(gpkg);
        }
    }
    
    public class GumtreePackage{
        public String sfId { get; set; }
        public String pkgId { get; set; }
        public String package_type_id { get; set; }
        public String gaccount_id { get; set; }
        public Date start_date { get; set; }
        public Date end_date { get; set; }
        public Integer initial_credits { get; set; }
        public Integer adjusted_credits { get; set; }
        public Integer used_credits { get; set; }
        public String pkgName { get; set; }
        public Boolean unlimited { get; set; }
           
        public Boolean isSuccess{get;set;}
        public String errMsg{get;set;}
        
        public String getRemaining(){
            unlimited = unlimited == null ? false : unlimited;
            return unlimited ? 'Unlimited' : String.valueOf(remainingVal());
        }
        
        private Integer remainingVal(){
            initial_credits = initial_credits == null ? 0 : initial_credits;
            adjusted_credits = adjusted_credits == null ? 0 : adjusted_credits;
            used_credits = used_credits == null ? 0 : used_credits;
            return initial_credits + adjusted_credits - used_credits;
        }
        
        public String getRemainingIdentity(){
            if(getRemaining() == 'Unlimited' || remainingVal() >= 10) return '3';
            if(remainingVal() >= 5 && remainingVal() < 10) return '2';
            return '1';
        }
        
        // GTCRM-1886 - Credits remaining don't tally with Salesforce - calculate total credits on the fly      
        
        public String getAvailable(){
            return String.valueOf(AvailableVal());    
  
        }
         
        public Integer AvailableVal(){
            initial_credits = initial_credits == null ? 0 : initial_credits;
            adjusted_credits = adjusted_credits == null ? 0 : adjusted_credits;
            System.debug('Initial credits: ' + initial_credits); 
            System.debug('Adjusted credits: ' + adjusted_credits);
            return initial_credits + adjusted_credits;
       } 
         
       }
 
     
}