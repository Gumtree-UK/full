/**
 Factory of Connector</br>
 for Switching from DART to DFP
*/
public with sharing class FactoryConnector {

	private static FactoryConnector instance;
	private FactoryConnector(){}
	
	public static FactoryConnector getInstance()
	{
		if(instance==null)
		{
			instance = new FactoryConnector();
		}
		 
		return instance;
	}
		
	public DARTObject.IDARTConnector createConnector(String dartVersion,HTTPWrapper.IGenericRequest request,DART6Parser.IDartParser parser)
	{	
		if(DARTUtil.DART6.equals(dartVersion)) // new version
		{	
			return new DART6Connector(request,parser);
		} 
		 
		return null; 
	}
}