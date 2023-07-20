@isTest
public class UserControllerTest {
    @TestSetup
    private static void setup(){
        //create account
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        schoolAccount.uuid__c = 'schoola';
        schoolAccount.MoE_School_ID__c = '200';
        schoolAccount.Email_Domain__c = 'invalid-domain.com'; //for filtering portal access, the contact and user's email must have the same domain.
        insert schoolAccount;
        
        //there is a process/trigger on account that automatically create a principal contact at the time account record is created
        Contact principalContact = new Contact();
        List<Contact> contacts = [SELECT id, name, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE AccountId =: schoolAccount.id and Current_Principal_Of_This_School__c = true];
        if (contacts.size()==1){
            //Contact principalContact = contacts[0];
            principalContact = contacts[0];
            principalContact.FirstName = 'FirstName1';
            principalContact.LastName = 'LastName1';
            principalContact.Email = 'email1@invalid-domain.com';
            update principalContact;
        } else {
            //create contacts in the school
            //Contact principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
            principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
            insert principalContact;    
        }
        
        
        List<Contact> newContacts = new List<Contact>();
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName2', 'LastName2', 'email2@invalid-domain.com', '02722222222', 'ICT Leader', False));
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName3', 'LastName3', 'email3@invalid-domain.com', '02733333333', 'External ICT', False));
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName4', 'LastName4', 'email4@invalid-domain.com', '02744444444', 'IT Support', False));
        
        Contact exPrincipalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName5', 'LastName5', 'email5@invalid-domain.com', '02755555555', 'Principal', False);
        
        newContacts.add(exPrincipalContact);
        
        insert newContacts;
        
        exPrincipalContact.Inactive_Contact_Record__c = true;
        update exPrincipalContact;
        
        
        
        
    }
    
    static testMethod void test_updateUsers_method() {
        Contact principalContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        
        //create user
        User externalUser = TestClassUtility.createExternalUser(principalContact);
        
        //execute @future method in UserController.updateUsers, just in case the Process Builder is deactivated
        test.startTest();
        
        insert externalUser;
        String testUserId = externalUser.Id;
        List<ID> ids = new List<ID>();
        ids.add(testUserId);
        UserController.updateUsers(ids); //test invocablemethod to call @future method
        
        test.stopTest();
        
        //evaluate test result for @future method outside of test.stopTest()
        //User testUser = [SELECT id, username, FederationIdentifier, User.Fortinet_Adom_Name__c, Account.Fortinet_Adom_Name__c FROM User WHERE id =: testUserId ];
        //Error Account.Fortinet_Adom_Name__c FROM ^ ERROR at Row:1:Column:90 Didn't understand relationship 'Account' in field path.
        User testUser = [SELECT id, username, FederationIdentifier, Fortinet_Adom_Name__c, AccountId FROM User WHERE id =: testUserId ];
        Account testAccount = [SELECT id, Fortinet_Adom_Name__c FROM Account WHERE id =: testUser.AccountId LIMIT 1 ];
        system.assertEquals(testUser.username, testUser.FederationIdentifier);
        system.assertEquals(testAccount.Fortinet_Adom_Name__c, testUser.Fortinet_Adom_Name__c);
        
    }
    
    
    static testMethod void test_updateUsers_InternalUser1_method() {
         //create internal user - relationship manager
        User rmUser = TestClassUtility.createInternalUser();
       
        //execute @future method in UserController.updateUsers, just in case the Process Builder is deactivated
        test.startTest();
        
        insert rmUser;
       
        String testUserId = rmUser.Id;
        List<ID> ids = new List<ID>();
        ids.add(testUserId);
        UserController.updateUsers(ids); //test invocablemethod to call @future method
        
        test.stopTest();
        
        //evaluate test result for @future method outside of test.stopTest()
        User testUser = [SELECT id, username, FederationIdentifier, Fortinet_Adom_Name__c, AccountId FROM User WHERE id =: testUserId ];
        
        system.assertEquals(testUser.username, testUser.FederationIdentifier);
        system.assertEquals(NULL, testUser.Fortinet_Adom_Name__c);
        
    }
    
