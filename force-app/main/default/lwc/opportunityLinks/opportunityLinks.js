/* reference 
*  https://github.com/trailheadapps/lwc-recipes/blob/master/force-app/main/default/lwc/ldsDeleteRecord/ldsDeleteRecord.js
*  https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.apex
*/
import { LightningElement, api, track, wire } from 'lwc';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, updateRecord  } from 'lightning/uiRecordApi';


import ID_FIELD from '@salesforce/schema/Opportunity.Id';
import LINKS_FIELD from '@salesforce/schema/Opportunity.Links__c';

const FIELDS = [
    ID_FIELD, LINKS_FIELD
];

//export default class TaskList extends LightningElement {
export default class LinkList extends LightningElement{
   // Flexipage provides recordId and objectApiName
    @api recordId;
    @track record;
    @track error;
    @api title = 'Opportunity Links'
    @track isLoading = true; //start spinner

    @track links = [];
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.record = data;
            this.links = this.jsonParseLinks(this.record.fields.Links__c.value);
            this.error = undefined;
            this.isLoading = false; //start spinner
        } else if (error) {
            this.error = error;
            this.record = undefined;
            this.links = [];
            this.isLoading = false; //start spinner
            console.log('in opportunityLink.js ERROR!!! this.links:', this.links);
        }
    }


    
    jsonParseLinks(jsonString){
        if(!jsonString){ jsonString = '[]'}//to handle empty Links__c in existing Opportunity records
        let jsonobject = [];
        try {
            jsonobject = JSON.parse(jsonString);
        }
        catch (e) {
            jsonobject = [];
        }
        return jsonobject;
       
    }
   

    // connectedCallback(){
    //     this.links = [
    //         {
    //             id:"os3te",
    //             title: 'The SLDS grid system',
    //             description: 'The SLDS grid system provides a flexible, mobile-first, device-agnostic layout system. It has features to control alignment, order, flow, and gutters.',
    //             url: 'https://www.lightningdesignsystem.com/utilities/grid/#Content-centered-2',
    //         },
    //         {
    //             id:"v2n90",
    //             title: 'SLDS Layout',
    //             description: 'Layout utility classes will help you to achieve layouts found within the Salesforce Platform.',
    //             url: 'https://www.lightningdesignsystem.com/utilities/layout/',
    //         },
    //         {
    //             id:"xexbl",
    //             title: 'SLDS Text',
    //             description: 'For consistent typography throughout the application, we created text helper classes for headings and body text.',
    //             url: 'https://www.lightningdesignsystem.com/utilities/text/',

    //         },
    //     ];
    // }
//--------------------- links ------------------------------
// @track editable;
// _links;
// @api
// set links(value) {
//     this._links = value;
//     this.editable = JSON.parse(JSON.stringify(value)); 
// }
// get links() {
//     return this._links;
// }
//--------------------- links ------------------------------


disconnectedCallback() {
    // unsubscribe from AccountSelected event
    unregisterAllListeners(this);
}


handleNew(){
    let newid = Math.random().toString(36).substr(2, 5);
    // console.log('in opportunityLink.js, newid is:', newid);
    //let newid = 'abc99';
    let newlink = {
        'id': newid,
        'title': '',
        'description': '',
        'url': ''
    };
    // console.log('in opportunityLink.js, newlink is:', JSON.stringify(newlink));

    this.links.push(newlink); //add newlink to array so that linkList LWC can create a new linkTile LWC element.
    // console.log('in opportunityLinks.js after push(newlink) this.links = ', JSON.stringify(this.links));
    //this.test = 'in opportunityLinks.js after push(newlink) this.links = ' + JSON.stringify(this.links);

    const querySelectorElement = 'c-link-tile[data-id="' + newid + '"]';
    // console.log('in opportunityLink.js, querySelectorElement is:', querySelectorElement);
    //this.test += '   |    const querySelectorElement: ' + querySelectorElement;

    const linkList = this.template.querySelector('c-link-list');
    // console.log('in opportunityLink.js, const linkList =this.template.querySelector("c-link-list") is:', JSON.stringify(linkList));
    //this.test += '   |    const linkList: ' + JSON.stringify(linkList);

    // console.log('in opportunityLink.js, STARTED executed linkList.links = this.links;');
    linkList.links = this.links; //must explicitly update the @track _links in child component linkList.js
    // console.log('in opportunityLink.js, ENDED executed linkList.links = this.links;');

    // console.log('in opportunityLink.js, STARTED linkList.handleShowLinkTileModal(querySelectorElement);');
    linkList.handleShowLinkTileModal(querySelectorElement);
    // console.log('in opportunityLink.js, ENDED linkList.handleShowLinkTileModal(querySelectorElement);');

}

handleLinksSaved(event){
    //get json object from Modal updated link
    const json = event.detail.value;
    //this.links.push(json);
    let linkIndex = this.links.findIndex( item => item.id === json.id ); //find the index of json object based on the same id

    this.links[linkIndex] = json;//update an item in array: links

    this.updateOpportunity();//update record
}


handleCreateLinksCanceled(event){
    this.removeLink(event);
}

handleLinksDeleted(event){
    this.removeLink(event);
    this.updateOpportunity();//update record
}

removeLink(event){
    //get json object from Modal updated link
    const json = event.detail.value;
    // this.test += '           |           const json = event.detail.value: ' + JSON.stringify(json);

    let linkIndex = this.links.findIndex( item => item.id === json.id ); //find the index of json object based on the same id
    // this.test += '           |           let linkIndex: ' + linkIndex;
    this.links.splice(linkIndex,1); //remove 1 item at this index
    // this.test += '           |            this.links.slice(linkIndex): ' + JSON.stringify(this.links);
}

@track test;
get output(){
return this.test;
}

updateOpportunity() {
        // Create the recordInput object
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[LINKS_FIELD.fieldApiName] = JSON.stringify(this.links);
        

        const recordInput = { fields };
        this.isLoading = true; //start spinner
        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.title,
                        message: 'Successfully updated',
                        variant: 'success'
                    })
                );
                this.isLoading = false; //stop spinner
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.message,
                        variant: 'error'
                    })
                );
                this.isLoading = false; //stop spinner
            });
        }
    






}