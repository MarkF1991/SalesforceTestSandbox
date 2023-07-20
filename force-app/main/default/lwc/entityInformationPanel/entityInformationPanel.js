import { LightningElement, api } from 'lwc';

export default class EntityInformationPanel extends LightningElement {
    @api items = [{ label: "Name", detail: "something" }];
}