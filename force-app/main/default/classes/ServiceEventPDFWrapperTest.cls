@IsTest
public with sharing class ServiceEventPDFWrapperTest {
    static testMethod void testParse() {
        //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventPDFcreatedMock' LIMIT 1];
        String json = staticResource.Body.toString();

        ServiceEventPDFWrapper r = ServiceEventPDFWrapper.parse(json);
        System.assert(r != null);
        
        json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
		ServiceEventPDFWrapper.Data objData = new ServiceEventPDFWrapper.Data(System.JSON.createParser(json));
		System.assert(objData != null);
        
        System.assert(objData.eventId == null);
		//System.assert(objData.inputData == null);
		System.assert(objData.pdfBlob == null);
	   
    }
}