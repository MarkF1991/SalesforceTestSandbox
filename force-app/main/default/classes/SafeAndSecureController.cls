public with sharing class SafeAndSecureController {
    @AuraEnabled() //when outbound call agent spoken to principal, and the outcome was to opt out.
    public static Map<String,String> OutboundCallOutcome (Id contactId, Id caseId, String action){
        Map<String,String> result = New Map<String,String>();
        MethodResponse res = new MethodResponse();
        
        //get contact
        List<Contact> contacts = [SELECT id, FirstName, Email, AccountId, Account.Name FROM Contact WHERE Id =: contactId];
        if(contacts.isEmpty()){
            res.setStatus(400);
            res.setResult('SafeAndSecureController.OutboundCallOutcome', 'invalid contactId: ' + contactId);
            result.put('response', res.getJSONstring()); //prepare result.response for LWC
            return result;
        } 
        Contact contact = contacts[0];
        
        //get case
        List<Case> cases = [SELECT id, Status, accountId, account.Name, account.Web_profiles_with_compliance_issues__c, account.Firewall_policies_with_compliance_issues__c, account.Akamai_DNS_Filtering__c, Case_Thread_ID__c, CaseNumber
                            FROM Case WHERE Id=: caseId];
        if(cases.isEmpty()){
            res.setStatus(400);
            res.setResult('SafeAndSecureController.OutboundCallOutcome', 'invalid caseId: ' + caseId);
            result.put('response', res.getJSONstring()); //prepare result.response for LWC
            return result;
        }
        Case inquiryCase = cases[0];

        //get email template api from email mapping 
        String emailMappingKey;
        switch on action {
            when 'moreinfo' {
                emailMappingKey = 'safe and secure outbound call confirmation email more info';
                result = moreInfo(contact, inquiryCase, emailMappingKey);
            }

            when 'optout' {
                emailMappingKey = 'safe and secure outbound call confirmation email opt out';
                result = optOut(contact, inquiryCase, emailMappingKey);
            }

            when 'tofix' {
                emailMappingKey = 'safe and secure outbound call confirmation email to fix';
                result = toFix(contact, inquiryCase, emailMappingKey);
            }

            when else {
                res.setStatus(400);
                res.setResult('SafeAndSecureController.OutboundCallOutcome', 'invalid action: ' + action);
                result.put('response', res.getJSONstring()); //prepare result.response for LWC
                return result;
            }
        }
        return result;
    }

    
    public static Map<String,String> moreInfo (Contact contact, Case inquiryCase, String emailMappingKey){
        Map<String,String> result = New Map<String,String>();
        MethodResponse res = new MethodResponse();

        //update case status
        inquiryCase.Status = 'Under Action';
        update inquiryCase;

        //send email
        MethodResponse res2 = send_SafeAndSecureOutboundCall_Email(contact, inquiryCase, emailMappingKey, false);
        //if(res2.statusCode >= 400) return res2;
        if(res2.statusCode >= 400){
            result.put('response', res2.getJSONstring()); //prepare result.response for LWC
            return result;
        }
        
    //*removed this task based on ticket MN-369    
        //create reminder task
        // Task task = new Task(
        //     Subject = inquiryCase.Account.Name + ' - required more info for safe and secure',
        //     WhatId = inquiryCase.Id,
        //     WhoId = contact.Id,
        //     Type = 'Call',
        //     Status = 'In Progress',
        //     OwnerId = UserInfo.getUserId(),
        //     RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Task, 'Callback Task'),
        //     IsReminderSet = true,
        //     ReminderDateTime = datetime.now().addDays(2) //add 2 days reminder
        // );
        // Insert task;

        res.setStatus(200);
        res.setResult('SafeAndSecureController.moreInfo', 'successfully updated case and sent email');
        result.put('response', res.getJSONstring()); //prepare result.response for LWC
        return result;
    }

    public static Map<String,String> optOut (Contact contact, Case inquiryCase, String emailMappingKey){
        Map<String,String> result = New Map<String,String>();
        MethodResponse res = new MethodResponse();
       
        //update Account to indicate that this school has opted out from Safe and Secure
        Account account = [SELECT Id, Safe_Secure_Internet_Opt_Out__c FROM Account WHERE Id=:inquiryCase.accountId];
        account.Safe_Secure_Internet_Opt_Out__c = TRUE;
        update account;

        //send email
        MethodResponse res2 = send_SafeAndSecureOutboundCall_Email(contact, inquiryCase, emailMappingKey, true);
        //if(res2.statusCode >= 400) return res2;
        if(res2.statusCode >= 400){
            result.put('response', res2.getJSONstring()); //prepare result.response for LWC
            return result;
        }
        
        //close this case
        inquiryCase.Status = 'Closed - Resolved';
        inquiryCase.Resolution_Category__c = 'Safe & Secure Compliance – Opt Out';
        update inquiryCase;

        res.setStatus(200);
        res.setResult('SafeAndSecureController.optOut', 'successfully updated case and sent email');
        result.put('response', res.getJSONstring()); //prepare result.response for LWC
        return result;
    }

    //public static MethodResponse toFix (Contact contact, Case inquiryCase, String emailMappingKey){
    public static Map<String,String>  toFix (Contact contact, Case inquiryCase, String emailMappingKey){
        Map<String,String> result = New Map<String,String>();
        MethodResponse res = new MethodResponse();

        //create new Service Request case to fix safe and secure config
        Group helpdeskQueue = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = 'Helpdesk Queue'];

        //create a request case
        Case requestCase = new Case(
            RecordTypeId = Helper.getRecordTypeId(Schema.SObjectType.Case, 'Service Request'),
            AccountId = inquiryCase.accountId,
            ContactId = contact.Id,
            ParentId = inquiryCase.Id,
            Status = 'New',
            Subject = 'Fix Safe And Secure Configuration',
            Product__c = 'MNttS - Safe & Secure Internet',
            Call_Driver__c = 'Safe And Secure Configuration Fix',
            Origin = 'Safe And Secure Followup',
            OwnerId = helpdeskQueue.Id,
            Description = 
                'Web profiles with compliance issues' + '\n' +
                nullCheck(inquiryCase.account.Web_profiles_with_compliance_issues__c).stripHtmlTags() + '\n\n' +
                'Firewall policies with compliance issues' + '\n' +
                nullCheck(inquiryCase.account.Firewall_policies_with_compliance_issues__c).stripHtmlTags() 
        );
        insert requestCase;

        //MN-377 uncheck the SS internet opt out 
        Account account = [SELECT id, name, Safe_Secure_Internet_Opt_Out__c FROM Account WHERE id =: inquiryCase.accountId];
        account.Safe_Secure_Internet_Opt_Out__c = False;
        update account;
        
         //send email
         MethodResponse res2 = send_SafeAndSecureOutboundCall_Email(contact, inquiryCase, emailMappingKey, true);
         //if(res2.statusCode >= 400) return res2;
         if(res2.statusCode >= 400){
             result.put('response', res2.getJSONstring()); //prepare result.response for LWC
             return result;
         }
 
         result.put('serviceRequestCase', JSON.serialize(requestCase));
         
         try {
             //close this case
             inquiryCase.Status = 'Closed - Resolved';
             inquiryCase.Resolution_Category__c = 'Safe & Secure Compliance – Fixed';
             // inquiryCase.ParentId = requestCase.Id;
             update inquiryCase;
 
             res.setStatus(200);
             res.setResult('SafeAndSecureController.toFix', 'successfully closed inquiry case, and created service request case and sent email');
 
             result.put('response', res.getJSONstring()); //prepare result.response for LWC
             
         } catch (Exception ex) {
             res.setStatus(400);
             res.setResult('SafeAndSecureController.toFix', ex.getStackTraceString());
             result.put('response', res.getJSONstring()); //prepare result.response for LWC
         }
        
         return result;
     
    }

    @AuraEnabled() //LWC Service Waiver will call this method to send email
    public static MethodResponse send_SafeAndSecureOutboundCall_Email (Contact contact, Case inquiryCase, String emailMappingKey, Boolean ccPrincipal){
        MethodResponse res = new MethodResponse();
        try{   
            //toAddresses
            List<String> toAddresses = new List<String>();
            if(contact != null && String.isNotBlank(contact.Email)) toAddresses.add(contact.Email);
            
            //ccAddresses - no cc required, but leave it as empty list by default
            List<String> ccAddresses = new List<String>();
            if(ccPrincipal){
                //get principal
                Map<string, List<Contact>> roleBasedContacts = ContactController.getRoleBaseContacts(inquiryCase.AccountId);
                Contact principal =  roleBasedContacts.get('Principal').get(0); //get principal of the school
                if(contact.Id != principal.Id){
                    ccAddresses.add(principal.Email);
                }
            }
            
            
            //get Email Template Name based on MetaData - Email Template Mapping
            MethodResponse res2 = EmailController.getEmailTemplateByMasterLabel(emailMappingKey);
            if(res2.statusCode >= 400) return res2;
            EmailTemplate emailTemplate = res2.emailTemplate; //dto in res
            OrgWideEmailAddress orgWideEmailAddress = res2.orgWideEmailAddress; //dto in res

            String htmlBody = emailTemplate.HtmlValue;
            htmlBody = htmlBody.replace('{!Contact.FirstName}', contact.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            htmlBody = htmlBody.replace('{!Account.Name}', inquiryCase.Account.Name); //email template cannot hold 3 or more level up {!Contact.Account.Name}. When saved, it get shorten to {!Contact.Account}
            
            htmlBody = htmlBody.replace('[displayStyleWebFiltering]', displayStyle(inquiryCase.Account.Web_profiles_with_compliance_issues__c)); 
            htmlBody = htmlBody.replace('{!Account.Web_profiles_with_compliance_issues__c}', nullCheck(inquiryCase.Account.Web_profiles_with_compliance_issues__c)); 
            
            htmlBody = htmlBody.replace('[displayStyleFirewall]', displayStyle(inquiryCase.Account.Firewall_policies_with_compliance_issues__c)); 
            htmlBody = htmlBody.replace('{!Account.Firewall_policies_with_compliance_issues__c}', nullCheck(inquiryCase.Account.Firewall_policies_with_compliance_issues__c)); 
            
            htmlBody = htmlBody.replace('[displayStyleDNS]', displayStyleDNS(inquiryCase.Account.Akamai_DNS_Filtering__c)); 
            htmlBody = htmlBody.replace('{!Account.Akamai_DNS_Filtering__c}', nullCheck(inquiryCase.Account.Akamai_DNS_Filtering__c)); 

            htmlBody = htmlBody.replace('{!Case.Case_Thread_ID__c}', inquiryCase.Case_Thread_ID__c); 
            htmlBody = htmlBody.replace('{!Case.CaseNumber}', inquiryCase.CaseNumber); 
            
            
            String plainBody = emailTemplate.Body;
            plainBody = plainBody.replace('{!Contact.FirstName}',  contact.FirstName); //when replacing htmlbody this way, the normal Salesforce merge field in email template way would not work
            plainBody = plainBody.replace('{!Account.Name}', inquiryCase.Account.Name); //email template cannot hold 3 or more level up {!Contact.Account.Name}. When saved, it get shorten to {!Contact.Account}
            plainBody = plainBody.replace('{!Account.Web_profiles_with_compliance_issues__c}', nullCheck(inquiryCase.Account.Web_profiles_with_compliance_issues__c)); 
            plainBody = plainBody.replace('{!Account.Firewall_policies_with_compliance_issues__c}', nullCheck(inquiryCase.Account.Firewall_policies_with_compliance_issues__c)); 
            plainBody = plainBody.replace('{!Account.Akamai_DNS_Filtering__c}', (inquiryCase.Account.Akamai_DNS_Filtering__c == 'Disabled' ? 'DNS Threat Protection & SafeSearch: Disabled' : '')); 
            plainBody = plainBody.replace('{!Case.Case_Thread_ID__c}', inquiryCase.Case_Thread_ID__c); 
            plainBody = plainBody.replace('{!Case.CaseNumber}', inquiryCase.CaseNumber); 

            //EmailController.sendEmail2(contract.CustomerSignedId, contract.AccountId, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, orgWideEmailAddress);    
            Messaging.Singleemailmessage email = EmailController.constructEmail2(contact.Id, inquiryCase.Id, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, orgWideEmailAddress);
            
            String subject = emailTemplate.Subject;
            if(subject.contains('{!Case.Case_Thread_ID__c}')){
                subject = subject.replace('{!Case.Case_Thread_ID__c}', inquiryCase.Case_Thread_ID__c); 
                email.setSubject(subject);
            }
 
            Messaging.sendEmail(new Messaging.SingleEmailmessage[] {email});
            res.setStatus(200);
            res.setResult('send_SafeAndSecureOutboundCall_Email', 'Sent ' + emailTemplate.Name +' Email to ' + string.join(toAddresses,','));  
            return res;
        
        } catch (System.Exception ex) {
			res.setStatus(400);
            res.setResult('error', ex.getMessage());
            res.setResult('log', 'SafeAndSecureController.send_SafeAndSecureOutboundCall_Email Exception' );
            return res;
		}
    }

    Public Static String nullCheck(String input){
        return (String.IsBlank(input) ? '' : input ); //return '' if input is null.
    }

    Public Static String displayStyle(String input){
        return (String.IsBlank(input) ? 'style="display: none;"' : '' ); //return 'style="display: none;"' in <tr> so that it can hide the entire section when there is no value to show
    }

    Public Static String displayStyleDNS(String input){
        if (String.IsBlank(input)){
            return 'style="display: none;"';
        }  
        return (input.equalsIgnoreCase('Disabled') ? '' : 'style="display: none;"' ); //return '' in <tr> so that it can show DNS when it is Disabled. Other wise, hide the section
    }

}