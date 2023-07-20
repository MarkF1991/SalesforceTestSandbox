// wireGetRecordDynamicaccount.js
import { LightningElement, api, wire, track } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'; // import toast message event .
import { loadStyle } from "lightning/platformResourceLoader";

//import createCustomerUser from '@salesforce/apex/UserController.createCustomerUser';
import createCustomerUser from '@salesforce/apex/SupportHubInviteSignupController.InviteToCreateCustomerUser';
import inviteBtnIsClicked from '@salesforce/apex/SupportHubInviteSignupController.inviteBtnIsClicked';
import inviteBtnClickedTime from '@salesforce/apex/SupportHubInviteSignupController.InviteBtnClickedTime';
import updateCustomerUserPermissionSchoolReporting from '@salesforce/apex/UserController.updateUser_SchoolReporting_fields';
import updateCustomerUserPermissionFilteringPortal from '@salesforce/apex/UserController.updateUser_FilteringPortal_fields';
import updateCustomerUserPermissionNMS from '@salesforce/apex/UserController.updateUser_NMS_fields';

import getContact_WithUser from '@salesforce/apex/ContactController.getContact_WithUser';

import COMMUNITY_RESOURCE from '@salesforce/resourceUrl/ContactManagementScreens';

import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CONTACT_ACCOUNT_ONBOARDING_SCHOOL_REPORTING_FIELD from '@salesforce/schema/Contact.Account.Onboarding_School_Reporting__c';
import CONTACT_ACCOUNT_ONBOARDING_FILTERING_PORTAL_FIELD from '@salesforce/schema/Contact.Account.Onboarding_Filtering_Portal__c';

import USER_ID from '@salesforce/user/Id';
import PROFILE_UserLicense_Name_FIELD from '@salesforce/schema/User.Profile.UserLicense.Name';

const CONTACT_FIELDS = [CONTACT_ACCOUNT_ONBOARDING_SCHOOL_REPORTING_FIELD, CONTACT_ACCOUNT_ONBOARDING_FILTERING_PORTAL_FIELD];

/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;

export default class ContactSingleItem extends NavigationMixin(LightningElement){
    textValue = 'Email sent at: ';
    
    @api recordId;
    @api title;
    @api title2;
    @api checkboxLabel = 'I have verified that the email is fit for creating a Support Hub user';
    
    @api checkbox_toggle1_show = false;
    @api checkbox_toggle1_label;// = 'Access to School Reporting';
    @api checkbox_toggle1_message1;
    @api checkbox_toggle1_message2;

    @api checkbox_toggle2_show = false;
    @api checkbox_toggle2_label;// = 'Access to Filtering Portal';
    @api checkbox_toggle2_message1;
    @api checkbox_toggle2_message2;

    @api checkbox_toggle3_show = false;
    @api checkbox_toggle3_label;// = 'Access to NMS';
    @api checkbox_toggle3_message1;
    @api checkbox_toggle3_message2;

    @wire(CurrentPageReference) pageRef; //afterRender threw an error in 'c:accountLWC' [pubsub listeners need a "@wire(CurrentPageReference) pageRef" property]

    // Flexipage provides recordId and objectApiName
    @track contacts;
    @track error;
    @track hasRecords;

    @track output;
    @track currentContactElement;
    @track elements;
    @track isLoading = true;
    @track userlicense;

    @track modal = {header: '',
                    id: '',
                    elements: [], 
                    mode: '', 
                    cancelButtonName: '',
                    submitButtonName: '',
                    confirmationMessage1: '',
                    confirmationMessage2: ''
                    };
    
    @track checked1 = false; //verified email with unmatched school email domain
    
    @track response;
    
    connectedCallback() {
        loadStyle(this, COMMUNITY_RESOURCE + '/CSS/contactSingleItem.css');
    }

