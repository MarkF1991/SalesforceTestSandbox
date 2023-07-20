import { LightningElement,  api } from 'lwc';


export default class tileItemAlert extends LightningElement {
    @api object;

    @api isActionable = false;
    @api actionLabel = "";
    
    get overallClass(){
        //return "slds-avatar slds-avatar_circle slds-avatar_medium slds-align_absolute-center " + this.iconclass;
        if(this.isActionable) {
            return "action slds-p-vertical_medium slds-p-horizontal_x-large " + this.object.image.class;
        }
        return "slds-p-vertical_medium slds-p-horizontal_x-large " + this.object.image.class;
    }
}