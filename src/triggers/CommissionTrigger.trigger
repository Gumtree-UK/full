trigger CommissionTrigger on Commission2__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {

    // set annual rate & ote
//     Commission.SetAnnualRate(trigger.new, trigger.old, trigger.oldMap, trigger.isBefore, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUnDelete);

    // calc commission payable
     Commission.SetCommissionPayable(trigger.new, trigger.old, trigger.oldMap, trigger.isBefore, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUnDelete);

    // auto start approval
//     Commission.setCommissionApproval(trigger.new, trigger.old, trigger.oldMap, trigger.isBefore, trigger.isInsert, trigger.isUpdate, trigger.isDelete, trigger.isUnDelete);
          
     }