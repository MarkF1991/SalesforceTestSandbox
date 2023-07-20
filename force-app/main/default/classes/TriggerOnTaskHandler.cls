/** 08/11/2020 created by N4L salesforce. 
 * create task history and chatter post.
 * refer to custom label Task History RecordType and Task History Fields.
**/
public without sharing class TriggerOnTaskHandler {
    public static void beforeUpdateHandler(Map<id,Task> newMap,Map<id,Task> oldMap){
        String trackingfield = Label.Task_History_Fields;
        String trackingrecordtype = Label.Task_History_RecordType;
        list<Task_History__c> newTHList = new list<Task_History__c>();
        list<FeedItem> postlist = new list<FeedItem>();
        List<String> fieldList= trackingfield.split(';') ;
        List<String> recordTypeList= trackingrecordtype.split(';') ;
        String type='Task';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(type);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap(); 
        set<id> taskRTSet = new set<id>();
        if(recordTypeList.size()>0){
            for(string rt:recordTypeList){
            taskRTSet.add(Schema.SObjectType.Task.getRecordTypeInfosByName().get(rt).getRecordTypeId());
            }    
        }
        if(fieldList.size()==0) return;
        for(Task t:newMap.values()){
            for(string f : fieldList){
                if(t.get(f)!=oldMap.get(t.id).get(f) && taskRTSet.contains(t.RecordTypeId)){
                    system.debug(f+' has been changed');
                    string lab = fieldMap.get(f).getDescribe().getLabel();
                    if(lab=='Due Date Only') lab='Due Date';
                    Task_History__c th =createTaskHistory(t,String.valueof(t.get(f)),String.valueof(oldMap.get(t.id).get(f)),lab);
                    FeedItem post = createChatterPost(th,t);
                    newTHList.add(th);
                    postlist.add(post);   
                } 
            }
        }    
        system.debug('old map:'+oldMap.values().get(0).Owner_Assignee_Full_Name__c);
        system.debug('new map:'+newMap.values().get(0).Owner_Assignee_Full_Name__c);
        if(newTHList.size()>0){
            insert newTHList;
        }
        if(postlist.size()>0){
            insert postlist;
        }
    }
    public static FeedItem createChatterPost(Task_History__c th,task t){
                 FeedItem post = new FeedItem();
                 post.ParentId = t.Id; 
                 post.Body = '#Field_Audit['+th.Field_Name__c+']\n'+ 
                             'Changed from "'+th.Old_Value__c+'" to '+'"'+th.New_Value__c+'"' ;
                 post.title = '#Field_Audit';                                
                 return post;
    }
    public static Task_History__c createTaskHistory(Task t,string newV,string oldV,String fieldName){
        Task_History__c th = new Task_History__c();
        th.Field_Name__c = fieldName.contains('Owner')? 'Assigned To':fieldName;
        th.New_Value__c = newV;
        th.Old_Value__c = oldV;
        if(String.Valueof(t.WhatId).startsWith('500') ){
           th.Parent_Case__c = t.WhatId;   
        }
        if(String.Valueof(t.WhatId).startsWith('006') ){
           th.Parent_Opportunity__c = t.WhatId;   
        }
        th.Changed_By__c = UserInfo.getFirstName() + ' '+UserInfo.getLastName();
        th.Parent_Task_ID__c = t.id;
        th.Task_Sequence__c = t.Sequence__c;
        th.Task_Subject__c = t.Subject;
        th.Task_Type__c = t.Type;
        th.Task_Record_Type__c = Schema.SObjectType.Task.getRecordTypeInfosById().get(t.RecordTypeId).getName();
        
        return th;
    }
}