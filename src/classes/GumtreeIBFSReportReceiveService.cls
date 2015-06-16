/**
 * Task #5283: GTCRM-2012 - Gumtree IBFS Report ReceiveService
 * Used to insert/update multiple (ARRAY) of IBFS_Feed_Reports sent from Gumtree with REST API
 * @createDate : 14-05-2015
 * @category: Import Gumtree 
 * @author : PhanithChhun
 * @changelog: NONE
 */
@RestResource(urlMapping='/ibfsfeedreportsinsert/*')
global class GumtreeIBFSReportReceiveService{
    
    //Test response JSON
    public static String fakeResponse = '{ "1815": { "mitchellbutler": [ { "accountId": "1815", "loginName": "mitchellbutler", "branch": "Mitchells & Butlers", "email": "daniel.sage@mbplc.com", "totalAds": 3016, "processed": 2932, "unprocessed": 0, "error": 84, "imageCount": 2311, "imageErrorCount": 0 } ] }, "3631": { "rainbowreid": [ { "accountId": "3631", "loginName": "rainbowreid", "branch": "Rainbow Reid", "email": "lettings@rainbowreid.co.uk", "totalAds": 13, "processed": 12, "unprocessed": 0, "error": 1, "imageCount": 77, "imageErrorCount": 1 } ] }, "3668": { "nestons": [ { "accountId": "3668", "loginName": "nestons", "branch": "Nestons", "email": "info@nestons.com", "totalAds": 0, "processed": 0, "unprocessed": 0, "error": 0, "imageCount": 0, "imageErrorCount": 0 } ] }, "3692": { "ludlowthompson": [ { "accountId": "3692", "loginName": "ludlowthompson", "branch": "Ludlowthompson Tooting", "email": "tootlet@ludlowthompson.com", "totalAds": 0, "processed": 0, "unprocessed": 0, "error": 0, "imageCount": 0, "imageErrorCount": 0 } ] } }';
    
    /**
     * Import Feed Report to SFDC : sample response as fakeResponse
     * @return String, 'true' operation is success, else is the error message.
     */
    @HttpPost
    global static String doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String responseBody = fakeResponse;
        if(!Test.isRunningTest()) responseBody = req.requestBody.toString();
        JSONParser parser = JSON.createParser(responseBody);
        List<FeedReport> lfeedRpts = new List<FeedReport>();
        //passing Json Response
        try{
            while (parser.nextToken() != null) {
              if(parser.getCurrentToken() == JSONtoken.START_ARRAY){
                while(parser.nextToken() != null){
                    if(parser.getCurrentToken() == JSONToken.START_OBJECT){
                        FeedReport fdRpt = (FeedReport)parser.readValueAs(FeedReport.class);
                        lfeedRpts.add(fdRpt);
                        break;
                    }
                }
              }        
            }
            if (lfeedRpts.isEmpty()) return 'No Feed Report found in message';
            Set<String> sAccountId = new Set<String>();
            for(FeedReport fr : lfeedRpts){
                if (!String.isEmpty(fr.accountId)){
                    sAccountId.add(fr.accountId);
                }
            }
            if (sAccountId.isEmpty()) return 'No account found in message';
            
            //Look up account in SFDC
            Map<String, Id> mSfAccount = new Map<String, Id>();
            List<Account> accList = [select Id, AccountNumber from Account where AccountNumber in: sAccountId];
            for(Account acc : accList){
                mSfAccount.put(acc.AccountNumber, acc.Id);
            }
            if (accList.isEmpty()) return 'No matching accounts found';
            List<IBFS_Report__c> lnewReport = new List<IBFS_Report__c>();
            for(FeedReport fr : lfeedRpts){
                IBFS_Report__c ifr = createSfFeedReport(fr, mSfAccount);
                lnewReport.add(ifr);
            }
            insert lnewReport;
        }catch(Exception ex){
            return ex.getMessage();
        }
        return 'true';
    }
    
    /**
     * FeedReport object to be casted to IBFS_Report__c object
     */
    private static IBFS_Report__c createSfFeedReport(FeedReport fr, Map<String, Id> mSfAccount){
        IBFS_Report__c ifr = new IBFS_Report__c();
        ifr.Report_date__c = System.today();
        if(!String.isEmpty(fr.accountId)) ifr.Account__c = mSfAccount.get(fr.accountId);
        ifr.Ads_in_Feed__c = fr.totalAds;
        ifr.Ads_Posted__c = fr.processed;
        ifr.Ads_not_processed__c = fr.unprocessed;
        ifr.Ads_Failed__c = fr.error;
        ifr.Images_Posted__c = fr.imageCount;
        ifr.Images_Failed__c = fr.imageErrorCount;
        return ifr;
    }
    
    /**
     * Memory Data model for accessing response 
     */
    public class FeedReport{
        String accountId;
        String loginName;
        String branch;
        String email;
        Decimal totalAds;
        Decimal processed;
        Decimal unprocessed;
        Decimal error;
        Decimal imageCount;
        Decimal imageErrorCount;
    }
}