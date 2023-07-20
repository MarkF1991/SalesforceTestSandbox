@IsTest
public with sharing class PDFGeneratorAsyncTest {
    static testMethod void test_PDFGenerator_success() {
    //do not use @TestSetup to prepare data. This will create DML before the @future method callout, which will cause it to fail
        Contract contract = new Contract();
        contract.CustomerSignedDate = date.newinstance(2020, 10, 1);
        contract.CustomerSignedTitle = 'principal';
        contract.CustomerSignedUser__c = UserInfo.getUserId();
        contract.Educount_Rolls__c = 1000;
        contract.Educount_Rolls_as_at__c = date.newinstance(2020, 7, 1);
        contract.School_Principal_Email__c = 'principal@n4l.co.nz';
        contract.School_Principal_Name__c = 'The Principal';
        contract.Product__c = 'Managed Network To The Classroom';
        contract.Name = 'Unit Test Contract';

        Test.startTest();
        // Set the Mock Class
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'ServiceEventPDFcreatedMock'));
        PDFGeneratorAsync.generatePDF(JSON.serialize(contract));
        Test.stopTest();

        //there should be 1 Service_Event__c record created after the callout
        List<Service_Event__c> events = [SELECT Action__c, Event_Date__c, Event_Id__c, Event_Type__c, Internal_Reference_Id__c, Name, Origin__c, Replay_Id__c, Request_Header__c, Request_Body__c, Response_Body__c, Status_Code__c, Record_Id__c
                                        FROM Service_Event__c];
        system.assertEquals(1, events.size());  
        
        //there should be 1 File record created after the callout
        List<Contentversion> contentVersions = [SELECT Title, VersionData, PathOnClient,ContentDocumentId FROM ContentVersion ];
        system.assertEquals(1, contentVersions.size());  
    }

    static testMethod void test_validateContractForPDF_error() {
        Contract contract = new Contract();
        PDFGeneratorAsync.validateContractForPDF(contract);
        Integer invocations = Limits.getEmailInvocations();
        system.assertEquals(TRUE, (invocations >= 1), 'at least an email should be sent');
    }
}