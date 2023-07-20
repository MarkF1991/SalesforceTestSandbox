import { LightningElement, api, track, wire } from 'lwc';

export default class DatatablePicklist extends LightningElement {

    // Input values ot the component
    @api value;
    @api context;
    @api options;
    @api fieldName;

    @track errors;

    handleChange(event) {

        this.value = event.target.value;

        // Build the data object to pass
        let data = {
            Id: this.context
        }
        data[this.fieldName] = this.value;

        // fire event to send context and selected value to the data table
        this.dispatchEvent(new CustomEvent('picklistchange', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: data
            }
        }));
    }

    get optionsWithDefault() {

        let optionsDefaulted = [];

        if (this.options) {
            // Iterate over each value to determine the current value
            this.options.forEach(option => {
                let newOption = Object.assign({}, option);
                if ((!this.value && !newOption.value) || newOption.value == this.value) {
                    newOption.isSelected = true;
                }
                optionsDefaulted.push(newOption);
            });
        }
        return optionsDefaulted;
    }
}