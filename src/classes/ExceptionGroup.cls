/** All exceptions go here
**/
public with sharing class ExceptionGroup {
	
	public ExceptionGroup(){}
	
	/**
	 HTTP Exception
	*/
	public  with sharing class HTTPException extends Exception{
	    
	}
	
	/**
	 Parser Exception
	*/
	public  with sharing class ParserException extends Exception{
	    
	}
	
	/** DART EXCEPTION */
	public class DARTException extends Exception{
		
	}
	
	/** Digest EXCEPTION */
	public class DigestException extends Exception{
		
	}
	/** FetchToken EXCEPTION (DART6?!)*/
	public class FetchTokenException extends Exception{
		
		
	}
	
	/** AvailForecast EXCEPTION (DART6?!)*/
	public class AvailForecastException extends Exception{
		
		
	}
	
	/** Keyvalue EXCEPTION (DART6?!)*/
	public class DARTKeyValueException extends Exception{
	
	}
	
	static testMethod void test()
	{
		Test.startTest();
		
		ExceptionGroup exg = new ExceptionGroup();
		
		Test.stopTest();
		
		
	}
}