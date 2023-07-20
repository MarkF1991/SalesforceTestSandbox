import { LightningElement, api } from 'lwc';
export default class RowBar extends LightningElement {

    @api total;
    @api sub;
    @api max;
    @api category;
  
    get barFill() {
        var percentage = 100;

        if( Number(this.total) > 0){
            if (typeof(Number(this.sub))==='number'){
                percentage = (this.sub / this.total * 100);
            }
        }
        return `width: ${percentage}%`;
    }

    get barWidth() {
        var percentage = 0;
        if( Number(this.max) > 0){
            if (typeof(Number(this.total))==='number'){
                percentage = (this.total / this.max * 100);
            }
        }
        return `width: ${percentage}%`;
    }
    
    get cssBarValue(){
        return `slds-progress-bar__value ${this.category === null ? '' : this.category}`;
    }

    get cssBar(){
        return `slds-progress-bar slds-align_center ${this.category === null ? '' : this.category}`;
    }
}