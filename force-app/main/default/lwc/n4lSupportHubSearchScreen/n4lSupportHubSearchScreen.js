import { LightningElement, api, track } from 'lwc';
import getResults from '@salesforce/apex/n4lAutoCompleteContact.getResults';
import getResultFromExistingSchool from '@salesforce/apex/n4lAutoCompleteContact.getResultFromExistingSchool';
import checkEmailDuplicates from '@salesforce/apex/n4lAutoCompleteContact.checkEmailDuplicates';
import checkEmailDomain from '@salesforce/apex/N4LFormScreen.checkEmailDomain';
import Screen_InvalidEmail from '@salesforce/label/c.Screen_InvalidEmail';
import Screen_DuplicateEmail from '@salesforce/label/c.Screen_DuplicateEmail';
import Screen_ReplaceDuplicateEmail from '@salesforce/label/c.Screen_ReplaceDuplicateEmail';
import Screen_WarningMessage from '@salesforce/label/c.Screen_WarningMessage';
import Screen_InheritCheckboxLabel from '@salesforce/label/c.Screen_InheritCheckboxLabel';
import Screen_SaveSuccess from '@salesforce/label/c.Screen_SaveSuccess';
import Screen_ErrorCompleteFields from '@salesforce/label/c.Screen_ErrorCompleteFields';
import Screen_MissingRole from '@salesforce/label/c.Screen_MissingRole';
import Screen_EmailDomain from '@salesforce/label/c.Screen_EmailDomain';
import Screen_SearchContact from '@salesforce/label/c.Screen_SearchContact';
import Screen_Generate_Random_Email from '@salesforce/label/c.Screen_Generate_Random_Email';
import Screen_ActiveLabel from '@salesforce/label/c.Screen_ActiveLabel';
import Screen_RoleDetails from '@salesforce/label/c.Screen_RoleDetails';
import Screen_NoEmail from '@salesforce/label/c.Screen_NoEmail';
export default class N4lSearchScreen extends LightningElement {
    @api recordId;
    @api objectName;
    @api fieldName;
    @api selectRecordId = '';
    @api accountId;
    @api selectRecordName;
    @api label;
    @api searchRecords = [];
    @api required = false;
    @api LoadingText = false;
    @api searchPlaceHolderText;
    @api isShowAdd;
    @api isReplace;
    @api replaceValue;
    @api emailaddress;
    @api emailEditable = false;
    @api selectedExistContact = false;
    @track txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track iconFlag = true;
    @track clearIconFlag = false;
    @track inputReadOnly = false;
    @track isContact = false;
    @track isShowResults = true;
    @track showEmailDomainWarning = false;
    @track domainWarningMes = "The email address doesn't match the school's email domain.";
    @track duplicateMes = "You can’t use this email address, as the contact already exists with this email address";
    label = {
        Screen_InvalidEmail, Screen_DuplicateEmail, Screen_WarningMessage, Screen_InheritCheckboxLabel,
        Screen_SaveSuccess, Screen_ErrorCompleteFields, Screen_MissingRole, Screen_ReplaceDuplicateEmail,
        Screen_EmailDomain, Screen_SearchContact, Screen_Generate_Random_Email, Screen_ActiveLabel,
        Screen_RoleDetails, Screen_NoEmail
    };

