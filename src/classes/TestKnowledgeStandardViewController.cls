/**
 * This class contains unit tests for validating the behavior of KnowledgeStandardViewController
 * @createdDate: 13-Aug-2014
 * @author: Pheaktra Hun
 */
@isTest(seeAllData=true)
private class TestKnowledgeStandardViewController {
	
	private static KnowledgeArticle knowArt;
	private static KnowledgeArticleVersion knowArtVer;
	
	//init data
	static{
		knowArtVer = [select KnowledgeArticleId from KnowledgeArticleVersion where PublishStatus = 'online' and Language='en_US' limit 1];
		knowArt = [select Id from KnowledgeArticle where Id =:knowArtVer.KnowledgeArticleId];
	}
	
	//test create Deflection
	@isTest static void testCreateArtDef(){
		KnowledgeStandardViewController knowCon = new KnowledgeStandardViewController();
		ArticleViewStateController artViewCon = new ArticleViewStateController();
		knowCon.articleId = knowArtVer.Id;
		Test.startTest();
			knowCon.initDeflection();
			knowCon.deferred();
			knowCon.recordArticleFeedback();
		Test.stopTest();
	}
}