import { LightningElement, api } from 'lwc';

export default class AccountTile extends LightningElement {
    @api account;

    
    handleClick(event) {
        // 1. Prevent default behavior of anchor tag click which is to navigate to the href url
        event.preventDefault();
        // 2. Read about event best practices at http://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.events_best_practices
        const selectEvent = new CustomEvent('select', {
            detail: {value:this.account.Id} 
            //detail: {value:this.account} 
        });
        // 3. Fire the custom event
        this.dispatchEvent(selectEvent);
    }
    

    
}