/**
@Author : spp
@Date : 23/09/2014
@Business :

When case is created via email under Gumtree Robot, we compute the User_Source__c, IP_Address__c

*
*/
trigger CaseUserAgentViaEmai_Trg on EmailMessage (after insert) {
		
	User robot = [SELECT Id, Name FROM User where name='Gumtree Robot'];
	Map<Id,EmailMessage> caseemails = new Map<Id,EmailMessage>();
	
	for(EmailMessage message : trigger.new) {

		// email message created by Gumtree Robot and incoming message
		if(message.CreatedById==robot.Id && message.Incoming) {

			caseemails.put(message.ParentId,message);
			
			System.debug('>> HEADER ' + message.Headers);
	    
	    }
	}
	
	if (!caseemails.keyset().isEmpty()) {
		
		// X-Mailer: iPhone Mail (11D257)
		// X-Mailer: iPad Mail (11D201)
		
		// X-Mailer: BlackBerry Email (2.0.0.7971)
		// X-Mailer: Apple Mail (2.1827)
		// X-Mailer: Microsoft Outlook Express 6.00.2600.0000
		//Mime-Version: 1.0 (Mac OS X Mail 6.2 \(1499\))
		
		// Message-ID: <1332714176.54741.androidMobile@web141101.mail.bf1.yahoo.com>
		
		// Received: from [209.85.212.176] ([209.85.212.176:49560] 
				
		
		// load all cases
		List<Case> tobeupdate = new List<Case>();
		for (Case c : [Select c.Id, c.User_Source__c, c.IP_Address__c, c.User_Source_Extra__c From Case c Where IsClosed=false and Id in : caseemails.keyset()]) {
			
			system.debug('>>> CaseUserAgentViaEmai_Trg Case Id ' + c.Id);
			
			c.User_Source__c = 'Unknown';
			c.User_Source_Extra__c = 'Unknown';
			
			String emailheader = caseemails.get(c.Id).Headers;
			String[] headers = emailheader.split('\n');
			for (String h : headers) {
				
				
				if (h.indexOf('Received: from')>-1 && String.isEmpty(c.IP_Address__c)) {
					system.debug('>>> CaseUserAgentViaEmai_Trg Case header ' + h);
         			String ipsource = NetworkingUtils.extractIP(h);
         			c.IP_Address__c = ipsource;
				}
				
				if (h.indexOf('X-Mailer:')>-1) {
					system.debug('>>> CaseUserAgentViaEmai_Trg Case header ' + h);
					if (NetworkingUtils.isiOS(h)) {
						c.User_Source__c = 'iOS';
						c.User_Source_Extra__c = 'Mobile';
					}
					else if (NetworkingUtils.isBB(h)) {
						c.User_Source__c = 'Blackberry';
						c.User_Source_Extra__c = 'Mobile';
					}					
					
				}
				else if (h.indexOf('Message-ID:')>-1) {
					system.debug('>>> CaseUserAgentViaEmai_Trg Case header ' + h);
					if (NetworkingUtils.isAndroid(h)) {
						c.User_Source__c = 'Android';
						c.User_Source_Extra__c = 'Mobile';
					}
				}
				
        
				
			}
			
			tobeupdate.add(c);
			
		}
		
		if (!tobeupdate.isEmpty()) {
			update tobeupdate;
		}
	}

}