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
    

    // get initial(){
    //     return this.line1.substring(0, 1).toUpperCase();
    // }
    
    selectHandler(event) {
        // Prevents the anchor element from navigating to a URL.
        event.preventDefault();

        // Creates the event with the contact ID data.
        const selectedEvent = new CustomEvent('selected', { detail: {title:this.title, goto:this.goto, listviewmode:this.listviewmode}, bubbles: true });

        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }
}