    connectedCallback() {
        if (this.objectName == 'Contact') {
            this.isContact = true;
        }
    }
    parentEmailChange(event) {
        this.emailaddress = event.target.value;
        const callparentemailchange = new CustomEvent("emailchangeevent", {
            detail: this.emailaddress
        });
        this.dispatchEvent(callparentemailchange);
    }
    searchField(event) {
        let emailCmp = this.template.querySelector('[data-id="userinput"]');
        emailCmp.setCustomValidity('');
        emailCmp.reportValidity();
        var currentText = event.target.value;
        this.parentEmailChange(event);
        this.searchProcess(currentText);
    }
    checkSearchEmailDuplicate(event) {
        let emailCmp = this.template.querySelector('[data-id="userinput"]');
        if (this.selectedExistContact == false) {
            console.log('**emailCmp**' + emailCmp);
            checkEmailDuplicates({
                email: this.emailaddress,
                recordId: this.recordId,
                emailEditable: this.emailEditable
            })
                .then((result) => {
                    console.log('**exist contact result**' + result);
                    if (result) {
                        //console.log('****' + this.label.Screen_DuplicateEmail);
                        this.isEmailExists = true;
                        //emailCmp.setCustomValidity(this.label.Screen_DuplicateEmail);
                        emailCmp.setCustomValidity(this.duplicateMes);
                        emailCmp.reportValidity();
                    } else {
                        if (!this.emailaddress.match('.+@[a-zA-Z0-9_-]+(\.).+')) {
                            emailCmp.setCustomValidity('Sorry, that email address is not valid.');

                        } else {
                            this.isEmailExists = false;
                            emailCmp.setCustomValidity('');
                            emailCmp.reportValidity();
                            this.verifyEmailDomain();
                        }
                    }
                }).catch((error) => {
                    console.log(error);
                });
        } else {
            this.showEmailDomainWarning = false;
            emailCmp.setCustomValidity('');
            emailCmp.reportValidity();
        }
    }
    ValidateEmailFormat() {
        //if (this.selectedExistContact == false) {
        const emailRegex = '.+@[a-zA-Z0-9_-]+(\.).+';
        let emailCmp = this.template.querySelector('[data-id="userinput"]');
        if (this.emailaddress.match(emailRegex)) {
            emailCmp.setCustomValidity('');

        } else {
            emailCmp.setCustomValidity('Sorry, that email address is not valid.');
        }

        // }
    }
    verifyEmailDomain() {
        checkEmailDomain({
            email: this.emailaddress,
            accountId: this.accountId
        }).then((result) => {
            this.isEmailDomainProceed = true;
            // let emailCmp = this.template.querySelector('[data-id="domainerror"]');
            console.log('domain result:=' + result);
            if (result) {

                this.showEmailDomainWarning = true;
                //emailCmp.setCustomValidity('');

            } else {
                this.showEmailDomainWarning = false;
                // emailCmp.setCustomValidity('');
            }
            // emailCmp.reportValidity();
            console.log('showEmailDomainWarning domain result:=' + this.showEmailDomainWarning);
        }).catch((error) => {
            console.log(error);
        });
    }
    searchProcess(inputValue) {
        this.LoadingText = true;
        if (this.isShowAdd && this.replaceValue == 'existingSchool') {
            getResultFromExistingSchool({
                value: inputValue, accountId: this.accountId
            }).then(result => {
                this.setSearchOptions(result);
            }).catch(error => {
                console.log('-------error-------------' + error);
                console.log(error);
            });
        } else {
            getResults({
                ObjectName: this.objectName, fieldName: this.fieldName,
                value: inputValue, accountId: this.accountId
            })
                .then(result => {
                    this.setSearchOptions(result);
                }).catch(error => {
                    console.log('-------error-------------' + error);
                    console.log(error);
                });
        }
    }

    setSearchOptions(searchRecs) {
        this.searchRecords = searchRecs;
        this.LoadingText = false;
        this.txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open';

        if (this.selectRecordId != null && this.selectRecordId.length > 0) {
            this.iconFlag = false;
            this.clearIconFlag = true;
        } else {
            this.iconFlag = true;
            this.clearIconFlag = false;
        }

    }

    onAddNewContact(event) {
        this.txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';

        // Creates the event with the data.
        const selectedEventFormScreen = new CustomEvent("addcontact", {
            detail: false
        });

        // Dispatches the event.
        this.dispatchEvent(selectedEventFormScreen);
    }

    setSelectedRecord(event) {
        var currentRecId = event.currentTarget.dataset.id;
        this.selectedExistContact = true;
        var selectName = event.currentTarget.dataset.name;
        this.emailaddress = event.currentTarget.dataset.name;
        this.txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        this.iconFlag = false;
        this.clearIconFlag = true;
        this.selectRecordId = currentRecId;
        this.inputReadOnly = true;
        this.isShowResults = false;
        console.log('currentRecId currentRecId===' + currentRecId);
        console.log('currentRecId emailaddress===' + this.emailaddress);
        const selectedEvent = new CustomEvent('selected', { detail: { selectName, currentRecId }, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);

        // Creates the event with the data.
        const selectedEventFormScreen = new CustomEvent("searchform", {
            //detail: currentRecId 
            detail: { recid: currentRecId, selectedemail: this.emailaddress }
        });

        // Dispatches the event.
        this.dispatchEvent(selectedEventFormScreen);

        // Creates the event with the data.
        const disableContactFormScreen = new CustomEvent("addcontact", {
            detail: true
        });

        // Dispatches the event.
        this.dispatchEvent(disableContactFormScreen);
        let emailCmp = this.template.querySelector('[data-id="userinput"]');
        emailCmp.setCustomValidity('');
        emailCmp.reportValidity();
    }

    @api
    processSearch(defaultEmailValue) {
        this.selectRecordName = defaultEmailValue;
        this.searchProcess(defaultEmailValue);
    }

    resetData(event) {
        this.selectedExistContact = false;
        this.selectRecordName = "";
        this.selectRecordId = "";
        this.emailaddress = "";
        this.inputReadOnly = false;
        this.iconFlag = true;
        this.clearIconFlag = false;
        this.isShowResults = true;
        const childReset = new CustomEvent("childresetevent", {
            detail: true
        });
        this.dispatchEvent(childReset);

    }
}