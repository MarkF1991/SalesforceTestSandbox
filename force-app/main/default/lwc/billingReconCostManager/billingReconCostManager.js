import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCosts from '@salesforce/apex/BillingReconCostManagerController.getCosts';
import getChargeCategories from '@salesforce/apex/BillingReconCostManagerController.getChargeCategories';
import getChargeCategoryOptions from '@salesforce/apex/BillingReconCostManagerController.getChargeCategoryOptions';

// The columns to search on
const searchFields = [
    'School_Name__c',
    'MOE_Id__c',
    'MoE_Site_Id__c',
    'Description__c',
    'Product_Service__c',
];

export default class BillingReconCostManager extends LightningElement {

    @api recordId;

    @track recordsOriginal = [];
    @track records = [];
    @track columns;
    @track errors;
    @track hasRows = false;
    @track isLoading = true; 
    @track queryTerm;

    // Hold any edited values to save
    @track draftValues = [];

    @track chargeCategoryOptions = [];
    @track selectedChargeCategoryFilter = 'all';

    // Wired Apex result so it can be refreshed by user on page
    wiredRecords;
    wiredCategories;
    
    @wire(getCosts, { statementId: '$recordId' })
    wireCosts(result) {

        this.wiredRecords = result;
        this.isLoading = true;

        if (result.data) {
            this.recordsOriginal = result.data;
            this.records = result.data;
            this.hasRows = this.records.length > 0;
            this.isLoading = false; 
            this.errors = undefined;
        }  
        else if (result.error) {
            this.recordsOriginal = undefined;
            this.records = undefined;
            this.hasRows = false; 
            this.isLoading = false;
            this.errors = result.error;      
        }
    }

    @wire(getChargeCategories, { statementId: '$recordId' })
    wireChargeCategories(result) {

        this.wiredCategories = result;
        
        // Pre-load the "All" option
        this.chargeCategoryOptions = [
            { label: 'All', value: 'all' },
        ];

        // Create an option for every other category
        if (result.data) {
            for (let i = 0; i < result.data.length; i++) {
                this.chargeCategoryOptions.push({ label: result.data[i], value: result.data[i] });
            }
            this.errors = undefined;
        }
        else if (result.error) {
            this.errors = result.error;
        }
    }

    @wire(getChargeCategoryOptions)
    wireChargeCategoryOptions(result) {
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
                { label: 'MoE Id', fieldName: 'MOE_Id__c' },
                { label: 'Site Id', fieldName: 'MoE_Site_Id__c' },
                { label: 'Funded', fieldName: 'Funded__c' },
                { label: 'School Type', fieldName: 'School_Type__c' },
                { label: 'Statement Date', fieldName: 'Statement_Date__c', type: 'date' },
                { label: 'Line Number', fieldName: 'Line_Number__c' },
                { label: 'Charge Type', fieldName: 'Charge_Type__c' },
                { label: 'From Date', fieldName: 'From_Date__c', type: 'date' },
                { label: 'To Date', fieldName: 'To_Date__c', type: 'date' },
                { label: 'Description', fieldName: 'Description__c' },
                { label: 'Product Service', fieldName: 'Product_Service__c' },
                { label: 'GST', fieldName: 'GST_Indicator__c' },
                { 
                    label: 'Charge Category', 
                    fieldName: 'Charge_Category__c', 
                    type: 'picklist', 
                    editable: true, 
                    typeAttributes: {
                        context: { fieldName: 'Id' },
                        value: { fieldName: 'Charge_Category__c' },
                        fieldName: 'Charge_Category__c',
                        options: result.data
                    }      
                },
                { label: 'CM Total', fieldName: 'Charge__c', type: 'currency' },
                { label: 'SF Total', fieldName: 'Calculated_Charge__c', type: 'currency' },
                { 
                    label: 'Variance', 
                    fieldName: 'Variance__c', 
                    type: 'currencyColoured',
                    cellAttributes: { 
                        alignment: 'right'
                    },
                    typeAttributes: {
                        value: { fieldName: 'Variance__c' }
                    }
                },
                { label: 'Comments', fieldName: 'Comments__c', editable: true },
            ];
        }
    }

    get renderTable() {
        return this.hasRows && !this.errors;
    }

    get renderNoRecordsMessage() {
        return !this.hasRows && !this.errors;
    }

    handleChargeCategoryChange(event) {
        // Update the selected value
        this.selectedChargeCategoryFilter = event.detail.value;
        // Load the original records
        this.records = this.recordsOriginal.slice();
        // If doesn't equal to all, then start filtering
        if (this.selectedChargeCategoryFilter != 'all') {
            // Filter records on the charge category that matches the filter
            this.records = this.records.filter(record => record.Charge_Category__c == this.selectedChargeCategoryFilter);
        }
    }

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

        // Build the records to save
        const recordInputs =  event.detail.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });

        // Update the records
        const promises = recordInputs.map(recordInput => updateRecord(recordInput));
        Promise.all(promises).then(records => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Costs updated',
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
        return refreshApex(this.wiredRecords)
            .then(()=> {
                this.isLoading = false;
                return this.refreshCategories();
            })
            .catch((error) => {
                this.isLoading = false;
                this.errors = error;
            });
    }

    refreshCategories() {
        return refreshApex(this.wiredCategories)
            .then(()=> {})
            .catch((error) => {
                this.errors = error;
            });
    }
}