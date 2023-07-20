// wireGetRecordDynamicaccount.js
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

// import getContactList_RoleBased from '@salesforce/apex/ContactController.getContactList_RoleBased';
import getContactList_RoleBased from '@salesforce/apex/ContactController.getContactList_RoleBased';
import getContactList_WithUser from '@salesforce/apex/ContactController.getContactList_WithUser';
import getAccount from '@salesforce/apex/AccountController.getAccount';

import createCustomerUser from '@salesforce/apex/SupportHubInviteSignupController.InviteToCreateCustomerUser';

import { refreshApex } from '@salesforce/apex';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';


import Id from '@salesforce/user/Id';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';
import USER_EMAIL_FIELD from '@salesforce/schema/User.Email';
import EmailPreferencesStayInTouchReminder from '@salesforce/schema/User.EmailPreferencesStayInTouchReminder';
const USER_FIELDS = [USER_NAME_FIELD, USER_EMAIL_FIELD];
/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;

export default class ContactList extends NavigationMixin(LightningElement){
    @api accountId = '';
    @api listTitle;
    @api emptyListMessage;

    @wire(CurrentPageReference) pageRef; //afterRender threw an error in 'c:accountLWC' [pubsub listeners need a "@wire(CurrentPageReference) pageRef" property]

    // Flexipage provides recordId and objectApiName
    @track contacts;
    @track accounts;
    @track error;
    @track hasRecords;
    @track currentContactElement;

    @track modal = {header: '',
                    id: '',
                    elements: [], 
                    mode: '', 
                    cancelButtonName: '',
                    submitButtonName: '',
                    confirmationMessage1: '',
                    confirmationMessage2: ''
                    };
    

    @wire(getContactList_RoleBased, { accountId: '$accountId' })
    wiredContactList(value) {
        // Hold on to the provisioned value so we can refresh it later.
        this.wiredContacts = value; // track the provisioned value
        const { error, data } = value; // destructure the provisioned value
        if (data) {
            console.log('getContactList_RoleBased returns: ', data);
            this.contacts = data;
            //this.contacts = JSON.parse(data); //data is returned as string
            console.log('getContactList_RoleBased returns this.contacts stringify: ', JSON.stringify(this.contacts));
            // this.hasRecords = (this.contacts.length > 0);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contacts = undefined;
            // this.hasRecords = false;
        }
    }

    @wire(getAccount, { accountId: '$accountId' })
    wiredAccountList(value) {
        const { error, data } = value; // destructure the provisioned value
        if (data) {
            console.log('getContactList_RoleBased returns: ', data);
            this.accounts = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.accounts = undefined;
            // this.hasRecords = false;
        }
    }

    handleContactSelect(event){
       //get contact id from Event selected event
       const contactRecordId = event.detail.value;
       // Navigate to Event record page
           this[NavigationMixin.Navigate]({
               type: 'standard__recordPage',
               attributes: {
                   recordId: contactRecordId,
                   objectApiName: 'Contact',
                   actionName: 'view',
               },
           });
    }

    handleContactSaved(event){
        return refreshApex(this.wiredContacts); //refresh lwc list
        //ref: https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.apex Topic: Refresh the Cache for a Wired Method
    }

