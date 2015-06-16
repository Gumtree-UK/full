@isTest
private class ClassifiedsAdsRemainingControllerTest {

    static testMethod void myPage_Test() {

    //Test coverage for the myPage visualforce page
    PageReference pageRef = Page.ClassifiedAdsRemaining;

    Test.setCurrentPageReference(pageRef);
    
    // create an instance of the controller
    ClassifiedsAdsRemainingController  myPageCon = new ClassifiedsAdsRemainingController();
    
    myPageCon.getSites();
    mypageCon.getSiteName();
    mypageCon.getpstatuses();
    mypageCon.getaccstatuses();
    mypageCon.getburnrates();
    mypageCon.getcreditsr();
    mypageCon.getdaysr();
    mypageCon.getolistdcredit();
    mypageCon.getoliftd3credit();
    mypageCon.getoliftd7credit();
    mypageCon.getoliftd14credit();
    mypageCon.getoliftdspotcredit();
    mypageCon.getoliftdurgcredit();
    mypageCon.getoliftdurlcredit();
    
    }
}