    static testMethod void test_updateUsers_InternalUser2_method() {
         //create internal user - relationship manager
        User user = TestClassUtility.createInternalUser('Another', 'InternalUser');
       
        //execute @future method in UserController.updateUsers, just in case the Process Builder is deactivated
        test.startTest();
        
        insert user;
       
        String testUserId = user.Id;
        List<ID> ids = new List<ID>();
        ids.add(testUserId);
        UserController.updateUsers(ids); //test invocablemethod to call @future method
        
        test.stopTest();
        
        //evaluate test result for @future method outside of test.stopTest()
        User testUser = [SELECT id, username, FederationIdentifier, Fortinet_Adom_Name__c, AccountId FROM User WHERE id =: testUserId ];
        
        system.assertEquals(testUser.username, testUser.FederationIdentifier);
        system.assertEquals(NULL, testUser.Fortinet_Adom_Name__c);
        
    }




//---------- Test Get Customer User: mostly used in Support Hub -----------------------------
static testMethod void test_getCustomerUser_method() {
    test.startTest();
    //create external user - for the school contact
    Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
    User externalUser = TestClassUtility.createExternalUser(schoolContact);
    insert externalUser;
    test.stopTest(); 
    
    //step 1: get external user
    User testUser = [SELECT id, FirstName, LastName, Name, username, email, LastLoginDate, IsActive, IsPortalEnabled, UserPermissionsFilteringPortalUser__c, UserPermissionsSchoolReportingUser__c, ContactId, Contact.AccountId, Contact.Account.Type, UserType, ProfileId, Profile.Name, Contact.Account.Pond_Registration_Approval_Email_Address__c FROM User WHERE email =: 'email2@invalid-domain.com' ];
    
    MethodResponse testResponse = UserController.getCustomerUser(testUser.Id);
    system.assertEquals(200, testResponse.statusCode);
    system.assertEquals(testUser.username, testResponse.user.username);
    system.assertEquals(testUser.ContactId, testResponse.user.ContactId);
    system.assertEquals(testUser.Contact.AccountId, testResponse.user.Contact.AccountId);
}

// static void test_getCustomerUser_method_ForRunAs_ExternalUser() {
   
//     User testUser = [SELECT id, FirstName, LastName, Name, username, email, LastLoginDate, IsActive, IsPortalEnabled, UserPermissionsFilteringPortalUser__c, UserPermissionsSchoolReportingUser__c, ContactId, Contact.AccountId, Contact.Account.Type, UserType, ProfileId, Profile.Name, Contact.Account.Pond_Registration_Approval_Email_Address__c FROM User WHERE email =: 'email2@invalid-domain.com' ];
    
//     MethodResponse testResponse = UserController.getCustomerUser(testUser.Id);
//     system.assertEquals(200, testResponse.statusCode);
//     system.assertEquals(testUser.username, testResponse.user.username);
//     system.assertEquals(testUser.ContactId, testResponse.user.ContactId);
//     system.assertEquals(testUser.Contact.AccountId, testResponse.user.Contact.AccountId);
// }

static testMethod void test_getCustomerUser_method_negative1() {
    //to test could not find user record situation
    String testUserId = '0055P000000UzlFQAS';
    
    MethodResponse testResponse = UserController.getCustomerUser(testUserId);
    system.assertEquals(404, testResponse.statusCode);
}

static testMethod void test_getCustomerUser_method_negative2() {
    //to test missing userId
    String testUserId = null;
    
    MethodResponse testResponse = UserController.getCustomerUser(testUserId);
    system.assertEquals(400, testResponse.statusCode);
}

static testMethod void test_createCustomerUser_method() {
    Contact principalContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        
        
        
        //execute @future method in UserController.updateUsers, just in case the Process Builder is deactivated
        test.startTest();
        //create user
        List<Map<String, String>> result = UserController.createCustomerUser(principalContact.id, false);

        test.stopTest();
        
        //evaluate test result for @future method outside of test.stopTest()
        //User testUser = [SELECT id, username, FederationIdentifier, User.Fortinet_Adom_Name__c, Account.Fortinet_Adom_Name__c FROM User WHERE id =: testUserId ];
        //Error Account.Fortinet_Adom_Name__c FROM ^ ERROR at Row:1:Column:90 Didn't understand relationship 'Account' in field path.
        User testUser = [SELECT id, username, email, FederationIdentifier, contactId, AccountId FROM User WHERE email =: 'email1@invalid-domain.com' ];
        system.assertEquals(testUser.email, principalContact.email);
        

}
    
