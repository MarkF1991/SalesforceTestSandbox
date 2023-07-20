@IsTest
public with sharing class CaseControllerTest {
    @TestSetup
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecords(True); //Parameter False is for not creating Onboarding Case, Tasks, and Contract so that we can test it here.
 
        //create internal user - relationship manager
        User rmUser = TestClassUtility.createInternalUser(); //email is internaluser@invalid-domain.com
        rmUser.UserPermissionsSchoolReportingUser__c = true; //allow user to getAccessibleSchools for School Reporting
        insert rmUser;
    } 

    static testMethod void test_getAccountCaseList_method() {
        String uuid = 'schoola';
        Account account = AccountController.getAccount_uuid(uuid);

        String testEmail = 'email1@invalid-domain.com'; //to get principal contact
        Contact contact = [SELECT id, FirstName, LastName, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: testEmail];
 
         Case sfcase1 = new Case(
            accountid = account.id,
            contactId = contact.id,
            subject = 'test case',
            RecordTypeId = TestClassUtility.getRecordTypeId(Schema.SObjectType.Case, 'Inquiry')
            
        );
        insert sfcase1;

        Case sfcase2 = new Case(
            accountid = account.id,
            contactId = contact.id,
            subject = 'test case',
            RecordTypeId = TestClassUtility.getRecordTypeId(Schema.SObjectType.Case, 'Inquiry'),
            Status = 'Closed'
        );
        insert sfcase2;



        

        List<Case> testCases = CaseController.getAccountCaseList(account.id, true);
        System.assertNotEquals(0, testCases.size()); 

        testCases = CaseController.getAccountCaseList(account.id, false);
        System.assertNotEquals(0, testCases.size()); 

    }

    static testMethod void test_addNewMACsTasksToCase_method() {
        Test.startTest();
        //Get ConfigAutoRecord__c
        List<ConfigAutoRecord__c> configAutoRecords = [SELECT Id, Name, SObjectType__c, Programme__c, Product__c, Case_Owner__c, Case_owner_Queue__c, Type__c FROM ConfigAutoRecord__c WHERE Programme__c = 'MAC'];
        ConfigAutoRecord__c configAutoRecord = configAutoRecords[0];

        system.assertEquals('Complex MAC', configAutoRecord.name);

        User caseOwner = [SELECT Id, Name FROM User LIMIT 1];
        List<Case> cases = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c FROM Case];
        cases[0].ownerId = caseOwner.Id;
        update cases[0];
        system.debug('>>>>>cases'+cases);
        Id testCaseId = cases[0].Id;
        List<id> caseIds = new List<id>();
        caseIds.add(testCaseId);
        
        CaseController.addNewMACsTasksToCase(caseIds);
        
          List<Task> testTasks = [SELECT Id, Subject, Status, Type, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: cases[0].Id ORDER BY Sequence__c];
        system.assertNotEquals(0, testTasks.size());
        Test.stopTest();
        
    

    }
}