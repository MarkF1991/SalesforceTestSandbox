import { LightningElement, api } from 'lwc';

export default class RankedListItem extends LightningElement {
    @api object;

    get iconClass() {
        if(this.object) {
            return `slds-avatar slds-avatar_circle slds-avatar_medium slds-align_absolute-center rank${this.object.rank}`;
        }
        return `slds-avatar slds-avatar_circle slds-avatar_medium slds-align_absolute-center rank2`;
    }
}