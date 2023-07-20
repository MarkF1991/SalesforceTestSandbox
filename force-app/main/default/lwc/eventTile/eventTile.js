import { LightningElement, api, track } from 'lwc';
import upsertEventRecord from '@salesforce/apex/ActivityController.upsertEventRecord';

//----------------------- Custom Label --------------------------------
import SchoolVisitDriver from '@salesforce/label/c.SchoolVisitDriver';


/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;
export default class sfEventTile extends LightningElement {
    label = {
        SchoolVisitDriver,
    }; 

    @api sfevent;
    @track description;
    @track driver;
    @track notes;
    @track selectedValue = '';

    get eventContact() {
        return (this.sfevent.Who ? this.sfevent.Who.Name : '' );
    }
    


    connectedCallback(){
        this.description = this.sfevent.Description;
        this.driver = this.sfevent.Driver__c;
        this.notes = this.sfevent.Notes__c;
    }

    handleClick(event) {
        // 1. Prevent default behavior of anchor tag click which is to navigate to the href url
        event.preventDefault();
        // 2. Read about event best practices at http://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.events_best_practices
        const selectEvent = new CustomEvent('sfeventselect', {
            bubbles: true,
            detail: {value:this.sfevent.Id} 
        });
        // 3. Fire the custom event
        this.dispatchEvent(selectEvent);
    }

    @track editMode = false;
    @track showMore = false;

    handleShowMoreClick() {
        this.showMore = !this.showMore;
    }
    handleUpdateClick() {
        this.editMode = !this.editMode;
    }
   
    handleDescriptionChange(event) {
        this.description = event.target.value;
    }

    handleDriverChange(event) {
        this.driver = event.target.value;
    }

    handleNotesChange(event) {
        this.notes = event.target.value;
    }


    //----------- Driver -------------------
    //setup options for driver
    get driverOptions() {
        const options = [];
        const array = this.label.SchoolVisitDriver.split(';');
        array.forEach(prepareOptions);

        return options;

        //loop through this.contacts to prepare an array of options {label, value} for combo box or radio group
        function prepareOptions(label) {
            var newItem = {
                "label": label,
                "value": label
            };
            options.push(newItem);
        }
    }
    // handle the selected value
    handleOptionChange(event) {
        this.selectedValue = event.detail.value;
        this.driver = this.selectedValue;
    }

    get isOther(){
        return (this.selectedValue === 'other');
    }
    //----------- Driver -------------------

    handleCancel(){
        this.editMode = false;
    }
    handleSave(){
        //build array dynamically
        const myArray = {};
        myArray['id'] = this.sfevent.Id;
        myArray['description'] = this.description;
        myArray['driver'] = this.driver;
        myArray['notes'] = this.notes;

        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            upsertEventRecord({ fieldsMap: myArray })
                .then(result => {
                    console.log('result from upsertEventRecord() = ', result);
                    this.sfevent = result;
                    this.error = undefined;
                })
                .catch(error => {
                    this.error = error;
                    this.sfevent = undefined;
                });
        }, DELAY);
        
        this.editMode = false;   
    }
    
}