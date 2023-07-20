import { LightningElement, track, api, wire } from 'lwc';
import requestAuth from '@salesforce/apex/JWTController.request_authorisation_with_credential';

//import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { partialURL, resolveSupportHubEnvironment } from "c/utilitiesURL";
//import TimeElement from "c/utilitiesTime";

//----------------------- Apex Method to request access --------------------------------
import { getQueryParams, pushStateToUrl } from "c/communitiesNavigation";
/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;

//----------------------- User --------------------------------
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';
import USER_EMAIL_FIELD from '@salesforce/schema/User.Email';
import USER_CONTACTID_FIELD from '@salesforce/schema/User.ContactId';
import USER_ISPORTALENABLED_FIELD from '@salesforce/schema/User.IsPortalEnabled';
const USER_FIELDS = [USER_NAME_FIELD, USER_EMAIL_FIELD, USER_CONTACTID_FIELD, USER_ISPORTALENABLED_FIELD];


//----------------------- Contract --------------------------------



export default class AgreementMOU extends NavigationMixin(LightningElement) {
//export default class MOUCommunity extends NavigationMixin(TimeElement) {
    // ---------------------------- WIRE FIRST before connectedCallBack ----------------------------
    userId = USER_ID;
    @wire(getRecord, { recordId: '$userId', fields: USER_FIELDS })
    user;
    //@api contractId = '';
    //@track signatoryContactId = '';

    @api title = '';
    @api description = '';
    @track error;
    @track message1;
    @track message2;


    //connectedCallback() {
    async connectedCallback() {
        this.queryParams = getQueryParams(window.location.search);
        this.p = this.queryParams.p;
        this.t = this.queryParams.t;
        if(!this.p) {
            this.p = "mou";
        }
        if(this.p && this.t){
            this.handleRequestAuth();
        } else {
            this.message1 = '400 BAD_REQUEST';
            this.message2 = 'missing parameter';
        }
        // if (this.queryParams.id) {
        //     this.contractId = this.queryParams.id;
        // }
        // if (this.queryParams.s) {
        //     this.signatoryContactId = this.queryParams.s;
        // }
    }

    // ---------------------------- get User Record ----------------------------
    // userId = USER_ID;
    // @wire(getRecord, { recordId: '$userId', fields: USER_FIELDS })
    // user;
    
    get authorisedToSubmit(){
        let isPortalEnabled = getFieldValue(this.user.data, USER_ISPORTALENABLED_FIELD);
        if(isPortalEnabled){
            return this.showMOUContract;
        }
        return true; //allow internal user to view contract on community page
    }

    get userOutput(){
        return JSON.stringify(this.user);
    }

    get contractOutput(){
        if(this.contract){
            return JSON.stringify(this.contract);
        }
        return 'this.contract = undefined';
        
    }

    @track response;
    @track parentResult;
    @track showMOUContract = true; //must default to true so that in this.refreshChildComponent(), the this.template.querySelector('c-mou-contract') will work
    
    // handleRequestAuth(){
    //     let userContactId = getFieldValue(this.user.data, USER_CONTACTID_FIELD);
    //     window.clearTimeout(this.delayTimeout);
    //     // eslint-disable-next-line @lwc/lwc/no-async-operation
    //     this.delayTimeout = setTimeout(() => {
    //         requestAuth({ productName: this.p , token: this.t, contactId: userContactId})
    //             .then(result => {
    //                 this.parentResult = JSON.parse(result); //getting ready to pass the result to child component mouContract.js
    //                 this.response = this.parentResult.response; //result is a json object from Map<String, String>, example { "response": "{\"statusCode\":404,\"status\":\"NOT_FOUND\",\"error\":\"Could not find a Contract record with id = 8005O0000000QdWQAU\"}" }
                    
