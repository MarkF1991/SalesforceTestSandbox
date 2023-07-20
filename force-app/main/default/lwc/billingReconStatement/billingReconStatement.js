import { LightningElement, api, track, wire } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getStatementAccounts from '@salesforce/apex/BillingReconStatementController.getStatementAccounts';
import getStatusOptions from '@salesforce/apex/BillingReconStatementController.getStatusOptions';

// The columns to search on
const searchFields = [
    'School_Name__c',
    'MoE_Id__c',
    'MoE_Site_Id__c',
];

const showHideOptions = [
    { label: 'Show', value: 'show' },
    { label: 'Hide', value: 'hide' },
]

export default class BillingReconStatement extends LightningElement {
    
    @api recordId;

    //control table
    @track records = [];
    @track recordsOriginal = [];

    // Hold any edited values to save
    @track draftValues = [];

    @track columns;
    @track errors;
    @track hasRows = true;
    @track isLoading = true;

    @track showHideOptions = showHideOptions;
    @track showHideAutoLines = 'hide';
    @track showHideClosedLines = 'show';

    // Wired Apex result so it can be refreshed by user on page
    wiredResults;

    @wire(getStatementAccounts, { statementId: '$recordId' })
    wireStatementAccounts(result) {

        this.wiredResults = result;
        this.isLoading = true;

        if (result.data) {
            this.recordsOriginal = result.data;
            this.records = result.data;
            this.hasRows = this.records.length > 0;
            this.errors = undefined;
            // Filter the records on load
            this.handleAutoReconChange();
            this.isLoading = false; 
        }  
        else if (result.error) {
            this.recordsOriginal = undefined;
            this.records = undefined;
            this.hasRows = false; 
            this.isLoading = false;
            this.errors = result.error;      
        }
    }

    @wire(getStatusOptions)
    wireStatusOptions(result) {
        if (result.data) {
            // Load the columns
            this.columns = [
                {
                    label: 'School Name', 
                    fieldName: 'School_Name__c',
                    type: 'navigation',
                    typeAttributes: {
                        label: { fieldName: 'School_Name__c' },
                        recordId: { fieldName: 'Id' },
                    }
                },
                {label: 'MoE Id', fieldName: 'MoE_Id__c' , type: 'text' },
                {label: 'Site Id', fieldName: 'MoE_Site_Id__c'  , type: 'text'},
                {label: 'Funded', fieldName: 'Funded__c' },
                {label: 'School Type', fieldName: 'School_Type__c' },
                {label: 'SF Total', fieldName: 'SF_Total__c', type:'currency' },
                {label: 'CM Total', fieldName: 'CM_Total__c', type:'currency' },
                {
                    label: 'Total Var', 
                    fieldName: 'Total_Variance__c', 
                    type: 'currencyColoured',
                    cellAttributes: { 
                        alignment: 'right'
                    },
                    typeAttributes: {
                        value: { fieldName: 'Total_Variance__c' }
                    }
                },
                {label: 'LFC SF Total', fieldName: 'LFC_Calculated_Charge_Total__c', type:'currency' },
                {label: 'LFC CM Total', fieldName: 'LFC_Charge_Total__c', type:'currency' },
                {
                    label: 'LFC Var.', 
                    fieldName: 'LFC_Charge_Variance__c', 
                    type: 'currencyColoured',
                    cellAttributes: { 
                        alignment: 'right'
                    },
                    typeAttributes: {
                        value: { fieldName: 'LFC_Charge_Variance__c' }
                    }
                },
                {label: 'LFC Install SF Total', fieldName: 'LFC_Install_Calculated_Charge_Total__c', type:'currency' },
                {label: 'LFC Install CM Total', fieldName: 'LFC_Install_Charge_Total__c', type:'currency' },
                {
                    label: 'LFC Install Var.', 
                    fieldName: 'LFC_Install_Charge_Variance__c', 
                    type: 'currencyColoured',
                    cellAttributes: { 
                        alignment: 'right'
                    },
                    typeAttributes: {
                        value: { fieldName: 'LFC_Install_Charge_Variance__c' }
                    }
                },
                {label: 'CLNE SF Total', fieldName: 'CLNE_Calculated_Charge_Total__c', type:'currency' },
                {label: 'CLNE CM Total', fieldName: 'CLNE_Charge_Total__c', type:'currency' },
                {
                    label: 'CLNE Var.', 
                    fieldName: 'CLNE_Charge_Variance__c', 
                    type: 'currencyColoured',
                    cellAttributes: { 
                        alignment: 'right'
                    },
                    typeAttributes: {
                        value: { fieldName: 'CLNE_Charge_Variance__c' }
                    }
                },
                {label: 'Safe & Secure SF Total', fieldName: 'Safe_Secure_Calculated_Charge_Total__c', type:'currency' },
                {label: 'Safe & Secure CM Total', fieldName: 'Safe_Secure_Charge_Total__c', type:'currency' },
                {
                    label: 'Safe & Secure Var.', 
                    fieldName: 'Safe_Secure_Charge_Variance__c', 
                    type: 'currencyColoured', 
                    cellAttributes: { 
                        alignment: 'right'
                    },
                    typeAttributes: {
                        value: { fieldName: 'Safe_Secure_Charge_Variance__c' }
                    }
                },
                {label: 'MAC CM Total', fieldName: 'MAC_Charge_Total__c', type:'currency' },
                {label: 'Unknown CM Total', fieldName: 'Other_Charges_Total__c', type:'currency' },
                {
                    label: 'Comments', 
                    fieldName: 'Comments__c', 
                    editable: true 
                },
                { 
                    label: 'Status', 
                    fieldName: 'Status__c', 
                    type: 'picklist', 
                    editable: true, 
                    typeAttributes: {
                        context: { fieldName: 'Id' },
                        value: { fieldName: 'Status__c' },
                        fieldName: 'Status__c',    
                        options: result.data
                    }      
                },
            ];
        }
    }

