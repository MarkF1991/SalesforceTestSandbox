import { LightningElement, api, track } from 'lwc';

import { loadStyle } from "lightning/platformResourceLoader";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import retrieveMultipicklistValues from '@salesforce/apex/N4LFormScreen.retrieveMultipicklistValues';
import getUserLicense from '@salesforce/apex/N4LFormScreen.getUserLicense';
import getRecordDetails from '@salesforce/apex/N4LFormScreen.getRecordDetails';
import checkSupportHubUser from '@salesforce/apex/N4LFormScreen.checkSupportHubUser';
import saveRelationship from '@salesforce/apex/n4lAutoCompleteContact.saveRelationship';
import checkEmailDuplicates from '@salesforce/apex/N4LFormScreen.checkEmailDuplicates';
import addNewContact from '@salesforce/apex/n4lAutoCompleteContact.addNewContact';
import validateContactFieldEdits from '@salesforce/apex/n4lAutoCompleteContact.validateContactFieldEdits';
import captureContactPrimaryAccountName from '@salesforce/apex/N4LFormScreen.captureContactPrimaryAccountName';
import getContactEmail from '@salesforce/apex/N4LFormScreen.getContactEmail';
import retrieveScreenSettings from '@salesforce/apex/N4LFormScreen.retrieveScreenSettings';
import getAccountDetails from '@salesforce/apex/N4LFormScreen.getAccountDetails';
import matchRolesAndAuthorities from '@salesforce/apex/N4LFormScreen.matchRolesAndAuthorities';
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

import COMMUNITY_RESOURCE from '@salesforce/resourceUrl/ContactManagementScreens';

export default class N4lFormScreen extends LightningElement {

    @api recordId;
    @api accountId;
    @api objectName;
    @api relatedObjectName;
    @api invokePopup;
    @api headerTitle;
    @api saveRelButton;
    @api searchPlaceHolderText;
    @api isReplace = false;
    @api formFunction;
    @api accountName;
    @api userlicense;
    @api setUserLicense;
    @api popupForm;
    @api isAdvancedView;

    @track contactId;
    @track currentContactField = {};
    @track currentAccountContactField = {};
    @track isLoading = true;
    @track isSupportHubUser = true;
    @track isLoaded = true;
    @track isRelationshipLoad = false;
    @track addContact = false;
    @track isHideAccordion = false;
    @track isShowReplaceMenu = false;
    @track isEmailExists = false;
    @track salutationOptions = [];
    @track isShowAdd = true;
    @track isContactEditable = false;
    @track isEmailDomainWarning = true;
    @track isEmailDomainProceed = true;
    @track currentRecordRoles;
    @track currentRecordId;
    @track isRelationshipEditable = false;
    @track primaryAccountName;
    @track showWarning = false;
    @track emailResult;
    @track showAuthority = true;
    @track showSystemAccessible = true;
    @track showCreateSupportHubUser = true;
    @track isInherit = false;
    @track isGenerateRandomEmail = false;
    @track oldEmailAddress = '';
    @track emailEditable = false;
    @track showEmailDomainWarning = false;
    @track emailDomain = '';
    //checkbox group demo
    @track selectedroles = [];
    @track selectedrolevalue = '';
    @track error;
    @track options = [];
    @track checkboxdisabled = false;
    @track dataList;
    @track rolefieldValue;
    activeSections = ['PersonalDetailsSection', 'CommunicationPreferencesSection', 'RelationshipDetailsSection', 'OtherDetailsSection'];

    label = {
        Screen_InvalidEmail, Screen_DuplicateEmail, Screen_WarningMessage, Screen_InheritCheckboxLabel,
        Screen_SaveSuccess, Screen_ErrorCompleteFields, Screen_MissingRole, Screen_ReplaceDuplicateEmail,
        Screen_EmailDomain, Screen_SearchContact, Screen_Generate_Random_Email, Screen_ActiveLabel,
        Screen_RoleDetails, Screen_NoEmail
    };

