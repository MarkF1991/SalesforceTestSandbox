import { LightningElement, track, api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'; // import toast message event .
import GET_CAMPAIGN_ACCOUNTS from '@salesforce/apex/CampaignController.getCampaignAccounts';

/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;

export default class CampaignGetAccounts extends LightningElement {
    @track response = '';
    @track isLoading = false;

    @track input = '';


    @api recordId = '';
    @api title = '';

    handleInputChange(event) {
        this.input = event.target.value;
    }

    handleSetAccountsModal(){
        
        this.isLoading = true; //start spinner
        console.log('recordId', this.recordId);
        
        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            GET_CAMPAIGN_ACCOUNTS({campaignId: this.recordId, input: this.input})
            .then(result => {
                this.response = JSON.parse(result.response); //result is json string
                this.error = undefined;
                if (this.response.statusCode === 200){
                     console.log(this.response.statusCode);
                     console.log('@@##!!@#:',this.response);
                     this.dispatchEvent(
                        new ShowToastEvent({
                            title: this.title,
                            message: 'Campaign Accounts has created successfully!',
                            variant: 'success'
                        })
        
                    );
               
                }
                if (this.response.statusCode >= 400){
                     console.log(this.response.statusCode);
                     console.log('@@##!!@#:',this.response);
                     this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Account Creation Failed ',
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
                    console.log('handleSetAccountsModal() error(): ' , error);
                    this.error = error;
                    this.response = undefined;
                });
        }, DELAY);
    }

    get output(){
        return 'the outcome is : ' + JSON.stringify(this.response);
    }
    

}