    get renderTable() {
        return this.hasRows && !this.errors;
    }

    get renderNoRecordsMessage() {
        return !this.hasRows && !this.errors;
    }
    
    // To show/hiden Auto Column
    handleAutoReconChange(event) {

        if (event) {
            this.showHideAutoLines = event.detail.value;
        }

        // Reload the records to show
        this.records = this.recordsOriginal.slice();
        
        // If hide, filter out the reconciled lines
        if (this.showHideAutoLines === 'hide') {
            // Filter records on the charge category that matches the filter
            this.records = this.records.filter(record => record.Status__c !== 'Auto-reconciled');     
        }    
    }

    // To show/hiden invest close column
    handleInvesClosedChange(event) {

        // Load the selected value
        if (event){
            this.showHideClosedLines = event.detail.value;
        }

        // Reload the records to show
        this.records = this.recordsOriginal.slice();
        
        if (showHideClosedLines === 'hide') {  
            // Filter records on the charge category that matches the filter
            this.records = this.records.filter(record => (record.Status__c !== 'Requires investigating' && record.Status__c !== 'To be investigated'));  
        }
    }    

    // Refresh Button
    refreshRecords() {

        this.isLoading = true;
        
        return refreshApex(this.wiredResults)
            .then(()=> {
                this.isLoading = false;
            })
            .catch((error) => {
                this.isLoading = false;
                this.errors = error;
            });
    }


    // Handle the search 
    handleSearchChange(event) {
        // Set the search term
        this.queryTerm = event.detail.value;
        // Run the search
        if (this.queryTerm && this.queryTerm.length >= 2) {
            // If we have this search already, clear it (debounce)
            if (this.delayTimeout) window.clearTimeout(this.delayTimeout);
            // Do the search
            this.delayTimeout = setTimeout(() => {
                // Reload to the original records
                this.records = this.recordsOriginal.slice();
                // Filter the records
                this.records = this.records.filter((record) => {
                    return Object.keys(record).filter(key => searchFields.includes(key)).reduce((x, curr) => {
                        return x || record[curr].toLowerCase().includes(this.queryTerm.toLowerCase());
                    }, false);
                });
            }, 500);
        }
        else {
            // Reload to the original records
            this.records = this.recordsOriginal.slice();
        }
    }

    handleSave(event) {

        const recordInputs =  event.detail.slice().map(record => {
            const fields = Object.assign({}, record);
            return { fields };
        });
    
        const promises = recordInputs.map(recordInput => updateRecord(recordInput));
        Promise.all(promises).then(record => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Billing reconcilation updated',
                    variant: 'success'
                })
            );
            // Clear all draft values
            this.draftValues = [];
    
            // Display fresh data in the datatable
            return this.refreshRecords();
        }).catch(error => {
            this.errors = error;
        });
    }

    refreshRecords() {
        this.isLoading = true;
        return refreshApex(this.wiredResults)
            .then(()=> {
                this.isLoading = false;
            })
            .catch((error) => {
                this.isLoading = false;
                this.errors = error;
            });
    }

}