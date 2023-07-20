@IsTest
public class NetworkDesignControllerTest {
    //test method to get test coverage on retired class
    static testMethod void testNothing() {
        NetworkDesignController.doNothing();
    }
    //public static string body = '{"data":{"_id":"e4c06212-1bb9-4f50-9bfe-44afce9da2d2","schoolId":"24ac35ec-e14d-401f-a50c-50552ee80cd9","caseNumber":"00162022","buildings":[{"_id":"6b5fbd38-3c2b-4dd6-aa42-5045017d3e49","ministryId":"44","ministryNumber":"A","ministryName":"Administration","name":"","code":"","whenCreated":"2020-05-01T10:12:31.414Z","whenUpdated":"2020-05-25T09:31:59.246Z","__v":0,"floors":[{"_id":"9a46e8d9-e83d-4370-9727-f2cbfaa0a514","ministryId":"1681023","ministryName":"Ground Floor","name":"","code":"","whenCreated":"2020-05-01T10:12:31.415Z","whenUpdated":"2020-05-25T09:31:59.381Z","__v":0,"rooms":[{"_id":"b306d8c0-2398-4b95-a251-24523e80135d","ministryId":"7250608","ministryNumber":"588013","ministryName":"Staff bathroom (Male)","name":"","code":"","locationId":"","whenCreated":"2020-05-01T10:12:31.502Z","whenUpdated":"2020-05-25T09:31:55.874Z","__v":0,"ownership":{"moe":100,"bot":0,"community":0},"networkElements":[{"_id":"218f8ae4-677d-409b-a325-f3dce345d7fe","status":"Proposed","hostname":"","productCode":"ICX7150-48-4X1G","moeFunded":100},{"_id":"9bc7f5eb-09e4-4ba8-9be4-2a16c28098bf","status":"Proposed","hostname":"","productCode":"901-R650-WW00","moeFunded":100}]}]}]},{"_id":"711ca8bb-630f-4897-b050-c3d191a7bd5e","ministryId":"48","ministryNumber":"E","ministryName":"E Block","name":"","code":"","whenCreated":"2020-05-01T10:12:31.440Z","whenUpdated":"2020-05-25T09:32:06.023Z","__v":0,"floors":[{"_id":"3023326a-1c12-4dff-a7b2-45cf7250664e","ministryId":"1692592","ministryName":"Ground Floor","name":"","code":"","whenCreated":"2020-05-01T10:12:31.441Z","whenUpdated":"2020-05-25T09:32:06.169Z","__v":0,"rooms":[{"_id":"aaefe273-a1c5-4cde-9376-f0ad2af98aba","ministryId":"7315146","ministryNumber":"136742","ministryName":"Design Room","name":"","code":"","locationId":"","whenCreated":"2020-05-01T10:12:32.335Z","whenUpdated":"2020-05-25T09:32:04.849Z","__v":0,"ownership":{"moe":100,"bot":0,"community":0},"networkElements":[{"_id":"f565d167-8585-4f8d-8bd2-0d25261c8260","status":"Proposed","hostname":"","productCode":"ICX7150-48P-4X1G","moeFunded":100}]}]}]}]}}';
    //public static string body = '{"data":{"_id":"e4c06212-1bb9-4f50-9bfe-44afce9da2d2","schoolId":"24ac35ec-e14d-401f-a50c-50552ee80cd9","caseNumber":"00162022","buildings":[{"_id":"6b5fbd38-3c2b-4dd6-aa42-5045017d3e49","ministryId":"44","ministryNumber":"A","ministryName":"Administration","name":"","code":"","whenCreated":"2020-05-01T10:12:31.414Z","whenUpdated":"2020-05-25T09:31:59.246Z","__v":0,"floors":[{"_id":"9a46e8d9-e83d-4370-9727-f2cbfaa0a514","ministryId":"1681023","ministryName":"Ground Floor","name":"","code":"","whenCreated":"2020-05-01T10:12:31.415Z","whenUpdated":"2020-05-25T09:31:59.381Z","__v":0,"rooms":[{"_id":"b306d8c0-2398-4b95-a251-24523e80135d","ministryId":"7250608","ministryNumber":"588013","ministryName":"Staff bathroom (Male)","name":"","code":"","locationId":"","whenCreated":"2020-05-01T10:12:31.502Z","whenUpdated":"2020-05-25T09:31:55.874Z","__v":0,"ownership":{"moe":100,"bot":0,"community":0},"networkElements":[{"_id":"218f8ae4-677d-409b-a325-f3dce345d7fe","status":"Proposed","hostname":"","productCode":"ICX7150-48-4X1G","moeFunded":100},{"_id":"9bc7f5eb-09e4-4ba8-9be4-2a16c28098bf","status":"Proposed","hostname":"","productCode":"901-R650-WW00","moeFunded":100},{"_id":"5cdac524-b25c-439f-8b77-0fbf1b31e306","status":"Proposed","hostname":"","productCode":"ICX7150-24P-4X1G","moeFunded":100},{"_id":"65b13b75-ee11-44a1-a0b7-7ad00b985214","status":"Proposed","hostname":"","productCode":"ICX7150-C10ZP-2X10GR","moeFunded":100},{"_id":"d6ea3174-17a6-4218-abae-55291ec3e0f5","status":"Proposed","hostname":"","productCode":"ICX7150-48ZP-E2X10G","moeFunded":100},{"_id":"f300a041-6f7b-4183-8a10-6002e44e40c0","status":"Proposed","hostname":"","productCode":"ICX7450-24","moeFunded":100}]}]}]},{"_id":"711ca8bb-630f-4897-b050-c3d191a7bd5e","ministryId":"48","ministryNumber":"E","ministryName":"E Block","name":"","code":"","whenCreated":"2020-05-01T10:12:31.440Z","whenUpdated":"2020-05-25T09:32:06.023Z","__v":0,"floors":[{"_id":"3023326a-1c12-4dff-a7b2-45cf7250664e","ministryId":"1692592","ministryName":"Ground Floor","name":"","code":"","whenCreated":"2020-05-01T10:12:31.441Z","whenUpdated":"2020-05-25T09:32:06.169Z","__v":0,"rooms":[{"_id":"aaefe273-a1c5-4cde-9376-f0ad2af98aba","ministryId":"7315146","ministryNumber":"136742","ministryName":"Design Room","name":"","code":"","locationId":"","whenCreated":"2020-05-01T10:12:32.335Z","whenUpdated":"2020-05-25T09:32:04.849Z","__v":0,"ownership":{"moe":100,"bot":0,"community":0},"networkElements":[{"_id":"f565d167-8585-4f8d-8bd2-0d25261c8260","status":"Proposed","hostname":"","productCode":"ICX7150-48P-4X1G","moeFunded":100}]}]}]}]}}  ';
    //'{"data":{"_id":"e4c06212-1bb9-4f50-9bfe-44afce9da2d2","salesforceId":"8015P000000E1KxQAK","schoolId":"27d685da-c9a7-4171-979f-de0678d1bd37","locations":[{"_id":"4bbc7406-8252-4273-bd76-71d828323ec6","ministryId":"22319","ministryNumber":"1","ministryName":"Primary School Blk","name":"","code":"P","type":"building","locations":[{"_id":"d9647b3a-f2b1-4b1c-b6aa-2cd05b338780","ministryId":"1693313","ministryName":"Ground Floor","name":"","code":"G","type":"floor","locations":[{"_id":"d002ce28-4b3d-4d8f-b89f-62c5241ab03c","ministryId":"7328476","ministryNumber":"16120","ministryName":"Computer / Breakout","name":"ICT Room","code":"I","locationId":"PGI","type":"room","networkElements":[{"status":"Proposed","hostname":"1-1031-PGI-01","productId":"01t5m000000EdcGAAS"},{"status":"Proposed","hostname":"1-1031-PGI-02","productId":"01t5m000000EdcEAAS"}]},{"_id":"c20a49d1-fbc8-4863-96a4-edb2a96caa03","ministryId":"7328487","ministryNumber":"16121","ministryName":"Photopy / Storage","name":"Photocopy Room","code":"P","locationId":"PGP","type":"room","networkElements":[{"status":"Proposed","hostname":"1-1031-PGP-01","productId":"01t5m000000EdcGAAS"},{"status":"Proposed","hostname":"1-1031-PGP-02","productId":"01t5m000000EdcEAAS"}]}]}]}]}}}';
    //{"data":{"_id":"e4c06212-1bb9-4f50-9bfe-44afce9da2d2","schoolId":"24ac35ec-e14d-401f-a50c-50552ee80cd9","caseNumber":"00162022","buildings":[{"_id":"6b5fbd38-3c2b-4dd6-aa42-5045017d3e49","ministryId":"44","ministryNumber":"A","ministryName":"Administration","name":"","code":"","whenCreated":"2020-05-01T10:12:31.414Z","whenUpdated":"2020-05-25T09:31:59.246Z","__v":0,"floors":[{"_id":"9a46e8d9-e83d-4370-9727-f2cbfaa0a514","ministryId":"1681023","ministryName":"Ground Floor","name":"","code":"","whenCreated":"2020-05-01T10:12:31.415Z","whenUpdated":"2020-05-25T09:31:59.381Z","__v":0,"rooms":[{"_id":"b306d8c0-2398-4b95-a251-24523e80135d","ministryId":"7250608","ministryNumber":"588013","ministryName":"Staff bathroom (Male)","name":"","code":"","locationId":"","whenCreated":"2020-05-01T10:12:31.502Z","whenUpdated":"2020-05-25T09:31:55.874Z","__v":0,"ownership":{"moe":100,"bot":0,"community":0},"networkElements":[{"_id":"218f8ae4-677d-409b-a325-f3dce345d7fe","status":"Proposed","hostname":"","productCode":"ICX7150-48-4X1G","moeFunded":100},{"_id":"9bc7f5eb-09e4-4ba8-9be4-2a16c28098bf","status":"Proposed","hostname":"","productCode":"901-R650-WW00","moeFunded":100},{"_id":"5cdac524-b25c-439f-8b77-0fbf1b31e306","status":"Proposed","hostname":"","productCode":"ICX7150-24P-4X1G","moeFunded":100},{"_id":"65b13b75-ee11-44a1-a0b7-7ad00b985214","status":"Proposed","hostname":"","productCode":"ICX7150-C10ZP-2X10GR","moeFunded":100},{"_id":"d6ea3174-17a6-4218-abae-55291ec3e0f5","status":"Proposed","hostname":"","productCode":"ICX7150-48ZP-E2X10G","moeFunded":100},{"_id":"f300a041-6f7b-4183-8a10-6002e44e40c0","status":"Proposed","hostname":"","productCode":"ICX7450-24","moeFunded":100}]}]}]},{"_id":"711ca8bb-630f-4897-b050-c3d191a7bd5e","ministryId":"48","ministryNumber":"E","ministryName":"E Block","name":"","code":"","whenCreated":"2020-05-01T10:12:31.440Z","whenUpdated":"2020-05-25T09:32:06.023Z","__v":0,"floors":[{"_id":"3023326a-1c12-4dff-a7b2-45cf7250664e","ministryId":"1692592","ministryName":"Ground Floor","name":"","code":"","whenCreated":"2020-05-01T10:12:31.441Z","whenUpdated":"2020-05-25T09:32:06.169Z","__v":0,"rooms":[{"_id":"aaefe273-a1c5-4cde-9376-f0ad2af98aba","ministryId":"7315146","ministryNumber":"136742","ministryName":"Design Room","name":"","code":"","locationId":"","whenCreated":"2020-05-01T10:12:32.335Z","whenUpdated":"2020-05-25T09:32:04.849Z","__v":0,"ownership":{"moe":100,"bot":0,"community":0},"networkElements":[{"_id":"f565d167-8585-4f8d-8bd2-0d25261c8260","status":"Proposed","hostname":"","productCode":"ICX7150-48P-4X1G","moeFunded":100}]}]}]}]}}  
    
