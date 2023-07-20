@isTest
public class ServiceEventOutboundTest {
    static testMethod void test_constructor(){
        String eventType = 'eventType';
        String action = 'action';

        Test.startTest();
        ServiceEventOutbound event = new ServiceEventOutbound(eventType, action);
        Test.stopTest();

        System.assertEquals(event.header.eventType, eventType, 'string did not match');
        System.assertEquals(event.header.action, action, 'string did not match');
        Service_Event__c serviceEvent = [SELECT Id,Internal_Reference_Id__c FROM Service_Event__c WHERE Internal_Reference_Id__c =: event.header.internalReferenceId];
        System.assertEquals(serviceEvent.Id, event.serviceEvent.Id, 'Id did not match');
    }

    static testMethod void test_add(){
        String eventType = 'LinkAsset';
        String action = 'create';
        ServiceEventOutbound event = new ServiceEventOutbound(eventType, action);
        String key = 'test';
        Device__c testDevice = new Device__c(HostName__c = 'testHostName');

        Test.startTest();
            event.add(key, testDevice);
        Test.stopTest();

        System.assertEquals(1, event.data.size(), 'data size incorrect');
        System.assertEquals(testDevice, event.data.get(key), 'data size incorrect');
    }

    static testMethod void test_finalise(){
        String eventType = 'LinkAsset';
        String action = 'create';
        ServiceEventOutbound event = new ServiceEventOutbound(eventType, action);
        String key = 'test';
        Device__c testDevice = new Device__c(HostName__c = 'testHostName');
        event.add(key, testDevice);

        Service_Event__c serviceEvent = [SELECT Id,Internal_Reference_Id__c,Name FROM Service_Event__c WHERE Internal_Reference_Id__c =: event.header.internalReferenceId];
        String nameSplitRight = serviceEvent.Name.split('-',2)[1];

        Test.startTest();
            event.finalise();
        Test.stopTest();

        serviceEvent = [SELECT Id,Internal_Reference_Id__c,Name,Request_Body__c,Replay_Id__c FROM Service_Event__c WHERE Internal_Reference_Id__c =: event.header.internalReferenceId];

        System.assert(event.header.eventDate != null, 'eventDate was null');
        System.assertEquals(Integer.valueOf(nameSplitRight), event.header.replayId, 'replayId in header incorrect');
        System.assertEquals(event.header.replayId, event.serviceEvent.Replay_Id__c, 'replayId in serviceEvent incorrect');
        System.assert(!String.isBlank(serviceEvent.Request_Body__c), 'request body stored in serviceEvent was blank');
    }

    static testMethod void test_send_success(){
        N4LSetting__mdt setting = Helper.getN4LSettings().get('Platform Services API')[0];
        String endpointDomain = setting.cryptoKey__c;
        MockHttpResponder jsonResponder = new MockHttpResponder(endpointDomain + '/sfs/events/', 'POST', 200, '{}');
        Test.setMock(HttpCalloutMock.class, jsonResponder);
        
        String eventType = 'LinkAsset';
        String action = 'create';
        ServiceEventOutbound event = new ServiceEventOutbound(eventType, action);
        String key = 'test';
        Device__c testDevice = new Device__c(HostName__c = 'testHostName');
        event.add(key, testDevice);
        Service_Event__c serviceEvent = [SELECT Id,Internal_Reference_Id__c,Name FROM Service_Event__c WHERE Internal_Reference_Id__c =: event.header.internalReferenceId];
        String nameSplitRight = serviceEvent.Name.split('-',2)[1];

        Id jobId = null;
        Test.startTest();
            jobId = event.send();
        Test.stopTest();
        
        AsyncApexJob jobInfo = [SELECT Status,NumberOfErrors FROM AsyncApexJob WHERE Id=:jobId];
        serviceEvent = [SELECT Id,Internal_Reference_Id__c,Name,Request_Body__c,Replay_Id__c FROM Service_Event__c WHERE Internal_Reference_Id__c =: event.header.internalReferenceId];

        System.assert(jobId != null, 'jobId was null');
        System.assertEquals('Completed', jobInfo.Status, 'OutboundEvent Job did not have Completed status or Job not found');
        System.assertEquals(Integer.valueOf(nameSplitRight), event.header.replayId, 'replayId in header incorrect');
        System.assertEquals(event.header.replayId, event.serviceEvent.Replay_Id__c, 'replayId in serviceEvent incorrect');
        System.assert(!String.isBlank(serviceEvent.Request_Body__c), 'request body stored in serviceEvent was blank');
    }

    static testMethod void test_send_failure(){
        N4LSetting__mdt setting = Helper.getN4LSettings().get('Platform Services API')[0];
        String token = setting.token__c;
        String endpointDomain = setting.cryptoKey__c;
        MockHttpResponder jsonResponder = new MockHttpResponder(endpointDomain + '/sfs/events/', 'POST', 200, '{}');
        Test.setMock(HttpCalloutMock.class, jsonResponder);
        
        String eventType = 'LinkAsset';
        String action = 'create';
        ServiceEventOutbound event = new ServiceEventOutbound(eventType, action);

        String key = 'test';
        Device__c testDevice = new Device__c(HostName__c = 'testHostName');
        event.add(key, testDevice);

        //Cause an error
        event.header = null;
        event.data = null;

        Id jobId = null;
        Test.startTest();
            jobId = event.send();
        Test.stopTest();

        Service_Event__c serviceEvent = [SELECT Id,Internal_Reference_Id__c,Name,Response_Body__c,Status_Code__c FROM Service_Event__c WHERE Id =: event.serviceEvent.Id];

        System.assert(jobId == null, 'jobId was not null');
        System.assert(serviceEvent.Response_Body__c.contains('unable to send event to Platform Services:'));
        System.assertEquals(500, serviceEvent.Status_Code__c, 'status code was not 500');
    }

}