import { LightningElement,  api } from 'lwc';


export default class tileItem extends LightningElement {
    //for navigation
    @api path; //navigating within Community Pages
    @api goto;
    @api listviewmode;
    @api line1;
    @api line2;
    @api title;
    @api uom;
    @api value;
    @api initial;
    @api materialicon;
    @api iconclass;
    @api object;
    @api disableLink = false;
}