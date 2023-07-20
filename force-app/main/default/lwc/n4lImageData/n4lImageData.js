import { LightningElement,api } from 'lwc';

export default class N4lImageData extends LightningElement {
    @api url;
    @api altText;

    renderedCallback() {
        this.template.querySelector('.image-text').innerHTML = this.url;
    }
}