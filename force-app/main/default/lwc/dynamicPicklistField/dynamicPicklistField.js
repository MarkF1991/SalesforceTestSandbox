import { LightningElement, api, wire, track } from 'lwc';
//Import the named import updateRecord
import { updateRecord } from "lightning/uiRecordApi";
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEmailTemplates from '@salesforce/apex/dynamicFieldController.getEmailTemplate';
import EmailTemplatesNameFIELD from '@salesforce/apex/dynamicFieldController.Email_Template_Name';
import getCampaign from '@salesforce/apex/dynamicFieldController.Update_Email_Template';
import EMAILTEMPLATENAME from '@salesforce/schema/Campaign.Email_Template_Name__c';
import CAMPAIGNID from '@salesforce/schema/Campaign.Id';

export default class DynamicPicklistField extends LightningElement {
  //If I need to update a record then I should have access
  // to the recordId(make sure you use the adaptor @api).    
  @api recordId;
  
    @track clickedEmailTemplate;
    @track allEmailTemplates;
    @track selectEmailTemplate;
    @track defaultEmailName;
    @track showPicklist = false; // show button by default

    @wire (EmailTemplatesNameFIELD, {campaignId: '$recordId'}) 
    emailName({error, data}){
        if(data){
            this.defaultEmailName = data;
            this.error = undefined;
        }else{
            this.error = error;
            this.contacts = undefined;
        }
    }

    @wire (getCampaign, {campaignId: '$recordId'}) 
    campaign({error, data}){
        if(data){
            if(data.RecordType.Name === "Sending generic email") {    
                this.showPicklist = true;
            }
        }else{
            this.error = error;
            this.contacts = undefined;
        }
    }

    @wire(getEmailTemplates, {})
    wiredEmailTemplates({ error, data }) {
        if (data) {
            try {
                this.allEmailTemplates = data; 
                let options = [];
                 
                for (var key in data) {
                    // Here key will have index of list of records starting from 0,1,2,....
                    options.push({ label: data[key].Name, value: data[key].DeveloperName });
 
                    // Here Name and Id are fields from sObject list.
                }
                this.selectEmailTemplate = options;
                console.log('>>>>>>>>@@@@@@options'+JSON.stringify(options));
            } catch (error) {
                console.error('check error here', error);
            }
        } else if (error) {
            console.error('check error here', error);
        }
 
    }
    

    handleChange(event) {
        this.clickedEmailTemplate = event.detail.value;

        // Create the recordInput object
        const fields = {};
        fields[CAMPAIGNID.fieldApiName] = this.recordId;
        fields[EMAILTEMPLATENAME.fieldApiName] = this.clickedEmailTemplate;
        const recordInput = { fields };
        console.log('>>>>>>>>@@@@@@recordInput'+JSON.stringify(recordInput));
        // Update the records
   updateRecord(recordInput)
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Email Template Updated',
                            variant: 'success'
                        })
                    );
                    // Display fresh data in the form
                    return refreshApex(this.campaign);
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating record',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
            }
            
}