    /**Retired MARCH-2022** replaced by flow - 'N4L PSI Asset Reconciliation'***
    @TestSetup
    Static void Setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
    }

    static testMethod void test_getNetworkDesign() {
        //setupMock();
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'NetworkDesignMock'));
        
        Order order = [SELECT id, PoNumber, uuid__c, Account.uuid__c, Case__r.caseNumber FROM Order WHERE PoNumber = 'PO11111' LIMIT 1];
        order.uuid__c = 'e4c06212-1bb9-4f50-9bfe-44afce9da2d2'; //to match with _id in static resource mock
        update order;
        
        Test.startTest();
        MethodResponse res = NetworkDesignController.getNetworkDesign(order);
        // Verify status code
        System.assertEquals(200,res.statuscode,
                            'The status code is not 200.');
   
        Test.stopTest();
        
        //it should have saved the http request
        List<Service_Event__c> events = [SELECT Id FROM Service_Event__c];
        system.assertEquals(1, events.size());
    }    


    // --temporary commented out. it works!
    static testMethod void test_processNetworkDesign() {
        
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'NetworkDesignMock' LIMIT 1];

        //get json object
        NetworkDesign networkDesign = NetworkDesign.parse(staticResource.Body.toString());
        
        MethodResponse res = NetworkDesignController.processNetworkDesign(networkDesign);
        system.assertEquals(200, res.statuscode);
        
        //get account record based on uuid
        Account account = [SELECT Id, uuid__c FROM Account WHERE uuid__c =: networkDesign.Data.schoolId ];
        
        List<Device__c> testNetworkElements = [SELECT Id, Customer__c, Status__c, Product__c, Product__r.productcode, MoE_Funded__c, Source_Data_UUID__c, HostName__c, Hosted_At__r.Source_Data_UUID__c, Hosted_At__c, Installation_Location__c FROM Device__c WHERE Customer__c =: account.Id ];
        system.assertEquals(3, testNetworkElements.size(), 'the total number network elements of the school should be 3 in this test');
        system.debug('testNetworkElements:'+testNetworkElements);
        Map<String, Device__c> mapTestNetworkElement = NetworkDesignController.getMapNetworkElement(testNetworkElements);
        system.debug('mapTestNetworkElement'+mapTestNetworkElement);
        
        string elementUUID = '218f8ae4-677d-409b-a325-f3dce345d7fe';
        system.assertEquals('ICX7150-48P-4X1G', mapTestNetworkElement.get(elementUUID).Product__r.productcode);
        system.assertEquals('Administration,Ground Floor,Staff bathroom (Male)', mapTestNetworkElement.get(elementUUID).Installation_Location__c, 'the location of this network element should be Administration,Ground Floor,Staff bathroom (Male)');
        
        testNetworkElements = [SELECT Id, Customer__c, Status__c, Product__c, HostName__c, Hosted_At__r.Source_Data_UUID__c, Hosted_At__c, Installation_Location__c FROM Device__c WHERE Installation_Location__c =: 'E Block,Ground Floor,Design Room' ];
        system.assertEquals(1, testNetworkElements.size(), 'the total number network elements of the a room should be 1 in this test');
        
    }
    
    
    static testMethod void test_processNetworkDesign_negative() {
        string bodyWithErrorData = '{"data":{"_id":"e4c06212-1bb9-4f50-9bfe-44afce9da2d2","schoolId":"schoola","caseNumber":"00162022","buildings":[{"_id":"6b5fbd38-3c2b-4dd6-aa42-5045017d3e49","ministryId":"44","ministryNumber":"A","ministryName":"Administration","name":"","code":"","whenCreated":"2020-05-01T10:12:31.414Z","whenUpdated":"2020-05-25T09:31:59.246Z","__v":0,"floors":[{"_id":"9a46e8d9-e83d-4370-9727-f2cbfaa0a514","ministryId":"1681023","ministryName":"Ground Floor","name":"","code":"","whenCreated":"2020-05-01T10:12:31.415Z","whenUpdated":"2020-05-25T09:31:59.381Z","__v":0,"rooms":[{"_id":"b306d8c0-2398-4b95-a251-24523e80135d","ministryId":"7250608","ministryNumber":"588013","ministryName":"Staff bathroom (Male)","name":"","code":"","locationId":"","whenCreated":"2020-05-01T10:12:31.502Z","whenUpdated":"2020-05-25T09:31:55.874Z","__v":0,"ownership":{"moe":100,"bot":0,"community":0},"networkElements":[{"_id":"218f8ae4-677d-409b-a325-f3dce345d7fe","status":"Proposed","hostname":"","productCode":"error_ICX7150-48P-4X1G","moeFunded":100},{"_id":"9bc7f5eb-09e4-4ba8-9be4-2a16c28098bf","status":"Proposed","hostname":"","productCode":"901-R650-WW00","moeFunded":100}]}]}]},{"_id":"711ca8bb-630f-4897-b050-c3d191a7bd5e","ministryId":"48","ministryNumber":"E","ministryName":"E Block","name":"","code":"","whenCreated":"2020-05-01T10:12:31.440Z","whenUpdated":"2020-05-25T09:32:06.023Z","__v":0,"floors":[{"_id":"3023326a-1c12-4dff-a7b2-45cf7250664e","ministryId":"1692592","ministryName":"Ground Floor","name":"","code":"","whenCreated":"2020-05-01T10:12:31.441Z","whenUpdated":"2020-05-25T09:32:06.169Z","__v":0,"rooms":[{"_id":"aaefe273-a1c5-4cde-9376-f0ad2af98aba","ministryId":"7315146","ministryNumber":"136742","ministryName":"Design Room","name":"","code":"","locationId":"","whenCreated":"2020-05-01T10:12:32.335Z","whenUpdated":"2020-05-25T09:32:04.849Z","__v":0,"ownership":{"moe":100,"bot":0,"community":0},"networkElements":[{"_id":"f565d167-8585-4f8d-8bd2-0d25261c8260","status":"Proposed","hostname":"","productCode":"ICX7150-48P-4X1G","moeFunded":100}]}]}]}]}}';
        NetworkDesign networkDesign = NetworkDesign.parse(bodyWithErrorData);
        MethodResponse res = NetworkDesignController.processNetworkDesign(networkDesign);
        system.assertEquals(400, res.statuscode);
    }
*/
}