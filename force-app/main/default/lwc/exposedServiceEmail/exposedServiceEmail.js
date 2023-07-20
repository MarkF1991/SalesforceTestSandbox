import { LightningElement, track, api} from 'lwc';

import SEND_CAMPAIGN_EMAIL from '@salesforce/apex/ExposedServiceController.sendCampaignEmail';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'; // import toast message event .

/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;

export default class exposedServiceEmail extends LightningElement {
    @track response = '';
    @track starturl = ''; //url parameter - start url
    @track isLoading = false;

    @track showMessage = false; //temporary solution until Winter 20 arrives 13 Oct 2019
    @track message1 = '';
    @track message2 = '';

    @api recordId = '';
 
    handleSubmit(){
        
        this.isLoading = true; //start spinner
        console.log('recordId', this.recordId);
        console.log('##$$@@#@#$recordId:', '$recordId');
        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            SEND_CAMPAIGN_EMAIL({campaignId: this.recordId, mode:'todo'})
                .then(result => {
                    this.response = JSON.parse(result.response); //result is json string
                    this.error = undefined;

                    if (this.response.statusCode === 200){
                        console.log(this.response.statusCode);
                         this.dispatchEvent(
                            new ShowToastEvent({
                                title: this.title,
                                message: 'Email has sent successfully!',
                                variant: 'success'
                            })      
                        );
                    }
                    if (this.response.statusCode >= 400){
                        console.log(this.response.statusCode);
                        this.dispatchEvent(
                           new ShowToastEvent({
                               title: 'Send Email Failed ',
                               message: this.response.message,
                               variant: 'error'
                           })
                       );
                    }
                    this.isLoading = false; //stop spinner: must be inside .then()
                })
                .catch(error => {
                    console.log('handleSubmit() error(): ' , error);
                    this.error = error;
                    this.response = undefined;
                });
        }, DELAY);
    }

    get output(){
        return 'the outcome is : ' + JSON.stringify(this.response);
    }
    

}