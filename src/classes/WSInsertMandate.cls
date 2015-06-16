/*
  
2014-05-14 - GTCRM-807 - Gumtree UK Direct Debit

Requirements;
    * log Theary 27-03-2014 
    * Web service call in Generate_DD_Form from ManDate and Generate_I/O_classifieds
    * Condition On Opportunty payment method=DirectDebit and StageName='Booking'
    * Condtion on Mandate payment method=DirectDebit and MandateStatus='Rejected'
    
*/

global class WSInsertMandate {
    
    public static final String PAYMETHOD='Direct Debit' ;
    public static final String STATENAME='Booking';
    public static final String MANSTATUS='NOK';
    public static final String MODULECHECKSALEOPP='Rejected';
    
    webservice static String insertMandate(String  oppId,string isOpp){
        Mandate__c objMan;
        string result='NONE';
        Map<string,String> mapPAYMETHOD=new Map<String,String>{'Direct Debit'=>'Direct Debit','Invoice'=>'Invoice'};
        try{
            Opportunity opp=[select Direct_Debit_Mandate__r.Mandate_Status__c,Direct_Debit_Mandate__r.Modulus_Check_Sales_Ops__c,Account.Account_Number_Fiqas__c,Payment_Method__c,StageName,AccountId,Account.Primary_contact__c from Opportunity where id=:oppId];
        
            if((PAYMETHOD.Equals(opp.Payment_Method__c ) &&
           	//   if(mapPAYMETHOD.containsKey(opp.Payment_Method__c ) &&
               		( (!STATENAME.equals(opp.StageName) && isOpp.equals('OPP') ) // I/O Generate button from Opportunity
              		// || ( MANSTATUS.equals(opp.Direct_Debit_Mandate__r.Mandate_Status__c) && !isOpp.equals('OPP')) )){//DD Mandate button Generate from Mandate object
             	 	//   || (('Pending'.equals(opp.Direct_Debit_Mandate__r.Mandate_Status__c) && 'Rejected'.equals(opp.Direct_Debit_Mandate__r.Modulus_Check_Sales_Ops__c)) && !isOpp.equals('OPP')) )){//request updated by Sri 30-07-2014
                	|| ((('Pending'.equals(opp.Direct_Debit_Mandate__r.Mandate_Status__c) && 'Rejected'.equals(opp.Direct_Debit_Mandate__r.Modulus_Check_Sales_Ops__c))
                  	||('NOK'.equals(opp.Direct_Debit_Mandate__r.Mandate_Status__c) && 'Approved'.equals(opp.Direct_Debit_Mandate__r.Modulus_Check_Sales_Ops__c)) )
                 	&& !isOpp.equals('OPP'))) //request updated by Sri 30-07-2014
                 ) || ('Invoice'.equals(opp.Payment_Method__c) && !isOpp.equals('OPP'))){//request by Sri 15-09-2014
                
                    //NK:11/04/2014: CustNr validation to accept account number from Busfire
                   /* if((opp.Account.Account_Number_Fiqas__c+'').length() != 12 )
                    {
                        return 'Validation: Invalid Account Number!';
                    }*/
                    
                    objMan=new Mandate__c();
                    objMan.Opportunity__c=oppId;
                    objMan.Account__c=opp.AccountId;
                    if(!isOpp.equals('OPP')){// objMan.Mandate_Status__c='NOK';
                       objMan.Mandate_Status__c='Pending';
                       objMan.Modulus_Check_Sales_Ops__c='Pending';
                       objMan.I_O_Display__c=true;
                    }
                    insert objMan;
                    opp.Direct_Debit_Mandate__c = objMan.id;
                    update opp;
                    result='OK';   
            }
        }catch(Exception ex){
            ex.getStackTraceString();
            result='Error:'+ex.getStackTraceString();
        }
        return result;
    }
    
    
    /**
    *
    *
    */
    webservice static String getPdfPagenameForGenerateAndAttach(String  oppId){
        
        Opportunity opp=[select Payment_Method__c,RecordTypeId, RecordType.DeveloperName, Account.Apply_VAT__c,Total_Discount_Check__c from Opportunity where id=:oppId];
        
        return Utils.getPdfPagenameForGenerateAndAttach(opp);     
    
    }
    
    
     static testMethod void cloneOpportunity() {

            User user = [select Id from User where IsActive=true limit 1];
    
            Account acc = new Account();
        acc.Name = 'Test Account 1'; 
        acc.BillingStreet = 'Fake Street';
        acc.BillingCity = 'Fake City';
        acc.BillingState = 'London';
        acc.BillingPostalCode = '123'; 
        acc.BillingCountry = 'GB';
        insert acc;
            
        // new contact
        Contact con=new Contact();
        con.LastName='TestContact';
        con.AccountId=acc.Id;
        con.Fax='1234567';
        con.Email='Test@test.com';
        con.MobilePhone='1346975';
    
        insert con;
    
            Product2 prod = new Product2(
                Name='ApexTestProd',
                IsActive=true);
            insert prod;
    
            Pricebook2 pb = [select Id from Pricebook2 where IsStandard=true limit 1];
    
            PricebookEntry pbe = new PricebookEntry(
                UseStandardPrice=false,
                Product2Id=prod.Id,
                Pricebook2Id=pb.Id,
                UnitPrice=1.00,
                IsActive=true);
            insert pbe;
    
            Opportunity opp = new Opportunity(
                Name='Test Opp',
                Probability=100,
                StageName='Contract',
                CloseDate=System.today(),
                 Payment_Method__c='Direct Debit',
                //Start_of_Campaign__c=System.today(),
                //End_of_Campaign__c=System.today(),
                Pricebook2Id=pb.Id);
            insert opp;
            WSInsertMandate.insertMandate(opp.Id,'OPP');
             WSInsertMandate.insertMandate(opp.Id,'MAN');
     }
}