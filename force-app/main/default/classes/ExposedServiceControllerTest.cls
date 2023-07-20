@IsTest
public with sharing class ExposedServiceControllerTest {
    @TestSetup
    
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
        
    }
    
    static testMethod void test_createToken() {
        test.startTest();
        String type='School Contacts Update';
        //create account, campaign, campaignAccount - for the campaignAccountContact
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Campaign campaign = [SELECT id, name, Programme__c, product__c, type, status, RecordTypeId FROM Campaign WHERE name = 'NHR (Pilot)'];
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        Campaign_Account__c campaignAccount = TestClassUtility.createCampaignAccount(campaign, account);
        insert campaignAccount;
        Campaign_Account_Contact__c campaignAccountContact = TestClassUtility.createCampaignAccountContact(campaign, contact, campaignAccount);
        insert campaignAccountContact;
        campaignAccountContact = [SELECT Id, Campaign__c, Contact__c, Campaign_Account__r.Account__c  FROM Campaign_Account_Contact__c WHERE Id =: campaignAccountContact.Id];
        
        test.stopTest(); 
        system.debug('@@!!!Campaign'+campaign);
        system.debug('@@!!!campaignAccount'+campaignAccount);
        system.debug('@@!!!campaignAccountContact'+campaignAccountContact);
        
        MethodResponse testResponse = ExposedServiceController.createToken(campaignAccountContact, type);
        system.debug('@@!!!campaignAccountContact'+testResponse); 
        system.assertEquals(201, testResponse.statuscode);

        Token__c token = testResponse.token; 
        system.debug('@@!!!token'+token);
        system.assertEquals(campaignAccountContact.Campaign_Account__r.Account__c, token.Account__c);
        system.assertEquals(String.valueOf(campaignAccountContact.Campaign_Account__r.Account__c), token.RecordId__c);
        system.assertEquals('School Contacts Update', token.Type__c);
        system.assertEquals(campaignAccountContact.Contact__c, token.Approver__c); //the when creating the onboarding token, it should be able to pick approver of the school automatically
        system.assertEquals(false, token.IsClosed__c);
    }
    
    public static testMethod void test_send_CampaignAccount_Email() {
        String partialURL;
        partialURL = Helper.supportHubURL();
        
        test.startTest();
        String type='School Contacts Update';
        //create account, campaign, campaignAccount - for the campaignAccountContact
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];

        Campaign campaign = [SELECT id, name, Programme__c, Email_Template_Name__c, product__c, type, status, RecordTypeId FROM Campaign WHERE name = 'NHR (Pilot)'];
        campaign.Email_Template_Name__c = 'school key contact confirmation';
        update campaign;

        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        Campaign_Account__c campaignAccount = TestClassUtility.createCampaignAccount(campaign, account);
        insert campaignAccount;
        Campaign_Account_Contact__c campaignAccountContact = TestClassUtility.createCampaignAccountContact(campaign, contact, campaignAccount);
        insert campaignAccountContact;
        campaignAccountContact = [SELECT Id, Campaign__c, Contact__c, Campaign_Account__r.Account__c  FROM Campaign_Account_Contact__c WHERE Id =: campaignAccountContact.Id];
        
        
        
        MethodResponse testResponse = ExposedServiceController.createToken(campaignAccountContact, type);
        Token__c token = testResponse.token;
        testResponse = ExposedServiceController.send_CampaignAccount_Email(campaign.Id, token, partialURL,false);
        
        //system.assertEquals(200, testResponse.statuscode);
        
        Integer invocations = Limits.getEmailInvocations();
        //system.assertEquals(TRUE, (invocations > 0), 'at least an email should be sent');
        test.stopTest(); 
    }
    
    public static testMethod void test_campaign_email_actions(){ 
        String partialURL;
        partialURL = Helper.supportHubURL();
        
            //create account, campaign, campaignAccount - for the campaignAccountContact
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Campaign campaign = [SELECT id, name, Programme__c, Email_Template_Name__c, product__c, type, status, RecordTypeId FROM Campaign WHERE name = 'NHR (Pilot)'];
        campaign.Email_Template_Name__c = 'school key contact confirmation';
        update campaign;

        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        Campaign_Account__c campaignAccount = TestClassUtility.createCampaignAccount(campaign, account);
        insert campaignAccount;
        Campaign_Account_Contact__c campaignAccountContact = TestClassUtility.createCampaignAccountContact(campaign, contact, campaignAccount);
        insert campaignAccountContact;

        campaignAccountContact = [SELECT Id, Campaign__c, Contact__c, Campaign_Account__r.Account__c  FROM Campaign_Account_Contact__c WHERE Id =: campaignAccountContact.Id];
        AccountContactRelation actContactRelation = [SELECT Id, ContactId,accountid, Roles FROM AccountContactRelation WHERE ContactId =: contact.Id];
        //actContactRelation.roles = 'It Support';
        //update actContactRelation;
        test.startTest();//n4l
        MethodResponse testResponse = ExposedServiceController.campaign_email_actions(campaignAccountContact, partialURL,true);
        test.stopTest();//n4l
        //system.assertEquals(200, testResponse.statuscode);
    }
    
    public static testMethod void test_getCampaignAccounts(){
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Campaign campaign = [SELECT Id, name, Programme__c, product__c, type, status, RecordTypeId FROM Campaign WHERE name = 'NHR (Pilot)'];
        String input = '8900-';

        Map<String,String> testResult = ExposedServiceController.getCampaignAccounts(campaign.Id, input);
        system.assertEquals(False, testResult.isEmpty());

    }
    
    public static testMethod void negtive_test_getCampaignAccounts(){
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Campaign campaign = [SELECT Id, name, Programme__c, product__c, type, status, RecordTypeId FROM Campaign WHERE name = 'NHR (Pilot)'];
        String input = '';

        Map<String,String> testResult = ExposedServiceController.getCampaignAccounts(campaign.Id, input);
        system.assertEquals(False, testResult.isEmpty());

    }

    public static testMethod void test_getCampaignAccountContacts(){
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Campaign campaign = [SELECT id, name, Programme__c, Email_Targetted_Roles__c, product__c, type, status, RecordTypeId FROM Campaign WHERE name = 'NHR (Pilot)'];
        campaign.Email_Targetted_Roles__c = 'Principal;IT Support';
        update campaign;
        
        Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];
        Campaign_Account__c campaignAccount = TestClassUtility.createCampaignAccount(campaign, account);
        insert campaignAccount;
        campaignAccount = [SELECT id, name, campaign__c, account__c FROM Campaign_Account__c WHERE account__c =: account.id];
        
        Campaign_Account_Contact__c campaignAccountContact = TestClassUtility.createCampaignAccountContact(campaign, contact, campaignAccount);
        insert campaignAccountContact;

        campaignAccountContact = [SELECT Id, Campaign__c, Contact__c, Campaign_Account__r.Account__c  FROM Campaign_Account_Contact__c WHERE Id =: campaignAccountContact.Id];
        
        Map<String,String> testResult = ExposedServiceController.getCampaignAccountContacts(campaign.Id);
        system.assertEquals(False, testResult.isEmpty());
    }

    public static testMethod void test_sendCampaignEmail(){
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Campaign campaign = [SELECT id, name, Programme__c, product__c, type, status, RecordTypeId FROM Campaign WHERE name = 'NHR (Pilot)'];
    
        Map<String,String> testResult = ExposedServiceController.sendCampaignEmail(campaign.Id, 'todo');
        system.assert(testResult != null);
    }
    // public static testMethod void test_CampaignEmailQueue(){
    //     Campaign campaign = [SELECT id, name, Programme__c, product__c, type, status, RecordTypeId FROM Campaign WHERE name = 'NHR (Pilot)'];
    //     List<Campaign_Account_Contact__c> campaignMembers = new List<Campaign_Account_Contact__c>();
    //     List<Contact> contacts = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact];
        
    //     for(Contact contact : contacts){
    //         campaignMembers.add(new campaignAccountContact(
    //             contactId = contact.id,
    //             campaignId = campaign.id
    //         ));
    //     }
    //     insert campaignMembers;

    //     String partialURL = Helper.supportHubURL();

    //     // query for test data to pass to queueable class
    //     List<Campaign_Account_Contact__c> testCampaignMembers = [select id, FirstName, LastName from Campaign_Account_Contact__c];
    //     // Create our Queueable instance
    //     ExposedServiceController.CampaignEmailQueue campEmailQue = new ExposedServiceController.CampaignEmailQueue(campaignMembers, partialURL);
    //     // startTest/stopTest block to force async processes to run
    //     Test.startTest();        
    //     System.enqueueJob(campEmailQue);
    //     Test.stopTest();        
    //     // Validate the job ran
    // }
}