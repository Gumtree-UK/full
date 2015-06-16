/*
 * This Class test for webservice ContactsGTHelpForm
 * @date 30/09/2014 
 * @author Kakada Khan
 */

@isTest
private class ContactsGTHelpForm_Test {
	
	static testMethod void testUnit(){
		String url = ContactsGTHelpForm.getContactListView();
		System.assert(url.contains('/003?fcf='));
		System.debug('URL>>>>>>>> '+url);
	}
}