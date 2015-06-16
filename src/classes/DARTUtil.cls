/**
 Utilities
 
Change log:
- 2013-04-16 - GTCRM-169 - Added mail.setCcAddresses(cc); to sendMail
 
*/
public with sharing class DARTUtil {
      
    final static String DART_DATEFORMAT = 'EEE MMM dd HH:mm z yyyy';
    public final static String DART_DATEFORMAT_QUERY = 'yyyy-MM-dd';
    
    public static String CLIENT_AUTH_URL = 'https://www.google.com/accounts/ClientLogin';
     
    
    public final static String DART5 = 'DART5';
    public final static String DART6 = 'DART6';
    public final static String AUTHENTICATION_TYPE = 'ClientLogin';
    public final static String URL_INSTANCE = 'https://'+URL.getSalesforceBaseURL().getHost();  
    public final static String EMAIL_SUBJECT = 'Availability Forecast' ;
    public final static String EMAIL_SUBJECT_BOOKING = 'Booking results' ;
    
    public final static String USER_ROLE_SALESPERSON = '1';
    public final static String USER_ROLE_PRIMARY_TRAFICKER = '2';
     
    public final static String TEAM_MEMBER_ROLE = 'Primary Trafficker';
    
    /** 
    @param username
    @param password
    @param server param
    @param method
    i.e:
    'myacc','mypwd','/xmlserver/','POST'
    */   
    public static String composeDigestAuthorizationHeader(String paramString1, String paramString2, String paramString3, String paramString4)
    {
        try
        { 
          
          String str1 = 'DART';
          String str2 = computeDigest(System.now().format(DART_DATEFORMAT));//Wed Sep 05 15:37:21 ICT 2012
          String str3 = '00000001';
          String str4 = computeDigest(System.now().format(DART_DATEFORMAT));
          String str5 = 'auth';
          String str6 = computeDigest(paramString1 + ':' + str1 + ':' + paramString2);
          String str7 = computeDigest(paramString4 + ':' + paramString3);
          String str8 = str2 + ':' + str3 + ':' + str4 + ':' + str5 + ':' + str7;
          String str9 = computeDigest(str6 + ':' + str8);
          String strDigest = 'Digest ';
          strDigest+='username="' + paramString1 + '", realm="' + str1 + '", qop="' + str5 + '", ';
          strDigest+='algorithm="MD5", uri="' + paramString3 + '", nonce="' + str2 + '", nc=' + str3 + ', ';
          strDigest+='cnonce="' + str4 + '", response="' + str9 + '"';
          //System.debug('>>>>>>>>>>>>System.now().format(df):'+System.now().format(df));
          //System.debug('>>>>strDigest.toString:'+strDigest);
          return strDigest;
        }
        catch (Exception ex)
        {
            //System.debug('>>>>>>>>>>>>ERRRROR:'+ex);
            throw new ExceptionGroup.DigestException('Could not compose digest authorization.\n'+ex.getStackTraceString());
        } 
        return null;
    }
    
    private static String computeDigest(String paramString) 
    {
        Blob hash = Crypto.generateDigest('MD5',Blob.valueOf(paramString));
        String hexDigest = EncodingUtil.convertToHex(hash);
        
        return  hexDigest;
    }
    static Map<String, String> mapDart6Token = new Map<String, String>();
    public static String getRequestToken(String countryCode)
    {       
        if(!mapDart6Token.containsKey(countryCode)){    
            try
            {
                 String authToken='';
                AdServer_Login__c login = getCredential(DART6, countryCode);
                
                HTTPWrapper.IRequest tokenReq = new DART6Message.DART6TokenRequest(login);
                DART6Message.GenericResponse tokeResponse = new DART6Message.GenericResponse(tokenReq);
                
                String responseBody = tokeResponse.getResBody();
                 
                
                if(!(responseBody+'').contains('Auth='))
                {
                    throw new ExceptionGroup.FetchTokenException(responseBody);
                }
                
                authToken = responseBody.substring(responseBody.indexOf('Auth=') + 5).trim();
                
                 mapDart6Token.put(countryCode,authToken); 
                 
                /*
                AdServer_Login__c login = getCredential(DART6);
                
                Http http = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(CLIENT_AUTH_URL);
                request.setMethod('POST');
                request.setHeader('Content-type', 'application/x-www-form-urlencoded');
                
                String body = 'service=gam&accountType=GOOGLE&' + 'Email=' + login.User_Name__c + '&Passwd=' + login.Password__c;
                request.setBody(body);
                
                HttpResponse response = http.send(request);
                String responseBody = response.getBody();
                authToken = responseBody.substring(responseBody.indexOf('Auth=') + 5).trim();
                */
            }catch(Exception ex)
            {
                throw new ExceptionGroup.FetchTokenException('Could not fetch token for DART6.\n'+ex.getStackTraceString());
            }
            
        }   
        return mapDart6Token.get(countryCode); 
    }
    
    static Map<String,AdServer_Login__c> mapCredential;
    
    public static AdServer_Login__c getCredential(String dartVersion, String countryCode)
    {
        if(mapCredential==null)
        {
            mapCredential = new Map<String,AdServer_Login__c>();
            
            //for( AdServer_Login__c login: [SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c, Site__c FROM AdServer_Login__c WHERE Active__c=true AND isDeleted=false])  old version            
            for( AdServer_Login__c login: [SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c, Refresh_Token__c, Client_Id__c, Client_Secret__c, Site__c FROM AdServer_Login__c WHERE Active__c=true AND isDeleted=false])   //for new version 201411
            {
                mapCredential.put(login.RecordType.name+'_'+login.Name,login);//DART Version, Login
            }
            System.debug('\n\n---------> countryCode: ' + countryCode +'---------> dartVersion: '+dartVersion +'---------> mapCredential: ' + mapCredential);
            if(mapCredential.isEmpty() || !mapCredential.containsKey(dartVersion+'_'+countryCode))
            {
                throw new ExceptionGroup.FetchTokenException('No related or active DART credential defined for DART: '+dartVersion+', Country: '+countryCode);
            } 
            
        }
        
        return mapCredential.get(dartVersion+'_'+countryCode);
    }
  
  /** send email */  
// 2013-04-16 - GTCRM-169 - Added mail.setCcAddresses(cc); to sendMail
   
   public static void sendMail(String[] addr, String[] cc, String subject,String displayName,String body){
         
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        mail.setToAddresses(addr);

        if(cc != null && !cc.isEmpty()) mail.setCcAddresses(cc);
        
        mail.setSenderDisplayName(displayName);
        
        mail.setSubject(subject);
        
        mail.setBccSender(false);

        mail.setUseSignature(false);

        mail.setHtmlBody(body);
        
        //start sending
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
     /** 
     * Generated Ids for IN where clause
     */   
    public static String generateIds(Set<String> sIds){
        String ids = '(';
        for(String s: sIds) {
            ids+='\''+s+'\',';
        }
        ids = ids.substring(0,ids.length()-1)+')';
        
        return ids;
    }
     
     
     public static Geography__c[] getListGeographies(String targetingId)
     {
     	return [Select Name, Country_Code__c, Dart_ID__c, Node_ID__c, Type__c From Geography__c Where ID IN (Select Geography__c From TargetingGeographyAssociation__c Where Targeting__c=:targetingId)];
     }
     
     public static Devices__c[] getListDevices(String targetingId)
     {
     	return [Select Name, DFP_API_Name__c, Dart_ID__c, Node_ID__c From Devices__c Where ID IN (Select Device__c From TargetingDeviceAssociation__c Where Targeting__c=:targetingId)];
     }
     
     public static Connection__c[] getListConnections(String targetingId)
     {
     	return [Select Name, DFP_API_Name__c, Dart_ID__c, Node_ID__c From Connection__c Where ID IN (Select Connection__c From TargetingConnectionAssociation__c Where Targeting__c=:targetingId)];
     }
     
     public static Country__c[] getListCountries(String targetingId)
     {
        
        return [SELECT Name,Country_Code__c,Dart_ID__c FROM Country__c WHERE Id IN (SELECT Country__c FROM TargetingCountryAssociation__c WHERE Targeting__c=:targetingId)];//'a07R0000006nHV5'
     }
     
     public static City__c[] getListCities(String targetingId)
     {
        
        return [SELECT Name,State_Region__c,Country__r.Name, Dart_ID__c  FROM City__c  WHERE Id IN (SELECT City__c FROM TargetingCityAssociation__c WHERE Targeting__c=:targetingId)];//'a07R0000006nHV5'
     }
     
     public static AreaCode__c[] getListAreaCodes(String targetingId)
     {
        
        return [SELECT Name, Dart_ID__c  FROM AreaCode__c WHERE Id IN (SELECT AreaCode__c FROM TargetingAreaCodeAssociation__c WHERE Targeting__c=:targetingId)];//'a07R0000006nHV5'
     }
     
     /**Get list of Contents either by targetingId or ProductId */   
     public static Content__c[] getListContents(String targetingId,String productId)
     {
        //1-Oppproduct.Targeting__r. TargetingContentAssociation__r.Content__r. Name 
        
        Content__c[] contents = getContentsByTargetType(targetingId,'Dart - Site');//'a07R0000006nHV5'
         
        //2- Product2--> Placement__c--> Content__c
        //Product.Placement__r.Content_Category_Site__c.Name      
        //productid: //'01t20000002byPq'
        
        //get Content Id from Product
        Set<String> siteConId = new Set<String>();
        for(Product2 p: [SELECT Placement__r.Content_Category_Site__c FROM Product2  WHERE ID=:productId])
        {
            siteConId.add(p.Placement__r.Content_Category_Site__c);
        }
        
        //get Content from related Product and add to the existing list of Contents
        contents.addAll([SELECT Name,DartName__c  FROM Content__c WHERE ID IN:siteConId]); 
        
        return contents;
     }
     
     public static Content__c[] getContentsByTargetType(String targetingId,String cType)
     {
        
        //
        return Database.query('SELECT Name,DartName__c,Site__r.Name,Site_Content_Category__r.Name  FROM Content__c '+ //Name = dartId
       'WHERE (Id IN (SELECT TargetingContent__c FROM TargetingContentAssociation__c '+
       'WHERE Targeting__c=:targetingId) AND Type__c=:cType)');
        
     }
     
     /** Get Advertiser */
    
     public static Advertiser__c[] getAdvertiser(String accId, String agency)
     {
        return [Select id, Name, Dart5_Advertiser_Id__c, Dart6_Advertiser_Id__c, AdServer_Login_Name__c From Advertiser__c Where Advertiser__c.Account__c =: accId AND Advertiser__c.Agency__c =: agency];
     }
     
     /** Advertiser  */
     //public static Advertiser__c[] getAdvertiser(String accId)
     //{
     //   return [Select id, Name, Dart5_Advertiser_Id__c, Dart6_Advertiser_Id__c, AdServer_Login_Name__c From Advertiser__c Where Advertiser__c.Account__c =: accId];
     //}
     
     /** OpportunityTeamMember  */   
     public static OpportunityTeamMember[] getOpportunityTeamMember(String oppId)
     {

        return [Select User.Name, UserId, TeamMemberRole From OpportunityTeamMember WHERE TeamMemberRole =: TEAM_MEMBER_ROLE and opportunityId=:oppId];
       
     } 
     
    /** For AvailForecast includeSite*/   
     public static Content__c[] getListAvailSites(String productId,Set<String> cType)
     {
         //schema: Product<---AvailableSite--->Content (via available_Site__c)       
         //Need: Product.Available_Site__r.Name (I think Content rather than this)
         //return [SELECT Name FROM Available_Site__c WHERE Product__c=:productId];
         return [SELECT Name,DartName__c,Site_Content_Category__r.Name  FROM Content__c WHERE Id IN 
                (SELECT available_Site__c FROM Available_Site__c WHERE Product__c=:productId) and Type__c IN:cType];
         
     }
     
     final static String TD_STYLE='style="border:solid gray 1pt; padding:3pt 3pt 3pt 3pt"';
     final static String TD_TEMPLATE = '<TD '+ TD_STYLE +'>{0}</TD>';
     public static String genTD(String val)
     {
        return String.format(TD_TEMPLATE, new String[]{val});
     }
    
     final static String TR_TEMPLATE = '<TR>{0}</TR>';
     public static String genTR(String val)
     {
        return String.format(TR_TEMPLATE, new String[]{val});
     }
     
     /** Generate table forecast */   
    public static  String generateTableForecast(List<DARTObject.DARTForecast> lst)
    {
       //final Map<String,String> mapFCPeriod = new Map<String,String>{'0'=>'Minutes','1'=>'Hours','2'=>'Days','3'=>'Weeks',null=>''};
       String trBody = '';//all TRs and TDs
       for(DARTObject.DARTForecast fc : lst)
       {
           //String fcp = (mapFCPeriod.get(fc.getFCPeriod())==null?'':mapFCPeriod.get(fc.getFCPeriod()));
           String strFC =   fc.getFCQty()+ '/' + fc.getFCAdServedEvery()+' ' + fc.getFCPeriodDart6();
           strFC = (('').equals(fc.getFCQty())?fc.getFCAdServedEvery()+' '+ fc.getFCPeriodDart6():strFC); 
                       
           String tds = genTD('<a href='+URL_INSTANCE+'/'+fc.getOppItemID() +'>'+fc.getOppItemID()+'</a>')+ 
                        genTD(fc.getPackage()) + genTD(fc.getProductName()) + 
                        genTD(fc.getLineDesc())+ genTD(strFC) + 
                        genTD(fc.getPeriod())+ genTD(fc.getQuantity()+'') + 
                        genTD(fc.getAvailableUnits()+'')+
                        genTD(fc.getShareOfVoice()+'%') ;
                       
           String trs = genTR(tds);            
           trBody += trs; 
          
       }    

       return trBody ;   
   }
   
    /** Generate table LineItemPage */   
    public static  String generateTableLineItemPage(List<OpportunityLineItem> lst){
    	String trBody = '';//all TRs and TDs
    	for(OpportunityLineItem item : lst){
			String tds = genTD('<a href='+URL_INSTANCE+'/'+ item.Id +'>'+item.Id+'</a>')+ 
						 genTD(strNotNull(item.PriceBookEntry.Product2.Name)) + 
                         genTD(strNotNull(item.Description)) + 
                         genTD(strNotNull(item.Period__c));
			String trs = genTR(tds);            
			trBody += trs; 
		}  
		return trBody ;   
   }
   
   /** Generate table LineItemPage error */   
   public static String generateTableLineItemPageError(Map<String, Exception> mapError){
		return generateTableForecastError(mapError);
   }
   
   /** Generate table Compaign */   
   public static String generateTableCompaigns(List<DARTObject.IDARTObjectOrder> lstOrder)
   {
       String trBody = '';//all TRs and TDs
       
       for(DARTObject.IDARTObjectOrder ord : lstOrder)
       {
           
           String tds = genTD('<a href='+URL_INSTANCE+'/'+ord.getOppID() +'>'+ord.getOppID()+'</a>')+ 
                        genTD(ord.getOppName())+
                        genTD(ord.getAssignAdserver()==null?'':ord.getAssignAdserver()) + 
                        genTD(ord.getDartId()==null?'':ord.getDartId()) + 
                        genTD(ord.getDartId()==null?'':'Update')+
                        genTD('')+
                        genTD(ord.getDartErrMsg()==null?'':ord.getDartErrMsg());
                        
                       
           String trs = genTR(tds);            
           trBody += trs;  
          
       }   

       return trBody ;
   }  
   
   /** Generate table Compaigns Items */  
    public static  String generateTableCompaignItems(List<DARTObject.IDARTObjectAds> lstAds)
    {
       String trBody = '';//all TRs and TDs
       for(DARTObject.IDARTObjectAds ads : lstAds)
       {
           DARTObject.IDARTObjectOrder ord = ads.getOrder();
           String tds = genTD('<a href='+URL_INSTANCE+'/'+ads.getOppItemID() +'>'+ads.getOppItemID()+'</a>')+ 
                        genTD(ads.getProductName()) + 
                        genTD(ads.getAssignAdserver()==null?'':ads.getAssignAdserver())+ 
                        genTD(ord==null?'':ord.getDartId())+ 
                        genTD(ads.getDartId()==null?'':ads.getDartId())+
                        //genTD(ads.getDartId()==null?'':'Created')+
                        genTD(ads.getDartId()==null?'':ads.getStatus())+
                        genTD('')+
                        genTD(ads.getDartErrMsg()==null?'':ads.getDartErrMsg());
                       
           String trs = genTR(tds);            
           trBody += trs; 
          
       } 
       return trBody;
    }  
   
   
   /** Generate table forecast error */   
   public static String generateTableForecastError(Map<String, Exception> mapError)
   {
       String trBody = '';//all TRs and TDs
       for(String st : mapError.keySet())
       {
           String tds = genTD('<a href='+ URL_INSTANCE+'/'+st +'>'+st+'</a>')+ 
                        genTD(mapError.get(st).getMessage());          
           String trs = genTR(tds);            
           trBody += trs;
       }
    
       return trBody;   
   }
   
   
    
    /**Count the current batch apex being excecuted before invoke another batch
    - Only 5 running batch allowed
     */  
    public static Integer countCurrentBatch()
    {
        //Select a.TotalJobItems, a.Status, a.NumberOfErrors, a.MethodName, a.JobType, a.JobItemsProcessed, a.Id, a.CreatedDate, a.CreatedById, a.CompletedDate, a.ApexClass.Name, a.ApexClassId From AsyncApexJob a where Status='Queued'
        return [select count() FROM AsyncApexJob a WHERE Status='Queued'];
    }  
    
    /**  STring to Double */  
    public static Double toDouble(String s)
    {
         
        try{
            return Double.valueOf((s+'').replace(',','.'));
        }catch(Exception ex)
        {
            return 0;
        }
        return 0; // never reach
    }   
    
    /**  STring to Integer */   
    public static Integer toInteger(String s)
    {
        try{
            return (s==null?0:Integer.valueOf((s+'')));
        }catch(Exception ex)
        {
            return 0;
        }
        return 0;// never reach
    }  
    
    /** Excract the user friendly message from webserice call out failure 
    ex:
    Web service callout failed: WebService returned a SOAP Fault: [RequiredError.REQUIRED @ targeting.inventoryTargeting] faultcode=soap:Server faultactor=
    
    -> RequiredError.REQUIRED @ targeting.inventoryTargeting
    */   
    public static String extractMessage(String msg)
    {
        Matcher m = Pattern.compile(DART6Message.DART6_WS_ERROR_PATTERN).matcher(msg);
        while (m.find()) {
            return m.group(1);
        }
        //in case...
        return msg; 
    }
    
    public static DART_Browser_Mapper__c getBrowserMapper(String key)
    {
        DART_Browser_Mapper__c brw = DART_Browser_Mapper__c.getInstance(key); 
                
        if(brw==null) throw new ExceptionGroup.DARTException('No Browser Id Mapping defined in Custom Setting.');
        
        return brw;
            
    }
    
    public static DART_OS_Mapper__c getOSMapper(String key)
    {
        DART_OS_Mapper__c os = DART_OS_Mapper__c.getInstance(key); 
        if(os==null) throw new ExceptionGroup.DARTException('No Operation System Id Mapping defined in Custom Setting.');
        
        return os;
    }
    
    public static boolean isNumber(String s)
    {
        try
        {
            Double.valueOf(s);
            return true;
        }catch(Exception ex)
        {
            return false;
        }   
        
    }
    
    public static String strNotNull(String s){
    	return s == null ? '' : s.trim();
    }
    
    private static final String[] HTML_CHAR  = new String[]{ '<', '>', '"', '\'','&'};
    private static final String[] HTML_CHAR_ENCODED  = new String[]{ '&lt;', '&gt;', '&quot;', '&#39;','&amp;' };
    
    public static String encodeHTML(String s)
    {
        if (s== null || s =='')
            return s;

        for (Integer i = 0; i < HTML_CHAR.size(); ++i) {
            s = s.replace(HTML_CHAR[i], HTML_CHAR_ENCODED[i]);
        }
        
        return s;
    }
    
    /** 
    	@createdDate: 12-12-2014
    	@param: AdserverLogin__c
    	@Des: to get googe access token
     */   
    static String access_token;
    public static final String ENDPOINT_GOOGLE_OAUTH2_TOKEN = 'https://accounts.google.com/o/oauth2/token';
    
    public static String getAccessToken(AdServer_Login__c login)
	{
		//get custtom setting
		//String access_token;
		try
		{
			if(access_token == null)
			{
				if(login.Refresh_Token__c==null)
				{
					throw new ExceptionGroup.DARTException('Refresh Token is not defined in the AdserverLogin. Please login and save via DFPCredential Page.');
				}
				
				String body ='refresh_token=%rtoken%&client_id=%clid%&client_secret=%secret%&grant_type=refresh_token';
				body=body.replace('%rtoken%',login.Refresh_Token__c).replace('%clid%',login.Client_Id__c).replace('%secret%',login.Client_Secret__c);
				
				if(Test.isRunningTest())
				{
					return 'xxxxxxxxxxxxxxxxxx';
				}
				
				access_token = oauth2Request(body,'access_token'); //pick up the field "access_token" from the response
				System.debug('---------->> access_token:' + access_token);
			}
	 	}
	 	catch(Exception ex){throw ex;} 
		 
		//return accesstoken
		return access_token;
	}
	
	
	 public static String oauth2Request(String body,String requestFieldName)
	{
 	    	HTTPWrapper.IRequest reqToken = new HTTPWrapper.SimpleRequest(ENDPOINT_GOOGLE_OAUTH2_TOKEN,'POST',body);
			HTTPWrapper.SimpleResponse resToken = new HTTPWrapper.SimpleResponse(reqToken);
			System.debug('>>>>>>>>>>OAuth2: Resbody: '+resToken.getResBody());
			
			//resp is a JSON string
			JSONParser parser = JSON.createParser(resToken.getResBody()); 
			while (parser.nextToken() != null)
			{
				if((parser.getCurrentToken() == JSONToken.FIELD_NAME))
				{
					String fieldName = parser.getText();
					parser.nextToken();
					if(requestFieldName == fieldName) //'access_token' / refresh_token
					{
						return parser.getText();
						
			   		}else if(fieldName=='error')
			   		{
			   			throw new ExceptionGroup.DARTException('Request to DFP returns error: '+parser.getText());
			   		}
				  }
			  }
		return null;
	}
	
}