@isTest
public with sharing class TestTargetingTrees {
    
    public static TestDataGenerator testDATA = new TestDataGenerator();
    
    /** -------- Test Tree Device ----------------- */
    static testMethod void testDeviceTargeting()
    {
		
        test.startTest();
            testDATA.createCredential();
            testDATA.createTargetingHierarchy();
            testDATA.createAccount();
            testDATA.createAdvertiser();
            testDATA.createOpp(testDATA.lstAcc.get(0));
            testDATA.createOppTeamMember(testDATA.opp.id);
            testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
            List<OpportunityLineItem> items = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});
        
       // String str = '/apex/TreeDeviceSelection?targetId='+testDATA.targetting[0].Id+'&itemId='+ items[0].Id ;
              //  PageReference pageRef = new PageReference(str);
               PageReference pg = Page.TreeConnectionSelection;
                Test.setCurrentPage(pg);
                 pg.getParameters().put('targetId',testDATA.targetting[0].Id );
	    		 pg.getParameters().put('proId',testDATA.lstPrd2[0].Id );
	    		 pg.getParameters().put('itemId',items[0].Id );
	    		 pg.getParameters().put('froIfr','true' );
               
        TreeDeviceSelectionController treeDev = new TreeDeviceSelectionController();
        
          Product2 pro = testDATA.lstPrd2[0];
	      pro.Devices__c = true;
	      pro.Fixed_device__c = true;
	      update pro;
	     treeDev = new TreeDeviceSelectionController();
        Boolean ishowcancel = treeDev.isShowCancel;
        List<Devices__c> lstDev = TreeDeviceSelectionController.searchDevice('Test');
        treeDev.selectedDevice = testDATA.lstDevices[1].Id+'';
        treeDev.getDevices();
        treeDev.saveRecords();
        treeDev.addDevice();
        
        test.stopTest();
        
    }
    // Test add parent node
    static testMethod void testDeviceTargeting2()
    {

        test.startTest();
            testDATA.createTargetingHierarchy();
 
        String str = '/apex/TreeDeviceSelection?targetId=&itemId=';
                PageReference pageRef = new PageReference(str);
                Test.setCurrentPage(pageRef);
        TreeDeviceSelectionController treeDev = new TreeDeviceSelectionController();
        TreeDeviceSelectionController.searchDevice('Test');
        treeDev.selectedDevice = testDATA.lstDevices[0].Id+'';
        treeDev.addDevice();
        
        test.stopTest();
        
    }
    
    /** -------- Test Tree Connection ----------------- */
    static testMethod void testConnectionTargeting()
    {

        test.startTest();
            testDATA.createCredential();
            testDATA.createTargetingHierarchy();
            testDATA.createAccount();
            testDATA.createAdvertiser();
            testDATA.createOpp(testDATA.lstAcc.get(0));
            testDATA.createOppTeamMember(testDATA.opp.id);
            testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
            List<OpportunityLineItem> items = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});
        
        
       // String str = '/apex/TreeConnectionSelection?targetId='+testDATA.targetting[0].Id+'&itemId='+ items[0].Id ;
                //PageReference pageRef = new PageReference(str);
                PageReference pg = Page.TreeConnectionSelection;
                Test.setCurrentPage(pg);
                 pg.getParameters().put('targetId',testDATA.targetting[0].Id );
	    		 pg.getParameters().put('proId',testDATA.lstPrd2[0].Id );
	    		 pg.getParameters().put('itemId',items[0].Id );
	    		 pg.getParameters().put('froIfr','true' );
        TreeConnectionSelectionController treeConn = new TreeConnectionSelectionController();
        treeConn.isShowCancel = true;
        List<Connection__c> lstDev = TreeConnectionSelectionController.searchConnection('Test');
        treeConn.selectedConnection = testDATA.lstConns[1].Id+'';
        treeConn.getConnections();
        treeConn.saveRecords();
        treeConn.addConnection();
        
        test.stopTest();
        
    }
    
    // Test add connection parent node
    static testMethod void testConnectionTargeting2()
    {

        test.startTest();
            testDATA.createTargetingHierarchy();
        
        String str = '/apex/TreeConnectionSelection?targetId=&itemId=';
                PageReference pageRef = new PageReference(str);
                Test.setCurrentPage(pageRef);
        TreeConnectionSelectionController treeConn = new TreeConnectionSelectionController();
        treeConn.selectedConnection = testDATA.lstConns[0].Id+'';
        treeConn.addConnection();
        test.stopTest();
        
    }
    
    /** -------- Test Tree Geography ----------------- */
    static testMethod void testGeographyTargeting()
    {

        test.startTest();
            testDATA.createCredential();
            testDATA.createTargetingHierarchy();
            testDATA.createAccount();
            testDATA.createAdvertiser();
            testDATA.createOpp(testDATA.lstAcc.get(0));
            testDATA.createOppTeamMember(testDATA.opp.id);
            testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
            List<OpportunityLineItem> items = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});
        
        String str = '/apex/TreeGeographySelecting?targetId='+testDATA.targetting[0].Id+'&itemId='+ items[0].Id ;
                PageReference pageRef = new PageReference(str);
                Test.setCurrentPage(pageRef);
        TreeGeographySelectingController treeGeo = new TreeGeographySelectingController();
        treeGeo.isShowCancel = true;
        TreeGeographySelectingController.searchCountry('Test');
        treeGeo.selectedGeography = testDATA.lstGeographies[1].Id+'';
        treeGeo.getGeographies();
        treeGeo.saveRecords();
        treeGeo.addCountry();
        
        
        
        test.stopTest();
        
    }
    
    // Test add parent geography
    static testMethod void testGeographyTargeting2()
    {

        test.startTest();
            testDATA.createTargetingHierarchy();
        String str = '/apex/TreeGeographySelecting?targetId=&itemId=';
                PageReference pageRef = new PageReference(str);
                Test.setCurrentPage(pageRef);
        TreeGeographySelectingController treeGeo = new TreeGeographySelectingController();
        treeGeo.searchFilter = 'COUNTRY';
        treeGeo.selectedGeography = testDATA.lstGeographies[0].Id+'';
        treeGeo.addCountry();
        
        test.stopTest();
        
    }
    
    
     // Test content
     //HCS 12.08.2014
    static testMethod void testContentTargeting(){
    	Profile p=[Select Id From Profile Where Name='System Administrator' or Name='Systemadministrator' Limit 1];
        User u=new User(Username='testUser1@boco.com',LastName='testLastName1',Email='testEmail1@boco.com',Alias='test1',CommunityNickname='testCommun1',
                        TimeZoneSidKey='Pacific/kiritimati',LocaleSidKey='ar',EmailEncodingKey='UTF-8',ProfileId=p.Id,LanguageLocaleKey='en_US');
        
        insert u;
             
       System.runAs(u){
       		 PageReference pg = Page.TargetingTreeSelection;
       		 Test.setCurrentPage(pg);       		
	    	Test.startTest();
	    		 testDATA.createTargetingHierarchy();
	    		 testDATA.createAccount();	          
	            testDATA.createOpp(testDATA.lstAcc.get(0));
	            testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
	            List<OpportunityLineItem> items = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});
	            
	    		 TargetingTreeSelectionController controller = new TargetingTreeSelectionController();
	    		 controller.addContent();
	    		 controller.saveRecords();
	    		  
	    		  Product2 pro = testDATA.lstPrd2[0];
	    		  pro.Content__c = testDATA.contents[0].Id;
	    		  update pro;
	    		 
	    		 TargetingTreeSelectionController.searchContent('test', testDATA.contents[0].Id);
	    		 pg.getParameters().put('targetId',testDATA.targetting[0].Id );
	    		 pg.getParameters().put('proId',pro.Id );
	    		 pg.getParameters().put('itemId',items[0].Id );
	    		 pg.getParameters().put('froIfr','true' );
	    		 
	    		  Content__c c = new Content__c( Site_Content_Category__c = testDATA.contents[0].Id ,Name='40006666',DartName__c='DartName66006',Type__c = 'Dart - Site' );
	    		  insert c;
	    		  
	    		  Content__c c1 = new Content__c( Site_Content_Category__c = c.Id ,Name='400066633333',DartName__c='DartName66633333',Type__c = 'Dart - Site' );
	    		  insert c1;
	    		 
	    		 controller = new TargetingTreeSelectionController();
	    		 controller.selectedContent = c.id;
	    		 controller.addContent();
	    		 
	    		 controller.selectedContent = c1.id;
	    		 controller.addContent();
	    		 
	    		 controller.saveRecords();
	    		 
	    		 String contentString = controller.contentString;
	    		 Boolean isShowCancel = controller.isShowCancel;    		 
	    		  
	    	Test.stopTest();
       }
    }
    
    
}