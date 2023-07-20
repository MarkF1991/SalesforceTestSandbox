import { LightningElement, api, wire, track } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'; // import toast message event .

import updateContract from '@salesforce/apex/ContractController.updateContract';
import inviteToSignContract from '@salesforce/apex/ContractController.inviteToSignContract';
import updateUserOrigin from '@salesforce/apex/ContractController.contact_userOrign_update';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import CONTRACT_ACCOUNTID_FIELD from '@salesforce/schema/Contract.AccountId';
import CONTRACT_CUSTOMERSIGNEDID_FIELD from '@salesforce/schema/Contract.CustomerSignedId';
import CONTRACT_OWNERID_FIELD from '@salesforce/schema/Contract.OwnerId'
import CONTRACT_STATUS_FIELD from '@salesforce/schema/Contract.Status';
import CONTRACT_EDUCOUNTROLLES_FIELD from '@salesforce/schema/Contract.Educount_Rolls__c';
import CONTRACT_EDUCOUNTROLLESASAT_FIELD from '@salesforce/schema/Contract.Educount_Rolls_as_at__c';

import getContact_WithUser from '@salesforce/apex/ContactController.getContact_WithUser';

const CONTRACT_FIELDS = [CONTRACT_ACCOUNTID_FIELD, CONTRACT_CUSTOMERSIGNEDID_FIELD, CONTRACT_STATUS_FIELD, CONTRACT_EDUCOUNTROLLES_FIELD, CONTRACT_EDUCOUNTROLLESASAT_FIELD];

/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;

