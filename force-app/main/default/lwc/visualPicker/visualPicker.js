import { LightningElement, api, track } from 'lwc';

export default class VisualPicker extends LightningElement {
   @api options;
   @track showCustomDateRangePicker = false;

   @track customDateFrom = null;
   @track customDateTo = null;
   @api selectedOption;

   get toDate() {
      if(this.options) {
         const opt = this.options.find((o) => o.id === 'custom-date-range');
         if(opt) {
            return opt.end;
         }
      }
      return null;
   }

   get fromDate() {
      if(this.options) {
         const opt = this.options.find((o) => o.id === 'custom-date-range');
         if(opt) {
            return opt.start;
         }
      }
      return null;
   }

   handleValuePickerSelected(event) {
      let selected = event.detail.value;
      if(selected.id === 'custom-date-range') {
         this.showCustomDateRangePicker = true;
      } else {
         this.selectedOption = selected; //detail.value is a json object for option
      }
   }

   // eslint-disable-next-line no-unused-vars
   handleCustomDateRangeUpdated(event) {
      let req = event.detail;
      this.customDateTo = req.to;
      this.customDateFrom = req.from;
   }

   handleClickSave(event) {
      // Prevents the anchor element from navigating to a URL.
      event.preventDefault();

      if(this.showCustomDateRangePicker) {
         if(this.customDateTo && this.customDateFrom) {
            let option = this.options.find((op) => op.id === 'custom-date-range');
            if(option) {
               this.selectedOption = {
                  start: this.customDateFrom, //Start of last week in UTC
                  end:  this.customDateTo,//End of last week in UTC
                  description: option.description,
                  id: option.id,
                  value: option.value,
                  label: option.label,
                  type: option.type,
                  isChecked: true
               }
            } else {
               // eslint-disable-next-line no-console
               console.log('could not find custom-date-range');
            }
            // this.selectedOption = {
            //    start: this.customDateFrom, //Start of last week in UTC
            //    end:  this.customDateTo,//End of last week in UTC
            //    description: "Custom",
            //    isChecked: true
            // }
            //this.customDateRangePickerData.isChecked = true;
         }
         this.showCustomDateRangePicker = false;
      }

      // Creates the event with the goto navigation target
      const returnEvent = new CustomEvent('saved', {detail: {value: this.selectedOption} });
      // Dispatches the event.
      this.dispatchEvent(returnEvent);
   }
   
   handleClickCancel(event) {
      // Prevents the anchor element from navigating to a URL.
      event.preventDefault();
      if(this.showCustomDateRangePicker) {
         this.showCustomDateRangePicker = false;
         this.customDateTo = null;
         this.customDateFrom = null;
      } else {     
         // Creates the event with the goto navigation target
         const returnEvent = new CustomEvent('cancelled', {detail: {value:null} });
         // Dispatches the event.
         this.dispatchEvent(returnEvent);
      }
   }
}