    connectedCallback() {
        console.log('formFunction ***** = ' + this.formFunction);
        loadStyle(this, COMMUNITY_RESOURCE + '/CSS/communityTableScreen.css');
        if (this.searchMenu) { this.isContactEditable = false; this.isRelationshipEditable = false; }
        ///if (this.isReplace) { this.isHideAccordion = true; this.isShowReplaceMenu = true; }

        this.fetchUserLicense();
        this.fetchAccountDetails();
        ///this.fetchPicklistValues();
    }

    replaceValue = '';

    get replaceCategories() {
        return [
            { label: 'Somebody existing in my school', value: 'existingSchool' },
            { label: 'Somebody outside my school', value: 'outsideSchool' },
        ];
    }

    get searchMenu() {

        return this.formFunction != 'Update';

    }

    get editableContactFields() {
        /// set to true for testing
        return true
        if (this.searchMenu && !this.addContact) {
            return false;
        } else if (this.isContactEditable && !this.searchMenu) {
            return false;
        } else {
            return true;
        }
    }

    get showSaveButton() {
        return !this.isContactEditable || !this.isRelationshipEditable;
    }

    get showEmailChangeView() {
        return this.isInherit || this.isGenerateRandomEmail;
    }

    fetchUserLicense() {
        getUserLicense({
        }).then((result) => {
            this.userlicense = result;
        }).catch((error) => {
            console.log(error);
        });
    }

    fetchAccountDetails() {
        getAccountDetails({
            recordId: this.recordId,
            accountId: this.accountId
        }).then((result) => {
            this.accountId = result.Id;
            this.accountName = result.Name;
            this.emailDomain = result.Email_Domain__c;

            ///this.getScreenSettings();
            this.fetchContactDetails();
            this.contactFieldEditsPermission();
        }).catch((error) => {
            console.log(error);
        });
    }

    getScreenSettings() {
        retrieveScreenSettings({
        }).then((result) => {
            console.log('===>User License' + this.userlicense);
            if (this.userlicense != 'Salesforce') {
                this.showAuthority = result.Show_authority__c;
                this.showSystemAccessible = result.Show_system_accessible__c;
                this.showCreateSupportHubUser = result.Show_Create_Support_Hub_User__c;
            }
        }).catch((error) => {
            console.log(error);
        });
    }

    contactFieldEditsPermission() {
        console.log('==> AccountId' + this.accountId);
        console.log('==> Record' + this.recordId);

        validateContactFieldEdits({
            recordId: this.recordId,
            accountId: this.accountId
        })
            .then((result) => {
                console.log('==> contactFieldEditsPermission this.searchMenu' + this.searchMenu);
                console.log('==> &&&&&&&&&& disableContact' + result[0]);
                console.log('==> &&&&&&&&&&  disableRelation' + result[1]);

                if (!this.searchMenu) {
                    this.isContactEditable = result[0];
                    ///this.isEmailDomainWarning = result[1]
                    this.isRelationshipEditable = result[1];
                }
            }).catch((error) => {
                console.log(error);
            });
    }

    handleReplaceSelection(event) {
        this.replaceValue = event.target.value;

        this.isHideAccordion = false;
        this.clearContactFields();

        if (this.replaceValue == 'existingSchool') {
            this.isShowAdd = true;
        } else {
            this.isShowAdd = false;
        }
    }

