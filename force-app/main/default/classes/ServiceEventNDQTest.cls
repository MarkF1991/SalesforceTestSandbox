@isTest
public with sharing class ServiceEventNDQTest {
    
    public static ServiceEventNDQ getQueueHandler(){
        //test setup
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];


        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'NetworkDesign';
        event.header.action = 'link';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';
        
        //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventNDWrapperMock' LIMIT 1];
        String json = staticResource.Body.toString();
        json = json.replace('"salesforceCaseId": "5005O000001Fet1QAC",', '"salesforceCaseId": "' + onboardingCase.Id + '",');
        json = json.replace('"schoolId": "697c296d-bc7d-47b7-8d02-3df3ee9e98b9",', '"schoolId": "schoola",');
        json = json.replace('"assignedTo": "0050o00000Vd2SaAAJ",', '"assignedTo": "' + onboardingCase.OwnerId + '",');
        json = json.replace('"approvedBy": "0050o00000Vd2SaAAJ",', '"approvedBy": "' + onboardingCase.OwnerId + '",');
        json = json.replace('"owner": "0050o00000Vd2SaAAJ",', '"owner": "' + onboardingCase.OwnerId + '",');

        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 
       
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();
      
        return new ServiceEventNDQ(event);
   }
   static testMethod void test_ServiceEventNDQ_Constructor(){
       ServiceEventNDQ queueHandler = getQueueHandler();
       system.assertNotEquals(null, queueHandler.onboardingData.onboardingCase); //when onboardingData is instantiated in the class, it should have a found an onboardingCase
   }
  //n4l error method
   static testMethod void test_OnboardingData_InnerClass(){
       //test setup
       TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
       List<Account> accounts = [SELECT id, Name, uuid__c FROM Account WHERE uuid__c != null];  
       Map<String, Account> accountMap = Helper.createAccountMap(accounts, 'uuid');

       Account account = accountMap.get('schoola');
       Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
       Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];

       //get response body from Static Resource
       StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventNDWrapperMock' LIMIT 1];
       String json = staticResource.Body.toString();
       json = json.replace('"salesforceCaseId": "5005O000001Fet1QAC",', '"salesforceCaseId": "' + onboardingCase.Id + '",');
       json = json.replace('"schoolId": "697c296d-bc7d-47b7-8d02-3df3ee9e98b9",', '"schoolId": "schoola",');
       json = json.replace('"assignedTo": "0050o00000Vd2SaAAJ",', '"assignedTo": "' + onboardingCase.OwnerId + '",');
       json = json.replace('"approvedBy": "0050o00000Vd2SaAAJ",', '"approvedBy": "' + onboardingCase.OwnerId + '",');
       json = json.replace('"owner": "0050o00000Vd2SaAAJ",', '"owner": "' + onboardingCase.OwnerId + '",');

       ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
       data.networkDesign = ServiceEventNDWrapper.parse(json); 

       ServiceEventNDQ.OnboardingData onboardingData = new ServiceEventNDQ.OnboardingData();

       //test getUser - assignedTo
       //n4l onboardingData.getUser(data.networkDesign.assignedTo, 'assignedTo');
       //n4l System.assertEquals(onboardingCase.OwnerId, onboardingData.designAssignedTo.Id);

       //test getUser - approvedBy
      //n4l onboardingData.getUser(data.networkDesign.approvedBy, 'approvedBy');
      //n4l  System.assertEquals(onboardingCase.OwnerId, onboardingData.designApprovedBy.Id);

       //test getUser - owner
       //n4l onboardingData.getUser(data.networkDesign.owner, 'owner');
       //n4l System.assertEquals(onboardingCase.OwnerId, onboardingData.designOwner.Id);

       //test getUser - error
       Id invalidUserId = Id.valueOf('0055P000000UzlFQAS'); //this is only an example of invalid user record id
       onboardingData.getUser(invalidUserId, 'assignedTo');
       System.assertEquals(FALSE, onboardingData.errorMessages.isEmpty());

       // test getAccount - school
       onboardingData.getAccount(data.networkDesign.schoolId, 'school');
       System.assertEquals(account.Id, onboardingData.school.Id);

       // test getAccount - returnTo
       onboardingData.getAccount('eWaste1', 'returnTo');
       System.assertEquals(accountMap.get('eWaste1').Id, onboardingData.returnTo.Id);

       // test getAccount - error
       String invalidAccoutUUId = 'invalid_uuid'; //this is only an example of invalid account uuid
       onboardingData.getAccount(invalidAccoutUUId, 'school');
       System.assertEquals(FALSE, onboardingData.errorMessages.isEmpty());

       //test preparePricebookMap and preparePricebookProductMap
       System.assertEquals(TRUE, onboardingData.pricebooksMap.isEmpty());
       System.assertEquals(TRUE, onboardingData.pricebookProductMap.isEmpty());

       onboardingData.preparePricebookMap();
       System.assertEquals(FALSE, onboardingData.pricebooksMap.isEmpty());

       Pricebook2 pricebook = onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment');
       System.assertEquals('equipmentProvider1 - Equipment', pricebook.Name);
       System.assertEquals(TRUE, onboardingData.pricebooksMap.containsKey(pricebook.Id));

       PricebookEntry pricebookEntry = pricebook.PricebookEntries[0];
       String key = Helper.concatenateKey(new List<String>{pricebook.Id, pricebookEntry.Product2Id});
       
       onboardingData.preparePricebookProductMap(new Set<String>{pricebook.Id});
       System.assertEquals(FALSE, onboardingData.pricebookProductMap.isEmpty());
       System.assertEquals(TRUE, onboardingData.pricebookProductMap.containsKey(key));
       System.assertEquals(pricebookEntry.Id, onboardingData.pricebookProductMap.get(key).Id);


       // test getErrorMessage
       onboardingData.errorMessages.clear();
       onboardingData.errorMessages.add('Red');
       onboardingData.errorMessages.add('Green');
       onboardingData.errorMessages.add('Blue');
       System.assertEquals('Red,Green,Blue', onboardingData.getErrorMessage());

   }

   
   static testMethod void test_queue_UpdateTask(){
       //prepare a queue
       ServiceEventNDQ queueHandler = getQueueHandler();

       //prepare an input task as parameter
       Task inputTask = new Task(
               WhatId = queueHandler.onboardingData.onboardingCase.id,
               OwnerId = queueHandler.onboardingData.onboardingCase.OwnerId,
               RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Task, 'Onboarding'),
               type = 'Design',
               Status = 'In Progress', 
               Entity_Attachment_Ids__c = 'file_record_id'
           );
           

       Test.startTest();
       System.enqueueJob(new ServiceEventNDQ.queue_UpdateTask(queueHandler, inputTask));
       Test.stopTest();

       //use the input task as parameter above to query a result and assert test result
       List<Task> tasks = [SELECT id, type, task_template__c, Status, OwnerId, Entity_Attachment_Ids__c
                               FROM Task
                               WHERE RecordTypeId =: inputTask.RecordTypeId
                                   AND Task_Template__r.Type__c =: inputTask.Type
                                   AND WhatId =: inputTask.WhatId
                               ];
       system.assertEquals(inputTask.OwnerId, tasks[0].ownerId); 
       system.assertEquals(inputTask.Status, tasks[0].Status); 
       system.assertEquals(inputTask.Entity_Attachment_Ids__c, tasks[0].Entity_Attachment_Ids__c); 
       
       Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);
       system.assertEquals(200, testServiceEvent.Result_Status_Code__c);
   }

   static testMethod void test_queue_UpdateTask_error(){
       //prepare a queue
       ServiceEventNDQ queueHandler = getQueueHandler();

       Id invalidUserId = Id.valueOf('0055P000000UzlFQAS'); //this is only an example of invalid user record id

       //prepare an inputTask task as parameter
       Task inputTask = new Task(
               WhatId = queueHandler.onboardingData.onboardingCase.id,
               OwnerId = invalidUserId,
               RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Task, 'Onboarding'),
               type = 'Design',
               Status = 'Invalid Status', 
               Entity_Attachment_Ids__c = 'file_record_id'
           );
           

       Test.startTest();
       System.enqueueJob(new ServiceEventNDQ.queue_UpdateTask(queueHandler, inputTask));
       Test.stopTest();

       Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);
       system.assertEquals(400, testServiceEvent.Result_Status_Code__c);
       
   }

   static testMethod void test_queue_UpdateTasks(){
    //prepare a queue
    ServiceEventNDQ queueHandler = getQueueHandler();

    //prepare an input task as parameter
    List<Task> inputTasks = new List<Task>();
    inputTasks.add(new Task(
        WhatId = queueHandler.onboardingData.onboardingCase.id,
        OwnerId = queueHandler.onboardingData.onboardingCase.OwnerId,
        RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Task, 'Onboarding'),
        type = 'Design',
        Status = 'In Progress', 
        Entity_Attachment_Ids__c = 'file_record_id1'
    ));
    inputTasks.add(new Task(
        WhatId = queueHandler.onboardingData.onboardingCase.id,
        OwnerId = queueHandler.onboardingData.onboardingCase.OwnerId,
        RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Task, 'Onboarding'),
        type = 'Design Financial Approval',
        Status = 'Deferred', 
        Entity_Attachment_Ids__c = 'file_record_id2'
    ));
            
    Set<String> types = new Set<String>();
    For(Task task : inputTasks){
        types.add(task.type);
    }

    Test.startTest();
    System.enqueueJob(new ServiceEventNDQ.queue_UpdateTasks(queueHandler, inputTasks));
    Test.stopTest();

    //use the input task as parameter above to query a result and assert test result
    List<Task> tasks = [SELECT id, type, task_template__c, Status, OwnerId, Entity_Attachment_Ids__c
                            FROM Task
                            WHERE RecordTypeId =: Helper.getRecordTypeId(Schema.SObjectType.Task, 'Onboarding')
                                AND Task_Template__r.Type__c IN: types
                                AND WhatId =: queueHandler.onboardingData.onboardingCase.id
                            ];
    system.assertEquals(inputTasks[0].OwnerId, tasks[0].ownerId); 

    for(Task task : tasks){
        switch on task.Type{
            when 'Design'{
                system.assertEquals('In Progress', task.Status);
                system.assertEquals('file_record_id1', task.Entity_Attachment_Ids__c); 
            }
            when 'Design Financial Approval'{
                system.assertEquals('Deferred', task.Status);
                system.assertEquals('file_record_id2', task.Entity_Attachment_Ids__c); 
            }
        }
    }
    
    Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);
    system.assertEquals(200, testServiceEvent.Result_Status_Code__c);
}

