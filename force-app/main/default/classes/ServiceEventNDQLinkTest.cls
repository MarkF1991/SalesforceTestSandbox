@IsTest
public with sharing class ServiceEventNDQLinkTest {

    public static ServiceEventNDQLink getQueueHandler(){
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
        
        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 
        
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();
        
        return new ServiceEventNDQLink(event);
    }

    static testMethod void test_Chained_Queues_NetworkDesignLink(){
        ServiceEventNDQLink queueHandler = getQueueHandler();

        //execute queue 1 ----------------------------------------------------------------------------------------------------
        ServiceEventNDQLink.queue_UpdateCase queue1 = new ServiceEventNDQLink.queue_UpdateCase(queueHandler);
        queue1.execute(null);
        //get result and run system assert - a case should be updated
        Case testCase = [SELECT Id, AccountId, Account.uuid__c, OwnerId, Owner.Name, Status , uuid__c, Design_Id__c FROM Case WHERE id =: queueHandler.onboardingData.onboardingCase.Id LIMIT 1];
        system.assertEquals(queueHandler.data.networkDesign.x_id, testCase.Design_Id__c);
        system.assertEquals(queueHandler.data.networkDesign.assignedTo, testCase.OwnerId);
        system.assertEquals(queueHandler.data.networkDesign.salesforceCaseId, testCase.Id);
        system.assertEquals(queueHandler.data.networkDesign.caseId, testCase.uuid__c);

        //execute queue 2 ----------------------------------------------------------------------------------------------------
        //use a task variable to pass parameters into the queuable job, using data from resulting testCase above 
        Task inputTask = new Task(
            WhatId = testCase.id,
            OwnerId = testCase.OwnerId,
            RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Task, 'Onboarding'),
            type = 'Design',
            Status = 'In Progress'
        );

        ServiceEventNDQLink.queue_UpdateTask queue2 = new ServiceEventNDQLink.queue_UpdateTask(queueHandler, inputTask);
        queue2.execute(null);
        
        //get result and run system assert - use the input task as parameter above to query a result and assert test result
        List<Task> tasks = [SELECT id, type, task_template__c, Status, OwnerId, Entity_Attachment_Ids__c
                                FROM Task
                                WHERE RecordTypeId =: inputTask.RecordTypeId
                                    AND Task_Template__r.Type__c =: inputTask.Type
                                    AND WhatId =: inputTask.WhatId
                                ];
        system.assertEquals(inputTask.OwnerId, tasks[0].ownerId); 
        system.assertEquals(inputTask.Status, tasks[0].Status); 
        system.assertEquals(inputTask.Entity_Attachment_Ids__c, tasks[0].Entity_Attachment_Ids__c); 
    }
    
    static testMethod void test_queue_UpdateCase_error(){
        ServiceEventNDQLink queueHandler = getQueueHandler();

        Id invalidUserId = Id.valueOf('0055P000000UzlFQAS'); //this is only an example of invalid user record id
        queueHandler.data.networkDesign.assignedTo = invalidUserId; //introduce error here

        //execute queue 1 ----------------------------------------------------------------------------------------------------
        ServiceEventNDQLink.queue_UpdateCase queue1 = new ServiceEventNDQLink.queue_UpdateCase(queueHandler);
        queue1.execute(null);
        
        //get error message track in Service Event record
        Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);
        system.assertEquals(400, testServiceEvent.Result_Status_Code__c);
    }
}