    fetchContactDetails() {
        console.log('this.recordId=>' + this.recordId);
        console.log('this.contactId=>' + this.contactId);
        console.log('this.accountId=>' + this.accountId);
        getRecordDetails({
            recordId: this.recordId,
            contactId: this.contactId,
            objectName: 'Contact',
            isReplace: this.isReplace,
            accountId: this.accountId,
            replaceValue: this.replaceValue
        })
            .then((result) => {
                result.forEach((contactData) => {
                    if (contactData.fieldName == 'id') { this.contactId = contactData.fieldValue; }
                    else if (contactData.fieldName == 'email') { this.currentContactField.Email = contactData; }
                    else if (contactData.fieldName == 'secondary_email__c') { this.currentContactField.Secondary_Email__c = contactData; }
                    else if (contactData.fieldName == 'firstname') { this.currentContactField.FirstName = contactData; }
                    else if (contactData.fieldName == 'system_accessible__c') { this.currentContactField.System_Accessible__c = contactData; }
                    else if (contactData.fieldName == 'lastname') { this.currentContactField.LastName = contactData; }
                    else if (contactData.fieldName == 'title') { this.currentContactField.Title = contactData; }
                    else if (contactData.fieldName == 'mobilephone') { this.currentContactField.MobilePhone = contactData; }
                    else if (contactData.fieldName == 'outage_notifications__c') { this.currentContactField.Outage_notifications__c = contactData; }
                    else if (contactData.fieldName == 'periodic_survey_emails__c') { this.currentContactField.Periodic_Survey_Emails__c = contactData; }
                    else if (contactData.fieldName == 'current_n4l_product_and_service_updates__c') { this.currentContactField.Current_N4L_product_and_service_updates__c = contactData; }
                    // else if(contactData.fieldName == 'hasoptedoutofemail') {this.currentContactField.HasOptedOutOfEmail = contactData;} 
                });

                if (this.formFunction == 'Add') {
                    this.headerTitle = 'Add a new contact for your school';
                } else if (this.formFunction == 'Replace') {
                    this.headerTitle = 'Replace ' + this.currentContactField.FirstName.fieldValue;
                } else {
                    this.headerTitle = this.currentContactField.FirstName.fieldValue + ' ' + this.currentContactField.LastName.fieldValue;
                }

                this.fetchPrimaryAccount();
                this.supportHubUser();
            }).catch((error) => {
                console.log('=== ERROR on Contact fetch ===');
                console.log(error);

                this.isLoading = false;
                this.isLoaded = false;
            });
    }

    fetchPrimaryAccount() {
        captureContactPrimaryAccountName({
            accConRelId: this.recordId
        }).then((result) => {
            this.primaryAccountName = result;
        }).catch((error) => {
            console.log(error);
            this.isLoading = false;
        });
    }

    supportHubUser() {
        checkSupportHubUser({
            recordId: this.recordId,
            contactId: this.contactId,
            objectName: 'AccountContactRelation',
            isReplace: this.isReplace
        }).then((result) => {
            console.log('-->' + result);
            this.isSupportHubUser = result;
            this.fetchAccountRelationDetails();
        }).catch((error) => {
            console.log(error);
            this.isLoading = false;
        });
    }