static testMethod void test_queue_UpdateTasks_error(){
    //prepare a queue
    ServiceEventNDQ queueHandler = getQueueHandler();

    Id invalidUserId = Id.valueOf('0055P000000UzlFQAS'); //this is only an example of invalid user record id

    //prepare an inputTask task as parameter
    List<Task> inputTasks = new List<Task>();
    inputTasks.add(new Task(
        WhatId = queueHandler.onboardingData.onboardingCase.id,
        OwnerId = invalidUserId,
        RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Task, 'Onboarding'),
        type = 'Design',
        Status = 'In Progress', 
        Entity_Attachment_Ids__c = 'file_record_id1'
    ));    

    Test.startTest();
    System.enqueueJob(new ServiceEventNDQ.queue_UpdateTasks(queueHandler, inputTasks));
    Test.stopTest();

    Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);
    system.assertEquals(400, testServiceEvent.Result_Status_Code__c);
    
}

   static testMethod void test_trackServiceEvent_createServiceEvent(){
       //prepare a queue
       ServiceEventNDQ queueHandler = getQueueHandler();
       //system.debug('n4l limits 111 ='+limits.getQueries());
       String recordId = '5005O000001Fet1QAC'; 
       ApiResponse result = new ApiResponse();
       result.setStatus(200);
       result.setRecord(recordId);

       //test ServiceEventNDQ.trackServiceEvent(ApiResponse result) - create Service Event record
       queueHandler.trackServiceEvent(result);
       Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);
       system.assertEquals(200, testServiceEvent.Status_Code__c);
       system.assertEquals(recordId, testServiceEvent.Record_Id__c);
       //system.debug('n4l limits 222 ='+limits.getQueries());
       //test 200 ServiceEventNDQ.trackServiceEvent(String message, Integer statusCode, String recordId) - update existing Service Event Record
       String message = 'this is a message in unit test';
       queueHandler.trackServiceEvent(message, 200, recordId);
       testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);
       system.assertEquals(200, testServiceEvent.Result_Status_Code__c);
       system.assertEquals(true, testServiceEvent.Result_Message__c.contains(message));
       //system.debug('n4l limits 333 ='+limits.getQueries());
       //test 400 ServiceEventNDQ.trackServiceEvent(String message, Integer statusCode, String recordId) - update existing Service Event Record
       test.startTest();//n4l
       queueHandler.trackServiceEvent(message, 400, recordId);
       testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);
       system.assertEquals(400, testServiceEvent.Result_Status_Code__c);
       system.assertEquals(true, testServiceEvent.Result_Message__c.contains(message));

       //system.debug('n4l limits 444 ='+limits.getQueries());
       //test with Exception ServiceEventNDQ.trackServiceEvent(Exception e, Integer statusCode, String recordId) - update existing Service Event with System.EmailException
       message = 'Read timed out';
       CalloutException e = new CalloutException();
       e.setMessage(message);
       queueHandler.trackServiceEvent(e, 400, recordId);

       testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);
       system.assertEquals(400, testServiceEvent.Result_Status_Code__c);
       system.assertEquals(true, testServiceEvent.Result_Message__c.contains(message));
       test.stopTest();//n4l
   }
   
}