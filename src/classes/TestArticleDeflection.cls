/**
 * This class contains unit tests for validating the behavior of ArticleDeflectionController
 * @createdDate: 13-Aug-2014
 * @author: Pheaktra Hun
 */
@isTest(seeAllData=true)
private class TestArticleDeflection {
	
	//init data
	static{
		
		KnowledgeArticleVersion knowArtVer = [select KnowledgeArticleId from KnowledgeArticleVersion where PublishStatus = 'online' and Language='en_US' limit 1];
		Apexpages.currentPage().getParameters().put('artId',knowArtVer.KnowledgeArticleId);
		
	}
	
	//test constructor
	@isTest static void testInitialize(){
		
		ArticleDeflectionController artCon = new ArticleDeflectionController();
		
	}
	
}