public with sharing class KnowledgeEmailArticle {
    public Map<String, Schema.SObjectType> gd  {get;set;}
    public Map<String,String> describeMap {get;set;}
    
    public Map<String, String> theArticles {get;set;} 
    public Map<String, String> ArticleWithQuery {get;set;}
    public Map<String, String> finalArticlePairs {get;set;}
    
    public String caseId {get;set;}
    public List <CaseArticle> myIds {get;set;}
    public SuperQueryLines[] mySQL {get;set;}
    public List<String> myEmailStrings {get;set;} 
    
    public KnowledgeEmailArticle(){
        myIds = new List<CaseArticle>();
        theArticles = new Map<String, String>(); /* String<knowledgeArticleId, articleType> */
        mySQL = new SuperQueryLines[]{};
        finalArticlePairs = new Map<String, String>();
        myEmailStrings = new List<String>();
    }
    
    public PageReference EmailArticle(){
        String[] AllArticles = new String[]{};
        
        caseId = System.CurrentPageReference().GetParameters().Get('id');
        /*get Id's, create describe map, and creates a map of article ID's with article types*/
        myIds = [select KnowledgeArticleId from CaseArticle where CaseId =: caseId ];
        createDescribeMap();
        
        if(myIds.size() >0){
            for(CaseArticle article : myIds){
                String articleType = getArticleType(article.KnowledgeArticleId);
                theArticles.put(article.KnowledgeArticleId, articleType);
                getSObjectFieldList(articleType);
            }
        }
        
        for(String x : theArticles.keySet()){ /* x = article id */
            String xValue = theArticles.get(x); /* xValue = article type. (gives you ???__kav) */
            
            /*builds the SOQL query*/
            List<String> xFields = getSObjectFieldList(xValue);
            String soqlQuery = 'Select ';
            for(String y : xFields) {
                soqlQuery = soqlQuery + y + ',';
            }
            
            /*this gets rid of the last comma from the query string*/
            soqlQuery = soqlQuery.substring(0, soqlQuery.length() - 1);
            soqlQuery = soqlQuery + ' from ' + xValue + ' where KnowledgeArticleId = \''+ x +'\' and PublishStatus = \'Online\'';
            mySQL.add(new SuperQueryLines(xValue, soqlQuery, xFields)); 
        }
        
        
        for(SuperQueryLines q : mySQL){
            SObject myFieldResults = Database.Query(q.queryString);
            Schema.DescribeSObjectResult R = myFieldResults.getSObjectType().getDescribe();
            Map<String, Schema.SObjectField> Fmap = R.fields.getmap();
            
            /*creates a map of labels and api names*/
            Map<String, String> labelNameMap = new Map<String, String>();
            for(String key : Fmap.keySet()){
                labelNameMap.put(key, Fmap.get(key).getDescribe().getlabel());
            }
            
            /*creates a map of labels and values*/
            for(String f : q.myFields){
                String fieldLabel = labelNameMap.get(f);
                String fieldValue = String.valueOf(myFieldResults.get(f));
                finalArticlePairs.put(fieldLabel,fieldValue);
            }
            
            String StringForTemplate = generateEmailText(finalArticlePairs);
            myEmailStrings.add(StringForTemplate);
        }
        
        Integer i = 1;
        blob AllArticlesBlob;
        String AllArticlesString = '';
        for(String a : myEmailStrings){
            AllArticlesString = AllArticlesString + '<br/><b><u>Case Article #'+i+': </u></b><br/>'+a;
            i++;
        }
        
        Case c = [Select All_Articles_String__c, Id, ContactId from Case where Id =: caseId];
        c.All_Articles_String__c = AllArticlesString;
        update c;
        
        EmailTemplate e = [select DeveloperName, Id From EmailTemplate where DeveloperName = 'CasewAnswerText'];
        
        PageReference pr = new PageReference('/_ui/core/email/author/EmailAuthor?retURL=%2F+'+c.Id+'&p3_lkid='+c.Id+'&rtype=003&p2_lkid='+c.ContactId+'&template_id='+e.Id+'&new_template=true');
        return pr;
    }
    
    public String generateEmailText(Map<String, String> FieldsAndValues) {
        String emailContent = '';
        
        for(String fieldKey : FieldsAndValues.keySet()){
            /*****uncomment this if statement and put in a fieldKey you would want to skip*****/
            if(fieldKey == 'Publication Status'){ continue; }
            if(fieldKey == 'URL Name'){ continue; }
            if(fieldKey == 'Internal information'){ continue; }
            if(fieldKey == 'Chat Answer'){ continue; }
            if(fieldKey == 'Title'){ continue; }
            if(fieldKey == 'Summary'){ continue; }
            
            emailContent = emailContent + '<br/>'+fieldKey+': '+ FieldsAndValues.get(fieldKey) +'<br/>';
        }
        return emailContent;
    }
    
    public Map<String,String> createDescribeMap() {
        describeMap = new Map<String, String>(); 
        gd = Schema.getGlobalDescribe();
        Set<String> keySet = gd.keySet();
        
        for (String key : keySet) {
            Schema.SObjectType objectType = gd.get(key);
            if (/* key.endsWith('ka') || key.endsWith('kb') || */ key.endsWith('kav')) {
                describeMap.put(objectType.getDescribe().getKeyPrefix(), objectType.getDescribe().getName());
            }
        }
        return describeMap;
    }
    
        
    public String getArticleType(String articleId) {
        String articlePrefix = articleId.substring(0,3);
        Set<String> keySet = describeMap.keySet();
        String articleType = null;
        for(String key: keySet) {
            if(articlePrefix.equalsIgnoreCase(key)) { 
               articleType = describeMap.get(key);
               return articleType;
            }
        }
        return null;
    }
        
    public List<String> getSObjectFieldList(String articleKAV) {
        List<string> options = new List<String>();
        Map<String, Schema.SObjectField> sobjFields = gd.get(articleKAV).getDescribe().fields.getMap();
        Set <String> keySet = new Set<String>();
        
        
        /* the keyset is a set of all of the fields for the given knowledge article type */
        keySet = sobjFields.keySet();
        for( String x : keySet ) {
            Schema.DescribeFieldResult r = sobjFields.get(x).getDescribe();
            if( r.getSoapType() == SoapType.String ) {
                options.add(x);
            }
        }
        return options;
    }
    
    
    public with sharing class SuperQueryLines {
        public String articleType {get;set;} /* this is the article type */
        public String queryString {get;set;} /* this is the soql query that will query the DB */
        public List<String> myFields {get;set;} /* this is all of the fields for the knowledge article type */
        
        public SuperQueryLines(String at, String q, List<String> f){
            articleType = at;
            queryString = q;
            myFields = f;
        }
    }
}