import { LightningElement, api } from 'lwc';

export default class filterItem extends LightningElement {
  @api object;

    get getTitle() {
        return 'Remove ' + this.object.description;
    }    

    handleClickFilterItem(event) {
      // Prevents the anchor element from navigating to a URL.
      event.preventDefault();

      // Creates the event with the goto navigation target
      const returnEvent = new CustomEvent('filterclick', {detail: {value:this.object} });

      // Dispatches the event.
      this.dispatchEvent(returnEvent);
   }     
}