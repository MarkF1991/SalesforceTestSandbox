/* reference 
*  https://github.com/trailheadapps/lwc-recipes/blob/master/force-app/main/default/lwc/ldsDeleteRecord/ldsDeleteRecord.js
*  https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.apex
*/
import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from 'lightning/uiRecordApi';
import getTaskList from '@salesforce/apex/ActivityController.getTaskList';
import createTaskRecord from '@salesforce/apex/ActivityController.createTaskRecord';

import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import TASK_OBJECT from '@salesforce/schema/Task';
import TASK_SUBJECT_FIELD from '@salesforce/schema/Task.Subject';
import TASK_STATUS_FIELD from '@salesforce/schema/Task.Status';
import TASK_ACTIVITYDATE_FIELD from '@salesforce/schema/Task.ActivityDate';
import TASK_OWNERID_FIELD from '@salesforce/schema/Task.OwnerId';
import TASK_WHATID_FIELD from '@salesforce/schema/Task.WhatId';
import TASK_DESCRIPTION_FIELD from '@salesforce/schema/Task.Description';

import USER_ID from '@salesforce/user/Id'

const FIELDS = [
    'Account.Name',
];

//export default class TaskList extends LightningElement {
export default class TaskList extends NavigationMixin(LightningElement){
   // Flexipage provides recordId and objectApiName
   @api title;
   @api emptyListMessage;
   @api recordId = '';// = '001N000001Q8e7dIAB';
   
   @track createMode = false;
   @track displayMode = true;

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


@track tasks; //for html items iteration
@track error;
@track hasRecords; //<template>.. if true/false

/** Wired Apex result so it can be refreshed programmatically in return refreshApex(this.wiredTasksResult);*/
wiredTasksResult; 

@wire(getTaskList, { whatId: '$recordId', isOpenOnly: true })
wiredAccounts(result) {
    this.wiredTasksResult = result;
    if (result.data) {
        this.tasks = result.data;
        this.error = undefined;
        this.hasRecords = (this.tasks.length > 0);
    } else if (result.error) {
        this.error = result.error;
        this.tasks = undefined;
        this.hasRecords = false;
    }
}

handleTaskSelect(event){
    //get Task id from Task selected event
    const taskRecordId = event.detail.value;
    // Navigate to task record page
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: taskRecordId,
				objectApiName: 'Task',
				actionName: 'view',
			},
		});
}

handleNew(){
    this.createMode = true;
}

//----------------- Create Task Record --------------------------------------
    @track taskId;
    subject = '';
    activityDate = new Date();
    description = '';

    handleSubjectChange(event) {
        this.taskId = undefined;
        this.subject = event.target.value;
    }
    handleDueDateChange(event) {
        this.taskId = undefined;
        this.activityDate = event.target.value;
    }
    
    handleDescriptionChange(event) {
        this.taskId = undefined;
        this.description = event.target.value;
    }
    handleCancel(){
        this.createMode = false;
    }
    handleSave(){
        
    
        const fields = {};
        fields[TASK_SUBJECT_FIELD.fieldApiName] = this.subject;
        fields[TASK_STATUS_FIELD.fieldApiName] = 'Not Started';
        fields[TASK_ACTIVITYDATE_FIELD.fieldApiName] = this.activityDate;
        fields[TASK_OWNERID_FIELD.fieldApiName] = USER_ID;
        fields[TASK_WHATID_FIELD.fieldApiName] = this.recordId;
        fields[TASK_DESCRIPTION_FIELD.fieldApiName] = this.description;

        //Error creating : Object Task is not supported in UI API
        //const recordInput = { apiName: TASK_OBJECT.objectApiName, fields };

        //implement with wired Apex Controller.
        createTaskRecord({ fieldsMap: fields })
            .then(task => {
                this.taskId = task.id;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Task created',
                        variant: 'success',
                    }),
                );
                //this.handleSetActiveSectionB(); //make section B active
                return refreshApex(this.wiredTasksResult); //refresh lwc list
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            });
            
            this.createMode = false;
        }

        // handleSetActiveSectionB() {
        //     const accordion = this.template.querySelector('.task-accordion');
    
        //     accordion.activeSectionName = 'B';
        // }
//----------------- Create Task Record --------------------------------------
}