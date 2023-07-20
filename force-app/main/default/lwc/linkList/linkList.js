/* reference 
*  https://github.com/trailheadapps/lwc-recipes/blob/master/force-app/main/default/lwc/ldsDeleteRecord/ldsDeleteRecord.js
*  https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.apex
*/
import { LightningElement, api, track } from 'lwc';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';



//export default class TaskList extends LightningElement {
export default class LinkList extends LightningElement{
   // Flexipage provides recordId and objectApiName
   @api title = 'Opportunity Links'
    @api legend = '';
    @api readOnly = false;
    @track error;
    



//--------------------- links ------------------------------
@track editable;
@track _links = []; //remember to use @track when we want the changes to reflect in html.
@api
set links(value) {
    // console.log('in linkList.js, value:', JSON.stringify(value));
    this._links = value;
    // console.log('in linkList.js, this._links :', JSON.stringify(this._links));
    this.editable = JSON.parse(JSON.stringify(value)); 
    // console.log('in linkList.js, this.editable :', JSON.stringify(this.editable ));
}
get links() {
    return this._links;
}

// @api
// refreshLinks(value){
//     this.links = 
// }
//--------------------- links ------------------------------


disconnectedCallback() {
    // unsubscribe from AccountSelected event
    unregisterAllListeners(this);
}

get isReadOnly(){
    return (this.readOnly ? true : '');
}

@api 
handleShowLinkTileModal(querySelectorElement){
    //apply DELAY to so that querySelector can find the newly created linkTile LWC in DOM
    window.clearTimeout(this.delayTimeout);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.delayTimeout = setTimeout(() => {
        console.log('in linkList.js, this.template.querySelector(querySelectorElement):', querySelectorElement);
        const linkTile = this.template.querySelector(querySelectorElement);
        console.log('in linkList.js, const linkTile is:', JSON.stringify(linkTile));
        if(linkTile){
            linkTile.handleNew();
        }
        

    }, 350);
}


}