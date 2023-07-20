@IsTest
public with sharing class TriggerOnTaskHandlerTest {
    @TestSetup
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
    }
    static testMethod void caseTaskTest(){
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Contract contract = [SELECT Id, AccountId FROM Contract WHERE Id =: opportunity.ContractId];
        Case testCase = [SELECT Id, Subject, RecordType.Name, OwnerId, contract__r.id, ContactId, Secondary_Contact__c, Install_Provider__r.Name FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
        List<Task> testTasks = [SELECT Id, Subject, Status, Type, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: testCase.Id ORDER BY Sequence__c];
        task t = testTasks[0];
        t.Status='test finished';
        update t;
        list<Task_History__c> thlist = [select id,Parent_Task_ID__c from Task_History__c where Parent_Task_ID__c=:t.id ];
        system.assertEquals(1, thlist.size());
    }
}