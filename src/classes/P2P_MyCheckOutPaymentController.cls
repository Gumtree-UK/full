/**
 * Task #4523: My checkout payment
 * @author: SP
 * @createdDate: 19-Dec-2014
 */
public class P2P_MyCheckOutPaymentController {
        
        public Integer numberItems {get;set;}
        public List<BasketRow> lstBasketRows {get;set;}
        public List<SelectOption> lstCustomDuration {get;set;}
        public Decimal totalVat {get;set;}
        public Decimal totalSub {get;set;}
        public Decimal totalPromo {get;set;}
        public Decimal totalPrice {get;set;}
        public String promoCode {get;set;}
        public Boolean showPromoCode {get;set;}
        public String errorPromoCode {get;set;}
        public String successPromoCode {get;set;}
        public Boolean displayStatusPromoCode {get;set;}
        public Integer indexProGroupSel {get;set;}
        public Integer indexSubPro {get;set;}
        public Boolean hasError {get;set;}
        public String invoiceBillingFrequency {get;set;}
               
        public String accId{get;set;}
        public P2P_MyCheckOutPaymentController(){
                init();
        }
        
        private void init(){
                //get media basket
                requestToken();                
                accId = Apexpages.currentPage().getParameters().get('id');
                if(String.isEmpty(accId)) accId = P2P_Utils.retrieveCommunityAccountId();
                numberItems = 0;
                totalSub = 0;
                displayStatusPromoCode = false;
                showPromoCode = false;
                totalVat = 0;
                totalPromo = 0;
                totalPrice = 0;
                hasError = false;
                invoiceBillingFrequency = '';
                if(String.isEmpty(accId)) return;
                
                
                //get related Media Basket From Account
                List<Media_Basket__c> lstMBs = [Select VAT__c, Promo_code__c, Net_Net_Net_inc_VAT__c, Gross__c, Sales_Price_Target__c, Id, Product_Group_Name__c, Quantity__c, PriceBookEntryIdText__c, 
                                                        Product_ID__c, until_Date__c, from_Date__c, Length_Months__c, Location__c, Net_Net_Net__c, OpportunityLineItemId__c, 
                                                        Payment_Method__c,  BillingFrequency__c, Feed_setup__c, Rate_Discount_II__c, Discount_reason__c 
                                                From Media_Basket__c Where Account_Id__c =: accId];
                numberItems = lstMBs.size();
                
                Map<String, List<Media_Basket__c>> mapProGroups = new Map<String, List<Media_Basket__c>>();
                Set<ID> proIds = new Set<ID>();
                
                //put Media Basket in map group, key product group
                for(Media_Basket__c mb : lstMBs){
                        if(!mapProGroups.containsKey(mb.Product_Group_Name__c)){
                                mapProGroups.put(mb.Product_Group_Name__c, new List<Media_Basket__c>());
                        }
                        mapProGroups.get(mb.Product_Group_Name__c).add(mb);
                        proIds.add(mb.Product_ID__c);
                }
                
                //get related products
                Map<ID, Product2> mapProducts = new Map<ID, Product2>([Select Rate_Card__c, Quantity__c, Id, Feed_setup__c From Product2 Where Id in: proIds]);
                
                //generate list basket row
                lstBasketRows = new List<BasketRow>();
                Integer i = 0;
                Decimal totalNet = 0;
                Decimal vatPrice = 0;
                for(String advName: mapProGroups.keySet()){
                        BasketRow br = new BasketRow(i, false, '', advName, '', '');
                        i++;
                        for(Media_Basket__c mb: mapProGroups.get(advName)){
                                Boolean isRateCard = mapProducts.containsKey(mb.Product_ID__c) ? mapProducts.get(mb.Product_ID__c).Rate_Card__c : false;
                                Boolean isEnableQTY = mapProducts.containsKey(mb.Product_ID__c) ? mapProducts.get(mb.Product_ID__c).Quantity__c == null || mapProducts.get(mb.Product_ID__c).Quantity__c <= 0 : false;
                                Boolean isFeedSetup = mapProducts.containsKey(mb.Product_ID__c) ? mapProducts.get(mb.Product_ID__c).Feed_setup__c : false;
                                System.debug('================Gross__c=' + mb.Gross__c);
                                totalSub += mb.Gross__c == null ? 0: mb.Gross__c;
                                System.debug('================totalSub=' + totalSub);
                                totalPrice += mb.Net_Net_Net_inc_VAT__c;
                                totalNet += mb.Net_Net_Net__c;
                                vatPrice = mb.VAT__c == null || mb.VAT__c == 0? vatPrice: mb.VAT__c;//The VAT will always be the same across each media basket.
                                
                                BasketItem bi = new BasketItem(br.basketItems.size(), mb, mb.Sales_Price_Target__c, isRateCard, isEnableQTY, isFeedSetup);
                                br.basketItems.add(bi);
                        }
                        
                        lstBasketRows.add(br);
                }
                totalVat = totalNet * (vatPrice/100);
                lstCustomDuration = P2P_MyCheckoutController.getProductDuration();
                
        }
        
