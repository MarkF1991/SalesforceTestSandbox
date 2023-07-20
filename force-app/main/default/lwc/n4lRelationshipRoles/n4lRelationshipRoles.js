import { LightningElement,api,track } from 'lwc';

import retrieveBusinessRoles from '@salesforce/apex/N4LDataTableScreen.retrieveBusinessRoles';
import retrieveOutageNotif from '@salesforce/apex/N4LDataTableScreen.retrieveOutageNotif';

export default class N4lRelationshipRoles extends LightningElement {

    @api recordId;
    @api relatedObjectApiName;

    @track missingMessage;
    @track missingOutageNotif;

    connectedCallback() {
        console.log('#### '+ this.recordId);

        this.fetchBusinessRoles();
        this.checkOutageNotification();
    }

    fetchBusinessRoles() {
        retrieveBusinessRoles({
            recordId : this.recordId
        })
        .then((result)=>{

            let lowerCaseReleatedObject = this.relatedObjectApiName.charAt(0).toLowerCase() + this.relatedObjectApiName.slice(1);

            if(result.length>0) {
                if(result.length == 1) {
                    this.missingMessage = 'Active relationship role "'+result.join()+'" is missing for this '+lowerCaseReleatedObject;
                } else {
                    this.missingMessage = 'Active relationship roles "'+result.join(', ')+'" are missing for this '+lowerCaseReleatedObject;
                }
            }
        }).catch((error) => {
            console.log(error);
        });
    }

    checkOutageNotification() {
        retrieveOutageNotif({
            recordId : this.recordId
        })
        .then((result)=>{
            this.missingOutageNotif = result;
        }).catch((error) => {
            console.log(error);
        });
    }
}