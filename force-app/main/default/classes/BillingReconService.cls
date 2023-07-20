/**
* @author Ben Edwards (beedwards@deloitte.co.nz)
* @date 12th June 2020
* @description Service class for handling various Billing Reconciliation actions
*
* CHANGE LOG
**/
public with sharing class BillingReconService {

    public Billing_Recon_Statement__c billingReconStatement;

    // Constructor to instantiate the record
    public BillingReconService(Id billingReconStatementId) {
        this.billingReconStatement = new Billing_Recon_Statement__c(Id = billingReconStatementId);
    }

    // Basic methods for updating statuses during batch process
    public void startPreparingStatus() {
        setStatementStatus('Preparing'); 
    }

    // Basic methods for updating statuses during batch process
    public void startProcessingCsvStatus() {
        setStatementStatus('Processing CSV');
    }

    public void startVarianceCalculationStatus() {
        setStatementStatus('Calculating Variances');
    }

    // Basic methods for updating statuses during batch process
    public void startReconcilingStatus() {
        setStatementStatus('Reconciling');
    }

    public void doneStatus() {
        setStatementStatus('Processed');
    }

    
    /**
    * @author Ben Edwards (beedwards@deloitte.co.nz)
    * @date 12th June 2020
    * @description Update the parent status of the Statement record
    **/
    public void setStatementStatus (String status) {

        setStatementStatus(status, null);
    }

    /**
    * @author Ben Edwards (beedwards@deloitte.co.nz)
    * @date 12th June 2020
    * @description Update the parent status of the Statement record
    **/
    public void setStatementStatus (String status, String error) {

        // Update the recon status
        billingReconStatement.Status__c = status;
        billingReconStatement.Error__c = error;
        update billingReconStatement;
    }

}