// wireGetRecordDynamicaccount.js
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getAccountCaseList from '@salesforce/apex/CaseController.getAccountCaseList';


import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';

const FIELDS = [
    'Account.Name',
];

//export default class CaseList extends LightningElement {
export default class CaseList extends NavigationMixin(LightningElement){
   // Flexipage provides recordId and objectApiName
   @api title;
   @api emptyListMessage;
   @api recordId = '';// = '001N000001Q8e7dIAB';

   @wire(getRecord, {
        recordId: '$recordId',
        fields: FIELDS
    })
    account;

    



@wire(CurrentPageReference) pageRef; //afterRender threw an error in 'c:accountLWC' [pubsub listeners need a "@wire(CurrentPageReference) pageRef" property]

connectedCallback() {
    // subscribe to AccountSelected event
    registerListener('accountSelected', this.handleAccountSelected, this);
}

disconnectedCallback() {
    // unsubscribe from AccountSelected event
    unregisterAllListeners(this);
}

handleAccountSelected(accountId) {
    this.recordId = accountId;
}
// handleAccountSelected(account) {
//     this.recordId = account.id;
// }


// @wire(getAccountCaseList, { accountId: '$recordId', isOpenOnly: true })
// sfcases;
@track sfcases;
@track error;
@track hasRecords;
@wire(getAccountCaseList, { accountId: '$recordId', isOpenOnly: true })
wiredCases({ error, data }) {
    if (data) {
        this.sfcases = data;
        this.hasRecords = (this.sfcases.length > 0);
        this.error = undefined;
    } else if (error) {
        this.error = error;
        this.sfcases = undefined;
        this.hasRecords = false;
    }
}


handleCaseSelect(event){
    //get case id from case selected event
    const caseId = event.detail.value;
    // Navigate to case record page
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: caseId,
				objectApiName: 'Case',
				actionName: 'view',
			},
		});
}

}