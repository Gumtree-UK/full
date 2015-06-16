@RestResource(urlMapping='/AccountMigration/*')
global with sharing class GumtreeMigrationRestResource {

    // Note: apex class version must be 24 or higher

    @HttpGet
    global static Account doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String accountNum = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Account result = [SELECT Id, Name, AccountNumber, Account_Migrated__c FROM Account WHERE AccountNumber = :accountNum];
        return result;
    }

    @HttpPut
    global static Account doMarkAsMigrated() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String accountNum = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Account result = [SELECT Id, Name, AccountNumber, Account_Migrated__c FROM Account WHERE AccountNumber = :accountNum];
        result.Account_Migrated__c = true;
        update result;
        return result;      
    }
    
    @HttpDelete
    global static Account doMarkAsNotMigrated() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String accountNum = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Account result = [SELECT Id, Name, AccountNumber, Account_Migrated__c FROM Account WHERE AccountNumber = :accountNum];
        result.Account_Migrated__c = false;
        update result;
        return result;          	
    }
}