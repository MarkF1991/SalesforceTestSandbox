/**
* @author Ben Soh (ben.soh@n4l.co.nz)
* @date 2019-07-23
* @description to display existing Tasks and Events and create new Task in LWC on Lightning App Page
*
* CHANGE LOG
**/

public with sharing class ActivityController {
    //--------------------------------- Task ---------------------------------
    @AuraEnabled(cacheable=true) 
    //@AuraEnabled()//removed cacheable=true so that the lwc can refresh after a task is created
    public static List<Task> getTaskList(string whatId,  Boolean isOpenOnly ) {
        List<Task> result  = new List<Task>();
        if (String.isBlank(whatId)) return result;
        
        if (isOpenOnly){
            result = [SELECT Id, Subject, Status, createdDate, ActivityDate, OwnerId, Owner.Name, WhoId, Who.Name, IsClosed, WhatId FROM Task WHERE WhatId =: whatId AND IsClosed = False ORDER BY CreatedDate Desc];
        } else {
            result = [SELECT Id, Subject, Status, createdDate, ActivityDate, OwnerId, Owner.Name, WhoId, Who.Name, IsClosed, WhatId FROM Task WHERE WhatId =: whatId ORDER BY CreatedDate Desc];
        }
        return result;
    }

    @AuraEnabled() //using cacheable=true will cause error LIMIT_USAGE_FOR_NS   Number of DML statements: 1 out of 0 ******* CLOSE TO LIMIT
    public static Task createTaskRecord(Map<string, object> fieldsMap ) {
        Task task = new Task();
        task.Id = String.valueOf(fieldsMap.get('id'));
        task.Subject = String.valueOf(fieldsMap.get('Subject'));
        task.Status =  String.valueOf(fieldsMap.get('Status'));
        task.ActivityDate = Date.valueOf(String.valueOf(fieldsMap.get('ActivityDate')));
        task.OwnerId = Id.valueOf(String.valueOf(fieldsMap.get('OwnerId')));
        task.WhatId = Id.valueOf(String.valueOf(fieldsMap.get('WhatId')));
        task.Description = String.valueOf(fieldsMap.get('Description'));
        upsert task;
        
        //query to return record back to lwc in order to add to tasks collections
        String recordId = task.Id;
        return [SELECT id, Subject, Status, createdDate, ActivityDate, OwnerId, Owner.Name, WhoId, Who.Name, IsClosed, WhatId FROM Task WHERE Id =: recordId];
    }

    //--------------------------------- Event ---------------------------------
    @AuraEnabled(cacheable=true) 
    //@AuraEnabled()//removed cacheable=true so that the lwc can refresh after a task is created
    public static List<Event> getEventList(string whatId,  Boolean isOpenOnly ) {
        //system.debug('>>>> in getEventList(whatId, isOpenOnly), whatId = ' + whatId );
        //system.debug('>>>> isBlank(whatId) = ' + String.IsBlank(whatId) );
        List<Event> result  = new List<Event>();
        if (String.isBlank(whatId)) return result;
        
        if (isOpenOnly){
            result = [SELECT Id, Subject, createdDate, ActivityDate, ActivityDateTime, OwnerId, Owner.Name, WhoId, Who.Name, WhatId, Description, Notes__c, Driver__c FROM Event WHERE WhatId =: whatId AND Event_Closed__c = False ORDER BY CreatedDate Desc];
        } else {
            result = [SELECT Id, Subject, createdDate, ActivityDate, ActivityDateTime, OwnerId, Owner.Name, WhoId, Who.Name, WhatId, Description, Notes__c, Driver__c FROM Event WHERE WhatId =: whatId ORDER BY CreatedDate Desc];
        }
        system.debug('>>>> in getEventList() result = ' + JSON.serializePretty(result) );
        return result;
    }

    @AuraEnabled() //using cacheable=true will cause error LIMIT_USAGE_FOR_NS   Number of DML statements: 1 out of 0 ******* CLOSE TO LIMIT
    public static Event upsertEventRecord(Map<string, object> fieldsMap ) {
        system.debug('>>>>> fieldsMap = ' + JSON.serializePretty(fieldsMap));
        Event event = new Event();
        event.Id = String.valueOf(fieldsMap.get('id'));
        event.Description = String.valueOf(fieldsMap.get('description'));
        event.Driver__c = String.valueOf(fieldsMap.get('driver'));
        event.Notes__c = String.valueOf(fieldsMap.get('notes'));
        upsert event; //using upsert to update event record
        system.debug('>>>>> upsert event = ' + JSON.serializePretty(event));
        //query to return record back to lwc in order to add to tasks collections
        String recordId = event.Id;
        return [SELECT Id, Subject, createdDate, ActivityDate, ActivityDateTime, OwnerId, Owner.Name, WhoId, Who.Name, WhatId, Description, Notes__c, Driver__c FROM Event WHERE Id =: recordId];
    }
}