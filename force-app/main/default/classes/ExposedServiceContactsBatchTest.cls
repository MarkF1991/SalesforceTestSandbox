@isTest
public with sharing class ExposedServiceContactsBatchTest {
    @TestSetup
    
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
        
    }

        static testMethod void ExposedServiceContactsBatchTest(){
            Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola']; 
            Campaign campaign = [SELECT id, name, Programme__c, product__c, type, status, RecordTypeId FROM Campaign WHERE name = 'NHR (Pilot)'];
            Contact contact = [SELECT id, name, email, FirstName, LastName, AccountId, Business_Role__c FROM Contact WHERE email =: 'email2@invalid-domain.com'];

            Campaign_Account_Contact__c campaignAccountContact = new Campaign_Account_Contact__c();
            campaignAccountContact.contact__c = contact.id;
            campaignAccountContact.campaign__c = campaign.id;
            insert campaignAccountContact;

            Test.startTest();
            ExposedServiceContactsBatch campSchCttsBatch = new ExposedServiceContactsBatch(campaign.id);
            Id batchJobId = Database.executeBatch(campSchCttsBatch, 5);
            Test.stopTest();
            
        }

}