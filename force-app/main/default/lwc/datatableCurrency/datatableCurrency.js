import { LightningElement, api } from 'lwc';

export default class DatatableCurrency extends LightningElement {

    @api value;

    get currencyClassName() {

        let className = 'slds-text-title_bold ';

        if (this.value > 0) {
            className += 'slds-text-color_success';
        }
        else if (this.value < 0) {
            className += 'slds-text-color_error';
        }
        return className;
    }
}