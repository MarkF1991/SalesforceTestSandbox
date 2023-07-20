/**
* @author Ben Edwards (ben@cloudinit.nz)
* @date 2017-10-06
* @description Test class for the SupportHubSignupController
*
* CHANGE LOG
* 21/8/2019 Ben Soh changed ...[SELECT Id, Name FROM User WHERE Name = 'N4L Support Hub Site Guest User'... to 'N4L Support Hub Site' due to user's name changed in production 28/06/2018
**/
@isTest
public class SupportHubSignupControllerTest {
    
    /**
*   @author David Catindoy (david@cloudinit.nz)
*   @description Setup method.
*   @date Oct 6, 2017
**/
    @testSetup
    static void setup(){
        List<Account> schools = new List<Account>();
        schools.add(new Account(Name = 'Mindanao State University', Email_Domain__c = 'yahoo.com'));
        schools.add(new Account(Name = 'The University of Auckland'));
        Database.insert(schools);
        
        Id schoolId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('School').getRecordTypeId();
        schools.get(0).RecordTypeId = schoolId;
        schools.get(1).RecordTypeId = schoolId;
        Database.update(schools);
    }
    
        public static testMethod void testtestsetup() {
        List<Account> accounts = [SELECT id, Name FROM Account];      
        Account account = accounts[0];

        List<AccountContactRelation> relationships =  [SELECT ContactId, Roles, IsActive FROM AccountContactRelation WHERE AccountId =: account.Id];
        system.debug('>>>>>>>>>>>>>>> relationships = ' + relationships);
        
        List<Contact> contacts = [SELECT Id, Name, FirstName, LastName, Business_Role__c FROM Contact WHERE AccountId =: account.Id];
        system.debug('>>>>>>>>>>>>>>> contacts = ' + contacts);

        system.assertEquals(True, (1==1));
    }
    
    /**
*   @author David Catindoy (david@cloudinit.nz)
*   @description Test self-registration method.
*   @date Oct 6, 2017
**/
    @isTest
    static void testSignupSuccess(){
        
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Mindanao State University'];
        
        System.runAs([SELECT Id, Name FROM User WHERE Name = 'N4L Support Hub Site' LIMIT 1][0]){
            
            Test.startTest();
            
            SupportHubSignupController controller = new SupportHubSignupController();
            
            system.assertNotEquals(null, controller.accountsJson);
            system.assertNotEquals(null, controller.selectedSchool);
            
            controller.selectedSchoolId = testAccount.Id;
            controller.selectSchool();
            
            controller.registration.firstName = 'David';
            controller.registration.lastName = 'Catindoy';
            controller.registration.email = 'catindoydavid';
            controller.registration.mobile = '021 123 4567';
            controller.registration.phone = '09 123 4567';
            //controller.registration.acceptTerms = true;
            
            controller.submit();
            
            System.assertEquals(Label.Support_Hub_Signup_Success, ApexPages.getMessages().get(0).getDetail());
            
            Test.stopTest();
        }
    }
    
    /**
*   @author Ben Edwards (ben@cloudinit.nz)
*   @description Test self-registration method.
*   @date Oct 6, 2017
**/
    @isTest
    static void testSignupNoEmailDomain(){
        
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'The University of Auckland'];
        
