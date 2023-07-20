// wireGetRecordDynamicaccount.js
import { LightningElement, api, wire, track } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'; // import toast message event .
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getContactList from '@salesforce/apex/ContactController.getContactList';
import OutboundCallOutcome from '@salesforce/apex/SafeAndSecureController.OutboundCallOutcome';

import CASE_CONTACTID from '@salesforce/schema/Case.ContactId';
import CASE_ACCOUNTID from '@salesforce/schema/Case.AccountId';
import CASE_ACCOUNT_NAME from '@salesforce/schema/Case.Account.Name';
import CASE_ISCLOSED from '@salesforce/schema/Case.IsClosed';
import CASE_PARENTID from '@salesforce/schema/Case.ParentId';

const CASE_FIELDS = [CASE_CONTACTID, CASE_ACCOUNTID, CASE_ACCOUNT_NAME, CASE_ISCLOSED, CASE_PARENTID];

export default class SafeAndSecure extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName = 'Account';
    @api title;
    @api isWithinTab = false;

    @api moreInfoButton;
    @api moreInfoConfirmation;
    @api tofixButton;
    @api tofixConfirmation;
    @api optoutButton;
    @api optoutConfirmation;



    @track isLoading = false; 
    @track error;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: CASE_FIELDS
    })
    case;

    // get display(){
    //     //for debugging purposes
    //     let displayFieldValues = [];
    //     displayFieldValues.push('CASE_CONTACTID :' + getFieldValue(this.case.data, CASE_CONTACTID));
    //     displayFieldValues.push('CASE_ACCOUNTID :' + getFieldValue(this.case.data, CASE_ACCOUNTID));
    //     displayFieldValues.push('CASE_ACCOUNT_NAME :' + getFieldValue(this.case.data, CASE_ACCOUNT_NAME));
    //     displayFieldValues.push('CASE_ISCLOSED :' + getFieldValue(this.case.data, CASE_ISCLOSED));
    //     displayFieldValues.push('get accountId() :' + this.accountId);
        
    //     return displayFieldValues;
    // }

    
    get accountId(){
        //getting case.accountId to pass to child component in order to display lightning-record-view-form
        return getFieldValue(this.case.data, CASE_ACCOUNTID);
    }

    get parentId(){
        //getting case.accountId to pass to child component in order to display lightning-record-view-form
        return getFieldValue(this.case.data, CASE_PARENTID);
    }

    get sldsHorizontalMargin(){
        return (this.isWithinTab ? 'slds-p-right_x-small' : 'slds-p-horizontal_small' );
    }
    
    @track _selectedContactId
    @api get selectedContactId() {
        return (this._selectedContactId ? this._selectedContactId : getFieldValue(this.case.data, CASE_CONTACTID));
      }
      set selectedContactId(val) {
        this._selectedContactId = val;
        if(val) {
            this.template.querySelector('c-contact-visual-picker').reloadCurrentContactElement(this._selectedContactId);//reload child component
            this.disabledButton = false;
        }
      }

    @track _disabledButton = true; //default to disable Button, until user make a selection on Contact
    @api get disabledButton() {
        if(getFieldValue(this.case.data, CASE_ISCLOSED)){
            return true; //disable buttons when the case is closed
        }
        //return(this._selectedContactId === undefined)
        if(this.selectedContactId && this.parentId == null) {
            this._disabledButton = false;
        }
        return this._disabledButton;
      }
      set disabledButton(val) {
        this._disabledButton = val;
      }

    // connectedCallback(){
    //     if(this.selectedContactId) {
    //         this.disabledButton = false;
    //     }
    // }
    
    //@track disabledButton = true; //default to disable Button, until user make a selection on Contact
    handleContactSelection(event){ 
        let contactElement = event.detail.value; //detail.value is a json object for option from ContractVisualPicker. 
        let contact = JSON.parse(contactElement.contactstring);
        this.selectedContactId = contact.Id;
        //this.disabledButton = false;
        this.template.querySelector('c-contact-visual-picker').reloadCurrentContactElement(this.selectedContactId);//reload child component
    }

    @track modal = {header: '',
                    id: '',
                    elements: [], 
                    mode: '', 
                    cancelButtonName: '',
                    submitButtonName: '',
                    confirmationMessage: '',
                    confirmationMessage2: ''
                    };

    handleWantMoreInfo(event){
        this.modal.header = 'Email More Info';
        this.modal.id = this.recordId;
        this.modal.elements = [];
        this.modal.mode = 'ToEmailMoreInfo';
        this.modal.cancelButtonName = 'No';
        this.modal.submitButtonName = 'Yes';
        this.modal.confirmationMessage = 'Are you sure you want to email more info?';
        this.modal.confirmationMessage2 = '';
                   
        const modal = this.template.querySelector('c-modal');
        modal.show();
    }

    handleProceedToEmailMoreInfo(){
        this.processOutboundCallOutcome('moreinfo');
    }

    handleToFix(event){
        this.modal.header = 'Agree To Fix';
        this.modal.id = this.recordId;
        this.modal.elements = [];
        this.modal.mode = 'ToFix';
        this.modal.cancelButtonName = 'No';
        this.modal.submitButtonName = 'Yes';
        this.modal.confirmationMessage = 'Are you sure you want to proceed to fix?';
        this.modal.confirmationMessage2 = '';
                   
        const modal = this.template.querySelector('c-modal');
        modal.show();
    }

    handleProceedToFix(){
        this.processOutboundCallOutcome('tofix');
        this.disabledButton = true;
    }

    handleOptOut(event){
        this.modal.header = 'Opt Out';
        this.modal.id = this.recordId;
        this.modal.elements = [];
        this.modal.mode = 'ToOptOut';
        this.modal.cancelButtonName = 'No';
        this.modal.submitButtonName = 'Yes';
        this.modal.confirmationMessage = 'Are you sure you want to Opt Out?';
        this.modal.confirmationMessage2 = '';
                   
        const modal = this.template.querySelector('c-modal');
        modal.show();
    }

    handleProceedToOptOut(){
        this.processOutboundCallOutcome('optout');
        this.disabledButton = true;
    }
    

    

    processOutboundCallOutcome(action) {
       this.disabledButton = true;
        this.isLoading= true;
            OutboundCallOutcome({
                contactId: this.selectedContactId,
                caseId: this.recordId,
                action: action
            })
            

            .then(result => {
                //console.log('result >>>>>>>', result);                
                this.response = JSON.parse(result.response); //result is a json object from Map<String, String>, example { "response": "{\"statusCode\":404,\"status\":\"NOT_FOUND\",\"error\":\"Could not find a Contract record with id = 8005O0000000QdWQAU\"}" }
                if (this.response.statusCode === 200){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Email successfully sent',
                            message: this.response,
                            variant: 'success',
                        }),
                    );
                }
                
                //if result returned service request case, then navigate to the record
                if (result.serviceRequestCase){
                    let serviceRequestCase = JSON.parse(result.serviceRequestCase);
                    //console.log('serviceRequestCase >>>>>>>', serviceRequestCase);  
                
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'A new Service Request Case has been created',
                                message: this.response,
                                variant: 'success',
                            }),
                        );
                        // View a custom object record.
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: serviceRequestCase.Id,
                                objectApiName: 'Case', // objectApiName is optional
                                actionName: 'view'
                            }
                        });
                   
                }

                if (this.response.statusCode >= 400){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error while sending email',
                            message: this.response.message,
                            variant: 'error',
                        }),
                    );
                }
                this.error = undefined;
                this.isLoading = false; //stop spinner: must be inside .then()
            })

            .catch(error => {
                this.error = error;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'LWC Error while sending email',
                        message: error.message,
                        variant: 'error',
                    })
                );
            });
    }

}