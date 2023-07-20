/**
 * @Date               : March 25, 2021
 * @Description        : apex trigger for related school ict provider
 * @Author             : Heidi Tang (heitang@deloitte.com)
**/
trigger N4LRelatedICTTrigger on Related_School_ICTProvider__c (after insert, after update, after delete, after undelete) {

    if(Trigger.isAfter) {
        if(Trigger.isInsert){
            N4LRelatedICTTriggerHandler.onAfterInsert(Trigger.new);
        } else if(Trigger.isUpdate){
            N4LRelatedICTTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        } else if(Trigger.isDelete) {
            N4LRelatedICTTriggerHandler.onAfterDelete(Trigger.old);
        } else if(Trigger.isUnDelete){
            N4LRelatedICTTriggerHandler.onAfterUnDelete(Trigger.new);
        }
    }
}