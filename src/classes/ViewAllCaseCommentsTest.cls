@isTest
private class ViewAllCaseCommentsTest{

    static testMethod void myPage_Test() {

    //Test coverage for the myPage visualforce page
    PageReference pageRef = Page.ViewAllCaseComments;

    Test.setCurrentPageReference(pageRef);
    
    // create an instance of the controller
    ViewAllCaseComments  myPageCon = new ViewAllCaseComments();
  
  myPageCon.getComments();

    }
}