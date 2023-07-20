import { LightningElement, api } from 'lwc';

export default class ContactVisualPickerItem extends LightningElement {
    @api object;
    @api disablePickerForNullUser = false;

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

    get propertyDisabled(){
        if (this.disablePickerForNullUser){
            if (this.object.userstring === 'null') return 'checked';

            let user = JSON.parse(this.object.userstring);
            return (user.IsActive ? '' : 'checked'); //disable picker item when user is inactive. Contract cannot have Owner as inactive user.
        }
        return '';
    }
}