/**
@Author : spp
@Date : 23/09/2014
@Business :

*/
@isTest
private class NetworkingUtils_Test {

    public static testMethod void testNetworkingUtils() {
     	
     	String ipString = 'Received: from [209.85.212.176] ([209.85.212.176:49560] helo=mail-wi0-f176.google.com) by mx3-sjl.mta.salesforce.com (envelope-from <srinivasvitta@gmail.com>) (ecelerity 2.2.2.45 r()) with ESMTPS (cipher=RC4-SHA subject="/C=US/ST=California/L=Mountain View/O=Google Inc/CN=smtp.gmail.com")  id ';
     	String res = NetworkingUtils.extractIP(ipString);
     	System.assertEquals('209.85.212.176', res);
     	
     	String ipString2 = 'Received: from helo=mail-wi0-f176.google.com) ';
     	String res2 = NetworkingUtils.extractIP(ipString2);
     	System.assertEquals(null, res2);
     	
     	
     	Boolean b1 = NetworkingUtils.isiOS('X-Mailer: iPhone Mail (11D257)');
     	System.assertEquals(true, b1);
     	
     	Boolean b2 = NetworkingUtils.isiOS('X-Mailer: BlackBerry Email (2.0.0.7971)');
     	System.assertEquals(false, b2);
     	
     	Boolean b3 = NetworkingUtils.isAndroid('X-Mailer: BlackBerry Email (2.0.0.7971)');
     	System.assertEquals(false, b3);
     	
     	Boolean b4 = NetworkingUtils.isAndroid('Message-ID: <0hhwdrusii4gxtjbiv24jabq.1411528069076@email.android.com>');
     	System.assertEquals(true, b4);
     
     	Boolean b5 = NetworkingUtils.isBB('X-Mailer: BlackBerry Email (2.0.0.7971)');
     	System.assertEquals(true, b5);

     	Boolean b6 = NetworkingUtils.isBB('X-Mailer: iPhone Mail (11D257)');
     	System.assertEquals(false, b6);
     	
     	String ua ='Mozilla/5.0 (iPad; U; CPU OS 3_2_1 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/7B405';
     	String device = NetworkingUtils.getOSFromUserAgent(ua);
     	System.assertEquals('iPad', device);
     	
     	
     
     }

}