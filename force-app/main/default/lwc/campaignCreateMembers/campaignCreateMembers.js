import { LightningElement, track, api, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'; 
import CREATE_CAMPAIGN_Members from '@salesforce/apex/CampaignController.createCampaignMembers'; 
/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;
export default class CampaignCreateMembers extends LightningElement {
    @track response = '';
    @track starturl = ''; //url parameter - start url
    @track isLoading = false;

    @track showMessage = false; //temporary solution until Winter 20 arrives 13 Oct 2019
    @track message1 = '';
    @track message2 = '';
    @track excludeOpt = 'false';
    @api recordId = '';
    
    handleExcludeOptout(event){
        this.excludeOpt = event.target.checked ? 'true' : 'false';
        console.log('checkbox value ===>'+this.excludeOpt);
    }
    handleCreateCampaignMembers(){
        
        this.isLoading = true; //start spinner
        console.log('recordId', this.recordId);

        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            CREATE_CAMPAIGN_Members({campaignId: this.recordId,excludeOptOut: this.excludeOpt})
            .then(result => {
                this.response = JSON.parse(result.response); //result is json string
                this.error = undefined;
                if (this.response.statusCode === 200){
                     console.log(this.response.statusCode);
                     console.log('@@##!!@#:',this.response);
                     this.dispatchEvent(
                        new ShowToastEvent({
                            title: this.title,
                            message: 'Campaign Members have created successfully!',
                            variant: 'success'
                        })
        
                    );
               
                }
                if (this.response.statusCode === 400){
                     console.log(this.response.statusCode);
                     console.log('@@##!!@#:',this.response);
                     this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Campaign Member Creation Failed ',
                            message: this.response.message,
                            variant: 'error'
                        })
                    );
                
                }
                if (this.response.statusCode === 404){
                    console.log(this.response.statusCode);
                    console.log('@@##!!@#:',this.response);
                    this.dispatchEvent(
                       new ShowToastEvent({
                           title: 'There is not selected contact ',
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
}