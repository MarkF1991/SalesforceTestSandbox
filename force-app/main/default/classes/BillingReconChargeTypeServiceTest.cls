/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 30th July 2020
* @description Test class for BillingReconChargeTypeService
*
* CHANGE LOG
**/
@isTest 
public class BillingReconChargeTypeServiceTest {
    
    @TestSetup
    static void makeData(){
        
        // Create a test statement
        Billing_Recon_Statement__c testStatement = BillingReconTestData.createBillingReconData();
        Account testAccount = [SELECT Id FROM Account];
        Billing_Recon_Statement_Account__c testSchool = BillingReconTestData.createBillingReconSchool(testStatement.Id, testAccount.Id);
        BillingReconTestData.createBillingReconCosts(testStatement.Id, testSchool.Id);
    }

    @isTest
    static void testGetChargeType() {

        Billing_Recon_Statement_Cost__c testCost = [SELECT Id FROM Billing_Recon_Statement_Cost__c LIMIT 1];

        Test.startTest();

        system.assertNotEquals(null, BillingReconChargeTypeService.getChargeType(testCost.Id));

        Test.stopTest();
    }
}