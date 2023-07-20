import { LightningElement, api, wire, track } from 'lwc';
import getContactList_WithUser from '@salesforce/apex/ContactController.getContactList_WithUser';

export default class ContactVisualPicker extends LightningElement {
   @api accountId; //provided by parent LWC
   @api currentContactId; //current value in saleforce field, ie: contract.CustomerSignedId

   @track options;
   @api submitButtonName; //for display purpose. This allow various parent LWCs to influence the name of this button ie: OK, Save, Submit
   @api disablePickerForNullUser = false; //default to false. This is used in child LWC: contactVisualPickerItem
   @track currentContactElement;
   @track showMore = false;

   @wire(getContactList_WithUser, { accountId: '$accountId' })
   wiredContactWithUserList(value) {
      // Hold on to the provisioned value so we can refresh it later.
      this.wiredContactsWithUser = value; // track the provisioned value
      const { error, data } = value; // destructure the provisioned value
      if (data) {
         //data is a json object from List<Map<String, String>>, example [ {
         //     "contactid": "0035O000002AFsIQAW",
         //     "contact": "{\"attributes\":{\"type\":\"Contact\",\"url\":\"/services/data/v47.0/sobjects/Contact/0035O000002AFsIQAW\"},\"Id\":\"0035O000002AFsIQAW\",\"Name\":\"John Smith\",\"FirstName\":\"John\",\"LastName\":\"Smith\",\"Business_Role__c\":\"N/A\",\"AccountId\":\"0015O000002rNYxQAM\",\"Email\":\"ben.soh+john@n4l.co.nz\",\"Title\":\"Acting Principal\",\"Phone\":\"02 132 1312\",\"Account\":{\"attributes\":{\"type\":\"Account\",\"url\":\"/services/data/v47.0/sobjects/Account/0015O000002rNYxQAM\"},\"Name\":\"Baradene College\",\"MoE_School_ID__c\":\"61\",\"MoE_Site_ID_Lookup__c\":\"a0D5O000000MF9rUAG\",\"Id\":\"0015O000002rNYxQAM\",\"MoE_Site_ID_Lookup__r\":{\"attributes\":{\"type\":\"MoE_School_Site__c\",\"url\":\"/services/data/v47.0/sobjects/MoE_School_Site__c/a0D5O000000MF9rUAG\"},\"Name\":\"D167\",\"Id\":\"a0D5O000000MF9rUAG\"}}}",
         //     "user": "{\"attributes\":{\"type\":\"User\",\"url\":\"/services/data/v47.0/sobjects/User/0055O000000jNpnQAE\"},\"ContactId\":\"0035O000002AFsIQAW\",\"Name\":\"John Smith\",\"Username\":\"ben.soh+john@n4l.co.nz\",\"IsActive\":true,\"IsPortalEnabled\":true,\"LastLoginDate\":\"2019-11-13T02:16:41.000+0000\",\"Id\":\"0055O000000jNpnQAE\"}"
         //   }, ]
         this.options = data;
         //console.log('>>>>> this.options: ', this.options );
         this.currentContactElement = this.options.find( ({ contactid }) => contactid === this.currentContactId ); //get the element for the contact of current CustomerSignedId
         //console.log('>>>>> this.currentContactElement: ', this.currentContactElement );
         this.error = undefined;
      } else if (error) {
         this.error = error;
         this.options = undefined;
      }
   }

   @api
   reloadCurrentContactElement(newcontactid){
       this.currentContactId = newcontactid;
       this.currentContactElement = this.options.find( ({ contactid }) => contactid === this.currentContactId ); //get the element for the contact of current CustomerSignedId
       //console.log('>>>>> this.currentContactId : ', this.currentContactId );
       try {
         this.template.querySelector('c-contact-tile').reload(this.currentContactElement);
         //console.log('reload successful here...');
       } catch (error) {
          //console.log('it is just an error here...');
       }
       //this.template.querySelector('c-contact-tile').reload(this.currentContactElement);
//console.log('no more reloading querySelector(c-contact-tile) ....blah blah blah ..................... ');
      //  console.log('>>>>>>>> starting to run this.template.querySelector(c-contact-tile);');
      //  let childComponent = this.template.querySelector('c-contact-tile');
      //  console.log('>>>>>>>> finished running this.template.querySelector(c-contact-tile);');
      //  console.log('>>>>>>>> childcomponent = ' + JSON.stringify(childComponent));
      //  console.log('>>>>>>>> childcomponent object = ', childComponent);
      //  if (!childComponent===undefined){
      //    console.log('>>>>>>>> start childComponent.reload(this.currentContactElement);');
      //    childComponent.reload(this.currentContactElement);
      //  }           

   }
   
   @track selectButtonDisabled = true; //to prevent user from clicking 'Select' button when there is no selection made

   @api selectedOption;
   handleValuePickerSelected(event){
      this.selectedOption = event.detail.value; //detail.value is a json object for option
      this.selectButtonDisabled = false; //to allow user to click on 'Select' button
   }

   handleShowMoreClick() {
      this.showMore = !this.showMore;
   }

   handleSubmit(event){
      this.showMore = false;
      // Prevents the anchor element from navigating to a URL.
      event.preventDefault();

      // Creates the event with the goto navigation target
      const returnEvent = new CustomEvent('saved', {detail: {value:this.selectedOption} });

      // Dispatches the event.
      this.dispatchEvent(returnEvent);
   }
   
   handleCancel(event){
      this.showMore = false;
      // Prevents the anchor element from navigating to a URL.
      event.preventDefault();

      // Creates the event with the goto navigation target
      const returnEvent = new CustomEvent('cancelled', {detail: {value:null} });

      // Dispatches the event.
      this.dispatchEvent(returnEvent);
   }

   @api
   get contactElement(){
      // if(this.currentContactElement===null){
      // return undefined; 
      // }
      return this.currentContactElement;//return JSON object
   }

}