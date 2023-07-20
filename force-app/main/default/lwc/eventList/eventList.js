/* reference 
*  https://github.com/trailheadapps/lwc-recipes/blob/master/force-app/main/default/lwc/ldsDeleteRecord/ldsDeleteRecord.js
*  https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.apex
*/
import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from 'lightning/uiRecordApi';
import getEventList from '@salesforce/apex/ActivityController.getEventList';


import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import EVENT_OBJECT from '@salesforce/schema/Event';
import EVENT_SUBJECT_FIELD from '@salesforce/schema/Event.Subject';
//import EVENT_ACTIVITYDATE_FIELD from '@salesforce/schema/Event.ActivityDate';
import EVENT_ACTIVITYDATETIME_FIELD from '@salesforce/schema/Event.ActivityDateTime';
import EVENT_OWNERID_FIELD from '@salesforce/schema/Event.OwnerId';
import EVENT_WHATID_FIELD from '@salesforce/schema/Event.WhatId';
import EVENT_DESCRIPTION_FIELD from '@salesforce/schema/Event.Description';
import EVENT_DRIVER_FIELD from '@salesforce/schema/Event.Driver__c';
import EVENT_NOTES_FIELD from '@salesforce/schema/Event.Notes__c';


import USER_ID from '@salesforce/user/Id'

const FIELDS = [
    'Account.Name',
];

//export default class TaskList extends LightningElement {
export default class Eventist extends NavigationMixin(LightningElement){
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
}


@track sfevents; //for html items iteration
@track error;
@track hasRecords; //<template>.. if true/false

@track inputMode = false;
@track displayMode = true;

/** Wired Apex result so it can be refreshed programmatically in return refreshApex(this.wiredEventsResult);*/
wiredEventsResult; 

@wire(getEventList, { whatId: '$recordId', isOpenOnly: true })
//@wire(getEventList, { whatId: this.recordId, isOpenOnly: true })
wiredAccounts(result) {
    this.wiredEventsResult = result;
    if (result.data) {
        //console.log('in wiredAccounts(result), result = ', result);
        this.sfevents = result.data;
        console.log('in wiredAccounts(result), this.sfevents = ', this.sfevents);
        console.log('in wiredAccounts(result), jsstring this.sfevents = ', JSON.stringify(this.sfevents));
        this.error = undefined;
        this.hasRecords = (this.sfevents.length > 0);
    } else if (result.error) {
        this.error = result.error;
        this.sfevents = undefined;
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
				objectApiName: 'Activity',
				actionName: 'view',
			},
		});
}

//----------------- Create Event Record --------------------------------------
    // @track eventId;
    // subject = '';
    // activityDate = new Date();
    // activityDateTime = new Date();
    // description = '';
    // driver = '';
    // notes = '';

    // handleSubjectChange(event) {
    //     this.eventId = undefined;
    //     this.subject = event.target.value;
    // }
    // handleDueDateChange(event) {
    //     this.eventId = undefined;
    //     //this.activityDate = event.target.value;
    //     this.activityDateTime = event.target.value;
    // }
    
    // handleDescriptionChange(event) {
    //     this.eventId = undefined;
    //     this.description = event.target.value;
    // }

    // createEvent() {
    //     const fields = {};
    //     fields[EVENT_SUBJECT_FIELD.fieldApiName] = this.subject;
    //     //fields[EVENT_ACTIVITYDATE_FIELD.fieldApiName] = this.activityDate;
    //     fields[EVENT_ACTIVITYDATETIME_FIELD.fieldApiName] = this.activityDateTime;
    //     fields[EVENT_OWNERID_FIELD.fieldApiName] = USER_ID;
    //     fields[EVENT_WHATID_FIELD.fieldApiName] = this.recordId;
    //     fields[EVENT_DESCRIPTION_FIELD.fieldApiName] = this.description;
    //     fields[EVENT_DRIVER_FIELD.fieldApiName] = this.driver;
    //     fields[EVENT_NOTES_FIELD.fieldApiName] = this.notes;
        
    //     //Error creating : Object Event is not supported in UI API
    //     //const recordInput = { apiName: EVENT_OBJECT.objectApiName, fields };

    //     //implement with wired Apex Controller.
    //     createEventRecord({ fieldsMap: fields })
    //         .then(sfevent => {
    //             this.eventId = sfevent.id;
    //             this.dispatchEvent(
    //                 new ShowToastEvent({
    //                     title: 'Success',
    //                     message: 'Event created',
    //                     variant: 'success',
    //                 }),
    //             );
    //             //this.handleSetActiveSectionB(); //make section B active
    //             return refreshApex(this.wiredEventsResult); //refresh lwc list
    //         })
    //         .catch(error => {
    //             this.dispatchEvent(
    //                 new ShowToastEvent({
    //                     title: 'Error creating record',
    //                     message: error.body.message,
    //                     variant: 'error',
    //                 }),
    //             );
    //         });
    //     }

      
//----------------- Create Task Record --------------------------------------
}