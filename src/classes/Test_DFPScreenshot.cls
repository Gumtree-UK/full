@isTest(seeAllData=true)
private class Test_DFPScreenshot {

	static TestDataGenerator testDATA = new TestDataGenerator();
	
	 public static testMethod void testCreateShot(){
	 	
	 	testDATA.createCredential();
       // testDATA.createTargetingHierarchy();
        
        String lineItemIds = '';
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        Opportunity opp = testDATA.opp;
        
        
        List<OpportunityLineItem> lstItems = createNewOppItems(opp.Id,2,null);
        List<OpportunityLineItem> lstItemsErr = createNewOppItemsError(opp.Id,1,null);
        
        Set<String> setoliIds = new Set<String>();
        for(OpportunityLineItem oppItem : lstItems)
        {
            setoliIds.add(oppItem.Id);
        }
          
       System.debug('>>>>>>>>>>> TEST setoliIds:'+setoliIds);
       
        Test.startTest();
        String result = WSLineItemCreative.createShots(false, opp.Id,lstItemsErr[0].Id ); 
        
        String result2 = WSLineItemCreative.createShots(false, opp.Id,lstItems[0].Id+','+lstItems[1].Id ); 
        System.debug('>>>>>>>>>>> result createShots:'+result);
        //String fname = WSLineItemCreative.validateFileName('test>');
        
        REST_DFPScreenshot.doPost1('11111', lstItems[0].Id, '123456', '56789', opp.Id,REST_DFPScreenshot.SHOT_TYPE_CHUNCK , '**body**', false);
        REST_DFPScreenshot.createContent(opp, REST_DFPScreenshot.SHOT_TYPE_CHUNCK, '11111', '56789', lstItems[0].Id, '123456', Blob.valueOf('test blob body'));
        
        PageReference pageRef = Page.GeneratePDFV2;
        pageRef.getParameters().put('Oppid', opp.Id);
        pageRef.getParameters().put('groupId', '11111');
        Test.setCurrentPage(pageRef);
        
	 	GumtreeGeneratePDFV2 pdfGen  = new GumtreeGeneratePDFV2();
	 	
        REST_DFPScreenshot.doPost1('11111', lstItems[0].Id, '123456', '567890', opp.Id,REST_DFPScreenshot.SHOT_TYPE_FULL_PDF, '**body**', true);
	 	 
	 	pdfGen  = new GumtreeGeneratePDFV2();
	 	
	 	WSLineItemCreative.doSend(new String[]{'test@test.com'}, new String[]{'test@test.com'}, 'test', 'displayName', 'body', 'attachedName', 'contentId');
	 	
	 	WSLineItemCreative.doSend(new String[]{}, new String[]{}, 'test', 'displayName', 'body', 'attachedName', 'contentId');
	 	
        
		
	 	
	 	
        Test.stopTest();
          
	 }
	 
    
    static Map<String,  Map<String, RecordType> > mapRecordType = null;
    public static RecordType getRecordType(String objName,String recName)
    {
    	if(mapRecordType==null)
    	{
    		mapRecordType = new Map<String,  Map<String, RecordType>>();
    		 
            for(RecordType rec : [Select id,SobjectType,DeveloperName, name From RecordType])
            {
            	if(!mapRecordType.containsKey(rec.SobjectType))
            	{
            		 mapRecordType.put(rec.SobjectType,new Map<String, RecordType>());
            	}
                mapRecordType.get(rec.SobjectType).put(rec.DeveloperName, rec);    
            }
         
    	}
        //Set<String> setRecName = new Set<String>{DARTUtil.DART5, DARTUtil.DART6};
        return mapRecordType.get(objName).get(recName);
    }
    public static List<OpportunityLineItem> createNewOppItems(String oppId,Integer numToCreate,String targetingId)
    {
        List<OpportunityLineItem> lstLineItems = new List<OpportunityLineItem>();
        List<PricebookEntry> lstPrdbEnDart = createNewPricebookEntry(numToCreate);
        for(Integer i=0; i<numToCreate; i++)
        {
            String orderId = (i==0?'':'123456');
            String advertiserId=(i==0?'':'654321');
            OpportunityLineItem oppItem = new OpportunityLineItem( 
                              OpportunityId= oppId,
                              from_Date__c =  date.newInstance(System.today().year(), System.today().month(), i),
                              until_Date__c = date.newInstance(System.today().year()+1, System.today().month()+6, i),
//                              Quantity =  200+i,
                              Quantity =  200,
                              Billing_category__c='CPC',
                              Package__c='Multiformat1',
                              Description='Test Desc',
                              Check_Inventory__c=true,
                              DFP_Time_Monday__c ='11:00 - 11:59;12:00 - 12:59;23:00 - 23:59',
                              DFP_Time_Tuesday__c ='12:00 - 12:59;23:00 - 23:59',
                              DFP_Time_Wednesday__c ='12:00 - 12:59;23:00 - 23:59',
                              DFP_Time_Thursday__c ='12:00 - 12:59;23:00 - 23:59',
                              DFP_Time_Friday__c ='12:00 - 12:59;23:00 - 23:59',
                              DFP_Time_Saturday__c ='12:00 - 12:59;23:00 - 23:59',
                              DFP_Time_Sunday__c ='12:00 - 12:59;23:00 - 23:59', 
                              AdDayOfWeek__c='Monday;Sunday',
                              AdHourOfDay__c='12:00 - 12:59;23:00 - 23:59', //23:00 - 23:59
                              TotalPrice=10.0,
                              AdWebBrowsers__c='Google Chrome (x.x)',
                              AdOperatingSystems__c='Macintosh',
                              Adserver_ID_Order_ID__c=orderId,
//                              Adserver_Adv_Advertiser_ID__c=advertiserId,
                              FC_Ad_served_every__c=5,
                              FC_Quantity__c=100,
                              FC_Period__c='Days',
                              PricebookEntryId=lstPrdbEnDart.get(i).id,
                              Targeting__c=targetingId,
                              Ad_Id__c='123456',
                             // Screenshot_Site_Tag__c='ad-slot-mpu',
                              //Adserver_ID_Network__c='23456',
                              PreviewUrl__c='www.gumtree.com/house'
                              );
            
            lstLineItems.add(oppItem);
        }
        System.debug('-------------->xxxxxxxxxxxxxx:lstLineItems'+lstLineItems);
        
        insert lstLineItems;
        
        return lstLineItems;
    } 
    public static List<OpportunityLineItem> createNewOppItemsError(String oppId,Integer numToCreate,String targetingId)
    {
        List<OpportunityLineItem> lstLineItems = new List<OpportunityLineItem>();
        List<PricebookEntry> lstPrdbEnDart = createNewPricebookEntry(numToCreate);
        for(Integer i=0; i<numToCreate; i++)
        {
            String orderId = (i==0?'':'123456');
            String advertiserId=(i==0?'':'654321');
            OpportunityLineItem oppItem = new OpportunityLineItem( 
                              OpportunityId= oppId,
                              from_Date__c =  date.newInstance(System.today().year(), System.today().month(), i),
                              until_Date__c = date.newInstance(System.today().year()+1, System.today().month()+6, i),
//                              Quantity =  200+i,
                              Quantity =  200,
                              Billing_category__c='CPC',
                              Package__c='Multiformat1',
                              Description='Test Desc',
                              Check_Inventory__c=true,
                              DFP_Time_Monday__c ='11:00 - 11:59;12:00 - 12:59;23:00 - 23:59',
                              DFP_Time_Tuesday__c ='12:00 - 12:59;23:00 - 23:59',
                              DFP_Time_Wednesday__c ='12:00 - 12:59;23:00 - 23:59',
                              DFP_Time_Thursday__c ='12:00 - 12:59;23:00 - 23:59',
                              DFP_Time_Friday__c ='12:00 - 12:59;23:00 - 23:59',
                              DFP_Time_Saturday__c ='12:00 - 12:59;23:00 - 23:59',
                              DFP_Time_Sunday__c ='12:00 - 12:59;23:00 - 23:59', 
                              AdDayOfWeek__c='Monday;Sunday',
                              AdHourOfDay__c='12:00 - 12:59;23:00 - 23:59', //23:00 - 23:59
                              TotalPrice=10.0,
                              AdWebBrowsers__c='Google Chrome (x.x)',
                              AdOperatingSystems__c='Macintosh',
                              Adserver_ID_Order_ID__c=null,
//                              Adserver_Adv_Advertiser_ID__c=advertiserId,
                              FC_Ad_served_every__c=5,
                              FC_Quantity__c=100,
                              FC_Period__c='Days',
                              PricebookEntryId=lstPrdbEnDart.get(i).id,
                              Targeting__c=targetingId,
                              Ad_Id__c=null,
                             // Screenshot_Site_Tag__c='ad-slot-mpu',
                              //Adserver_ID_Network__c='23456',
                              PreviewUrl__c=null
                              );
            
            lstLineItems.add(oppItem);
        }
        System.debug('-------------->xxxxxxxxxxxxxx:lstLineItems'+lstLineItems);
        
        insert lstLineItems;
        
        return lstLineItems;
    } 
    public static  List<PricebookEntry> createNewPricebookEntry(Integer numToCreate)
    {
       List<PricebookEntry>  lstPrdbEnDart = new List<PricebookEntry>();
        testDATA.getPricebook2();
         List<Product2>  lstPrd2 =createNewProduct2(numToCreate);

        for(integer i=0; i<numToCreate; i++)
        {
            PricebookEntry pbEntry2 = new PricebookEntry(
                        unitPrice=100,
                        Pricebook2Id = testDATA.pb2.Id,
                        Product2Id = lstPrd2.get(i).Id,
                        UseStandardPrice = false,
                        IsActive = true
                        );
            lstPrdbEnDart.add(pbEntry2);
        }
        insert lstPrdbEnDart;
        
        return lstPrdbEnDart;
    }
    public static List<Product2> createNewProduct2(Integer numToCreate)
    {
    	Advertising_Medium__c adm = new Advertising_Medium__c(Screenshot_Site_Tag__c='ad-slot-mpu');
    	insert adm;
    	   Site__c site = new Site__c(Name='Test1 Site', Country__c='DE');
            insert site;
            
        List<Product2>  lstPrd2 = new List<Product2>();
        RecordType recType = getRecordType('Product2','DART6');
        for(Integer i=0; i<numToCreate; i++)
        {
            Product2 prd2 = new Product2(
                            Name='Test product'+i, 
                            RecordTypeId=recType.Id , 
                            IsActive = true, No_Availability_Forecast__c=false,
                            Advertising_Medium__c =adm.Id,
                            Site__c=site.Id
                           );
                        
            lstPrd2.add(prd2);
        }
        insert lstPrd2;
        
        return lstPrd2;
    }
	 public static testMethod void testLineItemCreativeAssociationService(){
	 	
	 	LineItemCreativeAssociationService lcaService = new LineItemCreativeAssociationService();
	 	 
	 	LineItemCreativeAssociationService.ActivateLineItemCreativeAssociations a1 = new LineItemCreativeAssociationService.ActivateLineItemCreativeAssociations();
	 	LineItemCreativeAssociationService.AdSenseAccountError a2 = new LineItemCreativeAssociationService.AdSenseAccountError();
	 	LineItemCreativeAssociationService.ApiError a3 = new LineItemCreativeAssociationService.ApiError();
	 	LineItemCreativeAssociationService.ApiException a4  = new LineItemCreativeAssociationService.ApiException();
	 	//LineItemCreativeAssociationService.Authentication a5 = new LineItemCreativeAssociationService.Authentication();
	 	LineItemCreativeAssociationService.BooleanValue a6 = new LineItemCreativeAssociationService.BooleanValue();
	 	//LineItemCreativeAssociationService.ClientLogin a7 = new LineItemCreativeAssociationService.ClientLogin();
	 	//LineItemCreativeAssociationService.createLineItemCreativeAssociation_element a8 = new LineItemCreativeAssociationService.createLineItemCreativeAssociation_element();
	 	//LineItemCreativeAssociationService.createLineItemCreativeAssociationResponse_element a9 = new LineItemCreativeAssociationService.createLineItemCreativeAssociationResponse_element();
	 	LineItemCreativeAssociationService.createLineItemCreativeAssociations_element a10  =  new LineItemCreativeAssociationService.createLineItemCreativeAssociations_element();
	 	LineItemCreativeAssociationService.createLineItemCreativeAssociationsResponse_element a11 = new LineItemCreativeAssociationService.createLineItemCreativeAssociationsResponse_element();
	 	//LineItemCreativeAssociationService.getLineItemCreativeAssociation_element a12 = new LineItemCreativeAssociationService.getLineItemCreativeAssociation_element();
	 	//LineItemCreativeAssociationService.updateLineItemCreativeAssociation_element a13 = new LineItemCreativeAssociationService.updateLineItemCreativeAssociation_element();
	 	LineItemCreativeAssociationService.getPreviewUrl_element a14 = new LineItemCreativeAssociationService.getPreviewUrl_element();
	 	LineItemCreativeAssociationService.Value a15 = new LineItemCreativeAssociationService.Value();
	 	LineItemCreativeAssociationService.UpdateResult a16 = new LineItemCreativeAssociationService.UpdateResult();
	 	LineItemCreativeAssociationService.Stats a17 = new LineItemCreativeAssociationService.Stats();
	 	LineItemCreativeAssociationService.TextValue a18 = new LineItemCreativeAssociationService.TextValue();
	 	LineItemCreativeAssociationService.SetValue a19 = new LineItemCreativeAssociationService.SetValue();
	 	LineItemCreativeAssociationService.RichMediaStudioCreativeError a20 = new LineItemCreativeAssociationService.RichMediaStudioCreativeError();
	 	LineItemCreativeAssociationService.RequiredSizeError a21 = new LineItemCreativeAssociationService.RequiredSizeError();
	 	LineItemCreativeAssociationService.RequiredNumberError a22 = new LineItemCreativeAssociationService.RequiredNumberError();
	 	LineItemCreativeAssociationService.RequiredError a23 = new LineItemCreativeAssociationService.RequiredError();
	 	LineItemCreativeAssociationService.RequiredCollectionError a24 = new LineItemCreativeAssociationService.RequiredCollectionError();
	 	LineItemCreativeAssociationService.LineItemCreativeAssociationStats a25 = new LineItemCreativeAssociationService.LineItemCreativeAssociationStats();
	 	LineItemCreativeAssociationService.CommonError a26 = new LineItemCreativeAssociationService.CommonError();
	 	LineItemCreativeAssociationService.LineItemCreativeAssociationAction 	a27 = new LineItemCreativeAssociationService.LineItemCreativeAssociationAction();
	 	LineItemCreativeAssociationService.InternalApiError a28= new LineItemCreativeAssociationService.InternalApiError();
	 	//LineItemCreativeAssociationService.getLineItemCreativeAssociationResponse_element a29= new LineItemCreativeAssociationService.getLineItemCreativeAssociationResponse_element();
	 	LineItemCreativeAssociationService.StringLengthError a30= new LineItemCreativeAssociationService.StringLengthError();
	 	LineItemCreativeAssociationService.TemplateInstantiatedCreativeError a31 = new LineItemCreativeAssociationService.TemplateInstantiatedCreativeError();
	 	LineItemCreativeAssociationService.UniqueError a32 = new LineItemCreativeAssociationService.UniqueError();
	 	LineItemCreativeAssociationService.FeatureError a33 = new LineItemCreativeAssociationService.FeatureError();
	 	LineItemCreativeAssociationService.AuthenticationError a34 = new LineItemCreativeAssociationService.AuthenticationError();
	 	LineItemCreativeAssociationService.PermissionError a35 = new LineItemCreativeAssociationService.PermissionError();
	 	LineItemCreativeAssociationService.getPreviewUrlResponse_element a36 = new LineItemCreativeAssociationService.getPreviewUrlResponse_element();
	 	LineItemCreativeAssociationService.PublisherQueryLanguageSyntaxError a37 = new LineItemCreativeAssociationService.PublisherQueryLanguageSyntaxError();
	 	LineItemCreativeAssociationService.AudienceExtensionError a38 = new LineItemCreativeAssociationService.AudienceExtensionError();
	 	LineItemCreativeAssociationService.String_ValueMapEntry a39 = new LineItemCreativeAssociationService.String_ValueMapEntry();
	 	LineItemCreativeAssociationService.Size a40 = new LineItemCreativeAssociationService.Size();
	 	LineItemCreativeAssociationService.FileError a41 = new LineItemCreativeAssociationService.FileError();
//	 	LineItemCreativeAssociationService.OAuth a42 = new LineItemCreativeAssociationService.OAuth();
	 	LineItemCreativeAssociationService.LineItemCreativeAssociationError a43  = new LineItemCreativeAssociationService.LineItemCreativeAssociationError();
	 	LineItemCreativeAssociationService.updateLineItemCreativeAssociations_element a44 = new LineItemCreativeAssociationService.updateLineItemCreativeAssociations_element();
	 	LineItemCreativeAssociationService.InvalidUrlError a45 = new LineItemCreativeAssociationService.InvalidUrlError();
	 	LineItemCreativeAssociationService.TypeError a46 = new LineItemCreativeAssociationService.TypeError();
	 	LineItemCreativeAssociationService.NumberValue a47a = new LineItemCreativeAssociationService.NumberValue();
	 	LineItemCreativeAssociationService.SoapResponseHeader a47 = new LineItemCreativeAssociationService.SoapResponseHeader();
	 	LineItemCreativeAssociationService.NotNullError a48 = new LineItemCreativeAssociationService.NotNullError();
	 	LineItemCreativeAssociationService.SwiffyConversionError a49 = new LineItemCreativeAssociationService.SwiffyConversionError();
	 	LineItemCreativeAssociationService.EntityLimitReachedError a50 = new LineItemCreativeAssociationService.EntityLimitReachedError();
	 	LineItemCreativeAssociationService.DateTimeValue a51= new LineItemCreativeAssociationService.DateTimeValue();
	 	LineItemCreativeAssociationService.PublisherQueryLanguageContextError a52 = new LineItemCreativeAssociationService.PublisherQueryLanguageContextError();
	 	LineItemCreativeAssociationService.Date_x a53 = new LineItemCreativeAssociationService.Date_x();
	 	LineItemCreativeAssociationService.CustomCreativeError a54 = new LineItemCreativeAssociationService.CustomCreativeError();
	 	LineItemCreativeAssociationService.performLineItemCreativeAssociationActionResponse_element a55 = new LineItemCreativeAssociationService.performLineItemCreativeAssociationActionResponse_element();
	 	LineItemCreativeAssociationService.NullError a56  = new LineItemCreativeAssociationService.NullError();
	 	LineItemCreativeAssociationService.performLineItemCreativeAssociationAction_element a57  = new LineItemCreativeAssociationService.performLineItemCreativeAssociationAction_element();
	 	LineItemCreativeAssociationService.CreativeError a58  = new LineItemCreativeAssociationService.CreativeError();
	 	LineItemCreativeAssociationService.CreativeAssetMacroError a59  = new LineItemCreativeAssociationService.CreativeAssetMacroError();
	 	LineItemCreativeAssociationService.LineItemError a60 = new LineItemCreativeAssociationService.LineItemError();
	 	LineItemCreativeAssociationService.StatementError a61  = new LineItemCreativeAssociationService.StatementError();
	 	LineItemCreativeAssociationService.DateTime_x a62  = new LineItemCreativeAssociationService.DateTime_x();
	 	LineItemCreativeAssociationService.Long_StatsMapEntry a63 = new LineItemCreativeAssociationService.Long_StatsMapEntry();
	 	//LineItemCreativeAssociationService.updateLineItemCreativeAssociationResponse_element a64 =  new LineItemCreativeAssociationService.updateLineItemCreativeAssociationResponse_element();
	 	LineItemCreativeAssociationService.QuotaError a65 =  new LineItemCreativeAssociationService.QuotaError();
	 	LineItemCreativeAssociationService.DeactivateLineItemCreativeAssociations a66 =  new LineItemCreativeAssociationService.DeactivateLineItemCreativeAssociations();
	 	LineItemCreativeAssociationService.CreativeSetError a67 =  new LineItemCreativeAssociationService.CreativeSetError();
	 	LineItemCreativeAssociationService.DateValue a68 =  new LineItemCreativeAssociationService.DateValue();
	 	LineItemCreativeAssociationService.ImageError a69=  new LineItemCreativeAssociationService.ImageError();
	 	LineItemCreativeAssociationService.RangeError a70 =  new LineItemCreativeAssociationService.RangeError();
	 	LineItemCreativeAssociationService.ParseError a71 = new LineItemCreativeAssociationService.ParseError();
	 	LineItemCreativeAssociationService.Money a72 =  new LineItemCreativeAssociationService.Money();
	 	LineItemCreativeAssociationService.ApiVersionError a73 =  new LineItemCreativeAssociationService.ApiVersionError();
	 	LineItemCreativeAssociationService.updateLineItemCreativeAssociationsResponse_element a74 =  new LineItemCreativeAssociationService.updateLineItemCreativeAssociationsResponse_element();
	 	LineItemCreativeAssociationService.LabelEntityAssociationError a75 =  new LineItemCreativeAssociationService.LabelEntityAssociationError();
	 	LineItemCreativeAssociationService.AssetError a76 =  new LineItemCreativeAssociationService.AssetError();
	 	LineItemCreativeAssociationService.ServerError a77 =  new LineItemCreativeAssociationService.ServerError();
	 	LineItemCreativeAssociationService.LineItemCreativeAssociationOperationError a78 =  new LineItemCreativeAssociationService.LineItemCreativeAssociationOperationError();
	 	
	 	//LineItemCreativeAssociationServiceInterfacePort.
	 	
	 	LineItemCreativeAssociationService.LineItemCreativeAssociationServiceInterfacePort service = new LineItemCreativeAssociationService.LineItemCreativeAssociationServiceInterfacePort();
	 	//service.getLineItemCreativeAssociation(123456L,56789L);
	 	service.performLineItemCreativeAssociationAction(null,null);
	 	service.getPreviewUrl(123456,56789,'awas');
	 	//service.updateLineItemCreativeAssociation(null);
	 	
	 	service.updateLineItemCreativeAssociations(null);
	 	
	 	service.createLineItemCreativeAssociations(new LineItemCreativeAssociationService.LineItemCreativeAssociation[]{new LineItemCreativeAssociationService.LineItemCreativeAssociation()});
	 	//service.createLineItemCreativeAssociation(new LineItemCreativeAssociationService.LineItemCreativeAssociation());
	 
	 	
	 	
	 	
	 	
	 	
	 	
	 	
	 	
	 	
	 	
	 	
	 	
	 	
	 	
	 	
	 }
	 
}