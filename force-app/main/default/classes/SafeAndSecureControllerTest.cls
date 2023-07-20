@IsTest
public with sharing class SafeAndSecureControllerTest {
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
       insert newContacts;

       Case inquiryCase = New Case(
            RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Case, 'Inquiry'),
            AccountId = schoolAccount.Id,
            ContactId = principalContact.Id,
            Status = 'New',
            Subject = 'Safe and Secure Outbound Call',
            Product__c = 'MNttS - Safe & Secure Internet',
            Call_Driver__c = 'Firewall configuration',
            Origin = 'Safe And Secure Followup'
       );
       insert inquiryCase;
    }

    static testMethod void test_send_SafeAndSecureOutboundCall_Email_success(){
        Contact contact = [SELECT id, FirstName, Email FROM Contact WHERE Email = 'email2@invalid-domain.com' LIMIT 1]; //this is getting ICT Lead, so that email can cc Principal
        
        Case inquiryCase = [SELECT id, Status, accountId, account.Name, account.Web_profiles_with_compliance_issues__c, account.Firewall_policies_with_compliance_issues__c, account.Akamai_DNS_Filtering__c, Case_Thread_ID__c, CaseNumber 
                            FROM Case LIMIT 1];
        String emailMappingKey = 'safe and secure outbound call confirmation email more info'; //for getting email template in custom metadata mapping

        MethodResponse res = SafeAndSecureController.send_SafeAndSecureOutboundCall_Email(contact, inquiryCase, emailMappingKey, false);
        system.assertEquals(200, res.statuscode);
        
        Integer invocations = Limits.getEmailInvocations();
        system.assertEquals(1, invocations, 'An email should be sent'); //second round after testConstructEmail() above, assert Limits.getEmailInvocations() = 1
        
    }

    static testMethod void test_send_SafeAndSecureOutboundCall_Email_error(){
        Contact contact = [SELECT id, FirstName, Email FROM Contact WHERE Email = 'email1@invalid-domain.com' LIMIT 1];
        Case inquiryCase = [SELECT id, Status, accountId, account.Name, account.Web_profiles_with_compliance_issues__c, account.Firewall_policies_with_compliance_issues__c, account.Akamai_DNS_Filtering__c, Case_Thread_ID__c, CaseNumber 
                            FROM Case LIMIT 1];
        String emailMappingKey = 'you cannot find me'; //for getting email template in custom metadata mapping

        MethodResponse res = SafeAndSecureController.send_SafeAndSecureOutboundCall_Email(contact, inquiryCase, emailMappingKey, true);
        system.assertEquals(400, res.statuscode);
        
        Integer invocations = Limits.getEmailInvocations();
        system.assertEquals(0, invocations, 'An email should be sent'); //second round after testConstructEmail() above, assert Limits.getEmailInvocations() = 0

        res = SafeAndSecureController.send_SafeAndSecureOutboundCall_Email(null, null, emailMappingKey, true);
        system.assertEquals(400, res.statuscode);
    }

    static testMethod void test_OutboundCallOutcome_moreInfo_success(){
        Contact contact = [SELECT id, FirstName, Email FROM Contact WHERE Email = 'email1@invalid-domain.com' LIMIT 1];
        Case inquiryCase = [SELECT id, Status, accountId, account.Web_profiles_with_compliance_issues__c, account.Firewall_policies_with_compliance_issues__c 
                            FROM Case LIMIT 1];
        String action = 'moreinfo';
        
        Map<String,String> result = SafeAndSecureController.OutboundCallOutcome (contact.Id, inquiryCase.Id, action);
        MethodResponse res = (MethodResponse) JSON.deserialize(result.get('response'), MethodResponse.class);
        system.assertEquals(200, res.statuscode);

        //an email should be sent
        Integer invocations = Limits.getEmailInvocations();
        system.assertEquals(1, invocations, 'An email should be sent'); //second round after testConstructEmail() above, assert Limits.getEmailInvocations() = 1

        //inquiry case should be Awaiting Customer Response
        inquiryCase = [SELECT id, Status, accountId, account.Web_profiles_with_compliance_issues__c, account.Firewall_policies_with_compliance_issues__c 
                            FROM Case WHERE Id =: inquiryCase.Id];
        system.assertEquals('Under Action', inquiryCase.Status);

        //Task task = [SELECT id, WhoId, WhatId, Status, IsReminderSet, ReminderDateTime FROM Task WHERE WhatId =: inquiryCase.Id AND RecordType.Name = 'Callback Task' AND Type = 'Call' LIMIT 1];
        //system.assertEquals(contact.Id, task.WhoId);
        //system.assertEquals(true, task.IsReminderSet);
        //system.assertEquals('In Progress', task.Status);
        


       
    }

    static testMethod void test_OutboundCallOutcome_optOut_success(){
        Contact contact = [SELECT id, FirstName, Email FROM Contact WHERE Email = 'email1@invalid-domain.com' LIMIT 1];
        Case inquiryCase = [SELECT id, Status, accountId, account.Web_profiles_with_compliance_issues__c, account.Firewall_policies_with_compliance_issues__c 
                            FROM Case LIMIT 1];
        String action = 'optout';
        
        Map<String,String> result = SafeAndSecureController.OutboundCallOutcome (contact.Id, inquiryCase.Id, action);
        MethodResponse res = (MethodResponse) JSON.deserialize(result.get('response'), MethodResponse.class);
        //system.assertEquals(200, res.statuscode);

        //account should be updated
        Account account = [SELECT Id, Safe_Secure_Internet_Opt_Out__c FROM Account WHERE Id=:inquiryCase.accountId];
        system.assertEquals(TRUE, account.Safe_Secure_Internet_Opt_Out__c);

        //an email should be sent
        //Integer invocations = Limits.getEmailInvocations();
        //system.assertEquals(1, invocations, 'An email should be sent'); //second round after testConstructEmail() above, assert Limits.getEmailInvocations() = 1

        //inquiry case should be closed
        inquiryCase = [SELECT id, Status, accountId, account.Web_profiles_with_compliance_issues__c, account.Firewall_policies_with_compliance_issues__c 
                            FROM Case WHERE Id =: inquiryCase.Id];
        system.assertEquals('New', inquiryCase.Status);
    }

    static testMethod void test_OutboundCallOutcome_toFix_success(){
        Contact contact = [SELECT id, FirstName, Email FROM Contact WHERE Email = 'email1@invalid-domain.com' LIMIT 1];
        Case inquiryCase = [SELECT id, Status, accountId FROM Case LIMIT 1];
        String action = 'tofix';
        
        Map<String,String> result = SafeAndSecureController.OutboundCallOutcome (contact.Id, inquiryCase.Id, action);
        MethodResponse res = (MethodResponse) JSON.deserialize(result.get('response'), MethodResponse.class);
        //system.assertEquals(200, res.statuscode);

        //account should not be updated
        Account account = [SELECT Id, Safe_Secure_Internet_Opt_Out__c FROM Account WHERE Id=:inquiryCase.accountId];
        system.assertEquals(FALSE, account.Safe_Secure_Internet_Opt_Out__c);

        //an email should be sent
        //Integer invocations = Limits.getEmailInvocations();
        //system.assertEquals(1, invocations, 'An email should be sent'); //second round after testConstructEmail() above, assert Limits.getEmailInvocations() = 1

        //inquiry case should be closed
        inquiryCase = [SELECT id, Status, accountId, ParentId FROM Case WHERE Id =: inquiryCase.Id];
        system.assertEquals('New', inquiryCase.Status);
        //system.assertNotEquals(NULL,  inquiryCase.ParentId); //parentId should not be null

        Case serviceRequestCase = [SELECT Id, RecordType.Name, AccountId, ContactId, Status, Product__c, Call_Driver__c, Origin, Description, ParentId
                                    FROM Case WHERE ParentId =: inquiryCase.Id ];
        system.assertEquals(inquiryCase.Id, serviceRequestCase.ParentId);
        system.assertEquals('Service Request', serviceRequestCase.RecordType.Name);
        system.assertEquals(inquiryCase.accountId, serviceRequestCase.AccountId);
        system.assertEquals(contact.Id, serviceRequestCase.ContactId);
        system.assertEquals('New', serviceRequestCase.Status);
        system.assertEquals('MNttS - Safe & Secure Internet', serviceRequestCase.Product__c);
        system.assertEquals('Safe And Secure Configuration Fix', serviceRequestCase.Call_Driver__c);
        system.assertEquals('Safe And Secure Followup', serviceRequestCase.Origin);
        system.assertNotEquals(NULL, serviceRequestCase.Description);
    }

    static testMethod void test_OutboundCallOutcome_error(){
        Contact contact = [SELECT id, FirstName, Email FROM Contact WHERE Email = 'email1@invalid-domain.com' LIMIT 1];
        Case inquiryCase = [SELECT id, Status FROM Case LIMIT 1];
        String action = 'tofix';

        Id invalidRecordId = Id.valueOf('001xa000003DIlo');

        //null contact id
        Map<String,String> result = SafeAndSecureController.OutboundCallOutcome (null, inquiryCase.Id, action);
        MethodResponse res = (MethodResponse) JSON.deserialize(result.get('response'), MethodResponse.class);
        system.assertEquals(400, res.statuscode);

        //invalid contact id
        result = SafeAndSecureController.OutboundCallOutcome (invalidRecordId, inquiryCase.Id, action);
        res = (MethodResponse) JSON.deserialize(result.get('response'), MethodResponse.class);
        system.assertEquals(400, res.statuscode);

        //null inquiryCase id
        result = SafeAndSecureController.OutboundCallOutcome (contact.Id, null, action);
        res = (MethodResponse) JSON.deserialize(result.get('response'), MethodResponse.class);
        system.assertEquals(400, res.statuscode);
        
        //invalid inquiryCase id
        result = SafeAndSecureController.OutboundCallOutcome (contact.Id, invalidRecordId, action);
        res = (MethodResponse) JSON.deserialize(result.get('response'), MethodResponse.class);
        system.assertEquals(400, res.statuscode);

        //null action
        result = SafeAndSecureController.OutboundCallOutcome (contact.Id, inquiryCase.Id, null);
        res = (MethodResponse) JSON.deserialize(result.get('response'), MethodResponse.class);
        system.assertEquals(400, res.statuscode);

        //invalid action
        result = SafeAndSecureController.OutboundCallOutcome (contact.Id, inquiryCase.Id, 'invalid-action');
        res = (MethodResponse) JSON.deserialize(result.get('response'), MethodResponse.class);
        system.assertEquals(400, res.statuscode);
    }

    static testMethod void test_nullCheck(){
        String input = 'hello';
        String result = SafeAndSecureController.nullCheck(input);
        system.assertEquals(input, result);

        result = SafeAndSecureController.nullCheck(null);
        system.assertEquals('', result);
   }
   static testMethod void test_displayStyle(){
        String input = 'hello';
        String result = SafeAndSecureController.displayStyle(input);
        system.assertEquals('', result);

        result = SafeAndSecureController.displayStyle(null);
        system.assertEquals('style="display: none;"', result);
   }

   static testMethod void test_displayStyleDNS(){
        String input = 'disabled';
        String result = SafeAndSecureController.displayStyleDNS(input);
        system.assertEquals('', result);

        input = 'enabled';
        result = SafeAndSecureController.displayStyleDNS(input);
        system.assertEquals('style="display: none;"', result);

        input = 'unknown';
        result = SafeAndSecureController.displayStyleDNS(input);
        system.assertEquals('style="display: none;"', result);

        result = SafeAndSecureController.displayStyleDNS(null);
        system.assertEquals('style="display: none;"', result);
    }
}