        /**
        * Method to
        * - re-calculate End Date, Price when start date and Qty changed
        * - re-calculate Total VAT and Price
        * - update Media Basket
        */
        public Pagereference reCalculateAndUpdateMedia(){
                BasketRow proGroupSelected = lstBasketRows.get(indexProGroupSel);
                BasketItem subProSelected = proGroupSelected.basketItems.get(indexSubPro);
                proGroupSelected.errorMsg = '';
                
                Decimal unitprice = subProSelected.unitPrice == null ? 0: subProSelected.unitPrice;
                Decimal qty = subProSelected.mb.Quantity__c == null? 0 : subProSelected.mb.Quantity__c;
                
                //get related Rate Card for Unitprice to calculate
                if(subProSelected.isRateCard){
                        List<Rate_Card__c> lstRateCards = [Select Sales_Price__c, Id  
                                                                From Rate_Card__c 
                                                                Where Quantity2__c <=: subProSelected.mb.Quantity__c
                                                                        AND Product__c =: subProSelected.mb.Product_ID__c
                                                                        AND Length__c =: String.valueOf(Integer.valueOf(subProSelected.mb.Length_Months__c))
                                                                        AND Active__c = true order by Quantity2__c desc limit 1];
                                                                                                                
                        if(!lstRateCards.isEmpty()){
                                unitprice = lstRateCards.get(0).Sales_Price__c;
                        }
                }
                subProSelected.mb.from_Date__c = Date.parse(subProSelected.startDate);
                
                //update end date when start date changed
                hasError = false;
                if(subProSelected.mb.from_Date__c < system.today() || subProSelected.mb.from_Date__c == null){
                        proGroupSelected.errorMsg = 'Start date cannot empty/less than today.';
                        subProSelected.mb.from_Date__c.addError(' ');
                        hasError = true;
                }
                
                //update Media Basket
                Date endDate = P2P_MyCheckoutController.calculateEndDate(subProSelected.mb.from_Date__c, Integer.valueOf(subProSelected.mb.Length_Months__c));
                subProSelected.mb.until_Date__c = endDate == null ? subProSelected.mb.until_Date__c : endDate;
                subProSelected.mb.Sales_Price_Target__c = unitprice;
                subProSelected.mb.Gross__c = unitprice * qty;
                subProSelected.mb.Net_Net_Net__c = unitprice * qty;
                subProSelected.isChangedData = true;
                
                if(!isValidated()){
                        hasError = true;
                        return null;    
                }
                
                update subProSelected.mb;
                
                reCalculateVATandPRICE();
                return null;
        }
        
