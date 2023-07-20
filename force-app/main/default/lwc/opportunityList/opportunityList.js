/* reference 
*  https://github.com/trailheadapps/lwc-recipes/blob/master/force-app/main/default/lwc/ldsDeleteRecord/ldsDeleteRecord.js
*  https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.apex
*/
import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from 'lightning/uiRecordApi';
import getAccountOpportunityList from '@salesforce/apex/OpportunityController.getAccountOpportunityList';


import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';


const FIELDS = [
    'Account.Name',
];

export default class OpportunityList extends NavigationMixin(LightningElement){
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
    //console.log('in handleAccountSelected(accountId), accountId = ', accountId);
    this.recordId = accountId;
    console.log('in handleAccountSelected(accountId) this.recordId = accountId is: ', this.recordId);
}


@track opportunities; //for html items iteration
@track error;
@track hasRecords; //<template>.. if true/false

@track inputMode = false;
@track displayMode = true;

/** Wired Apex result so it can be refreshed programmatically in return refreshApex(this.wiredOpportunitiesResult);*/
wiredOpportunitiesResult; 

@wire(getAccountOpportunityList, { accountId: '$recordId' })
wiredOpportunities(result) {
    this.wiredOpportunitiesResult = result;
    console.log('in wiredOpportunities(result), this.wiredOpportunitiesResult = ', this.wiredOpportunitiesResult);
    if (result.data) {
        //console.log('in wiredOpportunities(result), result = ', result);
        this.opportunities = result.data;
        console.log('in wiredOpportunities(result), this.opportunities = ', this.opportunities);
        console.log('in wiredOpportunities(result), jsstring this.opportunities = ', JSON.stringify(this.opportunities));
        this.error = undefined;
        this.hasRecords = (this.opportunities.length > 0);
    } else if (result.error) {
        this.error = result.error;
        this.opportunities = undefined;
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
				objectApiName: 'Opportunity',
				actionName: 'view',
			},
		});
}

}