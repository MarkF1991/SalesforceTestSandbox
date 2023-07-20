@IsTest
public class ServiceEventControllerTest {
    @TestSetup
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecords(False); //Parameter False is for not creating Onboarding Case, Tasks, and Contract we don't need them here in these test.
    }

    private static ServiceEventWrapper setupEventToCreate_ServiceRequestWebFiltering(){
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];

        //prepare event
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
        return event;
    }

    static testMethod void test_createServiceEvent_success(){
        ServiceEventWrapper event = setupEventToCreate_ServiceRequestWebFiltering();

        //mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setStatus('OK');
        
        String recordId = '8005O0000000feNQAQ'; //example of a record id. Only used when generating PDF

        //create Service_Event__c record
        Service_Event__c serviceEvent = ServiceEventController.createServiceEvent(event, response, recordId);
        system.assertEquals(event.eventId, serviceEvent.Event_Id__c);
        system.assertEquals(event.header.eventType, serviceEvent.Event_Type__c);
        system.assertEquals(event.header.action, serviceEvent.Action__c);
        system.assertEquals(event.header.replayId, serviceEvent.Replay_Id__c);
        system.assertEquals(event.header.eventDate, serviceEvent.Event_Date__c);
        system.assertEquals(event.header.internalReferenceId, serviceEvent.Internal_Reference_Id__c);
        system.assertEquals(event.header.origin, serviceEvent.Origin__c);
        
        system.assertEquals(JSON.serialize(event), serviceEvent.Request_Body__c);
        
        system.assertEquals(200, serviceEvent.Status_Code__c);
        system.assertEquals(response.getBody(), serviceEvent.Response_Body__c);


        
        //update existing Service_Event__c record
        //test the first updateServiceEvent() method
        response.setStatusCode(408);
        response.setStatus('Request Timeout');
        Service_Event__c serviceEvent1 = ServiceEventController.updateServiceEvent(event.header.internalReferenceId, response);
        system.assertEquals(408, serviceEvent1.Status_Code__c);
        system.assertNotEquals(null, serviceEvent1.Response_Body__c);

        //test the second updateServiceEvent() method
        response.setStatusCode(200);
        response.setStatus('OK');
        Service_Event__c serviceEvent2 = ServiceEventController.updateServiceEvent(serviceEvent, response);
        system.assertEquals(200, serviceEvent2.Status_Code__c);
        system.assertNotEquals(null, serviceEvent2.Response_Body__c);
        
        //test get Service Event by Event Id
        Service_Event__c serviceEvent3 = ServiceEventController.getServiceEventbyEventId(event.eventId);
        system.assertEquals(event.eventId, serviceEvent3.Event_Id__c);

        //test get Service Event by Internal Reference Id
        Service_Event__c serviceEvent4 = ServiceEventController.getServiceEventbyInternalReferenceId(event.header.internalReferenceId);
        system.assertEquals(event.header.internalReferenceId, serviceEvent3.Internal_Reference_Id__c);
        
    }
    static testMethod void test_createServiceEvent_error(){
        ServiceEventWrapper event = setupEventToCreate_ServiceRequestWebFiltering();

        //mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(408);
        response.setStatus('Request Timeout');
        response.setHeader('replayId','3');

         //create Service_Event__c record
         Service_Event__c serviceEvent = ServiceEventController.createServiceEvent(event, response, null);
         system.assertEquals(event.eventId, serviceEvent.Event_Id__c);
         system.assertEquals(event.header.eventType, serviceEvent.Event_Type__c);
         system.assertEquals(event.header.action, serviceEvent.Action__c);
         system.assertEquals(3, serviceEvent.Replay_Id__c);
         system.assertEquals(event.header.eventDate, serviceEvent.Event_Date__c);
         system.assertEquals(event.header.internalReferenceId, serviceEvent.Internal_Reference_Id__c);
         system.assertEquals(event.header.origin, serviceEvent.Origin__c);
         
         system.assertEquals(JSON.serialize(event), serviceEvent.Request_Body__c);
        
         system.assertEquals(408, serviceEvent.Status_Code__c);
         system.assertEquals(response.getBody(), serviceEvent.Response_Body__c);
    }

    static testMethod void test_createServiceEvent_GetPDF(){
        String pdfId = '4b1c70c9-e866-4ac9-ad7d-c3ca34860744';

        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://dev-api.n4l.co.nz/pdf/' + pdfId);
        request.setHeader('Authorization', 'Bearer ' + 'this_is_token');
        request.setMethod('GET');

        HttpResponse response  = new HttpResponse();             
        //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventPDFcreatedMock' LIMIT 1];
        response.setBody(staticResource.Body.toString());
        response.setStatusCode(200);


        Service_Event__c serviceEvent = ServiceEventController.createServiceEvent_GetPDF(pdfId, request, response);
        system.assertEquals(200, serviceEvent.Status_Code__c);
        system.assertEquals(pdfId, serviceEvent.Internal_Reference_Id__c);
        system.assertEquals(request.toString(), serviceEvent.Request_Header__c);
        system.assertEquals(request.getBody(), serviceEvent.Request_Body__c);
        system.assertEquals(response.getBody(), serviceEvent.Response_Body__c);

    }

    static testMethod void test_createServiceEvent_general(){
        HttpRequest request = new HttpRequest();
        JSONGenerator body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeObjectField('parameters', 'request abc123');
        body.writeEndObject();
        request.setBody(body.getAsString());

        HttpResponse response  = new HttpResponse();
        body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeObjectField('parameters', 'response xyz789');
        body.writeEndObject();
        response.setBody(body.getAsString());
        
        response.setStatusCode(200);

        Service_Event__c serviceEvent = ServiceEventController.createServiceEvent_general('general', request, response, 'this is unit test', '8002O00000015NwQAI');
        system.assertEquals('this is unit test', serviceEvent.Internal_Reference_Id__c);
        system.assertEquals(200, serviceEvent.Status_Code__c);
        system.assertEquals(request.getBody(), serviceEvent.Request_Body__c);
        system.assertEquals(response.getBody(), serviceEvent.Response_Body__c);
    }

    static testMethod void test_createServiceEvent_general_error(){
        HttpRequest request = new HttpRequest();
        JSONGenerator body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeObjectField('parameters', 'request abc123');
        body.writeEndObject();
        request.setBody(body.getAsString());

        HttpResponse response  = new HttpResponse();
        body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeObjectField('parameters', 'response xyz789');
        body.writeEndObject();
        response.setBody(body.getAsString());
        
        response.setStatusCode(400);

        Service_Event__c serviceEvent = ServiceEventController.createServiceEvent_general('general', request, response, 'this is unit test', '8002O00000015NwQAI');
        system.assertEquals('this is unit test', serviceEvent.Internal_Reference_Id__c);
        system.assertEquals(400, serviceEvent.Status_Code__c);
        system.assertEquals(request.getBody(), serviceEvent.Request_Body__c);
        system.assertEquals(response.getBody(), serviceEvent.Response_Body__c);

        // Integer invocations = Limits.getEmailInvocations();
        // system.assertEquals(TRUE, (invocations >= 1), 'at least an email should be sent');
    }

    static testMethod void test_createServiceEvent_general_overloaded(){
        HttpRequest request = new HttpRequest();
        JSONGenerator body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeObjectField('parameters', 'request abc123');
        body.writeEndObject();
        request.setBody(body.getAsString());

        HttpResponse response  = new HttpResponse();
        body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeObjectField('parameters', 'response xyz789');
        body.writeEndObject();
        response.setBody(body.getAsString());
        
        response.setStatusCode(200);

        Service_Event__c serviceEvent = ServiceEventController.createServiceEvent_general('general', 'action', request, response, 'this is unit test', '8002O00000015NwQAI');
        system.assertEquals('this is unit test', serviceEvent.Internal_Reference_Id__c);
        system.assertEquals('action', serviceEvent.Action__c);
        system.assertEquals(200, serviceEvent.Status_Code__c);
        system.assertEquals(request.getBody(), serviceEvent.Request_Body__c);
        system.assertEquals(response.getBody(), serviceEvent.Response_Body__c);
    }

    static testMethod void test_createServiceEvent_async(){
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('callout:Xero/api.xro/2.0/PurchaseOrders');
        JSONGenerator body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeObjectField('parameters', 'request abc123');
        body.writeEndObject();
        request.setBody(body.getAsString());

        HttpResponse response  = new HttpResponse();
        body = JSON.createGenerator(false);
        body.writeStartObject();
        body.writeObjectField('parameters', 'response xyz789');
        body.writeEndObject();
        response.setBody(body.getAsString());
        
        response.setStatusCode(200);

        Test.startTest();

        ServiceEventController.createServiceEvent_async('Xero Callout', request.toString(), request.getBody(), String.valueOf(response.getStatusCode()), response.getBody(), 'this is unit test internal reference id', '8002O00000015NwQAI');

        Test.stopTest();

        Service_Event__c serviceEvent = ServiceEventController.getServiceEventbyInternalReferenceId('this is unit test internal reference id');

        system.assertEquals('this is unit test internal reference id', serviceEvent.Internal_Reference_Id__c);
        system.assertEquals(200, serviceEvent.Status_Code__c);
        system.assertEquals(request.getBody(), serviceEvent.Request_Body__c);
        system.assertEquals(response.getBody(), serviceEvent.Response_Body__c);
        

    }

    static testMethod void test_createServiceEvent_validationError(){
        //prepare an event using wrapper class
        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'PDF';
        event.header.action = 'create';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.origin = 'Salesforce';

        ServiceEventWrapper.Data_PDFcreate data = new ServiceEventWrapper.Data_PDFcreate();
        data.templateId = 'this_is_a_templateId';
        data.contract = new Contract();
        event.data = data; //casting to inherited component
        event.whenCreated = datetime.now();

        String message = 'this is a message to show validation error.';

        Service_Event__c serviceEvent = ServiceEventController.createServiceEvent_validationError(event, message, '8002O00000015NwQAI');
        system.assertEquals(400, serviceEvent.Status_Code__c);
        system.assertEquals(message, serviceEvent.Response_Body__c);

        // Integer invocations = Limits.getEmailInvocations();
        // system.assertEquals(TRUE, (invocations >= 1), 'at least an email should be sent');

    }

    static testMethod void test_getServiceEventbyInternalReferenceIdHavingRecordId_success(){
        String internalReferenceId = 'myInternalReference';
        Service_Event__c serviceEvent1 = new Service_Event__c (
                                        Event_Id__c = UUIDGenerator.Version4UUIDGenerator(null),
                                        Action__c = 'action 1',
                                        Internal_Reference_Id__c = internalReferenceId,
                                        Record_Id__c = null
                                        );
        Service_Event__c serviceEvent2 = new Service_Event__c (
                                        Event_Id__c = UUIDGenerator.Version4UUIDGenerator(null),
                                        Action__c = 'action 2',
                                        Internal_Reference_Id__c = internalReferenceId,
                                        Record_Id__c = 'exampleOfRecordId'
                                        );
        List<Service_Event__c> serviceEvents = new List<Service_Event__c>{serviceEvent1, serviceEvent2};
        insert serviceEvents;

        //test get Service Event by Internal Reference Id
        Service_Event__c serviceEvent3 = ServiceEventController.getServiceEventbyInternalReferenceIdHavingRecordId(internalReferenceId);
        system.assertEquals(serviceEvent2.Internal_Reference_Id__c, serviceEvent3.Internal_Reference_Id__c);
        system.assertEquals(serviceEvent2.Action__c, serviceEvent3.Action__c);
        
    }

    static testMethod void test_getServiceEventbyId() {
        Service_Event__c serviceEvent = new Service_Event__c(Internal_Reference_Id__c = 'intref');
        insert serviceEvent;

        Test.startTest();
            Service_Event__c result = ServiceEventController.getServiceEventbyId(serviceEvent.Id);
        Test.stopTest();

        System.assertEquals(serviceEvent.Id, result.Id, 'service event Ids didn\'t match');
        System.assertEquals(serviceEvent.Internal_Reference_Id__c, result.Internal_Reference_Id__c, 'service event internal refs didn\'t match');
    }

    static testMethod void test_createServiceEvent_overload() {
        String psId = 'someOtherUuid';
        String internalReferenceId = 'someUuid';
        String action = 'create';
        String eventType = 'LinkAsset';
        Datetime eventDate = Datetime.newInstance(2021, 7, 1, 10, 20, 30);
        String origin = 'ps';
        String body = '{ "header": {}, "data": {} }';

        Test.startTest();
            Service_Event__c result = ServiceEventController.createServiceEvent(psId, internalReferenceId, action, eventType, eventDate, origin, body);
        Test.stopTest();

        System.assertEquals(psId, result.Event_Id__c, 'eventId was not the same');
        System.assertEquals(eventType, result.Event_Type__c, 'event type was not the same');
        System.assertEquals(action, result.Action__c, 'action was not the same');
        System.assertEquals(eventDate, result.Event_Date__c, 'event date was not the same');
        System.assertEquals(internalReferenceId, result.Internal_Reference_Id__c, 'internal reference was not the same');
        System.assertEquals(origin, result.Origin__c, 'origin was not the same');
        System.assertEquals(body, result.Request_Body__c, 'req body was not the same');
        System.assertEquals('Not processed yet', result.Response_Body__c, 'res body was not the same');
    }

    static testMethod void test_uploadServiceEvent_overloadWithRecordId() {
        String internalReferenceId = 'someUuid';
        String action = 'create';
        String eventType = 'LinkAsset';
        Datetime eventDate = Datetime.newInstance(2021, 7, 1, 10, 20, 30);
        String origin = 'ps';
        String body = '{ "header": {}, "data": {} }';
        Service_Event__c serviceEvent = ServiceEventController.createServiceEvent('', internalReferenceId, action, eventType, eventDate, origin, body);

        ServiceEventWrapper eventWrapper = setupEventToCreate_ServiceRequestWebFiltering();
        HttpResponse response = new HttpResponse();
        response.setBody('res body');
        response.setStatusCode(200);
        String recordId = 'test';

        Test.startTest();
            Service_Event__c result = ServiceEventController.updateServiceEvent(serviceEvent.Id, eventWrapper, response, recordId);
        Test.stopTest();

        System.assertEquals(eventWrapper.eventId, result.Event_Id__c, 'eventId was not the same');
        System.assertEquals(eventWrapper.header.origin, result.Origin__c, 'origin was not the same');
        System.assertEquals(response.getStatusCode(), result.Status_Code__c, 'status code was not the same');
        System.assertEquals(response.getBody(), result.Response_Body__c, 'res body was not the same');
        System.assertEquals(eventWrapper.header.replayId, result.Replay_Id__c, 'replayId was not the same');
        System.assertEquals(recordId, result.Record_Id__c, 'recordId was not the same');
        System.assertEquals(System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId, result.url__c, 'url was not the same');
    }

    static testMethod void test_updateServiceEvent_Result() {
        String internalReferenceId = 'someUuid';
        String action = 'create';
        String eventType = 'LinkAsset';
        Datetime eventDate = Datetime.newInstance(2021, 7, 1, 10, 20, 30);
        String origin = 'ps';
        String body = '{ "header": {}, "data": {} }';
        Service_Event__c serviceEvent = ServiceEventController.createServiceEvent('', internalReferenceId, action, eventType, eventDate, origin, body);

        ServiceEventWrapper eventWrapper = setupEventToCreate_ServiceRequestWebFiltering();
        ApiResponse response = new ApiResponse();
        response.setRecord(serviceEvent.Id);
        response.setStatus(200);

        Test.startTest();
            Service_Event__c result = ServiceEventController.updateServiceEvent_Result(eventWrapper, response);
        Test.stopTest();

        System.assertEquals(eventWrapper.eventId, result.Event_Id__c, 'eventId was not the same');
        System.assertEquals(response.statusCode, result.Result_Status_Code__c, 'status code was not the same');
        System.assertEquals(JSON.serialize(response).left(131072), result.Result_Message__c, 'replayId was not the same');
        System.assert(!String.isBlank(result.Record_Id__c), 'recordId was blank');
        System.assertEquals(System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + result.Record_Id__c, result.url__c, 'url was not the same');
    }

    static testMethod void test_updateEventResponse_recordId() {
        String psId = 'someUuid1';
        String internalReferenceId = 'someUuid';
        String action = 'create';
        String eventType = 'LinkAsset';
        Datetime eventDate = Datetime.newInstance(2021, 7, 1, 10, 20, 30);
        String origin = 'ps';
        String body = '{ "header": {}, "data": {} }';
        Service_Event__c serviceEvent = ServiceEventController.createServiceEvent(psId, internalReferenceId, action, eventType, eventDate, origin, body);

        HttpResponse response = new HttpResponse();
        response.setBody('some other body');
        response.setStatusCode(200);
        response.setHeader('replayId','21');

        String recordId = 'someRecordId';

        Test.startTest();
            Service_Event__c result = ServiceEventController.updateEventResponse(serviceEvent.Id, response, recordId);
        Test.stopTest();

        System.assertEquals(response.getStatusCode(), result.Status_Code__c, 'status code was not the same');
        System.assertEquals(response.getBody(), result.Response_Body__c, 'response body was not the same');
        System.assertEquals(Decimal.valueOf('21'), result.Replay_Id__c, 'replayId was not the same');
        System.assertEquals(recordId, result.Record_Id__c, 'recordId was not the same');
        System.assertEquals(System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId, result.url__c, 'url was not the same');
    }

    static testMethod void test_updateEventResponse_blankRecordId() {
        String psId = 'someUuid1';
        String internalReferenceId = 'someUuid';
        String action = 'create';
        String eventType = 'LinkAsset';
        Datetime eventDate = Datetime.newInstance(2021, 7, 1, 10, 20, 30);
        String origin = 'ps';
        String body = '{ "header": {}, "data": {} }';
        Service_Event__c serviceEvent = ServiceEventController.createServiceEvent(psId, internalReferenceId, action, eventType, eventDate, origin, body);

        HttpResponse response = new HttpResponse();
        response.setBody('some other body');
        response.setStatusCode(200);
        response.setHeader('replayId','21');

        String recordId = '';

        Test.startTest();
            Service_Event__c result = ServiceEventController.updateEventResponse(serviceEvent.Id, response, recordId);
        Test.stopTest();

        System.assertEquals(response.getStatusCode(), result.Status_Code__c, 'status code was not the same');
        System.assertEquals(response.getBody(), result.Response_Body__c, 'response body was not the same');
        System.assertEquals(Decimal.valueOf('21'), result.Replay_Id__c, 'replayId was not the same');
        System.assertEquals(recordId, result.Record_Id__c, 'recordId was not the same');
        System.assertEquals('', result.url__c, 'url was not the same');
    }
}