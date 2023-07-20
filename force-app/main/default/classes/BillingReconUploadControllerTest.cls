/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 12th June 2020
* @description Test class for BillingReconUploadController
*
* CHANGE LOG
**/
@isTest 
public class BillingReconUploadControllerTest {

    @TestSetup
    static void makeData(){

        // Create the Billing Recon data
        BillingReconTestData.createBillingReconData();  
    }

    @isTest 
    static void testProcessCSV() {

        // Retrieve the test Billing Recon Statement
        Billing_Recon_Statement__c testStatement = [SELECT Id FROM Billing_Recon_Statement__c];

        Test.startTest();

        // Start the CSV job
        BillingReconUploadController.processCsv(testStatement.Id);

        // Check the status
        system.assertNotEquals(null, BillingReconUploadController.getStatus(testStatement.Id));

        // Check the canRetry boolean
        system.assert(!BillingReconUploadController.getCanRetry(testStatement.Id));

        // Retry the job
        Database.executeBatch(new BillingReconUploadBatch(testStatement.Id, true));

        Test.stopTest();
    }

}