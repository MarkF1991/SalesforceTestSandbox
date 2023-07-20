import { LightningElement, api, track } from 'lwc';
// import upsertEventRecord from '@salesforce/apex/ActivityController.upsertEventRecord';
/** The delay used when debouncing event handlers before invoking Apex. */
// const DELAY = 350;
export default class OpportunityTile extends LightningElement {
    

    @api opportunity;
    @track description;
    @track links;
    @track stageName;
    @track selectedValue = '';

       
    


    connectedCallback(){
        console.log('in OpportunityTile connectedCallback this.opportunity in string is: ', JSON.stringify(this.opportunity));
        this.description = this.opportunity.Description;
        console.log('in OpportunityTile (this.opportunity.Links__c) in string is: ', this.opportunity.Links__c);
        this.links = this.jsonParseLinks(this.opportunity.Links__c);
        console.log('in OpportunityTile this.links = this.jsonParseLinks(this.opportunity.Links__c) is: ', JSON.stringify(this.links));
        this.stageName = this.opportunity.StageName;
    }

    jsonParseLinks(jsonString){
        let jsonobject = [];
        try {
            jsonobject = JSON.parse(jsonString);
        }
        catch (e) {
            jsonobject = [];
        }
        return jsonobject;
    }

    handleClick(event) {
        // 1. Prevent default behavior of anchor tag click which is to navigate to the href url
        event.preventDefault();
        // 2. Read about event best practices at http://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.events_best_practices
        const selectEvent = new CustomEvent('opportunityselect', {
            bubbles: true,
            detail: {value:this.opportunity.Id} 
        });
        // 3. Fire the custom event
        this.dispatchEvent(selectEvent);
    }

    @track editMode = false;
    @track showMore = false;

    handleShowMoreClick() {
        this.showMore = !this.showMore;
    }
    
    //---------------------- commented out the edit and save part for future development ---------------------------
    // handleUpdateClick() {
    //     this.editMode = !this.editMode;
    // }
   
    // handleDescriptionChange(event) {
    //     this.description = event.target.value;
    // }

    // handleStageNameChange(event) {
    //     this.stageName = event.target.value;
    // }

    // handleCancel(){
    //     this.editMode = false;
    // }

    // handleSave(){
    //     //build array dynamically
    //     const myArray = {};
    //     myArray['id'] = this.opportunity.Id;
    //     myArray['description'] = this.description;
    //     myArray['links'] = this.links;
    //     myArray['stageName'] = this.stageName;

    //     window.clearTimeout(this.delayTimeout);
    //     // eslint-disable-next-line @lwc/lwc/no-async-operation
    //     this.delayTimeout = setTimeout(() => {
    //         upsertEventRecord({ fieldsMap: myArray })
    //             .then(result => {
    //                 console.log('result from upsertEventRecord() = ', result);
    //                 this.opportunity = result;
    //                 this.error = undefined;
    //             })
    //             .catch(error => {
    //                 this.error = error;
    //                 this.opportunity = undefined;
    //             });
    //     }, DELAY);
        
    //     this.editMode = false;   
    // }
    //---------------------- commented out the edit and save part for future development ---------------------------
    
}