import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

//----------------------- User --------------------------------
import { getRecord } from 'lightning/uiRecordApi';

import USER_ID from '@salesforce/user/Id';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';
import USER_EMAIL_FIELD from '@salesforce/schema/User.Email';
import USER_CONTACTID_FIELD from '@salesforce/schema/User.ContactId';
import USER_ISPORTALENABLED_FIELD from '@salesforce/schema/User.IsPortalEnabled';
const USER_FIELDS = [USER_NAME_FIELD, USER_EMAIL_FIELD, USER_CONTACTID_FIELD, USER_ISPORTALENABLED_FIELD];


//----------------------- Contract --------------------------------

export default class MOULightning extends NavigationMixin(LightningElement) {
    @api recordId;    
    @api title = '';
    @api description = '';
    @track error;
     
    //get user record
    userId = USER_ID;
    @wire(getRecord, { recordId: '$userId', fields: USER_FIELDS })
    user;

}