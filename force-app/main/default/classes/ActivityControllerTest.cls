@IsTest
public with sharing class ActivityControllerTest {
 @TestSetup
    private static void setup(){
        
        //create account
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        schoolAccount.uuid__c = 'schoola'; //for reporting test
        schoolAccount.MoE_School_ID__c = '100';
        insert schoolAccount;

        //there is a process/trigger on account that automatically create a principal contact at the time account record is created
		List<Contact> contacts = [SELECT id, name, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE AccountId =: schoolAccount.id and Current_Principal_Of_This_School__c = true];
        if (contacts.size()==1){
            Contact principalContact = contacts[0];
            principalContact.FirstName = 'FirstName1';
            principalContact.LastName = 'LastName1';
            principalContact.Email = 'email1@invalid-domain.com';
            update principalContact;
        } else {
            //create contacts in the school
            Contact principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
            insert principalContact;    
        }
        

        Contact schoolContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName2', 'LastName2', 'email2@invalid-domain.com', '02722222222', 'ICT Leader', False);
        insert schoolContact;

        //create internal user - relationship manager
        User rmUser = TestClassUtility.createInternalUser(); //email is internaluser@invalid-domain.com
        rmUser.UserPermissionsSchoolReportingUser__c = true; //allow user to getAccessibleSchools for School Reporting
        insert rmUser;


	}

    static testMethod void test_getTaskList_method() {
        String uuid = 'schoola';
        Account account = AccountController.getAccount_uuid(uuid);

        String testEmail = 'email1@invalid-domain.com'; //to get principal contact
        Contact contact = [SELECT id, FirstName, LastName, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: testEmail];

        Task task1 = new Task(
            whatId = account.id,
            whoId = contact.id,
            subject = 'test task 1'
        );
        insert task1;

        Task task2 = new Task(
            whatId = account.id,
            whoId = contact.id,
            subject = 'test task 2',
            status = 'Completed'
        );
        insert task2;


        List<Task> testResults = ActivityController.getTaskList(account.id, true);
        //System.assertEquals(1, testResults.size()); //n4l

        testResults = ActivityController.getTaskList(account.id, false);
        System.assertEquals(2, testResults.size()); 

    }

    static testMethod void test_createTaskRecord_method() {
        String uuid = 'schoola';
        Account account = AccountController.getAccount_uuid(uuid);

        String testEmail = 'email1@invalid-domain.com'; //to get principal contact
        Contact contact = [SELECT id, FirstName, LastName, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: testEmail];

        Map<string, object> fieldsMap = new Map<string, object>();
        fieldsMap.put('Subject','This is subject');
        fieldsMap.put('Status','In Progress');
        fieldsMap.put('ActivityDate','2019-01-01');
        fieldsMap.put('OwnerId','0050o00000Vd2SaAAJ');
        fieldsMap.put('WhatId',account.id);
        fieldsMap.put('Description','This is decription');


        Task task = ActivityController.createTaskRecord(fieldsMap);
         System.assertEquals(account.id, task.whatId); 

        List<Task> testResults = ActivityController.getTaskList(account.id, true);
        System.assertEquals(1, testResults.size()); 

       
    }


    static testMethod void test_getEventList_method() {
        String uuid = 'schoola';
        Account account = AccountController.getAccount_uuid(uuid);

        String testEmail = 'email1@invalid-domain.com'; //to get principal contact
        Contact contact = [SELECT id, FirstName, LastName, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: testEmail];

        Event event1 = new Event(
            whatId = account.id,
            whoId = contact.id,
            subject = 'test event 1',
            ActivityDate = date.today(),
            ActivityDateTime = datetime.now(),
            DurationInMinutes = 60
        );
        insert event1;

        Event event2 = new Event(
            whatId = account.id,
            whoId = contact.id,
            subject = 'test task 2',
            ActivityDate = date.today(),
            ActivityDateTime = datetime.now(),
            DurationInMinutes = 60,
            Event_Closed__c = true
        );
        insert event2;


        List<Event> testResults = ActivityController.getEventList(account.id, true);
        System.assertEquals(1, testResults.size()); 

        testResults = ActivityController.getEventList(account.id, false);
        System.assertEquals(2, testResults.size()); 

    }

     static testMethod void test_upsertEventRecord_method() {
        String uuid = 'schoola';
        Account account = AccountController.getAccount_uuid(uuid);

        String testEmail = 'email1@invalid-domain.com'; //to get principal contact
        Contact contact = [SELECT id, FirstName, LastName, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: testEmail];

        Event event1 = new Event(
            whatId = account.id,
            whoId = contact.id,
            subject = 'test event 1',
            ActivityDate = date.today(),
            ActivityDateTime = datetime.now(),
            DurationInMinutes = 60
        );
        insert event1;
        
        Map<string, object> fieldsMap = new Map<string, object>();
        //prepare for update
        fieldsMap.put('id',event1.Id);
        fieldsMap.put('description','This is description');
        fieldsMap.put('driver','This is driver');
        fieldsMap.put('notes','This is notes');
        
        
        //use upsert to update event record
        Event testEvent = ActivityController.upsertEventRecord(fieldsMap);
        System.assertEquals(account.id, testEvent.whatId); 
        System.assertEquals('test event 1', testEvent.Subject);   //remain unchanged
        System.assertEquals('This is description', testEvent.Description); 
        System.assertEquals('This is driver', testEvent.Driver__c); 
        System.assertEquals('This is notes', testEvent.Notes__c); 
    }
}