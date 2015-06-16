/**
 *	Task #3627 - PKB2 Integrate additional features (GTCRM-350)
 *	@Created Date : 2014-08-11
 *	@Authur : Pheaktra
 * 	@Logic : Controller of Standard Article View page use for created Article Deflection mapped current view Article
 */
public class KnowledgeStandardViewController {
	
	public final static Boolean DEFLECTION_YES = true;
	public final static Boolean DEFLECTION_NO = false;
	
	public KnowledgeArticleVersion knowArt;
	public Boolean isAnswer { get; set; }
	public Boolean isAnswerNo { get; set; }
	public Boolean isShowQuestion { get; set; }
	public String articleId { get; set; }
	public PKB_Article_Feedback_Deflection__c adf { get; set; }
	private User curUser;
	
	
	/**
	 * Constructor
	 * @modifiedBy: CPN 19-Aug-2014
	 * @description: Task #3757
	 */
	public KnowledgeStandardViewController(){
		isAnswer = false;
		isAnswerNo = false;
		isShowQuestion = false;
		curUser = [Select ContactId From User Where Id =: UserInfo.getUserId()];
	}
	
	//The article has been viewed
    public Pagereference initDeflection() {
    	List<KnowledgeArticleVersion> lstKnowArts = [Select Id, articleNumber, title, KnowledgeArticleId From KnowledgeArticleVersion Where PublishStatus = 'online' And Id =: articleId];
		if(!lstKnowArts.isEmpty()) knowArt = lstKnowArts.get(0);
		if(knowArt == null){
    		system.debug('Can not create article deflection !!!');
    		return null;
    	}
    	doCountWeeklyArticleView();
    	
    	isShowQuestion = true;
		adf = new PKB_Article_Feedback_Deflection__c();
    	adf.Article_ID__c = get15CharId(knowArt.Id);
	    adf.Article_Number__c = knowArt.articleNumber;
	    adf.Article_Title__c = knowArt.title;
	    adf.Keyword_searched__c = '';
	    adf.Comments__c = '';
	    adf.Contact__c = curUser.ContactId;
	    return null;
	}
	
	//Button "Yes" clicked
    public Pagereference deferred() {
	    upsertDeferral(DEFLECTION_YES);
	    isAnswer = true;
	    isShowQuestion = false;
	    return null;
	}
	
	//Button "No" clicked
	public PageReference requestFeedBack(){
		isAnswerNo = true;
		isAnswer = false;
		isShowQuestion = false;
		return null;
	}
	
	//Submit "No" Reason
	public Pagereference recordArticleFeedback() {
    	upsertDeferral(DEFLECTION_NO);
    	isAnswer = true;
    	isAnswerNo = false;
    	return null;
  	}
	
	/**
	 *	Create Article Deflection mapped with current Article
	 */
    private void upsertDeferral(Boolean deflectionState) {
	    // validate that the feedback source option is a valid option
	    adf.Deflection__c = deflectionState;
	    upsert adf;
	}
	
	// Count article view in a week
	private void doCountWeeklyArticleView(){
		Date todayDate = Date.today();
		String strArtId = get15CharId(articleId);
		DailyArticleState__c das = new DailyArticleState__c(
			ArticleId__c = strArtId,
			ArticleNumber__c = knowArt.articleNumber,
			ArticleTitle__c = knowArt.title,
			ViewDate__c = todayDate,
			ViewCount__c = 1,
			LastViewByContact__c = curUser.ContactId
		);
		List<DailyArticleState__c> ldas = [Select LastViewByContact__c, ViewCount__c From DailyArticleState__c Where ArticleId__c =: strArtId And ViewDate__c =: todayDate];
		if(!ldas.isEmpty()){
			das = ldas[0];
			das.LastViewByContact__c = curUser.ContactId;
			das.ViewCount__c += 1; 
		}
		upsert das;
	}
	
	private String get15CharId(String id){
		return id.substring(0, 15);
	}
}