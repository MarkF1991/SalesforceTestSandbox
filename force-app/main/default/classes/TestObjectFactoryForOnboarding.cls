@isTest
public with sharing class TestObjectFactoryForOnboarding {
    public static List<User> getAdminUser(){
        List<User> adminUsers =[select id from user where (profile.name ='N4L System Administrator' or profile.name ='System Administrator') and isactive=true limit 1];
        //system.debug('total system admin user number= '+adminUsers.size());
        return adminUsers;
    }    
    public static void setupOnboardingRecords(Boolean generateOnboardingRecords) {
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
            //SFB-176
            AccountContactRelation relationship =  [SELECT ContactId, Roles FROM AccountContactRelation WHERE  ContactId =: principalContact.Id AND IsActive = TRUE];
            relationship.Roles = 'principal';
            update relationship;
        }


        List<Contact> newContacts = new List<Contact>();
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName2', 'LastName2', 'email2@invalid-domain.com', '02722222222', 'ICT Leader', False));
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName3', 'LastName3', 'email3@invalid-domain.com', '02733333333', 'External ICT', False));
        newContacts.add(TestClassUtility.createContact(schoolAccount.Id, 'FirstName4', 'LastName4', 'email4@invalid-domain.com', '02744444444', 'External ICT', False));
        

        Contact exPrincipalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName5', 'LastName5', 'email5@invalid-domain.com', '02755555555', 'Principal', False);

        newContacts.add(exPrincipalContact);
        insert newContacts;

        exPrincipalContact.Inactive_Contact_Record__c = true;
        update exPrincipalContact;

        //unique for MOU Contract - the principal who is signing the contract must have a user record.
        //create external user - for the school principal
        User externalUser = TestClassUtility.createExternalUser(principalContact);
        insert externalUser;
        
        Contact schoolContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        User externalUser2 = TestClassUtility.createExternalUser(schoolContact);
        insert externalUser2;


        //create Campaigns
        List<Campaign> newCampaigns = new List<Campaign>();
        //newCampaigns.add(TestClassUtility.createCampaign('Filtering Portal (Pilot)', '', 'Filtering Portal', 'Onboarding', 'In Progress', 'Generic Campaign'));
        //newCampaigns.add(TestClassUtility.createCampaign('Identity Awareness (Pilot)', '', 'Identity Awareness', 'Onboarding', 'In Progress', 'Generic Campaign'));
        //newCampaigns.add(TestClassUtility.createCampaign('School Reporting (Pilot)', '', 'School Reporting', 'Onboarding', 'In Progress', 'Generic Campaign'));
        //newCampaigns.add(TestClassUtility.createCampaign('NHR (Pilot)', Helper.getProgrammeNameMapping().get('NHR').Programme__c, 'Managed Network To The Classroom', 'Onboarding', 'In Progress', 'Generic Campaign'));
        //newCampaigns.add(TestClassUtility.createCampaign('NSE (Pilot)', Helper.getProgrammeNameMapping().get('NSE').Programme__c, 'Managed Network Extension', 'Onboarding', 'In Progress', 'Generic Campaign'));
        newCampaigns.add(TestClassUtility.createCampaign('Filtering Portal (Pilot)', '', 'Support Hub', 'Onboarding', 'In Progress', 'Generic Campaign'));
        newCampaigns.add(TestClassUtility.createCampaign('Identity Awareness (Pilot)', '', 'N4L Website', 'Onboarding', 'In Progress', 'Generic Campaign'));
        newCampaigns.add(TestClassUtility.createCampaign('School Reporting (Pilot)', '', 'School Reporting', 'Onboarding', 'In Progress', 'Generic Campaign'));
        newCampaigns.add(TestClassUtility.createCampaign('NHR (Pilot)', Helper.getProgrammeNameMapping().get('NHR').Programme__c, 'Managed Network To The Classroom', 'Onboarding', 'In Progress', 'Generic Campaign'));
        newCampaigns.add(TestClassUtility.createCampaign('NSE (Pilot)', Helper.getProgrammeNameMapping().get('NSE').Programme__c, 'Internet Connection', 'Onboarding', 'In Progress', 'Generic Campaign'));
        insert newCampaigns;

        //create CampaignAccount
        List<Campaign_Account__c> newCampaignAccount = new List<Campaign_Account__c>();
        newCampaignAccount.add(TestClassUtility.createCampaignAccount(newCampaigns[3], schoolAccount));
        
        //create newCampaignAccountContacts
        List<Campaign_Account_Contact__c> newCampaignAccountContacts = new List<Campaign_Account_Contact__c>();
        newCampaignAccountContacts.add(TestClassUtility.createCampaignAccountContact(newCampaigns[3], newContacts[0], newCampaignAccount[0]));
        
        //create Opportunity
        List<Opportunity> newOpportunities = new List<Opportunity>();
        for (Integer i = 0; i < newCampaigns.size(); i++) {
            newOpportunities.add(TestClassUtility.createOpportunity(schoolAccount, newCampaigns[i], Date.Today(), 'Onboarding', 'New', 'Onboarding'));
        }
        insert newOpportunities;

        //get NHR opportunity
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE AccountId =: schoolAccount.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaing in Test Setup Method above

        //setup 4 Opportunity Contact Role
        List<OpportunityContactRole> opportunityContactRoles = new List<OpportunityContactRole>();
        opportunityContactRoles.add(TestClassUtility.createOpportunityContactRole(principalContact, opportunity, 'Authorised Signatory'));
        opportunityContactRoles.add(TestClassUtility.createOpportunityContactRole(newContacts[1], opportunity, 'Primary Contact'));
        opportunityContactRoles.add(TestClassUtility.createOpportunityContactRole(newContacts[2], opportunity, 'Secondary Contact'));
        opportunityContactRoles.add(TestClassUtility.createOpportunityContactRole(newContacts[3], opportunity, 'Technical Survey Contact'));
        insert opportunityContactRoles;



     //create ConfigAutoRecord__c
        List<ConfigAutoRecord__c> configAutoRecords = new List<ConfigAutoRecord__c>();

        ConfigAutoRecord__c configAutoRecordNHR = TestClassUtility.createConfigAutoRecord('NHR Config Auto Record', Helper.getProgrammeNameMapping().get('NHR').Programme__c, 'Managed Network To The Classroom', '', 'Onboarding', 'Case;Task;Contract', 'Test queue');//create case, task and contract
        ConfigAutoRecord__c configAutoRecordNSE = TestClassUtility.createConfigAutoRecord('NSE Config Auto Record', Helper.getProgrammeNameMapping().get('NSE').Programme__c, 'Internet Connection', '', 'Onboarding', 'Case', 'Test queue'); //create case only
        ConfigAutoRecord__c configAutoRecordComplexMACs = TestClassUtility.createConfigAutoRecord('Complex MAC', Helper.getProgrammeNameMapping().get('MAC').Programme__c, '','', 'Onboarding', 'Case;Task;Contract', 'Test queue'); //create case only
        ConfigAutoRecord__c configAutoRecordERlite = TestClassUtility.createConfigAutoRecord('ER Lite', Helper.getProgrammeNameMapping().get('NHR').Programme__c, 'Managed Network To The Classroom', 'ER Lite', 'Onboarding', 'Case;Task;Contract', 'Test queue'); //create case, task and contract
        configAutoRecords.add(configAutoRecordComplexMACs);
        configAutoRecords.add(configAutoRecordNHR);
        configAutoRecords.add(configAutoRecordNSE);
        configAutoRecords.add(configAutoRecordERlite);
        insert configAutoRecords;

        //Create TaskTemplate__c
        List<TaskTemplate__c> taskTemplates = new List<TaskTemplate__c>();

        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Technical Survey', 'In Progress', '005', 'Onboarding', 'NSE/NHR Provisioning Queue'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Design', 'Not Started', '010', 'Onboarding', 'NSE/NHR Provisioning Queue'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Design - Secure Access', 'Not Started', '015', 'Onboarding', 'NSE/NHR Provisioning Queue'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Assign ICT', 'Not Started', '020', 'Onboarding', 'Case Owner'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Assign Installer', 'Not Started', '021', 'Onboarding', 'Case Owner'));
        
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Design Financial Approval', 'Not Started', '040', 'Onboarding', 'NSE/NHR Provisioning Queue'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Contract Completion', 'Not Started', '050', 'Onboarding', 'Case Owner'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Schedule Work', 'Not Started', '060', 'Onboarding', 'Case Owner'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Release SOW - Installer', 'Not Started', '061', 'Onboarding', 'Case Owner'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Release SOW - ICT', 'Not Started', '062', 'Onboarding', 'Case Owner'));
        
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Order Equipment', 'Not Started', '070', 'Onboarding', 'Case Owner'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Pre Install Configuration', 'Not Started', '080', 'Onboarding', 'NSE/NHR Provisioning Queue'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Pre Migration Configuration', 'Not Started', '081', 'Onboarding', 'NSE/NHR Provisioning Queue'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Install Sign Off', 'Not Started', '090', 'Onboarding', 'NSE/NHR Provisioning Queue'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Migration Sign Off', 'Not Started', '091', 'Onboarding', 'NSE/NHR Provisioning Queue'));
        
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Invoice', 'Not Started', '100', 'Onboarding', 'ER Provisioning Coordinators Queue'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Migration Complete', 'Not Started', '101', 'Onboarding', 'NSE/NHR Provisioning Queue'));      
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNSE.Id, 'LAN Access', 'Not Started', '010', 'Onboarding', 'NSE/NHR Provisioning Queue'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNSE.Id, 'Wireless Access', 'Not Started', '020', 'Onboarding', 'NSE/NHR Provisioning Queue'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNSE.Id, 'Contract Completion', 'In Progress', '050', 'Onboarding', 'Case Owner'));
        
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNSE.Id, 'Switch Onboarding', 'Not Started', '060', 'Onboarding', 'NSE/NHR Provisioning Queue'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNSE.Id, 'Schedule Ruckus Migration', 'Not Started', '070', 'Onboarding', 'NSE/NHR Provisioning Queue'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNSE.Id, 'Ruckus Migration Completed', 'Not Started', '080', 'Onboarding', 'NSE/NHR Provisioning Queue'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNSE.Id, 'ZoneDirector Return', 'Not Started', '090', 'Onboarding', 'NSE/NHR Provisioning Queue'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNSE.Id, 'Licenses', 'Not Started', '100', 'Onboarding', 'NSE/NHR Provisioning Queue'));

        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordComplexMACs.Id, 'Design', 'Not Started', '005', 'Onboarding', 'Case Owner'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordComplexMACs.Id, 'Assign Installer', 'Not Started', '010', 'Onboarding', 'Case Owner'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordComplexMACs.Id, 'Design Financial Approval', 'Not Started', '015', 'Onboarding', 'Case Owner'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordComplexMACs.Id, 'Schedule Work', 'Not Started', '020', 'Onboarding', 'Case Owner'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordComplexMACs.Id, 'Release SOW - Installer', 'Not Started', '025', 'Onboarding', 'Case Owner'));

        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordERlite.Id, 'Design', 'Not Started', '005', 'Onboarding', 'Case Owner'));
        
        insert taskTemplates;

        //Get latest TaskTemplate__c of configAutoRecordNHR
        taskTemplates = [SELECT Id, Name, ConfigAutoRecord__c, Owner__c, Status__c, Type__c, Sequence__c, RecordTypeName__c FROM TaskTemplate__c WHERE ConfigAutoRecord__c =: configAutoRecordNHR.Id ORDER BY Sequence__c];

        Map<String, TaskTemplate__c> taskTemplateMap = new Map<String, TaskTemplate__c>();
        For(TaskTemplate__c taskTemplate : taskTemplates){
            taskTemplateMap.put(taskTemplate.Type__c, taskTemplate);
        }


        //Create TaskTemplateAction__c
        List<TaskTemplateAction__c> taskTemplateActions = new List<TaskTemplateAction__c>();
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Design').Id, taskTemplateMap.get('Design Financial Approval').Id, 'Completed', 'In Progress', '', '', '', '', '', '', ''));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Design Financial Approval').Id, taskTemplateMap.get('Contract Completion').Id, 'Completed', 'In Progress', '','', '', '', '', '', ''));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Contract Completion').Id, taskTemplateMap.get('Schedule Work').Id, 'Completed', 'In Progress', '', '', '', '', '', '', ''));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Schedule Work').Id, taskTemplateMap.get('Release SOW - Installer').Id, 'Completed', 'In Progress', '', '', '','', '', '', ''));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Release SOW - Installer').Id, taskTemplateMap.get('Order Equipment').Id, 'Completed', 'In Progress', '', '','', '', '', '', ''));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Release SOW - Installer').Id, taskTemplateMap.get('Pre Install Configuration').Id, 'Completed', 'In Progress', '', '', '', '', '', '', ''));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Release SOW - ICT').Id, taskTemplateMap.get('Pre Migration Configuration').Id, 'Completed', 'In Progress', '', '','', '', '', '', ''));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Install Sign Off').Id, taskTemplateMap.get('Invoice').Id, 'Completed', 'In Progress', null, '', '', '', '', '', ''));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Contract Completion').Id, null, 'Completed', '', 'SNU_04_Order_Form_Received_Next_Step', '', 'provision@n4l.co.nz', 'Authorised Signatory', 'Secondary Contact', 'Contract Completion', 'Order Form'));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Technical Survey').Id, null, 'In Progress', '', 'SNU_01A_Technical_Survey', '', 'provision@n4l.co.nz', 'Technical Survey Contact', 'Technical Survey Contact', 'Technical Survey', ''));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Technical Survey').Id, null, 'In Progress', '', 'SNU_01B_Technical_Survey', '', 'provision@n4l.co.nz', 'Primary Contact', 'Primary Contact; Secondary Contact', 'Technical Survey', ''));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Technical Survey').Id, null, 'In Progress', '', 'SNU_01B_Technical_Survey', '', 'provision@n4l.co.nz', 'Primary Contact', 'Primary Contact; Secondary Contact', 'Technical Survey', ''));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Schedule Work').Id, null, 'Completed', '', 'SNU_07_ER_Date_Confirmation', '', 'provision@n4l.co.nz', 'Primary Contact', 'Secondary Contact', 'Schedule Work > email Primary Contact', ''));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Design Financial Approval').Id, null, 'Completed', '', 'SNU_03A_Review_and_Approve_Design', '', 'provision@n4l.co.nz', 'Primary Contact', '', 'Design Financial Approval > email Primary Contact', ''));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Design').Id, null, 'In review with school', '', '', 'MNttC_ER_LITE_4a_Review_approve_design', 'provision@n4l.co.nz', 'Primary Contact', '', 'ER Lite 01) Design > email Primary Contact', ''));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Contract Completion').Id, null, 'Completed', '', '', 'MNttC_ER_LITE_5_Order_Form_received_next_steps', 'provision@n4l.co.nz', 'Authorised Signatory', '', 'ER Lite 05a) Contract Completion (ER) > email Authorised Signatory', ''));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Contract Completion').Id, null, 'Completed', '', 'SNU_ES_Onboarding_4a_Order_Form_completed_non_Ruckus', '', 'provision@n4l.co.nz', 'Authorised Signatory', '', 'ES01A) Contract Completion > Email Authorised Signatory NON-RUCKUS','Order Form'));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Contract Completion').Id, null, 'Completed', '', 'SNU_ES_Onboarding_4b_Order_Form_completed_Ruckus_Schedule', '', 'provision@n4l.co.nz', 'Authorised Signatory', '', 'ES01B) Contract Completion > Email Authorised Signatory RUCKUS','Order Form'));
        taskTemplateActions.add(TestClassUtility.createTaskTemplateAction(taskTemplateMap.get('Contract Completion').Id, null, 'Completed', '', 'SNU_ES_Onboarding_4b_Order_Form_completed_Ruckus_Schedule', '', 'provision@n4l.co.nz', 'Primary Contact', '', 'ES01C) Contract Completion > Email Primary Contact RUCKUS','Order Form'));

        insert taskTemplateActions;


        if (generateOnboardingRecords){
            //create Onboarding Case and Tasks and Contract for NHR
            MethodResponse res = OpportunityController.generateOnboardingRecords(opportunity.Id);
            system.debug('@@@@@@@@@@@@@'+res);
        }
    }

    public static void setupOnboardingRecordsWithOrders(){
        setupOnboardingRecords(true);

        //get schoola Account and NHR opportunity - which were created in TestObjectFactoryForOnboarding.setupOnboardingRecords(True);
        Account schoolAccount = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];      
        Opportunity opportunity = [SELECT Id, AccountId, Campaign.Programme__c, Campaign.Product__c, Campaign.Type, ContractId  FROM Opportunity WHERE AccountId =: schoolAccount.Id AND Campaign.Name = 'NHR (Pilot)']; //refer to createCampaign in Test Setup Method above
        Contract contract = [SELECT Id FROM Contract WHERE Id =: opportunity.ContractId];
        Case onboardingCase = [SELECT Id, Subject, RecordType.Name, OwnerId, ContactId, Secondary_Contact__c, Install_Provider__r.Name FROM Case WHERE Opportunity__c =: opportunity.Id LIMIT 1];
        
        //create providers
        // Account provider = TestClassUtility.createAccount('exeed',  'Non-School Organisation');
        // insert provider;
        List<Account> providers = new List<Account>();
        providers.add(TestClassUtility.createAccountWithUUID('equipmentProvider1',  'Non-School Organisation', 'equipmentProvider1'));
        providers.add(TestClassUtility.createAccountWithUUID('equipmentProvider2',  'Non-School Organisation', 'equipmentProvider2'));
        providers.add(TestClassUtility.createAccountWithUUID('sowInstaller1',  'Non-School Organisation', 'sowInstaller1'));
        providers.add(TestClassUtility.createAccountWithUUID('sowInstaller2',  'Non-School Organisation', 'sowInstaller2'));
        providers.add(TestClassUtility.createAccountWithUUID('SOW1ICT',  'Non-School Organisation', 'SOW1ICT'));
        providers.add(TestClassUtility.createAccountWithUUID('SOW2ICT',  'Non-School Organisation', 'SOW2ICT'));
        providers.add(TestClassUtility.createAccountWithUUID('eWaste1',  'Non-School Organisation', 'eWaste1'));
        providers.add(TestClassUtility.createAccountWithUUID('eWaste2',  'Non-School Organisation', 'eWaste2'));
        insert providers;

        //create provider.contact
        //Contact providerContact = TestClassUtility.createContact(provider.Id, 'FirstName6', 'LastName6', 'email6@invalid-domain.com', '027666666', 'ICT Leader', False);
        //insert providerContact;
        List<Contact> providerContacts = new List<Contact>();
        For (Account provider : providers){
            providerContacts.add(TestClassUtility.createContact(provider.Id, 'BillingContact', provider.uuid__c, provider.uuid__c + '@invalid-domain.com', '027666666', 'ICT Leader', False));
        }
        insert providerContacts;

        Map<Id, Contact> billingContactMap = new Map<Id, Contact>();
        For (Contact providerContact : providerContacts){
            billingContactMap.put(providerContact.accountId, providerContact);
        }
        
        Map<String, Account> providerMap = new Map<String, Account>();
        //update provider's billing contact and address to show in order
        For (Account provider : providers){
            provider.Billing_Contact__c = billingContactMap.get(provider.Id).Id;
            provider.BillingStreet = '123 Beautiful Street';
            provider.BillingCity = 'Auckland';
            provider.BillingPostalCode = '1234';
            provider.BillingCountry = 'New Zealand';
            provider.Xero_Id__c = '3a39dfce-0489-4041-a8c4-788e42bb939d'; //copied from XeroContactMock.txt in static resource. Without this, the orderControllerTest unit test will fail
            providerMap.put(provider.uuid__c, provider);
        }
        update providers;
        

        
        // provider.Billing_Contact__c = providerContact.Id;
        // provider.BillingStreet = '123 Beautiful Street';
        // provider.BillingCity = 'Auckland';
        // provider.BillingPostalCode = '1234';
        // provider.BillingCountry = 'New Zealand';
        // update provider;
        
        Account provider = AccountController.getAccount_uuid('equipmentProvider1');
         
        //update case
        onboardingCase.Install_Provider__c = provider.id;
        update onboardingCase;
        
        //create pricebook
        //List<Pricebook2> pricebooks = [SELECT id, Name FROM Pricebook2 WHERE Name = 'exeed' LIMIT 1];
        // Pricebook2 pricebook = new Pricebook2(
        //     name = 'exeed',
        //     provider__c = provider.Id
        // );
        // insert pricebook;

        List<Pricebook2> pricebooks = new List<Pricebook2>();
        pricebooks.add(new Pricebook2(
            name = providerMap.get('equipmentProvider1').Name + ' - Equipment',
            provider__c = providerMap.get('equipmentProvider1').Id,
            Description = providerMap.get('equipmentProvider1').Name,
            IsActive = true
        )); 
        pricebooks.add(new Pricebook2(
            name = providerMap.get('equipmentProvider2').Name + ' - Equipment',
            provider__c = providerMap.get('equipmentProvider2').Id,
            Description = providerMap.get('equipmentProvider2').Name,
            IsActive = true
        ));
        pricebooks.add(new Pricebook2(
            name = providerMap.get('sowInstaller1').Name + ' - Install',
            provider__c = providerMap.get('sowInstaller1').Id,
            Description = providerMap.get('sowInstaller1').Name,
            IsActive = true
        )); 
        pricebooks.add(new Pricebook2(
            name = providerMap.get('sowInstaller2').Name + ' - Install',
            provider__c = providerMap.get('sowInstaller2').Id,
            Description = providerMap.get('sowInstaller2').Name,
            IsActive = true
        )); 
        pricebooks.add(new Pricebook2(
            name = providerMap.get('SOW1ICT').Name,
            provider__c = providerMap.get('SOW1ICT').Id,
            Description = providerMap.get('SOW1ICT').Name,
            IsActive = true
        )); 
        pricebooks.add(new Pricebook2(
            name = providerMap.get('SOW2ICT').Name,
            provider__c = providerMap.get('SOW2ICT').Id,
            Description = providerMap.get('SOW2ICT').Name,
            IsActive = true
        )); 
        insert pricebooks;


        
        //create product2
        Id recordTypeId = TestClassUtility.getRecordTypeId(Schema.SObjectType.Product2, 'Quantity Based');
        List<Product2> products = new List<Product2>();
        products.add(new Product2(
            name = '24-Port Switch, no Power Supply or Fans',
            ProductCode = 'ICX7450-24',
            Description = '24-Port Switch, no Power Supply or Fans',
            QuantityUnitOfMeasure = 'Each',
            Family = 'Equipment',
            Warranty_Term_Months__c = 12,
            RecordTypeId = recordTypeId

        )); 
        products.add(new Product2(
            name = '48-Port POE+ 370W Switch, 4x1G SFP+ Uplink Ports',
            ProductCode = 'ICX7150-48P-4X1G',
            Description = 'ICX 7150 Switch, 48x 10/100/1000 PoE+ ports, 2x 1G RJ45 uplink-ports, 2x 1G SFP and 2x 10G SFP+ uplink-ports upgradable to 4x 10G SFP+',
            QuantityUnitOfMeasure = 'Each',
            Family = 'Equipment',
            Warranty_Term_Months__c = 12,
            RecordTypeId = recordTypeId
        ));  
        products.add(new Product2(
            name = 'R650 Dual Band 11ax Indoor AP, 2/4 Stream',
            ProductCode = '901-R650-WW00',
            Description = 'R650 Dual Band, Wi-Fi 6, 4x4:4 5GHz, 2x2:2 2.4GHz Access Point',
            QuantityUnitOfMeasure = 'Each',
            Family = 'Equipment',
            Warranty_Term_Months__c = 12,
            RecordTypeId = recordTypeId
        ));  
        products.add(new Product2(
            name = '- Install Switch 24 Ports',
            ProductCode = 'SWITCH24',
            Description = 'To remove existing switch and install a new switch with up to and including 24 ports, including mounting, labelling, all patching, testing and commissioning',
            QuantityUnitOfMeasure = 'Per Switch',
            Family = 'Field Services',
            Warranty_Term_Months__c = 12,
            RecordTypeId = recordTypeId
        ));  
        products.add(new Product2(
            name = '- Install Switch 48 Ports',
            ProductCode = 'SWITCH48',
            Description = 'To remove existing switch and install a new switch with more than 24 ports, including mounting, labelling, all patching, testing and commissioning',
            QuantityUnitOfMeasure = 'Per Switch',
            Family = 'Field Services',
            Warranty_Term_Months__c = 12,
            RecordTypeId = recordTypeId
        ));  
        products.add(new Product2(
            name = '- Install Access Point to 2.5m',
            ProductCode = 'AP',
            Description = 'To install a new WIFI AP including mounting, labelling, all patching, testing and commissioning (to existing cabling) up to and including 2.5M',
            QuantityUnitOfMeasure = 'Per Access Point',
            Family = 'Field Services',
            Warranty_Term_Months__c = 12,
            RecordTypeId = recordTypeId
        ));  
        insert products;  

        
        //Create PricebookEntry
        Id standardpricebookid = Test.getStandardPricebookId();
        List<PricebookEntry> pricebookEntries =  new List<PricebookEntry>();
        For(Product2 product : products){
            //add standard pricebook entry
            pricebookEntries.add(new PricebookEntry(
                Product2Id = product.Id,
                Pricebook2Id = standardpricebookid,
                UnitPrice = 1000,
                BuyPrice__c = 1000,
                isActive = true       
            ));
        }
        for(Pricebook2 pricebook : pricebooks){
            For(Product2 product : products){
                //add custom pricebook entry
                if (product.Family == 'Equipment' && pricebook.Name.contains('Equipment')){
                    pricebookEntries.add(new PricebookEntry(
                        Product2Id = product.Id,
                        Pricebook2Id = pricebook.Id,
                        UnitPrice = 1000,
                        BuyPrice__c = 1000,
                        isActive = true
                    ));
                }
                if (product.Family == 'Field Services' && pricebook.Name.contains('Install')){
                    pricebookEntries.add(new PricebookEntry(
                        Product2Id = product.Id,
                        Pricebook2Id = pricebook.Id,
                        UnitPrice = 500,
                        BuyPrice__c = 500,
                        isActive = true
                    ));
                }
            }
        }
        insert pricebookEntries;


        pricebooks = [SELECT id, Name, Provider__c, Description,
                            (SELECT Id,Pricebook2Id,Product2Id, Product2.Family,Product2.Name, UnitPrice FROM PricebookEntries WHERE IsActive = true)
                     FROM Pricebook2 WHERE IsStandard = False];

        Map<Id, Pricebook2> pricebookMap = new Map<Id, Pricebook2>(pricebooks);
        Map<String, Pricebook2> pricebooksMapByName = new Map<String, Pricebook2>();
        for(Pricebook2 pricebook : pricebooks){
            pricebooksMapByName.put(pricebook.Description, pricebook);
        }

        
        //create orders
        List<Order> orders =  new List<Order>();
        orders.add(new Order(
            AccountId = schoolAccount.Id,
            Case__c = onboardingCase.id,
            Status = 'Draft',
            PoDate = date.today(),
            EffectiveDate = date.today(),
            PoNumber = 'PO11111',
            Provider__c = pricebooksMapByName.get('equipmentProvider1').Provider__c,
            Pricebook2Id = pricebooksMapByName.get('equipmentProvider1').Id,
            ContractId = contract.Id,
            ShippingCountry = 'New Zealand',
            ShippingCity = 'Auckland',
            ShippingStreet = '123 Queen Street',
            ShippingPostalCode = '0622',
            CompanyAuthorizedById = UserInfo.getUserId(),
            Type = 'Equipment - New',
            Latest_Delivery_Date__c = date.today(),
            Earliest_Delivery_Date__c = date.today(),
            Description = 'equipmentProvider1Order'
        ));
        orders.add(new Order(
            AccountId = schoolAccount.Id,
            Case__c = onboardingCase.id,
            Status = 'Draft',
            PoDate = date.today(),
            EffectiveDate = date.today(),
            PoNumber = 'PO22222',
            Provider__c = pricebooksMapByName.get('sowInstaller1').Provider__c,
            Pricebook2Id = pricebooksMapByName.get('sowInstaller1').Id,
            ContractId = contract.Id,
            ShippingCountry = 'New Zealand',
            ShippingCity = 'Auckland',
            ShippingStreet = '123 Queen Street',
            ShippingPostalCode = '0622',
            CompanyAuthorizedById = UserInfo.getUserId(),
            Type = 'SOW - Installer',
            Latest_Delivery_Date__c = date.today(),
            Earliest_Delivery_Date__c = date.today(),
            Description = 'sowInstaller1Order'
        ));
        Test.setMock(HttpCalloutMock.class, new CalloutMock());
        orders.add(new Order(
            AccountId = schoolAccount.Id,
            Case__c = onboardingCase.id,
            Status = 'Draft',
            PoDate = date.today(),
            EffectiveDate = date.today(),
            PoNumber = 'PO3333',
            Pricebook2Id = pricebooksMapByName.get('SOW1ICT').Id,
            ContractId = contract.Id,
            ShippingCountry = 'New Zealand',
            ShippingCity = 'Auckland',
            ShippingStreet = '123 Queen Street',
            ShippingPostalCode = '0622',
            CompanyAuthorizedById = UserInfo.getUserId(),
            Type = 'SOW 1 - ICT',
            Latest_Delivery_Date__c = date.today(),
            Earliest_Delivery_Date__c = date.today(),
            Description = 'sow1'
        ));
        Insert orders;

        //create order items for the orders above, based on relative pricebook entries
        List<OrderItem> orderItems = new List<OrderItem>();
        for(Order order : orders){
            For(PricebookEntry entry : pricebookMap.get(order.Pricebook2Id).PricebookEntries){
                orderItems.add(new OrderItem(
                    OrderId = order.Id,
                    Quantity = 10,
                    UnitPrice = entry.UnitPrice,
                    Discount__c = 0,
                    PricebookEntryid = entry.id
                ));
            }
        }
        Insert orderItems;
        
        // Map<string, Order> ordersMap = New Map<string, Order>();
        // For(Order order : orders){
        //     ordersMap.put(order.PoNumber, order);
        // }

        // List<PricebookEntry> entries = [SELECT Id,Pricebook2Id,Product2Id, Product2.Family FROM PricebookEntry WHERE Pricebook2Id =: pricebook.Id];          
        // Map<string, List<PricebookEntry>> entriesMap = New Map<string, List<PricebookEntry>>();
        // For(PricebookEntry entry : entries){
        //     if (entriesMap.containsKey(entry.Product2.Family)){
        //         entriesMap.get(entry.Product2.Family).add(entry);
        //     } else {
        //         List<PricebookEntry> newList =  new List<PricebookEntry>();
        //         newList.add(entry);
        //         entriesMap.put(entry.Product2.Family, newList);
        //     }
        // }

        // List<OrderItem> orderItems = new List<OrderItem>();
        //     For(PricebookEntry entry : entriesMap.get('Equipment')){
        //         orderItems.add(new OrderItem(
        //             OrderId = ordersMap.get('PO11111').Id,
        //             Quantity = 10,
        //             UnitPrice = 1000,
        //             Discount__c = 0,
        //             PricebookEntryid = entry.id
        //         ));
        //     }
        //     For(PricebookEntry entry : entriesMap.get('Field Services')){
        //         orderItems.add(new OrderItem(
        //             OrderId = ordersMap.get('PO22222').Id,
        //             Quantity = 10,
        //             UnitPrice = 1000,
        //             Discount__c = 0,
        //             PricebookEntryid = entry.id
        //         ));
        //     }
        // Insert orderItems;
 


        //prepare existing site locations
        List<Site_Location__c> locations = new List<Site_Location__c>();
        locations.add(new Site_Location__c(
            Organisation__c = schoolAccount.Id,
            Source_Data_UUID__c = '711ca8bb-630f-4897-b050-c3d191a7bd5e',
            MoE_PMIS_ID__c = 'ministryId',
            MoE_PMIS_Number__c = 'ministryNumber',
            MoE_PMIS_Name__c = 'ministryName',
            Name = 'buildingName',
            Alias__c = 'code',
            Type__c = 'Building',
            Parent_Location__c = null //building does not have parent record
        ));
        insert locations;
        
        
        
        //Email Template

        

    }
    
}