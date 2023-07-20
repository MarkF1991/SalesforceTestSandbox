@isTest
public class ServiceEventAssetControllerTest {
    @TestSetup
    private static void setup(){
        String serial = 'TestAsset001';
        String oldDeviceHostname = '1000-101-AG01-OLD';
        String hostname = '1000-101-AG01-CS01';
        Account school = new Account(Name='School Z');
        insert school;
        N4L_Asset_Register__c asset = new N4L_Asset_Register__c(Serial_Number__c = serial);
        Device__c oldDevice = new Device__c(HostName__c = oldDeviceHostname, Customer__c = school.Id, Status__c = 'Active');
        Device__c networkElement = new Device__c(HostName__c = hostname, Customer__c = school.Id);
        insert asset;
        insert oldDevice;
        insert networkElement;
    }

    static testMethod void test_getAssetsByNetworkElementId_valid(){
        String serial = 'LINKEDTestAsset001';
        String hostname = 'LINKED1000-101-AG01-CS01';
        
        Account school = [SELECT Name, Id FROM Account where Name = 'School Z'];
        Device__c linkedDevice = new Device__c(HostName__c = hostname, Customer__c = school.Id, Status__c = 'Active');
        insert linkedDevice;
        N4L_Asset_Register__c linkedAsset = new N4L_Asset_Register__c(Serial_Number__c = serial, Status__c = 'In Service', Network_Element__c = linkedDevice.Id);
        insert linkedAsset;

        Test.startTest();
        N4L_Asset_Register__c[] result = ServiceEventAssetController.getAssetsByNetworkElementId(linkedDevice.Id);
        Test.stopTest();

        System.assertEquals(result[0].Id, linkedAsset.Id);
    }
    
    static testMethod void test_getAssetsByIds_valid(){
        String serial = 'TestAsset001';
        String serial2 = 'TestAsset001X12';
        String hostname = '1000-101-AG01-CS01';
        N4L_Asset_Register__c asset = [SELECT Asset_Number__c,Id,MAC_Address__c,Name,Product__c,Serial_Number__c,Status__c FROM N4L_Asset_Register__c WHERE Serial_Number__c = :serial];
        N4L_Asset_Register__c asset2 = new N4L_Asset_Register__c(Serial_Number__c = serial2, Status__c = 'In Service');
        insert asset2;
        asset2 = [SELECT Asset_Number__c,Id,MAC_Address__c,Name,Product__c,Serial_Number__c,Status__c FROM N4L_Asset_Register__c WHERE Serial_Number__c = :serial2];
        
        String[] ids = new List<String>(2);
        ids.add(asset.Id);
        ids.add(asset2.Id);
        
        Test.startTest();
        N4L_Asset_Register__c[] result = ServiceEventAssetController.getAssetsByIds(ids);
        Test.stopTest();

        System.assert(result.contains(asset), 'asset wasn\'t found in result');
        System.assert(result.contains(asset2), 'asset2 wasn\'t found in result');
        System.assert(result.size() == 2, 'result didn\'t have two assets');
    }

    static testMethod void test_getAssetById_valid(){
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS01';
        N4L_Asset_Register__c asset = [SELECT Asset_Number__c,Id,MAC_Address__c,Name,Product__c,Serial_Number__c,Status__c FROM N4L_Asset_Register__c WHERE Serial_Number__c = :serial];
        
        Test.startTest();
        N4L_Asset_Register__c result = ServiceEventAssetController.getAssetById(asset.Id);
        Test.stopTest();

        System.assertEquals(asset, result, 'asset found did not match');
    }

    static testMethod void test_getAssetById_notFound(){
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS01';
        N4L_Asset_Register__c asset = [SELECT Asset_Number__c,Id,MAC_Address__c,Name,Product__c,Serial_Number__c,Status__c FROM N4L_Asset_Register__c WHERE Serial_Number__c = :serial];
        
        Test.startTest();
        N4L_Asset_Register__c result = ServiceEventAssetController.getAssetById('invalid');
        Test.stopTest();

        System.assertEquals(null, result, 'asset was not null');
    }

