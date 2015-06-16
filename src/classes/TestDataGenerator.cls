/**
   This class create for creating test data.
        -> Call in Testclass 
   Created date: 19/12/2012

   Change log:
   
   - 2014-07-04 - GTCRM-1012 - Opportunity Account Record type to be submitted to Sales team custom field
   - 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
 */
@isTest
public class TestDataGenerator {
    
    
    public Pricebook2 pb2;
    public Map<String, String> mapDartRecordType;
    public List<Product2> lstPrd2;
    public List<PricebookEntry> lstPrdbEnDart;
    public Opportunity opp;
    public List<OpportunityLineItem> lstLineItems;
    public Targeting__c[] targetting;
    public Content__c[] contents;
    public AreaCode__c[] areaCodes;
    public City__c[] cities;
    public Country__c[] countries;
    public DART_KeyValue_2__c[] keyvalues;
    public AdServer_Login__c[] listLogin;
    public Site__c[] sites;
    public Advertiser__c[] lstAdvertiser;
    public Account[] lstAcc;
    public Devices__c[] lstDevices;
    public Connection__c[] lstConns;
    public Geography__c[] lstGeographies;
    
    public void createSite(Set<String> codes)
    {
        sites = new List<Site__c>();
        for(String s: codes)
        {
            Site__c site = new Site__c(Name='Test1'+s, Country__c=s);
            sites.add(site);
        }
        insert sites;
        
    }
    
    
    public void getPricebook2()
    {
        pb2 = [Select id from Pricebook2 where IsStandard= true];
        pb2.IsActive = true;
        
        update pb2;
    }
     
    public  Map<String, String> getMappingRecordType()
    {
          if(mapDartRecordType==null)
          {
            mapDartRecordType = new Map<String, String>();
            List<RecordType> recs = [Select id, name From RecordType Where Name =:DARTUtil.DART5 OR Name=: DARTUtil.DART6];
            for(RecordType rec : recs)
            {
                mapDartRecordType.put(rec.Name, rec.Id);    
            }
          }
            
         return mapDartRecordType;
        //Set<String> setRecName = new Set<String>{DARTUtil.DART5, DARTUtil.DART6};
        
    }
    
    public Map<String, String> getMappingRecordType(String objName)
    {
          
            Map<String, String> mapDartRecordType = new Map<String, String>();
            List<RecordType> recs = [Select id, name From RecordType Where SobjectType =:objName];
            for(RecordType rec : recs)
            {
                mapDartRecordType.put(rec.Name, rec.Id);    
            }
         
        //Set<String> setRecName = new Set<String>{DARTUtil.DART5, DARTUtil.DART6};
        return mapDartRecordType;
    }
    
    public void createNewProduct2TypeDART(Integer numToCreate,String dartVersion)
    {
        
        lstPrd2 = new List<Product2>();
        
        Map<String, String> mapRecIds = getMappingRecordType('Product2');
        createSite(new Set<String>{'DE'});
        for(Integer i=0; i<numToCreate; i++)
        {
            Product2 prd2 = new Product2(
                            Name='Test product'+i, 
                            RecordTypeId=mapRecIds.get(dartVersion) , 
                            IsActive = true, No_Availability_Forecast__c=false ,
                            Site__c=sites.get(0).id);
                        
            lstPrd2.add(prd2);
        }
        insert lstPrd2;
         
    }
    public void createNewPricebookEntryDART(Integer numToCreate,String dartVersion)
    {
        lstPrdbEnDart = new List<PricebookEntry>();
        getPricebook2();
        createNewProduct2TypeDART(numToCreate,dartVersion);

        for(integer i=0; i<numToCreate; i++)
        {
            PricebookEntry pbEntry2 = new PricebookEntry(
                        unitPrice=100,
                        Pricebook2Id = pb2.Id,
                        Product2Id = lstPrd2.get(i).Id,
                        UseStandardPrice = false,
                        IsActive = true
                        );
                        
            lstPrdbEnDart.add(pbEntry2);
            
        }
        
        insert lstPrdbEnDart;
        
    }
    /** Create new Opportunity */
    public void createOpp(Account acc)
    {
    
                
        opp = new Opportunity(
                                         Name='Test Opp',
                                         StageName='Out of Date',
                                         CloseDate=date.newInstance(System.today().year()+1, 01, 01),
                                         Type='Existing Business',
                                         P_O_Number__c = '123',
                                         AccountId=acc.Id,
                                         // 2015-05-21 - GTCRM-2028 - SOX controls: Signed contract attached on opportunity level
                                         Signed_contract_attached__c = true
                                         );
        
        insert opp;

    }
    