export default class MOUContractSignatory extends LightningElement {
@api recordId;    
@api title = 'Contract Authorised Signatory';
@api description = '';
@api currentContactId;

@track options;
@track currentContactElement;

@track error;
@track messageTitle = '';
@track messageDescription1 = '';
@track messageDescription2 = '';
@track isLoading = true; //remember to put it back to true when retrieving data.

//get contract record
@wire(getRecord, { recordId: '$recordId', fields: CONTRACT_FIELDS })
contract;

@wire(getContact_WithUser, { contactId: '$contactId' })
wiredContactWithUserObject(value) {
    // Hold on to the provisioned value so we can refresh it later.
    this.wiredContactWithUser = value; // track the provisioned value
    const { error, data } = value; // destructure the provisioned value
    if (data) {
        //data is a json object from List<Map<String, String>>, example [ {
        //     "contactid": "0035O000002AFsIQAW",
        //     "contact": "{\"attributes\":{\"type\":\"Contact\",\"url\":\"/services/data/v47.0/sobjects/Contact/0035O000002AFsIQAW\"},\"Id\":\"0035O000002AFsIQAW\",\"Name\":\"John Smith\",\"FirstName\":\"John\",\"LastName\":\"Smith\",\"Business_Role__c\":\"N/A\",\"AccountId\":\"0015O000002rNYxQAM\",\"Email\":\"ben.soh+john@n4l.co.nz\",\"Title\":\"Acting Principal\",\"Phone\":\"02 132 1312\",\"Account\":{\"attributes\":{\"type\":\"Account\",\"url\":\"/services/data/v47.0/sobjects/Account/0015O000002rNYxQAM\"},\"Name\":\"Baradene College\",\"MoE_School_ID__c\":\"61\",\"MoE_Site_ID_Lookup__c\":\"a0D5O000000MF9rUAG\",\"Id\":\"0015O000002rNYxQAM\",\"MoE_Site_ID_Lookup__r\":{\"attributes\":{\"type\":\"MoE_School_Site__c\",\"url\":\"/services/data/v47.0/sobjects/MoE_School_Site__c/a0D5O000000MF9rUAG\"},\"Name\":\"D167\",\"Id\":\"a0D5O000000MF9rUAG\"}}}",
        //     "user": "{\"attributes\":{\"type\":\"User\",\"url\":\"/services/data/v47.0/sobjects/User/0055O000000jNpnQAE\"},\"ContactId\":\"0035O000002AFsIQAW\",\"Name\":\"John Smith\",\"Username\":\"ben.soh+john@n4l.co.nz\",\"IsActive\":true,\"IsPortalEnabled\":true,\"LastLoginDate\":\"2019-11-13T02:16:41.000+0000\",\"Id\":\"0055O000000jNpnQAE\"}"
        //   }, ]
        this.options = data;
        console.log('>>>>> this.options: ', JSON.stringify(this.options) );
        console.log('>>>>> this.CustomerSignedId(): ', JSON.stringify(getFieldValue(this.contract.data, CONTRACT_OWNERID_FIELD) ));
        this.currentContactElement = this.options.find( ({ contactid }) => contactid === getFieldValue(this.contract.data, CONTRACT_OWNERID_FIELD)); //get the element for the contact of current CustomerSignedId
        console.log('>>>>> this.currentContactElement: ', JSON.stringify(this.currentContactElement) );
        this.error = undefined;
    } else if (error) {
        this.error = error;
        this.options = undefined;
    }
}

get AccountId() {
    return getFieldValue(this.contract.data, CONTRACT_ACCOUNTID_FIELD);
}

get EducountRolles() {
    return getFieldValue(this.contract.data, CONTRACT_EDUCOUNTROLLES_FIELD);
}

//MNTC-1414
get EducountRollesAsAt() {
    return getFieldValue(this.contract.data, CONTRACT_EDUCOUNTROLLESASAT_FIELD);
}

get CustomerSignedId() {
    return getFieldValue(this.contract.data, CONTRACT_CUSTOMERSIGNEDID_FIELD);
}

get CurrentDate() {
    // Get the current date/time in UTC
let rightNow = new Date();

// Adjust for the user's time zone
rightNow.setMinutes(
    new Date().getMinutes() - new Date().getTimezoneOffset()
);

// Return the date in "YYYY-MM-DD" format
let yyyyMmDd = rightNow.toISOString().slice(0,10);
// Displays the user's current date, e.g. "2020-05-15"
    return yyyyMmDd;
}

get DateDiff() {
    var dateCurrent= new Date(this.CurrentDate);
    var dateEducountRollesAsAt= new Date(this.EducountRollesAsAt);
    var dateDiff=(dateCurrent.getTime()-dateEducountRollesAsAt.getTime())/1000;//difference in mili seconds
    dateDiff=dateDiff/(60*60*24);
    return dateDiff;
}
get IsInviteButtonDisabled() { //invite button 

try{
    console.log('>>>>>>>this.CustomerSignedId 0:',this.CustomerSignedId);
    if(this.CustomerSignedId===null){

    return true;
    }

    let component = this.template.querySelector('c-contact-visual-picker');
    console.log('>>>>>>>component 1:',component);
    let element = component.contactElement;
    console.log('>>>>>>>element 2:',element);
    if(element===null){

        return true;
    }
    this.currentContactElement = element;
    console.log('>>>>>>> 3 element.user = ',element.userstring);
    let user = JSON.parse(element.userstring);
    console.log('>>>>>>>User 4:',user);
    //ITR-1397 remove these logic to allow the invite button runs for user who dont have user account yet
    // if (user === null){

    //     return true;
    // }
    // console.log('>>>>>>> 5:',user.IsActive);
    // if (user.IsActive===false){

    //     return true;
    // }

}
catch (error) {

    return true;
}

return false;
}


handleSave(event){ 
    let selectedOption = event.detail.value; //detail.value is a json object for option from ContractVisualPicker. 

//   this.updateRecord(myArray);
    this.updateContractOwner(selectedOption);
}


updateContractOwner(contactElement){
    let contact = JSON.parse(contactElement.contactstring);
    let user = JSON.parse(contactElement.userstring);

    //build array dynamically to update record
    const myArray = {};
    myArray['action'] = 'Update_Customer_Signatory';
    myArray['id'] = this.recordId;
    myArray['CustomerSignedId'] = contact.Id;

    //ITR-1397 Added logic to see whether the contact with user account or not
    if(user !== null){
        myArray['OwnerId'] = user.Id;
    }
    else if(user === null){
        myArray['OwnerId'] = '0055m000000I8LeAAK';
    }

    myArray['CustomerSignedTitle'] = contact.Title;

    console.log('>>>>>>>>>>>>>>> inside updateContractOwner(contactElement)');
    console.log('>>>>> before updateRecord, myArray = ' + JSON.stringify(myArray));
    this.updateRecord(myArray);
    console.log('>>@>>> after updateRecord, myArray = ' + JSON.stringify(myArray));
}


@track response;
updateRecord(myArray){
    this.isLoading = true; //start spinner
    
    //window.clearTimeout(this.delayTimeout);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    //this.delayTimeout = setTimeout(() => {
        updateContract({ fieldsMap: myArray })
            .then(result => {
                this.response = JSON.parse(result.response); //result is a json object from Map<String, String>, example { "response": "{\"statusCode\":404,\"status\":\"NOT_FOUND\",\"error\":\"Could not find a Contract record with id = 8005O0000000QdWQAU\"}" }

                if (this.response.statusCode === 200 && this.EducountRolles > 0 && this.EducountRollesAsAt !== null && this.DateDiff <= 420){
                    this.contract = JSON.parse(result.contract); //contract is the second element in the result from Map<String,String>
                    
                    //from definition above:  myArray['action'] = 'Update_Customer_Signatory';
                    if(myArray.action === 'Update_Customer_Signatory'){
                    
                    this.template.querySelector('c-contact-visual-picker').reloadCurrentContactElement(this.contract.CustomerSignedId);//reload child component

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: this.title,
                            message:'Contract record has been updated successfully',
                            variant: 'success',
                        }),
                    );
                    }
                    //when action = Update_Status_Only, no need to display any Toast Message 
                
                this.messageTitle = undefined; //clear error message
                }

