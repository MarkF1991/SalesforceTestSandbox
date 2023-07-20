public class TaskActionController {
    @InvocableMethod(label='' description='')    
    public static void Tasks (List<ID> ids) {
        Id taskId = ids[0];
        if(!Test.isRunningTest()){
        MethodResponse res = processTaskTemplateActions(taskId);
        }
    }
    
    public static MethodResponse processTaskTemplateActions(Id taskId){
        MethodResponse res = new MethodResponse();
        
try {
            //Get source task
            Task sourceTask = [SELECT Id, whatId, Status, Entity_Attachment_Ids__c, Subject, Task_Template__c, Type FROM Task WHERE Id =: taskId];
            
            //Get Case
            Case sourceCase = [SELECT Id, Opportunity__c, Opportunity__r.Contract.CustomerSignedId, ICT_Date_onsite__c, CaseNumber, ER_Lite__c, Phase_1_Install_Provider__r.Name, Phase_1_Install_Provider__c, Phase_1_Cutover_Appointment__c, Case_Thread_ID__c, Contract__r.Account.id, Contract__r.MoE_Party_Email__c, Opportunity__r.ContractId, Install_Contact__c, Install_Provider__c, Cutover_Appointment__c, Install_Provider__r.Billing_Contact__c, Install_Provider__r.Name, Install_Provider__r.ParentId, Install_Provider__r.Parent.Billing_Contact__c, ICT_Implementation_Provider__r.name, Cutover_Appointment_Date_Time_Text__c, Opportunity__r.Id, Account.Id, Account.Name, Account.Owner.Email, ContactId, Secondary_Contact__c, Account.CC_Wireless_AP_Make__c
                               FROM Case WHERE Id =: sourceTask.whatId];
            
            //Get Order
            Order order = null;
            List<Order> orders = [SELECT Id, uuid__c, Status, Case__c, Type, Case__r.caseNumber, Case__r.ICT_Date_onsite__c, Case__r.Cutover_Appointment__c, Contract.status, Earliest_Delivery_Date__c,
            Contract.ContractNumber, PoNumber, Account.NZ_Region__c, Account.MoE_External_ID__c, Order.PoDate, case__r.Case_Thread_ID__c, Account.Name, Account.uuid__c, Latest_Delivery_Date__c,
            OrderNumber, OrderReferenceNumber, Xero_Id__c, Xero_Error__c, Order.Shipping_Address__c, Order.ShippingStreet, Order.ShippingCity, Order.ShippingPostalCode,  TotalAmount,               
            Provider__r.Billing_Contact__c, Provider__r.Billing_Contact__r.FirstName, Provider__r.Billing_Contact__r.Email, Provider__r.Name, Provider__r.BillingStreet, 
            Provider__r.BillingCity, Provider__r.BillingPostalCode, Provider__r.BillingCountry FROM Order WHERE order.Case__c =: sourceCase.Id Limit 1];
  
            if(!orders.isEmpty()){
                order = orders[0];
            }

            //Get a List of tasks
            List<Task> tasks = [SELECT Id, whatId, Status, Task_Template__c, Type FROM Task WHERE whatId =: sourceTask.whatId];
            
            //Get a List of TaskTemplateAction__c looking for only those with TargetTaskTemplate
            List<TaskTemplateAction__c> taskTemplateActions = [SELECT Id, SourceTaskTemplate__c, OnStatusChanged__c, isActive__c, ChangeStatusTo__c, TargetTaskTemplate__c, SearchKeyWord__c 
                                                               FROM TaskTemplateAction__c
                                                               WHERE SourceTaskTemplate__c =: sourceTask.Task_Template__c
                                                               AND OnStatusChanged__c =: sourceTask.Status
                                                               AND TargetTaskTemplate__c != NULL];
            
            //Prepare a Map of Tasks in the Case
            Map<Id,Task> taskMap = new Map<Id,Task>();
            for(Task task : tasks) {
                taskMap.put(task.Task_Template__c, task);
            }
            
            //Update Target Tasks Status based on definitions in Task Template Actions
            List <Task> updatingTasks = new List <Task>();
            for(TaskTemplateAction__c taskTemplateAction :  taskTemplateActions) {
                Task targetTask = taskMap.get(taskTemplateAction.TargetTaskTemplate__c);
                if(targetTask.Status != 'Completed'){
                targetTask.status = taskTemplateAction.ChangeStatusTo__c;
                }
                updatingTasks.add(targetTask);   
            }
            update updatingTasks;
            system.debug('updatingTasks'+updatingTasks);
            system.debug('taskTemplateActions'+taskTemplateActions);
            
            
            res.setStatus(200);
            sendEmailWhenTaskStatusChanged(sourceTask,sourceCase, order);
            
                   
        } catch (System.Exception ex) {
            res.setStatus(400);
            res.setResult('Task Template Action', ex.getMessage());
        }
        
        return res;
    }
    
    
    public static MethodResponse sendEmailWhenTaskStatusChanged(Task sourceTask, Case sourceCase, Order order){
        MethodResponse res = new MethodResponse();
        
        List<TaskTemplateAction__c> taskTemplateActions;
        //get a list of actions for the source task: OnStatusChanged__c must match with current source task Status, and must have EmailTemplateName
        //to suit the ER lite process
        if(sourceCase.ER_Lite__c == false){
            taskTemplateActions = [SELECT Id, SourceTaskTemplate__c, isActive__c, SendEmailCc__c, SendEmailFrom__c, SendEmailTo__c, 
                                                           OnStatusChanged__c, ChangeStatusTo__c, TargetTaskTemplate__c, EmailTemplateName__c, Name, SearchKeyWord__c
                                                           FROM TaskTemplateAction__c
                                                           WHERE SourceTaskTemplate__c =: sourceTask.Task_Template__c
                                                           AND OnStatusChanged__c =: sourceTask.Status
                                                           AND EmailTemplateName__c != NULL];
        system.debug('@@(#*taskTemplateActions:'+taskTemplateActions);
        //return res when there is no actions to send emails.
        if (taskTemplateActions.isEmpty()) {
            res.setStatus(200);
            res.setResult('sendEmailWhenTaskStatusChanged', 'Skipped - no Task Template Actions to send email');
            return res;
        }
        }
        else if(sourceCase.ER_Lite__c == true){
                    //For ER Lite
        //get a list of actions for the source task: OnStatusChanged__c must match with current source task Status, and must have EmailTemplateName
        taskTemplateActions = [SELECT Id, SourceTaskTemplate__c, isActive__c, SendEmailCc__c, SendEmailFrom__c, SendEmailTo__c, 
                                                           OnStatusChanged__c, ChangeStatusTo__c, TargetTaskTemplate__c, EmailTemplateName__c, ER_Lite_EmailTemplateName__c, Name, SearchKeyWord__c
                                                           FROM TaskTemplateAction__c
                                                           WHERE SourceTaskTemplate__c =: sourceTask.Task_Template__c
                                                           AND OnStatusChanged__c =: sourceTask.Status
                                                           AND ER_Lite_EmailTemplateName__c != NULL];
        system.debug('@@(#*erLiteTaskTemplateActions:'+taskTemplateActions);
        //return res when there is no actions to send emails.
        if (taskTemplateActions.isEmpty()) {
            res.setStatus(200);
            res.setResult('sendEmailWhenTaskStatusChanged', 'Skipped - no Task Template Actions to send email');
            return res;
        }
        }
        


        
        
        
        //get opportunity contact roles: including extra fields in select statement for later use in sending email: Contact.FirstName, Contact.Email
        Map<String, OpportunityContactRole> opportunityContactRoleMap = new Map<String, OpportunityContactRole>();
        List<OpportunityContactRole> opportunityContactRoles = [SELECT Id, ContactId, Contact.FirstName, Contact.Email, Contact.MobilePhone, Contact.Phone, OpportunityId, Role FROM OpportunityContactRole WHERE OpportunityId =: sourceCase.Opportunity__c];
        for (OpportunityContactRole opportunityContactRole : opportunityContactRoles){
            opportunityContactRoleMap.put(opportunityContactRole.Role, opportunityContactRole); //prepare map for Get OpportunityContactRole by Role.
        }
        
        Map<String, Contact> contactMap = new Map<String, Contact>();
        system.debug('@@(#*contactMap-start:'+contactMap);
        //getting real and latest contact from Case and Contract - not from Opportunity Contact Role
        Id contactId;
        //Primary Contact
        contactId = sourceCase.ContactId;
        If (contactId != null){
            contactMap.put('Primary Contact', ContactController.getContact(contactId));
            // } else {
            //     contactMap.put('Primary Contact', ContactController.getContact(opportunityContactRoleMap.get('Primary Contact').Id)); //just in case 
        }
        
        //Secondary Contact
        contactId = sourceCase.Secondary_Contact__c;
        If (sourceCase.Secondary_Contact__c != null){
            contactMap.put('Secondary Contact', ContactController.getContact(contactId));
        }
        
        //Authorised Signatory from Contract Signatory
        contactId = sourceCase.Opportunity__r.Contract.CustomerSignedId;
        If (contactId != null){
            contactMap.put('Authorised Signatory', ContactController.getContact(contactId));
        }
        
        //Technical Survey Contact
        if (opportunityContactRoleMap.containsKey('Technical Survey Contact')) {
            contactId = opportunityContactRoleMap.get('Technical Survey Contact').ContactId;
            If (contactId != null){
                contactMap.put('Technical Survey Contact', ContactController.getContact(contactId));
            }
        }
                
        //Install Provider Contact
        if(sourceCase.Install_Provider__r.ParentId == null){
            contactId = sourceCase.Install_Provider__r.Billing_Contact__c;
            contactMap.put('Install Provider Contact', ContactController.getContact(contactId));
 
        }
        else if (sourceCase.Install_Provider__r.ParentId != null){
            contactId = sourceCase.Install_Provider__r.Parent.Billing_Contact__c;
            contactMap.put('Install Provider Contact', ContactController.getContact(contactId));
        }
        system.debug('@@(#*contactMap-end:'+contactMap); 
        system.debug('@@(#*contactMapkeyset:'+contactMap.keyset());
        
        //ADDED SEPTEMBER 2022 for ES Contact Completion to support different order confirmation emails for Ruckus and non-ruckus
        //get any resolved Schedule Migration task for the source case to check later which email template to send
        List<Task> scheduleMigrationTaskList_resolved = [SELECT Status FROM Task 
                                               WHERE Type = 'Schedule Ruckus Migration' AND WhatId = :sourceCase.Id AND Status = 'Resolved'
                                              ];
        Task scheduleMigrationTask_resolved; 
        if (scheduleMigrationTaskList_resolved.size() > 0) 
            scheduleMigrationTask_resolved = scheduleMigrationTaskList_resolved[0];
        
        
        //loop through task template actions to send email
        for(TaskTemplateAction__c taskTemplateAction : taskTemplateActions) {
            if(taskTemplateAction.isActive__c == true && sourceCase.ER_Lite__c == false){
                system.debug('@@(#*taskTemplateActionSendEmailTo__c:'+taskTemplateAction.SendEmailTo__c); 
                system.debug('@@(#*taskTemplateActions:'+taskTemplateActions); 

            if (taskTemplateAction.EmailTemplateName__c == 'SNU_01A_Technical_Survey' || taskTemplateAction.EmailTemplateName__c == 'SNU_01B_Technical_Survey'){
                //dont use oppoMap.get('').contact becasue it will return error: attempt to de-reference a null obejct 
                if(taskTemplateAction.EmailTemplateName__c == 'SNU_01A_Technical_Survey' && opportunityContactRoleMap.containsKey('Technical Survey Contact')){
                    sendTaskEmail(sourceTask, taskTemplateAction, contactMap, sourceCase, order);
                } 
                else if(taskTemplateAction.EmailTemplateName__c == 'SNU_01B_Technical_Survey' && !opportunityContactRoleMap.containsKey('Technical Survey Contact')) {
                    sendTaskEmail(sourceTask, taskTemplateAction, contactMap, sourceCase, order);
                }
                
            }
            
                else if(contactMap.keyset().contains(taskTemplateAction.SendEmailTo__c)){
                    //ADDED SEPTEMBER 2022 for ES Contact Completion to support different order confirmation emails for Ruckus and non-ruckus
                    //Skip NON-RUCKUS email if the following conditions are  met:  
                    //Account.CC_Wireless_AP_Make__c == 'Ruckus'AND Schedule Ruckus Migration Task status != 'Resolved'
                    if(taskTemplateAction.EmailTemplateName__c == 'SNU_ES_Onboarding_4a_Order_Form_completed_non_Ruckus') {
                       if(sourceCase.Account.CC_Wireless_AP_Make__c == 'Ruckus' && scheduleMigrationTask_resolved == null){
                           continue;
                       }
                    }
                    //Skip RUCKUS email if the following conditions are met:
                    //Account.CC_Wireless_AP_Make__c != 'Ruckus' OR Schedule Ruckus Migration task = Complete
                    if(taskTemplateAction.EmailTemplateName__c == 'SNU_ES_Onboarding_4b_Order_Form_completed_Ruckus_Schedule'){ 
                        //skip primary contact ruckus email if primary contact is authorised signatory to avoid duplicate email send
                        //cannot cc the primary contact into auth. signatory email because the requirement is 2 emails separate sent
                         if (taskTemplateAction.SendEmailTo__c == 'Primary Contact' && 
                            contactMap.keyset().contains('Authorised Signatory') &&
                            contactMap.get('Authorised Signatory').Id == contactMap.get('Primary Contact').Id ){
                                continue;
                            }
                        if((sourceCase.Account.CC_Wireless_AP_Make__c == 'Ruckus' && scheduleMigrationTask_resolved != null) ||
                           sourceCase.Account.CC_Wireless_AP_Make__c != 'Ruckus' ){
                               continue;
                           } 
                    }
                    
                    //sendTaskEmail(sourceTask, taskTemplateAction, contactMap, sourceCase, order);
                sendTaskEmailWithFile(sourceTask, taskTemplateAction, contactMap, sourceCase, order);
                
            }
        }
        }

        //For ER Lite Email
        for(TaskTemplateAction__c erLiteTaskTemplateAction : taskTemplateActions) {
            if(erLiteTaskTemplateAction.isActive__c == true && sourceCase.ER_Lite__c == True){
                system.debug('@@(#*erLiteTaskTemplateActionSendEmailTo__c:'+erLiteTaskTemplateAction.SendEmailTo__c); 
                system.debug('@@(#*erLiteTaskTemplateActions:'+taskTemplateActions); 
            
              if(contactMap.keyset().contains(erLiteTaskTemplateAction.SendEmailTo__c)){
                //sendTaskEmail(sourceTask, taskTemplateAction, contactMap, sourceCase, order);
                sendTaskEmailWithFile(sourceTask, erLiteTaskTemplateAction, contactMap, sourceCase, order);
                
            }
        }
        }

        return res;
    }
    
    
    public static MethodResponse sendTaskEmail(Task task, TaskTemplateAction__c taskTemplateAction, Map<String, Contact> contactMap, Case sourceCase, Order order){
        MethodResponse res = new MethodResponse();
        String emailAddress = '';
        //try { 
        
        //toAddresses
        List<String> toAddresses = new List<String>();
        //emailAddress = opportunityContactRoleMap.get(taskTemplateAction.SendEmailTo__c).Contact.Email;//get Contact.Email from OpportunityContactRole.
        emailAddress = contactMap.get(taskTemplateAction.SendEmailTo__c).Email;
        
        if(String.isNotBlank(emailAddress)){
            toAddresses.add(emailAddress);
        } else {
            res.setStatus(400);
            res.setResult('sendTaskEmail', 'could not find opportunity contact role for ' + taskTemplateAction.SendEmailTo__c);
            return res;
        }
        
        //ccAddresses
        List<String> ccAddresses = new List<String>();
        if(String.isNotBlank(taskTemplateAction.SendEmailCc__c)){
            //Split Send Email to Cc
            List<String> recipients = taskTemplateAction.SendEmailCc__c.split(';');
            for (string recipient : recipients){
                //add School's RM = Account Owner's email to ccAddresses
                if(recipient == 'Account : Owner') {
                    emailAddress = sourceCase.Account.Owner.Email;
                    
                }
                
                else if(recipient == 'MoE') {
                    emailAddress = sourceCase.Contract__r.MoE_Party_Email__c;                      
                }
                
                else {
                    //emailAddress = opportunityContactRoleMap.get(role).Contact.Email;//get Contact.Email from OpportunityContactRole.
                    emailAddress = contactMap.get(recipient).Email;
                }    
                if(String.isNotBlank(emailAddress)) ccAddresses.add(emailAddress);
                
            }
        }
        
        //get contact from ContactId of a OpportunityContactRole from opportunityContactRoleMap
        Contact contact = contactMap.get(taskTemplateAction.SendEmailTo__c);
        
        //whoId and whatId
        String whoId = contact.Id;
        String whatId = sourceCase.Id;
        
        //getOrgWideEmailAddress
        OrgWideEmailAddress owa = EmailController.getOrgWideEmailAddress(taskTemplateAction.SendEmailFrom__c);
        
        //get Email Template 
        List<EmailTemplate> emailTemplates = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate
                                              WHERE developerName =: taskTemplateAction.EmailTemplateName__c];
        if(emailTemplates.isEmpty()){
            res.setStatus(409);
            res.setResult('sendTaskEmail error', 'Could not find email template with developerName = ' + taskTemplateAction.EmailTemplateName__c);
            res.setResult('error log', 'EmailController.getEmailTemplateByLabel Handled Exception: Could not find email template with developerName = ' + taskTemplateAction.EmailTemplateName__c );
            return res;
        }
        EmailTemplate emailTemplate = emailTemplates[0];  
        
        EmailTemplateBody modifiedEmailTemplateBody = modifyEmailTemplateBody(emailTemplate, contact, task, sourceCase, order);
        
        String htmlBody = modifiedEmailTemplateBody.htmlBody;
        
        String plainBody = modifiedEmailTemplateBody.plainBody;
        
        
        Messaging.Singleemailmessage email = EmailController.constructEmail2(whoId, whatId, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, owa);
        if(emailTemplate.Subject != modifiedEmailTemplateBody.subject) {
            email.setSubject(modifiedEmailTemplateBody.subject);
        }
                
        // ------ using files instead of attachments --------
        List<Id> fileIdsToAttach = new List<Id>();
        //retrieve files from asset libraries
        Map<Id, sObject> existingFilesOnContract = new Map<Id, sObject>();
        
        //get parent id as the id from Asset Library where the file is saved
        List<ContentWorkspace> assetLibraries = [SELECT DeveloperName, Name, Id FROM ContentWorkspace WHERE DeveloperName = 'sfdc_asset_company_assets'];
        
        if(!assetLibraries.isEmpty()){
            existingFilesOnContract = FileController.getAttachmentOrFileIds(assetLibraries[0].Id, new List<String>{'%N4L Technical Survey for NHR%'},'Both');
            fileIdsToAttach.addAll(existingFilesOnContract.KeySet());
            email.setEntityAttachments(fileIdsToAttach); //attach all the file ids to be sent into email.   
        }
        // ------ using files instead of attachments --------
        
        Messaging.sendEmail(new Messaging.SingleEmailmessage[] {email});
        
        
        res.setStatus(200);
        res.setResult('sendTaskEmail', 'Successfully sent email: ' + taskTemplateAction.EmailTemplateName__c + ' to ' + string.join(toAddresses,','));
        try{   
        }
        catch (System.Exception ex){
            res.setStatus(400);
            res.setResult('Sending Purchase Order', 'Failed to send Equipment Purchase Order');
            res.setResult('Sending Purchase Order', ex.getMessage());
            //system.debug('Try Catch error:' + ex.getMessage());
        }
        return res;
    }
    
    public static MethodResponse sendTaskEmailWithFile(Task task, TaskTemplateAction__c taskTemplateAction, Map<String, Contact> contactMap, Case sourceCase, Order order){
        MethodResponse res = new MethodResponse();
        String emailAddress = '';
        //try { 
        
        //toAddresses
        List<String> toAddresses = new List<String>();
        //emailAddress = opportunityContactRoleMap.get(taskTemplateAction.SendEmailTo__c).Contact.Email;//get Contact.Email from OpportunityContactRole.
        emailAddress = contactMap.get(taskTemplateAction.SendEmailTo__c).Email;
        system.debug('*@*@^^!emailAddress:'+emailAddress);
        system.debug('*@*@^^!contactMap:'+contactMap);
         system.debug('*@*@^^!taskTemplateAction.SendEmailTo__c:'+taskTemplateAction.SendEmailTo__c);
        if(String.isNotBlank(emailAddress)){
            toAddresses.add(emailAddress);
        } else {
            res.setStatus(400);
            res.setResult('sendTaskEmail', 'could not find opportunity contact role for ' + taskTemplateAction.SendEmailTo__c);
            return res;
        }
        system.debug('*@*@^^!toAddresses:'+toAddresses);
        //ccAddresses
        List<String> ccAddresses = new List<String>();
        if(String.isNotBlank(taskTemplateAction.SendEmailCc__c)){
             emailAddress = '';
            //Split Send Email to Cc
            List<String> recipients = taskTemplateAction.SendEmailCc__c.split(';');
            for (string recipient : recipients){
                //add School's RM = Account Owner's email to ccAddresses
                if(recipient == 'Account : Owner') {
                    emailAddress = sourceCase.Account.Owner.Email;
                }
                
                else if(recipient == 'MoE') {
                    emailAddress = sourceCase.Contract__r.MoE_Party_Email__c;                      
                }
                
                else {
                    //emailAddress = opportunityContactRoleMap.get(role).Contact.Email;//get Contact.Email from OpportunityContactRole.
                    if (contactMap.containsKey(recipient)){
                        emailAddress = contactMap.get(recipient).Email;
                    }
                    //emailAddress = contactMap.get(recipient).Email;
                }    
                if(String.isNotBlank(emailAddress)) ccAddresses.add(emailAddress);
            }
        }
        
        //get contact from ContactId of a OpportunityContactRole from opportunityContactRoleMap
        Contact contact = contactMap.get(taskTemplateAction.SendEmailTo__c);
        
        //whoId and whatId
        String whoId = contact.Id;
        String whatId = sourceCase.Id;
        
        //getOrgWideEmailAddress
        OrgWideEmailAddress owa = EmailController.getOrgWideEmailAddress(taskTemplateAction.SendEmailFrom__c);
        
        //For ER Lite changes
        //get Email Template 
        List<EmailTemplate> emailTemplates;
        
        if(sourceCase.ER_Lite__c == false){
            emailTemplates = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate
            WHERE developerName =: taskTemplateAction.EmailTemplateName__c];
        }
        else if(sourceCase.ER_Lite__c == true){
            emailTemplates = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate
            WHERE developerName =: taskTemplateAction.ER_Lite_EmailTemplateName__c];
        }
        
        if(emailTemplates.isEmpty()){
            res.setStatus(409);
            res.setResult('sendTaskEmail error', 'Could not find email template with developerName = ' + taskTemplateAction.EmailTemplateName__c);
            res.setResult('error log', 'EmailController.getEmailTemplateByLabel Handled Exception: Could not find email template with developerName = ' + taskTemplateAction.EmailTemplateName__c );
            return res;
        }
        EmailTemplate emailTemplate = emailTemplates[0];  
        
        EmailTemplateBody modifiedEmailTemplateBody = modifyEmailTemplateBody(emailTemplate, contact, task, sourceCase, order);
        
        String htmlBody = modifiedEmailTemplateBody.htmlBody;
        
        String plainBody = modifiedEmailTemplateBody.plainBody;
        
        
        
        Messaging.Singleemailmessage email = EmailController.constructEmail2(whoId, whatId, emailTemplate, toAddresses, ccAddresses, htmlBody, plainBody, owa);
        if(emailTemplate.Subject != modifiedEmailTemplateBody.subject) {
            email.setSubject(modifiedEmailTemplateBody.subject);
        }
        
        
        // ------ using files instead of attachments --------
        
      
        Map<Id, sObject> existingFilesOnContract;
        List<String> entityAttachmentIds = new List<String>();
        //Get PDF From Task - Entity Attachment Id

        if(task.Entity_Attachment_Ids__c != null){
            String entityAttachmentId = task.Entity_Attachment_Ids__c;
            for(String eAid : entityAttachmentId.split(';')){
                entityAttachmentIds.add(eAid);

            }
            existingFilesOnContract  = FileController.getAttachmentOrFileFromCVIds(sourceCase.Contract__r.id, entityAttachmentIds);
        
            if(!existingFilesOnContract.isEmpty()){
                List<Id> fileIdsToAttach = new List<Id>();
                fileIdsToAttach.addAll(existingFilesOnContract.KeySet());
                email.setEntityAttachments(fileIdsToAttach); //attach all the file ids to be sent into email.   
            }

        }
        else{
        //SearchKeyWord for File
        String searchKeyWord = taskTemplateAction.SearchKeyWord__c;
        if(!String.isBlank(searchKeyWord)){
            List<String> allMakedUpSearchKeyWord = new List<String>();
            //loop through search key words to add %
            for(String keyword : searchKeyWord.split(',')){
                allMakedUpSearchKeyWord.add('%'+ keyword.trim() + '%');
            }

            existingFilesOnContract  = FileController.getAttachmentOrFileIds(sourceCase.Contract__r.id, allMakedUpSearchKeyWord,'Both');
        
            if(!existingFilesOnContract.isEmpty()){
                List<Id> fileIdsToAttach = new List<Id>();
                fileIdsToAttach.addAll(existingFilesOnContract.KeySet());
                email.setEntityAttachments(fileIdsToAttach); //attach all the file ids to be sent into email.   
            }
        }
    }
        // ------ using files instead of attachments --------          
        
        
        Messaging.sendEmail(new Messaging.SingleEmailmessage[] {email});
        
        
        res.setStatus(200);
        res.setResult('sendTaskEmail', 'Successfully sent email: ' + taskTemplateAction.EmailTemplateName__c + ' to ' + string.join(toAddresses,','));
        try{   
        }
        catch (System.Exception ex){
            res.setStatus(400);
            res.setResult('Sending Purchase Order', 'Failed to send Equipment Purchase Order');
            res.setResult('Sending Purchase Order', ex.getMessage());
            //system.debug('Try Catch error:' + ex.getMessage());
        }
        return res;
    }
    
    
    public static EmailTemplateBody modifyEmailTemplateBody(EmailTemplate emailTemplate, Contact contact, Task task, Case sourceCase, Order order) { 
        EmailTemplateBody emailTemplateBody  = new EmailTemplateBody();
        
        switch on emailTemplate.developerName {
            when  'SNU_01A_Technical_Survey'{
                emailTemplateBody = TechnicalSurvey1a(emailTemplate, contact, task, sourceCase);
            }
            
            when  'SNU_01B_Technical_Survey'{
                emailTemplateBody = TechnicalSurvey1b(emailTemplate, contact, task, sourceCase);
            }
            
            when else {
                emailTemplateBody = genericEmailTemplateBody(emailTemplate, contact, task, sourceCase, order);
            }
        }
        
        return emailTemplateBody;
    } 
    
    public static EmailTemplateBody TechnicalSurvey1a(EmailTemplate emailTemplate, Contact contact, Task task, Case sourceCase) { 
        EmailTemplateBody emailTemplateBody  = new EmailTemplateBody(emailTemplate, contact);
        emailTemplateBody.BodyReplace('{!Case.Account}', sourceCase.Account.Name);
        emailTemplateBody.SubjectReplace('{!Case.Account}', sourceCase.Account.Name);
        return EmailTemplateBody;
        
    }
    
    public static EmailTemplateBody TechnicalSurvey1b(EmailTemplate emailTemplate, Contact contact, Task task, Case sourceCase) { 
        EmailTemplateBody emailTemplateBody  = new EmailTemplateBody(emailTemplate, contact);
        emailTemplateBody.BodyReplace('{!Case.Account}', sourceCase.Account.Name);
        emailTemplateBody.SubjectReplace('{!Case.Account}', sourceCase.Account.Name);
        return EmailTemplateBody;
        
    }

    public static EmailTemplateBody genericEmailTemplateBody(EmailTemplate emailTemplate, Contact contact, Task task, Case sourceCase, Order order) { 
        Map<string, List<Contact>> schoolContactMap = ContactController.getRoleBaseContacts(sourceCase.Contract__r.Account.id);
        EmailTemplateBody emailTemplateBody  = new EmailTemplateBody(emailTemplate, contact);
        
        emailTemplateBody.SubjectReplace('{!Case.Account}', sourceCase.Account.Name);
        emailTemplateBody.BodyReplace('{!Case.CaseNumber}', sourceCase.CaseNumber);
        emailTemplateBody.BodyReplace('{!Case.Account}', sourceCase.Account.Name);
        emailTemplateBody.BodyReplace('{!Case.ICT_Implementation_Provider__c}', sourceCase.ICT_Implementation_Provider__r.name);
        emailTemplateBody.BodyReplace('{!Case.ICT_Date_onsite__c}', helper.formatNZdatetimeWithStringMonth(sourceCase.ICT_Date_onsite__c));
        emailTemplateBody.BodyReplace('{!Case.Case_Thread_ID__c}', sourceCase.Case_Thread_ID__c);
        emailTemplateBody.BodyReplace('{!Case.Install_Provider__c}', sourceCase.Install_Provider__r.Name);
        emailTemplateBody.BodyReplace('{!Case.Cutover_Appointment_Date_Time_Text__c}', helper.formatNZdatetimeWithStringMonth(sourceCase.Cutover_Appointment__c));
        emailTemplateBody.BodyReplace('{!Case.Phase_1_Install_Provider__c}', sourceCase.Phase_1_Install_Provider__r.Name);
        emailTemplateBody.BodyReplace('{!Case.Phase_1_Cutover_Appointment__c}', helper.formatNZdatetimeWithStringMonth(sourceCase.Phase_1_Cutover_Appointment__c));

        If(order != null){
            emailTemplateBody.BodyReplace('{!Order.Earliest_Delivery_Date__c}', helper.formatNZdate(order.Earliest_Delivery_Date__c));
            emailTemplateBody.BodyReplace('{!Order.Latest_Delivery_Date__c}', helper.formatNZdate(order.Latest_Delivery_Date__c));
        }
        if(schoolContactMap.containsKey('External ICT')){
            string externalICT = schoolContactMap.get('External ICT')[0].Name + ' ('+schoolContactMap.get('External ICT')[0].Email+')';
            emailTemplateBody.BodyReplace('{!External_ICT_contact_Name_With_Email_Address}', externalICT);
            emailTemplateBody.BodyReplaceDisplayStyle('[displayStyleWithExternalICT]',False);
            emailTemplateBody.BodyReplaceDisplayStyle('[displayStyleWithoutExternalICT]',True);
        }
        else{
            emailTemplateBody.BodyReplaceDisplayStyle('[displayStyleWithExternalICT]',True);
            emailTemplateBody.BodyReplaceDisplayStyle('[displayStyleWithoutExternalICT]',False);
        }

        if(!String.IsBlank(sourceCase.Contract__c)) {
            String contractRecordHyperlink = Helper.supportHubURL() + 'contract/' + sourceCase.Contract__c;
            emailTemplateBody.BodyReplace('[contractRecordHyperlink]', contractRecordHyperlink);
        }

        return EmailTemplateBody;
        
    }
    
    public class EmailTemplateBody {
        public EmailTemplate emailTemplate;
        public String htmlBody;
        public String plainBody;
        public String subject;
        public String userName;
        
        public EmailTemplateBody() {}
        
        public EmailTemplateBody(EmailTemplate emailTemplate, Contact contact) {
            this.htmlBody = emailTemplate.HtmlValue;
            this.plainBody = emailTemplate.Body;
            this.userName = UserInfo.getName();
            BodyReplace('{!Contact.FirstName}', contact.FirstName); 
            BodyReplace('{!User.Name}', userName);
            
            this.subject = emailTemplate.Subject;
        }
        
        public void BodyReplaceDisplayStyle (String target, Boolean display){
            String displayStyle = (display ? 'style="display: none;"' : '' ); //return 'style="display: none;"' in <tr> so that it can hide the entire section when there is no value to show
            BodyReplace (target, displayStyle);
        }

        public void BodyReplace (String target, String replacement){
            this.htmlBody = this.htmlBody.replace(target, nullCheck(replacement));
            this.plainBody = this.plainBody.replace(target, nullCheck(replacement));  
        }
        
        public void SubjectReplace (String target, String replacement){
            this.subject = this.subject.replace(target, nullCheck(replacement));
        }
        
        public String nullCheck(String input){
            return (String.IsBlank(input) ? '' : input ); //return '' if input is null.
        }
        
    }
    
}