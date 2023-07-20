import { LightningElement, api } from 'lwc';

export default class RankedListViewComponent extends LightningElement {
    @api title = "";
    @api items = [];
}