    @track element;
    @track user;
    IsButtonDisabled;
    @track output;
    @track elements;
    @wire(getContactList_WithUser, { accountId: '$accountId' })
    wiredContactWithUserList(value) {
        // Hold on to the provisioned value so we can refresh it later.
        this.wiredContactsWithUser = value; // track the provisioned value
        const { error, data } = value; // destructure the provisioned value
        if (data) {
            console.log('getContactList_WithUser returns: ', data);
            //data is a json object from List<Map<String, String>>, example [ {
            //     "contactid": "0035O000002AFsIQAW",
            //     "contact": "{\"attributes\":{\"type\":\"Contact\",\"url\":\"/services/data/v47.0/sobjects/Contact/0035O000002AFsIQAW\"},\"Id\":\"0035O000002AFsIQAW\",\"Name\":\"John Smith\",\"FirstName\":\"John\",\"LastName\":\"Smith\",\"Business_Role__c\":\"N/A\",\"AccountId\":\"0015O000002rNYxQAM\",\"Email\":\"ben.soh+john@n4l.co.nz\",\"Title\":\"Acting Principal\",\"Phone\":\"02 132 1312\",\"Account\":{\"attributes\":{\"type\":\"Account\",\"url\":\"/services/data/v47.0/sobjects/Account/0015O000002rNYxQAM\"},\"Name\":\"Baradene College\",\"MoE_School_ID__c\":\"61\",\"MoE_Site_ID_Lookup__c\":\"a0D5O000000MF9rUAG\",\"Id\":\"0015O000002rNYxQAM\",\"MoE_Site_ID_Lookup__r\":{\"attributes\":{\"type\":\"MoE_School_Site__c\",\"url\":\"/services/data/v47.0/sobjects/MoE_School_Site__c/a0D5O000000MF9rUAG\"},\"Name\":\"D167\",\"Id\":\"a0D5O000000MF9rUAG\"}}}",
            //     "user": "{\"attributes\":{\"type\":\"User\",\"url\":\"/services/data/v47.0/sobjects/User/0055O000000jNpnQAE\"},\"ContactId\":\"0035O000002AFsIQAW\",\"Name\":\"John Smith\",\"Username\":\"ben.soh+john@n4l.co.nz\",\"IsActive\":true,\"IsPortalEnabled\":true,\"LastLoginDate\":\"2019-11-13T02:16:41.000+0000\",\"Id\":\"0055O000000jNpnQAE\"}"
            //   }, ]
            this.elements = data;
            this.output = data; 

            // this.elements.forEach(element => {
            //     let userElement = JSON.parse(element.userstring);
                
            //     if(userElement !== null){
            //         this.IsButtonDisabled = true;
            //     }else{
            //         this.IsButtonDisabled = false;
            //     }
            //         console.log('!!@@@!!!userString: ',userElement);
            //         console.log('!!@@@!!!button: ',this.IsButtonDisabled);
            // });

            // this.contacts = data;
            this.hasRecords = (this.elements.length > 0);

            this.buttonVisibleHandler();

            this.error = undefined;
        } else if (error) {
            this.error = error;
            // this.contacts = undefined;
            this.hasRecords = false;
        }
    }

    get displayOutput(){
        return JSON.stringify(this.output);
    }

    // Ben Soh @ 8/3/2021 removed entire section, as the form no longer required since we have implemented new Contact Management enhancement 5/3/2021
    // //--------------------------------- prepare URL for School Business Contact Form ---------------------------------
    // //get user record
    // userId = Id;
    // @wire(getRecord, { recordId: '$userId', fields: USER_FIELDS })
    // user;

    // schoolPrincipalContactId(){
    //     var contactId = '';
    //     if (this.contacts) { //Defensive programming! to prevent obj.data being 'undefined' because, there could be delayed when the page is loaded. Api may not be able to immediately.
    //         let principal = this.contacts.find(item => item.Business_Role__c.toLowerCase() === 'principal');
    //         if (principal){
    //             contactId = principal.Id;
    //         }
    //     }
    //     return contactId;
    // }

    // userNameWithDot(){
    //     var str = getFieldValue(this.user.data, USER_NAME_FIELD);
    //     if(str){
    //         str = str.replace(/\s+/g, '.');
    //         return str;
    //     }
    //     return '';
    // }

    // get schoolcontactformURL(){
    //     if(this.contacts && this.user){
    //         return `https://school-info.n4l.co.nz/form?contactid=${this.schoolPrincipalContactId()}&userid=${this.userNameWithDot()}`;
    //     }
    //     return 'https://school-info.n4l.co.nz/form';
    // }
    // //--------------------------------- prepare URL for School Business Contact Form ---------------------------------

    //commented out and replaced by updated query below
    // get getFeedback_NHR_ATP_URL(){
    //     if (this.contacts) { //Defensive programming! to prevent obj.data being 'undefined' because, there could be delayed when the page is loaded. Api may not be able to immediately.
    //         let principal = this.contacts.find(item => item.Business_Role__c.toLowerCase() === 'principal');
    //         if (principal){
    //             let url = `https://n4l.getfeedback.com/r/7NB2tmBO?&gf_q[8346340][16623239]=${principal.Name}`;
    //             url += `&gf_q[8346340][16623240]=Principal`;
    //             url += `&SchoolName=${principal.Account.Name}`;
    //             url += `&MoE_ID=${principal.Account.MoE_School_ID__c}`;
    //             url += `&Account_ID=${principal.AccountId}`;
    //             url += `&Contact_ID=${principal.Id}`;
    //             return url;
    //         }
    //     }
    //     return '#';
    // }

