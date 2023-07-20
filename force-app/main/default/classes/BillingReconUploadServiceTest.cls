/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 12th June 2020
* @description Test class for BillingReconUploadService
*
* CHANGE LOG
**/
@isTest 
public class BillingReconUploadServiceTest {
    
    @TestSetup
    static void makeData(){
        
        // Create a test statement
        Billing_Recon_Statement__c testStatement = BillingReconTestData.createBillingReconData();
        Account testAccount = [SELECT Id FROM Account];
        Billing_Recon_Statement_Account__c testSchool = BillingReconTestData.createBillingReconSchool(testStatement.Id, testAccount.Id);
        BillingReconTestData.createBillingReconCosts(testStatement.Id, testSchool.Id);
    }

    @isTest
    static void testServices() {

        Billing_Recon_Statement__c testStatement = [SELECT Id FROM Billing_Recon_Statement__c];

        system.assertNotEquals(null, BillingReconUploadService.getFile(testStatement.Id));
        system.assertNotEquals(null, BillingReconUploadService.getSchoolsMap());
        system.assertNotEquals(null, BillingReconUploadService.columnHeaderToField);
        system.assertNotEquals(null, BillingReconUploadService.getBillingReconStatementCostFields());

        // Test values
        system.assertNotEquals(null, BillingReconUploadService.getValue('Account_Number__c', '123456'));
        system.assertNotEquals(null, BillingReconUploadService.getValue('From_Date__c', '1/1/2020'));
        system.assertNotEquals(null, BillingReconUploadService.getValue('CSV_Row__c', '5'));
        system.assertNotEquals(null, BillingReconUploadService.getValue('Charge__c', '$100'));

        // Test blank value
        BillingReconUploadService.getValue('Account_Number__c', '');

        // Test CSV processing
        system.assertNotEquals(null, BillingReconUploadService.getCSVRowCells(
            'XXXX NOT FOUND,3508 2043,6/05/20,307211548,"N4L, 120947447",Additional Services,1/05/20,31/05/20,Safe & Secure,Connectivity,N,$96.50,'
        ));
    }
}