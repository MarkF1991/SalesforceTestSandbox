/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 29th May 2020
* @description Test class for the various XeroAPI methods
**/
@isTest
public class XeroAPITest {

    @TestSetup
    static void makeData(){
        
        TestClassUtility.createOrderAndRelatedData();
    }

    @isTest
    static void testSendAccountSuccess () {

        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        // Set the Mock Class
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'XeroContactMock'));

        Test.startTest();

        // Run the test to send the Account to Xero
        XeroAPI.sendAccount(testAccount.Id);

        Test.stopTest();

        // Assert that the Xero ID is saved against the Account
        testAccount = [SELECT Xero_Id__c FROM Account WHERE Id = :testAccount.Id];
        system.assertNotEquals(null, testAccount.Xero_Id__c, 'Xero ID should be saved against the Account.');
    }

    @isTest
    static void testSendAccountError () {

        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        // Set the Mock Class
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(500, 'XeroContactMock'));

        Test.startTest();

        // Run the test to send the Account to Xero
        XeroAPI.sendAccount(testAccount.Id);

        Test.stopTest();

        // Assert that the Xero ID is saved against the Account
        testAccount = [SELECT Xero_Error__c FROM Account WHERE Id = :testAccount.Id];
        system.assertNotEquals(null, testAccount.Xero_Error__c, 'Xero Error should be saved against the Account.');
    }


    @isTest
    static void testSendPurchaseOrderSuccess () {

        String xeroEndpoint = 'callout:Xero/api.xro/2.0';

        Order testOrder = [SELECT Id FROM Order];

        // Set the Mock Classes for the multiple callouts
        // Love this feature!
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setMultiStaticMock(new Map<String, String>{
            xeroEndpoint + '/Contacts'  => 'XeroContactMock',
            xeroEndpoint + '/PurchaseOrders' => 'XeroPurchaseOrderMock'
        }));

        Test.startTest();

        // Run the test to send the Purchase Order to Xero
        XeroAPI.sendPurchaseOrder(testOrder.Id);

        Test.stopTest();

        // Assert that the Xero ID is saved against the Account
        testOrder = [SELECT Xero_Id__c FROM Order];
        system.assertNotEquals(null, testOrder.Xero_Id__c, 'Xero Id should be saved against Purchase Order.');
    } 

    @isTest
    static void testGetXeroTenantIdSuccess () {
        // Set the Mock Class
        Test.setMock(HttpCalloutMock.class, TestClassUtility.setStaticMock(200, 'XeroTenantIdMock'));

        Test.startTest();

        // Run the test to send the Account to Xero
        String xeroTenantId = XeroAPI.getXeroTenantId();
        system.assertNotEquals(null, xeroTenantId, 'Xero Tenant Id should be returned.');
        Test.stopTest();
    }

    @isTest
    static void testChargeToXeroId () {
         Xero_Charge_To_Account_Mapping__mdt customMetaData = [SELECT Charge_To__c, Provider__c, Type__c, Xero_Contact_Id__c FROM Xero_Charge_To_Account_Mapping__mdt limit 1];
         Map<String, Xero_Charge_To_Account_Mapping__mdt> XeroChargeToAccountMapping = new Map<String, Xero_Charge_To_Account_Mapping__mdt>();
         Order testOrder = [SELECT id, Provider__r.name, Charge_To__c, Type, Provider__r.Xero_Id__c FROM Order];
         String xeroId = XeroPurchaseOrder.ChargeToXeroId(testOrder);

         String key = Helper.concatenateKey(new List<String>{
            testOrder.Charge_To__c,
            testOrder.Provider__r.name,
            testOrder.Type
        });
        
         XeroChargeToAccountMapping.put(key, customMetaData);
         system.assertEquals(testOrder.Provider__r.Xero_Id__c,xeroId);
         system.assertEquals(True,XeroChargeToAccountMapping.COntainsKey(key));
    }

}