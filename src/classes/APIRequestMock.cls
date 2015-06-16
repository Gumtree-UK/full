@IsTest public with sharing class APIRequestMock implements APIRequestInterface {
    	
	private Integer statusCode = 500;
	private String body = 'default body';
	private Integer sendRequestCallCount = 0;
	
	public Integer getStatusCode() {
		return this.statusCode;
	}
	
	public void setStatusCode(Integer statusCode) {
		this.statusCode = statusCode;
		System.debug(''+this.statusCode);
	}
	
	public void setBody(String body) {
		this.body = body;
	}
    
    public String signUrl(String url) {
        Long timestamp = DateTime.now().getTime();
        url += url.contains('?') ? '&' : '?';
        url += 'apiKey='+GumtreeAPI.ACCESSKEY;
        url += '&timestamp='+timestamp;
        Blob mac = Crypto.generateMac('HMacSHA256', Blob.valueOf(url.toLowerCase()), Blob.valueOf(GumtreeAPI.PRIVATEKEY));
        url += '&signature='+EncodingUtil.urlEncode(EncodingUtil.convertToHex(mac), 'UTF-8');
        return url;             
    }
	
    public HttpResponse sendRequest(String method, String path, String requestBody) {
    	sendRequestCallCount++;
    	System.debug('sendRequestCallCount' + sendRequestCallCount);
        HttpResponse response = new HttpResponse();
        if (this.body != null) {
        	response.setBody(this.body);
        }else if(requestBody != null) {
        	response.setBody(requestBody);
        }
        System.debug('body'+this.body);
        response.setStatusCode(this.statusCode);
        return response;
    }
    
    public void verifySendRequest(Integer times) {
    	System.assertEquals(times, sendRequestCallCount);
    }
}