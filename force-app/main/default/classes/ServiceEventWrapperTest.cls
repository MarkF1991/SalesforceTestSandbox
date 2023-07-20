@IsTest
public with sharing class ServiceEventWrapperTest {
    static testMethod void testParse() {


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
        data.accountId = '0015O000004Up0KQAS';
        data.contactId = '0035O000003QKLvQAO';
        
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();

        String json = JSON.serialize(event);

        ServiceEventWrapper r = ServiceEventWrapper.parse(json);
        System.assert(r != null);

    }

    static testMethod void testParse_Header() {
    String json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
    ServiceEventWrapper.Header objHeader = new ServiceEventWrapper.Header(System.JSON.createParser(json));
		System.assert(objHeader != null);
		System.assert(objHeader.eventType == null);
		System.assert(objHeader.action == null);
		System.assert(objHeader.replayId == null);
		System.assert(objHeader.eventDate == null);
		System.assert(objHeader.internalReferenceId == null);
		System.assert(objHeader.origin == null);
    
        //test to hit the constructor
        ServiceEventWrapper.Header header = new ServiceEventWrapper.Header();
        System.assert(header != null);
    }

    static testMethod void testParse_Data_ServiceRequestWebFiltering() {
	
        //test to hit the constructor
        ServiceEventWrapper.Data_ServiceRequestWebFiltering objData = new ServiceEventWrapper.Data_ServiceRequestWebFiltering();
        System.assert(objData != null);
		System.assert(objData.subject == null);
		System.assert(objData.description == null);
		System.assert(objData.accountId == null);
		System.assert(objData.contactId == null);
    }

    static testMethod void testParse_Data_PDFid() {
        String json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
        ServiceEventWrapper.Data_PDFid objData = new ServiceEventWrapper.Data_PDFid(System.JSON.createParser(json));
		System.assert(objData != null);
		System.assert(objData.pdfId == null);
		
        //test to hit the constructor
        objData = new ServiceEventWrapper.Data_PDFid();
        System.assert(objData != null);
    }

    static testMethod void testParse_Data_PDFcreate() {
        String json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
        ServiceEventWrapper.Data_PDFcreate objData = new ServiceEventWrapper.Data_PDFcreate(System.JSON.createParser(json));
		System.assert(objData != null);
        System.assert(objData.templateId == null);
        System.assert(objData.contract == null);
		
        //test to hit the constructor
        objData = new ServiceEventWrapper.Data_PDFcreate();
        System.assert(objData != null);
    }

    static testMethod void testParse_PDF_Create() {
        //similar block of code copied from ServiceEventGeneratePDFCalloutTest.setupEventToCreatePDF() test class, so that we can make sure that ServiceEventWrapper class receive the hightest code coverage
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
        
        String json = System.JSON.serialize(event);

        ServiceEventWrapper r = ServiceEventWrapper.parse(json);
        System.assert(r.data != null);

    }

    static testMethod void testParse_PDF_Created() {
        //similar block of code copied from ServiceEventGeneratePDFCalloutTest.test_GetPDF_success() test class, so that we can make sure that ServiceEventWrapper class receive the hightest code coverage
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
         String json = System.JSON.serialize(event);

        ServiceEventWrapper r = ServiceEventWrapper.parse(json);
        System.assert(r.data != null);
    }

    static testMethod void testParse_NetworkDesign() {


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

        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();
        data.networkDesign = ServiceEventNDWrapper.parse(json);
        
        
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();

        json = System.JSON.serialize(event);

        ServiceEventWrapper r = ServiceEventWrapper.parse(json);
       
        System.assert(r != null);
    }

    

}