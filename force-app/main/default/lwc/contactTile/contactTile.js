import { LightningElement, api, track } from 'lwc';
import updateContactPictureURL from '@salesforce/apex/ContactController.updateContactPictureURL';

/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;

export default class ContactTile extends LightningElement {
    //@api contact;
    @track editPictureMode;
    @track pictureURL;

    @api contactstring = '';
    @api userstring = '';

    @track contact;
    @track user;
    @track userIcon = {};
    @track lastLoginDateTime;


    connectedCallback(){
        this.load();
    }

    load(){
        //------------------- contact -------------------
        this.contact = JSON.parse(this.contactstring);//convert json string of contact into JSON object 
        if (this.contact.Picture__c){
            this.pictureURL = this.contact.Picture__c;
        }
        
        //------------------- user -------------------
        this.user = JSON.parse(this.userstring);//convert json string of user into JSON object 
        if(this.user){
            this.lastLoginDateTime = undefined;
            if(this.user.LastLoginDate){
                this.lastLoginDateTime = new Date(this.user.LastLoginDate); 
            }
            this.userIcon.variant = (this.user.IsActive ? 'Success' : 'Error');
            this.userIcon.title = (this.user.IsActive ? 'Active Community User' : 'Deactivated Community User');
            this.userIcon.iconname = 'utility:user';
        }
    }

    //to allow parent component to call child component method
    @api 
    reload(contactElement){
        this.contactstring = contactElement.contactstring;
        this.userstring = contactElement.userstring;
        this.load();
    }

    get displayURL(){
        return (this.contact.Picture__c ? this.contact.Picture__c : '');
    }

    get IsShowInitial(){
        if (this.pictureURL) {
            return false;
        }
        return true;
    }

    get Initial() {
        var matches = this.contact.Name.match(/\b(\w)/g);
        return matches.join('');
    }

    get lastLoginString(){
        if(this.lastLoginDateTime){
            var options = { year: 'numeric', month: 'short', day: '2-digit', hour: 'numeric', minute: '2-digit', second: '2-digit'  };
            return this.lastLoginDateTime.toLocaleDateString('en-NZ', options); //13 Nov 2019, 11:07:04 pm
        }
        return '--';
    }

    get businessRoleOrTitle(){
        if(this.contact.Business_Role__c ==='N/A'){
            return this.contact.Title;
        }
        return this.contact.Business_Role__c;
    }

    get isShowBusinessRole(){
        return ( this.businessRoleOrTitle ? true : false);
    }


    handleAvatarClick(){
        this.editPictureMode = !this.editPictureMode;
        //this.pictureURL = this.contact.Picture__c;
    }

    handlePictureURLChange(event){
        this.pictureURL = event.target.value;
    }

    handlePictureURLSave(){
        //build array dynamically
        const myArray = {};
        myArray['id'] = this.contact.Id;
        myArray['pictureurl'] = this.pictureURL;

        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            updateContactPictureURL({ fieldsMap: myArray })
                .then(result => {
                    //console.log('result from updateContactPictureURL() = ', result);
                    this.contact = result;
                    this.error = undefined;
                    this.fireEvent_contactsaved(); //fire event for LWC contactList to refresh cache for a wired method
                })
                .catch(error => {
                    this.error = error;
                    this.contact = undefined;
                });
        }, DELAY);
        
        this.editPictureMode = false;   
    }

    fireEvent_contactsaved(){
        // 2. Read about event best practices at http://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.events_best_practices
        const selectEvent = new CustomEvent('contactsaved', {
            bubbles: true,
            detail: {value:this.contact.accountId} 
        });
        // 3. Fire the custom event
        this.dispatchEvent(selectEvent);
    }
    
    handleClick(event) {
        // 1. Prevent default behavior of anchor tag click which is to navigate to the href url
        event.preventDefault();
        // 2. Read about event best practices at http://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.events_best_practices
        const selectEvent = new CustomEvent('contactselect', {
            bubbles: true,
            detail: {value:this.contact.Id} 
        });
        // 3. Fire the custom event
        this.dispatchEvent(selectEvent);
    }
}