/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 12th June 2020
* @description Batch class for calculating auto-reconciled lines
*
* CHANGE LOG
**/
public with sharing class BillingReconAutoReconcileBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    // Load the service class used to manage statuses and errors
    public BillingReconService service; 

    public BillingReconAutoReconcileBatch(Id billingReconStatementId) {

        // Load the service class to use across the batch
        this.service = new BillingReconService(billingReconStatementId);

        // Mark statement as having no file to process
        service.startReconcilingStatus();
    }
    
    // Query for the Cost Lines to process
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
            SELECT 
                Total_Variance__c 
            FROM  
                Billing_Recon_Statement_Account__c  
            WHERE 
                Billing_Recon_Statement__c = :service.billingReconStatement.Id
        ]);
    }
    
    public void execute(Database.BatchableContext BC, List<Billing_Recon_Statement_Account__c> scope) {

        for (Billing_Recon_Statement_Account__c school :scope) {

            if (school.Total_Variance__c == 0) {

                school.Status__c = 'Auto-reconciled';
            }
        }

        update scope;
    }

    public void finish(Database.BatchableContext batchableContext) {

        // Mark as done
        service.doneStatus(); 
    }
}