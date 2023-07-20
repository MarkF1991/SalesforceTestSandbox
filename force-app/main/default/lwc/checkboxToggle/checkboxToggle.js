import { LightningElement, api, track } from 'lwc';


export default class CheckboxToggle extends LightningElement {
    @api checkboxLabel;
    @api checkboxOnLabel;
    @api checkboxOffLabel;
    @api checkboxDisabled = false;
    @api checkboxChecked = false;
    @api requiredShowModal = false;
    @api confirmationMessage1;
    @api confirmationMessage2;

    
    //@api recordId;
    @api responseActionName;

    @track modal = {header: '',
    id: '',
    elements: [], 
    mode: '', 
    cancelButtonName: '',
    submitButtonName: '',
    confirmationMessage: '',
    confirmationMessage2: ''
    };

    @track checkbox_toggle1 = false; //school reporting


    get checkbox_toggle1_checked(){
        return (this.checkboxChecked? 'checked' : '');
    }
        
    get checkbox_toggle1_disabled(){
        return this.checkboxDisabled;
    }
    
    handleCheckboxToggle1Change(event) {
        //this.checkbox_toggle1 = event.target.checked;
        this.checkboxChecked = event.target.checked;
        if (this.requiredShowModal){
            this.modal.header = this.checkboxLabel;
            this.modal.id = ''; //this.recordId; //not required here.
            this.modal.elements = [];
            this.modal.mode = 'ToProceed';
            this.modal.cancelButtonName = 'No';
            this.modal.submitButtonName = 'Yes';
            //this.modal.confirmationMessage1 = 'Do you want to proceed with updating ' + this.checkboxLabel + '?';
            this.modal.confirmationMessage = this.confirmationMessage1;
            this.modal.confirmationMessage2 = this.confirmationMessage2;
                       
            const modal = this.template.querySelector('c-modal');
            modal.show(); 
        } else {
            this.handleProceed();
        }
    }

    //when user click on Yes in modal
    handleProceed(event){
        this.handleDispatchEvent(event, this.responseActionName);
    }

    //when user clicked on No on modal or closedialog modal
    handleCancel(){
        //this.checkbox_toggle1 = !this.checkbox_toggle1; //reverse the previously selected value.
        this.checkboxChecked = !this.checkboxChecked;
    }

    handleDispatchEvent(event, customEventName){
        //prepare to return json object as event.value : onmodalsaved
        let json = {'checkboxChecked': this.checkboxChecked}; 

        // 1. Prevent default behavior of anchor tag click which is to navigate to the href url
        event.preventDefault();
        // 2. Read about event best practices at http://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.events_best_practices
        const selectEvent = new CustomEvent(customEventName, {
            bubbles: true,
            detail: {value:json} 
        });
        // 3. Fire the custom event
        this.dispatchEvent(selectEvent);
    }

   
    
}