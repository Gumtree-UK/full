public class ViewAllCaseComments{

    public ViewAllCaseComments() {

    }
        
    public CaseComment[] getComments() {
           return [SELECT Id, ParentId, CommentBody, CreatedDate, CreatedById FROM CaseComment
                WHERE ParentId = :ApexPages.currentPage().getParameters().get('id')
                ORDER BY CreatedDate DESC
                ];
    } 
 
    
}