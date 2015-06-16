/**
NK: 01/04/2014

*/
global with sharing class WSLineItemCreative {
    
    
    /*
    webservice static String getPreviewUrl(String itemId,String network,String oliId)
    {
        try{
            //System.debug('-------------------->> itemId:' + itemId+'>>>oliId:'+oliId);
             //get country code. i.e. UK.
            OpportunityLineItem oitem = [Select Id,PreviewUrl__c, Screenshot_Site_Tag__c,PriceBookEntry.Product2.Site__r.Country__c from OpportunityLineItem WHERE id=:oliId];
            //Token
            String authToken =  DARTUtil.getRequestToken(oitem.PriceBookEntry.Product2.Site__r.Country__c);//DARTRequestToken.performClientLogin();
            
            LineItemCreativeAssociationService.Authentication authService = new LineItemCreativeAssociationService.Authentication();
            authService.Authentication_Type='ClientLogin';
            authService.token = authToken;
            authService.type_x= 'ClientLogin';
            
            
            LineItemCreativeAssociationService.SoapRequestHeader header = new LineItemCreativeAssociationService.SoapRequestHeader();
            header.applicationName = 'LineItemCreativeAssociationService';
            header.authentication=authService;
            header.networkCode= '5144';//network;//'5144';
            
            
            LineItemCreativeAssociationService.LineItemCreativeAssociationServiceInterfacePort serviceRequest = new LineItemCreativeAssociationService.LineItemCreativeAssociationServiceInterfacePort();
            serviceRequest.RequestHeader = header;
            
            
            LineItemCreativeAssociationService.Statement filterStatement = new LineItemCreativeAssociationService.Statement();
            
            String querySt = 'WHERE lineItemId = '+itemId; //48012790//2-creatives: 49875190
            
            filterStatement.query = querySt;
            
            LineItemCreativeAssociationService.LineItemCreativeAssociationPage page1 =  serviceRequest.getLineItemCreativeAssociationsByStatement(filterStatement);
            
            Long creativId = null;      
            
            if (page1.totalResultSetSize > 0) { 
                    for(LineItemCreativeAssociationService.LineItemCreativeAssociation pg : page1.results ){
                        System.debug('-------------------->> pg.creativeId:' + pg.creativeId+'>>>>>>>>creativeSetId:'+pg.creativeSetId);
                        creativId = pg.creativeId;
                    }
            }
            
            
            Long lineItemId = Long.valueOf(itemId);//'48012790'
            Long creativeId = creativId; //Long.valueOf('39136183270');
            //String siteUrl = 'http://www.gumtree.com/flats-and-houses-for-rent-offered';
            String siteUrl =  oitem.PreviewUrl__c;
            String previewUrl = serviceRequest.getPreviewUrl(lineItemId, creativeId, siteUrl);
            
            System.debug('***-------------->> previewUrl:' + previewUrl);
            
            return previewUrl;
            
        }catch(Exception ex)
        {
        	System.debug('***>>>ex:' + ex);
            return 'Apex Error: '+ex;
            
        }
        
        
    }
    */
    webservice static String createShots(boolean allLine,String oppId, String itemIds)
    {
        try
        {
        	System.debug('-------------------->> itemIds:' + itemIds+'>>>>oppId:'+oppId);
        	OpportunityLineItem[] oitems;
        	if(!allLine)
        	{
        		oitems = [Select PriceBookEntry.Product2.RecordType.Name ,RepAdConfirm1__c,RepAdConfirm2__c,PostAdConfirm1__c,PostAdConfirm2__c,Id,Product_Name__c,Ad_Id__c,Screenshot_Site_Tag__c,Adserver_ID_Network__c,PreviewUrl__c, PriceBookEntry.Product2.Site__r.Country__c from OpportunityLineItem WHERE id IN:itemIds.split(',') AND PriceBookEntry.Product2.RecordType.Name=:DARTUtil.DART6];
        	}
        	else
        	{
        		oitems = [Select PriceBookEntry.Product2.RecordType.Name ,RepAdConfirm1__c,RepAdConfirm2__c,PostAdConfirm1__c,PostAdConfirm2__c,Id,Product_Name__c,Ad_Id__c,Screenshot_Site_Tag__c,Adserver_ID_Network__c,PreviewUrl__c, PriceBookEntry.Product2.Site__r.Country__c from OpportunityLineItem WHERE OpportunityId=:oppId  AND PriceBookEntry.Product2.RecordType.Name=:DARTUtil.DART6];
        	}
        	
        	System.debug('-------------------->> oitems:' + oitems);
        	Set<String> setIAdIds = new Set<String>();
        	 Map<String,String> mapUrl = new Map<String,String>(); 
        	 List<String> listError = new List<String>();
        	 //validate the dfp required field
        	 for(OpportunityLineItem oitem: oitems)
        	 {
        	    Validator valid = new Validator(oitem);
	            if(!valid.checkError())
	            {
	            	//return 'Apex Error: Validation: '+valid.getError();
	            	listError.addAll(valid.getError());
	            }
	            setIAdIds.add(oitem.Ad_Id__c);
	            mapUrl.put(oitem.Ad_Id__c,oitem.PreviewUrl__c);
        	 }
        	 if(!listError.isEmpty())
        	 {
        	 	return 'Apex Error: Validation: '+listError;
        	 }
        	 if(oitems.isEmpty())
        	 {
        	 	return 'Apex Error: Validation: Not DART6 Product! ';
        	 }
        	 String creativeFiltering = DartUtil.generateIds(setIAdIds);
        	 
        	 Map<String,String> mapOliCreative = new Map<String,String>(); 
	 	      
	           	// NK:24/03/2015. Token
	            AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6,oitems[0].PriceBookEntry.Product2.Site__r.Country__c);
				String authToken =  DARTUtil.getAccessToken(login);
	             
	            //v2015
	            Map<String,String> inputHttpHeaders_x = new Map<String, String>();    
	        	inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);            
		          
            	//-----------------------
	            LineItemCreativeAssociationService.SoapRequestHeader header = new LineItemCreativeAssociationService.SoapRequestHeader();
	            header.applicationName = 'LineItemCreativeAssociationService';
	            header.networkCode = '5144';
	            
	            
	            LineItemCreativeAssociationService.LineItemCreativeAssociationServiceInterfacePort serviceRequest = new LineItemCreativeAssociationService.LineItemCreativeAssociationServiceInterfacePort();
	            serviceRequest.RequestHeader = header;
	            // NK:24/03/2015. 
	             serviceRequest.inputHttpHeaders_x = inputHttpHeaders_x;     //v2015
		         serviceRequest.timeout_x = 120000;
	            
	            
	            LineItemCreativeAssociationService.Statement filterStatement = new LineItemCreativeAssociationService.Statement();
	            
	            //WHERE lineItemId IN ('48012550','48012790')
	            String querySt = 'WHERE lineItemId IN '+ creativeFiltering +' AND Status=\'ACTIVE\''; //oitem.Ad_Id__c ; //48012790//2-creatives: 49875190
	            
	            System.debug('-------------------->> querySt:' + querySt);
	            filterStatement.query = querySt;
	            
	            LineItemCreativeAssociationService.LineItemCreativeAssociationPage page1 =  serviceRequest.getLineItemCreativeAssociationsByStatement(filterStatement);
	            
	            Long creativId = null;      
	            List<String> creativeIds = new List<String>();
	            String arrayCreativeOLI = '';
	            if (page1.totalResultSetSize > 0) { 
	                    for(LineItemCreativeAssociationService.LineItemCreativeAssociation pg : page1.results ){
	                        System.debug('-------------------->> pg.creativeId:' + pg.creativeId+'>>>>>>>>creativeSetId:'+pg.creativeSetId);
	                        //pg.lineItemId
	                        creativId = pg.creativeId;
	                        creativeIds.add(pg.creativeId+'');
	                        arrayCreativeOLI+=pg.creativeId+'-'+pg.lineItemId+'_';
	                        mapOliCreative.put(pg.creativeId+'',pg.lineItemId+'');
	                    }
	            }else
	            {
	            	return 'Apex Error: No active Creatives found in DFP for these Ads: '+setIAdIds+' In network: '+oitems[0].Adserver_ID_Network__c;
	            }
	        	
	        	//A-A1_B-B1...
	        	String creative_items_String = arrayCreativeOLI;//(mapOliCreative+'').replace('{','').replace('}','').replace(' ','').replace(',','_').replace('=','-');
	        	
	        	//return '{"creativeIds":"'+(creativeIds+'').replace('(','').replace(')','').replace(' ','').replace(',','_')+'","adId":"'+oitem.Ad_Id__c+'","network":"'+oitem.Adserver_ID_Network__c+'","siteUrl":"'+oitem.PreviewUrl__c+'","token":"'+authToken+'","productName":"'+oitem.Product_Name__c+'"}';
	        	
        	//to avoid long string in the custom protocol: we query SitePreview Url at jar side 
           return '{"oliIds":"'+(itemIds+'').replace(',','_')+'","by":"'+(!allLine?'oliId':'oppId')+'","oppId":"'+oppId+'","creativeIds":"'+creative_items_String+'","token":"'+authToken+'"}'; 

        }
        catch(Exception ex)
        {
        	System.debug('***>>>ex:' + ex);
            return 'Apex Error: '+ex;
    	}
    }
    class Validator implements IValidator{
    	String[] listError;
    	OpportunityLineItem oitem;
    	public Validator(OpportunityLineItem oitem)
    	{
    		this.oitem = oitem;
    	}
    	public boolean checkError()
    	{
    		listError = new List<String>();
    		//if(oitem.PriceBookEntry.Product2.RecordType.Name!=DARTUtil.DART6)
    		//{
    		//	listError.add('Not DART6 Product: '+oitem.Product_Name__c); 
    		//	return false;
    		//}
    		if(oitem.Ad_Id__c == null)
    		{
    			listError.add('No DFP AdId for product: '+oitem.Product_Name__c); 
    		}
    		if( (!oitem.RepAdConfirm1__c && !oitem.RepAdConfirm2__c && !oitem.PostAdConfirm1__c && !oitem.PostAdConfirm2__c)
    			&& oitem.PreviewUrl__c ==null) 
    		{
    			listError.add('No Preview Url defined for product: '+oitem.Product_Name__c); 
    		}
    		if((!oitem.RepAdConfirm1__c && !oitem.RepAdConfirm2__c && !oitem.PostAdConfirm1__c && !oitem.PostAdConfirm2__c)
    			&& oitem.Screenshot_Site_Tag__c ==null)
    		{
    			listError.add('No Adslot Tag defined for product: '+oitem.Product_Name__c); 
    		}
    		 return (listError.isEmpty());
    	}
    	public String[] getError()
    	{
    		return listError;
    	}
    }
    
    interface IValidator{
    	boolean checkError();
    	String[] getError();
    }
    
    /*
    webservice static String sendShot(String emailTo,String url)
    {
    	try{
    		doSend(new String[]{emailTo},'Screenshot','Please find attached',url);
    		return 'Screnshot Sent!';
    	}
    	 catch(Exception ex)
        {
        	System.debug('***>>>ex:' + ex);
            return 'Apex Error: '+ex;
    	}
    }
     */
    public static String  doSend(String[] addr,String[] ccAddr,String subject,String displayName,String body,String attachedName,String contentId){
           
        if(addr.size()==0) return 'No Target "To" definded!\nNo email sent.';
       
       try{
       		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
	        mail.setToAddresses(addr); 
	        mail.setCcAddresses(ccAddr);
	       // mail.setSenderDisplayName(displayName);        
	        mail.setSubject(subject);        
	        mail.setBccSender(false);
	        mail.setUseSignature(false);
	        mail.setHtmlBody(body);       
	        mail.setOrgWideEmailAddressId(System.Label.ScreenshotOrgWideEmail); //Gumtree AdOps: adops@gumtree.com
	        
	        //PageReference pdfPage=new PageReference(urlPDF); //vf page generated          
	        
	        //Blob content = pdfPage.getContent();
	        ContentVersion cv = [Select Id,VersionData FROM ContentVersion where ID=:contentId];
	        //System.debug('>>> attach content: ' + attachContent);    
	        //System.debug('>>> page content size in email: ' + content.size());                
	        
	        //create an attachment object to populate with data
	        Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
	        fileAttachment.setBody(cv.VersionData);
	        fileAttachment.setFileName(attachedName);        
	        fileAttachment.setContentType('application/pdf');
	        //add attachments to mail message
	        mail.setFileAttachments(new Messaging.EmailFileAttachment[]{fileAttachment}); 
	        
	        //start sending
	        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	        
	        return 'ok';
        
       }catch(Exception ex)
       {
       		System.debug('>>>>>>>>>Dosend error:'+ex);
       		return 'Apex Error:'+ex;
       }
       
 
    }  
    
    static String[] reservedWindowsChar = new List<String>{'<','>',':','\'','/','\\','*','"'};
    
    public static String validateFileName(String fname)
	{
	  //alert('reservedWindowsChar >>>:'+reservedWindowsChar );
	  for(integer x=0;x<reservedWindowsChar.size();x++)
	  {
	    fname=fname.replace(reservedWindowsChar[x],'').replace(' ','_');
	  }
	  return fname;
	}
	
//window.location.href='dfpto://sid?{!API.Session_ID}#ins?{!$Api.Enterprise_Server_URL_270}#lid?{!Opportunity.Id}#nid?{!OpportunityLineItem.Adserver_ID_Network__c}#oid?{!OpportunityLineItem.Adserver_ID_Order_ID__c}#guser?#gpass?#outputName?screenshot1.png';

//https://c.cs17.visual.force.com/apex/GeneratePDFV2?opliId=00kw000000Ptud0,00kw000000Ptucz,00kw000000Ptucz&Oppid=006w000000VJ7rn
}