/** Connector for new DFP
*/
public with sharing class DART6Connector implements DARTObject.IDARTConnector{
	
	protected HTTPWrapper.IGenericRequest request;
	protected DART6Parser.IDartParser parser;
	 
	public DART6Connector(HTTPWrapper.IGenericRequest request,DART6Parser.IDartParser parser)
	{
		this.request =  request;
		this.parser = parser;
	}

	public void connect()
	{ 
		HTTPWrapper.IInvoker invoker = (HTTPWrapper.IInvoker)request;
		invoker.invoke();   
		 
 
		((DART6Parser.IDART6Parser)parser).setObjectDFP(invoker.getResponseObject()); 
		parser.parse();	 
	} 
	
	public List<DARTObject.IDARTGenericObject> getDartObjects()
	{
		return parser.getListDartObject();
	}  
	
	
	
	
}