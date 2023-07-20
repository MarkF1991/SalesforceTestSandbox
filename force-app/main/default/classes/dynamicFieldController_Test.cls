@isTest
public class dynamicFieldController_Test {
@TestSetup
    
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecordsWithOrders();
        
    }
    
    static testMethod void test_getEmailTemplate() {
        test.startTest();
        dynamicFieldController.getEmailTemplate();
        test.stopTest();
    }
    
    static testMethod void test_Email_Template_Name() {
        test.startTest();
        //create account, campaign, campaignAccount - for the campaignAccountContact
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Campaign campaign = [SELECT id, name, Programme__c, Email_Template_Name__c, product__c, type, status, RecordTypeId FROM Campaign WHERE name = 'NHR (Pilot)'];
        dynamicFieldController.Email_Template_Name(campaign.id);
        test.stopTest(); 
    }
    
    static testMethod void test_Update_Email_Template() {
        test.startTest();
        //create account, campaign, campaignAccount - for the campaignAccountContact
        Account account = [SELECT Id, Name FROM Account WHERE uuid__c = 'schoola'];
        Campaign campaign = [SELECT id, name, Programme__c, Email_Template_Name__c, product__c, type, status, RecordTypeId FROM Campaign WHERE name = 'NHR (Pilot)'];
        dynamicFieldController.Update_Email_Template(campaign.id);
        test.stopTest(); 
    }
}