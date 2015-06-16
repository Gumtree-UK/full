/**
*
*@Author : SPP
*@Date : 08/06/2014
*@Business : 
*
* Contains signature doc services
* Invoked by EchoSignServicesBatch.class
*
*/
public with sharing class EchoSignServices {

	
	 public static void invokeSendAutoEmailProcessWs(Id oppId,String sessionId){
    	HttpRequest req = new HttpRequest(); 
    	req.setMethod('POST');
    	req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/Soap/class/WSEchoSignAuto');
    	req.setHeader('SOAPAction','""');
    	req.setHeader('Content-Type', 'text/xml;charset=UTF-8' );
    	
    	String soapBody = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:wsec="http://soap.sforce.com/schemas/class/WSEchoSignAuto">';
   			   	soapBody+=	 '<soapenv:Header>';
      			soapBody+= 		'<wsec:SessionHeader>';
         		soapBody+=			'<wsec:sessionId>'+sessionId+'</wsec:sessionId>';
      			soapBody+=		'</wsec:SessionHeader>';
   				soapBody+=	'</soapenv:Header>';
   				soapBody+=	'<soapenv:Body>';
      			soapBody+=		'<wsec:sendEchoSignEmail>';
         		soapBody+=			'<wsec:oppId>'+oppId+'</wsec:oppId>';
      			soapBody+=		'</wsec:sendEchoSignEmail>';
   				soapBody+=	'</soapenv:Body>';
				soapBody+='</soapenv:Envelope>';
				
    	//Set HTTP body - soap msg goes here
		req.setBody(soapBody);
    	Http http = new Http();
    	HttpResponse res;
    	
    	if(!Test.isRunningTest())
		{
		     res = http.send(req);
		}
		else
		{
		     res = new EchoSignServicesHttpResponse().respond(req);
		}
    	
    	
    	System.debug('>>>>>res: '+res.getBody());
    	
    }
    
   
    

	public class EchoSignServicesHttpResponse implements HttpCalloutMock {
	
	     public HTTPResponse respond(HTTPRequest req) {
	        // Create a fake response
	        HttpResponse res = new HttpResponse();
	        res.setStatusCode(200);
	        return res;
	    }
	}
	
}