/**
 *
 * @createddate: 29/08/2014
 * @author: Kakada Khan
 */

public with sharing class CustomLookupContactEmail {
	
	public String lblSearchResult {get; set; }
    public Boolean hasRecord { get{ return lstContact.size() > 0; } }
    public String comId { get; set; }
    
    public String acctId { get; set; }
    public String contactName{get;set;}
    
    public List<Contact> lstContact { get; set; }
    
    public String year{ get{ return System.now().year() + '';} }
    

    public CustomLookupContactEmail(){
        comId = Apexpages.currentPage().getParameters().get('comId');
        acctId = Apexpages.currentPage().getParameters().get('accId');
        doSearch();
    }

    public void doSearch(){
        lblSearchResult = 'Search Results';
        String f = 'Where AccountId = \''+acctId +'\'';
        if(contactName != null && contactName != ''){
            f+='AND Name like \'%'+ String.escapeSingleQuotes(contactName.replace('*','%')) + '%\' ORDER BY Name';
        }
        lstContact = Database.query('Select Id, Name From Contact ' + f);
    }

    public void doClear(){
        acctId = null;
        doSearch();
    }

}