public with sharing class DFPCredentialController {
	
    public static final String ENDPOINT_GOOGLE_OAUTH2_TOKEN = 'https://accounts.google.com/o/oauth2/token';

	public List<AdserverLoginDTO> lstAdsDTO{get; set;}
	public String selectedValue { get; set; }
	public Boolean isChecked{get;set;}

	public String refreshToken{get; set;}
	public Boolean isSaveToken{get; set;}
	
	public static final String REDIRECT_URI = 'https://'+URL.getSalesforceBaseURL().getHost() + Page.DFPCredentialPage.getUrl()+'?retgoogle=1';
	public static final String SCOPE = 'https://www.googleapis.com/auth/dfp';
	final String CREDENTIAL_PAGE_NAME = Page.DFPCredentialPage.getUrl();  
	
	
	public DFPCredentialController()
	{
		
	
		
		lstAdsDTO  = new List<AdserverLoginDTO>();
		
		for(AdServer_Login__c adslog : [SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c, Active__c, Refresh_token__c FROM AdServer_Login__c WHERE Publisher_ID__c = null ])
		{
			AdserverLoginDTO adsDto = new AdserverLoginDTO(adslog, false);
			lstAdsDTO.add(adsDto);
		}		
		
		// Get authorization code after authentication
		String AuthorizeCode = ApexPages.currentPage().getParameters().get('code');
			
		// Exchange authorization code for refresh token
		if(AuthorizeCode != null)	
		{
			isSaveToken=true;
			refreshToken = exchangeCodeForRefreshToken(AuthorizeCode);
		}
		
	}
	
	public PageReference processCredential()
	{
		
		if(selectedValue==null || selectedValue=='')
		{
			ApexPages.AddMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Please select one record to process.'));
			return null;
		}
		
		System.debug('---------------------->>selectedValue:'+ selectedValue);
		
		PageReference pg;
		
		List<AdServer_Login__c> lstAdLoginSelected = [Select Client_Secret__c, Client_Id__c, Refresh_Token__c From AdServer_Login__c Where id =: selectedValue];
		if(!lstAdLoginSelected.isEmpty())
		{
			AdServer_Login__c lg = lstAdLoginSelected.get(0);
			if(lg.Client_Id__c == null || lg.Client_Secret__c == null)
			{
				ApexPages.AddMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Required field missing: '+(lg.Client_Id__c==null?'Client_Id__c':'Client_Secret__c')+' in the selected record.'));
				return null;
			} 
			lg.RT_Waiting__c = true;
			update lg;

			String urlOfflineAccess = 'https://accounts.google.com/o/oauth2/auth?access_type=offline&approval_prompt='+
			   'force&scope='+ SCOPE +'&response_type=code'+
			   '&client_id='+ lg.Client_Id__c +
			   '&redirect_uri='+ EncodingUtil.urlEncode(REDIRECT_URI, 'UTF-8');

			pg = new PageReference(urlOfflineAccess);
			pg.setRedirect(true);
		}
		
		return pg;
	}
	
	
	
	public PageReference clickTopenRecord()
	{
		return null;
	}
	
	/** after user login, google returns the oauthCode, use it to exchange for the refresh token */
	public  String exchangeCodeForRefreshToken(String oauthCode)
	{
		String refresh_token;
		try
		{
			//AdxSetting__c adxSetting = getSetting();
			List<AdServer_Login__c> lstAds = getListAdsLogin();
			
			System.debug('------------------->>REDIRECT_URI:' + REDIRECT_URI);
			
			String body ='code=%code%&client_id=%clid%&client_secret=%secret%&redirect_uri=%redirecturi%&grant_type=authorization_code'; //  refresh_token
			body=body.replace('%code%',oauthCode).replace('%clid%',lstAds.get(0).Client_Id__c).replace('%secret%',lstAds.get(0).Client_Secret__c).replace('%redirecturi%',REDIRECT_URI);
			
			refresh_token = DARTUtil.oauth2Request(body,'refresh_token'); //pick up the field "refresh_token" from the response
			
	 	}
	 	catch(Exception ex){throw ex;} 
		
		return refresh_token;
	}
	
	public PageReference saveToken()
	{
		isSaveToken=false;
		try
		{
			List<AdServer_Login__c> lstAdsLog =  getListAdsLogin();
			System.debug('---------------->>lstAdsLog:' + lstAdsLog);
			lstAdsLog.get(0).Refresh_Token__c = refreshToken;
			lstAdsLog.get(0).RT_Waiting__c = false;
			update lstAdsLog;
		}
		catch(Exception ex){ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex+''));}

		PageReference pg = new PageReference(CREDENTIAL_PAGE_NAME);
		pg.setRedirect(true);
		return pg;
	}
	
	public PageReference cancel()
	{
		
		List<AdServer_Login__c> lstAdsLog =  getListAdsLogin();
		lstAdsLog.get(0).RT_Waiting__c = false;
		update lstAdsLog;
		PageReference pg = new PageReference(CREDENTIAL_PAGE_NAME);
		pg.setRedirect(true);
		return pg;
	}
	
	public static List<AdServer_Login__c> getListAdsLogin()
	{
		List<AdServer_Login__c> lstLog = [SELECT Client_Id__c, Client_Secret__c, Refresh_Token__c, RT_Waiting__c From AdServer_Login__c WHERE RT_Waiting__c = true limit 1];
		if(lstLog.isEmpty())
		{
			throw new ExceptionGroup.DARTException('There is no Adserver login to get refresh token.');
		}
		
		return lstLog;
	}
	
	
	public class AdserverLoginDTO
	{
		public AdServer_Login__c adserverLogin{get; set;}
		public Boolean isSelected{get;set;}
		
		public AdserverLoginDTO(AdServer_Login__c adserverLogin, Boolean isSelected)
		{
			this.isSelected = isSelected;
			this.adserverLogin = adserverLogin;
		}
		
	}

}