@IsTest
public class ServiceEventCaseControllerTest {
    @TestSetup
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecords(False); //Parameter False is for not creating Onboarding Case, Tasks, and Contract we don't need them here in these test.
    }
    static testMethod void test_ServiceRequestWebFiltering_success(){
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];

        ServiceEventWrapper event = new ServiceEventWrapper();
        event.eventId = UUIDGenerator.Version4UUIDGenerator(null); 
        event.header.eventType = 'ServiceRequestWebFiltering';
        event.header.action = 'create';
        event.header.replayId = 1;
        event.header.eventDate = datetime.now();
        event.header.internalReferenceId = UUIDGenerator.Version4UUIDGenerator(null);
        event.header.origin = 'Platform Services';
        
        ServiceEventWrapper.Data_ServiceRequestWebFiltering data = new ServiceEventWrapper.Data_ServiceRequestWebFiltering();
        data.subject = 'this is subject';
        data.description = 'this is description';
        data.accountId = account.id;
        data.contactId = contact.id;
        
        event.data = data; //casting to inherited component
        
        event.whenCreated =  datetime.now();

        
        test.startTest();
        ApiResponse result = ServiceEventCaseController.ServiceRequestWebFiltering(event);
        system.assertEquals(200, result.statusCode);

        test.stopTest();

        //a case should be created
        List<Case> cases = [SELECT Id, Subject, Description, AccountId, ContactId, Status, Product__c, Call_Driver__c, Origin, Priority, uuid__c, OwnerId, RecordTypeId FROM Case WHERE AccountId =: account.id];
        Case testCase = cases[0];
        system.assertEquals(Helper.getRecordTypeId(Schema.SObjectType.Case, 'Service Request'), testCase.RecordTypeId );
        system.assertEquals(event.header.internalReferenceId, testCase.uuid__c);
        system.assertEquals(data.subject, testCase.Subject);
        system.assertEquals(data.description, testCase.Description);
        system.assertEquals(data.accountId, testCase.AccountId);
        system.assertEquals(data.contactId, testCase.ContactId);

        system.assertEquals(result.record.Id, testCase.Id);

        
        List<Group> queues = [SELECT Id, Name FROM Group WHERE Name = 'Helpdesk Queue' LIMIT 1];
        system.assertEquals(queues[0].Id, testCase.ownerId);
    }

    static testMethod void test_ServiceRequestWebFiltering_error(){
        ServiceEventWrapper event = new ServiceEventWrapper();
        //empty event should cause an error
        ApiResponse result = ServiceEventCaseController.ServiceRequestWebFiltering(event);
        system.assertEquals(500, result.statusCode);

        
        //change the queue name to an invalid name so that it can cause the error below
        List<Group> queues = [SELECT Id, Name FROM Group WHERE Name = 'Helpdesk Queue' LIMIT 1];
        Group queue = queues[0];
        queue.Name = 'Invalid Name';
        update queue;

        result = ServiceEventCaseController.ServiceRequestWebFiltering(event);
        system.assertEquals(500, result.statusCode);
    }

}