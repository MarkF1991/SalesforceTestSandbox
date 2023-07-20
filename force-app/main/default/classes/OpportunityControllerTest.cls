@IsTest
public with sharing class OpportunityControllerTest {
    @TestSetup
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecords(False); //Parameter False is for not creating Onboarding Case, Tasks, and Contract so that we can test it here.
    }

    public static testMethod void test_getAccountOpportunityList() {
        List<Account> accounts = [SELECT id, Name FROM Account];      
        Account account = accounts[0];
        
        List<Opportunity> opportunities = OpportunityController.getAccountOpportunityList(account.Id);
        system.assertEquals(5, opportunities.size());
    }

    public static testMethod void test_InvocableMethod_GenerateOnboardingRecords() {
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Opportunity opportunity = [SELECT Id, opportunity.Campaign.Programme__c, opportunity.Campaign.type, opportunity.Campaign.Product__c, Name FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above

        //Get ConfigAutoRecord__c
        List<ConfigAutoRecord__c> configAutoRecords = [SELECT Id, Name, SObjectType__c, Programme__c, Product__c, Case_Owner__c, Case_owner_Queue__c, Type__c FROM ConfigAutoRecord__c WHERE Programme__c =: opportunity.Campaign.Programme__c AND Product__c =: opportunity.Campaign.Product__c AND Type__c =: opportunity.Campaign.Type];
        ConfigAutoRecord__c configAutoRecord = configAutoRecords[0];
        
        List<ID> ids = new List<ID>();
        ids.add(opportunity.id);
        OpportunityController.InvocableMethod_GenerateOnboardingRecords(ids);
        //just do a simple test here to ensure the InvocalbeMethod works. Refer to testMethod: test_generateOnboardingRecords for more details.
        //verify onboarding case has been created
        List<Case> cases = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c FROM Case];
        Case testCase = cases[0];
        
        Group caseOwnerQueue = [SELECT id, name, type FROM Group WHERE type = 'Queue' AND name = 'Test Queue'];
        system.assertEquals(opportunity.Name + ' Onboarding', testCase.Subject); //expecting cannot find records for ConfigAutoRecord__c
        system.assertEquals('Onboarding', testCase.RecordType.Name);
        system.assertEquals(caseOwnerQueue.Id, testCase.OwnerId); 
    }
    
    public static testMethod void test_generateOnboardingRecords() {
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        
        Opportunity opportunity = [SELECT Id, Name, Campaign.Programme__c, Campaign.Product__c, Campaign.Type FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        
         //Get ConfigAutoRecord__c
        List<ConfigAutoRecord__c> configAutoRecords = [SELECT Id, Name, SObjectType__c, Programme__c, Product__c, Case_Owner__c, Case_owner_Queue__c, Type__c FROM ConfigAutoRecord__c WHERE Programme__c =: opportunity.Campaign.Programme__c AND Product__c =: opportunity.Campaign.Product__c AND Type__c =: opportunity.Campaign.Type];
        ConfigAutoRecord__c configAutoRecord = configAutoRecords[0];
        
        MethodResponse res = OpportunityController.generateOnboardingRecords(opportunity.Id);
        system.assertEquals(201, res.statuscode); //expecting cannot find records for ConfigAutoRecord__c

        //get OpportunityContactRole to test Primary Contact, Secondary Contact, Authorised Signatory
        Map<String, OpportunityContactRole> opportunityContactRoleMap = new Map<String, OpportunityContactRole>();
        List<OpportunityContactRole> opportunityContactRoles = [SELECT Id, ContactId, Contact.Email, Contact.MobilePhone, Contact.Phone, OpportunityId, Role FROM OpportunityContactRole WHERE OpportunityId =: opportunity.Id ];
        for (OpportunityContactRole opportunityContactRole : opportunityContactRoles){
            opportunityContactRoleMap.put(opportunityContactRole.Role, opportunityContactRole); //prepare map for Get OpportunityContactRole by Role.
        }

        //verify onboarding case has been created
        List<Case> cases = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, Programme__c, Product__c FROM Case];
        Case testCase = cases[0];
        Group caseOwnerQueue = [SELECT id, name, type FROM Group WHERE type = 'Queue' AND name = 'Test Queue'];
        system.assertEquals(opportunity.Name + ' Onboarding', testCase.Subject); //expecting cannot find records for ConfigAutoRecord__c
        system.assertEquals('Onboarding', testCase.RecordType.Name);
         system.assertEquals(caseOwnerQueue.Id, testCase.OwnerId); 
        system.assertEquals(opportunity.Campaign.Programme__c, testCase.Programme__c); //NP-939
        system.assertEquals(opportunity.Campaign.Product__c, testCase.Product__c); //NP-939

        OpportunityContactRole rolePrimaryContact = opportunityContactRoleMap.get('Primary Contact');
        system.assertEquals(rolePrimaryContact.ContactId, testCase.ContactId); //Case.ContactId (primary contact), should be the contactId of the 'Primary Contact' role

        OpportunityContactRole roleSecondaryContact = opportunityContactRoleMap.get('Secondary Contact');
        system.assertEquals(roleSecondaryContact.ContactId, testCase.Secondary_Contact__c); //Case.Secondary_Contact__c , should be the contactId of the 'Secondary Contact' role

        //Get TaskTemplate__c
        List<TaskTemplate__c> taskTemplates = [SELECT Id, Name, ConfigAutoRecord__c, Owner__c, Status__c, Type__c, Sequence__c, RecordTypeName__c FROM TaskTemplate__c WHERE ConfigAutoRecord__c =: configAutoRecord.Id ORDER BY Sequence__c];
        
        //verify 17 onboarding Tasks have been created
        //list Onboarding Tasks under Onboarding Case
        List<Task> testTasks = [SELECT Id, Subject, Status, Type, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: testCase.Id ORDER BY Sequence__c];
        //system.debug('>>>>>> JSON.serialize(testTasks) ' + JSON.serialize(testTasks));
        system.assertEquals(taskTemplates.size(), testTasks.size()); //the number of created onboarding tasks, should be the same as number of taskTemplates of this configAutoRecords.


        Group queueNHR = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = 'NSE/NHR Provisioning Queue' LIMIT 1];
        
        //based on TestObjectFactoryForOnboarding, the first item is ('Technical Survey', 'In Progress', '005', 'Onboarding', 'NSE/NHR Provisioning Queue')
        system.assertEquals('005', testTasks[0].Sequence__c); //the onboarding task's sequence should be the same as taskTemplate's sequence
        system.assertEquals('Technical Survey', testTasks[0].Type); //the onboarding task's Type should be the same as taskTemplate's Type
        //system.assertEquals('NSE/NHR Provisioning Queue', testTasks[0].Owner.Name); //for some reason Owner.Name does not appear in in the SOQL above during execution. Therefore, don't use it to compare. User OwnerId instead.
        system.assertEquals(queueNHR.Id, testTasks[0].OwnerId);
        
        //based on TestObjectFactoryForOnboarding, the fifth item is ('Assign Installer', 'Not Started', '021', 'Onboarding', 'Case Owner')
        system.assertEquals('021', testTasks[4].Sequence__c); 
        system.assertEquals('Assign Installer', testTasks[4].Type);
        system.assertEquals(testCase.OwnerId, testTasks[4].OwnerId);

        //verify a Contract has been created
        List<Contract> contracts  = [SELECT Id, Name, AccountId, CustomerSignedId  FROM Contract WHERE AccountId =: account.id];
        system.assertEquals(1, contracts.size()); //should have 1 contract 
        Contract testContract  = contracts[0]; //get the first contract

        OpportunityContactRole roleSignatoryContact = opportunityContactRoleMap.get('Authorised Signatory');
        system.assertEquals(roleSignatoryContact.ContactId, testContract.CustomerSignedId); //customerSignedId should be the contact id of the Authorised Signatory role

        //refresh, so that we can verify that Opportunity is now linked to the Contract
        Opportunity testOpportunity = [SELECT id, Name, ContractId FROM Opportunity WHERE Id =: opportunity.Id]; 
        system.assertEquals(testContract.Id, testOpportunity.ContractId);

        //call generateOnboardingRecords one more time to make sure that it does not create another case.
        MethodResponse res2 = OpportunityController.generateOnboardingRecords(opportunity.Id);
        List<Case> cases2 = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, Programme__c, Product__c FROM Case];
        system.assertEquals(1, cases2.size()); //should still have 1 case 

        List<Contract> contracts2  = [SELECT Id, Name, AccountId, CustomerSignedId  FROM Contract WHERE AccountId =: account.id];
        system.assertEquals(1, contracts2.size()); //should still have 1 contract 
    }

    public static testMethod void test_generateOnboardingRecords_CaseOnly() {
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        
        Opportunity opportunity = [SELECT Id, Name, Campaign.Programme__c, Campaign.Product__c, Campaign.Type FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NSE (Pilot)']; //refer to createCampaing in Test Setup Method above
        
        //Get ConfigAutoRecord__c
        List<ConfigAutoRecord__c> configAutoRecords = [SELECT Id, Name, SObjectType__c, Programme__c, Product__c, Case_Owner__c, Case_owner_Queue__c, Type__c FROM ConfigAutoRecord__c WHERE Programme__c =: opportunity.Campaign.Programme__c AND Product__c =: opportunity.Campaign.Product__c AND Type__c =: opportunity.Campaign.Type];
        ConfigAutoRecord__c configAutoRecord = configAutoRecords[0];
        
        MethodResponse res = OpportunityController.generateOnboardingRecords(opportunity.Id);
        system.assertEquals(201, res.statuscode); //expecting cannot find records for ConfigAutoRecord__c

        // //get OpportunityContactRole to test Primary Contact, Secondary Contact, Authorised Signatory
        // Map<String, OpportunityContactRole> opportunityContactRoleMap = new Map<String, OpportunityContactRole>();
        // List<OpportunityContactRole> opportunityContactRoles = [SELECT Id, ContactId, Contact.Email, Contact.MobilePhone, Contact.Phone, OpportunityId, Role FROM OpportunityContactRole WHERE OpportunityId =: opportunity.Id ];
        // for (OpportunityContactRole opportunityContactRole : opportunityContactRoles){
        //     opportunityContactRoleMap.put(opportunityContactRole.Role, opportunityContactRole); //prepare map for Get OpportunityContactRole by Role.
        // }

        //verify onboarding case has been created
        List<Case> cases = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, Programme__c, Product__c FROM Case];
        Case testCase = cases[0];
        Group caseOwnerQueue = [SELECT id, name, type FROM Group WHERE type = 'Queue' AND name = 'Test Queue'];
        
        system.assertEquals(opportunity.Name + ' Onboarding', testCase.Subject); //expecting cannot find records for ConfigAutoRecord__c
        system.assertEquals('Onboarding', testCase.RecordType.Name);
     system.assertEquals(caseOwnerQueue.Id, testCase.OwnerId);
        system.assertEquals(opportunity.Campaign.Programme__c, testCase.Programme__c); //NP-939
        system.assertEquals(opportunity.Campaign.Product__c, testCase.Product__c); //NP-939

        system.assertEquals(null, testCase.ContactId); //Case.ContactId (primary contact), should be null as there was no 'Primary Contact' role
        system.assertEquals(null, testCase.Secondary_Contact__c); //Case.Secondary_Contact__c , should be null as there was no 'Secondary Contact' role
        

        //verify 0 onboarding Tasks have been created
        //list Onboarding Tasks under Onboarding Case
        List<Task> testTasks = [SELECT Id, Subject, Status, Type, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: testCase.Id ORDER BY Sequence__c];
        system.assertEquals(0, testTasks.size());

        //verify 0 contract record
        List<Contract> testContracts  = [SELECT Id, Name, AccountId, CustomerSignedId  FROM Contract WHERE AccountId =: account.id];
        system.assertEquals(0, testContracts.size());


        //call generateOnboardingRecords one more time to make sure that it does not create another case.
        MethodResponse res2 = OpportunityController.generateOnboardingRecords(opportunity.Id);
        List<Case> cases2 = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c FROM Case];
        system.assertEquals(1, cases2.size()); //should still have 1 case 
    }

    public static testMethod void generateOnboardingRecords_test_negative1() {
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        
        //clear record ConfigAutoRecord__c so that this return 404
        List<ConfigAutoRecord__c> configAutoRecords = [SELECT Id FROM ConfigAutoRecord__c];
        delete configAutoRecords;

        MethodResponse res = OpportunityController.generateOnboardingRecords(opportunity.Id);
        system.assertEquals(404, res.statuscode); //expecting cannot find records for ConfigAutoRecord__c
    }

    public static testMethod void generateOnboardingRecords_test_negative2() {
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        
        //clear record ConfigAutoRecord__c so that this return 404
        List<TaskTemplate__c> taskTemplates = [SELECT Id FROM TaskTemplate__c];
        delete taskTemplates;

        MethodResponse res = OpportunityController.generateOnboardingRecords(opportunity.Id);
        system.assertEquals(404, res.statuscode); //expecting cannot find records for ConfigAutoRecord__c
    }


}