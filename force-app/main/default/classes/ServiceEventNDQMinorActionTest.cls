@IsTest
public inherited sharing class ServiceEventNDQMinorActionTest {
    public static ServiceEventNDQMinorAction getQueueHandler(ServiceEventNDQController.Mode mode){
        //test setup
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
        List<Account> accounts = [SELECT id, Name, uuid__c FROM Account WHERE uuid__c != null];  
        Map<String, Account> accountMap = Helper.createAccountMap(accounts, 'uuid');
        Account account = accountMap.get('schoola');
        

        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, Account.uuid__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];

        String action = '';
        switch on mode {
            when HOLD{
                action = 'hold';
            }
            when PEERREVIEW{
                action = 'peerreview';
            }
            when PEERREJECT{
                action = 'peerreject';
            }
            when SCHOOLREJECT{
                action = 'schoolreject';
            }
            when INSTALLERREJECT{
                action = 'installerreject';
            }
            when FINANCIALREVIEW{
                action = 'financialreview';
            }
            when FINANCIALREJECT{
                action = 'financialreject';
            }
            when ASSIGNINSTALLER{
                action = 'Assign Installer';
            }
        }
        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'NetworkDesign';
        event.header.action = action;
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';



        //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventNDWrapperMock' LIMIT 1];
        String json = staticResource.Body.toString();
        json = json.replace('"salesforceCaseId": "5005O000001Fet1QAC",', '"salesforceCaseId": "' + onboardingCase.Id + '",');
        json = json.replace('"schoolId": "697c296d-bc7d-47b7-8d02-3df3ee9e98b9",', '"schoolId": "' + onboardingCase.Account.uuid__c + '",');
        json = json.replace('"assignedTo": "0050o00000Vd2SaAAJ",', '"assignedTo": "' + onboardingCase.OwnerId + '",');
        json = json.replace('"approvedBy": "0050o00000Vd2SaAAJ",', '"approvedBy": "' + onboardingCase.OwnerId + '",');
        json = json.replace('"owner": "0050o00000Vd2SaAAJ",', '"owner": "' + onboardingCase.OwnerId + '",');

        
        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 

        event.data = data; //casting to inherited component

        event.whenCreated =  datetime.now();

        return new ServiceEventNDQMinorAction(event, mode);
    }

    static testMethod void test_ServiceEventNDQMinorAction_Constructor_success(){
        ServiceEventNDQMinorAction queueHandler = getQueueHandler(ServiceEventNDQController.Mode.PEERREVIEW);
        system.assertNotEquals(null, queueHandler.onboardingData.onboardingCase); //when onboardingData is instantiated in the class, it should have a found an onboardingCase
        system.assertNotEquals(null, queueHandler.onboardingData.school);
    }

    static testMethod void test_ServiceEventNDQMinorAction_Constructor_error(){
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
        List<Account> accounts = [SELECT id, Name, uuid__c FROM Account WHERE uuid__c != null];  
        Map<String, Account> accountMap = Helper.createAccountMap(accounts, 'uuid');
        Account account = accountMap.get('schoola');
        

        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, Account.uuid__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];


        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'NetworkDesign';
        event.header.action = 'schoolreview';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';


        String invalidAccountUUId = 'This is an invalid account uuid'; //this is only an example of invalid account uuid

        //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventNDWrapperMock' LIMIT 1];
        String json = staticResource.Body.toString();
        json = json.replace('"salesforceCaseId": "5005O000001Fet1QAC",', '"salesforceCaseId": "' + onboardingCase.Id + '",');
        json = json.replace('"schoolId": "697c296d-bc7d-47b7-8d02-3df3ee9e98b9",', '"schoolId": "' + invalidAccountUUId + '",');
        
        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 

        event.data = data; //casting to inherited component

        event.whenCreated =  datetime.now();

        ServiceEventNDQMinorAction queueHandler = new ServiceEventNDQMinorAction(event, ServiceEventNDQController.Mode.PEERREVIEW);

        //get error message track in Service Event record
        Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(queueHandler.event.eventId);
        system.assertEquals(400, testServiceEvent.Result_Status_Code__c);
    }

    static testMethod void test_queue_queue_UpdateTasks_success(){
        ServiceEventNDQMinorAction queueHandler = getQueueHandler(ServiceEventNDQController.Mode.PEERREVIEW);
        //use a task variable to pass parameters into the queuable job, using data from resulting testCase above 
        test.startTest();
        List<Task> inputTasks = new List<Task>();
        inputTasks.add(new Task(
            WhatId = queueHandler.onboardingData.onboardingCase.id,
            OwnerId = queueHandler.onboardingData.onboardingCase.OwnerId,
            RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Task, 'Onboarding'),
            type = 'Design',
            Status = 'In Peer Review'
        ));
        //execute queue 1 ----------------------------------------------------------------------------------------------------
        
        ServiceEventNDQMinorAction.queue_UpdateTasks queue1 = new ServiceEventNDQMinorAction.queue_UpdateTasks(queueHandler, inputTasks);
        queue1.execute(null);
        
        //Design Task should be updated
        
        List<Task> tasks = [SELECT id, type, task_template__c, Status, OwnerId
                            FROM Task
                            WHERE RecordType.name = 'Onboarding' 
                                AND Task_Template__r.Type__c =: 'Design'
                                AND WhatId =: queueHandler.onboardingData.onboardingCase.Id
                            ];
        Task testTask = tasks[0];
        system.assertEquals('In Peer Review'.toLowerCase(), testTask.Status.toLowerCase());
        test.stopTest();
   }

    static testMethod void test_PrepareInputTasks_FINANCIALREJECT(){
        Id whatId = Id.valueOf('5005O000001RMJ0QAO'); //an example of case.id
        List<Task> testTasks = ServiceEventNDQMinorAction.PrepareInputTasks(ServiceEventNDQController.Mode.FINANCIALREJECT, whatId);
        system.assertEquals(2, testTasks.size());
        
        Map<String, Task> taskMap = new Map<String, Task>();
        For(Task task : testTasks){
            taskMap.put(task.Type, task);
        }
        system.assertEquals('In Progress', taskMap.get('Design').Status);
        system.assertEquals('Deferred', taskMap.get('Design Financial Approval').Status);
   }

    static testMethod void test_PrepareInputTasks_PEERREVIEW(){
        Id whatId = Id.valueOf('5005O000001RMJ0QAO'); //an example of case.id
        List<Task> testTasks = ServiceEventNDQMinorAction.PrepareInputTasks(ServiceEventNDQController.Mode.PEERREVIEW, whatId);
        system.assertEquals(1, testTasks.size());
        
        Map<String, Task> taskMap = new Map<String, Task>();
        For(Task task : testTasks){
            taskMap.put(task.Type, task);
        }
        system.assertEquals('In Peer Review', taskMap.get('Design').Status);
        
    }

   static testMethod void test_MapTaskTypeAndStatus(){
        Task task = new Task();

        task = ServiceEventNDQMinorAction.MapTaskTypeAndStatus(task, ServiceEventNDQController.Mode.HOLD);
        system.assertEquals('Design', task.Type);
        system.assertEquals('Deferred'.toLowerCase(), task.Status.toLowerCase());

        task = ServiceEventNDQMinorAction.MapTaskTypeAndStatus(task, ServiceEventNDQController.Mode.PEERREVIEW);
        system.assertEquals('Design', task.Type);
        system.assertEquals('In Peer Review'.toLowerCase(), task.Status.toLowerCase());

        task = ServiceEventNDQMinorAction.MapTaskTypeAndStatus(task, ServiceEventNDQController.Mode.PEERREJECT);
        system.assertEquals('Design', task.Type);
        system.assertEquals('In Progress'.toLowerCase(), task.Status.toLowerCase());

        task = ServiceEventNDQMinorAction.MapTaskTypeAndStatus(task, ServiceEventNDQController.Mode.SCHOOLREJECT);
        system.assertEquals('Design', task.Type);
        system.assertEquals('In Progress'.toLowerCase(), task.Status.toLowerCase());

        task = ServiceEventNDQMinorAction.MapTaskTypeAndStatus(task, ServiceEventNDQController.Mode.INSTALLERREJECT);
        system.assertEquals('Design', task.Type);
        system.assertEquals('In Progress'.toLowerCase(), task.Status.toLowerCase());

        task = ServiceEventNDQMinorAction.MapTaskTypeAndStatus(task, ServiceEventNDQController.Mode.FINANCIALREVIEW);
        system.assertEquals('Design', task.Type);
        system.assertEquals('Completed'.toLowerCase(), task.Status.toLowerCase());
   }

}