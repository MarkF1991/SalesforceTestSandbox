public with sharing class OpportunityController {
  @AuraEnabled(cacheable=true)
    public static List<Opportunity> getAccountOpportunityList(String accountId){
        List<Opportunity> result  = new List<Opportunity>();
        if (String.isBlank(accountId)) return result;
        
        result = [SELECT id, Name, createddate, AccountId, CampaignId, Campaign_Name__c, CloseDate, Description, IsClosed, IsWon, Links__c, RecordType.Name, StageName, Type, Owner.Name FROM Opportunity WHERE AccountId =: accountId];
       
        return result;
    }
    @InvocableMethod(label='Generate Onboarding Case, Task and Contract' description='Automatically generate Onboarding Case, Tasks and Contract when Opportunity.StageName is changed to - Committed.')
    public static void InvocableMethod_GenerateOnboardingRecords(List<ID> ids) {
      System.debug('>>>>>>> InvocableMethod_GenerateOnboardingRecords running! ids = ' + JSON.serialize(ids));
        Id opportunityId = ids[0]; //default to first element
        MethodResponse res = generateOnboardingRecords(opportunityId);
        System.debug('>>>>>>> InvocableMethod_GenerateOnboardingRecords ends! res.StatusCode = ' + res.statuscode);
    }

    public static MethodResponse generateOnboardingRecords(Id opportunityId){
      MethodResponse res = new MethodResponse();

      Opportunity opportunity = [SELECT id, Name, AccountId, RecordType.Name, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId FROM Opportunity WHERE Id =: opportunityId ];
      Account account = [SELECT Id, Name, BillingAddress, BillingCity, BillingCountry, BillingCountryCode, BillingGeocodeAccuracy, BillingLatitude, BillingLongitude, BillingPostalCode, BillingState, BillingStateCode, BillingStreet, ShippingAddress, ShippingCity, ShippingCountry, ShippingCountryCode, ShippingGeocodeAccuracy, ShippingLatitude, ShippingLongitude, ShippingPostalCode, ShippingState, ShippingStateCode, ShippingStreet FROM Account WHERE Id =: opportunity.AccountId];

      Map<String, OpportunityContactRole> opportunityContactRoleMap = new Map<String, OpportunityContactRole>();
      List<OpportunityContactRole> opportunityContactRoles = [SELECT Id, ContactId, Contact.Email, Contact.MobilePhone, Contact.Phone, OpportunityId, Role FROM OpportunityContactRole WHERE OpportunityId =: opportunityId ];
      for (OpportunityContactRole opportunityContactRole : opportunityContactRoles){
        opportunityContactRoleMap.put(opportunityContactRole.Role, opportunityContactRole); //prepare map for Get OpportunityContactRole by Role.
      }

      //Get ConfigAutoRecord__c
      List<ConfigAutoRecord__c> configAutoRecords = [SELECT Id, Name, SObjectType__c, Programme__c, Product__c, Case_Owner__c, Case_owner_Queue__c, Type__c FROM ConfigAutoRecord__c WHERE Programme__c =: opportunity.Campaign.Programme__c AND Product__c =: opportunity.Campaign.Product__c AND Type__c =: opportunity.Campaign.Type];
      If (configAutoRecords.IsEmpty()){
        res.setStatus(404); //NOT_FOUND
        res.setResult('error', 'Could not find a Config Auto Record with Programme__c = ' + opportunity.Campaign.Programme__c + ' AND Product__c = ' + opportunity.Campaign.Product__c + ' AND Type__c = ' + opportunity.Campaign.Type);   
        return res;
      }
      ConfigAutoRecord__c configAutoRecord = configAutoRecords[0];
      String sObjectTypesToCreate = configAutoRecord.SObjectType__c; //This is multiple picklist. String Value example: "Case;Task;Contract"
      
      //Get Contract     
      If(sObjectTypesToCreate.contains('Contract') && opportunity.ContractId == null){
        OpportunityContactRole roleSignatoryContact = opportunityContactRoleMap.get('Authorised Signatory');
        Contract contract = new Contract(
          RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Contract, 'N4L Contract'),
          AccountId = account.Id,
          Programme__c = opportunity.Campaign.Programme__c,
          Product__c = opportunity.Campaign.Product__c,
          Status = 'Draft',
          Contract_Type__c = 'Master',
          CustomerSignedId = ( roleSignatoryContact == null? null : roleSignatoryContact.ContactId ),
          OwnerId = UserInfo.getUserId(),

          //BillingAddress= account.BillingAddress,
          BillingCity= account.BillingCity,
          BillingCountry= account.BillingCountry,
          BillingCountryCode= account.BillingCountryCode,
          BillingGeocodeAccuracy= account.BillingGeocodeAccuracy,
          BillingLatitude= account.BillingLatitude,
          BillingLongitude= account.BillingLongitude,
          BillingPostalCode= account.BillingPostalCode,
          BillingState= account.BillingState,
          BillingStateCode= account.BillingStateCode,
          BillingStreet= account.BillingStreet,
          //ShippingAddress= account.ShippingAddress,
          ShippingCity= account.ShippingCity,
          ShippingCountry= account.ShippingCountry,
          ShippingCountryCode= account.ShippingCountryCode,
          ShippingGeocodeAccuracy= account.ShippingGeocodeAccuracy,
          ShippingLatitude= account.ShippingLatitude,
          ShippingLongitude= account.ShippingLongitude,
          ShippingPostalCode= account.ShippingPostalCode,
          ShippingState= account.ShippingState,
          ShippingStateCode= account.ShippingStateCode,
          ShippingStreet= account.ShippingStreet
        );
        insert contract;

        //finally update opportunity to link to this contract
        opportunity.ContractId = contract.Id;
        update opportunity;
      }
        
      //MNTC-763 ConfigAutoRecord allow configuration to assign case owner to a queue
      List<Group> caseOwnerQueues = [SELECT id, name, type FROM Group WHERE Type = 'Queue'];
      Group caseOwnerQueue;

      if(configAutoRecord.Case_owner_Queue__c != null){
      caseOwnerQueue = [SELECT id, name, type FROM Group WHERE type = 'Queue' AND name =: configAutoRecord.Case_owner_Queue__c];
      }
      Id caseOwnerId;
      
      if(configAutoRecord.Case_owner_Queue__c != null){
        caseOwnerId = caseOwnerQueue.id;
      }else{
        caseOwnerId = configAutoRecord.Case_owner__c;
      }
      //-----------------------------------------------------MNTC-763---------END-----------------------------------------------------

      //get a list of onboarding cases
      List<Case> cases = [SELECT Id FROM Case WHERE RecordType.Name = 'Onboarding' AND Opportunity__c =: opportunity.Id];

      //Create an Onboarding Case - only when there is no existing onboarding cases against this opportunity.
      If(sObjectTypesToCreate.contains('Case') && cases.isEmpty()){
        OpportunityContactRole rolePrimaryContact = opportunityContactRoleMap.get('Primary Contact');
        OpportunityContactRole roleSecondaryContact = opportunityContactRoleMap.get('Secondary Contact');
        Case newCase = new Case(
          RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Case, 'Onboarding'),
          AccountId = account.Id,
          Status = 'New',
          Subject = opportunity.Name + ' Onboarding',
          Opportunity__c = opportunity.Id,
          ContactId = ( rolePrimaryContact == null? null : rolePrimaryContact.ContactId ),
          Secondary_Contact__c = (roleSecondaryContact == null? null : roleSecondaryContact.ContactId),
          Programme__c = opportunity.Campaign.Programme__c, //NP-939
          Product__c = opportunity.Campaign.Product__c, //NP-939
          Contract__c = opportunity.ContractId,
          //MNTC-700 & MNTC-763 set caseOnwer on ConfigAutoRecord
          OwnerId = caseOwnerId
        );
        insert newCase;

        //Since Onboarding Tasks has to relate to Onboarding Case, this block of code falls within If(sObjectTypesToCreate.contains('Case')).... 
        //Loop through Task Templates to create an Onboarding Tasks
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
            return res;
          }

          //create tasks
          List<Task> tasks = new List<Task>();
          For( TaskTemplate__c taskTemplate : taskTemplates){
            // System.debug('>>>> taskTemplate.Sequence__c =' + taskTemplate.Sequence__c );
            // Id ownerId;
            // if(taskTemplate.Owner__c == 'Case Owner'){
            //   ownerId = newCase.OwnerId;
            //   System.debug('>>>> taskTemplate.Owner__c =' + taskTemplate.Owner__c );              
            //   System.debug('>>>> ownerId = newCase.OwnerId =' + newCase.OwnerId );
            // } else {
              
            //   System.debug('>>>> queueMap.get(taskTemplate.Owner__c).Id =' + queueMap.get(taskTemplate.Owner__c).Id );
            //   System.debug('>>>> queueMap.get(taskTemplate.Owner__c).Name =' + queueMap.get(taskTemplate.Owner__c).Name );
            //   ownerId = queueMap.get(taskTemplate.Owner__c).Id;
              
            // }
            // System.debug('>>>> as a result, ownerId =' + ownerId);

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

      }//end of If(sObjectTypesToCreate.contains('Case'))
      

      
      res.setStatus(201);
      return res;
    }

    
}