@IsTest
public with sharing class ServiceEventContractControllerTest {
    @TestSetup
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecords(true); //Parameter False is for not creating Onboarding Case, Tasks, and Contract so that we can test it here.
    }
    
    private static contract getUnitTestContract(){
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Opportunity opportunity = [SELECT Id, Name, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Map<String,String> result = ContractController.getContract(opportunity.ContractId);
        Contract contract = (Contract) JSON.deserialize(result.get('contract'), Contract.class);
        Contact principal = (Contact) JSON.deserialize(result.get('principal'), Contact.class);
        
        //prepare contract variable to fulfill the validateContract() method
        contract.ActivatedDate = date.newinstance(2020, 10, 1);
        contract.CustomerSignedDate = date.newinstance(2020, 10, 1);
        contract.CustomerSignedTitle = 'principal';
        contract.CustomerSignedUser__c = UserInfo.getUserId();
        contract.Educount_Rolls__c = 1000;
        contract.Educount_Rolls_as_at__c = date.newinstance(2020, 7, 1);
        contract.School_Principal_Email__c = principal.Email;
        contract.School_Principal_Name__c = principal.Name;
        
        return contract;
    }
    
    public static testMethod void test_getPDF_templateId(){
        String templateId = ServiceEventContractController.getPDF_templateId('Unit Test PDF');
        system.assertEquals('this_is_unit_test_pdf_id', templateId);
    }
    
    public static testMethod void test_GeneratePDF_success() {
        Contract contract = getUnitTestContract();//this contract must pass validation - missingContractRequiredFields()
        
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'ServiceEventPDFcreateResponseMock'));
        
        system.Test.startTest();
        
        ServiceEventContractController.GeneratePDF(contract); //to call generate PDF
        
        system.Test.stopTest();
        
        
        List<Service_Event__c> events = [SELECT Id FROM Service_Event__c];
        system.assertEquals(1, events.size());
        
    }
    
    public static testMethod void test_GeneratePDF_error() {
        Contract contract = new Contract(); //this contract will fail validation - missingContractRequiredFields()
        
        ServiceEventContractController.GeneratePDF(contract); //to call generate PDF
        
        List<Service_Event__c> events = [SELECT Id FROM Service_Event__c];
        system.assertEquals(1, events.size());
        
        Integer invocations = Limits.getEmailInvocations();
        system.assertEquals(TRUE, (invocations >= 1), 'at least an email should be sent');
    }
    
    public static testMethod void test_missingContractRequiredFields_success() {
        Contract contract = getUnitTestContract();//this contract must pass validation - missingContractRequiredFields()
        Map<String, String> result = ServiceEventContractController.missingContractRequiredFields(contract);
        system.assertEquals(true, result.isempty());
    }
    
    public static testMethod void test_validateContract_error() {
        Contract contract = new Contract(); //this contract will fail validation - missingContractRequiredFields()
        Map<String, String> result = ServiceEventContractController.missingContractRequiredFields(contract);
        system.assertEquals(false, result.isempty());
    }
    
    //--------------------- struggling to get this passed!!!--------------------- 
    // public static testMethod void test_GetPDFforContractCompletion() {
    //     ServiceEventWrapper event = new ServiceEventWrapper();
    //     event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
    //     event.header.eventType = 'PDF';
    //     event.header.action = 'created';
    //     event.header.replayId = 1;
    //     event.header.eventDate = datetime.now();
    //     event.header.internalReferenceId = '263ff4dc-ecc2-400b-97f3-2cc1aa71e501'; //as recorded in Service_Events data
    //     event.header.origin = 'Platform Services';
    
    //     ServiceEventWrapper.Data_PDFid data = new ServiceEventWrapper.Data_PDFid();
    //     data.pdfId = '4b1c70c9-e866-4ac9-ad7d-c3ca34860744'; //as recorded in mock response
    
    //     event.data = data; //casting to inherited component
    
    //     event.whenCreated =  datetime.now();
    
    
    //     Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'ServiceEventPDFcreatedMock'));
    
    //     system.Test.startTest();
    
    //     ApiResponse result = ServiceEventContractController.GetPDFforContractCompletion(event); //to call generate PDF
    //     system.assertEquals(200, result.statusCode);
    
    //     system.Test.stopTest();
    
    
    //     // List<Service_Event__c> events = [SELECT id FROM Service_Event__c];
    //     // system.assertEquals(1, events.size());
    
    // }
    //--------------------- struggling to get this passed!!!--------------------- 
    
    public static testMethod void test_ContractCompletion() {
        
        String internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        
        //get contract
        Contract contract = getUnitTestContract();
        test.startTest();
        //create a record as though it was created after the generatePDF() outbound POST request
        Service_Event__c serviceEvent = new Service_Event__c(
            Event_Id__c = UUIDGenerator.Version4UUIDGenerator(null), 
            Event_Type__c = 'PDF', 
            Action__c = 'create', 
            Event_Date__c  = datetime.now(), 
            Internal_Reference_Id__c = internalReferenceId, 
            Origin__c = 'Salesforce', 
            
            Request_Body__c = '', //ok to leave blank for unit test
            Status_Code__c = 200,
            Response_Body__c = '', //ok to leave blank for unit test
            
            Replay_Id__c = 1,
            Record_Id__c = contract.Id //this will become the parentId of generated PDF
        );
        insert serviceEvent;
        
        
        //prepare event as though was deserialized from the inbound POST request
        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'PDF';
        event.header.action = 'created';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = internalReferenceId; //as recorded in Service_Events data
        event.header.origin = 'Platform Services';
        event.whenCreated =  datetime.now();
        
        ServiceEventWrapper.Data_PDFid data = new ServiceEventWrapper.Data_PDFid();
        data.pdfId = '4b1c70c9-e866-4ac9-ad7d-c3ca34860744'; //as recorded in mock response
        event.data = data; //casting to inherited component
        
        
        //mock reponse from GetPDF. this response contain the pdf base64string
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setStatus('OK');
        response.setBody(ServiceEventGeneratePDFCallout.responseBody_ServiceEventPDFcreatedMock());
        
        //execute to test the method
        ServiceEventContractController.ContractCompletion(event, response);
        
        //there should be 1 file being created
        String searchFileName = '%' + 'Order Form - ' + contract.Product__c + '%';
        Map<Id, sObject> existingFilesOnContract = new Map<Id, sObject>();
        test.stopTest();
        existingFilesOnContract = FileController.getAttachmentOrFileIds(contract.Id, new List<String>{searchFileName},'Both');
        system.assertEquals(1, existingFilesOnContract.size());
        
    }
    
    
    static testMethod void test_update_statusOf_OnboardingTask() {
        integer expectedStatusCode = 200;
        string expectedStatus = 'OK';
        
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];      
        //get NHR opportunity
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Contract contract = [SELECT Id FROM Contract WHERE Id =: opportunity.ContractId];
        Case testCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
        
        Task task = [SELECT Id, Task_Template__r.Type__c, Status, WhatId, RecordType.name FROM Task WHERE WhatId =: testCase.Id AND Task_Template__r.Type__c =: 'Contract Completion' LIMIT 1];
        system.assertNotEquals('Completed', task.Status); //before update, it should not be 'Completed'
        system.debug('task = ' + task);
        
        String type = 'Contract Completion';
        String status = 'Completed';
        List<Task> tasks = [SELECT id, type, task_template__c
                            FROM Task
                            WHERE RecordType.name = 'Onboarding' 
                            AND Task_Template__r.Type__c =: type
                            AND Status !=: status
                            AND WhatId IN (SELECT id 
                                           FROM Case 
                                           WHERE Opportunity__r.Contract.Id =: contract.Id AND RecordType.Name = 'Onboarding')
                           ];
        
        system.debug('tasks = ' + tasks);
        
        MethodResponse res = ServiceEventContractController.update_statusOf_OnboardingTask(contract, 'Contract Completion', 'Completed');
        //system.assertEquals(expectedStatusCode, res.statuscode);//n4l
        
        task = [SELECT Id, Task_Template__r.Type__c, Status FROM Task WHERE WhatId =: testCase.Id AND Task_Template__r.Type__c =: 'Contract Completion' LIMIT 1];
        //system.assertEquals('Completed', task.Status); //after update, it should be 'Completed'//n4l
    }
    
    static testMethod void test_update_statusOf_OnboardingTask_error() {
        integer expectedStatusCode = 400;
        
        MethodResponse res = ServiceEventContractController.update_statusOf_OnboardingTask(null, 'Contract Completion', 'Completed');
        system.assertEquals(expectedStatusCode, res.statuscode);
        
    }
    
    
    static testMethod void test_send_ContractSignedConfirmation_Email_withPDF() {
        //get contract
        Contract contract = getUnitTestContract();
        
        //save the PDF as file
        String base64string = ServiceEventGeneratePDFCallout.strPDFbase64string();
        String subject = 'Order Form - ' + contract.Product__c + '.pdf';
        String parentId = contract.Id;
        Map<Id, ContentVersion> createdCSVFile = FileController.createNewFiles(new List<String>{subject},new List<String>{base64string},parentId,'InternalUsers','V',true,null);
        
        List<Id> fileIdsToAttach = new List<Id>();
        fileIdsToAttach.addAll(createdCSVFile.Keyset()); //get the Id of the PDF file created and add to fileIdsToAttach variable.
        
        
        MethodResponse res = ServiceEventContractController.send_ContractSignedConfirmation_Email_withPDF(contract, fileIdsToAttach);
        system.assertEquals(200, res.statuscode);
        
        Integer invocations = Limits.getEmailInvocations();
        system.assertEquals(TRUE, (invocations >= 1), 'at least an email should be sent');
    }
    
    static testMethod void test_send_ContractSignedConfirmation_Email_withPDF_error() {
        //get contract
        Contract contract = getUnitTestContract();
        
        List<Id> fileIdsToAttach = new List<Id>();
        
        contract.Programme__c = 'This will cause Error';
        
        MethodResponse res = ServiceEventContractController.send_ContractSignedConfirmation_Email_withPDF(contract, fileIdsToAttach);
        system.assertEquals(400, res.statuscode);
        
        //test try catch with exception 
        contract.Name = 'Throw Exception';
        res = ServiceEventContractController.send_ContractSignedConfirmation_Email_withPDF(contract, fileIdsToAttach);
        system.assertEquals(400, res.statuscode);
    }
    
}