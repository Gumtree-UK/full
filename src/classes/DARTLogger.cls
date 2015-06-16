/** Singleton : Log message for DARTx
Created: 07/12/2012
Last Modified:
*/
public with sharing class DARTLogger {
  
  public final static String TYPE_SUCCESS = 'SUCCESS' ;
  public final static String TYPE_WARNING ='WARNING';
  public final static String TYPE_ERROR ='ERROR' ;
  
  public final static String OPPERATION_FORECAST = 'AVAILABILITY_FORECAST' ;
  public final static String OPPERATION_SUBMIT_ORDER = 'ORDER_SUBMIT';
  public final static String OPPERATION_SUBMIT_ADS = 'ADS_SUBMIT';
  public final static String OPPERATION_UPDATE_OPP = 'UPDATE_OPPORTUNITY';
  public final static String OPPERATION_UPDATE_OPPLINEITEM = 'UPDATE_OPPORTUNITYLINEITEM';
    public final static String OPPERATION_SUBMIT_COMPANY_ADVERTISER ='COMPANY/ADVERTISER_SUBMIT';
  public final static String OPPERATION_CREATE_NEW_ADVERTISER = 'CREATE_ADVERTISER';
  public final static String OPPERATION_UPDATE_ADVERTISER = 'UPDATE_ADVERTISER';
  
  //MORE HERE.....
  //public final static String OPPERATION_REQUEST....
  
  private static DARTLogger logger;
  
  private DARTLogger(){}
  
  public static DARTLogger getInstance()
  {
    if(logger==null)
    {
      logger = new DARTLogger();
    }
    
    return logger;
  }
  /** Log an error (specific for logging exception)*/
  /*
  public void log(String objId,String operation,String dMethod,String dartVersion,Exception ex)
  {
    log(new Map<String,Exception>{objId=>ex},operation,dMethod,dartVersion);
  }
  */
  /** Log multiple errors at once (specific for logging exception)*/
  
  /*
  public void log(Map<String,Exception> exSet,String operation,String dMethod,String dartVersion)
  {
    Note[] listAtt = new List<Note>();
    for(String recId : exSet.keySet())
    {
      Exception ex = exSet.get(recId);
      Note att = prepareNoteLog(recId,operation,dMethod,dartVersion,TYPE_ERROR,ex.getMessage(),ex.getStackTraceString());
      listAtt.add(att);
    }
    saveNotes(listAtt);  
  }
  */
   
  /** Log a simple message (any message)
  */
  
  /*
  public void log(String parentId,String operation,String dMethod,String dartVersion,String status,String msg,String detail)
  {
    Note att = prepareNoteLog(parentId,operation,dMethod,dartVersion,status,msg,detail);
    saveNotes(new Note[]{att});
  }
  */
  /** Log multiple message at once (any message)
  */
  /*
  public void log(ILogMessage[] logMsg)
  {
    Note[] listAtt = new List<Note>();
    for(ILogMessage msg: logMsg)
    {
      Note att = prepareNoteLog(msg.getRecordId(),msg.getOperation(),msg.getMethod(),msg.getDartVersion(),msg.getStatus(),msg.getMessage(),msg.getDetail());
      listAtt.add(att);
    }
    saveNotes(listAtt);  
  }
  */
  /** Combine all message into one Note log, and attach to a parent records.
    e.g: multiple lineitems messages log attach to opportunity as Note
  */
  public void log(String parentId,ILogMessage[] logMsg)
  {  //Conbine all msg into one
    String combineMessage = '';
     
    for(ILogMessage msg: logMsg)
    {
      combineMessage+= prepareBody(msg.getRecordId(),msg.getOperation(),msg.getMethod(),
              msg.getDartVersion(),msg.getStatus(),msg.getMessage(),msg.getDetail());
              
      combineMessage+= LINE_BREAK;
       
    }
    //and save as note attach to parent object
    saveNotes(new Note[]{newNote(parentId,'DART LOG:'+System.now(),combineMessage)});
  }
  
  /*private Note prepareNoteLog(String parentId,String operation,String dMethod,String dartVersion,String status,String msg,String detail)
  {
    String body = prepareBody(parentId,operation,dMethod,dartVersion,status,msg,detail);
    
    return newNote(parentId,'DART LOG -'+operation+' - '+System.now(),body);
  }
  */
  
  
  private String prepareBody(String parentId,String operation,String dMethod,String dartVersion,String status,String msg,String detail)
  {
    String body = MESSAGE_TEMPLATE.replace('{!dateTime}',System.now()+'').replace('{!recordId}',parentId)
    .replace('{!dartVersion}',dartVersion)
    .replace('{!opperation}',operation).replace('{!method}',dMethod).replace('{!status}',status)
    .replace('{!msg}',msg).replace('{!msgDetail}',detail);
    
    return body; 
  }
  
  private Note newNote(String parentId,String title,String body)
  {
  	
    Note n = new Note(Title=title,ParentId=parentId,Body=body);
    return n;
  }
  
  private void saveNotes(Note[] atts)
  {
    try
    {
    	 
      Database.SaveResult[] logSaveResult = Database.Insert(atts, false);//partial success
      //System.debug('-----------LogMessage-------------> logSaveResult: ' + logSaveResult);
      //System.debug('-----------LogMessage-------------> atts: ' + atts);
      
    }catch(Exception ex)
    {
      System.debug('**************DART LOGGER: Attachment Saving Fail*****\n\rMessage:'+ex.getMessage()+'\n\rStackTrace:'+ex.getStackTraceString());
    }
    
  }
  
  final String LINE_BREAK = '\n\r--------------------------------------------------------------------------------------\n\r';
  final String MESSAGE_TEMPLATE ='Date Time:\t\t\t{!dateTime}'+
  '\n\rDART Version:  {!dartVersion}'+
  '\n\rRecordId:    {!recordId}'+
  '\n\rOperation:    {!opperation}'+
  '\n\rMethod:    {!method}'+
  '\n\rStatus:    {!status}'+
  '\n\rMessage:    {!msg}'+
  '\n\rDetail:\n\r{!msgDetail}'
  ;
  
  public interface ILogMessage{
    String getRecordId();
    String getOperation();
    String getDartVersion();
    String getMethod();
    String getStatus();
    String getMessage();
    String getDetail();
  }
   
  public class LogMessage implements ILogMessage{
    
    String parentId, operation, dMethod, dartVersion, status, msg, detail;
    /**Constructor */
    public LogMessage(){}
    /**Constructor */
    public LogMessage(String parentId,String operation,String dMethod,String dartVersion,String status,String msg,String detail)
    {
      this.parentId = parentId;
      this.operation = operation;
      this.dMethod = dMethod;
      this.dartVersion = dartVersion;
      this.status = status;
      this.msg = msg;
      this.detail = detail;
      
     
    }
    /** constructor log error */
    
    public LogMessage(String parentId,String operation,String dMethod,String dartVersion,Exception ex)
    {
      this(parentId,operation,dMethod,dartVersion,TYPE_ERROR,ex.getMessage(),ex.getStackTraceString());
    }
    
    
    
    public String getRecordId()
    {
      return parentId;
    }
    public String getOperation()
    {
      return operation;
    }
    public String getDartVersion()
    {
      return dartVersion;
    }
    public String getMethod()
    {
      return dMethod;
    }
    public String getStatus()
    {
      return status;
    }
    public String getMessage()
    {
      return msg;
    }
    public String getDetail()
    {
      return detail;
    }
  }
}