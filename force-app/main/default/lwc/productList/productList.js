import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getAccountProductList from '@salesforce/apex/InstalledN4LProductFeatureController.getAccountProductList';

import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { registerListener, unregisterAllListeners } from 'c/pubsub';

const FIELDS = [
    'Account.Name',
];

export default class ProductList extends NavigationMixin(LightningElement){ 

    @wire(CurrentPageReference) pageRef; //afterRender threw an error in 'c:accountLWC' [pubsub listeners need a "@wire(CurrentPageReference) pageRef" property]
    @api title;
    @api emptyListMessage;
    @api recordId;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: FIELDS
    })
    account;

    connectedCallback() {
        // subscribe to AccountSelected event
        registerListener('accountSelected', this.handleAccountSelected, this);
    }
    disconnectedCallback() {
        // unsubscribe from AccountSelected event
        unregisterAllListeners(this);
    }

    handleAccountSelected(accountId) {
        //console.log('in handleAccountSelected(accountId), accountId = ', accountId);
        this.recordId = accountId;
        console.log('in handleAccountSelected(accountId) this.recordId = accountId is: ', this.recordId);
    }

    @track products;
    hasRecords;
    error;
    inputMode = false;
    displayMode = true;

    /** Wired Apex result so it can be refreshed programmatically in return refreshApex(this.wiredOpportunitiesResult);*/
    wiredProductsResult; 

    @wire(getAccountProductList, { accountId: '$recordId' })
    wiredProducts(result) {
        this.wiredProductsResult = result;
        if (result.data) {
            this.products = result.data;
            this.error = undefined;
            if(this.products.length > 0) this.hasRecords = true;
        } else if (result.error) {
            this.error = result.error;
            this.products = undefined;
            this.hasRecords = false;
        }
    }

    handleEventSelect(event){
        //get Event id from Event selected event
        const eventRecordId = event.detail.value;
        // Navigate to Event record page
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: eventRecordId,
                    objectApiName: 'Installed_N4L_Product_Feature__c',
                    actionName: 'view',
                },
            });
    }
}