public virtual class PaginationExt_GT {
	
	public list<InvoicesSent__c> pageInvoicesList;
	public Integer pageSize;
	public Integer totalPageNumber;
	public FiqasUIBatchInvoiceInsert_GT controller;  
	
	public Integer getPageSize() {
	    return pageSize;
	}
	
	public Boolean getPreviousButtonEnabled() {
		return !(controller.pageNumber > 1);
	}
	
	public Boolean getNextButtonDisabled() {
		if (controller.InvoicesList == null) {
			return true;
		} 
		else {
			return ((controller.pageNumber * pageSize) >= controller.InvoicesList.size());
		}
	}
	
	public Integer getTotalPageNumber() {
		if (controller.InvoicesList !=null) {
			totalPageNumber = controller.InvoicesList.size() / pageSize;
			Integer mod = controller.InvoicesList.size() - (totalPageNumber * pageSize);
			if (mod > 0) totalPageNumber++;
		}
		return totalPageNumber;
	}
	
	// Constructor
	public PaginationExt_GT(FiqasUIBatchInvoiceInsert_GT controller) 	{
	    this.controller = controller;
		totalPageNumber = 1;
		pageSize = 200;
	}
	
	public list<InvoicesSent__c> BindData(integer newPageIndex) {
	try {
		pageInvoicesList = new List<InvoicesSent__c>();
		Transient Integer counter = 0;
		Transient Integer min = 0;
		Transient Integer max = 0;
		
		if (newPageIndex > controller.pageNumber) {
			min = controller.pageNumber * pageSize;
			max = newPageIndex * pageSize;
		}
		else {
			max = newPageIndex * pageSize;
			min = max - pageSize;
		}
		for(InvoicesSent__c a : controller.InvoicesList) {
			counter++;
			if (counter > min && counter <= max) {
				pageInvoicesList.add(a);
			}
		}
		
		if (pageInvoicesList == null || pageInvoicesList.size() <= 0) {
			//ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'There are no invoices to display.'));
		}
	}
	catch(Exception ex) {
		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,ex.getMessage()));
	}
	
	return pageInvoicesList;
    }
	
}