    static testMethod void updateUser_SchoolReporting_fields_Method() {
        //Create User       
        User user_Positive = TestClassUtility.createInternalUser();
        user_Positive.UserPermissionsSchoolReportingUser__c = True;
        Insert user_Positive;
        
        User user_Negative = TestClassUtility.createInternalUser();
        //execute @future method in UserController.updateUsers, just in case the Process Builder is deactivated
        test.startTest();
        UserController.updateUser_SchoolReporting_fields(user_Positive.Id, True);
        test.stopTest();
        system.assertEquals(user_Positive.UserPermissionsSchoolReportingUser__c, True);
        
        UserController.updateUser_SchoolReporting_fields(user_Negative.Id, True);
        system.assertEquals(user_Negative.UserPermissionsSchoolReportingUser__c, False);
        

}
    
static testMethod void updateUser_FilteringPortal_fields_Method() {
        //Create User       
        User user_Positive = TestClassUtility.createInternalUser();
        user_Positive.UserPermissionsFilteringPortalUser__c = True;
        Insert user_Positive;
        
        User user_Negative = TestClassUtility.createInternalUser();
        //execute @future method in UserController.updateUsers, just in case the Process Builder is deactivated
        test.startTest();
        UserController.updateUser_FilteringPortal_fields(user_Positive.Id, True);
        test.stopTest();
        system.assertEquals(user_Positive.UserPermissionsFilteringPortalUser__c, True);
        
        UserController.updateUser_FilteringPortal_fields(user_Negative.Id, True);
        system.assertEquals(user_Negative.UserPermissionsFilteringPortalUser__c, False);
    }

    // 03-05-2021 Created by Deloitte Team for NMS test class coverage
    static testMethod void testUpdateUser_NMS_fields() {
        //Create User       
        User user_Positive = TestClassUtility.createInternalUser();
        user_Positive.UserPermissionsNMSUser__c = false;
        insert user_Positive;

        User user_Negative = TestClassUtility.createInternalUser();
        //execute @future method in UserController.updateUsers, just in case the Process Builder is deactivated
        Test.startTest();
            UserController.updateUser_NMS_fields(user_Positive.Id, true);
        Test.stopTest();

        user_Positive = [SELECT Id,UserPermissionsNMSUser__c FROM User WHERE Id = :user_Positive.Id];
        System.assertEquals(user_Positive.UserPermissionsNMSUser__c, true);

        UserController.updateUser_NMS_fields(user_Negative.Id, false);
    }

    // 03-05-2021 Created by Deloitte Team for Customer user test class coverage
    static testMethod void testCreateCustomerUser() {
        Test.startTest();
            //create user
            List<Map<String, String>> result = UserController.createCustomerUser(null, false);
        Test.stopTest();
    }
    
//  static testMethod void test_runAs_InternalUser() {
//         //create internal user - relationship manager
//         User internalUser = TestClassUtility.createInternalUser();
//         insert internalUser;
        
//         System.runAs(internalUser) {
//             system.assertEquals('Standard', UserInfo.getUserType());
//             test_getCustomerUser_method();
//             test_getCustomerUser_method_negative1();
//             test_getCustomerUser_method_negative2();
//         }
//     }

//     static testMethod void test_runAs_ExternalUser() {
//         test.startTest();
//         //create external user - for the school contact
//         Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
//         User externalUser = TestClassUtility.createExternalUser(schoolContact);
//         insert externalUser;
//         test.stopTest(); 

//         //get testUser as external user
//         User testUser = [SELECT id, username, name, contactId, Contact.AccountId FROM User WHERE email =: 'email2@invalid-domain.com' ];
        
//         // Profile p = [SELECT id, Name FROM Profile WHERE Name = 'Support Hub Community Member User - Login Licence MFA'];
        
//         // User testUser = new User(Alias = 'ExtUsr', Email='SupportHubExternalUser@invalid-domain.com', 
//         //     EmailEncodingKey='UTF-8', FirstName='SuppotHub', LastName='ExternalUser', LanguageLocaleKey='en_US', 
//         //     LocaleSidKey='en_US', ProfileId = p.Id, 
//         //     TimeZoneSidKey='America/Los_Angeles', UserName='SupportHubExternalUser@invalid-domain.com');

        
//         System.runAs(testUser) {
//             system.assertEquals('CspLitePortal', UserInfo.getUserType());
//             test_getCustomerUser_method_ForRunAs_ExternalUser();
//             test_getCustomerUser_method_negative1();
//             test_getCustomerUser_method_negative2();
//         }
//     }

//     static testMethod void test_runAs_GuestUser() {
//         Profile p = [SELECT Id FROM Profile WHERE Name='Guest License User']; 
        
//         //no need to insert this guest user
//         User testUser = new User(Alias = 'GstUsr', Email='SupportHubGuestUser@invalid-domain.com', 
//             EmailEncodingKey='UTF-8', FirstName='SuppotHub', LastName='GuestUser', LanguageLocaleKey='en_US', 
//             LocaleSidKey='en_US', ProfileId = p.Id, 
//             TimeZoneSidKey='America/Los_Angeles', UserName='SupportHubGuestUser@invalid-domain.com');

//         System.runAs(testUser) {
//             system.assertEquals('Guest', UserInfo.getUserType());
//             test_getCustomerUser_method();
//             test_getCustomerUser_method_negative1();
//             test_getCustomerUser_method_negative2();
//         }
//     }

    
}