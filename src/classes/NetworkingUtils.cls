/**
@Author : spp
@Date : 23/09/2014
@Business :

*/
public class NetworkingUtils {

	private static String IPADDRESS_PATTERN = '(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)';


	/**
	*
	*

	String ipString = 'Received: from [209.85.212.176] ([209.85.212.176:49560] helo=mail-wi0-f176.google.com) by mx3-sjl.mta.salesforce.com (envelope-from <srinivasvitta@gmail.com>) (ecelerity 2.2.2.45 r()) with ESMTPS (cipher=RC4-SHA subject="/C=US/ST=California/L=Mountain View/O=Google Inc/CN=smtp.gmail.com")  id ';

	return 209.85.212.176

	*/
	public static String extractIP(String ipstring) {

	Matcher matcher = Pattern.compile(IPADDRESS_PATTERN).matcher(ipString);

	if (matcher.find()) {
            return matcher.group();
    }

	return null;
	
	}

	/**
	* X-Mailer: iPhone Mail (11D257)
	* X-Mailer: iPad Mail (11D201)
	*
	*/
	public static boolean isiOS(String mailerstring) {
	
		String deviceReg = '(?i)(iphone|ipod|ipad)';	  
	  
	 	Matcher m = Pattern.compile(deviceReg).matcher(mailerstring);
        
     	return m.find();
     
     }
     
     /**
	* X-Mailer: iPhone Mail (11D257)
	* X-Mailer: iPad Mail (11D201)
	* X-Mailer: BlackBerry Email (2.0.0.7971)
	*/
	public static boolean isBB(String mailerstring) {
	
		String deviceReg = '(?i)(blackberry)';	  
	  
	 	Matcher m = Pattern.compile(deviceReg).matcher(mailerstring);
        
     	return m.find();
     
     }
     
     /**
     * Message-ID: <1332714176.54741.androidMobile@web141101.mail.bf1.yahoo.com>
     *
     */
     public static boolean isAndroid(String mailerstring) {
	
		String deviceReg = '(?i)(droid|android)';	  
	  
	 	Matcher m = Pattern.compile(deviceReg).matcher(mailerstring);
        
     	return m.find();
     
     }
     
     /**
     *
     */
     public static String getOSFromUserAgent(String userAgent){
        
        
        if (!String.isEmpty(userAgent))  {        
        	
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
	                return m.group();//'Desktop';
	            }
	        }
        }
        
        return 'Unknown OS';
    }
    
    
   

     
     

}