        /**
        * Method to check required fields before update
        */
        private Boolean isValidated(){
                Boolean noError = true;
                
                for(BasketRow br: lstBasketRows){
                        Boolean isError = false;
                        
                        for(BasketItem bi: br.basketItems){
                                if(!bi.isChangedData) continue;
                                
                                if(bi.mb.Quantity__c == null || bi.mb.Quantity__c <= 0){
                                        bi.mb.Quantity__c.addError(' ');
                                        isError = true;
                                }
                                if(bi.mb.from_Date__c == null || bi.mb.from_Date__c < System.today()){
                                        bi.mb.from_Date__c.addError(' ');
                                        isError = true;
                                }
                                if(bi.mb.Length_Months__c == null || bi.mb.Length_Months__c <= 0){
                                        bi.mb.Length_Months__c.addError(' ');
                                        isError = true;
                                }
                        }
                        
                        if(isError){
                                br.errorMsg = 'Please specify your quantity, start date and duration';
                                noError = false;
                        }
                }
                
                return noError;
        }
        
        
        /**
        * Update MediaBasket when Feed Setup is changed
        */
        public Pagereference feedSetupUpdateMB(){
                BasketRow proGroupSelected = lstBasketRows.get(indexProGroupSel);
                BasketItem subProSelected = proGroupSelected.basketItems.get(indexSubPro);
                
                Boolean curFeedSetup = subProSelected.mb.Feed_setup__c;
                subProSelected.mb.Feed_setup__c = !curFeedSetup;
                
                update subProSelected.mb;
                return null;
        }
        
        /**
        * Method remove MediaBasket
        */
        public Pagereference removeMediabasket(){
                BasketRow proGroupSelected = lstBasketRows.get(indexProGroupSel);
                BasketItem subProSelected = proGroupSelected.basketItems.get(indexSubPro);
                String mbId = subProSelected.mb.Id;
                proGroupSelected.basketItems.remove(indexSubPro);
                
                delete [Select Id From Media_Basket__c Where Id=:mbId];
                
                //prepare list index again
                Integer i = 0;
                for(BasketItem bi: proGroupSelected.basketItems){
                        bi.index = i;
                        i++;
                }
                numberItems--;
                reCalculateVATandPRICE();
                return null; 
        }
        
        /**
        * Method Pay by Card
        */
        public Pagereference doPayByCard(){
            
                List<Media_Basket__c> lstMBUpdates = new List<Media_Basket__c>();
                for(BasketRow br: lstBasketRows){
                        
                        for(BasketItem bi: br.basketItems){
                                bi.mb.Payment_Method__c = 'Credit/Debit Card';
                                bi.mb.BillingFrequency__c = 'Up-front';
                                lstMBUpdates.add(bi.mb);
                        }
                }
                
                if(!lstMBUpdates.isEmpty()){
                        update lstMBUpdates;
                }
                //==== kakada ======
                lstBV = [Select Payment_Type_value__c, PaymentType__c,PaymentToken__c,Masked_card_number__c,Paypal_Email__c From Braintree_Vault__c where status__c = 'active' and Account__c =:accid and PayPal_email__c = null]; 
                
                return null;
        }
        
        /**
        * Method Pay by Invoice
        */
        public Pagereference doPayByInvoice(){
                List<Media_Basket__c> lstMBUpdates = new List<Media_Basket__c>();
                for(BasketRow br: lstBasketRows){
                        
                        for(BasketItem bi: br.basketItems){
                                bi.mb.Payment_Method__c = 'Invoice';
                                bi.mb.BillingFrequency__c = invoiceBillingFrequency;
                                bi.mb.Stage__c = 'Booking';
                                lstMBUpdates.add(bi.mb);
                        }
                }
                
                if(!lstMBUpdates.isEmpty()){
                        update lstMBUpdates;
                }
                return null;
        }
        
