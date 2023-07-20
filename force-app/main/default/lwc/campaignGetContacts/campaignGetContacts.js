import { LightningElement, track, api, wire} from 'lwc';
import CREATE_CAMPAIGN_ACCOUNT_CONTACT from '@salesforce/apex/CampaignController.getCampaignAccountContacts';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'; // import toast message event .

/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;

export default class CampaignGetContacts extends LightningElement {
    @track response = '';
    @track starturl = ''; //url parameter - start url
    @track isLoading = false;

    @track showMessage = false; //temporary solution until Winter 20 arrives 13 Oct 2019
    @track message1 = '';
    @track message2 = '';

    @api recordId = '';
    
    handleCreateCampaignContacts(){
        
        this.isLoading = true; //start spinner
        console.log('recordId', this.recordId);

        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            CREATE_CAMPAIGN_ACCOUNT_CONTACT({campaignId: this.recordId})
            .then(result => {
                this.response = JSON.parse(result.response); //result is json string
                this.error = undefined;
                if (this.response.statusCode === 200){
                     console.log(this.response.statusCode);
                     console.log('@@##!!@#:',this.response);
                     this.dispatchEvent(
                        new ShowToastEvent({
                            title: this.title,
                            message: 'Campaign Account Members have created successfully!',
                            variant: 'success'
                        })
        
                    );
               
                }
                if (this.response.statusCode >= 400){
                     console.log(this.response.statusCode);
                     console.log('@@##!!@#:',this.response);
                     this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Contact Creation Failed ',
                            message: this.response.message,
                            variant: 'error'
                        })
                    );
                //     console.log('navigate to: ',  `${partialURL()}request-authorisation?m=request-error`);
                //     this.navigateToWebPage_toShowOnScreenMessage(`${partialURL()}request-authorisation?m=request-error`);
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
    

}