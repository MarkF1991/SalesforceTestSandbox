import { LightningElement,track,api} from 'lwc';
import retrieveMultipicklistValues from '@salesforce/apex/N4LFormScreen.retrieveMultipicklistValues';
import Screen_RequiredField from '@salesforce/label/c.Screen_RequiredField';

export default class N4LMultipicklistScreen extends LightningElement {

    @api objectName;
    @api fieldName;
    @api fieldLabel;
    @api fieldHelpText;
    @api fieldValue;
    @api isRequired;
    @api isRelationshipEditable;
    @api accountId;

    @track options=[];
    @track error;
    @track dropdown = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track dataList;
    @track dropdownList = 'slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta';
    @track selectedValue = 'Select value';
    @track placeHolder;
    @track selectedListOfValues='';
    @track isPicklistRequired = false;

    label = {
        Screen_RequiredField
    };

    connectedCallback() {
        this.placeHolder = 'Select '+this.fieldLabel;

        if(this.fieldValue != undefined) {
            this.selectedListOfValues = this.fieldValue;
        } else {
            this.selectedListOfValues = '';
        }

        this.fetchPicklistValues();
    }
    
    @api
    processMyData(defaultPicklistValues) {
        this.selectedListOfValues = defaultPicklistValues;
        this.fieldValue = defaultPicklistValues;
        this.fetchPicklistValues();
    }

    get errorComplete() {
        return this.isRequired && (this.selectedListOfValues == '' || this.selectedListOfValues == null) ? true : false;
    }

    fetchPicklistValues() {
        console.log('*** Field Name: '+this.fieldName);
        retrieveMultipicklistValues({
            objectName : this.objectName,
            fieldName : this.fieldName,
            accountId : this.accountId
        })
        .then((result)=>{
            this.options = [];
            
            this.dataList = result.picklistValues;
            
            var len = 0;

            for(var dataKey in this.dataList) {
                len++;
                let checkedVar = false;
                let picklistClass = this.dropdownList;

                if(this.fieldValue != undefined){
                    if(this.fieldValue.includes(dataKey)) {
                        checkedVar = true;
                        picklistClass = 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small slds-media_center slds-is-selected';
                    }    
                }

                this.options = [...this.options, { value: dataKey, label: this.dataList[dataKey],isChecked:checkedVar,class:picklistClass}];
            }

            console.log('***** length :'+len);

            if(len == 0) {
                this.isRelationshipEditable = true;
            }

            this.error = undefined;
        }).catch((error) => {
            console.log(error);
            this.options = undefined;
        });
    }

    openDropdown(){
        this.dropdown =  'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open';  
    }

    closeDropDown(){
        this.dropdown =  'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    }

    selectOption(event){

        var isCheck = event.currentTarget.dataset.id;
        var label = event.currentTarget.dataset.name;
        var selectedListData=[];
        var selectedOption='';
        var allOptions = this.options;
        var count=0;

        for(let i=0;i<allOptions.length;i++){ 
            if(allOptions[i].value===label) { 
                if(isCheck==='true') { 
                    allOptions[i].isChecked = false;
                    allOptions[i].class = this.dropdownList;
                } else { 
                    allOptions[i].isChecked = true; 
                    allOptions[i].class = 'slds-media slds-listbox__option slds-listbox__option_plain slds-media_small slds-media_center slds-is-selected';
                }
            } 

            if(allOptions[i].isChecked) { 
                selectedListData.push(allOptions[i].value); 
                count++; 
            } 
        }
        
        this.options = allOptions;
        this.selectedValue = selectedOption;
        this.selectedListOfValues = selectedListData.join(";");

        // Creates the event with the data.
        const selectedEvent = new CustomEvent("roles", {
            detail: this.selectedListOfValues
        });
    
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }
	
    removeRecord(event){

        var value = event.detail.name;
        var removedOptions = this.options;
        var count = 0;
        var selectedListData=[];
        for(let i=0; i < removedOptions.length; i++){

            if(removedOptions[i].label === value){
            removedOptions[i].isChecked = false;
            removedOptions[i].class = this.dropdownList;
            }

            if(removedOptions[i].isChecked){
            selectedListData.push(removedOptions[i].label); 
            count++;
            }   
        }

        var selectedOption;
        
        if(count === 1){
            selectedOption = count+' Country Selected';
        }else if(count>1){
            selectedOption = count+' Roles Selected';
        }else if(count === 0){
            selectedOption = 'Select Roles';
            selectedListData = "";
        }
        
        this.selectedListOfValues = selectedListData;
        this.selectedValue = selectedOption;
        this.options = removedOptions;

    }

}