        /**
        * Method Pay by Paypal
        */
        public Pagereference doPayByPaypal(){
                List<Media_Basket__c> lstMBUpdates = new List<Media_Basket__c>();
                for(BasketRow br: lstBasketRows){
                        
                        for(BasketItem bi: br.basketItems){
                                bi.mb.Payment_Method__c = 'PayPal';
                                bi.mb.BillingFrequency__c = 'Upfront';
                                
                                lstMBUpdates.add(bi.mb);
                        }
                }
                 
                if(!lstMBUpdates.isEmpty()){
                        update lstMBUpdates;
                }
                
                //======= kakada =======
                lstBV = [Select Payment_Type_value__c, PaymentType__c,PaymentToken__c,Masked_card_number__c,Paypal_Email__c From Braintree_Vault__c where status__c = 'active' and Account__c =:accid and PayPal_email__c !=null];
                
                
                return null;
        }
        
        
        /**
        * Method to recalculate Total VAT and Total Price
        */
        private void reCalculateVATandPRICE(){
                totalSub = 0;
                totalPrice = 0;
                totalVat = 0;
                Decimal vatPrice = 0;
                Decimal totalNet = 0;
                for(BasketRow br: lstBasketRows){
                        
                        for(BasketItem bi: br.basketItems){
                                totalPrice += bi.mb.Net_Net_Net__c + (bi.mb.Net_Net_Net__c * (bi.mb.VAT__c/100));
                                totalSub += bi.mb.Gross__c == null? 0 : bi.mb.Gross__c;
                                totalNet += bi.mb.Net_Net_Net__c;
                                vatPrice = bi.mb.VAT__c == null || bi.mb.VAT__c == 0? vatPrice: bi.mb.VAT__c;//The VAT will always be the same across each media basket.
                        }
                }
                totalVat = totalNet * (vatPrice / 100);
                
        }
        
