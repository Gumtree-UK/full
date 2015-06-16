/*
*
*@Author : SPP
*@Date : 08/06/2014
*@Business : 

This batch is called the trigger : 
opportunity_after_insert on Opportunity
*
*/
global class EchoSignServicesBatch implements Database.Batchable<sObject>, Database.AllowsCallouts,Database.Stateful{
	global final Set<Id> oppIds;
	global String sessionId;
	
	global EchoSignServicesBatch(Set<Id> oppIds,String sessionId){
		this.oppIds = oppIds;
		this.sessionId = sessionId;
	}
	global Database.QueryLocator start(Database.BatchableContext BC){
      	return Database.getQueryLocator('Select Id from Opportunity Where Id in:oppIds');
   	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope){
     	
     	for(SObject o : scope){
     		Opportunity opp = (Opportunity)o;
     		
     		EchoSignServices.invokeSendAutoEmailProcessWs(opp.Id, sessionId);
     	}
    }

   	global void finish(Database.BatchableContext BC){
   	}
   	
   
}