    @wire(getContact_WithUser, { contactId: '$recordId' })
    wiredgetContact_WithUser(value) {
        // Hold on to the provisioned value so we can refresh it later.
        this.wiredContactWithUser = value; // track the provisioned value
        const { error, data } = value; // destructure the provisioned value
        if (data) {
            console.log('wiredgetContact_WithUser returns: ', data);
            //data is a json object from List<Map<String, String>>, example [ {
            //     "contactid": "0035O000002AFsIQAW",
            //     "contact": "{\"attributes\":{\"type\":\"Contact\",\"url\":\"/services/data/v47.0/sobjects/Contact/0035O000002AFsIQAW\"},\"Id\":\"0035O000002AFsIQAW\",\"Name\":\"John Smith\",\"FirstName\":\"John\",\"LastName\":\"Smith\",\"Business_Role__c\":\"N/A\",\"AccountId\":\"0015O000002rNYxQAM\",\"Email\":\"ben.soh+john@n4l.co.nz\",\"Title\":\"Acting Principal\",\"Phone\":\"02 132 1312\",\"Account\":{\"attributes\":{\"type\":\"Account\",\"url\":\"/services/data/v47.0/sobjects/Account/0015O000002rNYxQAM\"},\"Name\":\"Baradene College\",\"MoE_School_ID__c\":\"61\",\"MoE_Site_ID_Lookup__c\":\"a0D5O000000MF9rUAG\",\"Id\":\"0015O000002rNYxQAM\",\"MoE_Site_ID_Lookup__r\":{\"attributes\":{\"type\":\"MoE_School_Site__c\",\"url\":\"/services/data/v47.0/sobjects/MoE_School_Site__c/a0D5O000000MF9rUAG\"},\"Name\":\"D167\",\"Id\":\"a0D5O000000MF9rUAG\"}}}",
            //     "user": "{\"attributes\":{\"type\":\"User\",\"url\":\"/services/data/v47.0/sobjects/User/0055O000000jNpnQAE\"},\"ContactId\":\"0035O000002AFsIQAW\",\"Name\":\"John Smith\",\"Username\":\"ben.soh+john@n4l.co.nz\",\"IsActive\":true,\"IsPortalEnabled\":true,\"LastLoginDate\":\"2019-11-13T02:16:41.000+0000\",\"Id\":\"0055O000000jNpnQAE\"}"
            //   }, ]
            this.elements = data;
            this.currentContactElement = this.elements.find( ({ contactid }) => contactid === this.recordId ); //get the element for the contact of current CustomerSignedId
            this.output = data; 
            this.error = undefined;
        } else if (error) {
            console.log(error);
            this.error = error;
            this.elements = undefined;
        }
        this.isLoading = false;
    }

    @wire(inviteBtnIsClicked, {contactId: '$recordId'}) invitebtnIsClicked;

    @wire(inviteBtnClickedTime, {contactId: '$recordId'}) inviteBtnClickedTime;

    @wire(getRecord,{
        recordId: USER_ID,
        fields: [PROFILE_UserLicense_Name_FIELD]
    }) wireuser({error,data}) {
        if (error) {
           this.error = error ; 
        } else if (data) {
            this.userlicense = data.fields.Profile.value.fields.UserLicense.value.fields.Name.value;
        }
    }

   //get order record
   @wire(getRecord, { recordId: '$recordId', fields: CONTACT_FIELDS })
   contactRecord;

    // get displayOutput(){
    //     if(this.output){
    //         return JSON.stringify(this.output);
    //     }
    //     return 'this.output is undefined';
    // }

    handleCheckbox1Change(event) {
        this.checked1 = event.target.checked;
    }

    get checkbox1_checked(){
        return (this.checked1? 'checked' : '');
    }
    get noUserYet(){
        if(this.currentContactElement){
            return this.currentContactElement.userstring === 'null';
        }
        return true;
    }

    get allowAddUser(){
        // if(this.checked1){
        //     return true; //overwrite the rule to allow creating Support Hub user using email with unmatched School Email Domain
        // }
        if(this.currentContactElement){
            let contact = JSON.parse(this.currentContactElement.contactstring);
            //return (contact.Email_Domain_Matched__c  && this.currentContactElement.userstring === 'null') ;
            return (contact.Email_Domain_Matched__c || this.checked1);
        }
        return false;
    }

    //user access permission ---------------------------------------
    get showUserAccess(){
        return !this.noUserYet;
    }

    get checkbox_toggle1_checked(){
        if(this.currentContactElement){
            let user = JSON.parse(this.currentContactElement.userstring);
            return (user.UserPermissionsSchoolReportingUser__c);
        }
        return false;
    }
        
    get checkbox_toggle1_disabled(){
        if(getFieldValue(this.contactRecord.data, CONTACT_ACCOUNT_ONBOARDING_SCHOOL_REPORTING_FIELD)){
            return !(getFieldValue(this.contactRecord.data, CONTACT_ACCOUNT_ONBOARDING_SCHOOL_REPORTING_FIELD) === 'Opt In' || getFieldValue(this.contactRecord.data, CONTACT_ACCOUNT_ONBOARDING_SCHOOL_REPORTING_FIELD) === 'Activated'); //if Activated = true, return disabled = false
        }
        return true;
    }
    
    //this is called with child component returned event: onupdateuserpermissionschoolreporting
    handleUpdateUserPermissionSchoolReporting(event){
        //get json object from Modal
        const json = event.detail.value;
        this.UpdateUserPermissionSchoolReporting(json.checkboxChecked);
    }
    
