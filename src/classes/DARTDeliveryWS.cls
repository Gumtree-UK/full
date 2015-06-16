global with sharing class DARTDeliveryWS {


	/** Import Opportunity Product (yesterday/today)*/
	webservice static String processImportDelivery()
	{
		String result = doImport(DeliveryController.SCH_TYPE_MANUALLY, DeliveryController.SOBJECT_OPPPRODUCT);
		return result;
	}
	
	/** Import Revenue Schedule Daily (yesterday/today) */
	webservice static String processImportDeliveryRS_Daily()
	{
		String result = doImport(DeliveryController.SCH_TYPE_MANUALLY, DeliveryController.SOBJECT_REV_SCH2_DAILY);
		return result;
	}
	
	/** Import Revenue Schedule Monthly (Month to Date) */
	webservice static String processImportDeliveryRS_Monthly()
	{
		String result = doImport(DeliveryController.SCH_TYPE_MANUALLY, DeliveryController.SOBJECT_REV_SCH2);
		return result;
	}
	
	private static String doImport(String schType,String sobjType)
	{
		String result='';
		try
		{ 
			
			Integer numPending = [Select count() from DART_Delivery_Support__c 
				WHERE Schedule_Type__c=:schType 
				AND Sobject__c=:sobjType
				AND Status__c <> :DeliveryController.DART_STATUS_FINISHED];
			
			//We expected all DDS are 'finished'; so we can run another, or wait until they all finish
			if(numPending>0)
			{	  
				return 'Importing Delivery of '+sobjType+' is already running.';
			}
			DeliveryController.start(schType, sobjType);
			
			result = 'SUCCESS: Importing Delivery of '+sobjType+' is now running in background.';
			
		}catch(Exception ex){result+='ERROR: '+ex;}
		
		return result;
	}
	
	
	static testMethod void testWS()
	{
		TestDataGenerator dataGen = new TestDataGenerator();
		dataGen.createCredential();
		
		dataGen.createAccount();
		dataGen.createOpp(dataGen.lstAcc[0]);
 
		//dataGen.createNewOppItemsDart(dataGen.opp.id,1,DARTUtil.DART6,null);
		//dataGen.createNewOppItemsDart(dataGen.opp.id,1,DARTUtil.DART5,null);
		
		Test.startTest();
		String result = processImportDelivery();
		System.assertEquals(result,'SUCCESS: Importing Delivery of Opportunity Product is now running in background.');
		
		processImportDeliveryRS_Daily();
		
		processImportDeliveryRS_Monthly();
		
		Test.stopTest();
	}
	
}