    static testMethod void test_getAssetBySerialNumber_valid(){
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS01';
        N4L_Asset_Register__c asset = [SELECT Asset_Number__c,Id,MAC_Address__c,Name,Product__c,Serial_Number__c,Status__c FROM N4L_Asset_Register__c WHERE Serial_Number__c = :serial];
        
        Test.startTest();
        N4L_Asset_Register__c result = ServiceEventAssetController.getAssetBySerialNumber(serial);
        Test.stopTest();

        System.assertEquals(asset, result, 'asset found did not match');
    }

    static testMethod void test_getAssetBySerialNumber_notFound(){
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS01';
        N4L_Asset_Register__c asset = [SELECT Asset_Number__c,Id,MAC_Address__c,Name,Product__c,Serial_Number__c,Status__c FROM N4L_Asset_Register__c WHERE Serial_Number__c = :serial];
        
        Test.startTest();
        N4L_Asset_Register__c result = ServiceEventAssetController.getAssetBySerialNumber('invalid');
        Test.stopTest();

        System.assertEquals(null, result, 'asset found did not match');
    }

    static testMethod void test_getNetworkElementById_valid(){
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS01';
        Device__c device = [SELECT HostName__c,Id,Installed_N4L_Asset__c,Product__c,Installation_Location__c,Installed_N4L_Asset_Status__c,Status__c FROM Device__c WHERE HostName__c = :hostname];
        
        Test.startTest();
        Device__c result = ServiceEventAssetController.getNetworkElementById(device.Id);
        Test.stopTest();

        System.assertEquals(device, result, 'device found did not match');
    }

    static testMethod void test_getNetworkElementById_notFound(){
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS01';
        Device__c device = [SELECT HostName__c,Id,Installed_N4L_Asset__c,Product__c,Installation_Location__c FROM Device__c WHERE HostName__c = :hostname];
        
        Test.startTest();
        Device__c result = ServiceEventAssetController.getNetworkElementById('invalid');
        Test.stopTest();

        System.assertEquals(null, result, 'device was not null');
    }

    static testMethod void test_getNetworkElementByHostName_valid(){
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS01';
        Device__c device = [SELECT HostName__c,Id,Installed_N4L_Asset__c,Product__c,Installation_Location__c,Installed_N4L_Asset_Status__c,Status__c FROM Device__c WHERE HostName__c = :hostname];
        
        Test.startTest();
        Device__c result = ServiceEventAssetController.getNetworkElementByHostName(hostname);
        Test.stopTest();

        System.assertEquals(device, result, 'device found did not match');
    }

    static testMethod void test_getNetworkElementByHostName_notFound(){
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS01';
        Device__c device = [SELECT HostName__c,Id,Installed_N4L_Asset__c,Product__c,Installation_Location__c FROM Device__c WHERE HostName__c = :hostname];
        
        Test.startTest();
        Device__c result = ServiceEventAssetController.getNetworkElementByHostName('invalid');
        Test.stopTest();

        System.assertEquals(null, result, 'device was not null');
    }

    static testMethod void test_validate_success(){ 
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS01';
        ServiceEventAssetController.LinkAssetMessage message = new ServiceEventAssetController.LinkAssetMessage();
        message.header = new ServiceEventMessageHeader();
        message.header.action = 'create';
        message.data = new ServiceEventAssetController.LinkAssetData();
        message.data.hostname = hostname;
        message.data.serial = serial;

        Test.startTest();
        String result = ServiceEventAssetController.validate(message);
        Test.stopTest();

        System.assert(String.isBlank(result), 'result was not empty string');
    }

    static testMethod void test_validate_noHostname(){ 
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS01';
        ServiceEventAssetController.LinkAssetMessage message = new ServiceEventAssetController.LinkAssetMessage();
        message.header = new ServiceEventMessageHeader();
        message.header.action = 'create';
        message.data = new ServiceEventAssetController.LinkAssetData();
        message.data.hostname = null;
        message.data.serial = serial;

        Test.startTest();
        String result = ServiceEventAssetController.validate(message);
        Test.stopTest();

        System.assertEquals('hostname not provided;', result, 'result was not correct error');
    }

    static testMethod void test_validate_noSerial(){ 
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS01';
        ServiceEventAssetController.LinkAssetMessage message = new ServiceEventAssetController.LinkAssetMessage();
        message.header = new ServiceEventMessageHeader();
        message.header.action = 'create';
        message.data = new ServiceEventAssetController.LinkAssetData();
        message.data.hostname = hostname;
        message.data.serial = null;

        Test.startTest();
        String result = ServiceEventAssetController.validate(message);
        Test.stopTest();

        System.assertEquals('serial number not provided;', result, 'result was not correct error');
    }

