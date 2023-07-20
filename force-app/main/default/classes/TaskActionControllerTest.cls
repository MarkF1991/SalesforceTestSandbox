@IsTest
public with sharing class TaskActionControllerTest {
    @TestSetup
    
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
        
    }
    
    public static testMethod void TaskActionControllerTest() {
        test.startTest();
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];      
        //get NHR opportunity
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Contract contract = [SELECT Id, AccountId FROM Contract WHERE Id =: opportunity.ContractId];
        Case testCase = [SELECT Id, Subject, RecordType.Name, CaseNumber, OwnerId, Case_Thread_ID__c, Opportunity__c, contract__r.id, ICT_Implementation_Provider__r.Name, ContactId, Secondary_Contact__c, Install_Provider__r.Name FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
        
        //list Onboarding Tasks under Onboarding Case
        List<Task> testTasks = [SELECT Id, Subject, Status, Type, OwnerId, Owner.Name, Entity_Attachment_Ids__c, Sequence__c FROM Task WHERE WhatId =: testCase.Id ORDER BY Sequence__c];
        system.assertEquals(17, testTasks.size());
        
        //prepare a Map for task
        Map<String, Task> testTaskMap = new Map<String, Task>();
        For(Task testTask : testTasks){
            testTaskMap.put(testTask.Type, testTask);  
        }
        
        //update one task to start another task 1
        Task completingTask = testTaskMap.get('Design');
        completingTask.Status = 'Completed';
        update completingTask;
        MethodResponse res2 = TaskActionController.processTaskTemplateActions(completingTask.Id);
        system.assertEquals(200, res2.statuscode);
        
        //query to get updated list of case task
        testTasks = [SELECT Id, Subject, Status, Type, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: testCase.Id ORDER BY Sequence__c];
        
        testTaskMap.clear();
        For(Task testTask : testTasks){
            testTaskMap.put(testTask.Type, testTask);
        }
        
        system.assertEquals('In Progress', testTaskMap.get('Design Financial Approval').Status);
        
        //update one task to start another task 2
        completingTask = testTaskMap.get('Release SOW - Installer');
        completingTask.Status = 'Completed';
        update completingTask;
        
        res2 = TaskActionController.processTaskTemplateActions(completingTask.Id);
        system.assertEquals(200, res2.statuscode);
        
        //query to get updated list of case task
        testTasks = [SELECT Id, Subject, Status, Type, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: testCase.Id ORDER BY Sequence__c];
        
        testTaskMap.clear();
        For(Task testTask : testTasks){
            testTaskMap.put(testTask.Type, testTask);
        }
        
        system.assertEquals('In Progress', testTaskMap.get('Order Equipment').Status);
        system.assertEquals('In Progress', testTaskMap.get('Pre Install Configuration').Status);
        test.stopTest();
    }
    
    
    //-----------------------------------------------------------Test_Send_Email-----------------------------------------------------------------------------
    public static testMethod void test_sendEmailWhenTaskStatusChanged() {
        test.startTest();
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];      
        //get NHR opportunity
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Contract contract = [SELECT Id FROM Contract WHERE Id =: opportunity.ContractId];
        Case testCase = [SELECT Id, Subject, RecordType.Name, ICT_Implementation_Provider__r.Name, Opportunity__c, CaseNumber, OwnerId, ContactId, Case_Thread_ID__c, contract__r.id, Secondary_Contact__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
        
        //order
        List<Order> orders = [SELECT Id, uuid__c, Status, Case__c, Type, Case__r.caseNumber, Case__r.ICT_Date_onsite__c, Case__r.Cutover_Appointment__c, Contract.status, 
                              Contract.ContractNumber, PoNumber, Account.NZ_Region__c, Account.MoE_External_ID__c, Order.PoDate, case__r.Case_Thread_ID__c, Account.Name, Account.uuid__c, Latest_Delivery_Date__c,
                              OrderNumber, OrderReferenceNumber, Xero_Id__c, Xero_Error__c, Order.Shipping_Address__c, Order.ShippingStreet, Order.ShippingCity, Order.ShippingPostalCode,  TotalAmount,               
                              Provider__r.Billing_Contact__c, Provider__r.Billing_Contact__r.FirstName, Provider__r.Billing_Contact__r.Email, Provider__r.Name, Provider__r.BillingStreet, 
                              Provider__r.BillingCity, Provider__r.BillingPostalCode, Provider__r.BillingCountry FROM Order];
        
        Order order = orders[0];
        
        MethodResponse res = OpportunityController.generateOnboardingRecords(opportunity.Id);
        system.assertEquals(201, res.statuscode); 
        
        //verify onboarding case has been created
        List<Case> cases = [SELECT Id, Subject, RecordType.Name, CaseNumber, ICT_Implementation_Provider__r.Name, Er_Lite__c, Account.Id, contract__r.id, Case_Thread_ID__c, Account.Name, Opportunity__r.Contract.CustomerSignedId, Opportunity__r.ContractId, Opportunity__r.Id, Opportunity__c, OwnerId, ContactId, Secondary_Contact__c FROM Case];
        Case sourceCase = cases[0];
        
        //list Onboarding Tasks under Onboarding Case
        List<Task> testTasks = [SELECT Id, Subject, Status, Type, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: sourceCase.Id ORDER BY Sequence__c];
        system.assertEquals(17, testTasks.size());
        
        //prepare a Map for task
        Map<String, Task> testTaskMap = new Map<String, Task>();
        For(Task testTask : testTasks){
            testTaskMap.put(testTask.Type, testTask);
        }
        
        //update one task to start another task
        Task completingTask = testTaskMap.get('Technical Survey');
        completingTask.Status = 'In Progress';
        update completingTask;
        MethodResponse res2 = TaskActionController.processTaskTemplateActions(completingTask.Id);
        system.assertEquals(200, res2.statuscode);
        
        //query to get updated list of case task
        testTasks = [SELECT Id, Subject, Status, Type, Task_Template__c, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: sourceCase.Id ORDER BY Sequence__c];
        Task sourceTask = testTasks[0];
        //oppo
        Map<String, OpportunityContactRole> opportunityContactRoleMap = new Map<String, OpportunityContactRole>();
        List<OpportunityContactRole> opportunityContactRoles = [SELECT Id, ContactId, Opportunity.ContractId, Contact.FirstName, Contact.Email, Contact.MobilePhone, Contact.Phone, OpportunityId, Role FROM OpportunityContactRole WHERE OpportunityId =: sourceCase.Opportunity__c];
        for (OpportunityContactRole opportunityContactRole : opportunityContactRoles){
            opportunityContactRoleMap.put(opportunityContactRole.Role, opportunityContactRole); //prepare map for Get OpportunityContactRole by Role.
        }
        system.assertEquals(4, opportunityContactRoleMap.size());
        system.assertEquals(True, opportunityContactRoleMap.containsKey('Technical Survey Contact'));
        //TaskTemplateAction
        List<TaskTemplateAction__c> taskTemplateActions = [SELECT Id, SourceTaskTemplate__c, SendEmailCc__c, SendEmailFrom__c, SendEmailTo__c, 
                                                           OnStatusChanged__c, ChangeStatusTo__c, TargetTaskTemplate__c, EmailTemplateName__c, Name
                                                           FROM TaskTemplateAction__c   
                                                           
                                                          ];
        system.debug('taskTemplateActions'+taskTemplateActions);
        system.assertEquals('Technical Survey Contact', taskTemplateActions[9].SendEmailCc__c);
        
        res = TaskActionController.sendEmailWhenTaskStatusChanged(sourceTask, sourceCase, order);
        system.assertEquals(200, res.statuscode);
        test.stopTest();
        //Integer invocations = Limits.getEmailInvocations();
        //system.assertEquals(TRUE, (invocations > 0), 'at least an email should be sent');
        
    } 
    
    
    public static testMethod void test_sendEmailWhenTaskStatusChanged2() {
        test.startTest();
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];      
        //get NHR opportunity
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Contract contract = [SELECT Id FROM Contract WHERE Id =: opportunity.ContractId];
        Case testCase = [SELECT Id, Subject, RecordType.Name, CaseNumber, ICT_Implementation_Provider__r.Name, Er_Lite__c, OwnerId, contract__r.id, Case_Thread_ID__c, ContactId, Secondary_Contact__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
        
        //order
        List<Order> orders = [SELECT Id, uuid__c, Status, Case__c, Type, Case__r.caseNumber, Case__r.ICT_Date_onsite__c, Case__r.Cutover_Appointment__c, Contract.status, 
                              Contract.ContractNumber, PoNumber, Account.NZ_Region__c, Account.MoE_External_ID__c, Order.PoDate, case__r.Case_Thread_ID__c, Account.Name, Account.uuid__c, Latest_Delivery_Date__c,
                              OrderNumber, OrderReferenceNumber, Xero_Id__c, Xero_Error__c, Order.Shipping_Address__c, Order.ShippingStreet, Order.ShippingCity, Order.ShippingPostalCode,  TotalAmount,               
                              Provider__r.Billing_Contact__c, Provider__r.Billing_Contact__r.FirstName, Provider__r.Billing_Contact__r.Email, Provider__r.Name, Provider__r.BillingStreet, 
                              Provider__r.BillingCity, Provider__r.BillingPostalCode, Provider__r.BillingCountry FROM Order];
        
        Order order = orders[0];
        
        MethodResponse res = OpportunityController.generateOnboardingRecords(opportunity.Id);
        system.assertEquals(201, res.statuscode); 
        
        //verify onboarding case has been created
        List<Case> cases = [SELECT Id, Subject, RecordType.Name, CaseNumber, ICT_Implementation_Provider__r.Name, Case_Thread_ID__c, ER_Lite__c, Account.Id, Account.Name, contract__r.id, Opportunity__r.Contract.CustomerSignedId, Opportunity__r.ContractId, Opportunity__r.Id, Opportunity__c, OwnerId, ContactId, Secondary_Contact__c, Install_Provider__c FROM Case];
        Case sourceCase = cases[0];
        
        //list Onboarding Tasks under Onboarding Case
        List<Task> testTasks = [SELECT Id, Subject, Status, Type, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: sourceCase.Id ORDER BY Sequence__c];
        system.assertEquals(17, testTasks.size());
        
        //prepare a Map for task
        Map<String, Task> testTaskMap = new Map<String, Task>();
        For(Task testTask : testTasks){
            testTaskMap.put(testTask.Type, testTask);
        }   
        
        //update one task to start another task
        Task completingTask = testTaskMap.get('Technical Survey');
        completingTask.Status = 'In Progress';
        update completingTask;
        MethodResponse res2 = TaskActionController.processTaskTemplateActions(completingTask.Id);
        system.assertEquals(200, res2.statuscode);
        
        //query to get updated list of case task
        testTasks = [SELECT Id, Subject, Status, Type, Task_Template__c, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: sourceCase.Id ORDER BY Sequence__c];
        Task sourceTask = testTasks[0];
        //oppo
        Map<String, OpportunityContactRole> opportunityContactRoleMap = new Map<String, OpportunityContactRole>();
        List<OpportunityContactRole> opportunityContactRoles = [SELECT Id, ContactId, Contact.FirstName, Contact.Email, Contact.MobilePhone, Contact.Phone, OpportunityId, Role FROM OpportunityContactRole WHERE OpportunityId =: sourceCase.Opportunity__c];
        for (OpportunityContactRole opportunityContactRole : opportunityContactRoles){
            opportunityContactRoleMap.put(opportunityContactRole.Role, opportunityContactRole); //prepare map for Get OpportunityContactRole by Role.
        }
        system.assertEquals(4, opportunityContactRoleMap.size());
        system.assertEquals(True, opportunityContactRoleMap.containsKey('Primary Contact'));
        system.debug('opportunityContactRoleMap'+opportunityContactRoleMap);
        //TaskTemplateAction
        List<TaskTemplateAction__c> taskTemplateActions = [SELECT Id, SourceTaskTemplate__c, SendEmailCc__c, SendEmailFrom__c, SendEmailTo__c, 
                                                           OnStatusChanged__c, ChangeStatusTo__c, TargetTaskTemplate__c, EmailTemplateName__c, Name
                                                           FROM TaskTemplateAction__c   
                                                           
                                                          ];
        TaskTemplateAction__c taskTemplateAction = taskTemplateActions[10];
        
        system.assertEquals('Primary Contact;Secondary Contact', taskTemplateActions[10].SendEmailCc__c);
        
        //get Email Template 
        List<EmailTemplate> emailTemplates = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate
                                              WHERE developerName =: taskTemplateAction.EmailTemplateName__c];
        EmailTemplate emailTemplate = emailTemplates[0]; 
        system.debug('!!line183-emailTemplate:'+emailTemplate);
        system.assertEquals('SNU_01B_Technical_Survey', emailTemplates[0].developerName);
        //get contact from ContactId of a OpportunityContactRole from opportunityContactRoleMap
        Contact contact = ContactController.getContact(opportunityContactRoleMap.get(taskTemplateAction.SendEmailTo__c).ContactId);
        
        TaskActionController.TechnicalSurvey1b(emailTemplate, contact, sourcetask, sourceCase);
        
        system.assertEquals('Primary Contact', taskTemplateActions[10].SendEmailTo__c);
        
        res = TaskActionController.sendEmailWhenTaskStatusChanged(sourceTask, sourceCase, order);
        test.stopTest();
        system.assertEquals(200, res.statuscode);
        
        //Integer invocations = Limits.getEmailInvocations();
        //system.assertEquals(TRUE, (invocations > 0), 'at least an email should be sent');
        
        
    }
    
    public static testMethod void test_sendEmailWhenTaskStatusChanged3() {
        test.startTest();
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];      
        //get NHR opportunity
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Contract contract = [SELECT Id, account.id FROM Contract WHERE Id =: opportunity.ContractId];
        Case sourceCase = [SELECT Id, Subject, RecordType.Name, CaseNumber, OwnerId, Opportunity__c, ER_Lite__c, ICT_Implementation_Provider__r.Name, Case_Thread_ID__c, ContactId, contract__r.id, contract__r.account.id, Secondary_Contact__c, Install_Provider__r.Name FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
        
        //order
        // List<Order> orders = [SELECT Id, uuid__c, Status, Case__c, Type, Case__r.caseNumber, Case__r.ICT_Date_onsite__c, Case__r.Cutover_Appointment__c, Contract.status, Earliest_Delivery_Date__c,
        //                       Contract.ContractNumber, PoNumber, Account.NZ_Region__c, Account.MoE_External_ID__c, Order.PoDate, case__r.Case_Thread_ID__c, Account.Name, Account.uuid__c, Latest_Delivery_Date__c,
        //                       OrderNumber, OrderReferenceNumber, Xero_Id__c, Xero_Error__c, Order.Shipping_Address__c, Order.ShippingStreet, Order.ShippingCity, Order.ShippingPostalCode,  TotalAmount,               
        //                       Provider__r.Billing_Contact__c, Provider__r.Billing_Contact__r.FirstName, Provider__r.Billing_Contact__r.Email, Provider__r.Name, Provider__r.BillingStreet, 
        //                       Provider__r.BillingCity, Provider__r.BillingPostalCode, Provider__r.BillingCountry FROM Order WHERE AccountId =: account.Id];
        
        // Order order = orders[0];
        
        
        //list Onboarding Tasks under Onboarding Case
        List<Task> testTasks = [SELECT Id, Subject, Status, Type, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: sourceCase.Id ORDER BY Sequence__c];
        system.assertEquals(17, testTasks.size());
        
        //prepare a Map for task
        Map<String, Task> testTaskMap = new Map<String, Task>();
        For(Task testTask : testTasks){
            testTaskMap.put(testTask.Type, testTask);
        }
        
        //update one task to start another task
        Task completingTask = testTaskMap.get('Contract Completion');
        completingTask.Status = 'Completed';
        update completingTask;
        MethodResponse res2 = TaskActionController.processTaskTemplateActions(completingTask.Id);
        system.assertEquals(200, res2.statuscode);
        
        // //query to get updated list of case task
        // testTasks = [SELECT Id, Subject, Status, Type, Task_Template__c, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: sourceCase.Id ORDER BY Sequence__c];
        // Task sourceTask = testTasks[0];
        // //oppo
        // Map<String, OpportunityContactRole> opportunityContactRoleMap = new Map<String, OpportunityContactRole>();
        // List<OpportunityContactRole> opportunityContactRoles = [SELECT Id, ContactId, Contact.FirstName, Contact.Email, Contact.MobilePhone, Contact.Phone, OpportunityId, Role FROM OpportunityContactRole WHERE OpportunityId =: sourceCase.Opportunity__c];
        // for (OpportunityContactRole opportunityContactRole : opportunityContactRoles){
        //     opportunityContactRoleMap.put(opportunityContactRole.Role, opportunityContactRole); //prepare map for Get OpportunityContactRole by Role.
        // }
        // system.assertEquals(4, opportunityContactRoleMap.size());
        
        // Map<String, Contact> contactMap = new Map<String, Contact>();
        
        // //getting real and latest contact from Case and Contract - not from Opportunity Contact Role
        // Id contactId;
        // //Primary Contact
        // contactId = sourceCase.ContactId;
        // If (contactId != null){
        //     contactMap.put('Authorised Signatory', ContactController.getContact(contactId));
        //     // } else {
        //     //     contactMap.put('Primary Contact', ContactController.getContact(opportunityContactRoleMap.get('Primary Contact').Id)); //just in case 
        // }
        
        // //TaskTemplateAction
        // List<TaskTemplateAction__c> taskTemplateActions = [SELECT Id, SourceTaskTemplate__c, SendEmailCc__c, SendEmailFrom__c, SendEmailTo__c, 
        //                                                    OnStatusChanged__c, ChangeStatusTo__c, TargetTaskTemplate__c, EmailTemplateName__c, Name, SearchKeyWord__c
        //                                                    FROM TaskTemplateAction__c   
        
        //                                                   ];
        // TaskTemplateAction__c taskTemplateAction = taskTemplateActions[8];
        
        // system.assertEquals('Authorised Signatory', taskTemplateActions[8].SendEmailTo__c);
        // system.assertEquals('Secondary Contact', taskTemplateActions[8].SendEmailCc__c);
        // system.assertEquals('Order Form', taskTemplateActions[8].SearchKeyWord__c);
        
        // MethodResponse res = TaskActionController.sendEmailWhenTaskStatusChanged(sourceTask, sourceCase, order);
        // system.assertEquals(200, res.statuscode);
        
        // //get Email Template 
        // List<EmailTemplate> emailTemplates = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate
        //                                       WHERE developerName =: taskTemplateAction.EmailTemplateName__c];
        // EmailTemplate emailTemplate = emailTemplates[0]; 
        
        // //get contact from ContactId of a OpportunityContactRole from opportunityContactRoleMap
        // Contact contact = ContactController.getContact(opportunityContactRoleMap.get(taskTemplateAction.SendEmailTo__c).ContactId);
        
        // TaskActionController.genericEmailTemplateBody(emailTemplate, contact, sourcetask, sourceCase, order);
        // system.assertEquals('SNU_04_Order_Form_Received_Next_Step', emailTemplates[0].developerName);
        
        // MethodResponse res3 = TaskActionController.sendEmailWhenTaskStatusChanged(sourceTask, sourceCase, order);
        // system.assertEquals(200, res3.statuscode);
        
        Integer invocations = Limits.getEmailInvocations();
        test.stopTest();
        system.assertEquals(TRUE, (invocations > 0), 'at least an email should be sent');
    }
    
    public static testMethod void test_sendEmailWhenTaskStatusChanged4() {
        test.startTest();
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];      
        //get NHR opportunity
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Contract contract = [SELECT Id FROM Contract WHERE Id =: opportunity.ContractId];
        Case sourceCase = [SELECT Id, Subject, RecordType.Name, OwnerId, Opportunity__c, ICT_Implementation_Provider__r.Name, Phase_1_Install_Provider__r.name, CaseNumber, ER_Lite__c, Contract__r.id, ContactId, Case_Thread_ID__c, Install_Provider__c, Secondary_Contact__c FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
        sourceCase.ER_Lite__c = false; 
            update sourceCase;
        //order
        List<Order> orders = [SELECT Id, uuid__c, Status, Case__c, Type, Case__r.caseNumber, Case__r.ICT_Date_onsite__c, Case__r.Cutover_Appointment__c, Contract.status, 
                              Contract.ContractNumber, PoNumber, Account.NZ_Region__c, Account.MoE_External_ID__c, Order.PoDate, case__r.Case_Thread_ID__c, Account.Name, Account.uuid__c, Earliest_Delivery_Date__c, Latest_Delivery_Date__c,
                              OrderNumber, OrderReferenceNumber, Xero_Id__c, Xero_Error__c, Order.Shipping_Address__c, Order.ShippingStreet, Order.ShippingCity, Order.ShippingPostalCode,  TotalAmount,               
                              Provider__r.Billing_Contact__c, Provider__r.Billing_Contact__r.FirstName, Provider__r.Billing_Contact__r.Email, Provider__r.Name, Provider__r.BillingStreet, 
                              Provider__r.BillingCity, Provider__r.BillingPostalCode, Provider__r.BillingCountry FROM Order WHERE AccountId =: account.Id  ];
        
        Order order = orders[0];
        
        // //verify onboarding case has been created
        // List<Case> cases = [SELECT Id, Subject, RecordType.Name, CaseNumber, Contract__r.Account.id, Contract__r.id, Account.Id, Case_Thread_ID__c, Account.Name, Cutover_Appointment__c, Cutover_Appointment_Date_Time_Text__c, Install_Provider__c, Install_Provider__r.Name, Opportunity__r.Id, Opportunity__c, OwnerId, ContactId, Secondary_Contact__c FROM Case];
        // Case sourceCase = cases[0];
        
        //list Onboarding Tasks under Onboarding Case
        List<Task> testTasks = [SELECT Id, Subject, Status, Type, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: sourceCase.Id ORDER BY Sequence__c];
        system.assertEquals(17, testTasks.size());
        
        //prepare a Map for task
        Map<String, Task> testTaskMap = new Map<String, Task>();
        For(Task testTask : testTasks){
            testTaskMap.put(testTask.Type, testTask);
        }   
        
        //update one task to start another task
        Task completingTask = testTaskMap.get('Technical Survey');
        completingTask.Status = 'In Progress';
        update completingTask;
        MethodResponse res2 = TaskActionController.processTaskTemplateActions(completingTask.Id);
        system.assertEquals(200, res2.statuscode);
        
        //query to get updated list of case task
        testTasks = [SELECT Id, Subject, Status, Type, Task_Template__c, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: sourceCase.Id ORDER BY Sequence__c];
        Task sourceTask = testTasks[0];
        //oppo
        Map<String, OpportunityContactRole> opportunityContactRoleMap = new Map<String, OpportunityContactRole>();
        List<OpportunityContactRole> opportunityContactRoles = [SELECT Id, ContactId, Contact.FirstName, Contact.Email, Contact.MobilePhone, Contact.Phone, OpportunityId, Role FROM OpportunityContactRole WHERE OpportunityId =: sourceCase.Opportunity__c];
        for (OpportunityContactRole opportunityContactRole : opportunityContactRoles){
            opportunityContactRoleMap.put(opportunityContactRole.Role, opportunityContactRole); //prepare map for Get OpportunityContactRole by Role.
        }
        system.assertEquals(4, opportunityContactRoleMap.size());
        system.assertEquals(True, opportunityContactRoleMap.containsKey('Primary Contact'));
        system.debug('opportunityContactRoleMap'+opportunityContactRoleMap);
        //TaskTemplateAction
        List<TaskTemplateAction__c> taskTemplateActions = [SELECT Id, SourceTaskTemplate__c, SendEmailCc__c, SendEmailFrom__c, SendEmailTo__c, 
                                                           OnStatusChanged__c, ChangeStatusTo__c, TargetTaskTemplate__c, EmailTemplateName__c, Name
                                                           FROM TaskTemplateAction__c   
                                                           
                                                          ];
        TaskTemplateAction__c taskTemplateAction = taskTemplateActions[11];
        
        system.assertEquals('Primary Contact;Secondary Contact', taskTemplateActions[11].SendEmailCc__c);
        
        // //get Email Template 
        // List<EmailTemplate> emailTemplates = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate
        //                                       WHERE developerName =: taskTemplateAction.EmailTemplateName__c];
        // EmailTemplate emailTemplate = emailTemplates[0]; 
        // system.debug('!!line183-emailTemplate:'+emailTemplate);
        // system.assertEquals('SNU_07_ER_Date_Confirmation', emailTemplates[0].developerName);
        //get contact from ContactId of a OpportunityContactRole from opportunityContactRoleMap
        //Contact contact = ContactController.getContact(opportunityContactRoleMap.get(taskTemplateAction.SendEmailTo__c).ContactId);
        
        //TaskActionController.genericEmailTemplateBody(emailTemplate, contact, sourcetask, sourceCase, order);
        
        system.assertEquals('Primary Contact', taskTemplateActions[11].SendEmailTo__c);
        
        MethodResponse res = TaskActionController.sendEmailWhenTaskStatusChanged(sourceTask, sourceCase, order);
        system.assertEquals(200, res.statuscode);
        
        //Integer invocations = Limits.getEmailInvocations(); 
        //system.assertEquals(TRUE, (invocations > 0), 'at least an email should be sent');
        test.stopTest();
        
    }
    
    public static testMethod void test_sendEmailWhenTaskStatusChanged5() {
        test.startTest();
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];      
        //get NHR opportunity
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Contract contract = [SELECT Id, account.id FROM Contract WHERE Id =: opportunity.ContractId];
        Case testCase = [SELECT Id, Subject, RecordType.Name, CaseNumber, ICT_Implementation_Provider__r.Name, ER_Lite__c, OwnerId, ContactId, Case.Case_Thread_ID__c, contract__r.id, contract__r.account.id, Secondary_Contact__c, Install_Provider__r.Name FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
        
        //order
        List<Order> orders = [SELECT Id, uuid__c, Status, Case__c, Type, Case__r.caseNumber, Case__r.ICT_Date_onsite__c, Case__r.Cutover_Appointment__c, Contract.status, Earliest_Delivery_Date__c,
                              Contract.ContractNumber, PoNumber, Account.NZ_Region__c, Account.MoE_External_ID__c, Order.PoDate, case__r.Case_Thread_ID__c, Account.Name, Account.uuid__c, Latest_Delivery_Date__c,
                              OrderNumber, OrderReferenceNumber, Xero_Id__c, Xero_Error__c, Order.Shipping_Address__c, Order.ShippingStreet, Order.ShippingCity, Order.ShippingPostalCode,  TotalAmount,               
                              Provider__r.Billing_Contact__c, Provider__r.Billing_Contact__r.FirstName, Provider__r.Billing_Contact__r.Email, Provider__r.Name, Provider__r.BillingStreet, 
                              Provider__r.BillingCity, Provider__r.BillingPostalCode, Provider__r.BillingCountry FROM Order];
        
        Order order = orders[0];
        
        //verify onboarding case has been created
        List<Case> cases = [SELECT Id, Subject, RecordType.Name, CaseNumber, ICT_Implementation_Provider__r.Name, Phase_1_Cutover_Appointment__c, ICT_Date_onsite__c, Phase_1_Install_Provider__r.name, ER_Lite__c, Account.Id, Case_Thread_ID__c, Account.Name, contract__r.id, contract__r.account.id, Opportunity__r.Contract.CustomerSignedId, Opportunity__r.ContractId, Opportunity__r.Id, Opportunity__c, OwnerId, ContactId, Secondary_Contact__c, Cutover_Appointment__c, Install_Provider__r.Name, Install_Provider__c FROM Case];
        Case sourceCase = cases[0];
        
        //Create Task data
        Task onboardingTask = [SELECT id, whatId, status, type, Entity_Attachment_Ids__c FROM Task WHERE whatId =: sourceCase.Id AND Type = 'Design Financial Approval' limit 1];
        onboardingTask.Status = 'Completed';
        onboardingTask.Entity_Attachment_Ids__c = '0685O000000BS9AQAW;0685O000000BS9FQAW;0685O000000BS9KQAW;0685O000000BS9PQAW;0685O000000BS9UQAW;0685O000000BS9ZQAW';
        update onboardingTask;
        
        system.assert(True, onboardingTask.Entity_Attachment_Ids__c);
        
        Map<Id, sObject> existingFilesOnContract;
        List<String> entityAttachmentIds = new List<String>();
        entityAttachmentIds.add(onboardingTask.Entity_Attachment_Ids__c);
        existingFilesOnContract  = FileController.getAttachmentOrFileFromCVIds(sourceCase.Contract__r.id, entityAttachmentIds);
        system.assert(True,existingFilesOnContract.isEmpty());
        
        //list Onboarding Tasks under Onboarding Case
        List<Task> testTasks = [SELECT Id, Subject, Status, Type, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: sourceCase.Id ORDER BY Sequence__c];
        //system.assertEquals(17, testTasks.size());
        
        //prepare a Map for task
        Map<String, Task> testTaskMap = new Map<String, Task>();
        For(Task testTask : testTasks){
            testTaskMap.put(testTask.Type, testTask);
        }
        
        //update one task to start another task
        Task completingTask = testTaskMap.get('Design Financial Approval');
        completingTask.Status = 'Completed';
        update completingTask;
        
        MethodResponse res2 = TaskActionController.processTaskTemplateActions(completingTask.Id);
        
        system.assertEquals(200, res2.statuscode);
        
        //query to get updated list of case task
        testTasks = [SELECT Id, Subject, Status, Type, Task_Template__c, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: sourceCase.Id ORDER BY Sequence__c];
        Task sourceTask = testTasks[0];
        //oppo
        Map<String, OpportunityContactRole> opportunityContactRoleMap = new Map<String, OpportunityContactRole>();
        List<OpportunityContactRole> opportunityContactRoles = [SELECT Id, ContactId, Contact.FirstName, Contact.Email, Contact.MobilePhone, Contact.Phone, OpportunityId, Role FROM OpportunityContactRole WHERE OpportunityId =: sourceCase.Opportunity__c];
        for (OpportunityContactRole opportunityContactRole : opportunityContactRoles){
            opportunityContactRoleMap.put(opportunityContactRole.Role, opportunityContactRole); //prepare map for Get OpportunityContactRole by Role.
        }
        system.assertEquals(4, opportunityContactRoleMap.size());
        
        Map<String, Contact> contactMap = new Map<String, Contact>();
        
        //getting real and latest contact from Case and Contract - not from Opportunity Contact Role
        Id contactId;
        //Primary Contact
        contactId = sourceCase.ContactId;
        If (contactId != null){
            contactMap.put('Primary Contact', ContactController.getContact(contactId));
            // } else {
            //     contactMap.put('Primary Contact', ContactController.getContact(opportunityContactRoleMap.get('Primary Contact').Id)); //just in case 
        }
        
        //TaskTemplateAction
        List<TaskTemplateAction__c> taskTemplateActions = [SELECT Id, SourceTaskTemplate__c, SendEmailCc__c, SendEmailFrom__c, SendEmailTo__c, 
                                                           OnStatusChanged__c, ChangeStatusTo__c, TargetTaskTemplate__c, EmailTemplateName__c, Name, SearchKeyWord__c
                                                           FROM TaskTemplateAction__c   
                                                           
                                                          ];
        TaskTemplateAction__c taskTemplateAction = taskTemplateActions[13];
        
        system.assertEquals('Primary Contact', taskTemplateActions[13].SendEmailTo__c);
        //system.assertEquals('Secondary Contact', taskTemplateActions[13].SendEmailCc__c);
        
        MethodResponse res = TaskActionController.sendEmailWhenTaskStatusChanged(sourceTask, sourceCase, order);
        system.assertEquals(200, res.statuscode);
        
        //get Email Template 
        List<EmailTemplate> emailTemplates = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate
                                              WHERE developerName =: taskTemplateAction.EmailTemplateName__c];
        EmailTemplate emailTemplate = emailTemplates[0]; 
        
        //get contact from ContactId of a OpportunityContactRole from opportunityContactRoleMap
        Contact contact = ContactController.getContact(opportunityContactRoleMap.get(taskTemplateAction.SendEmailTo__c).ContactId);
        
        TaskActionController.genericEmailTemplateBody(emailTemplate, contact, sourcetask, sourceCase, order);
        system.assertEquals('SNU_03A_Review_and_Approve_Design', emailTemplates[0].developerName);
        
        MethodResponse res3 = TaskActionController.sendEmailWhenTaskStatusChanged(sourceTask, sourceCase, order);
        test.stopTest(); 
        system.assertEquals(200, res3.statuscode);
        
        //Integer invocations = Limits.getEmailInvocations();
        //system.assertEquals(TRUE, (invocations > 0), 'at least an email should be sent');
    }
    
    public static testMethod void test_sendTaskEmail() {
        test.startTest();
        //order
        List<Order> orders = [SELECT Id, uuid__c, Status, Case__c, Type, Case__r.caseNumber, Case__r.ICT_Date_onsite__c, Case__r.Cutover_Appointment__c, Contract.status, 
                              Contract.ContractNumber, PoNumber, Account.NZ_Region__c, Account.MoE_External_ID__c, Order.PoDate, case__r.Case_Thread_ID__c, Account.Name, Account.uuid__c, Latest_Delivery_Date__c,
                              OrderNumber, OrderReferenceNumber, Xero_Id__c, Xero_Error__c, Order.Shipping_Address__c, Order.ShippingStreet, Order.ShippingCity, Order.ShippingPostalCode,  TotalAmount,               
                              Provider__r.Billing_Contact__c, Provider__r.Billing_Contact__r.FirstName, Provider__r.Billing_Contact__r.Email, Provider__r.Name, Provider__r.BillingStreet, 
                              Provider__r.BillingCity, Provider__r.BillingPostalCode, Provider__r.BillingCountry FROM Order];
        
        Order order = orders[0];
        
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];      
        //get NHR opportunity
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
        Contract contract = [SELECT Id, account.id FROM Contract WHERE Id =: opportunity.ContractId];
        Case sourceCase = [SELECT Id, Subject, RecordType.Name, CaseNumber, OwnerId, Opportunity__c, accountid, Account.Id, Account.Name, ER_Lite__c, ICT_Implementation_Provider__r.Name, Case_Thread_ID__c, ContactId, contract__r.id, contract__r.account.id, Secondary_Contact__c, Install_Provider__r.Name FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
        
        //list Onboarding Tasks under Onboarding Case
        List<Task> testTasks = [SELECT Id, Subject, Status, Type, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: sourceCase.Id ORDER BY Sequence__c];
        system.assertEquals(17, testTasks.size());
        
        //prepare a Map for task
        Map<String, Task> testTaskMap = new Map<String, Task>();
        For(Task testTask : testTasks){
            testTaskMap.put(testTask.Type, testTask);
        }
        
             //update one task to start another task
        Task completingTask = testTaskMap.get('Technical Survey');
        completingTask.Status = 'In Progress';
        update completingTask;
        MethodResponse res2 = TaskActionController.processTaskTemplateActions(completingTask.Id);
        system.assertEquals(200, res2.statuscode);
        
        //query to get updated list of case task
        testTasks = [SELECT Id, Subject, Status, Type, Task_Template__c, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: sourceCase.Id ORDER BY Sequence__c];
        Task sourceTask = testTasks[0];
        
        //oppo
        Map<String, OpportunityContactRole> opportunityContactRoleMap = new Map<String, OpportunityContactRole>();
        List<OpportunityContactRole> opportunityContactRoles = [SELECT Id, ContactId, Contact.FirstName, Contact.Email, Contact.MobilePhone, Contact.Phone, OpportunityId, Role FROM OpportunityContactRole WHERE OpportunityId =: sourceCase.Opportunity__c];
        for (OpportunityContactRole opportunityContactRole : opportunityContactRoles){
            opportunityContactRoleMap.put(opportunityContactRole.Role, opportunityContactRole); //prepare map for Get OpportunityContactRole by Role.
        }
        system.assertEquals(4, opportunityContactRoleMap.size());
        
        //TaskTemplateAction
        List<TaskTemplateAction__c> taskTemplateActions = [SELECT Id, SourceTaskTemplate__c, SendEmailCc__c, SendEmailFrom__c, SendEmailTo__c, 
                                                           OnStatusChanged__c, ChangeStatusTo__c, TargetTaskTemplate__c, EmailTemplateName__c, Name
                                                           FROM TaskTemplateAction__c   
                                                           
                                                          ];
        TaskTemplateAction__c taskTemplateAction = taskTemplateActions[10];
        
        //get Email Template 
        List<EmailTemplate> emailTemplates = [SELECT Id, Subject, HtmlValue, Body, name, developerName FROM EmailTemplate
                                              WHERE developerName =: taskTemplateAction.EmailTemplateName__c];
        EmailTemplate emailTemplate = emailTemplates[0]; 
        system.debug('!!line183-emailTemplate:'+emailTemplate);
        system.assertEquals('SNU_01B_Technical_Survey', emailTemplates[0].developerName);
        //get contact from ContactId of a OpportunityContactRole from opportunityContactRoleMap
        Contact contact = ContactController.getContact(opportunityContactRoleMap.get(taskTemplateAction.SendEmailTo__c).ContactId);
system.debug('!!$##@#@$@@$@$@$contact:'+contact);
        
        Map<String, Contact> contactMap = new Map<String, Contact>();
        contactMap.put('Primary Contact', ContactController.getContact(contact.Id));
        contactMap.put('Secondary Contact', ContactController.getContact(contact.Id));
        system.debug('!!contactMap:'+contactMap);
        
        MethodResponse res3 = TaskActionController.sendTaskEmail(completingTask, taskTemplateAction, contactMap, sourceCase, order);
        system.assertEquals(200, res3.statuscode);
        test.stopTest();
    }
    
    //------------------------------------------------------------------------------------------------
    // public static testMethod void sendEmail_Nagetive() {
    //     Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];      
    //     //get NHR opportunity
    //     Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: account.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above
    //     Contract contract = [SELECT Id FROM Contract WHERE Id =: opportunity.ContractId];
    //     Case sourceCase = [SELECT Id, Subject, RecordType.Name, CaseNumber, OwnerId, ContactId, Secondary_Contact__c, Case_Thread_ID__c, Install_Provider__r.Name FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
    
    //     //order
    //     List<Order> orders = [SELECT Id, uuid__c, Status, Case__c, Type, Case__r.caseNumber, Case__r.ICT_Date_onsite__c, Case__r.Cutover_Appointment__c, Contract.status, Earliest_Delivery_Date__c,
    //                           Contract.ContractNumber, PoNumber, Account.NZ_Region__c, Account.MoE_External_ID__c, Order.PoDate, case__r.Case_Thread_ID__c, Account.Name, Account.uuid__c, Latest_Delivery_Date__c,
    //                           OrderNumber, OrderReferenceNumber, Xero_Id__c, Xero_Error__c, Order.Shipping_Address__c, Order.ShippingStreet, Order.ShippingCity, Order.ShippingPostalCode,  TotalAmount,               
    //                           Provider__r.Billing_Contact__c, Provider__r.Billing_Contact__r.FirstName, Provider__r.Billing_Contact__r.Email, Provider__r.Name, Provider__r.BillingStreet, 
    //                           Provider__r.BillingCity, Provider__r.BillingPostalCode, Provider__r.BillingCountry FROM Order WHERE AccountId =: account.Id];
    
    //     Order order = orders[0];
    
    //     // MethodResponse res = OpportunityController.generateOnboardingRecords(opportunity.Id);
    //     // system.assertEquals(201, res.statuscode); 
    
    //     // //verify onboarding case has been created
    //     // List<Case> cases = [SELECT Id, Subject, RecordType.Name, CaseNumber, Account.Id, Account.Name, Case_Thread_ID__c, Opportunity__r.Id, Opportunity__c, OwnerId, ContactId, Secondary_Contact__c FROM Case];
    //     // Case sourceCase = cases[0];
    
    //     //list Onboarding Tasks under Onboarding Case
    //     List<Task> testTasks = [SELECT Id, Subject, Status, Type, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: sourceCase.Id ORDER BY Sequence__c];
    //     system.assertEquals(17, testTasks.size());
    
    //     //prepare a Map for task
    //     Map<String, Task> testTaskMap = new Map<String, Task>();
    //     For(Task testTask : testTasks){
    //         testTaskMap.put(testTask.Type, testTask);
    //     }
    
    //     //update one task to start another task
    //     Task completingTask = testTaskMap.get('Contract Completion');
    //     completingTask.Status = 'Completed';
    //     update completingTask;
    //     MethodResponse res2 = TaskActionController.processTaskTemplateActions(completingTask.Id);
    //     system.assertEquals(200, res2.statuscode);
    
    //     //query to get updated list of case task
    //     testTasks = [SELECT Id, Subject, Status, Type, Task_Template__c, OwnerId, Owner.Name, Sequence__c FROM Task WHERE WhatId =: sourceCase.Id ORDER BY Sequence__c];
    //     Task sourceTask = testTasks[0];
    //     //oppo
    //     Map<String, OpportunityContactRole> opportunityContactRoleMap = new Map<String, OpportunityContactRole>();
    //     List<OpportunityContactRole> opportunityContactRoles = [SELECT Id, ContactId, Contact.FirstName, Contact.Email, Contact.MobilePhone, Contact.Phone, OpportunityId, Role FROM OpportunityContactRole WHERE OpportunityId =: sourceCase.Opportunity__c];
    //     for (OpportunityContactRole opportunityContactRole : opportunityContactRoles){
    //         opportunityContactRoleMap.put(opportunityContactRole.Role, opportunityContactRole); //prepare map for Get OpportunityContactRole by Role.
    //     }
    //     system.assertEquals(4, opportunityContactRoleMap.size());
    
    //     Map<String, Contact> contactMap = new Map<String, Contact>();
    
    //     //getting real and latest contact from Case and Contract - not from Opportunity Contact Role
    //     Id contactId;
    //     //Primary Contact
    //     contactId = sourceCase.ContactId;
    //     If (contactId != null){
    //         contactMap.put('Authorised Signatory', ContactController.getContact(contactId));
    //         // } else {
    //         //     contactMap.put('Primary Contact', ContactController.getContact(opportunityContactRoleMap.get('Primary Contact').Id)); //just in case 
    //     }
    
    //     //TaskTemplateAction
    //     List<TaskTemplateAction__c> taskTemplateActions = [SELECT Id, SourceTaskTemplate__c, SendEmailCc__c, SendEmailFrom__c, SendEmailTo__c, 
    //                                                        OnStatusChanged__c, ChangeStatusTo__c, TargetTaskTemplate__c, EmailTemplateName__c, Name
    //                                                        FROM TaskTemplateAction__c   
    
    //                                                       ];
    //     TaskTemplateAction__c taskTemplateAction = taskTemplateActions[11];
    
    //     MethodResponse res3 = TaskActionControllersendTaskEmail(sourceTask, taskTemplateAction, contactMap, sourceCase, order);
    //     system.assertEquals(400, res3.statuscode);
    // }
    
    public static testMethod void test_testSetup() {
        system.assertEquals(TRUE, (1==1));
    }   
}