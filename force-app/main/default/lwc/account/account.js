import { LightningElement, track, wire } from 'lwc';
import { getQueryParams } from "c/communitiesNavigation";
import getAccount_uuid from '@salesforce/apex/AccountController.getAccount_uuid';

import { getRecord } from 'lightning/uiRecordApi';

import USER_ID from '@salesforce/user/Id';

import NAME_FIELD from '@salesforce/schema/User.Name';
import EMAIL_FIELD from '@salesforce/schema/User.Email';

/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;

export default class User extends LightningElement {
    @track schoolId;
    @track object;

    @track email = "loading";
    @track name;
    @track initial;

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [NAME_FIELD, EMAIL_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
           this.error = error;
        } else if (data) {
            this.email = data.fields.Email.value;
            this.name = data.fields.Name.value;

            this.initial = `${this.name}`.charAt(0).toUpperCase();
        }
    }

    connectedCallback() {
        this.queryParams = getQueryParams(window.location.search);
    
        if (this.queryParams.schoolId) {
          this.schoolId = this.queryParams.schoolId;
          this.reload();
        }
    }

    reload() {
        this.handleGetAccountUUID();
    }

    handleGetAccountUUID(){
        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            getAccount_uuid({ uuid: this.schoolId })
                .then(result => {
                    this.object = result;
                    this.error = undefined;
                })
                .catch(error => {
                    this.error = error;
                    this.object = undefined;
                });
        }, DELAY);
    }

    get display1(){
        return JSON.stringify(this.object);
    }
}