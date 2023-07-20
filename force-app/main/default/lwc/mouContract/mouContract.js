import { LightningElement, track, api, wire } from 'lwc';

import { NavigationMixin } from 'lightning/navigation';
import TimeElement from "c/utilitiesTime";
import { formatNumber } from "c/utilitiesFunction";
//import { partialURL } from "c/utilitiesURL";
//----------------------- Apex Method to request access --------------------------------
/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;

//----------------------- Contract --------------------------------
import getContract from '@salesforce/apex/ContractController.getContract';
import updateContract from '@salesforce/apex/ContractController.updateContract';
//import testSendConfirmationEmail from '@salesforce/apex/ContractController.testSendConfirmationEmail';

//----------------------- User --------------------------------
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import USER_ID from '@salesforce/user/Id';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';
import USER_EMAIL_FIELD from '@salesforce/schema/User.Email';
import USER_CONTACTID_FIELD from '@salesforce/schema/User.ContactId';
import USER_ISPORTALENABLED_FIELD from '@salesforce/schema/User.IsPortalEnabled';
const USER_FIELDS = [USER_NAME_FIELD, USER_EMAIL_FIELD, USER_CONTACTID_FIELD, USER_ISPORTALENABLED_FIELD];

//----------------------- Helper --------------------------------
//import getSupportHubURL from '@salesforce/apex/Helper.getSupportHubURL';
import getProgrammeMapping from '@salesforce/apex/Helper.getProgrammeMapping';
import N4LSchoolGeneralTermsURL from '@salesforce/label/c.N4LSchoolGeneralTermsURL';

//this is a child LWC, used in Wrapper LWCs: mouLightning (for Lightning record pages) and mouCommunity (for Community pages with URL params)
export default class MOUContract extends NavigationMixin(TimeElement) {
    
    label = {
        N4LSchoolGeneralTermsURL,
    }; 
    @api contractId = '';
    @track contract;
    // @track contract = {
    //     "Id": "8005O0000000QAHQA2",
    //     "Name": "temporary contract record",
    //     "AccountId": "0015O000002rNYxQAM",
    //     "Contract_Type__c": "Master",
    //     "CustomerSignedDate": "2019-10-30",
    //     "CustomerSignedId": "0035O0000022j3KQAQ",
    //     "MoE_Project_Manager__c": "0035O000002CM6cQAG",
    //     "MoE_Signatory__c": "0035O000002CM68QAG",
    //     "Roll_Count__c": 100,
    //     "Per_Pupil_Contribution__c": 5,
    //     "Annual_Contribution__c": 500,
    //     "Order_Total_Amount__c": 200,
    //     "Programme__c": "Network Hardware Replacement",
    //     "Status": "Draft",
    //     "StatusCode": "Draft",
    //     "Accepted_N4L_Terms_and_Conditions__c": false,
    //     "Account": {
    //       "Name": "School Name",
    //       "MoE_School_ID__c": "999",
    //       "Id": ""
    //     },
    //     "CustomerSigned": {
    //       "Name": "school principal",
    //       "Email": "customer@email.com",
    //       "Id": ""
    //     },
    //     "MoE_Project_Manager__r": {
    //       "Name": "Project Manger",
    //       "Email": "project.manager@education.govt.nz.invalid",
    //       "Id": ""
    //     },
    //     "MoE_Signatory__r": {
    //       "Name": "Ministry Signatory",
    //       "Email": "ministry.signatory@education.govt.nz.invalid",
    //       "Id": ""
    //     }
    //   };
    
    @api title = '';
    @api description = '';
    @api isLightningPage = false;
    
    @track error;
    @track messageTitle = '';
    @track messageDescription1 = '';
    @track messageDescription2 = '';
    @track isLoading = true; //remember to put it back to true when retrieving data.

    @track popUpWindow;
    
    @track contractSignedDate = new Date('2019-02-01'); //from salesforce data 
    @track IsSubmitDisabled = true;
    @track principal;
    @track contractRollCountAsAtDate = new Date('2019-07-01'); //from salesforce data

    @track programmeMapping; //to map and compare system previously known developer name to current Programme__c Global Value Set

    async connectedCallback() {
        //console.log('in async connectedCallback()... right at the beginning this._parentResult = ' , JSON.stringify(this._parentResult));//for debug
         
         if (this.contractId){
        //this is for the contract preview displaying 
             this.handleGetContract();
         }
            // } else if (this._parentResult){
        //     console.log('in async connectedCallback()...in block of (else if (this._parentResult)...) this._parentResult = ' , this._parentResult)
        //     this.handleAssignParentResultToContract();
        // }
        
        
    }