    static testMethod void test_validate_emptyMessage(){ 
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS01';
        ServiceEventAssetController.LinkAssetMessage message = null;

        Test.startTest();
        String result = ServiceEventAssetController.validate(message);
        Test.stopTest();

        System.assertEquals('message was null', result, 'result was not correct error');
    }

    static testMethod void test_validate_emptyData(){ 
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS01';
        ServiceEventAssetController.LinkAssetMessage message = new ServiceEventAssetController.LinkAssetMessage();
        message.data = null;
        
        Test.startTest();
        String result = ServiceEventAssetController.validate(message);
        Test.stopTest();

        System.assertEquals('data was null', result, 'result was not correct error');
    }

    static testMethod void test_linkAsset_invalid(){ 
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS02';
        String[] serials = new List<String>();
        serials.add(serial);
        ServiceEventAssetController.LinkAssetMessage message = new ServiceEventAssetController.LinkAssetMessage();
        message.header = new ServiceEventMessageHeader();
        message.header.action = 'create';
        message.data = new ServiceEventAssetController.LinkAssetData();
        message.data.hostname = hostname;
        message.data.serial = serial;
        
        String messageBody = JSON.serialize(message);

        Test.startTest();
        ApiResponse result = ServiceEventAssetController.linkAsset(messageBody);
        Test.stopTest();

        System.assert(result.error.message.contains('Network Element not found for '+hostname), result.error.message);
        System.assertEquals(result.statusCode, 500);
        System.assertEquals(null, result.record);
    }

    static testMethod void test_linkAsset_valid(){ 
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS01';
        String[] serials = new List<String>();
        serials.add(serial);
        ServiceEventAssetController.LinkAssetMessage message = new ServiceEventAssetController.LinkAssetMessage();
        message.header = new ServiceEventMessageHeader();
        message.header.action = 'create';
        message.data = new ServiceEventAssetController.LinkAssetData();
        message.data.hostname = hostname;
        message.data.serial = serial;

        N4LSetting__mdt setting = Helper.getN4LSettings().get('Platform Services API')[0];
        String endpointDomain = setting.cryptoKey__c;
        MockHttpResponder jsonResponder = new MockHttpResponder(endpointDomain + '/sfs/events/', 'POST', 200, '{}');
        Test.setMock(HttpCalloutMock.class, jsonResponder);
        
        String messageBody = JSON.serialize(message);

        Test.startTest();
        ApiResponse result = ServiceEventAssetController.linkAsset(messageBody);
        Test.stopTest();

        System.assertEquals(result.statusCode, 200);
        System.assert(result.error == null, 'error was not null');
        System.assert(result.record != null, 'record was null');
        
        Device__c device = [SELECT HostName__c,Id,Product__c,Installation_Location__c FROM Device__c WHERE HostName__c = :hostname];
        N4L_Asset_Register__c asset = [SELECT Asset_Number__c,Id,MAC_Address__c,Name,Product__c,Serial_Number__c,Status__c,Network_Element__c FROM N4L_Asset_Register__c WHERE Serial_Number__c = :serial];
        System.assertEquals(device.Id, asset.Network_Element__c, 'asset link not created');
    }

