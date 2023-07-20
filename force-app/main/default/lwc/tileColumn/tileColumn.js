import { LightningElement, api } from 'lwc';

export default class TileRow extends LightningElement {
    @api object;
    object = {
        label:'NAME',
        count:'#USERS',
        bar1:{  
                label:'BROWSING TIME',
                unit:'(HH:MM:SS)'
            },
        bar2:{  
                label:'BANDWIDTH USAGE',
                unit:'(GB)'
            },
        bar3:{  
                label:'BLOCKED ATTEMPTS',
                unit:''
            }
      };
    
    get cssChipColumn(){
        return `slds-col ${this.object.bar2 === null ? 'slds-size_4-of-12' : 'slds-size_2-of-12'} slds-text-align_left slds-truncate`;
    }
    get cssCountColumn(){
        return `slds-col ${this.object.bar2 === null ? 'slds-size_2-of-12' : 'slds-size_1-of-12'} slds-text-align_center slds-truncate`;
    }
    get cssBarColumn(){
        return `slds-col ${this.object.bar2 === null ? 'slds-size_6-of-12' : 'slds-size_3-of-12'} slds-p-horizontal_medium`;
    }

    get showBar2(){
        return !(this.object.bar2 === null);
    }
    
    get showBar3(){
        return !(this.object.bar3 === null);
    }
}