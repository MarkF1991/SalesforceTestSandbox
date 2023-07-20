import { LightningElement,api,track} from 'lwc';

export default class N4lPhoneData extends LightningElement {
    @api textValue;
    @track url;

    connectedCallback() {
        this.url = 'tel:'+this.textValue;
    }
}