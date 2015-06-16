/**
 * Controller for page P2P_MyMetricsPDF.page
 * @author Kakada KHAN
 * @date 28-Nov-2014
 */

global class P2P_MyMetricsPDFController {
     
	public Account acc{get;set;}
	public List<Metrics_Dashboard__c>lstMDs{get;set;}

    //Constructor
    public P2P_MyMetricsPDFController(){
        String accId = ApexPages.currentPage().getParameters().get('accid');
        if(String.isEmpty(accid)) return;
        
        acc = [Select Id, Name from Account where Id=:accId];
        
        lstMDs = [Select Id, Chart_Title__c, Chart_Description__c, Timeframe__c, (Select Id from Attachments) 
        		from Metrics_Dashboard__c where Account__c=:accId order by Position__c];  
    }

}