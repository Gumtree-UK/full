public with sharing class OpportunityHandler {
	
	public static void updatePrimaryContact(List<Opportunity> lOpportunity){
	   List<OpportunityContactRole> lOpportunityContactRole=new List<OpportunityContactRole>();
	   map<id,id> mapOpptyContactRole=new map<id,id>();
	   String temp;
				
	   lOpportunityContactRole=[select ContactID,OpportunityId from OpportunityContactRole where OpportunityId in:lOpportunity and isPrimary=true ];
	   
	   for	(OpportunityContactRole oOpptyContactRole : lOpportunityContactRole){
	   	   mapOpptyContactRole.put(oOpptyContactRole.OpportunityId,oOpptyContactRole.ContactID );
	   }
	  
	   for (Opportunity oOppty :lOpportunity){
	   	   temp=null;
	       temp=mapOpptyContactRole.get(oOppty.id);	   	
	       if(temp != null){	   		
	   	     oOppty.Primary_Contact__c=temp;	   	    
	      } 	
	   }
	}

}