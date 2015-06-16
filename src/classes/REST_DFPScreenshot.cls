/**
NK: 24/04/2014
Rest for DFP Screenshot

Change log:
- GTCRM-635 - Update tags to include industry from account and display as default (SP)
- GTCRM-635 - Update author of content to opportunity owner (SP)

*/

@RestResource(urlMapping='/DFPSC/*')
global without sharing class REST_DFPScreenshot {
    public final static String SHOT_TYPE_CHUNCK = 'Screenshot-Image';
    public final static String SHOT_TYPE_FULL_PDF = 'Screenshot-PDF';
    
    final static String CONTENT_URL = 'https://c.$inst$.content.force.com/sfc/servlet.shepherd/version/download/$contId$?operationContext=CHATTER';
 
    //final static String PDF_URL =  System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/GeneratePDFV2?Oppid=$oppId$&groupId=$groupId';
    
    //https://c.na7.content.force.com/sfc/servlet.shepherd/version/download/068A00000004Qk0?operationContext=CHATTER&asPdf=false
    
    //create screenshot as attachment and notify Opportunity Owner
    @HttpPost
    global static String doPost1(String groupId,String olid,String adId,String creativeId, String oppId, String contentType, String body,boolean isLast) {
        //String oppId = RestContext.request.params.get('oppId');
        String result = '' ;
        String instance = getInstanceName();
        try {
            
            Opportunity opp = [Select Id, Industry__c , Account.Industry, Opportunity_Group__c, Owner.Name, Name ,Owner.Email, OwnerId, Campaign_Name__c from Opportunity where Id=:oppId];
            
            
            //Attachment att  = new Attachment(Name=olid+'_'+adId,ParentId=oppId,ContentType=contentType,Body=Encodingutil.base64Decode(body));
            //insert att;
            
           
            
            //https://cs17.salesforce.com/00Xg0000000MCGu?setupid=CommunicationTemplatesEmail
            // send email here
            //https://c.cs17.content.force.com/servlet/servlet.FileDownload?file=00Pg0000001DFFa
            
           
            if(!isLast)
            {                
                 //create temp content as image
                createContent(opp,SHOT_TYPE_CHUNCK , groupId, creativeId, olid,adId,Encodingutil.base64Decode(body));
               
                //System.debug('>>>>Created Content image:'+cv);
            }else
            {
                  //String ebody = 'Screenshot is created and store as attachment to Opportunity <a href="https://c.cs17.content.force.com/servlet/servlet.FileDownload?file=$_attId_$">Here</a>';
                     
                  String pdfUrl = getPDFURL(); //PDF_URL;
                  pdfUrl = pdfUrl.replace('$oppId$',oppId).replace('$groupId$',groupId);
                   //'https://c.$ints$.visual.force.com/apex/GeneratePDFV2?Oppid='+oppId+'&groupId='+groupId;
                  //String pdfUrl = 'https://c.cs17.visual.force.com/apex/GeneratePDFV2?Oppid=006w000000VmKRq&groupId=HLBCHIKISG';
                    
                  //Blob.valueOf('test001a v2');
                  Set<String> tobeDeletedImages = new Set<String>();  
                  Set<String> allCreatives = new Set<String>();  
                  Set<String> allAds = new Set<String>();  
                  Set<String> allLines = new Set<String>();  
                  
                   System.debug('>>>>>>>Created Content PDF <<<<<<<<<<:');
                  
                  for(ContentVersion image : [Select Id,Group_Id__c,Creative__c,AdId__c,Line_Item__c,ContentDocumentId from ContentVersion where Group_Id__c =: groupId AND Shot_Type__c=:SHOT_TYPE_CHUNCK])
                  {
                    System.debug('>>>>>>>image:'+image);
                    tobeDeletedImages.add(image.ContentDocumentId);
                    allCreatives.add(image.Creative__c);
                    allAds.add(image.AdId__c);
                    allLines.add(image.Line_Item__c);
                  }
                   System.debug('>>>>>>>allAds:'+allAds);
                   System.debug('>>>>>>>allLines:'+allLines);
                   System.debug('>>>>>>>allCreatives:'+allCreatives);
                   
                  //PageReference pdfPage=new PageReference('https://c.cs17.visual.force.com/apex/GeneratePDFV2?Oppid='+oppId); //vf page generated          
                  //PageReference pdfPage = new PageReference(pdfUrl.replace('$ints$',instance)); //vf page generated
                  System.debug('>>>>>>>pdfUrl:'+pdfUrl);
                  PageReference pdfPage = new PageReference(pdfUrl); //vf page generated
                  
                   Blob content =  (Test.isRunningTest()?Blob.valueOf('test'):pdfPage.getContent());
                  //create pdf 
                  String pdfId =  createContent(opp,SHOT_TYPE_FULL_PDF , groupId, allCreatives.size()+'', allLines.size()+'',allAds.size()+'',content);
                  
                  //clear images, keep only pdf
                  //delete ContentDocument not Version(not writable)
                 System.debug('>>>>>>>tobeDeletedImages:'+tobeDeletedImages);
                 Delete [Select Id from ContentDocument WHERE ID IN: tobeDeletedImages];
                  
                  
                  //email notification 
                  String ebody = '';
                  String subject = '';  
                  EmailTemplate[] emlt = [Select Id,HtmlValue, DeveloperName,Subject from EmailTemplate WHERE DeveloperName=:System.Label.ScreenshotAlert_EN];
                 
                  if(!emlt.isEmpty())
                  {
                    ebody= emlt[0].HtmlValue;
                    ebody = ebody.replace('{!opp.Owner}',opp.Owner.Name)
                    .replace('{!opp.Id}','https://'+URL.getSalesforceBaseURL().getHost()+'/'+opp.Id)
                    .replace('{!opp.Name}',opp.Name)                    
                    .replace('{!lineItem}',allLines.size()+'')
                    .replace('{!Ads}',allAds.size()+'')
                    .replace('{!Creative}',allCreatives.size()+'')
                    .replace('{!Message}','');
                    
                    //String emailPdfUrl = CONTENT_URL.replace('$inst$',instance).replace('$contId$' ,pdfId);
                    String emailPdfUrl = getContentForceURL().replace('$contId$' ,pdfId);
                    
                    
                    ebody = ebody.replace('{!pdfURL}',emailPdfUrl);
                    
                    
                    subject = (emlt[0].Subject).replace('{!opp.Name}',opp.Name);
                  }else
                  {//in case no email template defined
                    ebody = 'Screenshot is created and store as attachment to Opportunity <a href="'+'https://'+URL.getSalesforceBaseURL().getHost()+'/$_attId_$">Here</a>';
                    ebody = ebody.replace('$_attId_$',oppId);
                    subject = 'Screenshot Created';
                  }
                  
                  ContentVersion pdf = [Select Id,Group_Id__c,Creative__c,AdId__c,Line_Item__c,ContentDocumentId from ContentVersion where Id =: pdfId];
                  
                  
                  System.debug('>>>>>>>>pdf.ContentDocumentId:'+pdf.ContentDocumentId);
                  
                  DARTUtil.sendMail(new String[]{opp.Owner.Email}, null, subject, 'Gumtree Robot', ebody);
                
                postFeed(pdf.ContentDocumentId,opp); 
            }
             
            //result = 'success: email sent successfully: '+oppId;
             result = 'success ';
              
             System.debug('>>>>>>>>result:'+result);
        } catch(Exception e) {
            result = e+'';
        }
        
        return result;
    }
    
    /**
    	-in case GT has own custom domin, content.force to download content(file) need to be reflected as described in the method.
    */
    private static String getContentForceURL()
    {
    	String c_domain = get_c_Domain();
    	String realDomain = c_domain.replace('my.salesforce.com','content.force.com');
    	
    	return 'https://'+realDomain+'/sfc/servlet.shepherd/version/download/$contId$?operationContext=CHATTER';
    	
    	//https://gumtree--full--c.cs17.content.force.com/sfc/servlet.shepherd/version/download/068w0000001xzZO?operationContext=CHATTER
    }
    
    /**
    	-> old:
    	System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/GeneratePDFV2?Oppid=$oppId$&groupId=$groupId';
    	->origin:
    	   https://gumtree--full.cs17.my.salesforce.com/apex/GeneratePDFV2?Oppid=$oppId$&groupId=$groupId
    	-> expected: 
    	   https://gumtree--full--c.cs17.visual.force.com/apex/GeneratePDFV2?Oppid=$oppId$&groupId=$groupId
    */
    private static String getPDFURL()
    {
    	//expected: gumtree--full--c
    	String c_domain = get_c_Domain();
    	String realDomain = c_domain.replace('my.salesforce.com','visual.force.com');
    	
    	return 'https://'+realDomain+'/apex/GeneratePDFV2?Oppid=$oppId$&groupId=$groupId$';
    }
    
    /**
    	from: 
    		gumtree--full
    	to: gumtree--full--c
    	
    	returns
    		gumtree--full--c.cs17.my.salesforce.com
    		
    */
    private static String get_c_Domain()
    {
    	//gumtree--full.cs17.my.salesforce.com
    	//gumtree.my.salesforce.com
    	String fullDomain = System.URL.getSalesforceBaseUrl().getHost();
    	//gumtree--full 
    	String domain1 = fullDomain.substring(0,fullDomain.indexOf('.'));
    	
    	//expected: gumtree--full--c
    	String domain1Expect = !isSandbox()?domain1+'--c.'+System.Label.instanceName:domain1+'--c';
    	 
    	
    	return fullDomain.replace(domain1,domain1Expect);
    	
    }
    /* to fix production domain
    	there is no instace number visible but domain name (e.g. gumtree.my.salesforce.com)*/
    private static boolean isSandbox()
    {
    	return [select Id, IsSandbox from Organization limit 1].IsSandbox;
    }
 
    
    public static String  createContent(Opportunity opp,String shot_type,String groupId,String creativeId,String olid,String adId,Blob content)
    {
            //cv.ContentDocumentId='069g0000000D68R'; //for new version only!!!
                ContentVersion cv = new ContentVersion(
                Title='Screenshot_'+opp.Campaign_Name__c,
                OwnerId = (Test.isRunningTest()?UserInfo.getUserId(): opp.OwnerId), //NK:20/08/2014:fixed blank owner in production
                FirstPublishLocationId = System.Label.LibraryId, //'058g00000000ErsAAE',   // library id;
                VersionData = content,  
                PathOnClient= WSLineItemCreative.validateFileName(opp.name)+(SHOT_TYPE_CHUNCK.equals(shot_type)?'.PNG':'.PDF'),
                Creative__c = creativeId,
                Line_Item__c = olid,
                Group_Id__c = groupId,
                Shot_Type__c = shot_type,  
                Opportunity__c = opp.Id,
                AdId__c = adId,
                TagCsv =  (opp.Industry__c==null?'':opp.Industry__c) +
                          (','+'Display') +
                          + (opp.Account.Industry==null?'':','+opp.Account.Industry)
                          + (opp.Opportunity_Group__c==null?'':','+opp.Opportunity_Group__c)
            );
            insert cv;
            System.debug('>>>>Created Content type:'+shot_type+'>>creativeId:'+creativeId+'>>>:'+cv);
         return cv.Id+'';
    }
    private static String getInstanceName()
    {
        return URL.getSalesforceBaseURL().getHost().split('[.]')[0];
        
    }
    //NK: 19/08/2014:11:14pm
    //version 31+
    public static void postFeed(String contentDocId, Opportunity opp)
    {
        ConnectApi.MentionSegmentInput mention = new ConnectApi.MentionSegmentInput();
        mention.id = opp.OwnerId;
        
        //CONTENT_URL = 'https://c.$inst$.content.force.com/sfc/servlet.shepherd/version/download/$contId$?operationContext=CHATTER';
        //NK:25/03/2015 
        String pdfUrl = getContentForceURL().replace('$contId$' ,contentDocId);//CONTENT_URL;
        //pdfUrl = '/'+contentDocId;//pdfUrl.replace('$inst$',getInstanceName()).replace('$contId$',contentDocId);
        ConnectApi.LinkAttachmentInput  pdfLink = new ConnectApi.LinkAttachmentInput ();
        pdfLink.url = pdfUrl;
        pdfLink.urlName =  opp.Name;
        
        // Controls the attachment to the feed and shows preview
        ConnectApi.ContentAttachmentInput contentAttachmentInput = new ConnectApi.ContentAttachmentInput();    
        contentAttachmentInput.contentDocumentId = contentDocId;
        
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text = ' Please see your screenshots for '+opp.Campaign_Name__c;
        
        messageBodyInput.messageSegments.add(mention);
        messageBodyInput.messageSegments.add(textSegmentInput);
//        messageBodyInput.messageSegments.add(pdfLink);
        
        
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        // Controls the attachment to the feed and shows preview
        //feedItemInput.attachment = pdfLink;//contentAttachmentInput; contentAttachmentInput = create another attachment from content - we dont need 2
        feedItemInput.attachment = contentAttachmentInput;
        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;

        feedItemInput.subjectId = opp.Id;
        
        //post feed
        ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(null, feedItemInput, null);
        
        //asign topic to feed
        ConnectApi.Topics.assignTopicByName(null,feedElement.Id,'Screenshots');
        //ConnectApi.ConnectApiException: "contentDocumentId" value does not refer to a content document
    }
}