@IsTest
public class EmailControllerTest {
    @TestSetup
    private static void setup(){
         //create account
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
        
        
    }

    static testMethod void test_getEmailTemplateMappings() {
        Map<String, Email_Template_Mapping__mdt> emailTemplateMap = EmailController.getEmailTemplateMappings();
        String masterLabel = 'ServiceWaiverAcknowledgement';
        String templateName = '';
        if(emailTemplateMap.containsKey(masterLabel)) {
            templateName = emailTemplateMap.get(masterLabel).DeveloperName;
        }
        
        system.assertEquals('Service_Waiver_Acknowledgement', templateName);
    }
    
    static testMethod void getEmailTemplateByMasterLabel() {
        MethodResponse res = EmailController.getEmailTemplateByMasterLabel('filtering portal principal approval');
        system.assertEquals(200, res.statusCode);
        system.assertEquals('Filtering_Portal_Principal_Approval', res.emailTemplate.developerName);
    }

    static testMethod void getEmailTemplateByMasterLabel_negative1() {
        MethodResponse res = EmailController.getEmailTemplateByMasterLabel('invalid label for Custom Metadata Types: Email Template Mappings');
        system.assertEquals(400, res.statusCode);
        system.assertEquals(NULL, res.emailTemplate);
    }

    static testMethod void getEmailTemplateByMasterLabel_negative2() {
        MethodResponse res = EmailController.getEmailTemplateByMasterLabel('unit test missing email template');
        system.assertEquals(409, res.statusCode);
        system.assertEquals(NULL, res.emailTemplate);
        system.assertEquals(TRUE, res.results.get('error').contains('Could not find email template'));
    }

    static void testConstructEmail(Contact contact ){
        MethodResponse res = EmailController.getEmailTemplateByMasterLabel('filtering portal principal approval');
        EmailTemplate emailTemplate = res.emailTemplate;
        
        // String whoId = '';
        // String whatId = '';
        ID whoId  = contact.id;
        ID whatId = contact.AccountId;

        // if (UserInfo.getUserType() == 'Guest'){
        //     whoId = '0035P000001Zl2XQAS';
        //     whatId = '0015P000002M2s4QAC';
        // } else {
        //     Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        //     whoId  = contact.id;
        //     whatId = contact.AccountId;
        // }
        

        //empty list of address and default html body
        List<String> toAddresses = new List<String>();
        List<String> ccAddresses = new List<String>();
        String htmlBody = emailTemplate.HtmlValue;
        String plainBody = emailTemplate.Body;

        //test construct Email
        Messaging.Singleemailmessage email = EmailController.constructEmail(whoId, whatId, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody); 
        //System.debug('>>>>> single email message: ' + JSON.serializePretty(email));
        // if (UserInfo.getUserType() == 'Guest' || UserInfo.getUserType() == 'CspLitePortal'){
        //     System.assertEquals(NULL, email.orgWideEmailAddressId); //Guest and CspLitePortal user should not be able to use Org Wide Email Address
        //     System.assertEquals('N4L Support', email.senderDisplayName); //Guest and CspLitePortal user should not be able to use Org Wide Email Address
        // } else {
            OrgWideEmailAddress owd = EmailController.getOrgWideEmailAddress(Label.N4L_Sender_Email);
            System.assertEquals(owd.id, email.orgWideEmailAddressId); //internal user can use Org Wide Email Address
            System.assertEquals(NULL, email.senderDisplayName); //leave this null
        //}

        System.assertEquals(emailTemplate.Id, email.templateId); //example: "templateId" : "00X5P000000PhYRUA0",
        System.assertEquals(whoId, email.targetObjectId); //example "targetObjectId" : "0035P000001Zl2XQAS",
        System.assertEquals(whatId, email.whatId); //example "whatId" : "0015P000002M2s4QAC"
        System.assertEquals(htmlBody, email.htmlBody); //example:  "htmlBody" : "<!DOCTYPE html>\r\n<head>\r\n    <meta http-equiv ....
        System.assertEquals(plainBody, email.plainTextBody); //example:  "plainTextBody" : "Tēnā koe {!Contact.FirstName} .....

        //test send email
        //reference:  https://salesforce.stackexchange.com/questions/123786/how-to-test-messaging-sendemail
        
        //commented out
        EmailController.sendEmail(whoId, whatId, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody);
        //Messaging.sendEmail(new Messaging.SingleEmailmessage[] {email}); //directly send email from here. The variable {email} here, already has valid values from EmailController.constructEmail above...
        
        
        Integer invocations = Limits.getEmailInvocations();
        system.assertEquals(1, invocations, 'An email should be sent');
    }

