/**
 * 	This class will provide the specified URL to Contact Listview.
 *	Call from javascript on button (Account) View Contacts.
 *	@author Kakada Khan
 *	@date 30/09/2014
 *	
 */

global class ContactsGTHelpForm {
	
	/** 
	* Execute by javascript, redirect to Contact ListView.
	* @return String The URL for Contact ListView
	*/	
    webService static String getContactListView(){
    	
    	//ListView URL Prefix of Contact
    	String url = '/003?fcf=';
    	
        String q = 'SELECT Name FROM Contact LIMIT 1';
        ApexPages.StandardSetController SSC = new ApexPages.StandardSetController(Database.getQueryLocator(q));
        List<SelectOption> ListViews = SSC.getListViewOptions();
        
        for(SelectOption w : ListViews ){
            if(w.getLabel().equals('Contacts Error - CS Account')){
                url += w.getValue().left(15);
                break;
            }
        }
        
        return url;     
    }
}