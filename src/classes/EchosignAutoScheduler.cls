/**
*@Author : SPP
*@Date : 14/08/2014
*@Business : 

* Scheduler used to push agreement template -> agreement to EchoSign

Used by WSEchoSignAuto.class

Maybe we better use this scheduler to scan any recent agreement created and push ?

*/
global with sharing class EchosignAutoScheduler implements Schedulable {
	
	private String agreementTemplateId;
	private String oppId;
	
	
	public EchosignAutoScheduler( String agreementTemplateId,String oppId) {
		this.agreementTemplateId = agreementTemplateId;
		this.oppId = oppId;
	}
	
   global void execute(SchedulableContext SC) {
   	
   	Id agreementId = echosign_dev1.AgreementTemplateService.load(agreementTemplateId,oppId);
	delete [Select Id from echosign_dev1__Agreement_Template__c where Id=:agreementTemplateId];
			
   }
  
}