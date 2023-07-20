import { LightningElement, api, track } from 'lwc';
import { getIdFromTarget } from "c/utilitiesFunction";


export default class Modal extends LightningElement {
    @api id;
    @api submitButtonName = 'Save';
    @api cancelButtonName = 'Cancel';
    @api confirmationMessage = '';
    @api confirmationMessage2 = '';
    @api mode; //edit or create or confirmToDelete
    @track disabled = false;

    //--------------------- header ------------------------------
    @api
    set header(value) {
        this.hasHeaderString = value !== '';
        this._headerPrivate = value;
    }
    get header() {
        return this._headerPrivate;
    }

    @track hasHeaderString = false;
    _headerPrivate;
    //--------------------- header ------------------------------



    //--------------------- elements ------------------------------
    //@api elements is read only
    //@api elements = [];
    // @api elements = 
    //     [
    //             {id: '1', label: 'title', value:'SLDS Grid', type:'text'},
    //             {id: '2', label: 'url', value:'https://www.lightningdesignsystem.com/utilities/grid/#Content-centered-2', type:'url'},
    //             {id: '3', label: 'description', value:'The SLDS grid system provides a flexible, mobile-first, device-agnostic layout system. It has features to control alignment, order, flow, and gutters.', type:'text'},
    //     ];
    @track editable; //to track user's changes to the json object in handleInputChange
    
    _elements;
    @api
    set elements(value) {
        this._elements = value;
        this.editable = JSON.parse(JSON.stringify(value)); 
    }
    get elements() {
        return this._elements;
    }
    
    handleInputChange(event){
        //temporary track user changes 
        let itemId = getIdFromTarget(event.target.id);
        let data = this.editable.find((item) => item.id === itemId);
        data.value = event.target.value;
        //this.test = data;
    }

    IsAllValid(){
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputFields) => {
                inputFields.reportValidity();
                return validSoFar && inputFields.checkValidity();
            }, true);
        return allValid;
    }
    //--------------------- elements ------------------------------
    
    

    //--------------------- show / hide modal ------------------------------
    @track showModal = false;
    @api show() {
        this.showModal = true;
        //this.editable = JSON.parse(JSON.stringify(this.elements)); 
        //this.editable = this.elements;
    }

    @api hide() {
        this.showModal = false;
    }

    // handleDialogClose() {
    //     //Let parent know that dialog is closed (mainly by that cross button) so it can set proper variables if needed
    //     const closedialog = new CustomEvent('closedialog');
    //     this.dispatchEvent(closedialog);
    //     this.hide();
    // }
    handleDialogClose(event) {
        //Let parent know that dialog is closed (mainly by that cross button) so it can set proper variables if needed
        this.handleDispatchEvent(event, 'modaldialogclosed');
        this.handleCloseModal();
    }
  
    handleCloseModal() {
        this.showModal = false;
    }
    
    handleSubmitModal(event){
        if(this.mode === 'confirmToDelete'){
            this.handleConfirmDeleteModal(event);
        } else if(this.mode === 'confirmToProceed'){
            this.handleConfirmToProceedModal(event);
        } else {
            if(this.IsAllValid()){
                if(this.submitButtonName === 'Save'){
                    this.handleSaveModal(event);
                }
                let modalResponse = `modalconfirmed${this.mode}`.toLowerCase();
                console.log('modalResponse', modalResponse);
                this.handleDispatchEvent(event, modalResponse);
                this.handleCloseModal();
            }
        }
    }

    handleSaveModal(event){
        this.handleDispatchEvent(event, 'modalsaved');
        this.handleCloseModal();
    }

    handleConfirmDeleteModal(event) {
        this.handleDispatchEvent(event, 'modalconfirmtodelete');
        this.handleCloseModal();
    }

    handleConfirmToProceedModal(event) {
        this.handleDispatchEvent(event, 'modalconfirmtoproceed');
        this.handleCloseModal();
    }

    handleCancelModal(event) {
        // if(this.mode === 'create'){
        //     this.handleDispatchEvent(event, 'modalcanceledcreate');
        // }
        let modalResponse = `modalcanceled${this.mode}`.toLowerCase();
        this.handleDispatchEvent(event, modalResponse);
        this.handleCloseModal();
    }
   

    handleDispatchEvent(event, customEventName){
        //prepare to return json object as event.value : onmodalsaved
        let json = {'id': getIdFromTarget(this.id)}; //for some reason, the id was automatically appened with "-number"
        for(var i = 0, l = this.editable.length; i < l; i++) {
            json[this.editable[i].label] = this.editable[i].value;
        }

        this.test = json;

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
    //--------------------- show / hide modal ------------------------------

    @track test;
    get output(){
        return JSON.stringify(this.test);
    }

    get jsonelements(){
        return JSON.stringify(this.elements);
    }

    get jsoneditable(){
        return JSON.stringify(this.editable);
    }

    

    //--------------------- show / hide confirmation message ------------------------------
    get isConfirmationMode(){
        return (this.confirmationMessage.length > 0);
    }


   

}