    public void createOppTeamMember(String oppId)
    {
        
        Profile p = [select id from profile where name='Standard User'];
        
        List<User> lstUser = [select id From User where userName='standarduser_TestDart123@test.com'];
        if(lstUser.isEmpty())
        {
            User u = new User(alias = 'standt', email='standarduser@test.com', 
            emailencodingkey='UTF-8', lastname='TestingUser', languagelocalekey='en_US', 
            localesidkey='en_US', profileid = p.Id, 
            timezonesidkey='America/Los_Angeles', username='standarduser_TestDart123@test.com');
        
            insert u;
            lstUser.add(u);
        }
         
        
        
        OpportunityTeamMember oppTeam = new OpportunityTeamMember(UserId = lstUser.get(0).id, TeamMemberRole='Primary Trafficker', opportunityId = oppId);
        insert oppTeam;
        
    }
       
    public void createAccount()
    {
             
      lstAcc = new List<Account>();
      for(Integer i=0; i<3; i++)
      {
      
        RecordType rt = [select id from RecordType where SobjectType = 'Account' LIMIT 1];
        
        Account acc = new Account(
                        Name='Test Acc'+i,
                        BillingStreet = 'DFP Fake Street',
                        BillingCity = 'DFP Fake City',
                        BillingState = 'DFP Fake State',
                        BillingPostalCode = '123',
                        BillingCountry = 'GB',
                        Country_Code__c='GB',
                        Bank_Country__c = 'GB',
                        RecordTypeId = rt.id  
                      );
            lstAcc.add(acc);
      }

        insert lstAcc;
           
    }
    
    
    
    public void createAdvertiser()
    {
      lstAdvertiser = new List<Advertiser__c>();
      Advertiser__c advertiser1 = new Advertiser__c(Account__c=lstAcc.get(0).id, Agency__c=lstAcc.get(0).id);
      lstAdvertiser.add(advertiser1);
      Advertiser__c advertiser2 = new Advertiser__c(Account__c=lstAcc.get(1).id, Agency__c=lstAcc.get(1).id, DART5_Advertiser_Id__c='111111', DART6_Advertiser_Id__c='222222');
      lstAdvertiser.add(advertiser2);
      
      insert lstAdvertiser;
      
      
      
    }
    
