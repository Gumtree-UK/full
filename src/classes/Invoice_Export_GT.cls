public with sharing class Invoice_Export_GT {
	
	InvoicesSent__c [] Invoices;
	public static string output = '';

	public List<string> getInvoices(){
    	string InvId = ApexPages.CurrentPage().getParameters().get('InvId');
    	if(Invoices == null){
                        Invoices = [ SELECT
										Account_Number_Fiqas__c,
										Fiqas_Product_type__c,
										Fiqas_Product_Subtype__c,
										Fiqas_Product_Code__c,
										Fiqas_Invoice_Description__c ,
										Unit_Label__c,
										Invoice_Quantity__c,
										Sales_Price__c ,
										Invoice_Amount__c ,
										Fiqas_VAT_Percentage__c,
										Apply_VAT__c,
										Amount_Paid__c,
										from_Date__c,
										until_Date__c,
										Fiqas_Start_Date__c,
										Fiqas_End_Date__c,
										Opportunity__c,
										InvoiceExtra1__c,
										InvoiceExtra2__c,
										InvoiceExtra3__c,
										InvoiceExtra4__c,
										InvoiceLineExtra1__c,
										InvoiceLineExtra2__c,
										InvoiceLineExtra3__c,
										IONumber__c
									FROM InvoicesSent__c
									WHERE InvID__c = :InvId
									];
		} 

		list<string> InvExp = new  list<string>();
        for (InvoicesSent__c Inv: Invoices){
        	InvExp.add(getTemp(Inv));
		}
        return InvExp;
	}
	
	public static String ReplaceNull(String input){
	 	output = input;
	 	if (input==null){
	 		output = '';
	 	}
 		return output;
 	} 
 	
	public String NewLine{
        get { return '\r'; }
        set;
    }

	public decimal getTotalAmount(){
    	decimal total = 0;
	    for(InvoicesSent__c Inv: Invoices) {
	        if (Inv.Invoice_Amount__c != null) {  
	            total += Inv.Invoice_Amount__c;
	        }
	    }   
	    return total;
    }

	String LongDate = ' ';

	// Init cLongDate with the current Datetime in long date format    
 	public String getLongDate() {
	    Datetime cDT = System.now();
	    LongDate = cDT.format('yyyyMMd');
	    return LongDate;
	}

	public String getTemp(InvoicesSent__c Inv){
	 	String Temp = '';
	 	Temp = 	'00000002~'+ 												//Recordtype
				Inv.Account_Number_Fiqas__c.trim() + '~' +					//Customer ID
				ReplaceNull(Inv.Fiqas_Product_type__c).trim() + '~' +		//'Marktplaats Daily Deals~'+ 		//Product Type
				ReplaceNull(Inv.Fiqas_Product_Subtype__c).trim() + '~' +	//productsubType
				ReplaceNull(Inv.Fiqas_product_code__c).trim() + '~' +		//Marktplaats Daily Deals 			//ProductCode
				ReplaceNull(Inv.IONumber__c).trim() + '~' +                 //Reference
				ReplaceNull(Inv.Fiqas_Invoice_Description__c).trim() + '~' +//Description 
				ReplaceNull(Inv.Unit_Label__c).trim()+ '~' + 				//Unitlabel
				ReplaceNull(string.valueOf(Inv.Invoice_Quantity__c)) + '~' +				//Vouchers_Redeemed__c				//Unitcount
				ReplaceNull(string.valueOf(Inv.Sales_Price__c)) + '~' +						//Deal_Discount_Price__c			//Unitprice
				ReplaceNull(string.valueOf(Inv.Invoice_Amount__c)) + '~' +					//Deal_Total_Amount_Net__c			//Amount
				ReplaceNull(string.valueOf(Inv.Fiqas_VAT_Percentage__c)) + '~' +			//Deal_VAT_Rate__c					//VATPercentage
				ReplaceNull(Inv.Apply_VAT__c) + '~' +						//VAT_Type__c						
				ReplaceNull(string.valueOf(Inv.Amount_Paid__c)) + '~' +						//AmountPaid
				ReplaceNull(Inv.Fiqas_Start_Date__c).trim()+'~'+			//StartDate
				ReplaceNull(Inv.Fiqas_End_Date__c).trim()+'~'+				//EndDate
				Inv.Opportunity__c + '~' +									//IndividualInvoice
				ReplaceNull(Inv.InvoiceExtra1__c).trim() + '~' +			//InvoiceExtra1
				ReplaceNull(Inv.InvoiceExtra2__c).trim() + '~' +			//InvoiceExtra2
				ReplaceNull(Inv.InvoiceExtra3__c).trim() + '~' +			//InvoiceExtra3
				ReplaceNull(Inv.InvoiceExtra4__c).trim() + '~' +			//InvoiceExtra4
				'~' +														//InvoiceExtra5
				'~' +														//InvoiceLineExtra1
				ReplaceNull(Inv.InvoiceLineExtra2__c).trim() + '~' +		//InvoiceLineExtra2
				'~' +														//InvoiceLineExtra3
				'~' +														//InvoiceLineExtra4
				'~' + NewLine ;												//InvoiceLineExtra5
		return Temp;
	}

	public static TestMethod void testInvoice_Export(){
        // Insert Inv TODO: assign values
        InvoicesSent__c Inv = new InvoicesSent__c(
        			Account_Number_Fiqas__c = 'TEST20000',
                      Fiqas_Product_type__c = 'Gumtree Daily Deals',
                      Fiqas_Product_Subtype__c = '',
                      Fiqas_Product_Code__c = 'Gumtree Daily Deals',
                      Fiqas_Invoice_Description__c = 'Test Daily Deal',
                      Unit_Label__c = '',
                      IONumber__c = '123',
                      Invoice_Quantity__c = 10,
                      Sales_Price__c = 100,
                      Invoice_Amount__c = 1000,
                      Fiqas_VAT_Percentage__c = 0,
                      Amount_Paid__c = 0,
                      from_Date__c = date.today(),
                      until_Date__c =  date.today(),
                      Fiqas_Start_Date__c = '20110901',
                      Fiqas_End_Date__c = '20110930',
                      InvoiceExtra1__c = 'GB',
					  InvoiceExtra3__c = '',
					  InvoiceExtra4__c = '',
					  InvoiceLineExtra2__c = ''
		);
        insert Inv;
        ApexPages.StandardController sc = new Apexpages.StandardController(Inv);
        
        // String pageName = 'IO_Display_inc_VAT';
        Invoice_Export_GT IE = new Invoice_Export_GT();
        IE.getLongDate();
		IE.getInvoices();
        IE.getTotalAmount();
    }
}