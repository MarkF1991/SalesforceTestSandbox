/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 12th June 2020
* @description Batch class for processing of variance amounts for each cost line
*
* CHANGE LOG
**/
public with sharing class BillingReconVarianceBatch implements Database.Batchable<sObject>, Database.Stateful {

    // Load the service class used to manage statuses and errors
    public BillingReconService service;

    public BillingReconVarianceBatch(Id billingReconStatementId) {

        // Load the service class to use across the batch
        this.service = new BillingReconService(billingReconStatementId);

        // Mark statement as having no file to process
        service.startVarianceCalculationStatus();
    }
    
    // Query for the Cost Lines to process
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
            SELECT 
                Charge__c
                , Charge_Category__c
                , From_Date__c
                , To_Date__c
                // School Details
                , Statement_Account__r.Account__r.Billing_Initiative__c 
                , Statement_Account__r.Account__r.Billing_Total_Users__c
                , Statement_Account__r.Account__r.Current_CLNE_Make_Model__c
                , Statement_Account__r.Account__r.Current_Connection_Bandwidth__c  
                , Statement_Account__r.Account__r.Managed_Network_Service_MoE_Funding__c
                , Statement_Account__r.Account__r.LFC_Provider__c
                , Statement_Account__r.Account__r.LFC_Provider_Access_Type__c
                , Statement_Account__r.Account__r.School_Type__c
            FROM  
                Billing_Recon_Statement_Cost__c  
            WHERE 
                Statement_Account__r.Billing_Recon_Statement__c = :service.billingReconStatement.Id
              AND 
                Status__c = 'Not Processed'
        ]); 
    }
    
    public void execute(Database.BatchableContext BC, List<Billing_Recon_Statement_Cost__c> scope) {

        for (Billing_Recon_Statement_Cost__c cost :scope) {

            // Default charge to $0
            cost.Calculated_Charge__c = 0;

            // Mark as processed
            cost.Status__c = 'Processed'; 
            
            // If not unknown, we need to determine the matching Product
            // and Pricebook Entry, and then ultimately the variance
            if (cost.Charge_Category__c != 'Unknown') {

                // Calculate the charge
                try {

                    cost = BillingReconVarianceService.calculateCharge(cost);
                }
                catch (Exception ex) {

                    cost.Status__c = 'Error';
                    cost.Error__c = ex.getMessage();
                }
            }
        }

        update scope;
    }


    public void finish(Database.BatchableContext batchableContext) {

        // Finally, start the auto-reconciliation batch
        service.billingReconStatement.Batch_Job_Id__c = Database.executeBatch(new BillingReconAutoReconcileBatch(service.billingReconStatement.Id), 100);

        // Update status to Variance Processing
        service.startReconcilingStatus(); 
    }
}