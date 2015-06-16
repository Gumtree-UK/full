/**
 * Unit-Testing and Code Converage for classe Gumtree IBFS_ReportReceiveService
 * @category: Test Logic
 * @author : PhanithChhun 
 * @createDate : 14-05-2015
 * @changelog: NONE
 */
@isTest
public class GumtreeIBFSReportReceiveServiceTest{
    
    private static User activeUser;
    
    /**
     * Init test data
     */
    static void setupData(){
        //Create user
        Profile pro = [select id from Profile where Name = 'System Administrator' limit 1];
        activeUser = new User(alias = 'u2', email = 'testIBFS_Report@test.com', emailencodingkey = 'UTF-8',
                            FirstName = 'testIBFS_Report' , lastname='U', languagelocalekey = 'en_US',
                            localesidkey = 'en_US', profileid = pro.Id, timezonesidkey = 'America/Los_Angeles', CommunityNickname = 'u2',
                            isActive = true, username = 'testIBFS_Report@test.com');
        insert activeUser;
        
        //Create account coresponding to IBFS_ReportReceiveService.fakeResponse
        List<Account> lacc = new List<Account>();
        List<String> accNumbers = new List<String>{'3668', '3692', '1815', '3631'};
        for(String accNum : accNumbers){
            lacc.add(
                new Account(
                    AccountNumber=accNum, 
                    Name=accNum, 
                    BillingStreet = 'ds',
                    BillingCity = 'ds',
                    BillingCountry = 'GB',
                    BillingPostalCode = 'ds'
                )
            );
        }
        insert lacc;
    }
    
    /**
     * Test All functionalities in one method
     */
    static testmethod void testGumtreeIBFSReportReceiveService(){
        setupData();
        System.runAs(activeUser){
            Test.startTest();
                System.assertEquals('true', GumtreeIBFSReportReceiveService.doPost());
            Test.stopTest();
        }
    }
}