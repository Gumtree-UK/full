@isTest
private class ViewAllHistoryTest{

    static testMethod void myPage_Test() {

    //Test coverage for the myPage visualforce page
    PageReference pageRef = Page.ViewAllHistory;

    Test.setCurrentPageReference(pageRef);
    
    // create an instance of the controller
    ViewAllHistory  myPageCon = new ViewAllHistory();
  
  myPageCon.getTasks();

    }
}