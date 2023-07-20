import { LightningElement, api, track, wire } from 'lwc';
import getSummaryRows from '@salesforce/apex/BillingReconSchoolSummaryController.getSummaryRows';

export default class BillingReconSchoolSummary extends LightningElement {

    @api recordId;

    @track errors;
    @track isLoading = true;

    @wire(getSummaryRows, { statementSchoolId: '$recordId' })
    wireSummaryRows({ error, data }) {
        if (data) {
            this.summaryRows = data;
            this.errors = undefined;
            this.isLoading = false;
        }
        else if (error) {
            this.summaryRows = [];
            this.errors = error;
            this.isLoading = false;
        }
    }   
}