    fetchAccountRelationDetails() {
        getRecordDetails({
            recordId: this.recordId,
            contactId: this.contactId,
            objectName: 'AccountContactRelation',
            isReplace: this.isReplace,
            accountId: this.accountId,
            replaceValue: this.replaceValue
        })
            .then((result) => {
                result.forEach((accountContactData) => {
                    if (accountContactData.fieldName == 'id') { this.recordId = accountContactData.fieldValue; }
                    else if (accountContactData.fieldName == 'roles') {
                        this.currentAccountContactField.Roles = accountContactData;
                        if (this.currentAccountContactField.Roles.fieldValue != undefined && this.currentAccountContactField.Roles.fieldValue != null) {
                            this.selectedroles = this.currentAccountContactField.Roles.fieldValue.split(';');
                            console.log('!@#$ this.selectedroles=' + this.selectedroles);
                        }
                        console.log('!@#$=' + this.currentAccountContactField.Roles.fieldValue);
                    }
                    else if (accountContactData.fieldName == 'authority__c') { this.currentAccountContactField.Authority__c = accountContactData; }
                    else if (accountContactData.fieldName == 'isactive') { this.currentAccountContactField.IsActive = accountContactData; }
                    else if (accountContactData.fieldName == 'can_provide_site_access__c') { this.currentAccountContactField.Can_Provide_Site_Access__c = accountContactData; }
                });
                this.fetchPicklistValues();
                if (this.isReplace) {
                    let newRoles = [];

                    if (this.currentRecordRoles != null) {
                        var currentRecordRoleList = this.currentRecordRoles.split(';');

                        newRoles = this.currentAccountContactField.Roles.fieldValue != undefined ? this.currentAccountContactField.Roles.fieldValue.split(';') : [];

                        for (let i = 0; i < currentRecordRoleList.length; i++) {
                            if (this.currentAccountContactField.Roles.fieldValue != undefined) {
                                if (!this.currentAccountContactField.Roles.fieldValue.includes(currentRecordRoleList[i])) {
                                    newRoles.push(currentRecordRoleList[i]);
                                }
                            } else {
                                newRoles.push(currentRecordRoleList[i]);
                            }
                        }

                        this.currentAccountContactField.Roles.fieldValue = newRoles.join(";");
                        ///this.handlePicklistRoles(null);

                    }
                }

                this.isLoading = false;
                this.isLoaded = false;
                this.isRelationshipLoad = false;

                if (this.template.querySelectorAll('c-n4-l-multipicklist-screen')[0] != undefined && this.showAuthority) {
                    this.template.querySelectorAll('c-n4-l-multipicklist-screen')[0].processMyData(this.currentAccountContactField.Roles.fieldValue);
                }

                this.activeSections = ['PersonalDetailsSection', 'CommunicationPreferencesSection', 'RelationshipDetailsSection', 'OtherDetailsSection'];
            }).catch((error) => {
                console.log(error);
                this.isLoading = false;
                this.isLoaded = false;
                this.isRelationshipLoad = false;
            });

    }

    handleSearchForm(event) {
        ///this.searchMenu = false;
        this.isRelationshipLoad = true;
        ///this.contactId = event.detail;
        this.contactId = event.detail.recid;
        this.emailResult = event.detail.selectedemail
        this.addContact = true;
        this.currentRecordRoles = this.currentAccountContactField.Roles.fieldValue;
        this.currentRecordId = this.recordId;
        this.isContactEditable = true;
        this.isRelationshipEditable = false;
        console.log('handleSearchForm->currentRecordId=' + this.currentRecordId);
        console.log('handleSearchForm->this.recordId=' + this.recordId);
        console.log('handleSearchForm->this.searchMenu=' + this.searchMenu);
        console.log('handleSearchForm->isContactEditable=' + this.isContactEditable);
        console.log('handleSearchForm->isRelationshipEditable=' + this.isRelationshipEditable);
        console.log('handleSearchForm->this.accountId=' + this.accountId);
        console.log('handleSearchForm->this.contactId=' + this.contactId);
        this.fetchContactDetails();
        //this.emailResult = this.currentContactField.email;
        //console.log('handleSearchForm email result :' + this.emailResult);
        // console.log('handleSearchForm email result :' + this.currentContactField.email);

    }

    handleEmailChange(event) {
        this.emailResult = this.formFunction == 'Update' ? event.target.value : event.detail;
        console.log('===>' + this.emailEditable);
        console.log('email search key word' + this.emailResult);

        checkEmailDuplicates({
            email: this.emailResult,
            recordId: this.recordId,
            emailEditable: this.emailEditable
        })
            .then((result) => {
                let emailCmp = this.template.querySelector('[data-id="' + this.currentContactField.Email.fieldName + '"]');
                //let emailCmp = this.template.querySelector('c-n4l-support-hub-search-screen[data-id="resultBox"]');
                console.log('**emailCmp**' + emailCmp);
                if (result) {
                    console.log('****' + this.label.Screen_DuplicateEmail);
                    this.isEmailExists = true;
                    if (this.isReplace) {
                        emailCmp.setCustomValidity(this.label.Screen_ReplaceDuplicateEmail);
                    } else {
                        emailCmp.setCustomValidity(this.label.Screen_DuplicateEmail);
                    }
                    emailCmp.reportValidity();

                    // if(!this.isInherit) {this.template.querySelectorAll('c-n4l-search-screen')[0].processSearch(this.emailResult);}
                } else {
                    this.isEmailExists = false;
                    emailCmp.setCustomValidity('');
                    emailCmp.reportValidity();
                    this.verifyEmailDomain();
                }
            }).catch((error) => {
                console.log(error);
            });
    }

