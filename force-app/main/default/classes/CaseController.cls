public with sharing class CaseController {
  @AuraEnabled(cacheable=true)
    public static List<Case> getAccountCaseList(String accountId, Boolean isOpenOnly){
        List<Case> result  = new List<Case>();
        if (String.isBlank(accountId)) return result;
        
        if (isOpenOnly){
            result = [SELECT id, subject, CaseNumber, Status, createddate, ContactId, Contact.Name, Contact.Email, Owner.Name FROM Case WHERE AccountId =: accountId AND IsClosed = False];
        } else {
            result = [SELECT id, subject, CaseNumber, Status, createddate, ContactId, Contact.Name, Contact.Email, Owner.Name FROM Case WHERE AccountId =: accountId];
        }
        return result;
    }

     @invocableMethod(label='CreateMACtasks')
    //Create complex MACs Tasks
    public static void addNewMACsTasksToCase(List<ID> caseIds){
        MethodResponse res = new MethodResponse();
        //Get ConfigAutoRecord__c
      List<ConfigAutoRecord__c> configAutoRecords = [SELECT Id, Name, SObjectType__c, Programme__c, Product__c, Case_Owner__c, Case_owner_Queue__c, Type__c FROM ConfigAutoRecord__c WHERE Programme__c = 'MAC'];
      If (configAutoRecords.IsEmpty()){
        res.setStatus(404); //NOT_FOUND
        res.setResult('error', 'Could not find a Config Auto Record');   
      }
      ConfigAutoRecord__c configAutoRecord = configAutoRecords[0];
      String sObjectTypesToCreate = configAutoRecord.SObjectType__c; //This is multiple picklist. String Value example: "Case;Task;Contract"
      
        //adding tasks to case
        Case newCase = [SELECT id, AccountId, ownerId FROM Case WHERE id =: caseIds[0]];
        //Loop through Task Templates to create MAC Tasks
        If(sObjectTypesToCreate.contains('Task')){
            Map<String, Group> queueMap = new Map<String, Group>();
            List<Group> queues = [SELECT Id, Name FROM Group WHERE Type = 'Queue'];
            For(Group queue : queues){
              queueMap.put(queue.Name, queue);
            }
  
            //Get TaskTemplate__c
            List<TaskTemplate__c> taskTemplates = [SELECT Id, Name, ConfigAutoRecord__c, Owner__c, Status__c, Type__c, Sequence__c, RecordTypeName__c FROM TaskTemplate__c WHERE ConfigAutoRecord__c =: configAutoRecord.Id ORDER BY Sequence__c];
            If (taskTemplates.IsEmpty()){
              res.setStatus(404); //NOT_FOUND
              res.setResult('error', 'Could not find a TaskTemplate__c record with ConfigAutoRecord__c = ' + configAutoRecord.Id);   
            }
  
            //create tasks
            List<Task> tasks = new List<Task>();
            For( TaskTemplate__c taskTemplate : taskTemplates){
              Account account = [SELECT Id, Name, BillingAddress, BillingCity, BillingCountry, BillingCountryCode, BillingGeocodeAccuracy, BillingLatitude, BillingLongitude, BillingPostalCode, BillingState, BillingStateCode, BillingStreet, ShippingAddress, ShippingCity, ShippingCountry, ShippingCountryCode, ShippingGeocodeAccuracy, ShippingLatitude, ShippingLongitude, ShippingPostalCode, ShippingState, ShippingStateCode, ShippingStreet FROM Account WHERE Id =: newCase.AccountId];
              tasks.add(new Task(
                Subject = account.Name + ' - ' + taskTemplate.Type__c,
                WhatId = newCase.Id,
                Type = taskTemplate.Type__c,
                Status = taskTemplate.Status__c,
                //OwnerId = ownerId,
                OwnerId = (taskTemplate.Owner__c == 'Case Owner' ? newCase.OwnerId : queueMap.get(taskTemplate.Owner__c).Id),
                //OwnerId = newCase.OwnerId,
                RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Task, 'Onboarding'),
                Task_Template__c = taskTemplate.Id
              ));
            }
            insert tasks;
          }
          res.setStatus(201);
    }
}