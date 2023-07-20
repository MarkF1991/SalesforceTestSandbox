import { LightningElement, api} from 'lwc';


export default class TaskTile extends LightningElement {
    @api task;

    handleClick(event) {
        // 1. Prevent default behavior of anchor tag click which is to navigate to the href url
        event.preventDefault();
        // 2. Read about event best practices at http://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.events_best_practices
        const selectEvent = new CustomEvent('taskselect', {
            bubbles: true,
            detail: {value:this.task.Id} 
        });
        // 3. Fire the custom event
        this.dispatchEvent(selectEvent);
    }

}