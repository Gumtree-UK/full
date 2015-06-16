/*
- GTCRM-363 - Show related cases in CS console

Change log:
- GTCRM-376 - Extend number of related cases shown to 5
- GTCRM-791 - Show related live agent cases in CS console
- GTCRM-791 -Live Chat Duplicate detector
*/

public class caseContactcon {
    private Case oCase;
    public Contact oContact {get; set;}   
    private final String contactID;
    private final String caseID;
    public List< Contact> oContacts {get; set;} 
 public List<LiveChatTranscript> lstTranscripts {get; set;} 
     
    public caseContactcon(ApexPages.StandardController stdController) {
        this.oCase = (Case)stdController.getRecord();
        caseID = oCase.Id;
  lstTranscripts = new List<LiveChatTranscript>();
        if (caseID > ''){
            oCase = [SELECT Id, ContactId,Contact.email FROM Case WHERE Id=:caseID];
            contactID = oCase.ContactId;
            if (contactID > ''){
                oContacts = [SELECT Id, AccountId,                            
                            (SELECT Id, CreatedDate, ActivityDate, Subject
                             FROM ActivityHistories
                             ORDER BY ActivityDate DESC LIMIT 5),
                             (SELECT Id, CaseNumber, Status, Subject, CreatedDate, LastModifiedDate
                              FROM Cases
                              WHERE Id <> :caseID
                              ORDER BY LastModifiedDate DESC LIMIT 5)
                            from Contact where Id=:contactID OR (email=:ocase.Contact.email AND email!=null)];
       
       
  
         Set<Id> CaseIds = new Set<Id>();
     for(Contact conRec: oContacts)
     {
      for(Case caseRec: conRec.cases)
      {
       caseIds.add(caseRec.id);
      }
     }
     lstTranscripts = [SELECT Id,Name,Status,Createddate from LiveChatTranscript where CaseId =:caseIds];
       

            }
        }
    }
    public Contact getContact() {
        return oContact;
    }
     public List<Contact> getContacts() {
        return oContacts;
    }
    @isTest(seeAllData=true)
   private static void testController()
    {
      LiveChatTranscript transRec = [SELECT Id,CaseId from LiveChatTranscript where CaseId!=null limit 1];   
   ApexPages.StandardController contr = new ApexPages.StandardController([select Id from Case where Id =: transRec.CaseId limit 1]);
      caseContactcon c = new caseContactcon(contr);
      Contact con = c.getContact();
    }
  
}