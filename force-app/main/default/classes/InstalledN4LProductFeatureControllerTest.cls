@isTest
public with sharing class InstalledN4LProductFeatureControllerTest {
    @TestSetup
    private static void setup(){
        TestObjectFactoryForOnboarding.setupOnboardingRecords(False); //Parameter False is for not creating Onboarding Case, Tasks, and Contract so that we can test it here.
    	List<Account> accounts = [SELECT id, Name FROM Account];  
        N4L_Product_Features__c productFeature = new N4L_Product_Features__c(Name='Test Product Feature', N4l_Product_Name__c='IEM');
        insert productFeature;
        List<Installed_N4L_Product_Feature__c> products = new List<Installed_N4L_Product_Feature__c>();
        for (Account account : accounts) {
            Installed_N4L_Product_Feature__c installedProduct = new Installed_N4L_Product_Feature__c();
            installedProduct.Name = 'Test Installed Product Feature';
            installedProduct.N4L_Product_Features__c = productFeature.Id;
            installedProduct.Organisation__c = account.Id;
            installedProduct.Active_Date__c = Date.today();
            installedProduct.Status__c = 'Active';
            products.add(installedProduct);
        }
        insert products;
    }

    public static testMethod void test_getAccountProductList() {
        List<Account> accounts = [SELECT id, Name FROM Account];      
        Account account = accounts[0];
        List<Installed_N4L_Product_Feature__c> products = InstalledN4LProductFeatureController.getAccountProductList(account.Id);
        system.assertEquals(1, products.size());
    }
}