    //---------------------- get User Record ----------------------------------
    userId = USER_ID;
    @wire(getRecord, { recordId: '$userId', fields: USER_FIELDS })
    user;

    //---------------------- get Programme Mapping ----------------------------------
    wiredProgrammeMappings;
    @wire(getProgrammeMapping, {})
    wireProgrammeMapping(result) {
        this.wiredProgrammeMappings = result;

        if (result.data) {
            this.programmeMapping = JSON.parse(result.data);
            this.error = undefined;
        }  
        else if (result.error) {
            this.programmeMapping = undefined;
            this.error = result.error;      
        }
    }

    //---------------------- get Contract Record ----------------------------------
    @track output;
    @track response;
    handleGetContract(){
        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            getContract({ contractId: this.contractId })
                .then(result => {
                    this.response = JSON.parse(result.response); //result is a json object from Map<String, String>, example { "response": "{\"statusCode\":404,\"status\":\"NOT_FOUND\",\"error\":\"Could not find a Contract record with id = 8005O0000000QdWQAU\"}" }            
                    if (this.response.statusCode === 200){
                        this.contract = JSON.parse(result.contract); //contract is the second element in the result from Map<String,String>
                        this.contractSignedDate = new Date(this.contract.CustomerSignedDate);
                        this.contractRollCountAsAtDate = new Date(this.contract.Educount_Rolls_as_at__c);
                        this.checked1 = this.contract.Accepted_MoE_Terms_and_Conditions__c;
                        this.checked2 = this.contract.Accepted_N4LCharges_Terms_and_Conditions__c;
                        this.checked3 = this.contract.Accepted_N4L_Terms_and_Conditions__c;

                        this.principal = JSON.parse(result.principal); //contract is the second element in the result from Map<String,String>
                    }

                    if (this.response.statusCode >= 400){
                        this.contract = undefined;
                        this.messageTitle = this.response.statusCode + ' ' + this.response.status;
                        this.messageDescription1 = this.response.error;
                    }

                    this.output = result;
                    this.error = undefined;
                    this.isLoading = false;
                })
                .catch(error => {
                    this.error = error;
                    this.contract = undefined;
                    this.isLoading = false;
                    
                });
        }, DELAY);
    }

    //Pop Up window logic
    handleAlertClick(){
        this.popUpWindow = false;
    }
       
@track _parentResult; //remember to use @track when we want the changes to reflect in html.
@api
set parentResult(value) {
    this._parentResult = value;
    // console.log('in mouContract.js set parentResult(value)... value = ' , JSON.stringify(value)); //for debug
    // console.log('in mouContract.js set parentResult(value)... this._parentResult = ' , JSON.stringify(this._parentResult));//for debug
    let _contract = JSON.parse(value.contract);
    this.contractId = _contract.Id;
}
get parentResult() {
    // console.log('in get parentResult() ...returning  this._parentResult' , this._parentResult);
    return this._parentResult;
}

