import { LightningElement, api, track, wire } from 'lwc';

import processCsv from '@salesforce/apex/BillingReconUploadController.processCsv';
import getStatus from '@salesforce/apex/BillingReconUploadController.getStatus';
import getCanRetry from '@salesforce/apex/BillingReconUploadController.getCanRetry';

export default class BillingReconUpload extends LightningElement { 

    // ID of the Billing Recon Statement
    @api recordId;

    // Determine if possible to retry
    @track canRetry;

    @track error;

    @track isRecordLoading = true;
    @track isStatusLoading = true;
    @track isStarted = false;
    @track isRunning = false;
    @track isFinished = false;

    // Status tracking
    @track currentStatus = 'Not Started';
    @track processedCount;
    @track totalBatchSize;
    @track progress = 0;
    
    // Specifiy accept formats
    // For now, it's just CSV
    get acceptedFormats() {
        return ['.csv']; 
    }

    connectedCallback() {
        // Start job processing ot determine if already in process
        // or not
        this.isStatusLoading = true;
        this.startJobStatusInterview();
    }

    @wire(getCanRetry, { billingReconStatementId: '$recordId' })
    wireCanRetry(result) {

        this.isRecordLoading = true;
        
        if (result.error) {
            this.isRecordLoading = false;
            this.canRetry = false;
            this.error = error;
        }
        else {
            this.isRecordLoading = false;
            this.canRetry = result.data;
            this.error = undefined;
        }
    }

    handleUploadFinished(event) {

        // Calling apex class
        processCsv({
            billingReconStatementId: this.recordId
        })
        .then(result => {
            this.error = undefined;
            this.currentStatus = 'Preparing';
            // Set as runnning
            this.isStarted = true;
            this.isRunning = true;
            this.isFinished = false;
            // Start polling for the current status
            this.startJobStatusInterview();
        })
        .catch(error => {
            this.isRunning = false;
            this.error = error;
        });
    }

    startJobStatusInterview() {

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._statusInterval = setInterval(() => {
            
            // Call Apex method to get job status
            getStatus({billingReconStatementId: this.recordId})
            .then(result => {

                // Mark as no longer loading
                this.isStatusLoading = false;

                // Set status and values
                this.currentStatus = result.statementStatus;

                console.log(this.currentStatus);

                // If not started, clear the interval 
                // Or if Processed or Error and hasn't yet been started
                // WE can assume it's page loaded so clear everything
                if (
                    !this.isStarted && (
                        this.currentStatus == 'Not Started' || 
                        this.currentStatus == 'Processed' ||
                        this.currentStatus == 'Error'
                    )
                ) {  

                    // Set all booleans to default
                    this.isStarted = false;
                    this.isRunning = false;
                    this.isFinished = false;
                    clearInterval(this._statusInterval);
                }
                else {

                    // Set as runnning
                    this.isStarted = true;
                    this.isRunning = true;
                    this.isFinished = false;

                    // Set processed values
                    this.processedCount = result.processedCount;
                    this.totalBatchSize = result.totalBatchSize;

                    // Set progress based on batches process
                    this.progress = (result.processedCount / result.totalBatchSize) * 100;

                    // Stop interval when done
                    if (this.currentStatus == 'Processed' || this.currentStatus == 'Error') {
                        this.isRunning = false;
                        this.isFinished = true;
                        clearInterval(this._statusInterval);
                    }

                    if (this.currentStatus == 'Processed') {
                        // Reload the page
                        setTimeout(function(){ 
                            window.location.reload();
                        }, 1000);
                    }
                }
            })
            .catch(error => {

                this.error = error;
                this.isRunning = false;
                this.isStatusLoading = false;
                this.currentStatus = 'Error';

                // Clear the intertview
                clearInterval(this._statusInterval);
            });
            
        }, 3000);
    }

    // Will return true if either record or status is loading
    get isLoading() {
        return this.isRecordLoading || this.isStatusLoading;
    }

}