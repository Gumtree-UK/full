/*
Trigger to send accounts to the Fiqas.nl Abillity Web system for billing
*/
trigger Fiqas_Trigger on Account (after insert, after update) {

    system.debug('Fiqas_Trigger: Running...');
    string[] todo = new string[]{};

    if (Trigger.isInsert) {        
        for ( Account newa: Trigger.new) { 
            system.debug('Fiqas_Trigger: Deciding whether to insert account ' + newa.id);
            String fiqasAccountNumber = newa.Account_Number_Fiqas__c;
            if ((newa.RecordTypeId == '01220000000YZvhAAG' || newa.RecordTypeId == '01220000000Y83eAAC'
                    || newa.RecordTypeId == '01220000000YDN3AAO' || newa.RecordTypeId == '01220000000Y83jAAC'
                    || newa.RecordTypeId == '012200000005MbLAAU' || newa.RecordTypeId == '01220000000DisxAAC'
                    || newa.RecordTypeId == '01220000000Q8xSAAS' || newa.RecordTypeId == '012w0000000QA3AAAW'
                    || newa.RecordTypeId == '01220000000DqONAA0' || newa.RecordTypeId == '012200000002LlMAAU') 
                    && newa.BillingStreet != null
                    && newa.BillingCity != null
                    && newa.BillingPostalCode != null
                    && newa.BillingCountry != null
                    && newa.Finance_contact__c != null
                    && fiqasAccountNumber != null
                    && fiqasAccountNumber.length() >= 12) {
                Contact newFinanceContact = [SELECT Id, FirstName, LastName, Email, Phone
                        FROM Contact where ID = :newa.Finance_contact__c];
                if (newFinanceContact.LastName != null)
                {  
                    todo.add((string)newa.id);            
                }
            }        
        }
        // should limit to 10...
        if ( todo.size() > 0 && todo.size() <= 10) {
            system.debug('Fiqas_Trigger: Going to insert to Fiqas for ' + todo);
            FiqasAPIservice.Customer_InsUpdate(todo);  
        }
    }
 
    if (Trigger.isUpdate) {
        for (Account newa : Trigger.new) {
            system.debug('Fiqas_Trigger: Deciding whether to update account ' + newa.id);
            Account olda = Trigger.oldMap.get(newa.id);
            if (newa.RecordTypeId == '01220000000YZvhAAG' || newa.RecordTypeId == '01220000000Y83eAAC'
                    || newa.RecordTypeId == '01220000000YDN3AAO' || newa.RecordTypeId == '01220000000Y83jAAC'
                    || newa.RecordTypeId == '012200000005MbLAAU' || newa.RecordTypeId == '01220000000DisxAAC'
                    || newa.RecordTypeId == '01220000000Q8xSAAS' || newa.RecordTypeId == '012w0000000QA3AAAW'
                    || newa.RecordTypeId == '01220000000DqONAA0' || newa.RecordTypeId == '012200000002LlMAAU') {

                // Only trigger an update if:
                // 1. The account has a full Fiqas account number, and
                // 2. A relevant field has changed, and
                // 3. The mandatory fields are not null, and
                // 4. The Gumtree account number has not changed - this prevents a potential future call
                //    within a future call an Opportunity is updated and triggers a new acocunt number to
                //    be generated.
                String fiqasAccountNumber = newa.Account_Number_Fiqas__c;
                if (fiqasAccountNumber != null
                            && fiqasAccountNumber.length() >= 12
                            && newa.Finance_contact__c != null
                            && newa.AccountNumber == olda.AccountNumber) {
                    Contact newFinanceContact = [SELECT Id, FirstName, LastName, Email, Phone
                                FROM Contact where ID = :newa.Finance_contact__c];
                    if (newa.BillingStreet != null
                                && newa.BillingCity != null
                                && newa.BillingPostalCode != null
                                && newa.BillingCountry != null
                                && newFinanceContact.LastName != null) {
                        if (newa.Name != olda.Name
                                    || newa.BillingStreet != olda.BillingStreet
                                    || newa.BillingCity != olda.BillingCity
                                    || newa.BillingPostalCode != olda.BillingPostalCode
                                    || newa.BillingCountry != olda.BillingCountry
                                    || newa.Company_Reg_No__c != olda.Company_Reg_No__c
                                    || newa.Company_VAT_No__c != olda.Company_VAT_No__c
                                    || newa.Apply_VAT__c != olda.Apply_VAT__c
                                    || newa.Finance_Contact__c != olda.Finance_contact__c
                                    || newa.Fiqas_Dunning_Flow__c != olda.Fiqas_Dunning_Flow__c
                                    || newa.Fiqas_Account_Synced__c == 'CONTACTRESYNC') {
                                todo.add((string)newa.id);
                        }
                    }
                }
            }
        }
        // should limit to 10...
        if ( todo.size() > 0 && todo.size() <= 10) {
            system.debug('Fiqas_Trigger: Going to update Fiqas for ' + todo);
            FiqasAPIservice.Customer_InsUpdate(todo);
        }
    }
    system.debug('Fiqas_Trigger: Finished');
}