    verifyEmailDomain() {
        checkEmailDomain({
            email: this.emailResult,
            accountId: this.accountId
        }).then((result) => {
            this.isEmailDomainProceed = true;
            let emailCmp = this.template.querySelector('[data-id="' + this.currentContactField.Email.fieldName + '"]');
            //let emailCmp = this.template.querySelector('c-n4l-support-hub-search-screen[data-id="resultBox"]');
            if (result) {
                if (this.isEmailDomainWarning) {
                    this.showEmailDomainWarning = true;
                    emailCmp.setCustomValidity('');
                } else {
                    this.isEmailDomainProceed = false;
                    this.showEmailDomainWarning = false;
                    emailCmp.setCustomValidity(this.label.Screen_EmailDomain);
                }
            } else {
                this.showEmailDomainWarning = false;
                emailCmp.setCustomValidity('');
            }
            emailCmp.reportValidity();
        }).catch((error) => {
            console.log(error);
        });
    }

    handleAddContact(event) {
        this.addContact = event.detail;
        console.log('add contact', this.addContact);
        if (!this.addContact) {
            this.clearContactFields();
            this.isGenerateRandomEmail = true;

            if (this.isReplace) {
                getContactEmail({
                    recordId: this.recordId
                }).then((result) => {
                    this.isInherit = result != null && result != '' ? true : false;
                    this.oldEmailAddress = result;
                }).catch((error) => {
                    console.log(error);
                });
            }
        }
    }


    clearContactFields() {
        this.isSupportHubUser = false;
        this.currentContactField.Email.fieldValue = '';
        /// this.currentContactField.Secondary_Email__c.fieldValue = '';
        this.currentContactField.FirstName.fieldValue = '';
        this.currentContactField.LastName.fieldValue = '';
        this.currentContactField.Title.fieldValue = '';
        this.currentContactField.MobilePhone.fieldValue = '';
        /// this.currentContactField.Outage_notifications__c.fieldValue = false;
        ///  this.currentContactField.Periodic_Survey_Emails__c.fieldValue = false;
        /// this.currentContactField.Current_N4L_product_and_service_updates__c.fieldValue = false;
        // this.currentContactField.HasOptedOutOfEmail.fieldValue = false;
    }

    handlePicklistRoles(event) {
        this.currentAccountContactField.Roles.fieldValue = event == null ? this.currentAccountContactField.Roles.fieldValue : event.detail;

        matchRolesAndAuthorities({})
            .then((result) => {
                console.log(result);
                this.currentAccountContactField.Authority__c.fieldValue = '';

                result.forEach(roleAuthorityMatch => {
                    if (this.currentAccountContactField.Roles.fieldValue.includes(roleAuthorityMatch.MasterLabel)) {
                        if (roleAuthorityMatch.Default_authority_types__c != '' && roleAuthorityMatch.Default_authority_types__c != null) {
                            if (this.currentAccountContactField.Authority__c.fieldValue == '' || this.currentAccountContactField.Authority__c.fieldValue == null) {
                                this.currentAccountContactField.Authority__c.fieldValue = roleAuthorityMatch.Default_authority_types__c;
                            } else {
                                this.currentAccountContactField.Authority__c.fieldValue = this.currentAccountContactField.Authority__c.fieldValue + ';' + roleAuthorityMatch.Default_authority_types__c;
                            }
                        } else {
                            this.currentAccountContactField.Authority__c.fieldValue = roleAuthorityMatch.Default_authority_types__c;
                        }

                        if (this.currentAccountContactField.Authority__c.fieldValue != null) {
                            var setOfAuthority = new Set();
                            var listOfAuthority = this.currentAccountContactField.Authority__c.fieldValue.split(';');

                            listOfAuthority.forEach(authority => {
                                setOfAuthority.add(authority);
                            });

                            this.currentAccountContactField.Authority__c.fieldValue = [...setOfAuthority].join(";");
                        }

                        this.currentContactField.Outage_notifications__c.fieldValue = roleAuthorityMatch.Is_Outage_notifications_checked__c;
                        this.currentContactField.Periodic_Survey_Emails__c.fieldValue = roleAuthorityMatch.Is_periodic_emails_checked__c;
                        this.currentContactField.Current_N4L_product_and_service_updates__c.fieldValue = roleAuthorityMatch.Is_Operational_emails_checked__c;
                    }
                });

                if (this.currentAccountContactField.Authority__c.fieldValue == undefined) {
                    this.currentAccountContactField.Authority__c.fieldValue = '';
                }

                if (this.showAuthority) {
                    this.template.querySelectorAll('c-n4-l-multipicklist-screen')[1].processMyData(this.currentAccountContactField.Authority__c.fieldValue);
                }
            }).catch((error) => {
                console.log(error);
            });
    }

