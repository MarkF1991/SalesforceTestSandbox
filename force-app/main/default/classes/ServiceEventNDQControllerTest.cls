@isTest
public with sharing class ServiceEventNDQControllerTest {

    static testMethod void test_NetworkDesignValidation_Link_success(){
        //test setup
        TestObjectFactoryForOnboarding.setupOnboardingRecords(True); //Parameter True is for creating Onboarding Case, Tasks, and Contract we need them here in these test.

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

        //run test on ServiceEventNDQController class
        test.startTest();
        ApiResponse apiResponse = ServiceEventNDQController.NetworkDesignValidation(event);
        test.stopTest();

        //since ServiceEventNDQApprove and other similar classes not running system.enqueueJob() during unit test, we can expect no error being tracked in Service Event record.
        Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(event.eventId);
        system.assertEquals(null, testServiceEvent);
    }

    static testMethod void test_NetworkDesignValidation_Approve_success(){
        //test setup
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();

        List<Account> accounts = [SELECT id, Name, uuid__c FROM Account WHERE uuid__c != null];  
        Map<String, Account> accountMap = Helper.createAccountMap(accounts, 'uuid');
        Account account = accountMap.get('schoola');
        Account returnTo = accountMap.get('eWaste1');

        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, Account.uuid__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];


        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'NetworkDesign';
        event.header.action = 'approve';
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

        //prepare payload "equipmentForRemoval" with uuid of return to 
        json = json.replace('"organisationId": "69a2ef5c-360e-47e4-9192-8488e721ae7b",', '"organisationId": "' + returnTo.uuid__c + '",');


        //use ServiceEventNDQ.OnboardingData class temporary to get pricebook map
        ServiceEventNDQ.OnboardingData onboardingData = new ServiceEventNDQ.OnboardingData();
        onboardingData.preparePricebookMap();//prepare a Map collection of pricebook and pricebook entries in inner class

        //prepare payload with 2 different unit test pricebooks
        json = json.replace('"salesforcePriceBookId": "01s5m0000000G87AAE",', '"salesforcePriceBookId": "' + onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment').Id + '",');
        json = json.replace('"salesforcePriceBookId": "01s5m0000000PkjAAE",', '"salesforcePriceBookId": "' + onboardingData.pricebooksMapByName.get('equipmentProvider2 - Equipment').Id + '",');

        //prepare payload with unit test product id for respective pricebook
        json = json.replace('"salesforceId": "01t5m000000EdcJAAS",', '"salesforceId": "' + onboardingData.pricebooksMapByName.get('equipmentProvider1 - Equipment').PricebookEntries[0].Product2Id + '",');
        json = json.replace('"salesforceId": "01t5m000000EdcGAAS",', '"salesforceId": "' + onboardingData.pricebooksMapByName.get('equipmentProvider2 - Equipment').PricebookEntries[0].Product2Id + '",');

        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 
    
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();

        //run test on ServiceEventNDQController class
        test.startTest();
        ApiResponse apiResponse = ServiceEventNDQController.NetworkDesignValidation(event);
        test.stopTest();

        //since ServiceEventNDQApprove and other similar classes not running system.enqueueJob() during unit test, we can expect no error being tracked in Service Event record.
        Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(event.eventId);
        //system.assertEquals(null, testServiceEvent);//n4l
    }

    public static ServiceEventWrapper  GenerateEventForMinorActions(String action){
        //test setup
        TestObjectFactoryForOnboarding.setupOnboardingRecords(True); //Parameter True is for creating Onboarding Case, Tasks, and Contract we need them here in these test.

        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];


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
        json = json.replace('"schoolId": "697c296d-bc7d-47b7-8d02-3df3ee9e98b9",', '"schoolId": "schoola",');
        json = json.replace('"assignedTo": "0050o00000Vd2SaAAJ",', '"assignedTo": "' + onboardingCase.OwnerId + '",');


        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 
    
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();

        return event;
        
    }
    
    static testMethod void test_NetworkDesignValidation_schoolreview(){
        ServiceEventWrapper event = GenerateEventForMinorActions('schoolreview');

        //run test on ServiceEventNDQController class
        test.startTest();
        ApiResponse apiResponse = ServiceEventNDQController.NetworkDesignValidation(event);
        test.stopTest();

        //since ServiceEventNDQApprove and other similar classes not running system.enqueueJob() during unit test, we can expect no error being tracked in Service Event record.
        Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(event.eventId);
        system.assertEquals(null, testServiceEvent);
    }

    static testMethod void test_NetworkDesignValidation_installerreview(){
        ServiceEventWrapper event = GenerateEventForMinorActions('installerreview');

        //run test on ServiceEventNDQController class
        test.startTest();
        ApiResponse apiResponse = ServiceEventNDQController.NetworkDesignValidation(event);
        test.stopTest();

        //since ServiceEventNDQApprove and other similar classes not running system.enqueueJob() during unit test, we can expect no error being tracked in Service Event record.
        Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(event.eventId);
        system.assertEquals(null, testServiceEvent);
    }

    static testMethod void test_NetworkDesignValidation_hold(){
        ServiceEventWrapper event = GenerateEventForMinorActions('hold');

        //run test on ServiceEventNDQController class
        test.startTest();
        ApiResponse apiResponse = ServiceEventNDQController.NetworkDesignValidation(event);
        test.stopTest();

        //since ServiceEventNDQApprove and other similar classes not running system.enqueueJob() during unit test, we can expect no error being tracked in Service Event record.
        Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(event.eventId);
        system.assertEquals(null, testServiceEvent);
    }

    static testMethod void test_NetworkDesignValidation_peerreview(){
        ServiceEventWrapper event = GenerateEventForMinorActions('peerreview');

        //run test on ServiceEventNDQController class
        test.startTest();
        ApiResponse apiResponse = ServiceEventNDQController.NetworkDesignValidation(event);
        test.stopTest();

        //since ServiceEventNDQApprove and other similar classes not running system.enqueueJob() during unit test, we can expect no error being tracked in Service Event record.
        Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(event.eventId);
        system.assertEquals(null, testServiceEvent);
    }

    static testMethod void test_NetworkDesignValidation_peerrejected(){
        ServiceEventWrapper event = GenerateEventForMinorActions('peerreject');

        //run test on ServiceEventNDQController class
        test.startTest();
        ApiResponse apiResponse = ServiceEventNDQController.NetworkDesignValidation(event);
        test.stopTest();

        //since ServiceEventNDQApprove and other similar classes not running system.enqueueJob() during unit test, we can expect no error being tracked in Service Event record.
        Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(event.eventId);
        system.assertEquals(null, testServiceEvent);
    }

    static testMethod void test_NetworkDesignValidation_schoolrejected(){
        ServiceEventWrapper event = GenerateEventForMinorActions('schoolreject');

        //run test on ServiceEventNDQController class
        test.startTest();
        ApiResponse apiResponse = ServiceEventNDQController.NetworkDesignValidation(event);
        test.stopTest();

        //since ServiceEventNDQApprove and other similar classes not running system.enqueueJob() during unit test, we can expect no error being tracked in Service Event record.
        Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(event.eventId);
        system.assertEquals(null, testServiceEvent);
    }

    static testMethod void test_NetworkDesignValidation_installerrejected(){
        ServiceEventWrapper event = GenerateEventForMinorActions('installerreject');

        //run test on ServiceEventNDQController class
        test.startTest();
        ApiResponse apiResponse = ServiceEventNDQController.NetworkDesignValidation(event);
        test.stopTest();

        //since ServiceEventNDQApprove and other similar classes not running system.enqueueJob() during unit test, we can expect no error being tracked in Service Event record.
        Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(event.eventId);
        system.assertEquals(null, testServiceEvent);
    }

    static testMethod void test_NetworkDesignValidation_dfa(){
        ServiceEventWrapper event = GenerateEventForMinorActions('financialreview');

        //run test on ServiceEventNDQController class
        test.startTest();
        ApiResponse apiResponse = ServiceEventNDQController.NetworkDesignValidation(event);
        test.stopTest();

        //since ServiceEventNDQApprove and other similar classes not running system.enqueueJob() during unit test, we can expect no error being tracked in Service Event record.
        Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(event.eventId);
        system.assertEquals(null, testServiceEvent);
    }

    static testMethod void test_NetworkDesignValidation_dfarejected(){
        ServiceEventWrapper event = GenerateEventForMinorActions('financialreject');

        //run test on ServiceEventNDQController class
        test.startTest();
        ApiResponse apiResponse = ServiceEventNDQController.NetworkDesignValidation(event);
        test.stopTest();

        //since ServiceEventNDQApprove and other similar classes not running system.enqueueJob() during unit test, we can expect no error being tracked in Service Event record.
        Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(event.eventId);
        system.assertEquals(null, testServiceEvent);
    }

    static testMethod void test_NetworkDesignValidation_assigninstaller(){
        ServiceEventWrapper event = GenerateEventForMinorActions('assigninstaller');

        //run test on ServiceEventNDQController class
        test.startTest();
        ApiResponse apiResponse = ServiceEventNDQController.NetworkDesignValidation(event);
        test.stopTest();

        //since ServiceEventNDQApprove and other similar classes not running system.enqueueJob() during unit test, we can expect no error being tracked in Service Event record.
        Service_Event__c testServiceEvent = ServiceEventController.getServiceEventbyEventId(event.eventId);
        system.assertEquals(null, testServiceEvent);
    }


    static testMethod void test_NetworkDesignValidation_Other_Actions(){

        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'NetworkDesign';
        event.header.action = 'other';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';
        
        //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventNDWrapperMock' LIMIT 1];
        String json = staticResource.Body.toString();
        

        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json); 
    
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();

        //run test on ServiceEventNDQController class
        test.startTest();
        ApiResponse apiResponse = ServiceEventNDQController.NetworkDesignValidation(event);
        test.stopTest();
       
        system.assertEquals(200, apiResponse.statusCode);
        system.assertEquals(null, apiResponse.record);
    }

    static testMethod void test_NetworkDesignValidation_error(){
        //test setup
        TestObjectFactoryForOnboarding.setupOnboardingRecords(True); //Parameter True is for creating Onboarding Case, Tasks, and Contract we need them here in these test.

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

        //intentionally delete the case record so that the following validation will return error
        delete onboardingCase;

        //run test on ServiceEventNDQController class
        test.startTest();
        ApiResponse apiResponse = ServiceEventNDQController.NetworkDesignValidation(event);
        test.stopTest();

        system.assertEquals(400, apiResponse.statusCode);
    }
    static testMethod void test_getPricebookChargeToKey(){
        system.assertEquals('MOE',ServiceEventNDQController.getChargeTo(100));
        system.assertEquals('N4L',ServiceEventNDQController.getChargeTo(0));
        system.assertEquals('N4L',ServiceEventNDQController.getChargeTo(50));
        system.assertEquals('N4L',ServiceEventNDQController.getChargeTo(-100));

        String pricebookId = '01s5m0000000G87AAE';
        system.assertEquals('01s5m0000000G87AAE-MOE',ServiceEventNDQController.getPricebookChargeToKey(pricebookId, 100));
        system.assertEquals('01s5m0000000G87AAE-N4L',ServiceEventNDQController.getPricebookChargeToKey(pricebookId, 0));
        system.assertEquals('01s5m0000000G87AAE-N4L',ServiceEventNDQController.getPricebookChargeToKey(pricebookId, 50));
        system.assertEquals('01s5m0000000G87AAE-N4L',ServiceEventNDQController.getPricebookChargeToKey(pricebookId, -100));
    }
}