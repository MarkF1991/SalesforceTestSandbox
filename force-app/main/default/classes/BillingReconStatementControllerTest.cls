/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 12th June 2020
* @description Test class for the BillingReconStatementController
*
* CHANGE LOG
**/
@isTest 
public class BillingReconStatementControllerTest {
    
    @TestSetup
    static void makeData(){
        
        // Create a test statement
        Billing_Recon_Statement__c testStatement = BillingReconTestData.createBillingReconData();
        Account testAccount = [SELECT Id FROM Account];
        Billing_Recon_Statement_Account__c testSchool = BillingReconTestData.createBillingReconSchool(testStatement.Id, testAccount.Id);
        BillingReconTestData.createBillingReconCosts(testStatement.Id, testSchool.Id);
    }

    @isTest 
    static void testController() {

        // Retrieve the test statement
        Billing_Recon_Statement__c testStatement = [SELECT Id FROM Billing_Recon_Statement__c];

        Test.startTest();

        BillingReconStatementController.getStatementAccounts(testStatement.Id);
        BillingReconStatementController.getStatusOptions();

        Test.stopTest();
    }
}