    static testMethod void test_linkAsset_valid_withOldAsset(){ 
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS01';
        ServiceEventAssetController.LinkAssetMessage message = new ServiceEventAssetController.LinkAssetMessage();
        message.header = new ServiceEventMessageHeader();
        message.header.action = 'create';
        message.data = new ServiceEventAssetController.LinkAssetData();
        message.data.hostname = hostname;
        message.data.serial = serial;

        //Add old device to asset
        String oldDeviceHostname = '1000-101-AG01-OLD';
        Device__c oldDevice = [SELECT HostName__c,Id,Installed_N4L_Asset__c,Product__c,Installation_Location__c, Status__c FROM Device__c WHERE HostName__c = :oldDeviceHostname];
        N4L_Asset_Register__c asset1 = [SELECT Asset_Number__c,Id,MAC_Address__c,Name,Product__c,Serial_Number__c,Status__c FROM N4L_Asset_Register__c WHERE Serial_Number__c = :serial];
        
        asset1.Network_Element__c = oldDevice.Id;
        update asset1;

        N4LSetting__mdt setting = Helper.getN4LSettings().get('Platform Services API')[0];
        String endpointDomain = setting.cryptoKey__c;
        MockHttpResponder jsonResponder = new MockHttpResponder(endpointDomain + '/sfs/events/', 'POST', 200, '{}');
        Test.setMock(HttpCalloutMock.class, jsonResponder);
        
        String messageBody = JSON.serialize(message);

        Test.startTest();
        ApiResponse result = ServiceEventAssetController.linkAsset(messageBody);
        Test.stopTest();

        System.assertEquals(result.statusCode, 200);
        System.assert(result.error == null, 'error was not null');
        System.assert(result.record != null, 'record was null');
        
        Device__c device = [SELECT HostName__c,Id,Product__c,Installation_Location__c,Status__c FROM Device__c WHERE HostName__c = :hostname];
        Device__c oldDevice2 = [SELECT HostName__c,Id,Product__c,Installation_Location__c,Status__c FROM Device__c WHERE HostName__c = :oldDeviceHostname];
        N4L_Asset_Register__c asset = [SELECT Asset_Number__c,Id,MAC_Address__c,Name,Product__c,Serial_Number__c,Status__c,Network_Element__c FROM N4L_Asset_Register__c WHERE Serial_Number__c = :serial];
        System.assertEquals(device.Id, asset.Network_Element__c, 'asset link not created');
        System.assertEquals('Inactive', oldDevice2.Status__c, 'old device status not updated');
    }

    static testMethod void test_linkAssetDelete_invalid(){ 
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS02';
        String[] serials = new List<String>();
        serials.add(serial);
        ServiceEventAssetController.LinkAssetMessage message = new ServiceEventAssetController.LinkAssetMessage();
        message.header = new ServiceEventMessageHeader();
        message.header.action = 'delete';
        message.data = new ServiceEventAssetController.LinkAssetData();
        message.data.hostname = hostname;
        message.data.serial = serial;
        
        String messageBody = JSON.serialize(message);

        Test.startTest();
        ApiResponse result = ServiceEventAssetController.linkAssetDelete(messageBody);
        Test.stopTest();

        System.assert(result.error.message.contains('Network Element not found for '+hostname), result.error.message);
        System.assertEquals(result.statusCode, 500);
        System.assertEquals(null, result.record);
    }

    static testMethod void test_linkAssetDelete_valid(){ 
        String serial = 'TestAsset001';
        String hostname = '1000-101-AG01-CS01';
        String[] serials = new List<String>();
        serials.add(serial);
        ServiceEventAssetController.LinkAssetMessage message = new ServiceEventAssetController.LinkAssetMessage();
        message.header = new ServiceEventMessageHeader();
        message.header.action = 'delete';
        message.data = new ServiceEventAssetController.LinkAssetData();
        message.data.hostname = hostname;
        message.data.serial = serial;

        N4LSetting__mdt setting = Helper.getN4LSettings().get('Platform Services API')[0];
        String endpointDomain = setting.cryptoKey__c;
        MockHttpResponder jsonResponder = new MockHttpResponder(endpointDomain + '/sfs/events/', 'POST', 200, '{}');
        Test.setMock(HttpCalloutMock.class, jsonResponder);
        
        String messageBody = JSON.serialize(message);

        Test.startTest();
        ApiResponse result = ServiceEventAssetController.linkAssetDelete(messageBody);
        Test.stopTest();

        System.assertEquals(result.statusCode, 200);     
        System.assert(result.error == null, 'error was not null');
        System.assert(result.record != null, 'record was null');
        
        Device__c device = [SELECT HostName__c,Id,Product__c,Installation_Location__c FROM Device__c WHERE HostName__c = :hostname];
        N4L_Asset_Register__c asset = [SELECT Asset_Number__c,Id,MAC_Address__c,Name,Product__c,Serial_Number__c,Status__c,Network_Element__c FROM N4L_Asset_Register__c WHERE Serial_Number__c = :serial];
        System.assert(device.Id != asset.Network_Element__c, 'asset link not deleted');
    }


}