@isTest
public class ServiceEventRestTest {
    @TestSetup
    private static void setup(){
        
    }
    static testMethod void test_doPost_ServiceRequestWebFiltering_success(){
        TestObjectFactoryForOnboarding.setupOnboardingRecords(False); //Parameter False is for not creating Onboarding Case, Tasks, and Contract we don't need them here in these test.
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        //String internalReferenceId = '4a6911fd-1dcd-4d8d-a80c-be2323d4ae3e';
        //string json = '{"_id":"0bb85828-ac67-49bf-b851-a547da0442f2","header":{"eventType":"ServiceRequestWebFiltering","action":"create","replayId":1,"eventDate":"2020-08-25T20:52:55.000Z","' + internalReferenceId + '":"4a6911fd-1dcd-4d8d-a80c-be2323d4ae3e","origin":"Platform Services"},"data":{"subject":"This is a subject","description":"this is a description","accountId":"' + account.id + '","contactId":"' + contact.id + '","origin":"School Reporting"},"whenCreated":"2020-08-25T20:56:55.000Z"}';



        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'ServiceRequestWebFiltering';
        event.header.action = 'create';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';
        
        ServiceEventWrapper.Data_ServiceRequestWebFiltering data = new ServiceEventWrapper.Data_ServiceRequestWebFiltering();
        data.subject = 'this is subject';
        data.description = 'this is description';
        data.accountId = account.id;
        data.contactId = contact.id;
        
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();

        String json = JSON.serialize(event);
        system.debug(json);
     
        RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/n4l/platform/events';
        request.httpMethod = 'POST';
		request.requestBody = blob.valueOf(json);
        
        RestContext.request = request;
		system.Test.startTest();
        ApiResponse result = ServiceEventRest.doPost();
        system.assertEquals(200, result.statusCode, 'statusCode not 200 '+result);
        system.Test.stopTest();

        List<Case> cases = [SELECT Subject, Description, AccountId, ContactId, Status, Product__c, Call_Driver__c, Origin, Priority, uuid__c, OwnerId, RecordTypeId FROM Case WHERE AccountId =: account.id];
        Case testCase = cases[0];
        system.assertEquals(Helper.getRecordTypeId(Schema.SObjectType.Case, 'Service Request'), testCase.RecordTypeId );
        system.assertEquals(event.header.internalReferenceId, testCase.uuid__c);

    }

    static testMethod void test_doPost_NetworkDesignRouting_success(){
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        //get NHR opportunity
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, AccountId, ContactId, Secondary_Contact__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];

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

        json = System.JSON.serialize(event);
        system.debug(json);
     
        RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/n4l/platform/events';
        request.httpMethod = 'POST';
		request.requestBody = blob.valueOf(json);
        
        RestContext.request = request;
		system.Test.startTest();
        ApiResponse result = ServiceEventRest.doPost();
        system.assertEquals(200, result.statusCode);
        system.Test.stopTest();


