public with sharing class GumtreeGeneratePDFV2 {

        public string imageUrl{get;set;}
        public Opportunity Opp {get;set;}
        public OpportunityLineItem opli{get;set;}
        public list<DTO> listDTO{get;set;}
        public integer addLine{get;set;}
        public integer creative{get;set;}
        public integer screenshot{get;set;}
       // final String SHORTTYPE='Screenshot-Image';
       public String agency{get;set;}
         public GumtreeGeneratePDFV2(){
            addLine=0;
            creative=0;
            screenshot=0;
            
            String oppId =ApexPages.currentPage().getParameters().get('Oppid');
            String groupId = ApexPages.currentPage().getParameters().get('groupId');
            listDTO = showContentVersion(oppId,groupId);
            
         }
         
         private list<DTO> showContentVersion (String oppId,String groupId){
        	 string url = '';
         	string shortType=REST_DFPScreenshot.SHOT_TYPE_CHUNCK;
            Opp=[select Account.Name,Agency__r.Name,Name,Campaign_Start__c,Campaign_End__c,IOnumber__c,Owner.Name,Owner.Phone,Owner.Email from Opportunity where Id=:oppId];              
            agency=Opp.Agency__r.Name!=null?'|  Agency: '+Opp.Agency__r.Name:''; 
            map<string,List<String>> mapCon=new map<string,List<String>>();
           	 Set<String> allCreatives = new Set<String>();  
              Set<String> allAds = new Set<String>();  
              Set<String> allLines = new Set<String>(); 
            for(ContentVersion con:[select  Shot_Type__c,Line_Item__c,Creative__c,AdId__c,Opportunity__c,Group_Id__c from ContentVersion where Opportunity__c =:oppId and Group_Id__c=:groupId And  Shot_Type__c=:shortType]){
			   system.debug('>>>con=='+con); 
			    if(con.Line_Item__c==null) continue;
			    String key =  (con.Line_Item__c+'xxx').substring(0,15);
			    if(!mapCon.containsKey(key)){
			        mapCon.put(key,new List<string>());
			     }
			    url='/sfc/servlet.shepherd/version/download/'+con.Id+'?operationContext=CHATTER&asPdf=false';
			     mapCon.get(key).add(url); 
			    allCreatives.add(con.Creative__c);
			  	allAds.add(con.AdId__c);
			  	allLines.add(con.Line_Item__c);
                 
            }
           	addLine=allAds.size();
            creative=allCreatives.size();
            screenshot=allCreatives.size();
            list<DTO> dtos=new list<DTO>();
            listDTO=new list<DTO>();
             system.debug('>>>mapCon=='+mapCon); 
          for(OpportunityLineItem opli: [select Id,OpportunityId,AdServer_ID__c,Ad_Id__c,Creative_Size__c,PricebookEntry.Product2.Advertising_Medium__r.Name,PricebookEntry.Product2.Advertising_Medium__r.Dart_AdSlotSize__c from OpportunityLineItem where Id in: mapCon.keySet() ] ){
             string key = (''+opli.Id).substring(0,15);
              system.debug('>>>key=='+key+'>>>>>>opli:'+opli); 
             if( mapCon.get(key).isEmpty()) continue;// mapCon.get(opli.Id).isEmpty()||  mapCon.get(opli.Id).isEmpty()
             DTO dto=new DTO(mapCon.get(key),opli);
             dtos.add(dto);
               
          }
         
             creative=screenshot;
             return dtos; 
   }
     public class DTO{
        public list<string> atIds{get;set;}
        public OpportunityLineItem opli{get;set;}
        public DTO(list<string> atIds,OpportunityLineItem opli){
            this.atIds = atIds;
            this.opli = opli;
        }
            
        
        
     }


}