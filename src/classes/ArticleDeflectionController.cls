/**
 *  Task #3627 - PKB2 Integrate additional features (GTCRM-350)
 *  @Created Date : 2014-08-13
 *  @Authur : Pheaktra
 *  @Logic : Controller of ArticleDeflection page to view related Article Deflection for ArticleId
 */
public class ArticleDeflectionController {
    
    public KnowledgeArticleVersion knowArt{get;set;}
    public List<PKB_Article_Feedback_Deflection__c> lstArtDefs{get;set;}
    public Boolean hasArtDef{get;set;}
    
    public ArticleDeflectionController(){
        String artId = Apexpages.currentPage().getParameters().get('artId');
        artId = artId == null ? '' : artId;
        
        List<KnowledgeArticleVersion> lstKnowArts = [select ArticleNumber, Title from KnowledgeArticleVersion where PublishStatus = 'online' and Id=:artId];
        if(!lstKnowArts.isEmpty()) knowArt = lstKnowArts.get(0);
        
        lstArtDefs = [select Id, Name, Article_Number__c, Article_Title__c, Comments__c,Deflection__c, Keyword_searched__c from PKB_Article_Feedback_Deflection__c where Article_Id__c =:artId];
        hasArtDef = !lstArtDefs.isEmpty();
    }
    
}