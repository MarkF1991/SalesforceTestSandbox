/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 12th June 2020
* @description Batch class for deleting existing data on a Billing Recon batch
*
* CHANGE LOG
**/
public with sharing class BillingReconStatementDeleteDataBatch implements Database.Batchable<sObject> {

    // Load the service class used to manage statuses and errors
    public BillingReconService service;

    public BillingReconStatementDeleteDataBatch(Id billingReconStatementId) {

        // Load the service class to use across the batch
        this.service = new BillingReconService(billingReconStatementId);

        // Mark statement as having no file to process
        service.startPreparingStatus();
    }
    
    // Query for the Cost Lines to process
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
            SELECT 
                Id 
            FROM  
                Billing_Recon_Statement_Account__c  
            WHERE 
                Billing_Recon_Statement__c = :service.billingReconStatement.Id
        ]);
    }
    
    public void execute(Database.BatchableContext BC, List<Billing_Recon_Statement_Account__c> scope) {

        delete scope;
    }


    public void finish(Database.BatchableContext batchableContext) {

        // Run the variance calculation and store the new batch job id
        service.billingReconStatement.Batch_Job_Id__c = Database.executeBatch(new BillingReconUploadBatch(service.billingReconStatement.Id), 50);

        // Update status to Variance Processing
        service.startProcessingCsvStatus(); 
    }
}