/**
 * To test logic in the class RevenueSchedule2Handler
 * @author : SUY Sreymol
 * @createddate : 20/05/2014
 */
@isTest
class RevenueSchedule2HandlerTest {
	private static Profile p;
	private static User admin; 
	private static Map<String, RecordType> mrecordTypes = new Map<String, RecordType>();
	private static Set<String> sobjTypes = new Set<String>{'Opportunity', 'Product2'};
	private static Set<String> names = new Set<String>{'DART6', 'Classifieds', 'Campaign_Delivery'};
	private static List<OpportunityLineItem> olis;
	private static List<Product2> prods;
	
	private static void init() {
		p = [Select Id from Profile Where Name = 'System Administrator' limit 1];
		admin = new User(alias = 'u2', email = 'rs2handler@test.com', emailencodingkey = 'UTF-8', 
                            FirstName = 'rs2handler' , lastname = 'RS2', languagelocalekey = 'en_US',
                            localesidkey = 'en_US', profileId = p.Id, timezonesidkey = 'America/Los_Angeles', CommunityNickname = 'RS2',
                            isActive = true, username = 'rs2handler@test.com'); 
        insert admin;
        
        for (RecordType r : [Select Id, DeveloperName From RecordType Where DeveloperName IN : names And SobjectType IN : sobjTypes]){
        	if (r.DeveloperName == 'DART6') mrecordTypes.put('DART6', r);
        	else if (r.DeveloperName == 'Classifieds') mrecordTypes.put('Classifieds', r);
        	else if (r.DeveloperName == 'Campaign_Delivery') mrecordTypes.put('Campaign_Delivery', r);
        }
        system.debug('mrecordTypes :::>>>>>>>>>>>' + mrecordTypes);	
        Account acc = new Account(Name = 'Test Account Cancellation',  BillingStreet = '#222', BillingState = 'Test State', //Account_Migrated__c = true,
        							BillingPostalCode = 'BE', BillingCountry = 'BE', BillingCity = 'Test City', Account_Status__c = 'Active');
        insert acc;
         
        Pricebook2 pb = [select Id from Pricebook2 where IsStandard = false and IsActive = true limit 1];
        Pricebook2 pbstd = [select Id from Pricebook2 where IsStandard = true];
        
        //Classified product
        Product2 prod2Cf = new Product2(Name = 'Test', Billing_Category__c = 'CPM', RecordTypeId = mrecordTypes.get('Classifieds').Id);
        //DART6 product
        Product2 prod2Dart6 = new Product2(Name = 'Test', Billing_Category__c = 'Fixed Price', RecordTypeId = mrecordTypes.get('DART6').Id);
        prods = new List<Product2> {prod2Cf, prod2Dart6};
        insert prods;
         
        PricebookEntry stdPbecls = new PricebookEntry(Pricebook2Id = pbstd.Id, Product2Id = prod2Cf.Id, UnitPrice = 300, IsActive = true);
		PricebookEntry pbeclf = new PricebookEntry(UseStandardPrice = false, Product2Id = prod2Cf.Id, Pricebook2Id = pb.Id, UnitPrice = 300, IsActive = true);
		PricebookEntry stdPbedart6 = new PricebookEntry(Pricebook2Id = pbstd.Id, Product2Id = prod2Dart6.Id, UnitPrice = 250, IsActive = true);
		PricebookEntry pbedart6 = new PricebookEntry(UseStandardPrice = false, Product2Id = prod2Dart6.Id, Pricebook2Id = pb.Id, UnitPrice = 250, IsActive = true);
        List <PricebookEntry> pbes = new List <PricebookEntry> {stdPbecls, pbeclf, stdPbedart6, pbedart6};
        insert pbes;
        
        Opportunity opp = new Opportunity(Name = 'Test Cancellation Opp', AccountId = acc.Id, Pricebook2Id = pb.Id, StageName = 'Booking Cancelled', 
        									CloseDate = system.today(),  RecordTypeId = mrecordTypes.get('Campaign_Delivery').Id);
        insert opp;
        
        OpportunityLineItem oppLineItem1 = new OpportunityLineItem(OpportunityId = opp.Id, UnitPrice = 200, PricebookEntryId = pbeclf.Id, CPM_Sales_Price__c = 20.50, Quantity = 20, 
        															from_Date__c = system.today() - 30, until_Date__c = system.today() + 60, Billing_Category__c = 'CPM');
        OpportunityLineItem oppLineItem2 = new OpportunityLineItem(OpportunityId = opp.Id, UnitPrice = 200, PricebookEntryId = pbedart6.Id, CPM_Sales_Price__c = 20.50, Quantity = 20, 
        															from_Date__c = system.today() - 30, until_Date__c = system.today() + 60, Billing_Category__c = 'CPM');															
		olis = new List<OpportunityLineItem>{oppLineItem1, oppLineItem2};
	}
	
	@isTest(SeeAllData=true)
	static void test() {
		init();
		system.runAs(admin) {
			Test.startTest();
				insert olis;
				List<Revenue_Schedule2__c> rs2s = [Select Id, Net_Net_Net_delivered__c, Product__c From Revenue_Schedule2__c Where Product__c = : prods[0].Id];
				system.assertEquals(true, (rs2s !=null));
			Test.stopTest();
		}
	}
}