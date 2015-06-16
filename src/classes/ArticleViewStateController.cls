/**
 *	Task #3757 - Self Help Article Stats
 *	@Created Date : 21-Aug-2014
 *	@Authur : CPN
 * 	@Logic : Controller of ArticleViewstate page to view related Article Deflection for ArticleId
 */
public class ArticleViewStateController {
	public KnowledgeArticleVersion knowArt{get;set;}
	public List<DailyArticleState__c> lstArtStat{get;set;}
	public Boolean hasArtStat{get;set;}
	
	public ArticleViewStateController(){
		String artId = Apexpages.currentPage().getParameters().get('artId');
		artId = artId == null ? '' : artId;
		
		List<KnowledgeArticleVersion> lstKnowArts = [Select ArticleNumber, Title From KnowledgeArticleVersion Where PublishStatus = 'online' and Id=:artId];
		if(!lstKnowArts.isEmpty()) knowArt = lstKnowArts.get(0);
		
		lstArtStat = [Select Name, Id, ViewDate__c, ArticleNumber__c, ArticleTitle__c, LastViewByContact__c, ViewCount__c From DailyArticleState__c Where ArticleId__c =:artId order by ViewDate__c Desc];
		hasArtStat = !lstArtStat.isEmpty();
	}
	
}