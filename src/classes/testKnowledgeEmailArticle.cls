@isTest
private class testKnowledgeEmailArticle {
    static testMethod void testKnowledgeEmailArticle(){
        KnowledgeEmailArticle controller = new KnowledgeEmailArticle();
        String testId = '500w000000bIHW8AAO';
        
        Apexpages.currentPage().getParameters().put('id', testId);
        List<CaseArticle> testMyIds =[select KnowledgeArticleId from CaseArticle where caseId =: testId  limit 10];
        
        controller.createDescribeMap();
        controller.myIds = testMyIds; 
        
        controller.EmailArticle();
        String testArticleId = 'kA120000000TNNV';
        controller.getArticletype(testArticleId);
        
        String testArticleKav = 'FAQ__kav';
        controller.getSobjectFieldList(testArticleKav);
        List<String> testFieldList = new List<String>();
        testFieldList.add('Question');
        testFieldList.add('Title');
        testFieldList.add('Answer'); 
        String testQuery = 'select Question, Title, Answer from FAQ__kav where KnowledgeArticleId = \'kA120000000TNNV\' and PublishStatus = \'Online\'';
        
        
        //SuperQueryLines wrapperClass = new SuperQueryLines('FAQ__kav', testQuery, testFieldList);
        
    }
}