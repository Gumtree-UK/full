public class ViewAllHistory{

    public ViewAllHistory() {

    }
        
    public Task[] gettasks() {
           return [SELECT Id, WhatId, WhoId, AccountId, Subject, Description, Type, Time_Date_Event__c, ActivityDate FROM Task
                WHERE AccountId = :ApexPages.currentPage().getParameters().get('id')
                AND Time_Date_Event__c != null
                ORDER BY Time_Date_Event__c DESC 
                Limit 20
                ];
    } 
 
    
}