                if (this.response.statusCode >= 400){
                    //this.contract = undefined;
                    this.messageTitle = this.response.statusCode + ' ' + this.response.status;
                    this.messageDescription1 = this.response.error;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error while saving Contract record',
                            message: this.response.error,
                            variant: 'error',
                        })
                    );
                }
                this.error = undefined;
                this.isLoading = false; //stop spinner: must be inside .then()
            })
            .catch(error => {
            console.log('>>>>>!!!!!!!!! after updateContract ran .then(result failed ) .... .catch(error...)= ' + JSON.stringify(error));
                this.error = error;
                this.response = undefined;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while saving Contract record',
                        message: error.message,
                        variant: 'error',
                    })
                );
            });
    //}, DELAY);
    console.log('>>>>> Inside updateRecord - finished. ');
}


updateStatus(status){
//build array dynamically
const myArray = {};
myArray['action'] = 'Update_Status_Only';
myArray['id'] = this.recordId;
myArray['status'] = status;

this.updateRecord(myArray);
}

//ITR1397 to update contact userOrigin
updateContactUserOrigin(){
updateUserOrigin({recordId: this.recordId});
}


handleSendInvite(){
this.isLoading = true; //start spinner

window.clearTimeout(this.delayTimeout);
// eslint-disable-next-line @lwc/lwc/no-async-operation
this.delayTimeout = setTimeout(() => {

this.updateContractOwner(this.currentContactElement);//pass contactElement from child LWC into the method to update Contract's owner. Before sending email.

if(this.EducountRolles > 0 && this.EducountRollesAsAt !== null && this.DateDiff <= 420){
this.sendInvite();
}

//MNTC-1414-----Start-----
else if (this.EducountRolles == null || this.EducountRolles <= 0){
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'inviteToSignContract error',
            message: '"Educount Rolls" must be greater than 0 ',
            variant: 'error'
        })
    );

}

else if (this.EducountRollesAsAt == null){
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'inviteToSignContract error',
            message: '"Educount Rolls as at" cannot be empty ',
            variant: 'error'
        })
    );

}

else if (this.DateDiff > 420){
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'inviteToSignContract error',
            message: '"Educount Rolls as at" cannot be older than 14 months ',
            variant: 'error'
        })
    );

}
//MNTC-1414-----End-----
}, DELAY);
}

sendInvite(){
console.log('?????>>>>this.EducountRolles',this.EducountRolles);
console.log('?????>>>>this.EducountRollesAsAt get time',this.EducountRollesAsAt);
console.log('?????>>>>this.Current Date',this.CurrentDate);
console.log('?????>>>>current date - EducountRollesAsAt date = ',this.DateDiff);

//window.clearTimeout(this.delayTimeout);
// eslint-disable-next-line @lwc/lwc/no-async-operation
//this.delayTimeout = setTimeout(() => {
    inviteToSignContract({ type: 'MOU' , recordId: this.recordId})
        .then(result => {
            this.response = JSON.parse(result); //result is json string
            this.error = undefined;
            if (this.response.statusCode === 200){
                console.log('>>>>>>>>>>> in sendInvite() before running  this.updateStatus(In Approval Process)');
                this.updateStatus('In Approval Process'); //update the status
                this.updateContactUserOrigin(); //ITR-1397 update userOrigin
                console.log('>>>>>>>>>>> in sendInvite() after running  this.updateStatus(In Approval Process)');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Invitation to Sign MOU',
                        message: 'Successfully sent email',
                        variant: 'success'
                    })
                );
            }

            else if (this.response.statusCode >= 400){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'inviteToSignContract error',
                        message: this.response.message,
                        variant: 'error'
                    })
                );

            }
            this.isLoading = false; //stop spinner: must be inside .then()
        })
        .catch(error => {
            this.error = error;
            this.response = undefined;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error updating record',
                    message: error.message,
                    variant: 'error'
                })
            );
        });
//}, DELAY);
}
}