        /**
        * Method to validate Voucher_code__c (Promo Code)
        */
        public Pagereference validatePromoCode(){
            displayStatusPromoCode = true;
            errorPromoCode = '';
            successPromoCode = '';
            
            //check if it is empty promo code
            If(String.isEmpty(promoCode)){
                errorPromoCode = 'Please input Promo Code.';
                return null;
            }
            
            //Check if Promo Code is related Account and match condition
            // - Promo_code__c.Voucher_code__c is found related to the Promo_code__c.Account__c
            // - Promo_code__c.Vouchers_remaining__c > 0
            // - Promo_code__c.Voucher_expiry__c >= TODAY()) 
            
            List<Promo_Code__c> lstPromoCodes = [Select Id, Value__c, Promo_code_type__c, Voucher_code__c, Voucher_expiry__c, Discount_type__c, Specific_product__r.Name,
                                                        Specific_product__c, Voucher_redeemed__c, Vouchers_redeemed__c, Minimum_package_value__c,
                                                        Promo_code_reason__c        
                                                    From Promo_Code__c 
                                                    Where Vouchers_remaining__c > 0 
                                                        AND Voucher_expiry__c >= TODAY
                                                        AND Voucher_code__c =: promoCode
                                                        AND Account__c =: accId];
            
            //If Promo Code is not found, display error message                                         
            if(lstPromoCodes.isEmpty()){
                errorPromoCode = 'Unfortunately your code is no longer valid';
                return null;
            }
            
            //the below is business logic if Promo Code is found
            
            //Point 4.7.2.3 - Minimum package value to unlock discount (optional)
            if(lstPromoCodes.get(0).Minimum_package_value__c > totalSub){
                errorPromoCode = 'Unfortunately you have not met the minimum package value, you will need to spend more than ?' + lstPromoCodes.get(0).Minimum_package_value__c + ' to receive the discount';
                return null;
            }
            
            
            Boolean promoCodeIsProduct = lstPromoCodes.get(0).Promo_code_type__c == 'Product';
            Boolean isFixAmount = lstPromoCodes.get(0).Discount_type__c == 'Fixed amount';
            
            //check if it is specific product and it doesnt have product
            if(promoCodeIsProduct && lstPromoCodes.get(0).Specific_product__c == null){
                errorPromoCode = 'Unfortunately your code is no longer valid';
                return null;
            }
            
            
            //If Discount Type = Fixed Amount, Value__c will present as Amount. If Not, it will present as percent.
            //If Promo Code Type is Product, we will take the whole Price to calculate with specific product
            
            //If Promo Code Type is Package and Discount Type is Fixed Amount, Each product should be discounted by an even amount for the total to equal the Value__c. 
            //ie. If Value__c = 200 and 4 records in cart then each record should receive the same discount amount to equal to the total value, in this case ?50 per record.
            
            //If Promo Code Type is Package and Discount Type is Fixed Percent, Each product should be discounted by the Value__c as a percentage.
            //Ie. If Value__c = 10 and 4 records in cart then each record should receive a 10% discount.
            Decimal discountPriceAmount = promoCodeIsProduct ? lstPromoCodes.get(0).Value__c : (lstPromoCodes.get(0).Value__c / Decimal.valueOf(numberItems));
            Decimal discountPricePercent = lstPromoCodes.get(0).Value__c / 100;
            
            Set<Id> productId = new Set<Id>{lstPromoCodes.get(0).Specific_product__c};
            String specificProName = lstPromoCodes.get(0).Specific_product__r.Name;
            
            List<Media_Basket__c> lstMB2Update = new List<Media_Basket__c>();
            Boolean codeApplied = false;
            
            for(BasketRow br: lstBasketRows){
                for(BasketItem bi: br.basketItems){
                    
                    //- Add Promo_code__c.id to Media_Basket__c.Promo_code__c field
                    //- Add Promo_code__c.id to OpportunityLineItem.Promo_code__c field --> Trigger will handle this point
                    bi.mb.Promo_code__c = lstPromoCodes.get(0).Id;
                     
                    //If Promo Code Type = Product, only the Specific_Product__c should receive the discount equal to the Value__c.
                    if(promoCodeIsProduct && productId.contains(bi.mb.Product_ID__c)){
                        Decimal discountPrice = isFixAmount ? discountPriceAmount : (bi.mb.Gross__c * discountPricePercent);
                        Decimal priceAfterDiscount = bi.mb.Gross__c - discountPrice;
                        Decimal rateDiscountII = isFixAmount ? ((discountPriceAmount * 100) / bi.mb.Gross__c) : (discountPricePercent * 100); //this field will get only percent value
                        
                        bi.mb.Net_Net_Net__c = priceAfterDiscount;
                        bi.mb.Rate_Discount_II__c = rateDiscountII;
                        bi.mb.Discount_reason__c = lstPromoCodes.get(0).Promo_code_reason__c;
                        totalPromo += discountPrice;
                        codeApplied = true;
                    }
                    
                    //If Promo Code Type = Package, the discount will relate to all products within that media basket
                    if(!promoCodeIsProduct){
                        Decimal discountPrice = isFixAmount ? discountPriceAmount : (bi.mb.Gross__c * discountPricePercent);
                        Decimal priceAfterDiscount = bi.mb.Gross__c - discountPrice;
                        Decimal rateDiscountII = isFixAmount ? ((discountPriceAmount * 100) / bi.mb.Gross__c) : (discountPricePercent * 100); //this field will get only percent value
                        
                        bi.mb.Net_Net_Net__c = priceAfterDiscount;
                        bi.mb.Rate_Discount_II__c = rateDiscountII;
                        bi.mb.Discount_reason__c = lstPromoCodes.get(0).Promo_code_reason__c;
                        totalPromo += discountPrice;
                        codeApplied = true;
                    }
                    
                    lstMB2Update.add(bi.mb);
                }
            }
            
            //- Promo code should not be accepted if there is no discount to attribute. 
            //ie. In this example, the promo code relates to a standard job ads (rouk) product which is not being purchased 
            //therefore we should show an error message saying 'The promo code is not valid for this product, please add 'Product2.Name' to receive your discount.'
            if(!codeApplied){
                errorPromoCode = 'The promo code is not valid for this product, please add "' + specificProName + '" to receive your discount.';
                return null;
            }
            
            showPromoCode = true;
            if(!lstMB2Update.isEmpty()){
                update lstMB2Update;
            }
            
            //- Display message to customer (example below);
            //Promo_code_type__c && ? Discount? && ?- Save? && Value__c && ?-? Voucher_code__c ?- Expiry? && Voucher_expiry__c && ?- ACCEPTED?
            successPromoCode = lstPromoCodes.get(0).Promo_code_type__c + ' Discount - Save ?' + lstPromoCodes.get(0).Value__c + ' - ' + lstPromoCodes.get(0).Voucher_code__c + ' - Expiry ' + lstPromoCodes.get(0).Voucher_expiry__c + ' - ';
            reCalculateVATandPRICE();
            
            //When a customer successfully uses a promo code we should update the following fields on the Promo_code__c record;
            //- Voucher_redeemed__c = Date.Now()  (overwrite previous date each time)
            //- Vouchers_redeemed__c = Count + 1 (each time the code is used on site)
            lstPromoCodes.get(0).Voucher_redeemed__c = System.now();
            lstPromoCodes.get(0).Vouchers_redeemed__c = lstPromoCodes.get(0).Vouchers_redeemed__c == null ? 1 : lstPromoCodes.get(0).Vouchers_redeemed__c + 1;
            update lstPromoCodes;
            
            return null;
        }
        
         
        public class BasketRow {
                public Integer index {get;set;}
                public String productGroupId {get;set;}
                public String productGroupName {get;set;}
                public String productGroupDesc {get;set;}
                public Boolean selected { get; set; }
                public List<BasketItem> basketItems{ get; set;}
                public String pricebookEntryId {get;set;}
                public Boolean isChangedData {get;set;}
                public Boolean isPopulate {get;set;}
                public String errorMsg {get;set;}
                
