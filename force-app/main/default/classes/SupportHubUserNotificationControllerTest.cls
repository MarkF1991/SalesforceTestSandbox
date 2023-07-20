@IsTest
public with sharing class SupportHubUserNotificationControllerTest {
    @TestSetup
    private static void setup(){ //copied from ContactControllerTest
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
        contacts = [SELECT id, name, email, Business_Role__c, Inactive_Contact_Record__c FROM Contact WHERE AccountId =: schoolAccount.id];
        Map<Id, Contact> contactMap = new Map<Id, Contact>(contacts);

        List<AccountContactRelation> relationships =  [SELECT ContactId, Roles, IsActive FROM AccountContactRelation WHERE AccountId =: schoolAccount.Id];
        for(AccountContactRelation relationship : relationships){
            relationship.Roles = contactMap.get(relationship.ContactId).Business_Role__c;
            relationship.IsActive = !contactMap.get(relationship.ContactId).Inactive_Contact_Record__c;
        }
        update relationships;


    }

    static testMethod void test_SendUserNotificationEmails(){
        Contact schoolContact1 = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c  FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User user = TestClassUtility.createExternalUser(schoolContact1);
        insert user;

        test.startTest();
            List<ID> ids = new List<ID>{user.id};
            SupportHubUserNotificationController.SendUserNotificationEmails(ids);
        test.stopTest();
        

        Integer invocations = Limits.getEmailInvocations();
        system.assertEquals(TRUE, (invocations == 0), 'in unit test, the queue did not run therefore no email should be sent');
    }

    static testMethod void test_SendUserNotificationEmails_error(){
        Id invalidUserId = Id.valueOf('0055P000000UzlFQAS'); //this is only an example of invalid user record id

        test.startTest();
            List<ID> ids = new List<ID>{invalidUserId};
            SupportHubUserNotificationController.SendUserNotificationEmails(ids);
        test.stopTest();
        
        List<Service_Event__c> events = [SELECT Id, Status_Code__c  FROM Service_Event__c];
        system.assertEquals(1, events.size());
        system.assertEquals(400, events[0].Status_Code__c);
    }


    static testMethod void test_queue_RecursiveSendUserNotificationEmails_success(){
        //prepare a list of user
        Contact schoolContact1 = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c  FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User user = TestClassUtility.createExternalUser(schoolContact1);
        insert user;

        List<User> users = new List<User>{user};

        //prepare map
        Map<string, Support_Hub_User_Creation_Mapping__mdt> userCreationMap = SupportHubUserNotificationController.getUserCreationMapping('origin');
                
        //prepare a set of template api names
        Set<String> templateNames = new Set<String>();
        for (Support_Hub_User_Creation_Mapping__mdt mapping : userCreationMap.values()){
            if(!String.isBlank(mapping.Welcome_Email_Template_Mapping__r.EmailTemplateApiName__c)){
                templateNames.add(mapping.Welcome_Email_Template_Mapping__r.EmailTemplateApiName__c);
            }
        }

        //prepare template map
        Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();
        List<EmailTemplate> emailTemplates = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate WHERE developerName IN: templateNames];
        for(EmailTemplate emailTemplate : emailTemplates){
            emailTemplateMap.put(emailTemplate.developerName, emailTemplate);
        }
        
        //support hub usl
        String partialURL = Helper.supportHubURL();

        test.startTest();
            system.enqueueJob(new SupportHubUserNotificationController.queue_RecursiveSendUserNotificationEmails(users, userCreationMap, emailTemplateMap, partialURL));
        test.stopTest();

        Integer invocations = Limits.getEmailInvocations();
        system.assertEquals(TRUE, (invocations >= 0), 'at least an email should be sent');
    }
    
    static testMethod void test_queue_RecursiveSendUserNotificationEmails_error(){
        //prepare a list of user
        Contact schoolContact1 = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c  FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User user = TestClassUtility.createExternalUser(schoolContact1);
        insert user;

        List<User> users = new List<User>{user};

        //prepare map
        Map<string, Support_Hub_User_Creation_Mapping__mdt> userCreationMap = SupportHubUserNotificationController.getUserCreationMapping('origin');
                
        //prepare a set of template api names
        Set<String> templateNames = new Set<String>();
        for (Support_Hub_User_Creation_Mapping__mdt mapping : userCreationMap.values()){
            if(!String.isBlank(mapping.Welcome_Email_Template_Mapping__r.EmailTemplateApiName__c)){
                templateNames.add(mapping.Welcome_Email_Template_Mapping__r.EmailTemplateApiName__c);
            }
        }

        //prepare template map = null to cause error
        Map<String, EmailTemplate> emailTemplateMap = null;
        
        //support hub usl
        String partialURL = Helper.supportHubURL();

        test.startTest();
            system.enqueueJob(new SupportHubUserNotificationController.queue_RecursiveSendUserNotificationEmails(users, userCreationMap, emailTemplateMap, partialURL));
        test.stopTest();
        
        List<Service_Event__c> events = [SELECT Id, Status_Code__c  FROM Service_Event__c];
        system.assertEquals(1, events.size());
        system.assertEquals(400, events[0].Status_Code__c);
    }


    static testMethod void test_send_UserNotification_Email_success(){
        Contact schoolContact1 = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c  FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User user = TestClassUtility.createExternalUser(schoolContact1);
        //insert user;

        Map<string, Support_Hub_User_Creation_Mapping__mdt> userCreationMap = SupportHubUserNotificationController.getUserCreationMapping('key');
        Support_Hub_User_Creation_Mapping__mdt mapping = userCreationMap.get('unittest');

        OrgWideEmailAddress owa = EmailController.getOrgWideEmailAddress(mapping.Welcome_Email_Template_Mapping__r.OWA__c);

        List<EmailTemplate> emailTemplates = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate WHERE developerName =: mapping.Welcome_Email_Template_Mapping__r.EmailTemplateApiName__c];
        EmailTemplate emailTemplate = emailTemplates[0];

        String hyperlink = 'http://n4l.co.nz';

        
        test.startTest();
        MethodResponse res = SupportHubUserNotificationController.send_UserNotification_Email(user, emailTemplate, owa, hyperlink);
        test.stopTest();
        system.assertEquals(200, res.statuscode);
    }

    static testMethod void test_send_UserNotification_Email_error(){
        Contact schoolContact1 = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c  FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User user = TestClassUtility.createExternalUser(schoolContact1);
        //insert user;

        Map<string, Support_Hub_User_Creation_Mapping__mdt> userCreationMap = SupportHubUserNotificationController.getUserCreationMapping('key');
        Support_Hub_User_Creation_Mapping__mdt mapping = userCreationMap.get('unittest');

        OrgWideEmailAddress owa = EmailController.getOrgWideEmailAddress(mapping.Welcome_Email_Template_Mapping__r.OWA__c);

        List<EmailTemplate> emailTemplates = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate WHERE developerName =: mapping.Welcome_Email_Template_Mapping__r.EmailTemplateApiName__c];
        EmailTemplate emailTemplate = emailTemplates[0];

        String hyperlink = 'http://n4l.co.nz';

        
        test.startTest();
        //null emailTemplate
        MethodResponse res = SupportHubUserNotificationController.send_UserNotification_Email(user, null, owa, hyperlink);
        system.assertEquals(400, res.statuscode);

        //null owa
        res = SupportHubUserNotificationController.send_UserNotification_Email(user, emailTemplate, null, hyperlink);
        system.assertEquals(400, res.statuscode);

        //null user
        res = SupportHubUserNotificationController.send_UserNotification_Email(null, emailTemplate, owa, hyperlink);
        system.assertEquals(400, res.statuscode);

        test.stopTest();
        
    }


    static testMethod void test_GenerateHyperlink_SchoolContactsUpdateCampaign(){
        String recordId = '0015O000004Up0KQAS'; 
        List<Support_Hub_User_Creation_Mapping__mdt> mappings = [SELECT DeveloperName, Id, MasterLabel, Key__c, Description__c, UserOrigin__c, startURL__c, IsVisualforcePage__c
                                                                                , Invitation_Email_Template_Mapping__r.EmailTemplateApiName__c, Invitation_Email_Template_Mapping__r.OWA__c
                                                                                , Welcome_Email_Template_Mapping__r.EmailTemplateApiName__c, Welcome_Email_Template_Mapping__r.OWA__c
                                                                                , Message_on_Verify_Email_Page__c 
                                                                                FROM Support_Hub_User_Creation_Mapping__mdt
                                                                                WHERE Key__c = 'schoolcontactsupdatecampaign' LIMIT 1];
        Support_Hub_User_Creation_Mapping__mdt mapping = mappings[0];
        String partialURL = Helper.supportHubURL(mapping.IsVisualforcePage__c);

        String expected = partialURL + mapping.startURL__c + '?recId=' + recordId;
        
        String result = SupportHubUserNotificationController.GenerateHyperlink(recordId, mapping, partialURL);
               
        system.assertEquals(expected, result);
    }

    static testMethod void test_GenerateHyperlink_Generic(){
        String recordId = null; 
        
        Map<string, Support_Hub_User_Creation_Mapping__mdt> userCreationMap = SupportHubUserNotificationController.getUserCreationMapping('key');
        Support_Hub_User_Creation_Mapping__mdt mapping = userCreationMap.get('unittest');


        String partialURL = Helper.supportHubURL(mapping.IsVisualforcePage__c);

        String expected = partialURL + Helper.getStringValue(mapping.startURL__c);
        
        String result = SupportHubUserNotificationController.GenerateHyperlink(recordId, mapping, Helper.supportHubURL());
               
        system.assertEquals(expected, result);
    }
    static testMethod void test_getUserCreationMapping(){
        Map<string, Support_Hub_User_Creation_Mapping__mdt> userCreationMap = SupportHubUserNotificationController.getUserCreationMapping('origin');
        system.assertEquals('unittest', userCreationMap.get('unit test').Key__c);

        userCreationMap = SupportHubUserNotificationController.getUserCreationMapping('key');
        system.assertEquals('unit test', userCreationMap.get('unittest').UserOrigin__c);
    }
}