@api
refresh(){
    // console.log('in mouContract.js resfresh() this._parentResult = ' , JSON.stringify(this._parentResult));  //for debug
    this.response = JSON.parse(this._parentResult.response); //result is a json object from Map<String, String>, example { "response": "{\"statusCode\":404,\"status\":\"NOT_FOUND\",\"error\":\"Could not find a Contract record with id = 8005O0000000QdWQAU\"}" }

    if (this.response.statusCode === 200){
        this.contract = JSON.parse(this._parentResult.contract); //contract is the second element in the result from Map<String,String>
        this.contractSignedDate = new Date(this.contract.CustomerSignedDate);
        this.contractRollCountAsAtDate = new Date(this.contract.Educount_Rolls_as_at__c);
        this.checked1 = this.contract.Accepted_MoE_Terms_and_Conditions__c;
        this.checked2 = this.contract.Accepted_N4LCharges_Terms_and_Conditions__c;
        this.checked3 = this.contract.Accepted_N4L_Terms_and_Conditions__c;

        console.log('Order_Total_Amount__c: ',this.contract.Order_Total_Amount__c);
        console.log('Order_Total_at_Time_of_Invite__c: ',this.contract.Order_Total_at_Time_of_Invite__c);

        //Pop Up window logic
        if(this.contract.Order_Total_Amount__c != this.contract.Order_Total_at_Time_of_Invite__c) {
            this.popUpWindow = true;
        }else{
            this.popUpWindow = false;
        }
        //this.contractId = this.contract.contractNetworkDesign;

        this.principal = JSON.parse(this._parentResult.principal); //contract is the second element in the result from Map<String,String>
    }

    if (this.response.statusCode >= 400){
        this.contract = undefined;
        this.messageTitle = this.response.statusCode + ' ' + this.response.status;
        this.messageDescription1 = this.response.error;
    }

    // this.output = this._parentResult;
    this.error = undefined;
    this.isLoading = false;
}


    // //------------------------- Debug Mode -------------------------
    // get generalOutput(){
    //     if(this.output){
    //         return JSON.stringify(this.output);
    //     }
    //     return 'this.output = undefined';
    // }

    // get generalOutput2(){
    //     if(this.output){
    //         let res = JSON.parse(this.output.response);
    //         //let m = JSON.parse(this.output);
    //         return JSON.stringify(res);
    //     }
    //     return 'this.output = undefined';
    // }

    // get generalOutput3(){
    //     // if(this.output.contract){
    //     //     let con = JSON.parse(this.output.contract);
    //     //     return JSON.stringify(con);
    //     // }
    //     //return 'this.output.contract = undefined';
    //     return 'ok';
    // }

    // get contractOutput(){
    //     if(this.contract){
    //         return JSON.stringify(this.contract);
    //     }
    //     return 'this.contract = undefined';
    // }
    // //------------------------- Debug Mode -------------------------


    //---------------------- get Contract Record ----------------------------------

    //---------------------- ui control ----------------------------------
    @track checked1 = false; //moe terms
    @track checked2 = false; //n4l additional charges terms
    @track checked3 = false; //n4l terms
    handleCheckboxChange1(event) { 
        this.checked1 = event.target.checked;
        this.evaluateToEnableSubmitButton();
    }
    handleCheckboxChange2(event) {
        this.checked2 = event.target.checked;
        this.evaluateToEnableSubmitButton();
    }
    handleCheckboxChange3(event) {
        this.checked3 = event.target.checked;
        this.evaluateToEnableSubmitButton();
    }
    evaluateToEnableSubmitButton(){
        if (this.isShowAdditionalCosts){
            this.IsSubmitDisabled = !(this.checked1 && this.checked2 && this.checked3);
        } else {
            this.IsSubmitDisabled = !(this.checked1 && this.checked3);
        }
    }

    //6.6.2023 popup window
    get showAdditionalCharges(){
        return (this.contract.Order_Total_Amount__c - this.contract.Order_Total_at_Time_of_Invite__c).toFixed(2);
    }

    get showOrderTotalAmount(){
        return (this.contract.Order_Total_Amount__c).toFixed(2);
    }

    get isShowAdditionalCosts(){
        return (this.contract.Order_Total_Amount__c > 0); //greater than zero
    }
    
    get checkbox1_checked(){
        return (this.checked1? 'checked' : '');
    }

    get checkbox2_checked(){
        return (this.checked2? 'checked' : '');
    }

    get checkbox3_checked(){
        return (this.checked3? 'checked' : '');
    }

    get checkboxes_disabled(){
        return !this.isShowSubmitButton;
    }


    get isShowSubmitButton(){
        if(this.isLightningPage) {
            return false;
        }
        if(this.contract.Status === 'Declined'){
            return false;
        }
        return !(this.contract.Status === 'Signed' || this.contract.Status === 'Activated');
    }

        
        
    get isNSE(){
        if(this.programmeMapping){
            return (this.contract.Programme__c === this.programmeMapping.NSE.Programme__c);
        } 
        return false;
    }

    get isNHR(){
        if(this.programmeMapping){
            return (this.contract.Programme__c === this.programmeMapping.NHR.Programme__c);
        } 
        return false;
    }

    get isActivated(){
        return (this.contract.StatusCode == 'Activated');
    }

    get AcceptedOrDeclined1(){
        let declined = {"iconname":"action:remove", "description":"Contract Declined"};
        let accepted = {"iconname":"action:check", "description":"accepted MoE's terms and conditions"};
        let signed = {"iconname":"action:check", "description":"Contract signed and accepted MoE's terms and conditions"};
        let activated = {"iconname":"action:check", "description":"Contract activated and accepted MoE's terms and conditions"};
        let neutral = {"iconname":"action:new_campaign", "description":"in progress contract"};
        
        if(this.contract.Status === 'Declined'){ //evaluate Status = Declined first
            return declined;
        }
        if (this.isShowSubmitButton == false && this.contract.Accepted_MoE_Terms_and_Conditions__c == true){
            if(this.contract.Status === 'Signed') return signed;
            if(this.contract.Status === 'Activated') return activated;
            return accepted;
        }
        
        return neutral; 
    }

    get AcceptedOrDeclined2(){
        let declined = {"iconname":"action:remove", "description":"Contract Declined"};
        let accepted = {"iconname":"action:check", "description":"accepted N4L's additional charges terms and conditions"};
        let signed = {"iconname":"action:check", "description":"Contract signed and accepted N4L's additional charges terms and conditions"};
        let activated = {"iconname":"action:check", "description":"Contract activated and accepted N4L's additional charges terms and conditions"};
        let neutral = {"iconname":"action:new_campaign", "description":"in progress contract"};
        
        if(this.contract.Status === 'Declined'){ //evaluate Status = Declined first
            return declined;
        }
        if (this.isShowSubmitButton == false && this.contract.Accepted_N4LCharges_Terms_and_Conditions__c == true){
            if(this.contract.Status === 'Signed') return signed;
            if(this.contract.Status === 'Activated') return activated;
            return accepted;
        }
        
        return neutral; 
    }

    get AcceptedOrDeclined3(){
        let declined = {"iconname":"action:remove", "description":"Contract Declined"};
        let accepted = {"iconname":"action:check", "description":"accepted N4L's terms and conditions"};
        let signed = {"iconname":"action:check", "description":"Contract signed and accepted N4L's terms and conditions"};
        let activated = {"iconname":"action:check", "description":"Contract activated and accepted N4L's terms and conditions"};
        let neutral = {"iconname":"action:new_campaign", "description":"in progress contract"};
        
        if(this.contract.Status === 'Declined'){ //evaluate Status = Declined first
            return declined;
        }
        if (this.isShowSubmitButton == false && this.contract.Accepted_N4L_Terms_and_Conditions__c == true){
            if(this.contract.Status === 'Signed') return signed;
            if(this.contract.Status === 'Activated') return activated;
            return accepted;
        }
        
        return neutral; 
    }

    get ContractDeclined(){
        let declined = {"iconname":"action:remove", "description":"Order Form has been declined"};
        if(this.contract.Status === 'Declined'){ //evaluate Status = Declined first
            return declined;
        }
        return undefined;
    }

    get ContractAccepted(){
        let accepted = {"iconname":"action:check", "description":"Order Form has been accepted and submitted"};
        if (this.contract.Status === 'Signed' || this.contract.Status === 'Activated'){
            return accepted;
        }
        return undefined;
    }


    get isShowSystemDate(){
        return (this.contractSignedDate == 'Invalid Date');
    }

    get todayDateString(){
        var todayDate = new Date();
        var options = { year: 'numeric', month: 'short', day: '2-digit' };
        return todayDate.toLocaleDateString('en-NZ', options); //example 01 Dec 2019
    }

    get contractSignedDateString(){
        var options = { year: 'numeric', month: 'short', day: '2-digit' };
        return this.contractSignedDate.toLocaleDateString('en-NZ', options); //example 01 Dec 2019
    }

    get contractOrderTotalAmount(){
        return formatNumber((this.contract.Order_Total_Amount__c ? this.contract.Order_Total_Amount__c : 0).toFixed(2)); //fix 2 decimal places, display number with , separator
    }

    get contractRollCount(){
        return formatNumber(this.contract.Educount_Rolls__c ? this.contract.Educount_Rolls__c : 0); //display number with , separator
    }

    get contractRollCountAsAt(){
        if(!isNaN(this.contractRollCountAsAtDate)){
            var options = { year: 'numeric', month: 'long' }; //excluding day
            return this.contractRollCountAsAtDate.toLocaleDateString('en-NZ', options); //example July 2019
        } else {
            return '';
        }
    }
    get contractPerPupilContribution(){
        return formatNumber((this.contract.Per_Pupil_Contribution__c ? this.contract.Per_Pupil_Contribution__c : 0).toFixed(2)); //fix 2 decimal places, display number with , separator
    }

    get contractAnnualContribution(){
        return formatNumber((this.contract.Annual_Contribution__c ? this.contract.Annual_Contribution__c : 0).toFixed(2)); //fix 2 decimal places, display number with , separator
    }

    get contractNetworkDesign(){
        //return 'https://test-n4lportal.cs152.force.com/schoolictsupport/s/relatedlist/8005P0000000N0OQAU/AttachedContentDocuments';
        //return `${partialURL()}relatedlist/${this.contractId}/AttachedContentDocuments`; 
        
        return `relatedlist/${this.contractId}/AttachedContentDocuments`;  //Community Page and Lightning Experience can automatically figure out the front part of the URL.

        //big lesson learned:
        //1. when we return url without partialURL like 'https://.....force.com/schoolictsupport/s/', both Community Page and Lightning Experience can automatically figure out it's own full URL.
        //2. when we tried to use apex to return supporthub url, it works in Lightning Experience, but it added 'null' in the place of 'https://' in Community Page.
        //3. below was the code with correct logic, but return error in Community Page.
        // let supportHubPartialURL = '';
        // window.clearTimeout(this.delayTimeout);
        // // eslint-disable-next-line @lwc/lwc/no-async-operation
        // this.delayTimeout = setTimeout(() => {
        //     getSupportHubURL({}) //no parameters
        //         .then(result => {
        //             result = supportHubPartialURL; //result is a string from Helper.
        //             console.log('~~~~~~ result = '+result);
        //             console.log('~~~~~~ this.supportHubPartialURL  = ' + supportHubPartialURL );
        //             console.log('~~~~~~ returning url = '+ `${supportHubPartialURL }relatedlist/${this.contractId}/AttachedContentDocuments`);
        //             //return `${supportHubPartialURL}relatedlist/${this.contractId}/AttachedContentDocuments`; 
        //         })
        //         .catch(error => {
        //             supportHubPartialURL = 'https://support.n4l.co.nz/s'; //default to support hub url
        //             console.log('~~~~~~ returning url = '+ `${supportHubPartialURL}relatedlist/${this.contractId}/AttachedContentDocuments`);
                    
        //         });
        //     }, DELAY);
        //     return `${supportHubPartialURL}relatedlist/${this.contractId}/AttachedContentDocuments`; 
       
    }

    handleDecline(){
        this.checked1 = false;
        this.checked2 = false;
        this.checked3 = false;
        this.updateRecord('Declined');
    }

    handleSubmit(){
        this.updateRecord('Activated');
    }

    updateRecord(status){
        this.isLoading = true; //start spinner

        //build array dynamically
        const myArray = {};
        myArray['action'] = 'Update_Signed_Or_Declined';
        myArray['id'] = this.contract.Id;
        myArray['status'] = status;
        myArray['acceptedTsandCs1'] = this.checked1;
        myArray['acceptedTsandCs2'] = this.checked2;
        myArray['acceptedTsandCs3'] = this.checked3;
        myArray['principalname'] = this.principal.Name;
        myArray['principalemail'] = this.principal.Email;
        myArray['customerUserId'] = this.userId;


        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            updateContract({ fieldsMap: myArray })
                .then(result => {

                    this.response = JSON.parse(result.response); //result is a json object from Map<String, String>, example { "response": "{\"statusCode\":404,\"status\":\"NOT_FOUND\",\"error\":\"Could not find a Contract record with id = 8005O0000000QdWQAU\"}" }

                    if (this.response.statusCode === 200){
                        this.contract = JSON.parse(result.contract); //contract is the second element in the result from Map<String,String>
                        this.contractSignedDate = new Date(this.contract.CustomerSignedDate);
                        this.checked1 = this.contract.Accepted_MoE_Terms_and_Conditions__c;
                        this.checked2 = this.contract.Accepted_N4LCharges_Terms_and_Conditions__c;
                        this.checked3 = this.contract.Accepted_N4L_Terms_and_Conditions__c;

                    }

                    if (this.response.statusCode >= 400){
                        this.contract = undefined;
                        this.messageTitle = this.response.statusCode + ' ' + this.response.status;
                        this.messageDescription1 = this.response.error;
                    }
                    this.error = undefined;
                    this.isLoading = false; //stop spinner: must be inside .then()
                })
                .catch(error => {
                    console.log('handleSubmit() error(): ' , error);
                    this.error = error;
                    this.response = undefined;
                });
        }, DELAY);
    }

    
    
    
    // @track testURLResult = '';
    // handleTestButton(){
        
    //     window.clearTimeout(this.delayTimeout);
    //     // eslint-disable-next-line @lwc/lwc/no-async-operation
    //     this.delayTimeout = setTimeout(() => {
    //         testSendConfirmationEmail({ })
    //             .then(result => {
    //                 this.testURLResult = result;
    //             })
    //             .catch(error => {
    //                 this.error = error;
    //             });
    //     }, DELAY);
    // }

}