                public BasketRow(Integer index, Boolean isSelected, String pid, String pname, String pdesc, String pricebookEntryId){
                        this.selected = isSelected;
                        this.productGroupId = pid;
                        this.productGroupName = pname;
                        this.productGroupDesc = pdesc;
                        this.pricebookEntryId = pricebookEntryId;
                        this.basketItems = new List<BasketItem>();
                        this.index = index;
                        this.isChangedData = false;
                        this.isPopulate = false;
                }
                
                 
        }
        
        public class BasketItem { 
                public Media_Basket__c mb {get;set;}
                public Integer index {get;set;}
                public Boolean isEnableQty {get;set;}
                public Decimal unitPrice {get;set;}
                public Boolean isRateCard {get;set;}
                public Boolean isChangedData {get;set;}
                public Boolean isFeedSetup {get;set;}
                public String startDate {get;set;}
                
                public BasketItem(Integer i, Media_Basket__c mb, Decimal unitPrice, Boolean isRateCard, Boolean isEnableQty, Boolean isFeedSetup){
                        this.index = i;
                        this.mb = mb;
                        this.unitPrice = unitPrice;
                        this.isEnableQty = isEnableQty ;
                        this.isRateCard = isRateCard;
                        this.isChangedData = false;
                        this.isFeedSetup = isFeedSetup;
                        this.startDate = P2P_Utils.dateToStringWithFormat(mb.from_Date__c, 'dd/MM/yyyy');
                }
                
        }
     
        //====== kakada Task #4829========
        public List<Braintree_Vault__c> lstBV{get;set;}
        public String paymentId{get;set;}
        public boolean isErrorTrans{get;set;}
	    public String errorMsg{get;set;}
	    private static String GUMTREE = 'Gumtree';
	    private static String CURRENCY_CODE = 'GBP';
	    public String client_token{get;set;}
	    public String methodnonce{get;set;}
	    public String paypal_email{get;set;}
	    public String selectPaypal{get;set;}
	    private decimal amount;
	    
	    /**
	     * Create transaction to Braintree.
	     */
	    public PageReference doTransaction(){
	    	String pref = getPaymentRef();
	        Braintree_Vault__c bv = [Select PaymentToken__c, Payment_Type_Value__c, Account__c from Braintree_Vault__c where id =:paymentId];
	        Fiqas_Settings__c FS = Fiqas_Settings__c.getInstance('Braintree_Webservice');
	        P2P_tempuriOrg.BasicHttpBinding_IBrainTreeCollectionService service = new P2P_tempuriOrg.BasicHttpBinding_IBrainTreeCollectionService ();
	        service.timeout_x = P2P_BraintreeServices.REQUEST_TIMEOUT;
	        String token = service.Login(FS.User__c,FS.Key__c);
	        P2P_schemasDatacontractOrg.BrainTreeCollectionServiceResult result = service.InitiatePayment(token, GUMTREE, bv.PaymentToken__c, amount, CURRENCY_CODE, pref);
	        errorMsg = result.Message;
	        isErrorTrans = !(result.Succes);
	        System.debug('Trans result>>>>>>>>'+result.Message);
	        System.debug('result.Succes>>>>>>>>'+result.Succes);
	        
	        //Update invoice
	        if(result.Succes){
	            //successTransaction(lstInvs,bv);
	        }
	      
	      return null;
	    }  