    get getFeedback_NHR_ATP_URL(){
        
        if (this.contacts) { //Defensive programming! to prevent obj.data being 'undefined' because, there could be delayed when the page is loaded. Api may not be able to immediately.
        //     let principal = this.contacts.find(item => item.Roles.toLowerCase() === 'principal');
        //     if (principal){
        //         let url = `https://n4l.getfeedback.com/r/7NB2tmBO?&gf_q[8346340][16623239]=${principal.Name}`;
        //         url += `&gf_q[8346340][16623240]=Principal`;
        //         url += `&SchoolName=${principal.Account.Name}`;
        //         url += `&MoE_ID=${principal.Account.MoE_School_ID__c}`;
        //         url += `&Account_ID=${principal.AccountId}`;
        //         url += `&Contact_ID=${principal.Id}`;
        //         return url;
        //     }
        // }

            if(this.contacts.principal && this.contacts.principal.length > 0){
                let principal = this.contacts.principal[0];
                let url = `https://n4l.getfeedback.com/r/7NB2tmBO?&gf_q[8346340][16623239]=${principal.Name}`;
                    url += `&gf_q[8346340][16623240]=Principal`;
                    url += `&SchoolName=${this.accounts.Name}`;
                    url += `&MoE_ID=${this.accounts.MoE_School_ID__c}`;
                    url += `&Account_ID=${this.accountId}`;
                    url += `&Contact_ID=${principal.Id}`;
                return url;
            }
        }

        return '#';
    }
    
    handleAddUserModal(event){
        //get contactId by clicked button
        const selectedRecordId = event.target.name;
        console.log('ContactId:'+selectedRecordId);
        this.selectedRecordId = selectedRecordId;
        
        this.currentContactElement = this.elements.find( ({ contactid }) => contactid === selectedRecordId );
        console.log('currentContactElement:'+this.currentContactElement);

        let contact = JSON.parse(this.currentContactElement.contactstring);
        console.log('contact:'+contact);
        
        this.modal.header = 'Support Hub User';
        this.modal.id = selectedRecordId;
        this.modal.elements = [];
        this.modal.mode = 'confirmToProceed';
        this.modal.cancelButtonName = 'No';
        this.modal.submitButtonName = 'Yes';
        this.modal.confirmationMessage1 = 'Create a user for ' + contact.Name + '?';
        this.modal.confirmationMessage2 = 'A user record cannot be deleted';

        const modal = this.template.querySelector('c-modal');
        modal.show();
        
        //this.addUser(selectedRecordId);
    }
    
    @track selectedRecordId;
    handleAddUser(event){
        //get json object from Modal
        const json = event.detail.value;
        console.log('json>>>>>:'+json.id);
        //just in case there are other similar modal event got fired, we need to make sure that it is refering to the same record that we are dealinig with.
        console.log('json>>>selectedRecordId>>:'+this.selectedRecordId);
        if(json.id === this.selectedRecordId){
            
            this.addUser();
        }
    }

    addUser(){
        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            createCustomerUser({ contactId: this.selectedRecordId, userOrigin: 'N4L Invitation - Default'})
                .then(result => {
               
                    this.output = result;
                    //this.elements = result;
                    this.error = undefined;
                })
                .catch(error => {
                    this.error = error;
                    this.response = undefined;
                    
                });
        }, DELAY);
    }

    buttonVisibleHandler(){
        getContactList_WithUser ({ accountId: this.accountId })
        .then(res => {
            let tempData = JSON.parse(JSON.stringify(res));
            console.log('!!@@@!!!res: ',tempData);
            this.elements = tempData;

            this.elements.forEach(element => {
                let userElement = JSON.parse(element.userstring);
                
                if(userElement !== null){
                    element.IsButtonDisabled = false;
                }else{
                    element.IsButtonDisabled = true;
                }
                    console.log('!!@@@!!!userString: ',userElement);
                    console.log('!!@@@!!!button: ',element.IsButtonDisabled);
            });
        })
    }
}