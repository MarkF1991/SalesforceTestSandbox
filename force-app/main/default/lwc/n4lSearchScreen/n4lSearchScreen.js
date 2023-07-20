import { LightningElement,api,track } from 'lwc';
import getResults from '@salesforce/apex/N4LFormScreen.getResults';
import getResultFromExistingSchool from '@salesforce/apex/N4LFormScreen.getResultFromExistingSchool';

export default class N4lSearchScreen extends LightningElement {
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

    @track txtclassname = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track iconFlag =  true;
    @track clearIconFlag = false;
    @track inputReadOnly = false;
    @track isContact = false;
    
    connectedCallback() {
        if(this.objectName == 'Contact') {
            this.isContact = true;
        }
    }

    searchField(event) {
        var currentText = event.target.value;
        this.searchProcess(currentText);
    }
    
    searchProcess(inputValue) {
        this.LoadingText = true;
        
        if(this.isShowAdd && this.replaceValue == 'existingSchool') {
            getResultFromExistingSchool({
                value: inputValue, accountId : this.accountId
            }).then(result =>{
                this.setSearchOptions(result);
            }).catch(error => {
                console.log('-------error-------------'+error);
                console.log(error);
            });
        } else {
            getResults({ ObjectName: this.objectName, fieldName: this.fieldName, 
                value: inputValue, accountId : this.accountId  })
            .then(result => {
                this.setSearchOptions(result);
            }).catch(error => {
                console.log('-------error-------------'+error);
                console.log(error);
            });
        }
    }

    setSearchOptions(searchRecs) {
        this.searchRecords= searchRecs;
        this.LoadingText = false;
        
        this.txtclassname =  'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open';

        if(this.selectRecordId != null && this.selectRecordId.length > 0) {
            this.iconFlag = false;
            this.clearIconFlag = true;
        } else {
            this.iconFlag = true;
            this.clearIconFlag = false;
        }
    }

    onAddNewContact(event) {
        this.txtclassname =  'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';

        // Creates the event with the data.
        const selectedEventFormScreen = new CustomEvent("addcontact", {
            detail: false
        });
    
        // Dispatches the event.
        this.dispatchEvent(selectedEventFormScreen);
    }

    setSelectedRecord(event) {
        var currentRecId = event.currentTarget.dataset.id;
        var selectName = event.currentTarget.dataset.name;
        this.txtclassname =  'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        this.iconFlag = false;
        this.clearIconFlag = true;
        this.selectRecordName = event.currentTarget.dataset.name;
        this.selectRecordId = currentRecId;
        this.inputReadOnly = true;
        const selectedEvent = new CustomEvent('selected', { detail: {selectName, currentRecId}, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);

        // Creates the event with the data.
        const selectedEventFormScreen = new CustomEvent("searchform", {
            detail: currentRecId
        });
    
        // Dispatches the event.
        this.dispatchEvent(selectedEventFormScreen);

        // Creates the event with the data.
        const disableContactFormScreen = new CustomEvent("addcontact", {
            detail: true
        });
    
        // Dispatches the event.
        this.dispatchEvent(disableContactFormScreen);
    }
    
    @api
    processSearch(defaultEmailValue) {
        this.selectRecordName = defaultEmailValue;
        this.searchProcess(defaultEmailValue);
    }

    resetData(event) {
        this.selectRecordName = "";
        this.selectRecordId = "";
        this.inputReadOnly = false;
        this.iconFlag = true;
        this.clearIconFlag = false;
       
    }
}