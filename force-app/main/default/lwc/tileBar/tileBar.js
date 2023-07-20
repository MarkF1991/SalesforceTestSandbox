import { LightningElement, api, track } from 'lwc';
import { formatNumber, getReadableDuration } from 'c/utilitiesFunction';
import { getFieldDisplayValue } from 'lightning/uiRecordApi';
export default class TileBar extends LightningElement {

    @track display;
  
    

    @api object;
    // object = {  category:'blockedAttempts',
    //             type:'duration',            
    //             value:10,
    //             max:100,
    //             fillpercentage:100,
    //             widthpercentage:100
    //         };
    
    

    get value() {
        if(this.object === null){
            return 0;
        }

        if (this.object.type === 'count'){
            return formatNumber(this.object.value); //return count with comma separator
        } else if (this.object.type === 'data-size'){
            return this.object.value;
        } else if (this.object.type === 'duration'){
            return getReadableDuration(this.object.value); //return in format ("hh:mm:ss")
        }
        return this.object.value;
        
    }
            
    get barFill() {
        return `width: ${this.object === null ? '100' : this.object.fillpercentage}%`;
    }
    get barWidth() {
        var percentage = 0;
        if(this.object === null){
            return 'width: 100%';
        }


        if( Number(this.object.max) > 0){
            if (typeof(Number(this.object.value))==='number'){
                percentage = (this.object.value / this.object.max * 100);
                return `width: ${percentage}%`;
                
            }
        }
        
        if (percentage = 0){
            return `width: ${this.object.widthpercentage}%`;
        }
        
        
    }
    
    get cssBarValue(){
        return `slds-progress-bar__value ${this.object === null ? '' : this.object.category}`;
        
    }

    get cssBar(){
        return `slds-progress-bar slds-align_center slds-m-top_xx-small ${this.object === null ? '' : this.object.category}`;
    }
}