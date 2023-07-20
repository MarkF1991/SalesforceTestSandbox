// wireGetRecordDynamicaccount.js
import { LightningElement, api, wire, track } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'; // import toast message event .
import { getRecord } from 'lightning/uiRecordApi';
import getContactList from '@salesforce/apex/ContactController.getContactList';
import sendWaiverRequestEmail from '@salesforce/apex/ServiceWaiverController.sendWaiverRequestEmail';
import userId from '@salesforce/user/Id';

//to get picklist values of Waiver_Default_Categories__c in ..data.js. The @wire getpicklistvalue... method failed to deliver the outcome
import {multipicklistvalues} from './serviceWaiverData';


const FIELDS = [
    'Account.Name',
    'Account.Waiver_Default_Categories__c',
    'Account.Waiver_Default_Categories_Removed__c',
    'Account.Waiver_Firewall_Removed__c',
    'Account.Waiver_Web_Security_Removed__c',
];

export default class WireGetRecordDynamicAccount extends LightningElement {
    @api recordId;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: FIELDS
    })
    account;

    get name() {
        return this.account.data.fields.Name.value;
    }

    //picklist values -----------------------
    waiverDefaultCategoriesSelectedValues() {
        var myArray = [];
        if (this.account.data.fields.Waiver_Default_Categories__c.value) {
            myArray = this.account.data.fields.Waiver_Default_Categories__c.value.split(';'); //split multiselect picklist values into array
        }
        return myArray;
    }

    
    get waiverDefaultCategories() {
        return this.waiverDefaultCategoriesSelectedValues();
    }

    get waiverDefaultCategoriesUnselectedValues() {
        var selectedValues = this.waiverDefaultCategoriesSelectedValues();
        var unselectedValues = [];
        
        //var obj = this.picklistValues;
        var obj = multipicklistvalues();
            if (obj.data) { //Defensive programming! to prevent obj.data being 'undefined' because, there could be delayed when the page is loaded. Api may not be able to immediately.
                obj.data.values.forEach(function (data) {
                     if (selectedValues.findIndex((item) => item === data.value) < 0) {
                         unselectedValues.push(data.value);
                     }
                });
            }                
        return unselectedValues;
    }
    //picklist values -----------------------
    
    get waiverDefaultCategoriesRemoved() {
        return (!this.account.data.fields.Waiver_Default_Categories_Removed__c.value); //show checkbox in reversed: salesforce value = true means "Waived" in checkbox on display
    }

    get waiverFirewallRemoved() {
        return (!this.account.data.fields.Waiver_Firewall_Removed__c.value); //show checkbox in reversed: salesforce value = true means "Waived" in checkbox on display
    }

    get waiverWebSecurityRemoved() {
        return (!this.account.data.fields.Waiver_Web_Security_Removed__c.value); //show checkbox in reversed: salesforce value = true means "Waived" in checkbox on display
    }

    get DefaultCategoriesDisabled() {
        var result = 'Enabled';
        /*if(this.account.data.fields.Waiver_Default_Categories_Removed__c.value){ 
            result = 'Disabled';
        }*/
        return result;
    }

    get giveMeTrue(){
        return true;
    }

    get giveMeFalse(){
        return false;
    }

    get FirewallDisabled() {
        var result = 'Disable';
        /*if(this.account.data.fields.Waiver_Firewall_Removed__c.value){ 
            result = 'Disabled';
        }*/
        return result;
    }

    @track serviceToggle;
    get WebSecurityDisabled() {
        var result = 'Enabled';
        /*if(this.account.data.fields.Waiver_Web_Security_Removed__c.value){ 
            result = 'Disabled';
        }*/
        if (result === 'Enabled'){
            this.serviceToggle = 'serviceEnabled';
        }
        return result;
    }
    


    @track contacts;
    @track error;
    @track items;
    @wire(getContactList, {
        accountId: '$recordId'
    })
    wiredContacts({
        error,
        data
    }) {
        if (data) {
            this.contacts = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contacts = undefined;
        }
    }


    get contactOptions() {
        const myOptions = [];
        this.contacts.forEach(prepareMyOptions);

        // sort by label
        myOptions.sort(function(a, b) {
            var labelA = a.label.toUpperCase(); // ignore upper and lowercase
            var labelB = b.label.toUpperCase(); // ignore upper and lowercase
            if (labelA < labelB) {
                return -1;
            }
            if (labelA > labelB) {
                return 1;
            }
            // names must be equal
            return 0;
        });

        return myOptions;

        //loop through this.contacts to prepare an array of options {label, value} for combo box
        function prepareMyOptions(contact) {
            var newItem = {
                "label": contact.Name + ' - ' + contact.Email,
                "value": contact.Id
            };
            myOptions.push(newItem);
        }
    }

    @track selectedContactId;
    @track disabledButton = true; //default to disable Button, until user make a selection on Contact
    handleComboBoxChange(event) {
        this.selectedContactId = event.target.value;
        // Display field-level errors and disable button if a name field is empty.
        if (!event.target.value) {
            event.target.reportValidity();
            this.disabledButton = true;
        }
        else {
            this.disabledButton = false;
        }
    }


    @track includeAdditonalNote;
    includeAdditonalNote = false;

    handleCheckboxChange(event) {
        this.includeAdditonalNote = event.target.checked;
    }



    handleButtonClick(event) {
        //getfeedback url = https://n4l.getfeedback.com/r/GwKOsO9z?accountID={!Account.Id}&contactID={!Contact.Id}&ownerID={!Account.OwnerId}
        const hyperlink = 'https://n4l.getfeedback.com/r/GwKOsO9z?accountID=' + this.recordId + '&contactID=' + this.selectedContactId + '&ownerID=' + userId;
        var additionalNote = '';
        if (this.includeAdditonalNote) {
            additionalNote = '- note, your school has recently opted into this additional layer of threat protection and we recommend you do not remove this.';
        } else {
            additionalNote = '';
        }
        this.outputValue2 = hyperlink + ' | ' + additionalNote;

        sendWaiverRequestEmail({
                contactId: this.selectedContactId,
                accountId: this.recordId,
                userId: userId,
                hyperlink: hyperlink,
                additionalNote: additionalNote
            })
            .then(result => {
                this.error = undefined;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: ' Service Waiver Email successfully sent',
                        message: result,
                        variant: 'success',
                    }),
                );
            })
            .catch(error => {
                this.error = error;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while sending email',
                        message: error.message,
                        variant: 'error',
                    })
                );
            });
    }

    @track myversion;
    myversion = '3 this.waiverDefaultCategoriesSelectedValues();';//'ready for production';

    
}