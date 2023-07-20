import { LightningElement, api } from 'lwc';

export default class VisualPickerItem extends LightningElement {
   @api object;
  
  handleSelect() {
     const selectedEvent = new CustomEvent('selected', {detail: {value:this.object} });
      this.dispatchEvent(selectedEvent);
    }
   
   //https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/radio
   get propertyChecked(){
      var result = ''; //default to not checked
      if (this.object && this.object.isChecked){
         result = 'checked'; //manipulate <input> HTML property checked = 'checked'
      }
      return result;
   }
}