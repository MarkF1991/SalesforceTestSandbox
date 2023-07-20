import { LightningElement, api } from 'lwc';

export default class DatatableStringType extends LightningElement {
    @api text = "";
    @api align = "right";

    get CssClass() {
        let css = "t-text";
        css += this.align ? " " + this.align : " right";
        return css;
    }
}