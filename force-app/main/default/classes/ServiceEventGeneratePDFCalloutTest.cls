@IsTest
public class ServiceEventGeneratePDFCalloutTest {
    //lesson learned: when testing @Future method with callout, we cannot have DML before the the callout. 
    //common.apex.runtime.impl.ExecutionException: You have uncommitted work pending. Please commit or rollback before calling out
    //DML must comes after the callout. Therefore, we must insert service_event__c record after the GeneratePDF() method.
    //@TestSetup
    // private static void setup(){
        //TestObjectFactoryForOnboarding.setupOnboardingRecords(False); //Parameter False is for not creating Onboarding Case, Tasks, and Contract we don't need them here in these test.
    // }

    private static ServiceEventWrapper setupEventToCreatePDF(){
        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'PDF';
        event.header.action = 'create';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = 'a5863333-797a-4ed5-8f6b-c0359d07de17'; //same internal reference in static resource
        event.header.origin = 'Salesforce';
        
        ServiceEventWrapper.Data_PDFcreate data = new ServiceEventWrapper.Data_PDFcreate();
        data.templateId = 'pdftemplate1';
        data.contract = new contract();
        
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();
        return event;
    }
    static testMethod void test_executeGeneratePDF_success(){
        ServiceEventWrapper event =  setupEventToCreatePDF();
        
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'ServiceEventPDFcreateResponseMock'));
        
        system.Test.startTest();
        
        HttpRequest request = new HttpRequest();
        HttpResponse response =  ServiceEventGeneratePDFCallout.executeGeneratePDF(1000, event, request);
        system.assertEquals(200, response.getStatusCode());

        system.Test.stopTest();
    }

    static testMethod void test_executeGeneratePDF_error(){
        ServiceEventWrapper event =  setupEventToCreatePDF();
        
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(408, 'ServiceEventPDFcreateResponseMock'));
        
        system.Test.startTest();
        
        HttpRequest request = new HttpRequest();
        HttpResponse response =  ServiceEventGeneratePDFCallout.executeGeneratePDF(10, event, request);
        system.assertEquals(408, response.getStatusCode());

        system.Test.stopTest();
       
    }

    static testMethod void test_executeGeneratePDF_error2(){
        ServiceEventWrapper event =  setupEventToCreatePDF();
        
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(500, 'ServiceEventPDFcreateResponseMock'));
        
        system.Test.startTest();
        
        HttpRequest request = new HttpRequest();
        HttpResponse response =  ServiceEventGeneratePDFCallout.executeGeneratePDF(20, event, request);
        system.assertEquals(500, response.getStatusCode());

        system.Test.stopTest();
       
    }

    
    static testMethod void test_GeneratePDF_success(){
        ServiceEventWrapper event =  setupEventToCreatePDF();

       
        // Set the Mock Class
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'ServiceEventPDFcreateResponseMock'));

        Test.startTest();

        String recordId = '8005O0000000feNQAQ';
        //run @future method to execute callout ... with retry, and finally update service_event__c record
        ServiceEventGeneratePDFCallout.GeneratePDF(JSON.serialize(event), recordId);
        
        Test.stopTest();

        Service_Event__c serviceEvent = ServiceEventController.getServiceEventbyEventId(event.eventId);
        system.assertEquals(event.eventId, serviceEvent.Event_Id__c);
        system.assertNotEquals(null, serviceEvent.Request_Body__c);
        system.assertNotEquals(null, serviceEvent.Status_Code__c);
        system.assertNotEquals(null, serviceEvent.Response_Body__c);

    }





    static testMethod void test_executeGetPDF_success(){
        
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'ServiceEventPDFcreatedMock'));
        
        system.Test.startTest();
        
        HttpRequest request = new HttpRequest();
        HttpResponse response =  ServiceEventGeneratePDFCallout.executeGetPDF(1000, 1, request);
        system.assertEquals(200, response.getStatusCode());

        system.Test.stopTest();
    }

    static testMethod void test_executeGetPDF_error(){
        
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(408, 'ServiceEventPDFcreatedMock'));
        

        system.Test.startTest();
        
        HttpRequest request = new HttpRequest();
        HttpResponse response =  ServiceEventGeneratePDFCallout.executeGetPDF(10, 1, request);
        system.assertEquals(408, response.getStatusCode());

        system.Test.stopTest();
       
    }


    
    static testMethod void test_GetPDF_success(){
        String pdfId = '4b1c70c9-e866-4ac9-ad7d-c3ca34860744'; //as recorded in mock response

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
         data.pdfId = pdfId;
         
         event.data = data; //casting to inherited component
         
         event.whenCreated =  datetime.now();
 
       
        // Set the Mock Class
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'ServiceEventPDFcreatedMock'));

        Test.startTest();

        String recordId = '8005O0000000feNQAQ';
        //run @future method to execute callout ... with retry, and finally update service_event__c record
        ServiceEventGeneratePDFCallout.GetPDF(pdfId, JSON.serialize(event));
        
        Test.stopTest();



        //similar testing system.assertEquals used in ServiceEventControllerTest.cls
        Service_Event__c serviceEvent = ServiceEventController.getServiceEventbyInternalReferenceId(pdfId);
        system.assertEquals(200, serviceEvent.Status_Code__c);
        system.assertEquals(pdfId, serviceEvent.Internal_Reference_Id__c);
        system.assertNotEquals(null, serviceEvent.Request_Header__c);
        system.assertEquals(null, serviceEvent.Request_Body__c);
        system.assertNotEquals(null, serviceEvent.Response_Body__c);

    }

    static testMethod void test_GetPDFandSaveAsFileAsync_success(){
        String pdfId = '4b1c70c9-e866-4ac9-ad7d-c3ca34860744'; //as recorded in mock response

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
         data.pdfId = pdfId;
         
         event.data = data; //casting to inherited component
         
         event.whenCreated =  datetime.now();
 
         Account account = new Account(Name = 'UnitTestAccount');
         insert account;
       
        // Set the Mock Class
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'ServiceEventPDFcreatedMock'));

        Test.startTest();

        //String recordId = '8005O0000000feNQAQ';
        String recordId = account.Id;
        String filename = 'unit test network design';
        //run @future method to execute callout ... with retry, and finally update service_event__c record
        ServiceEventGeneratePDFCallout.GetPDFandSaveAsFileAsync(pdfId, filename, recordId);
        
        Test.stopTest();



        //similar testing system.assertEquals used in ServiceEventControllerTest.cls
        Service_Event__c serviceEvent = ServiceEventController.getServiceEventbyInternalReferenceId(pdfId);
        system.assertEquals(200, serviceEvent.Status_Code__c);
        system.assertEquals(pdfId, serviceEvent.Internal_Reference_Id__c);
        system.assertNotEquals(null, serviceEvent.Request_Header__c);
        system.assertEquals(null, serviceEvent.Request_Body__c);
        system.assertNotEquals(null, serviceEvent.Response_Body__c);

        ContentVersion cv = [SELECT Id, Title, ContentBodyId, ContentDocumentId, VersionData FROM ContentVersion WHERE Id =: serviceEvent.Record_Id__c];
        system.assertNotEquals(null, cv);
        system.assertEquals('unit test network design.pdf', cv.Title);

    }

    static testMethod void test_GetPDFandSaveAsFile_FileAlreadyExist(){
        String pdfId = '4b1c70c9-e866-4ac9-ad7d-c3ca34860744'; //as recorded in mock response
        Account account = new Account(Name = 'UnitTestAccount');
        insert account;
        String recordId = account.Id;
        String filename = 'unit test network design';

        String base64string = ServiceEventGeneratePDFCallout.strPDFbase64string();

        //prepare an existing file
        Map<Id, ContentVersion> createdPDFFile = FileController.createNewFiles(new List<String>{filename},new List<String>{base64string},recordId,'AllUsers','V',true,null);
        ContentVersion existing_cv = (ContentVersion) createdPDFFile.values()[0];

        MethodResponse res = new MethodResponse();

        Test.startTest();
        
        //run @future method to execute callout ... with retry, and finally update service_event__c record
        res = ServiceEventGeneratePDFCallout.GetPDFandSaveAsFile(pdfId, filename, recordId);
        
        Test.stopTest();
        
      
        system.assertNotEquals(null, res);
        system.assertEquals(200, res.statuscode);
        system.assertEquals(existing_cv.Id, res.results.get('fileRecordId'));
    }

    static testMethod void test_result_of_static_resources(){
        system.assertNotEquals(null, ServiceEventGeneratePDFCallout.responseBody_ServiceEventPDFcreateResponseMock());
        system.assertNotEquals(null, ServiceEventGeneratePDFCallout.responseBody_ServiceEventPDFcreatedMock());
        system.assertNotEquals(null, ServiceEventGeneratePDFCallout.strPDFbase64string());
    }

}