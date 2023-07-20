/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 12th June 2020
* @description Controller class for handling upload of CSV file
*
* CHANGE LOG
**/
public with sharing class BillingReconUploadController {

    // Handle upload of the CSV file to the reocrd
    @AuraEnabled
    public static void processCsv(Id billingReconStatementId){

        // Run the batch
        try {

            // Generate the statement
            Billing_Recon_Statement__c billingReconStatement = new Billing_Recon_Statement__c(Id = billingReconStatementId); 

            // Run the batch and store the Job ID against the statement
            billingReconStatement.Batch_Job_Id__c = Database.executeBatch(new BillingReconStatementDeleteDataBatch(billingReconStatementId), 50);
            update billingReconStatement;
        }
        catch (Exception ex){

            throw new AuraHandledException(ex.getMessage());
        }
    }

    // Retrieve the current batch status
    // Used to display to the user
    @AuraEnabled
    public static BillingReconStatementStatus getStatus(Id billingReconStatementId) { 

        try {
            // Return the Job Status component
            return new BillingReconStatementStatus(billingReconStatementId);
        }
        catch (Exception ex){

            throw new AuraHandledException(ex.getMessage());
        }
    }

    // Returns a Boolean if errors and a file exists
    @AuraEnabled(cacheable=true)
    public static Boolean getCanRetry(Id billingReconStatementId){

        Boolean hasFile = false;

        try {
            hasFile = BillingReconUploadService.getFile(billingReconStatementId) != null;
        }
        catch (Exception ex) {}

        // Query any errors
        Boolean hasErrors = ![SELECT Id FROM Billing_Recon_Error__c WHERE Billing_Recon_Statement__c = :billingReconStatementId].isEmpty();

        return hasFile && hasErrors;
    }

    // Wrapper class to hold the status variables to return to the page
    public class BillingReconStatementStatus {

        @AuraEnabled
        public String statementStatus;

        @AuraEnabled
        public Integer processedCount; 

        @AuraEnabled
        public Integer totalBatchSize; 

        public BillingReconStatementStatus(Id billingReconStatementId) {

            // Load the recon statement
            Billing_Recon_Statement__c reconStatement = [SELECT Batch_Job_Id__c, Status__c, Error__c FROM Billing_Recon_Statement__c WHERE Id = :billingReconStatementId];

            // Set the status
            this.statementStatus = reconStatement.Status__c;

            // Throw error to the LWC if an error has occurred during processing
            if (reconStatement.Status__c == 'Error') {
                throw new AuraHandledException(reconStatement.Error__c);
            }

            // Set the batch job status
            if (String.isNotBlank(reconStatement.Batch_Job_Id__c)) { 

                // Retrieve the Async Job
                try {
                    AsyncApexJob asyncBatchJob = [
                        SELECT 
                            JobItemsProcessed
                            , TotalJobItems
                            , ExtendedStatus
                        FROM 
                            AsyncApexJob 
                        WHERE 
                            Id = :reconStatement.Batch_Job_Id__c
                    ];

                    this.processedCount = asyncBatchJob.JobItemsProcessed;
                    this.totalBatchSize = asyncBatchJob.TotalJobItems; 
                }
                catch (Exception ex) {}
            }
        }
    }
}