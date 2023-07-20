import { LightningElement, track, wire } from 'lwc';
import {
    getRecord
} from 'lightning/uiRecordApi';
import { resolveEnvironment } from 'c/utilitiesFunction';
import USER_ID from '@salesforce/user/Id';

import NAME_FIELD from '@salesforce/schema/User.Name';
import EMAIL_FIELD from '@salesforce/schema/User.Email';

export default class User extends LightningElement {
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

    handleOnselect(event) {
        if(event.detail.value === "logout") {
            let environment = resolveEnvironment();
            if(environment === 'production' || environment === 'demo') {
                window.location.replace(`https://${window.location.host}/secur/logout.jsp`);
            } else {
                window.location.replace(`https://${window.location.host}/reporting/secur/logout.jsp`);
            }
        }
    }
}