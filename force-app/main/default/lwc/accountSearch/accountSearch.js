import { LightningElement, track, wire } from 'lwc';
import findAccounts from '@salesforce/apex/AccountController.findAccounts';

import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';

/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;

export default class AccountSearch extends LightningElement {
    @wire(CurrentPageReference) pageRef;

    @track accounts;
    @track error;
    @track selectedId;
    @track selectedAccount;
    @track showList;

    handleKeyChange(event) {
        // Debouncing this method: Do not actually invoke the Apex call as long as this function is
        // being called within a delay of DELAY. This is to avoid a very large number of Apex method calls.
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            findAccounts({ searchKey })
                .then(result => {
                    this.accounts = result;
                    this.error = undefined;
                    this.showList = true;
                })
                .catch(error => {
                    this.error = error;
                    this.accounts = undefined;
                    this.showList = false;
                });
        }, DELAY);
    }

    handleSelect(event){
        //console.log('>>>>>',event);
        this.selectedId = event.detail.value;
        fireEvent(this.pageRef, 'accountSelected', this.selectedId);
        this.showList = false;

        // console.log('>>>>> event.detail.value', event.detail.value);
        // this.selectedAccount = event.detail.value; //detail.value is a json object for account
        // fireEvent(this.pageRef, 'accountSelected', this.selectedAccount);

    }


    

    // FireEvent_AccountSelected() {
    //     fireEvent(this.pageRef, 'accountSelected', this.selectedId);
    // }

    
    
}