    UpdateUserPermissionSchoolReporting(checkboxToggleChecked){
        this.isLoading = true; //start spinner
        let user = JSON.parse(this.currentContactElement.userstring);

        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            updateCustomerUserPermissionSchoolReporting({ userId: user.Id, isSchoolReportingUser: checkboxToggleChecked})
                .then(result => {
        
                    this.response = JSON.parse(result.response); //result is a json object from Map<String, String>, example { "response": "{\"statusCode\":404,\"status\":\"NOT_FOUND\",\"error\":\"Could not find a Contract record with id = 8005O0000000QdWQAU\"}" }

                    if (this.response.statusCode === 200){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: this.title2,
                                message:'User Access Permission to School Reporting has been updated successfully',
                                variant: 'success',
                            }),
                        );
                    }

                    if (this.response.statusCode >= 400){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: this.title2,
                                message:'Error while updating User Access Permission to School Reporting : ' + this.response.error,
                                variant: 'error',
                            }),
                        );
                    }
                    this.error = undefined;
                    this.isLoading = false; //stop spinner: must be inside .then()
                })
                .catch(error => {
                    console.log('Error while granting School Reporting access to user : ' , error);
                    this.error = error;
                    this.response = undefined;
                });
        }, DELAY);      
    }

    get checkbox_toggle3_checked(){
        if(this.currentContactElement){
            let user = JSON.parse(this.currentContactElement.userstring);
            return (user.UserPermissionsNMSUser__c);
        }
        return false;
    }

    get checkbox_toggle3_disabled(){
        return this.userlicense != 'Salesforce' ? true : false;
    }

    get checkbox_toggle2_checked(){
        if(this.currentContactElement){
            let user = JSON.parse(this.currentContactElement.userstring);
            return (user.UserPermissionsFilteringPortalUser__c);
        }
        return false;
    }

    get checkbox_toggle2_disabled(){
        return true;
        //RA-603 Elina asked for making Filtering Portal access toggle available, and read-only. Therefore this is commmented out temporary until further notice from Elina.
        // if(getFieldValue(this.contactRecord.data, CONTACT_ACCOUNT_ONBOARDING_FILTERING_PORTAL_FIELD)){
        //     let onbordingFilteringPortal = getFieldValue(this.contactRecord.data, CONTACT_ACCOUNT_ONBOARDING_FILTERING_PORTAL_FIELD);
        //     return !(onbordingFilteringPortal === 'Opt In' || onbordingFilteringPortal === 'Activated'); //if Activated = true, return disabled = false
        // }
        //------------------------------- commented out to keep Filtering Portal access toggle disabled -------------------------------
    }

    //this is called with child component returned event: onupdateuserpermissionschoolreporting
    handleUpdateUserPermissionFilteringPortal(event){
        //get json object from Modal
        const json = event.detail.value;
        this.UpdateUserPermissionFilteringPortal(json.checkboxChecked);
    }
    
    UpdateUserPermissionFilteringPortal(checkboxToggleChecked){
        this.isLoading = true; //start spinner
        let user = JSON.parse(this.currentContactElement.userstring);

        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            updateCustomerUserPermissionFilteringPortal({ userId: user.Id, isFilteringPortalUser: checkboxToggleChecked})
                .then(result => {
        
                    this.response = JSON.parse(result.response); //result is a json object from Map<String, String>, example { "response": "{\"statusCode\":404,\"status\":\"NOT_FOUND\",\"error\":\"Could not find a Contract record with id = 8005O0000000QdWQAU\"}" }

                    if (this.response.statusCode === 200){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: this.title2,
                                message:'User Access Permission to Filtering Portal has been updated successfully',
                                variant: 'success',
                            }),
                        );
                    }

                    if (this.response.statusCode >= 400){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: this.title2,
                                message:'Error while updating User Access Permission to Filtering Portal : ' + this.response.error,
                                variant: 'error',
                            }),
                        );
                    }
                    this.error = undefined;
                    this.isLoading = false; //stop spinner: must be inside .then()
                })
                .catch(error => {
                    console.log('Error while granting Filtering Portal access to user : ' , error);
                    this.error = error;
                    this.response = undefined;
                });
        }, DELAY);      
    }
    
    handleUpdateuserpermissionnms(event) {
        //get json object from Modal
        const json = event.detail.value;
        this.UpdateUserPermissionNMS(json.checkboxChecked);
    }

    UpdateUserPermissionNMS(checkboxToggleChecked){
        this.isLoading = true; //start spinner
        let user = JSON.parse(this.currentContactElement.userstring);

        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            updateCustomerUserPermissionNMS({ userId: user.Id, isNMSUser: checkboxToggleChecked})
                .then(result => {
        
                    this.response = JSON.parse(result.response); //result is a json object from Map<String, String>, example { "response": "{\"statusCode\":404,\"status\":\"NOT_FOUND\",\"error\":\"Could not find a Contract record with id = 8005O0000000QdWQAU\"}" }

                    if (this.response.statusCode === 200){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: this.title2,
                                message:'User Access Permission to Network Management System has been updated successfully',
                                variant: 'success',
                            }),
                        );
                    }

                    if (this.response.statusCode >= 400){
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: this.title2,
                                message:'Error while updating User Access Permission to Network Management System : ' + this.response.error,
                                variant: 'error',
                            }),
                        );
                    }
                    this.error = undefined;
                    this.isLoading = false; //stop spinner: must be inside .then()
                })
                .catch(error => {
                    console.log('Error while granting Network Management System access to user : ' , error);
                    this.error = error;
                    this.response = undefined;
                });
        }, DELAY);      
    }
    //user access permission ---------------------------------------
    
    handleAddUserModal(){
        let contact = JSON.parse(this.currentContactElement.contactstring);
        this.modal.header = 'Support Hub User';
        this.modal.id = this.recordId;
        this.modal.elements = [];
        this.modal.mode = 'confirmToProceed';
        this.modal.cancelButtonName = 'No';
        this.modal.submitButtonName = 'Yes';
        this.modal.confirmationMessage1 = 'Create a user for ' + contact.Name + '?';
        this.modal.confirmationMessage2 = 'A user record cannot be deleted';

        const modal = this.template.querySelector('c-modal');
        modal.show();
    }

    handleAddUser(event){
        //get json object from Modal
        const json = event.detail.value;
        //just in case there are other similar modal event got fired, we need to make sure that it is refering to the same record that we are dealinig with.
        if(json.id === this.recordId){
            this.addUser();
        }
    }
    
    addUser(){
        this.isLoading = true; //start spinner
        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            //createCustomerUser({ contactId: this.recordId, approvedUnmatchEmailDomain: this.checked1 })
            createCustomerUser({ contactId: this.recordId, userOrigin: 'N4L Invitation - Default'})
                .then(result => {
               
                    this.output = result;
                    this.elements = result;
                    this.currentContactElement = this.elements.find( ({ contactid }) => contactid === this.recordId ); //get the element for the contact of current CustomerSignedId
                    this.isLoading = false; //stop spinner: must be inside .then(), and before .querySelector in child LWC

                    this.template.querySelector('c-contact-tile').reload(this.currentContactElement);
                    this.error = undefined;
                })
                .catch(error => {
                    this.error = error;
                    this.response = undefined;
                    
                });
        }, DELAY);
    }


    //result from createCustomerUser()
    //[{"contactid":"0035O0000022j5BQAQ","contactstring":"{\"attributes\":{\"type\":\"Contact\",\"url\":\"/services/data/v47.0/sobjects/Contact/0035O0000022j5BQAQ\"},\"Id\":\"0035O0000022j5BQAQ\",\"Name\":\"Catherine Petoe\",\"FirstName\":\"Catherine\",\"LastName\":\"Petoe\",\"Business_Role__c\":\"ICT Leader\",\"AccountId\":\"0015O000002rNYxQAM\",\"Email\":\"ben.soh+cpetoe-bc@n4l.co.nz\",\"Title\":\"ICT Leader\",\"Picture__c\":\"http://www.camhigh.school.nz/img/staff/thumb/sy.jpg\",\"Account\":{\"attributes\":{\"type\":\"Account\",\"url\":\"/services/data/v47.0/sobjects/Account/0015O000002rNYxQAM\"},\"Name\":\"Baradene College\",\"MoE_School_ID__c\":\"1000\",\"MoE_Site_ID_Lookup__c\":\"a0D5O000000MF9rUAG\",\"Id\":\"0015O000002rNYxQAM\",\"MoE_Site_ID_Lookup__r\":{\"attributes\":{\"type\":\"MoE_School_Site__c\",\"url\":\"/services/data/v47.0/sobjects/MoE_School_Site__c/a0D5O000000MF9rUAG\"},\"Name\":\"D167\",\"Id\":\"a0D5O000000MF9rUAG\"}}}","userstring":"{\"attributes\":{\"type\":\"User\",\"url\":\"/services/data/v47.0/sobjects/User/0055O000000lHJdQAM\"},\"ContactId\":\"0035O0000022j5BQAQ\",\"Name\":\"Catherine Petoe\",\"Username\":\"ben.soh+cpetoe-bc@n4l.co.nz\",\"IsActive\":true,\"IsPortalEnabled\":true,\"Id\":\"0055O000000lHJdQAM\"}"}]
}