    public void createNewOppItemsDart(String oppId,Integer numToCreate,String dartVersion,String targetingId)
    {
        
        lstLineItems = new List<OpportunityLineItem>();
        createNewPricebookEntryDART(numToCreate,dartVersion);

        System.debug('-------------->xxxxxxxxxxxxxx:'+numToCreate+' :dartVersion:'+dartVersion);
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
                              Targeting__c=targetingId
                              );
                              
            
            lstLineItems.add(oppItem);
        }
        System.debug('-------------->xxxxxxxxxxxxxx:lstLineItems'+lstLineItems);
        
        insert lstLineItems;
    } 
    public void createCredential()
    {
        Map<String,String> mapRecType = getMappingRecordType('AdServer_Login__c');
        AdServer_Login__c login5 = new AdServer_Login__c(RecordTypeId=mapRecType.get(DARTUtil.DART5),
            Name = 'DE',
            Login_URL__c='http://test.com',
            User_Name__c='dart5testuser',
            Password__c ='testpwd123456',
            Active__c = true,
            Client_ID__c = 'xxxxxxxxxxxxxxxxxxxxx',
            Client_Secret__c = 'xxxxxxxxxxxxxxx',
            Refresh_Token__c = 'xxxxxxxxxxx'
            );
        AdServer_Login__c login6 = new AdServer_Login__c(RecordTypeId=mapRecType.get(DARTUtil.DART6),
            Name = 'DE',
            Login_URL__c='http://test.com',
            User_Name__c='dart6testuser@gmail.com',
            Password__c ='testpwddart6123456',
            Active__c = true,
            Network_ID__c='123456',
            Client_ID__c = 'xxxxxxxxxxxxxxxxxxxxx',
            Client_Secret__c = 'xxxxxxxxxxxxxxx',
            Refresh_Token__c = 'xxxxxxxxxxx'
            );
            
            listLogin = new List<AdServer_Login__c>{login5,login6};
            insert listLogin;
            
            //AdServer_Login__c login: [SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c FROM AdServer_Login__c WHERE Active__c
    }
     
    public void createCountries(Integer numToCreate)
    {
        countries = new List<Country__c>();
        for(Integer i=0;i<numToCreate;i++)
        {
            Country__c c = new Country__c(Name='Canada'+i,Country_Code__c='X'+i,Dart_ID__c=1000+i);
            countries.add(c); 
        }
        insert countries;
    }
    
    public  void createCities(Integer numToCreate,String countryId)
    {
        cities = new List<City__c>();
        for(Integer i=0;i<numToCreate;i++)
        {
            City__c c = new City__c(Name='Alberto'+i,State_Region__c='BC',Country__c=countryId,Dart_ID__c=2000+i);
            cities.add(c); 
        }
        insert cities;
        
    }
    
    
    public void createAreaCodes(Integer numToCreate)
    {
        areaCodes = new List<AreaCode__c>();
        for(Integer i=0;i<numToCreate;i++)
        {
            AreaCode__c a = new AreaCode__c(Name='Area '+i, Dart_ID__c='3000'+i);
            areaCodes.add(a);
        }
        
        insert areaCodes;
        
    }
    /**Type:
    Dart - Site
    Dart - Zone
    Dart - ContentCategory
     */
    public void createContents(Integer numToCreate,List<String> ctype)
    {
        contents = new List<Content__c>();
        for(Integer i=0;i<numToCreate;i++)
        {
            Content__c c = new Content__c(Name='4000'+i,DartName__c='DartName'+i,Type__c=ctype[i]);
            contents.add(c);
        }
        insert contents;
    }
    public void createKV(Integer numToCreate)
    {
        keyvalues = new List<DART_KeyValue_2__c>();
        for(Integer i=0;i<numToCreate;i++)
        {
            DART_KeyValue_2__c kv = new DART_KeyValue_2__c(Name='DE RTM Targeting'+i,Key__c='seg'+i,Key_Value__c='seg'+i,Key_Value_Name__c='DE RTM Targeting',Active__c=true);
            keyvalues.add(kv);
        }
        insert keyvalues;
    }
    public void createTargetings(Integer numToCreate)
    {
        targetting = new List<Targeting__c>();
        for(Integer i=0;i<numToCreate;i++)
        {
            Targeting__c t = new Targeting__c(Description__c='test',Key_Values__c='key=value');
            targetting.add(t);
        }
        insert targetting;
         
    }

     
    public void createTargetingHierarchy()
    {
        List<Sobject> listObj = new List<SObject>();
        createTargetings(1);
        
        //country + assoc
        createCountries(1);
        TargetingCountryAssociation__c countryAssoc = new TargetingCountryAssociation__c(Targeting__c=targetting[0].Id,TargetCountry__c=countries[0].Id);
        
        //city +  assoc
        createCities(1,countries[0].Id);
        TargetingCityAssociation__c cityAsso =new TargetingCityAssociation__c(targetcity__c='TestCity',Targeting__c=targetting[0].Id,City__c=cities[0].Id);
        listObj.add(cityAsso);
        
        //area +  assoc
        createAreaCodes(1);
        TargetingAreaCodeAssociation__c tgArea = new TargetingAreaCodeAssociation__c(AreaCode__c=areaCodes[0].Id,Targeting__c=targetting[0].Id);
        listObj.add(tgArea);
        
        //kv +  assoc
        createKV(1);
        
        TargetingKeyValueAssociation__c kvAssoc = new TargetingKeyValueAssociation__c(Name='kvAssocTest',DART_KeyValue__c=keyvalues[0].Id,Targeting__c=targetting[0].Id);
        listObj.add(kvAssoc);
        
        //content +  assoc
        createContents(3,new List<String>{'Dart - Site','Dart - Site','Dart - Zone'});
        TargetingContentAssociation__c contAssoc = new TargetingContentAssociation__c(Target_Content_Key__c='key',Targeting__c=targetting[0].Id,TargetingContent__c=contents[0].Id);
        listObj.add(contAssoc);
        
        //device + asso
        createDevices();
        TargetingDeviceAssociation__c devAssoc = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev', Targeting__c=targetting[0].Id, Device__c = lstDevices[0].id);
        listObj.add(devAssoc);
        TargetingDeviceAssociation__c devAssoc2 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[1].id);
        listObj.add(devAssoc2);
        TargetingDeviceAssociation__c devAssoc3 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[2].id);
        listObj.add(devAssoc3);
        
        //Connection + asso
        createConnections();
        TargetingConnectionAssociation__c connAssoc = new TargetingConnectionAssociation__c(TargetConnection__c='TestConn', Targeting__c=targetting[0].Id, Connection__c = lstConns[0].id);
        listObj.add(connAssoc);
        TargetingConnectionAssociation__c connAssoc2 = new TargetingConnectionAssociation__c(TargetConnection__c='TestConn2', Targeting__c=targetting[0].Id, Connection__c = lstConns[1].id);
        listObj.add(connAssoc2);
        TargetingConnectionAssociation__c connAssoc3 = new TargetingConnectionAssociation__c(TargetConnection__c='TestConn3', Targeting__c=targetting[0].Id, Connection__c = lstConns[2].id);
        listObj.add(connAssoc3);
        
        //geography + assoc
        createGeographies();
        TargetingGeographyAssociation__c geoAssoc = new TargetingGeographyAssociation__c(TargetGeography__c='TestGeo', Targeting__c=targetting[0].Id, Geography__c = lstGeographies[0].id);
        listObj.add(geoAssoc);
        TargetingGeographyAssociation__c geoAssoc2 = new TargetingGeographyAssociation__c(TargetGeography__c='TestGeo2', Targeting__c=targetting[0].Id, Geography__c = lstGeographies[1].id);
        listObj.add(geoAssoc2);
        TargetingGeographyAssociation__c geoAssoc3 = new TargetingGeographyAssociation__c(TargetGeography__c='TestGeo3', Targeting__c=targetting[0].Id, Geography__c = lstGeographies[2].id);
        listObj.add(geoAssoc3);
        
        insert listObj;
        
    }
    
    public void createTargetingKVHierarchy()
    {
        //createTargetings(1);
        //createSite(new Set<String>{'DE'});
        
        keyvalues = new List<DART_KeyValue_2__c>(); 
        
        // Key Free-form 
        DART_KeyValue_2__c k1 = new DART_KeyValue_2__c(Dart6_KeyId__c=11111,Name='car test',Key__c='car',Key_Value__c='car',Key_Value_Name__c='car',Active__c=true, Site__c=sites.get(0).id, Key_ValueType_FreeForm__c=true);
        insert k1;
        

        DART_KeyValue_2__c val1 = new DART_KeyValue_2__c(Node_ID__c=k1.Id,Dart6_ValueId__c=22222,Name='bmw',Key_Value__c='bmw',Key_Value_Name__c='bmw',Active__c=true);
        DART_KeyValue_2__c val2 = new DART_KeyValue_2__c(Node_ID__c=k1.Id,Dart6_ValueId__c=null,Name='hummer',Key_Value__c='hummer',Key_Value_Name__c='hummer',Active__c=true);
        insert new DART_KeyValue_2__c[]{val1,val2};
        
        // Key not Free-form
        DART_KeyValue_2__c k2 = new DART_KeyValue_2__c(Dart6_KeyId__c=123123,Name='color test',Key__c='color',Key_Value__c='color',Key_Value_Name__c='color',Active__c=true, Site__c=sites.get(0).id);
        insert k2;
        
        DART_KeyValue_2__c val21 = new DART_KeyValue_2__c(Node_ID__c=k2.Id,Dart6_ValueId__c=66666,Name='red',Key_Value__c='red',Key_Value_Name__c='red',Active__c=true);
        DART_KeyValue_2__c val22 = new DART_KeyValue_2__c(Node_ID__c=k2.Id,Dart6_ValueId__c=555555,Name='white',Key_Value__c='white',Key_Value_Name__c='white',Active__c=true);
        insert new DART_KeyValue_2__c[]{val21,val22};
        
        
        keyvalues.add(k1);
        keyvalues.add(val1); 
        keyvalues.add(val2); 
        keyvalues.add(k2);
        keyvalues.add(val21); 
        keyvalues.add(val22);
        
        // Create Keyvalue Audience Segment
        
        List<DART_KeyValue_2__c> lstKeyAs = [Select id, name, Key_Value__c, Key_Value_Name__c From DART_KeyValue_2__c Where Key_Value__c='Audience Segment'];
        if(lstKeyAs.size()>0)
        {
            
            DART_KeyValue_2__c asVal11 = new DART_KeyValue_2__c(Node_ID__c=lstKeyAs.get(0).Id,Dart6_ValueId__c=999999,Name='Aud1',Key_Value__c='Aud1',Key_Value_Name__c='Aud1',Active__c=true);
            DART_KeyValue_2__c asVal12 = new DART_KeyValue_2__c(Node_ID__c=lstKeyAs.get(0).Id,Dart6_ValueId__c=888888,Name='Aud2',Key_Value__c='Aud2',Key_Value_Name__c='Aud2',Active__c=true);
            insert new DART_KeyValue_2__c[]{asVal11,asVal12};
            
            keyvalues.addAll(lstKeyAs);
            keyvalues.add(asVal11);
            keyvalues.add(asVal12);
            
        }
        else
        {
            DART_KeyValue_2__c kvAs = new DART_KeyValue_2__c(Dart6_KeyId__c=123123,Name='Audience Segment',Key__c='Audience Segment',Key_Value__c='Audience Segment',Key_Value_Name__c='Audience Segment',Active__c=true);
            insert kvAs;
            
            DART_KeyValue_2__c asVal1 = new DART_KeyValue_2__c(Node_ID__c=kvAs.Id,Dart6_ValueId__c=999999,Name='Aud1',Key_Value__c='Aud1',Key_Value_Name__c='Aud1',Active__c=true);
            DART_KeyValue_2__c asVal2 = new DART_KeyValue_2__c(Node_ID__c=kvAs.Id,Dart6_ValueId__c=888888,Name='Aud2',Key_Value__c='Aud2',Key_Value_Name__c='Aud2',Active__c=true);
            insert new DART_KeyValue_2__c[]{asVal1,asVal2};
            
            keyvalues.add(kvAs);
            keyvalues.add(asVal1);
            keyvalues.add(asVal2);
            
        }
        
        
          //TargetingKeyValueAssociation__c kvAssoc1 = new TargetingKeyValueAssociation__c(Name='kvAssocTest1',DART_KeyValue__c=val1.Id,Targeting__c=targetting[0].Id);
          //TargetingKeyValueAssociation__c kvAssoc2 = new TargetingKeyValueAssociation__c(Name='kvAssocTest2',DART_KeyValue__c=val2.Id,Targeting__c=targetting[0].Id);
          //insert new TargetingKeyValueAssociation__c[]{kvAssoc1,kvAssoc2};
         
    }    
        
    
    public List<OpportunityLineItem> getOppItem(String oppId, Set<String> lineItemIds)
   {
    Set<String> dartRecType = new Set<String>{DARTUtil.DART5,DARTUtil.DART6};
    /*List<OpportunityLineItem> lstItem = [Select Id, Quantity, Package__c, Pricebook_Name__c, 
                  Description, UnitPrice, PriceBookEntry.Product2.Name, 
                  PricebookEntry.Product2.RecordType.Name, OpportunityId,Opportunity.Name,
                  Opportunity.Owner.Name, Availability__c, Period__c, 
                  Targeting__c,PriceBookEntry.Product2.Advertising_Medium__r.DART_AdSlotSize__c,
                  from_Date__c,until_Date__c,FC_Quantity__c,FC_Ad_served_every__c,
                  FC_Period__c,AdDayOfWeek__c,AdHourOfDay__c,AdOperatingSystems__c,
                  AdWebBrowsers__c,PriceBookEntry.Product2Id,AdKeyWords__c,Ad_Id__c, 
                  Billing_category__c,PriceBookEntry.Product2.Site__r.Country__c ,
                  CPM_net_net_net__c, Net_Net_Net__c, Ad_Name__c, PriceBookEntry.Product2.Fixed_Site__c
                   From OpportunityLineItem
                   WHERE Id =:oppItemId AND PricebookEntry.Product2.RecordType.Name IN : dartRecType ];
             */
        BatchAvailabilityForecastProcess batchFc = new BatchAvailabilityForecastProcess(oppId, lineItemIds); 
        //System.debug('----------------> : ' + batchFc.soqlItems);     
        //List<OpportunityLineItem> lstItem = Database.query(batchFc.soqlItems +' Where ID=:oppItemId AND PricebookEntry.Product2.RecordType.Name IN:dartRecType' );
        List<OpportunityLineItem> lstItem = Database.query(batchFc.soqlItems);
             
    return lstItem;
  }
  
  public Opportunity getOppty(String oppId)
  {
    Opportunity opp = [Select id, Name, P_O_Number__c, Campaign_Name__c, Campaign_Start__c, Campaign_End__c, Owner.Name, Owner.id, Owner.Email
    // , Agency__c, AccountId, Owner.Division From Opportunity Where id =: oppId];
    // GTCRM-1012 - Opportunity Account Record type to be submitted to Sales team custom field
        , Agency__c, AccountId, Owner.Division, Account.RecordType.Name From Opportunity Where id =: oppId];
        
       return opp;      
    
    
  }
  
  public Contact createContact() {
    return new Contact(lastName = 'test');
  }
  
  
  public void createDevices()
  {
        lstDevices = new List<Devices__c>();
        Devices__c dev1 = new Devices__c(Name = 'Test1', Dart_ID__c=123456, DFP_API_Name__c='DeviceManufacturer');
        insert dev1;
        Devices__c dev2 = new Devices__c(Name = 'Test2', Dart_ID__c=555555, Node_ID__c= dev1.Id);
        insert dev2;
        Devices__c dev3 = new Devices__c(Name = 'Test3', Dart_ID__c=333333, Node_ID__c= dev2.Id);
        insert dev3;
        
        lstDevices.add(dev1);
        lstDevices.add(dev2);
        lstDevices.add(dev3);
  }
  
  public void createConnections()
  {
        lstConns = new List<Connection__c>();
        Connection__c conn1 = new Connection__c(Name = 'Test1', Dart_ID__c=123456, DFP_API_Name__c='Bandwidth');
        insert conn1;
        Connection__c conn2 = new Connection__c(Name = 'Test1', Dart_ID__c=666666, Node_ID__c = conn1.Id);
        insert conn2;
        Connection__c conn3 = new Connection__c(Name = 'Test3', Dart_ID__c=111111, Node_ID__c = conn2.Id);
        insert conn3;
        
        lstConns.add(conn1);
        lstConns.add(conn2);
        lstConns.add(conn3);
  }
  
  public void createGeographies()
  {
        lstGeographies = new List<Geography__c>();
        Geography__c geo1 = new Geography__c(Name = 'Test1', Dart_ID__c=123456, Type__c = 'COUNTRY');
        insert geo1;
        Geography__c geo2 = new Geography__c(Name = 'Test2', Dart_ID__c=888888, Type__c = 'CITY', Node_ID__c=geo1.Id);
        insert geo2;
        Geography__c geo3 = new Geography__c(Name = 'Test3', Dart_ID__c=999999, Type__c = 'CITY', Node_ID__c=geo2.Id);
        insert geo3;
        lstGeographies.add(geo1);
        lstGeographies.add(geo2);
        lstGeographies.add(geo3);
        
  }
 
    
}