        /* commented out as we have changed the approach to use Queueable Apex for async solution instead : system.enqueueJob() are not runned during unit test-------------------------------
        // //a case should be updated
        // Case testCase = [SELECT Id, AccountId, Account.uuid__c, OwnerId, Owner.Name, Status , uuid__c, Design_Id__c FROM Case WHERE id =: onboardingCase.Id LIMIT 1];
        // system.assertEquals(data.networkDesign.x_id, testCase.Design_Id__c);
        // system.assertEquals(data.networkDesign.assignedTo, testCase.OwnerId);
        // system.assertEquals(data.networkDesign.salesforceCaseId, testCase.Id);

        // //Design Task should be updated
        // List<Task> tasks = [SELECT id, type, task_template__c, Status, OwnerId
        //                         FROM Task
        //                         WHERE RecordType.name = 'Onboarding' 
        //                             AND Task_Template__r.Type__c =: 'Design'
        //                             AND WhatId =: testCase.Id
        //                         ];
        // Task testTask = tasks[0];
        // system.assertEquals(data.networkDesign.assignedTo, testTask.OwnerId);
        // system.assertEquals('In Progress', testTask.Status);
        ----------------------------------------------------------------------------- */
    }

    static testMethod void test_doPost_PDF(){

        //prepare event wrapper as though it has already been deserialsed from doPost()
        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'PDF';
        event.header.action = 'created';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';
        
        ServiceEventWrapper.Data_PDFid data = new ServiceEventWrapper.Data_PDFid();
        data.pdfId = '4b1c70c9-e866-4ac9-ad7d-c3ca34860744'; //as recorded in mock response
        
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();


        String json = JSON.serialize(event);
        system.debug(json);
     
        RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/n4l/platform/events';
        request.httpMethod = 'POST';
		request.requestBody = blob.valueOf(json);
        
        RestContext.request = request;
		system.Test.startTest();
        ApiResponse result = ServiceEventRest.doPost();
        system.assertEquals(400, result.statusCode);
        system.Test.stopTest();

        

    }

    static testMethod void test_doPost_NetworkDesign_OtherAction(){

        //prepare event wrapper as though it has already been deserialsed from doPost()
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


        json = System.JSON.serialize(event);
        system.debug(json);
     
        RestRequest request = new RestRequest();
        request.requestUri ='/services/apexrest/n4l/platform/events';
        request.httpMethod = 'POST';
		request.requestBody = blob.valueOf(json);
        
        RestContext.request = request;
		system.Test.startTest();
        ApiResponse result = ServiceEventRest.doPost();
        system.assertEquals(200, result.statusCode);
        system.Test.stopTest();
    }

    static testMethod void test_trackServiceEvent(){
        //prepare event wrapper as though it has already been deserialsed from doPost()
        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'PDF';
        event.header.action = 'created';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';
        
        ServiceEventWrapper.Data_PDFid data = new ServiceEventWrapper.Data_PDFid();
        data.pdfId = '4b1c70c9-e866-4ac9-ad7d-c3ca34860744'; //as recorded in mock response
        
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();

        //prepare result as ServiceEventRest.ServiceEventRestApiResponse
        ServiceEventRest.ServiceEventRestApiResponse result = new ServiceEventRest.ServiceEventRestApiResponse();
        result.setStatus(200);
        result.error = null;
        result.internalReferenceId = event.header.internalReferenceId;

        //test trackServiceEvent method
        ServiceEventRest.trackServiceEvent(event, result);
        //the created record in Service_Event__c should have the same eventId as the source
        Service_Event__c serviceEvent = ServiceEventController.getServiceEventbyEventId(event.eventId);
        system.assertEquals(event.eventId, serviceEvent.Event_Id__c);
    }

    //Testing REST call
    //See article here: https://salesforce.stackexchange.com/questions/185163/a-testclass-for-restresource-httppost
    static testMethod void test_eventWithEmptyBody(){
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/n4l/platform/events/*';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{}');

        RestContext.request = req;
        RestContext.response = res;
        ApiResponse postResult = null;
        Test.startTest();
            try {
                postResult = ServiceEventRest.doPost();
            }
            catch(NullPointerException e) {
                //Current expected behaviour is to throw a NullPointerException if body is empty object
            }
        Test.stopTest();

        System.assertEquals(null, postResult, 'result was not null');
    }
  
    static testMethod void test_updateServiceEvent(){
        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'PDF';
        event.header.action = 'created';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';
        
        ServiceEventWrapper.Data_PDFid data = new ServiceEventWrapper.Data_PDFid();
        data.pdfId = '4b1c70c9-e866-4ac9-ad7d-c3ca34860744'; //as recorded in mock response
        
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();

        //prepare result as ServiceEventRest.ServiceEventRestApiResponse
        ServiceEventRest.ServiceEventRestApiResponse result = new ServiceEventRest.ServiceEventRestApiResponse();
        result.setStatus(200);
        result.error = null;
        result.internalReferenceId = event.header.internalReferenceId;

        //test updateServiceEvent method
        ServiceEventRest.updateServiceEvent(result.internalReferenceId, result);
    }


    //Salesforce test context does not send callouts e.g. LinkEvent to PS
    //See https://salesforce.stackexchange.com/questions/244797/how-do-i-unit-test-code-that-includes-a-callout
    // Service event - temporarily disabled due to log spam CJF 27092021 
    // static testMethod void test_eventWithBadLinkEvent(){
    //     RestRequest req = new RestRequest();
    //     RestResponse res = new RestResponse();

    //     req.requestURI = '/n4l/platform/events/*';
    //     req.httpMethod = 'POST';
    //     req.requestBody = Blob.valueOf('{ "_id" : "testDoPostLinkEvent",'
    //      + '"header" : { "action" : "create", "replayId" : 199999, "eventDate" : "2021-06-28T09:09:56.220+0000", "eventType" : "asset.link", "internalReferenceId" : null,'
    //         + '"origin" : "provision", "source" : "ps", "direction" : "OUTBOUND" },'
    //      + '"data" : { "hostname": "1000-101-AG01-CS01", "serial": "123456789" }'
    //      + '}');

    //     String expectedMessage = 'asset and network element pair not found for serial number: 123456789 and hostname: 1000-101-AG01-CS01';

    //     RestContext.request = req;
    //     RestContext.response = res;

    //     Test.startTest();
    //         ApiResponse postResult = ServiceEventRest.doPost();
    //     Test.stopTest();

    //     System.assertEquals(404, postResult.statusCode);
    //     System.assert(postResult.error.message.contains(expectedMessage));
    // }

    // Service event - temporarily disabled due to log spam CJF 27092021 
    // static testMethod void test_eventWithGoodLinkEvent(){
    //     RestRequest req = new RestRequest();
    //     RestResponse res = new RestResponse();

    //     req.requestURI = '/n4l/platform/events/*';
    //     req.httpMethod = 'POST';
    //     req.requestBody = Blob.valueOf('{ "_id" : "testDoPostLinkEvent",'
    //      + '"header" : { "action" : "create", "replayId" : 199999, "eventDate" : "2021-06-28T09:09:56.220+0000", "eventType" : "asset.link", "internalReferenceId" : null,'
    //         + '"origin" : "provision", "source" : "ps", "direction" : "OUTBOUND" },'
    //      + '"data" : { "hostname": "1000-101-AG01-CS01", "serial": "123456789" }'
    //      + '}');

    //     Account testSchool = new Account();
    //     testSchool.Name = 'School Z';
    //     insert testSchool;

    //     N4L_Asset_Register__c asset = new N4L_Asset_Register__c(Serial_Number__c = '123456789');
    //     Device__c networkElement = new Device__c(HostName__c = '1000-101-AG01-CS01', Customer__c = testSchool.Id);
    //     insert asset;
    //     insert networkElement;

    //     N4LSetting__mdt setting = Helper.getN4LSettings().get('Platform Services API')[0];
    //     String endpointDomain = setting.cryptoKey__c;
    //     MockHttpResponder jsonResponder = new MockHttpResponder(endpointDomain + '/sfs/events/', 'POST', 200, '{}');
    //     Test.setMock(HttpCalloutMock.class, jsonResponder);

    //     RestContext.request = req;
    //     RestContext.response = res;

    //     Test.startTest();
    //         ApiResponse postResult = ServiceEventRest.doPost();
    //     Test.stopTest();

    //     N4L_Asset_Register__c assetAfter = [SELECT Id,Serial_Number__c FROM N4L_Asset_Register__c WHERE Serial_Number__c = '123456789'];
    //     Device__c networkElementAfter =  [SELECT Id,HostName__c,Installed_N4L_Asset__c FROM Device__c WHERE HostName__c = '1000-101-AG01-CS01'];

    //     String jobId = postResult.record.Id;
    //     AsyncApexJob jobInfo = [SELECT Status,NumberOfErrors FROM AsyncApexJob WHERE Id=:jobId];

    //     System.assertEquals(200, postResult.statusCode);
    //     System.assert(postResult.messages.size() == 0);
    //     System.assert(String.isBlank(postResult.internalReferenceId));
    //     System.assert(postResult.error == null);
    //     System.assertEquals('Completed', jobInfo.Status, 'OutboundEvent Job did not have Completed status or Job not found');
    //     System.assertEquals(networkElementAfter.Installed_N4L_Asset__c, assetAfter.Id, 'asset not assigned to network element');
    // }
}