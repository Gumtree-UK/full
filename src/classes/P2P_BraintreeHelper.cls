/**
 * Use to support P2P_BraintreeServices class
 * @author Kakada Khan
 * @date 09-Oct-2014
 */


public class P2P_BraintreeHelper { 

	/**
	 * Get id as 15 digits since BrainTree keeps 15 digits 
	 * @param id is the Account Id
	 * @return String as 15 digits charactor
	 */
	public static String getId15Digits(String id){
		return id.substring(0, 15);
	}
	
	/* Example xml:
		------------------------------------------------
		<?xml version="1.0" encoding="UTF-8"?>
		<customer>
			  <id>16681806</id> 
			  <credit-cards type="array">
				    <credit-card> 
				      <default type="boolean">true</default> 
				      <token>k55x6b</token> 
				    </credit-card>
				    <credit-card> 
				      <default type="boolean">false</default> 
				      <token>k55x6b</token> 
				    </credit-card>
			  </credit-cards> 
		</customer> 
		------------------------------------------------*/
		
	 /**	
	 *  Getting a list of Node
	 *  Ex:  xPath = 'customer/credit-cards' will return a list of 2 credit-card nodes
	 *	@param root
	 * 	@param xPath
	 *	@return List<DOM.XMLNode>
	 */
	public static List<DOM.XMLNode> getNodes(DOM.XMLNode root, String xPath) {
		 
		DOM.XMLNode parentNode = getNode(root, xPath.split('/')[0],xPath);
		DOM.XMLNode[] theList = new List<DOM.XMLNode>();
		if( parentNode != null)
		theList = parentNode.getChildElements(); 
		return theList;
	}
	
	
	/**
	 *  TODO: Getting a Node
	 *  Ex: rootName = 'customer' and xPath = 'customer/id' will return an id node
	 *	@param root
	 *	@param rootName
	 *	@param xPath
	 *	@return
	 */ 
	public static DOM.XMLNode getNode(DOM.XMLNode root, String rootName, String xPath){  
    	DOM.XmlNode tmp;
    	
    	if(root == null || String.isBlank(xPath) || rootName.equals(xPath)){
    		tmp = root;
    	}else{
	    	for(DOM.XMLNode node : root.getChildElements()){ 
	            if(tmp == null) tmp = getNode (node, rootName + '/' + node.getName(), xPath);
	            else break;
	        }
    	}
    	return tmp;  
    }
     
    
    /* Example xml:
		------------------------------------------------
		<error>
	          <code>91609</code>
	          <attribute type="symbol">id</attribute>
	          <message>Customer ID has already been taken.</message>
        </error>
		------------------------------------------------*/
		
	 /**	
	 *  TODO: Getting an error connected string
	 *  Ex:  91609 - Customer ID has already been taken.
	 *	@param errors 
	 *	@return String
	 */ 
    public static String getErrorString(DOM.XMLNode[] errors){
    	String errorString = '';
    	for(DOM.XMLNode err : errors){
    		String errCode = getNode(err, 'error', 'error/code').getText();
    		String errMsg  = getNode(err, 'error', 'error/message').getText();
    		errorString += errCode + ' - ' + errMsg + '<br/>';
    	} 
    	return errorString; 
    }

}