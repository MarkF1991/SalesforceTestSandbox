/* reference 
*  https://github.com/trailheadapps/lwc-recipes/blob/master/force-app/main/default/lwc/ldsDeleteRecord/ldsDeleteRecord.js
*  https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.apex
*/
import { LightningElement, api, wire, track } from 'lwc';

import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import UUID_FIELD from '@salesforce/schema/Account.uuid__c';
import MOEID_FIELD from '@salesforce/schema/Account.MoE_School_ID__c';

const FIELDS = [
    NAME_FIELD, UUID_FIELD, MOEID_FIELD
];

//export default class TaskList extends LightningElement {
export default class Eventist extends NavigationMixin(LightningElement){
   // Flexipage provides recordId and objectApiName
   @api title = 'Links'; //default title. We can modify title in Lightning Appp page, but not in Lighting Record Page
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
}

get schoolreportingURL(){
    return 'https://reporting.n4l.co.nz/s/?schoolId=' + getFieldValue(this.account.data, UUID_FIELD);
}

get educountURL(){
    return 'https://www.educationcounts.govt.nz/find-school/school/profile?school=' + getFieldValue(this.account.data, MOEID_FIELD);
}


}