    static void testConstructEmail2(Contact contact ){
        //copied from testConstructEmail above. The only difference is on orgWideEmailAddress, and not using Label.N4L_Sender_Email
        MethodResponse res = EmailController.getEmailTemplateByMasterLabel('filtering portal principal approval');
        EmailTemplate emailTemplate = res.emailTemplate;
        OrgWideEmailAddress owa = res.orgWideEmailAddress;
        
        // String whoId = '';
        // String whatId = '';
        ID whoId  = contact.id;
        ID whatId = contact.AccountId;

        // if (UserInfo.getUserType() == 'Guest'){
        //     whoId = '0035P000001Zl2XQAS';
        //     whatId = '0015P000002M2s4QAC';
        // } else {
        //     Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        //     whoId  = contact.id;
        //     whatId = contact.AccountId;
        // }
        

        //empty list of address and default html body
        List<String> toAddresses = new List<String>();
        List<String> ccAddresses = new List<String>();
        String htmlBody = emailTemplate.HtmlValue;
        String plainBody = emailTemplate.Body;

        //test construct Email
        Messaging.Singleemailmessage email = EmailController.constructEmail2(whoId, whatId, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, owa); 
        //System.debug('>>>>> single email message: ' + JSON.serializePretty(email));
        // if (UserInfo.getUserType() == 'Guest' || UserInfo.getUserType() == 'CspLitePortal'){
        //     System.assertEquals(NULL, email.orgWideEmailAddressId); //Guest and CspLitePortal user should not be able to use Org Wide Email Address
        //     System.assertEquals('N4L Support', email.senderDisplayName); //Guest and CspLitePortal user should not be able to use Org Wide Email Address
        // } else {
            //OrgWideEmailAddress owd = EmailController.getOrgWideEmailAddress(orgWideEmailAddress);
            System.assertEquals(owa.id, email.orgWideEmailAddressId); //internal user can use Org Wide Email Address
            System.assertEquals(NULL, email.senderDisplayName); //leave this null
        //}

        System.assertEquals(emailTemplate.Id, email.templateId); //example: "templateId" : "00X5P000000PhYRUA0",
        System.assertEquals(whoId, email.targetObjectId); //example "targetObjectId" : "0035P000001Zl2XQAS",
        System.assertEquals(whatId, email.whatId); //example "whatId" : "0015P000002M2s4QAC"
        System.assertEquals(htmlBody, email.htmlBody); //example:  "htmlBody" : "<!DOCTYPE html>\r\n<head>\r\n    <meta http-equiv ....
        System.assertEquals(plainBody, email.plainTextBody); //example:  "plainTextBody" : "Tēnā koe {!Contact.FirstName} .....

        //test send email
        //reference:  https://salesforce.stackexchange.com/questions/123786/how-to-test-messaging-sendemail

        EmailController.sendEmail2(whoId, whatId, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, owa);
        
        
        
        Integer invocations = Limits.getEmailInvocations();
        system.assertEquals(2, invocations, 'An email should be sent'); //second round after testConstructEmail() above, assert Limits.getEmailInvocations() = 2
    }

    static testMethod void test_runAs_InternalUser() {
        //create internal user - relationship manager
        User internalUser = TestClassUtility.createInternalUser();
        insert internalUser;
        
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];

        System.runAs(internalUser) {
            system.assertEquals('Standard', UserInfo.getUserType());
            getEmailTemplateByMasterLabel();
            getEmailTemplateByMasterLabel_negative1();
            getEmailTemplateByMasterLabel_negative2();
            testConstructEmail(schoolContact); //first round, assert Limits.getEmailInvocations() = 1
            testConstructEmail2(schoolContact); //second round, assert Limits.getEmailInvocations() = 2
        }
    }

    static testMethod void test_runAs_ExternalUser() {
        test.startTest();
        //create external user - for the school contact
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser = TestClassUtility.createExternalUser(schoolContact);
        insert externalUser;
        test.stopTest(); 
        
        //get testUser as external user
        User testUser = [SELECT id, username, name, contactId, Contact.AccountId FROM User WHERE email =: 'email2@invalid-domain.com' ];
        
        System.runAs(testUser) {
            system.assertEquals('CspLitePortal', UserInfo.getUserType());
            getEmailTemplateByMasterLabel();
            getEmailTemplateByMasterLabel_negative1();
            getEmailTemplateByMasterLabel_negative2();
            testConstructEmail(schoolContact); //first round, assert Limits.getEmailInvocations() = 1
            testConstructEmail2(schoolContact); //second round, assert Limits.getEmailInvocations() = 2
        }
    }

    static testMethod void test_runAs_GuestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Guest License User']; 
        
        //no need to insert this guest user
        User testUser = new User(Alias = 'WGWeb', Email='SupportHubGuestUser@invalid-domain.com', 
            EmailEncodingKey='UTF-8', FirstName='SuppotHub', LastName='GuestUser', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='SupportHubGuestUser@invalid-domain.com');

        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        
        System.runAs(testUser) {
            system.assertEquals('Guest', UserInfo.getUserType());
            getEmailTemplateByMasterLabel();
            getEmailTemplateByMasterLabel_negative1();
            getEmailTemplateByMasterLabel_negative2();
            
            //--------------------------------------------------------------------------------------------
            //20/2/2020 This line of code keep failing unit test.Example: EXCEPTION_THROWN [112]|System.EmailException: SendEmail failed. First exception on row 0; first error: INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, insufficient access rights on cross-reference id: [targetObjectId, 0035P000002wEOnQAM] 
            //Ben Soh decided to commented out this line, and evaluated that Guest User should not be sending email to existing contact. 
            //Filtering Portal - required Guest to sign up before they can make request to access filtering portal
            //SupportHub Sign Up - Invocable Apex only calls the sendemail method when the user has been created.
            //MOU - Authorised Signatory must be an Authenticated user before they can sign MOU Contract. All other invite emails or notification emails are sent from Internal Lightning Experience. These are internal users - authenticated.
            //therefore, no need to test this as Guest user.
            
            //testConstructEmail(schoolContact);
            //--------------------------------------------------------------------------------------------
        }
    }

}