    //                 if(this.parentResult.statusCode === 200){
    //                     // console.log('>>>> in if(this.response.statusCode === 200){ >>>>>  this.parentResult : ' , JSON.stringify(this.parentResult);//for debug
    //                     this.showMOUContract = true;
    //                     this.refreshChildComponent();
    //                 } else {
    //                     // console.log('>>>> in ELSE OF if(this.response.statusCode === 200) >>>>>  this.parentResult : ' , JSON.stringify(this.parentResult); //for debug
    //                     if(userContactId === undefined){
    //                         console.log('>>>>>>>>>>>>>>>>> userContactId === undefined | run  this.handleRequestAuth() again');
    //                         this.handleRequestAuth();
    //                     }else{
    //                         this.showMOUContract = false;
    //                         this.message1 = this.parentResult.statusCode + ' ' + this.parentResult.status;
    //                         this.message2 = this.parentResult.error;
    //                     }
                        
    //                 }
    //             })
    //             .catch(error => {
    //                 this.error = error;
    //                 this.response = undefined;
    //             });
    //     }, DELAY);
    // }

    handleRequestAuth(){
        window.clearTimeout(this.delayTimeout);
        //console.log('++++++++++userId: USER_ID:', USER_ID);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            //console.log('++++++++++userId: USER_ID:', USER_ID);
            requestAuth({ productName: this.p , token: this.t, userId: USER_ID})
                .then(result => {
                    //console.log('>>>>> requestAuth().result = ' + JSON.stringify(result));
                    this.parentResult = JSON.parse(result); //getting ready to pass the result to child component mouContract.js
                    this.response = this.parentResult.response; //result is a json object from Map<String, String>, example { "response": "{\"statusCode\":404,\"status\":\"NOT_FOUND\",\"error\":\"Could not find a Contract record with id = 8005O0000000QdWQAU\"}" }
                    
                    if(this.parentResult.statusCode === 200){
                        // console.log('>>>> in if(this.response.statusCode === 200){ >>>>>  this.parentResult : ' , JSON.stringify(this.parentResult);//for debug
                        this.showMOUContract = true;
                        //this.refreshChildComponent();
                        this.evaluateDisplayComponentOrRedirect();
                    } else {
                        // console.log('>>>> in ELSE OF if(this.response.statusCode === 200) >>>>>  this.parentResult : ' , JSON.stringify(this.parentResult); //for debug
                        // if(userContactId === undefined){
                        //     console.log('>>>>>>>>>>>>>>>>> userContactId === undefined | run  this.handleRequestAuth() again');
                        //     this.handleRequestAuth();
                        // }else{
                            this.showMOUContract = false;
                            this.message1 = this.parentResult.statusCode + ' ' + this.parentResult.status;
                            this.message2 = this.parentResult.error;
                        // }
                        
                    }
                })
                .catch(error => {
                    this.error = error;
                    this.response = undefined;
                });
        }, DELAY);
    }


    evaluateDisplayComponentOrRedirect(){
        let _contract = JSON.parse(this.parentResult.contract); //contract is the second element in the result from Map<String,String>
        if (_contract.Status === 'Activated'){
            this.redirectToRecordPage(_contract);
        } else {
            this.refreshChildComponent();
        }
    }

    redirectToRecordPage(_contract){
        // Navigate to a URL
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: _contract.Id,
                objectApiName: 'Contract',
                actionName: 'view'
            }
        },
        true // Replaces the current page in your browser history with the URL
        );
    }
    
    refreshChildComponent(){
        const mouContract = this.template.querySelector('c-mou-contract');
        mouContract.parentResult = this.parentResult; //must explicitly update the @track _parentResult in child component mouContract.js
        mouContract.refresh();
    }

    get output(){
        return JSON.stringify(this.parentResult);
    }

}

// JSON.stringify(this.user) gives you this
// {
//     "data": {
//         "apiName": "User",
//         "childRelationships": {},
//         "fields": {
//             "ContactId": {
//             "displayValue": null,
//             "value": "0035O000002AFsIQAW"
//             },
//             "Email": {
//             "displayValue": null,
//             "value": "ben.soh+john@n4l.co.nz"
//             },
//             "Name": {
//             "displayValue": null,
//             "value": "John Smith"
//             }
//         },
//         "id": "0055O000000jNpnQAE",
//         "lastModifiedById": "00590000006UfEyAAK",
//         "lastModifiedDate": "2019-11-01T01:17:33.000Z",
//         "recordTypeInfo": null,
//         "systemModstamp": "2019-11-01T01:17:33.000Z"
//         }
// }