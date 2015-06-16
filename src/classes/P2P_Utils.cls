public without sharing class P2P_Utils{
    
    //****** Apex Controller Util ******
    public static List<SelectOption> getPicklist(String obName, String fieldName) {
        SObject so = Schema.getGlobalDescribe().get(obName).newSObject();
        Schema.DescribeSObjectResult sObjDescribe = so.getSObjectType().getDescribe();
        return getPicklist(sObjDescribe, fieldName);
    }
    
    private static List<SelectOption> getPicklist(Schema.DescribeSObjectResult sObjDescribe, String fieldName) {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult describeField = sObjDescribe.fields.getMap().get(fieldName).getDescribe();
        for(Schema.PicklistEntry pck : describeField.getPicklistValues()) {
            options.add(new SelectOption(pck.getValue(), pck.getLabel(), !pck.isActive()));
        }
        return options;
    }
    
    public static List<SelectOption> getPickList(List<String> lstOptions){
        List<SelectOption> options = new List<SelectOption>();
        
        for(String opt: lstOptions){
            options.add(new SelectOption(opt, opt));
        }
        return options;
    }  
    
    public static String dateToStringWithFormat(Date d, String dateFormat){
        Datetime dt = Datetime.newInstance(d.year(), d.month(), d.day());
        return dt.format(dateFormat);
    }
    
    public static String curAccId;
    public static String retrieveCommunityAccountId(){
        if(curAccId == null){
            User curUser = [Select GT_AccountNumber__c, ContactId From User Where Id =: UserInfo.getUserId()];
            if(curUser.ContactId == null) curAccId = ApexPages.currentPage().getParameters().get('id');
            else curAccId = [Select Id From Account Where AccountNumber =: curUser.GT_AccountNumber__c Limit 1].Id;
        }
        return curAccId;
    }
    
    public static String getSitePrefix(){
        return Site.getPathPrefix() == null ? '' : Site.getPathPrefix();
    }
    
    public static String attachmentPhoto(String attNameAsId){
        attNameAsId = attNameAsId.substring(0,15) + '%';
        List<Attachment> atts = [Select Body From Attachment Where Name like:attNameAsId];
        if(atts.isEmpty()) return '';
        return blobToImageDataUrl(atts[0].Body);
    }
    
    public static String blobToImageDataUrl(Blob b){
        return 'data:image/png;base64,' + EncodingUtil.base64Encode(b);
    }
    
    //***** SSO Utils ******
    private static P2P_GumtreeRequestSetting__c gtReqSetting = P2P_GumtreeRequestSetting__c.getInstance('SSO_Request');
    /**
     * This method return true if user is able to access page, meaning the use is passed the authentication 
     * Available to Community Only
     * redirPage: ApexPages.currentPage().getUrl() ==>  /apex/Test?id=32423423
     * siteURL: Site.getCurrentSiteUrl() ==> http://force2b.test.cs3.force.com/testSite/
     */
    public static String generateAuthGTBusAccURL(String redirPage, String siteURL, String loggedIdenParam){
        //Leave it without authentication: Auth Provider should handle it.
        return null;
        if(gtReqSetting == null || String.isEmpty(getSitePrefix())) return null;
        redirPage += (redirPage.contains('?') ? '&' : '?') + loggedIdenParam;
        return gtReqSetting.SSOAuthURL__c + '?' + gtReqSetting.SSORedirectParamName__c + '=' + EncodingUtil.urlEncode(redirPage, 'UTF-8') + '&' + gtReqSetting.SSOOrgParamName__c + '=' + EncodingUtil.urlEncode(siteURL, 'UTF-8');
    }
}