        /**
         * Delete payment method
         * @param token is the payment token to be delete at braintree
         */
        public PageReference doDeletePayment(){
            P2P_BraintreeServices btServices = new P2P_BraintreeServices();
            Braintree_Vault__c bv = [Select Id,PaymentToken__c, Status__c from Braintree_Vault__c where id =:paymentId];
            P2P_BraintreeServices.CreditCartParser ccParser = btServices.deleteCreditCard(bv.PaymentToken__c);
            bv.Status__c = 'inactive';
            update bv;
            return null;
        }
        
        /**
       	 * Update the invoice object
         */
		/*private void successTransaction(List<InvoiceItem> inItem,Braintree_Vault__c bv){
			List<Invoices__c> lstInv = new List<Invoices__c>();
			for(InvoiceItem i : inItem){
		        i.invoice.Payment_Method__c = bv.Payment_Type_Value__c + ' - Online';
		        i.invoice.Braintree_Vault__c = bv.id;
		        //i.invoice.Amount_Paid__c = i.invoice.Invoice_Amount__c;
		        lstInv.add(i.invoice);
	     	}
			update lstInv;
		}*/
        
		/**
	     * get client token from braintree server
	     */
		public void requestToken(){
			P2P_BraintreeServices btServices = new P2P_BraintreeServices();   	
			P2P_BraintreeServices.ClientTokenParser ctParser = btServices.getClientToken();
			client_token = ctParser.clientToken;
		}
        
        /**
         * Create payment with paypal
         */
		public PageReference createPaymentPaypal(){      	
		  	P2P_BraintreeServices btServices = new P2P_BraintreeServices();
		  	Boolean isInsertBV = true;
		  	
			//Braintree_Customer_ID__c, BraintreeActiveFrom__c, EncryptedBTCustToken__c
		    Account acc = [ Select  Id, Name, Finance_contact__r.Email, Finance_contact__r.Phone From Account Where Id = :accId];
		    
		    // Second request (Create a customer) when the button clicked
		    P2P_BraintreeServices.CustomerParser cuParser = btServices.createCustomer(methodnonce, '', acc, false);              
		    String paymentToken = cuParser.defaultPaymentMethodToken;
		    Boolean def = cuParser.defaultToken;
	        
	        if(cuParser.isError){
	            // if Creating a customer fail, create a new payment method
	            P2P_BraintreeServices.CreditCartParser ccParser = btServices.createCreditCard(methodnonce, '', acc.id, false);              
	            paymentToken = ccParser.token; 
	        	def = ccParser.defaultToken;
	        	isInsertBV = !ccParser.isError;
	        }
	        if(isInsertBV){
	        	Braintree_Vault__c bv = new Braintree_Vault__c();
		      	bv.Payment_Type_Value__c = 'PayPal';
		      	bv.Account__c = accId;
		      	bv.PaymentToken__c = paymentToken;
		      	bv.DefaultToken__c = def;
		      	bv.PayPal_email__c = paypal_email;
			    insert bv;
			    selectPaypal = bv.id;
			    lstBV = [Select Payment_Type_value__c, PaymentType__c,PaymentToken__c,Masked_card_number__c,Paypal_Email__c From Braintree_Vault__c where status__c = 'active' and Account__c =:accId /*'0011100000bN9SOAA0'*/ and PayPal_email__c !=null];
	        }
	        return null;
		}
        /**
         * Get payment referrence format as
         * GT141100194~GT141000208~GT140900196
         */
		private String getPaymentRef(){
			Media_Basket__c MB = [Select OpportunityId__c From Media_Basket__c Where Account_Id__c =: accId Limit 1];
			System.debug('Opp>>>>>>'+MB.OpportunityId__c);
			Opportunity op = [Select Amount_Net_Net_Inc_VAT__c From Opportunity where Id =:MB.OpportunityId__c];
			amount = op.Amount_Net_Net_Inc_VAT__c;
			
    		return MB.OpportunityId__c+'';
		}

        //======End Task #4829 =====
        
          
}