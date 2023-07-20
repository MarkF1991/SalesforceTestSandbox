/**
* @author Kamal Lamgade (kamal.lamgade@n4l.co.nz)
* @date 2021-07-12
* @test: installer selected for a Design to be reflected on the linked Salesforce Onboarding Case(#MNTC-520)
* CHANGE LOG
**/
@isTest
public class ServiceEventNDQInstallerAssignedTest {
    @TestSetup
    private static void setup(){
     Case onBoardingCase = new Case();
     onBoardingCase.Subject = 'test installerassigned';
     Task testTask = new Task();
     testTask.Type = 'Assign Installer';
     insert onBoardingCase;
     testTask.WhatId = onBoardingCase.Id;
     insert testTask;
     Account account = new Account();
     account.uuid__c = '0015P00000BUu1mQAD';
     account.Name = 'Test Vitel Cabling Ltd';
     insert account;
     }
     
     @isTest
    static  void test_getCaseById_valid(){
        //arrange
          String subject = 'test installerassigned';
          List<Case> cases = [ SELECT Id, Status FROM Case WHERE Subject = :'test installerassigned'];
          Case expectedCase = cases[0];
          //act
          Test.startTest();
          Case actualCase = ServiceEventNDQInstallerAssigned.getCaseById(expectedCase.Id); 
          Test.stopTest();
          //assert
          System.assertEquals(expectedCase, actualCase, 'case with correct caseId is found');
    }

   @isTest
    static void test_getTaskByType_valid(){
          //arrange
          List<Case> cases = [ SELECT Id, Status FROM Case WHERE Subject = :'test installerassigned'];
          Case caseRetrieved = cases[0];
          String taskType = 'Assign Installer';
          List<Task> tasks = [ SELECT Id, Status, WhatId FROM Task WHERE Type =:taskType AND WhatId = :caseRetrieved.Id];
          Task expectedTask = tasks[0];
          //act
          Test.startTest();
          Task taskRetrieved = ServiceEventNDQInstallerAssigned.getTaskByType(taskType, caseRetrieved.Id); 
          Test.stopTest();
          //assert
          System.assertEquals(expectedTask, taskRetrieved, 'task with correct taskId is found');
 }

     @isTest
     static void test_execute_valid() {
          //arrange
          ServiceEventNDQInstallerAssigned.InstallerAssignedQueueable queueHandler = getQueueHandler();        
          Account schoolAccount = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];      
          Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: schoolAccount.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaign in Test Setup Method above
          Contract contract = [SELECT Id FROM Contract WHERE Id =: opportunity.ContractId];
          Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, Install_Provider__r.Name, Install_Provider__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
          List<Task> tasks = [ SELECT Id, Status, WhatId FROM Task WHERE Type = 'Assign Installer' AND WhatId = :onboardingCase.Id];
          Task expectedTask = tasks[0];
          Task task = tasks[0];
          //act
          Test.startTest(); 
          System.enqueueJob(queueHandler);
          Test.stopTest();
          //assert
          String taskType = 'Assign Installer';
          Task taskRetrieved = ServiceEventNDQInstallerAssigned.getTaskByType(taskType, onboardingCase.Id);
          System.debug('taskRetrieved in test '+ taskRetrieved);
          Case caseRetrieved = [ SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, Install_Provider__r.Name, Install_Provider__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
          System.debug('caseRetrieved in test '+ caseRetrieved);
          System.assertEquals(taskRetrieved.WhatId, onboardingCase.Id);
          System.assertEquals('Completed', taskRetrieved.Status);
     }
     
     public static ServiceEventNDQInstallerAssigned.InstallerAssignedQueueable getQueueHandler() {
          TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
          Account schoolAccount = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];      
          Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: schoolAccount.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaign in Test Setup Method above
          Contract contract = [SELECT Id FROM Contract WHERE Id =: opportunity.ContractId];
          Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, Install_Provider__r.Name FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
        
          ServiceEventWrapper event = new ServiceEventWrapper();
          event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
          event.header.eventType = 'NetworkDesign';
          event.header.action = 'link';
          event.header.replayId = 1;
          event.header.eventDate = datetime.now();
          event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
          event.header.origin = 'Platform Services';

     //get response body from Static Resource
        StaticResource staticResource = [SELECT Id, Body FROM StaticResource WHERE Name = 'ServiceEventNDWrapperMock' LIMIT 1];
        String json = staticResource.Body.toString();
        json = json.replace('"salesforceCaseId": "5005O000001Fet1QAC",', '"salesforceCaseId": "' + onboardingCase.Id + '",');
        json = json.replace('"schoolId": "697c296d-bc7d-47b7-8d02-3df3ee9e98b9",', '"schoolId": "schoola",');
        json = json.replace('"assignedTo": "0050o00000Vd2SaAAJ",', '"assignedTo": "' + onboardingCase.OwnerId + '",');
        ServiceEventWrapper.Data_NetworkDesign data = new ServiceEventWrapper.Data_NetworkDesign();

        data.networkDesign = ServiceEventNDWrapper.parse(json);
        data.networkDesign.implementation =  new ServiceEventNDWrapper.Implementation();
        data.networkDesign.implementation.salesforceProviderId =  '0015P00000BUu1mQAD';
        event.data = data; 
        event.whenCreated =  datetime.now();
        ServiceEventNDQInstallerAssigned.InstallerAssignedQueueable queue = new ServiceEventNDQInstallerAssigned.InstallerAssignedQueueable(event);
        return queue;
     }
}