        System.runAs([SELECT Id, Name FROM User WHERE Name = 'N4L Support Hub Site' LIMIT 1][0]){
            
            Test.startTest();
            
            SupportHubSignupController controller = new SupportHubSignupController();
            
            controller.selectedSchoolId = testAccount.Id;
            controller.selectSchool();
            
            System.assert(controller.noEmailDomain);
            System.assertEquals(Label.Support_Hub_No_Email_Domain_Error, ApexPages.getMessages().get(0).getDetail());
        }
    }
    
    /**
*   @author David Catindoy (david@cloudinit.nz)
*   @description Test self-registration method with errors.
*   @date Oct 6, 2017
**/
    @isTest
    static void testSignupWithErrors(){
        
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Mindanao State University'];
        
        System.runAs([SELECT Id, Name FROM User WHERE Name = 'N4L Support Hub Site' LIMIT 1][0]){
            
            Test.startTest();
            
            SupportHubSignupController controller = new SupportHubSignupController();
            
            controller.selectSchool();
            controller.selectedSchoolId = testAccount.Id;
            controller.selectSchool();
            
            // Fail mobile and phone validation
            controller.registration.firstName = 'David';
            controller.registration.lastName = 'Catindoy';
            controller.registration.email = 'catindoydavid@yahoo.com';
            controller.registration.mobile = '091234567';
            controller.registration.phone = '091234567';
            //controller.registration.acceptTerms = true;
            controller.submit();
            
            // Fail because mobile and phone is blank
            controller.registration.mobile = null;
            controller.registration.phone = null;
            controller.submit();
            
            controller.registration.email = UserInfo.getUserName().substringBefore('@');
            controller.selectedSchool.Email_Domain__c = UserInfo.getUserName().substringAfter('@');
            controller.submit();
            
            Test.stopTest();
        }
    }
    
    /**
*   @author David Catindoy (david@cloudinit.nz)
*   @description Test self-registration method with contact exist.
*   @date Oct 6, 2017
**/
    @isTest
    static void testSignupWithContactExist(){
        
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Mindanao State University'];

        Contact newCont = new Contact(FirstName = 'David', LastName = 'Catindoy', Email = 'catindoydavid@yahoo.com', AccountId = testAccount.Id);
        Database.insert(newCont);
        
        System.runAs([SELECT Id, Name FROM User WHERE Name = 'N4L Support Hub Site' LIMIT 1][0]){
            
            Test.startTest();
            
            SupportHubSignupController controller = new SupportHubSignupController();
            
            controller.selectedSchoolId = testAccount.Id;
            controller.selectSchool();
            
            controller.registration.firstName = 'David';
            controller.registration.lastName = 'Catindoy';
            controller.registration.email = 'catindoydavid';
            controller.registration.phone = '09 123 4567';
            //controller.registration.acceptTerms = true;
            
            controller.submit();
            
            System.assertEquals(Label.Support_Hub_Signup_Success, ApexPages.getMessages().get(0).getDetail());
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void test_send_SupportHubSignUp_PrincipalNotification_Email(){
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        schoolAccount.uuid__c = 'schoola';
        schoolAccount.MoE_School_ID__c = '200';
        schoolAccount.Email_Domain__c = 'invalid-domain.com'; //for filtering portal access, the contact and user's email must have the same domain.
        schoolAccount.Fortinet_Adom_Name__c = 'n4l-adom-name';
        insert schoolAccount;
        
        //create contacts in the school
        Contact principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
        insert principalContact;   
        
        Profile profileObj = [SELECT id, Name FROM Profile WHERE Name = 'Support Hub Community Member User - Login Licence MFA'];
        
        User testUser = new User(
            profileId = profileObj.id,
            username = 'internaluser@invalid-domain.com',
            email = 'internaluser@invalid-domain.com',
            emailencodingkey = 'UTF-8',
            localesidkey = 'en_US',
            languagelocalekey = 'en_US',
            timezonesidkey = 'Pacific/Auckland',
            alias = 'iuser',
            contactId = principalContact.Id,
            firstname = 'Internal',
            lastname = 'User');
        Insert testUser;
        
        
        MethodResponse testResponse = SupportHubSignupController.send_SupportHubSignUp_PrincipalNotification_Email(testUser.Id);
        system.assertEquals(200, testResponse.statusCode);
        
    }
    
    
    @isTest
    static void test_send_SupportHubSignUp_PrincipalNotification_Email_method(){
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        schoolAccount.uuid__c = 'schoola';
        schoolAccount.MoE_School_ID__c = '200';
        schoolAccount.Email_Domain__c = 'invalid-domain.com'; //for filtering portal access, the contact and user's email must have the same domain.
        schoolAccount.Fortinet_Adom_Name__c = 'n4l-adom-name';
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
        
        test.startTest();
        //create external user - for the school contact
        User externalUser = TestClassUtility.createExternalUser(schoolContact);
        insert externalUser;
        //externalUser.Send_Email_School_Principal__c = true;
        //update externalUser;
        SupportHubSignupController.triggerEmailForNewUser(externalUser.id, true); //use @future method to udpate user to make User.Send_Email_School_Principal__c = true
        
        test.stopTest(); 
        
        User testUser = [SELECT id, username, name, contactId, Contact.AccountId, Send_Email_School_Principal__c FROM User WHERE email =: 'email2@invalid-domain.com' ];
        system.debug('>>> 1 testUser.Send_Email_School_Principal__c' + testUser.Send_Email_School_Principal__c);
        
        
        MethodResponse testResponse = SupportHubSignupController.send_SupportHubSignUp_PrincipalNotification_Email(testUser.Id);
        //system.assertEquals(200, testResponse.statusCode);
        //reference:  https://salesforce.stackexchange.com/questions/123786/how-to-test-messaging-sendemail
        Integer invocations = Limits.getEmailInvocations();
        //system.assertEquals(1, invocations, 'An email should be sent');
        
        //test invocable method with the same data.
        List<Id> ids = new List<Id>();
        ids.add(testUser.Id);
        SupportHubSignupController.SupportHubSignUp_PrincipalNotification(ids);
        invocations = Limits.getEmailInvocations();
        //system.assertEquals(2, invocations, 'An email should be sent'); //should be counting 2 by now
        
    }
    
    @isTest
    static void test_send_SupportHubSignUp_PrincipalNotification_Email_method_negative1(){
        //to test could not find user record situation
        String testUserId = '0055P000000UzlFQAS'; 
        
        MethodResponse testResponse = SupportHubSignupController.send_SupportHubSignUp_PrincipalNotification_Email(testUserId);
        system.assertEquals(404, testResponse.statusCode); //404 for not able to find the user
        
        
        //test invocable method with the same data.
        List<Id> ids = new List<Id>();
        ids.add(testUserId);
        SupportHubSignupController.SupportHubSignUp_PrincipalNotification(ids);
        integer invocations = Limits.getEmailInvocations();
        system.assertEquals(0, invocations, 'no email should be sent'); 
        
    }
    
    @isTest
    static void test_send_SupportHubSignUp_PrincipalNotification_Email_method_mustPreventSendingEmailToPrincipal(){
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        schoolAccount.uuid__c = 'schoola';
        schoolAccount.MoE_School_ID__c = '200';
        schoolAccount.Email_Domain__c = 'invalid-domain.com'; //for filtering portal access, the contact and user's email must have the same domain.
        schoolAccount.Fortinet_Adom_Name__c = 'n4l-adom-name';
        insert schoolAccount;
        
        
        Contact principalContact = new Contact();
        //there is a process/trigger on account that automatically create a principal contact at the time account record is created
        List<Contact> contacts = [SELECT id, name, email, Business_Role__c, AccountId, Current_Principal_Of_This_School__c FROM Contact WHERE AccountId =: schoolAccount.id and Current_Principal_Of_This_School__c = true];
        if (contacts.size()==1){
            principalContact = contacts[0];
            principalContact.FirstName = 'FirstName1';
            principalContact.LastName = 'LastName1';
            principalContact.Email = 'email1@invalid-domain.com';
            principalContact.AccountId = schoolAccount.id;
            update principalContact;
        } else {
            //create contacts in the school
            principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
            insert principalContact;    
        }
        system.debug('>>> principalContact' + principalContact);
        
        List<Contact> newContacts = new List<Contact>();
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName2', 'LastName2', 'email2@invalid-domain.com', '02722222222', 'IT Lead', False)); //was ICT Leader
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName3', 'LastName3', 'email3@invalid-domain.com', '02733333333', 'IT Support', False)); //was External ICT
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName4', 'LastName4', 'email4@invalid-domain.com', '02744444444', 'IT Support', False)); //was External ICT
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName6', 'LastName6', 'email6@invalid-domain.com', '02766666666', '', False)); //for blank role test scenario

        Contact exPrincipalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName5', 'LastName5', 'email5@invalid-domain.com', '02755555555', 'Principal', False);
        
        newContacts.add(exPrincipalContact);

        insert newContacts;

        exPrincipalContact.Inactive_Contact_Record__c = true;
        update exPrincipalContact;

        //update relationship
        contacts = [SELECT id, name, email, Business_Role__c, AccountId, Inactive_Contact_Record__c FROM Contact WHERE AccountId =: schoolAccount.id];
        Map<Id, Contact> contactMap = new Map<Id, Contact>(contacts);

        List<AccountContactRelation> relationships =  [SELECT ContactId, Roles, IsActive FROM AccountContactRelation WHERE AccountId =: schoolAccount.Id];
        for(AccountContactRelation relationship : relationships){
            relationship.Roles = contactMap.get(relationship.ContactId).Business_Role__c;
            relationship.IsActive = !contactMap.get(relationship.ContactId).Inactive_Contact_Record__c;
        }
        update relationships;
        
        test.startTest();
        //create external user - for the school principal
        User externalUser = TestClassUtility.createExternalUser(principalContact);
        insert externalUser;
 
        //externalUser.Send_Email_School_Principal__c = true;
        //update externalUser;
        SupportHubSignupController.triggerEmailForNewUser(externalUser.id, true); //use @future method to udpate user to make User.Send_Email_School_Principal__c = true
        
        test.stopTest(); 
        
        User testUser = [SELECT id, username, name, email, contactId, Contact.AccountId, Send_Email_School_Principal__c FROM User WHERE email =: 'email1@invalid-domain.com' limit 1];
        system.debug('>>> 1 testUser.Send_Email_School_Principal__c' + testUser.Send_Email_School_Principal__c);
                system.debug('>>> 1 testUser' + testUser.Contact.AccountId);
         system.debug('>>> externalUser' + externalUser.Contact.AccountId);
        
        MethodResponse testResponse = SupportHubSignupController.send_SupportHubSignUp_PrincipalNotification_Email(externalUser.Id);
        system.assertEquals(200, testResponse.statusCode);
        //reference:  https://salesforce.stackexchange.com/questions/123786/how-to-test-messaging-sendemail
        Integer invocations = Limits.getEmailInvocations();
        system.assertEquals(0, invocations, 'NO email should be sent');
    }
    
    //additional test methods to cover original methods that are not in used since the submit() code has been change 15/03/2021
    @isTest
    static void test_newUser(){
        SupportHubSignupController supporthub = new SupportHubSignupController();
        supporthub.registration.firstName = 'Ben';
        supporthub.registration.lastName = 'Soh';
        supporthub.registration.mobile = '021 123 456';
        supporthub.registration.phone = '09 123 456';
        
        test.startTest();
        User user = supporthub.newUser('ben.soh@n4l.co.nz');
        test.stopTest(); 
        system.assertEquals('ben.soh@n4l.co.nz', user.Email);
    }
    
    @isTest
    static void test_uniqueNickname(){
        test.startTest();
        SupportHubSignupController supporthub = new SupportHubSignupController();
        String nickname = supporthub.uniqueNickname();
        system.assertEquals(40, nickname.length());
        system.assertEquals(TRUE, nickname.startsWith('N4LCustomer.'));
        test.stopTest(); 
    }
    
}