@IsTest
public with sharing class TestClassUtilityTest {
    
    static testMethod void test_createContact() {
        Account schoolAccount = TestClassUtility.createAccount('Baradene College',  'School');
        schoolAccount.uuid__c = 'schoola'; //for reporting test
        schoolAccount.MoE_School_ID__c = '100';
        insert schoolAccount;
        
        Contact principalContact = TestClassUtility.createContact(schoolAccount.Id, 'FirstName1', 'LastName1', 'email1@invalid-domain.com', '02711111111', 'Principal', True);
        insert principalContact;
        system.assertEquals(principalContact.FirstName, 'FirstName1');
    }

    static testMethod void test_createContact_nonSchool() {
        Account account = TestClassUtility.createAccount('Norcomm',  'Non-School Organisation');
        account.uuid__c = 'account1';
        insert account;

        Contact contact = TestClassUtility.createContact(account.Id, 'ICT', 'Tech002', 'ict.tech002@invalid-domain.com', '027444444');
        insert contact;
        system.assertEquals('ICT', contact.FirstName);
    }
    
    
    static testMethod void test_createInternalUser() {
        User rmUser = TestClassUtility.createInternalUser();
        insert rmUser;
        system.assertEquals(rmUser.username, 'internaluser@invalid-domain.com');
    }
    
    static testMethod void test_createInternalUserWithParams() {
        User rmUser = TestClassUtility.createInternalUser('testxyzn4', 'user');
        insert rmUser;
        system.assertEquals(rmUser.username, 'testxyzn4user@test.com');
    }
    
    static testMethod void test_createPowerCustomerSuccessUser_method() {
        //mostly copied from AccountControllerTest.cls
        Account ictAccount = TestClassUtility.createAccount('New Era IT',  'Non-School Organisation');
        insert ictAccount; 
        //we had to do this after a record is create because of process builder - Account Creation Process force the new account's Type = 'Other/Adhoc (Unmanaged). Waiting for system admin/helpdesk to manually update this value'
        ictAccount.Type = 'School ICT Provider';
        update ictAccount;
        
        
        String testEmail = 'ict.tech001@invalid-domain.com';
        
        Contact ictContact = TestClassUtility.createContact(ictAccount.Id, 'ICT', 'Tech001', testEmail, '0273333333', 'External ICT', False);
        insert ictContact;
        
        test.startTest();        
        Contact contact = [SELECT id, FirstName, LastName, email, Business_Role__c, Current_Principal_Of_This_School__c FROM Contact WHERE email =: testEmail];
        //create PowerCustomerSuccess user - external ICT personnel
        User ictUser = TestClassUtility.createPowerCustomerSuccessUser(contact);
        ictUser.UserPermissionsSchoolReportingUser__c = true; //allow user to getAccessibleSchools for School Reporting
        insert ictUser;
        
        test.stopTest();
        
        User testUser = [SELECT id, username, email, name, contactId, AccountId FROM User WHERE email =: testEmail ];
        
        System.assertEquals(testEmail, testUser.email); //should have access to schoola and schoolb, not schoolc
        
    }
    
    
    static testMethod void test_createCampaign() {
        //Campaign campaign = TestClassUtility.createCampaign('Filtering Portal (Pilot)', '', 'Filtering Portal', 'Onboarding', 'In Progress', 'Generic Campaign');
        Campaign campaign = TestClassUtility.createCampaign('Filtering Portal (Pilot)', '', 'Support Hub', 'Onboarding', 'In Progress', 'Generic Campaign');
        
        insert campaign;
        Campaign testCampaign = [SELECT id, Name, CampaignMemberRecordType.Name FROM Campaign WHERE id =: campaign.id LIMIT 1];
        system.assertEquals('Filtering Portal (Pilot)', testcampaign.name);
        system.assertEquals('Generic Campaign Member', testcampaign.CampaignMemberRecordType.Name); //'Generic Campaign Member' was hard coded in TestClassUtility.createCampaign 
    }
    
    static testMethod void test_createCampaignAccount() {
        test_createContact(); //create account
        test_createCampaign(); //create campaign
        
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola' LIMIT 1 ];
        Campaign campaign = [SELECT id, Name FROM Campaign WHERE Name =: 'Filtering Portal (Pilot)' LIMIT 1];
        Campaign_Account__c campaignAccount = TestClassUtility.createCampaignAccount(campaign, account);
        insert campaignAccount;
         
        //Campaign_Account__c testCampaignAccount = [SELECT id, Name, Campaign__c, Account__c FROM Campaign_Account__c WHERE Name=: 'NHR - SchoolA'];
        Campaign_Account__c testCampaignAccount = [SELECT id, Name, Campaign__c, Account__c FROM Campaign_Account__c WHERE Campaign__c=:campaign.id];
        system.debug('testCampaignAccount name ='+testCampaignAccount.name);
        //system.assertEquals('NHR - SchoolA', testCampaignAccount.name);
    }

    static testMethod void test_createCampaignAccountContact() {
        test_createCampaignAccount();
        
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola' LIMIT 1];
        Contact contact = [SELECT id, Name, email FROM Contact WHERE email = 'email1@invalid-domain.com' LIMIT 1 ];
        Campaign campaign = [SELECT id, Name FROM Campaign WHERE Name =: 'Filtering Portal (Pilot)' LIMIT 1];
        //Campaign_Account__c campaignAccount = [SELECT id, Name, Campaign__c, Account__c FROM Campaign_Account__c WHERE Name=: 'NHR - SchoolA'];
        Campaign_Account__c campaignAccount = [SELECT id, Name, Campaign__c, Account__c FROM Campaign_Account__c Where Campaign__c=:campaign.id];
        
        Campaign_Account_Contact__c campaignAccountContact = TestClassUtility.createCampaignAccountContact(campaign, contact, campaignAccount);
        insert campaignAccountContact;
        
        //Campaign_Account_Contact__c testcampaignAccountContact = [SELECT id, Campaign__c, Contact__c, Campaign_Account__c, Campaign_Account__r.Name FROM Campaign_Account_Contact__c WHERE Campaign_Account__r.Name =: 'NHR - SchoolA'];
         Campaign_Account_Contact__c testcampaignAccountContact = [SELECT id, Campaign__c, Contact__c, Campaign_Account__c, Campaign_Account__r.Name FROM Campaign_Account_Contact__c WHERE Campaign_Account__c=:campaignAccount.id];
        //system.assertEquals('NHR - SchoolA', testcampaignAccountContact.Campaign_Account__r.Name);
    }
    
    static testMethod void test_createOpportunity() {
        test_createContact(); //create account
        test_createCampaign(); //create campaign
        
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola' LIMIT 1 ];
        Campaign campaign = [SELECT id, Name FROM Campaign WHERE Name =: 'Filtering Portal (Pilot)' LIMIT 1];
        
        Opportunity opportunity  = TestClassUtility.createOpportunity(account, campaign, Date.Today(), 'Onboarding', 'New', 'Onboarding');
        insert opportunity;
        Opportunity testOpportunity  = [SELECT id, Name FROM Opportunity WHERE id =: opportunity.id LIMIT 1];
        system.assertEquals('Baradene College - Filtering Portal (Pilot)', testOpportunity.name); //Name = account.Name + ' - ' + campaign.name
        
    }
    
    static testMethod void test_createOpportunityContactRole() {
        test_createOpportunity();// prepare Account, Contact, Campaign and Opportunity
        
        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola' LIMIT 1 ];
        Contact principalContact = [SELECT Id, Name, Email FROM Contact WHERE Email = 'email1@invalid-domain.com'];
        Opportunity opportunity  = [SELECT id, Name FROM Opportunity WHERE AccountId =: account.id LIMIT 1];
        
        
        List<OpportunityContactRole> opportunityContactRoles = new List<OpportunityContactRole>();
        opportunityContactRoles.add(TestClassUtility.createOpportunityContactRole(principalContact, opportunity, 'Authorised Signatory'));
        insert opportunityContactRoles;
        
        List<OpportunityContactRole> testOpportunityContactRoles = [SELECT Id, ContactId, Contact.Email, Contact.MobilePhone, Contact.Phone, OpportunityId, Role FROM OpportunityContactRole WHERE OpportunityId =: opportunity.Id];
        system.assertEquals(1, testOpportunityContactRoles.size());
        system.assertEquals(principalContact.Email, testOpportunityContactRoles[0].Contact.Email);
        system.assertEquals('Authorised Signatory', testOpportunityContactRoles[0].Role);
        
        
    }
    
    static testMethod void test_createContract() {
        test_createContact(); //create account and principal contact
        
        String programmeName = Helper.getProgrammeNameMapping().get('NHR').Programme__c;

        Account account = [SELECT id, Name FROM Account WHERE uuid__c = 'schoola' LIMIT 1 ];
        Contact principalContact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c, Picture__c  FROM Contact WHERE email =: 'email1@invalid-domain.com'];
        
        Contract contract  = TestClassUtility.createContract(account, programmeName, principalContact, 'N4L Contract');
        insert contract;
        Contract testContract  = [SELECT id, Name FROM Contract WHERE id =: contract.id LIMIT 1];
        system.assertEquals('Baradene College - ' + programmeName, testContract.name); //Name = account.Name + ' - ' + Contract.Programme__c
    }
    
    
    static testMethod void test_createConfigAutoRecord() {
        String programmeName = Helper.getProgrammeNameMapping().get('NHR').Programme__c;
        ConfigAutoRecord__c configAutoRecordNHR = TestClassUtility.createConfigAutoRecord('NHR Config Auto Record', programmeName, 'Managed Network To The Classroom','', 'Onboarding', 'Case;Task;Contract', 'Test queue'); 
        insert configAutoRecordNHR;
        ConfigAutoRecord__c testConfigAutoRecord = [SELECT Id, Name, SObjectType__c, Programme__c, Product__c, Type__c FROM ConfigAutoRecord__c WHERE Name = 'NHR Config Auto Record' LIMIT 1];
        system.assertEquals('Case;Task;Contract', testConfigAutoRecord.SObjectType__c);
        system.assertEquals(programmeName, testConfigAutoRecord.Programme__c); 
        
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
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Invoice', 'Not Started', '100', 'Onboarding', 'Finance Queue'));
        taskTemplates.add(TestClassUtility.createTaskTemplate(configAutoRecordNHR.Id, 'Migration Complete', 'Not Started', '101', 'Onboarding', 'NSE/NHR Provisioning Queue'));
        insert taskTemplates;
        
        List<TaskTemplate__c> testTaskTemplates = [SELECT Id, Name, ConfigAutoRecord__c, Owner__c, Status__c, Type__c, Sequence__c, RecordTypeName__c FROM TaskTemplate__c WHERE ConfigAutoRecord__c =: configAutoRecordNHR.Id ORDER BY Sequence__c];
        system.assertEquals(true, testTaskTemplates.size()>0);
        system.assertEquals('005', testTaskTemplates[0].Sequence__c); 
        system.assertEquals('Technical Survey', testTaskTemplates[0].Type__c); 
    }
    
    static testMethod void test_createProductBundle() {
        String name = '';
        String productCode = '';
        String stockKeepingUnit = ''; 
        String description = '';
        String family = '';
        String productType = ''; 
        String quantityUnitOfMeasure = ''; 
        String recordTypeName = 'Quantity Based';
        
        List<Product2> products = new List<Product2>();
        
        //equipment product
        name = '8-Port POE+ Switch, 2x1G SFP Uplink Ports';
        productCode = 'ICX7150-C08P-2X1G-unitTest';
        stockKeepingUnit = productCode + '-N4L-unitTest'; //use -unitTest to prevent error: DUPLICATE_VALUE, A Product with this SKU already exists.: [StockKeepingUnit]
        description = 'ICX 7150 Compact Switch, 8x 10/100/1000 PoE+ ports, 2x 1G SFP uplink-ports, 62W PoE budget, L2 (switch image only)';
        family = 'Equipment';    
        quantityUnitOfMeasure = 'Each';
        Product2 equipmentProduct = TestClassUtility.createProduct(name, productCode, stockKeepingUnit, description, family, productType, quantityUnitOfMeasure, recordTypeName);
        products.add(equipmentProduct);
        
        //field services product
        name = 'SWITCH24';
        productCode = 'SWITCH24-unitTest';
        stockKeepingUnit = productCode + '-unitTest';
        description = 'To remove existing switch and install a new switch with less than 24 ports, including mounting, labelling, all patching, testing and commissioning';
        family = 'Field Services';    
        quantityUnitOfMeasure = 'Per Switch';
        Product2 requiresProduct1 = TestClassUtility.createProduct(name, productCode, stockKeepingUnit, description, family, productType, quantityUnitOfMeasure, recordTypeName);
        products.add(requiresProduct1);
        
        //equipment product
        name = 'NZ Power Cable (required for each switch)';
        productCode = 'PCAUS-unitTest';
        stockKeepingUnit = productCode + '-N4L-unitTest';
        description = 'Power Cable';
        family = 'Equipment';    
        quantityUnitOfMeasure = 'Each';
        Product2 requiresProduct2 = TestClassUtility.createProduct(name, productCode, stockKeepingUnit, description, family, productType, quantityUnitOfMeasure, recordTypeName);
        products.add(requiresProduct2);
        
        
        //bulk insert products
        insert products;
        
        List<Product2> testProducts = [SELECT id, Name FROM Product2 ];
        system.assertEquals(3, testProducts.size());
        
        //Product Bundle
        List<ProductBundle__c> productBundles = new List<ProductBundle__c>();
        productBundles.add(TestClassUtility.createProductBundle(equipmentProduct.Id, 'Field Services', requiresProduct1.Id));
        productBundles.add(TestClassUtility.createProductBundle(equipmentProduct.Id, 'Equipment', requiresProduct2.Id));
        
        //bulk insert product bundles
        insert productBundles;
        
        List<ProductBundle__c> testProductBundles = [SELECT id, EquipmentProduct__c, Family__c, RequiresProduct__c FROM ProductBundle__c WHERE EquipmentProduct__c =: equipmentProduct.Id ];
        system.assertEquals(2, testProductBundles.size());
    }
    
    //TO DO: Post Xero Integration deployment Refactor - consider creating TestObjectFactoryOrder
    static testMethod void test_createOrderAndRelatedData() {
        Order order = TestClassUtility.createOrderAndRelatedData(); //this method is used many times in Xero related classes.
        system.assertEquals('PO123123', order.PoNumber); //just to cover the code. 
    }

    static testMethod void test_setStaticMock_Success () {
        // Set the Mock Class
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock('XeroContactMock'));

        Test.startTest();
            HttpRequest request = new HttpRequest();
            HttpResponse response = new Http().send(request);// Execute the callout
            system.assertEquals(200, response.getStatusCode());
        Test.stopTest();
    }
    static testMethod void test_setStaticMock_Error () {
        // Set the Mock Class
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(500, 'XeroContactMock'));

        Test.startTest();
            HttpRequest request = new HttpRequest();
            HttpResponse response = new Http().send(request);// Execute the callout
            system.assertEquals(500, response.getStatusCode());
        Test.stopTest();
    }

    static testMethod void test_setMultiStaticMock_Success () {
        // Set the Multi Mock Class
        String xeroEndpoint = 'callout:Xero/api.xro/2.0';

        // Set the Mock Classes for the multiple callouts
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setMultiStaticMock(new Map<String, String>{
            xeroEndpoint + '/Contacts'  => 'XeroContactMock',
            xeroEndpoint + '/PurchaseOrders' => 'XeroPurchaseOrderMock'
        }));

        Test.startTest();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:Xero/api.xro/2.0/Contacts');
            HttpResponse response = new Http().send(request);// Execute the callout
            system.assertEquals(200, response.getStatusCode());
        Test.stopTest();
    }
}