    handlePicklistAuthorities(event) {
        this.currentAccountContactField.Authority__c.fieldValue = event.detail;
    }


    handleCloseForm(event) {
        this.invokePopup = false;
        // Creates the event with the data.
        const selectedEvent = new CustomEvent("closeform", {
            detail: this.invokePopup
        });

        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    openWarningMessage(event) {
        if (this.popupForm) { this.template.querySelector('[data-id="main-form"]').style = 'opacity:-1'; }

        if (this.formFunction == 'Update') {
            this.showWarning = true;
        } else {
            this.saveContact(event);
        }
    }

    cancelWarningMessage() {
        if (this.popupForm) { this.template.querySelector('[data-id="main-form"]').style = 'opacity : unset'; }
        this.showWarning = false;
    }

    saveContact(event) {
        this.showWarning = false;
        this.isLoaded = true;
        console.log('save contact event:');
        console.log('this.isReplace:' + this.isReplace);
        console.log('this.replaceValue:' + this.replaceValue);
        console.log('this.addContact:' + this.addContact);
        console.log('this.editableContactFields:' + this.editableContactFields);
        if (this.isReplace && this.replaceValue != 'existingSchool') {
            console.log('event order 1');
            this.saveRelationship(event, true);
        } else if (this.isReplace && this.replaceValue == 'existingSchool') {
            if (!this.addContact) {
                console.log('event order 2');
                this.addNewContact(event);
            } else {
                console.log('event order 3');
                this.saveRelationship(event, false);
            }
        } else {
            if (!this.addContact) {
                console.log('event order 4');
                this.addNewContact(event);
            } else {
                if (!this.editableContactFields) {
                    console.log('event order 5');
                    this.addNewContact(event);
                } else {
                    console.log('event order 6');
                    ///this.addNewContact(event); /// set for testing
                    this.saveRelationship(event, false);
                }
            }
        }
    }

    addNewContact(event) {
        console.log('this.emailResult===>' + this.emailResult);
        let conLastName = this.template.querySelector('[data-id="' + this.currentContactField.LastName.fieldName + '"]').value;
        console.log('conLastName===>' + conLastName);
        let conFirstName = this.template.querySelector('[data-id="' + this.currentContactField.FirstName.fieldName + '"]').value;
        console.log('conconFirstName===>' + conFirstName);
        //let emailfieldinput = this.template.querySelector('[data-id="' + this.currentContactField.Email.fieldName + '"]').value;
        let conEmail = this.formFunction == 'Update' ? this.template.querySelector('[data-id="' + this.currentContactField.Email.fieldName + '"]').value : this.emailResult;
        let accConRole = this.currentAccountContactField.Roles.fieldValue;
        console.log('conEmail===>' + conEmail);
        console.log('conLastName===>' + conLastName);
        console.log('conconFirstName===>' + conFirstName);

        if (accConRole != '' && accConRole != null && conLastName != '' && conLastName != null
            && conFirstName != '' && conFirstName != null && conEmail != '' && conEmail != null
            && this.isEmailDomainProceed) {

            ///console.log('===>' + this.currentContactField.System_Accessible__c.fieldValue);

            if (!this.isEmailExists) {
                let supportHubUser = false;

                ///if (this.template.querySelector('[data-id="Create_Support_Hub_User__c"]') != null) {
                ///    supportHubUser = this.template.querySelector('[data-id="Create_Support_Hub_User__c"]').checked;
                ///}

                console.log('This accountId :' + this.accountId);
                console.log('This recordId :' + this.recordId);
                console.log('Email Editable :' + this.emailEditable);

                addNewContact({
                    newEmail: conEmail,
                    firstName: conFirstName,
                    lastName: conLastName,
                    jobTitle: this.template.querySelector('[data-id="' + this.currentContactField.Title.fieldName + '"]').value,
                    mobilePhone: this.template.querySelector('[data-id="' + this.currentContactField.MobilePhone.fieldName + '"]').value,
                    ///outageNotif: this.template.querySelector('[data-id="' + this.currentContactField.Outage_notifications__c.fieldName + '"]').checked,
                    ///periodicEmail: this.template.querySelector('[data-id="' + this.currentContactField.Periodic_Survey_Emails__c.fieldName + '"]').checked,
                    ///operational: this.template.querySelector('[data-id="' + this.currentContactField.Current_N4L_product_and_service_updates__c.fieldName + '"]').checked,
                    // HasOptedOutOfEmail  : this.template.querySelector('[data-id="'+this.currentContactField.HasOptedOutOfEmail.fieldName+'"]').checked, 
                    ///createSupportHubUser: supportHubUser,
                    accountId: this.accountId,
                    recordId: this.recordId,
                    isReplace: this.isReplace,
                    replaceValue: this.replaceValue,
                    isInherit: this.isInherit,
                    isActive: true
                    ///secondaryEmail: this.template.querySelector('[data-id="' + this.currentContactField.Secondary_Email__c.fieldName + '"]').value,
                    ///systemAccessible: this.currentContactField.System_Accessible__c.fieldValue,
                    ///isActive: this.template.querySelector('[data-id="' + this.currentAccountContactField.IsActive.fieldName + '"]').checked,
                })
                    .then((result) => {
                        this.contactId = result.Id;
                        this.saveRelationship(event, false);
                    }).catch((error) => {
                        console.log(error);
                        this.showErrorMessages(error.body.message);
                    });
            } else {
                this.showErrorMessages(this.label.Screen_DuplicateEmail);
            }
        } else {
            this.showErrorMessages(!this.isEmailDomainProceed ? this.label.Screen_EmailDomain : this.label.Screen_ErrorCompleteFields);
        }
    }

    showErrorMessages(errorMessage) {
        this.handleError(errorMessage);
        this.isLoading = false;
        this.isLoaded = false;
        this.cancelWarningMessage();
    }

    saveRelationship(event, isChangeOldEmail) {

        if (this.currentAccountContactField.Roles.fieldValue != '' && this.currentAccountContactField.Roles.fieldValue != null) {
            let supportHubUser = false;

            ///if (this.template.querySelector('[data-id="Create_Support_Hub_User__c"]') != null) {
            ///    supportHubUser = this.template.querySelector('[data-id="Create_Support_Hub_User__c"]').checked;
            ///}

            console.log('Contact Id' + this.contactId);
            console.log('Account Contact Id' + this.recordId);
            console.log('Roles' + this.currentAccountContactField.Roles.fieldValue);

            saveRelationship({
                recordId: this.recordId,
                accountId: this.accountId,
                contactId: this.contactId,
                isActive: true,
                canProvideSiteAccess: false,
                isInherit: false,
                createSupportHubUser: false,
                ///isActive: this.template.querySelector('[data-id="' + this.currentAccountContactField.IsActive.fieldName + '"]').checked,
                ///canProvideSiteAccess: this.template.querySelector('[data-id="' + this.currentAccountContactField.Can_Provide_Site_Access__c.fieldName + '"]').checked,
                roles: this.currentAccountContactField.Roles.fieldValue,
                ///authorities: this.currentAccountContactField.Authority__c.fieldValue,
                ///createSupportHubUser: supportHubUser,
                currentRecordId: this.currentRecordId,
                isReplace: this.isReplace,
                replaceValue: this.replaceValue,
                isChangeOldEmail: isChangeOldEmail
                //isInherit: false,
                ///systemAccessible: this.currentContactField.System_Accessible__c.fieldValue
            })
                .then((result) => {
                    this.isLoaded = false;
                    this.showToast({
                        message: this.successMessage || this.label.Screen_SaveSuccess
                    });
                    this.handleCloseForm(event);
                }).catch((error) => {
                    console.log(error);
                    this.showErrorMessages(error.body.message);
                });
        } else {
            this.showErrorMessages(this.label.Screen_MissingRole);
        }
    }

    showToast({ title, message, variant, mode }) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title || 'Success',
                message: message,
                variant: variant || 'success',
                mode: mode || 'dismissable'
            })
        );
    }

    handleError(errorMessage) {
        console.error(errorMessage);
        this.showToast({
            title: 'Error',
            message: errorMessage,
            variant: 'error',
            mode: 'dismissable'
        });
    }
    handleChildReset(event) {
        console.log('reset this.recordId=>' + this.recordId);
        console.log('reset this.contactId=>' + this.contactId);
        console.log('reset this.accountId=>' + this.accountId);
        this.currentContactField.Email = '';
        this.currentContactField.FirstName = '';
        this.currentContactField.LastName = '';
        this.currentContactField.Title = '';
        this.selectRecordName = "";
        this.selectRecordId = "";
        this.inputReadOnly = false;
        this.currentAccountContactField.Roles.fieldValue = '';
        //this.currentAccountContactField.Roles = '';
        this.isContactEditable = false;
        this.isRelationshipEditable = false;
        this.addContact = false;
        //this.this.contactId = '';
        // this.isRelationshipLoad = false;
        //this.recordId = '';
        //this.fetchAccountDetails();
    }


    fetchPicklistValues() {
        //console.log('default currentAccountContactField=' + this.currentAccountContactField.roles.fieldValue);
        retrieveMultipicklistValues({
            objectName: 'AccountContactRelation',
            fieldName: 'roles',
            accountId: this.accountId
        })
            .then((result) => {
                this.options = [];

                this.dataList = result.picklistValues;

                var len = 0;

                for (var dataKey in this.dataList) {
                    len++;
                    let checkedVar = false;
                    let picklistClass = this.dropdownList;
                    /*
                    if(this.fieldValue != undefined){
                        if(this.fieldValue.includes(dataKey)) {
                            checkedVar = true;
                            picklistClass = 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small slds-media_center slds-is-selected';
                        }    
                    }*/

                    this.options = [...this.options, { value: dataKey, label: this.dataList[dataKey] }];
                }
                if (this.selectedroles != null) {

                    for (var sd in this.selectedroles) {
                        console.log('sd***=' + sd);
                        console.log('this.selectedroles[sd]***=' + this.selectedroles[sd]);

                        if (this.dataList[this.selectedroles[sd]] == null) {
                            if (this.selectedroles[sd] == 'Principal' && this.formFunction == 'Update') {
                                this.checkboxdisabled = true;
                            }
                            this.options = [{ value: this.selectedroles[sd], label: this.selectedroles[sd] }, ...this.options];
                        }
                    }
                }
                //console.log('***** length :'+len);

                //if(len == 0) {
                //     this.isRelationshipEditable = true;
                //  }

                this.error = undefined;
            }).catch((error) => {
                console.log(error);
                this.options = undefined;
            });
    }




    handleRoleChange(e) {
        this.selectedrolevalue = e.detail.value.join(';');
        this.currentAccountContactField.Roles.fieldValue = this.selectedrolevalue;
    }

}