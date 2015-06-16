public with sharing class PaginationExt_GT_Test {
    static testMethod void myPage_Test()

    {

FiqasUIBatchInvoiceInsert_GT myPageConParent = new FiqasUIBatchInvoiceInsert_GT();
PaginationExt_GT myPageCon = new PaginationExt_GT(myPageConParent);

myPageCon.getPageSize();
myPageCon.getPreviousButtonEnabled();
myPageCon.getNextButtonDisabled();
myPageCon.getTotalPageNumber();
myPageCon.BindData(1);

    }
}