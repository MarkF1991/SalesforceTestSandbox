/** 08/11/2020 created by N4L salesforce. 
 * before update to catch updat of task history.
**/
trigger TriggerOnTask on Task (before update) {
    
    if(Trigger.isBefore && Trigger.isUpdate ){
           TriggerOnTaskHandler.beforeUpdateHandler(trigger.newmap,trigger.oldmap);
        }

}