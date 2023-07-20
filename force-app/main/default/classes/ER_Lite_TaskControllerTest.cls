@istest
public class ER_Lite_TaskControllerTest {
    @TestSetup
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecords(True); //Parameter False is for not creating Onboarding Case, Tasks, and Contract so that we can test it here.
        
    } 
    
    static testMethod void test_createER_Lite_tasks() {
        Test.startTest();
        //Get ConfigAutoRecord__c
        List<ConfigAutoRecord__c> configAutoRecords = [SELECT Id, Name, SObjectType__c, Programme__c, Product__c, Case_Owner__c, Case_owner_Queue__c, Type__c, Product_variation__c FROM ConfigAutoRecord__c WHERE Product_variation__c = 'ER Lite'];
        ConfigAutoRecord__c configAutoRecord = configAutoRecords[0];
        
        system.assertEquals('ER Lite', configAutoRecord.name);
        
        User caseOwner = [SELECT Id, Name FROM User LIMIT 1];
        List<Case> cases = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c FROM Case];
        cases[0].ownerId = caseOwner.Id;
        update cases[0];
        system.debug('>>>>>cases'+cases);
        Id testCaseId = cases[0].Id;
        List<id> caseIds = new List<id>();
        caseIds.add(testCaseId);
        
        ER_Lite_TaskController.createER_Lite_tasks(caseIds);
         
        List<Task> testTasks = [SELECT Id, Subject, Status, Type, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: cases[0].Id ORDER BY Sequence__c];
        Test.stopTest();
        system.assertNotEquals(0, testTasks.size());
        
        
    }
}