import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { partialURL, resolveSupportHubEnvironment } from "c/utilitiesURL";

//----------------------- Apex Method to request access --------------------------------
//import WITCH_HUNT from '@salesforce/apex/OnboardingController.witchHunt';
import REQUEST_ACCESS from '@salesforce/apex/OnboardingController.request_access';
import REQUEST_ACCESS_PREREQUISITE from '@salesforce/apex/OnboardingController.request_access_prerequisite';
import { getQueryParams, pushStateToUrl } from "c/communitiesNavigation";
/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;

//----------------------- User --------------------------------
import { getRecord, createRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import EMAIL_FIELD from '@salesforce/schema/User.Email';
import FORTIPORTAL_CUSTOMER_NAME_FIELD from '@salesforce/schema/User.FortiPortal_Customer_Name__c';
import IS_FILTERING_PORTAL_USER_FIELD from '@salesforce/schema/User.UserPermissionsFilteringPortalUser__c';

//----------------------- Custom Label --------------------------------
import FilteringPortalUrl from '@salesforce/label/c.FilteringPortalUrl';
import N4LTermsAndConditionURL from '@salesforce/label/c.N4LTermsAndConditionURL';


export default class OnboardingFiltering extends NavigationMixin(LightningElement) {
    label = {
        FilteringPortalUrl,
        N4LTermsAndConditionURL,
    }; 

    @track p = ''; //url parameter - product name
    //@track response = {};  //responsed from Apex method: {"statusCode":401,"status":"UNAUTHORIZED","request_authorisation":"Token Expired"}
    @track response = {"statusCode":401,"status":"UNAUTHORIZED","request_authorisation":"Token Expired"}
    
    @api title = 'Welcome to Filtering Portal';
    @api description = 'Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas porttitor congue massa. Fusce posuere, magna sed pulvinar ultricies, purus lectus malesuada libero, sit amet commodo magna eros quis urna. Nunc viverra imperdiet enim. Fusce est. Vivamus a tellus. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Proin pharetra nonummy pede. Mauris et orci. Aenean nec lorem. In porttitor. Donec laoreet nonummy augue. Suspendisse dui purus, scelerisque at, vulputate vitae, pretium mattis, nunc. Mauris eget neque at sem venenatis eleifend. Ut nonummy.';
    
    @track showSignUp = false;
    @track showTakeMeThere = false;
    @track showRequestAccess = false;
    @track IsRequestAccessDisabled = true;
    
    @track showForbidRequestAccess = false;
    @track prerequisiteEmail = '';
    @track prerequisiteDomain = '';

    @track error;
    
    @track email;
    @track name;
    @track FortiPortal_Customer_Name;
    @track isFilteringPortalUser = false;
    
    @track isLoading = true;

    @track showMessage = false; //temporary solution until Winter 20 arrives 13 Oct 2019
    @track message1 = '';
    @track message2 = '';

    connectedCallback() {
        this.queryParams = getQueryParams(window.location.search);
        this.p = this.queryParams.p;

        if(!this.p) {
            this.p = "filtering-portal";
        }
    }
    
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [NAME_FIELD, EMAIL_FIELD, FORTIPORTAL_CUSTOMER_NAME_FIELD, IS_FILTERING_PORTAL_USER_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
            this.error = error;
            console.log('this.error = ', this.error);
        } else if (data) {
            this.email = data.fields.Email.value;
            this.name = data.fields.Name.value;

            this.isFilteringPortalUser = data.fields.UserPermissionsFilteringPortalUser__c.value;
            // this.FortiPortal_Customer_Name = data.fields.FortiPortal_Customer_Name__c.value;
            // if (this.FortiPortal_Customer_Name === "spark.co.nz" && this.isFilteringPortalUser === true){
            if (this.isFilteringPortalUser === true){
                this.ToggleShowTakeMeThere();
            } else {
                this.checkRequestAccessPrerequisite();
            }
            this.isloading = false;
        }
    }

    // ---------------------------- UI control ----------------------------
    get showSignUpButton(){
        return (this.email === undefined || this.showSignUp === true ? true : false);
    }

    get showTakeMeThereButton(){
        return this.isFilteringPortalUser;
    }

    get showRequestAccessButton(){
        return this.showRequestAccess;
    }

    get showForbidRequestAccessReason(){
        return this.showForbidRequestAccess;
    }

    ToggleShowTakeMeThere() {
        this.showSignUp = false;
        this.showTakeMeThere = true;
        this.showRequestAccess = false;
        this.showForbidRequestAccess = false;        
    }

    ToggleShowRequestAccess() {
        this.showSignUp = false;
        this.showTakeMeThere = false;
        this.showRequestAccess = true;
        this.showForbidRequestAccess = false;
    }

    ToggleForbidRequestAccess() {
        this.showSignUp = true; //give instructions to sign up when showForbidRequestAccess = true
        this.showTakeMeThere = false;
        this.showRequestAccess = false;
        this.showForbidRequestAccess = true; 
    }

    handleCheckboxChange(event) {
        this.IsRequestAccessDisabled = !event.target.checked;
    }
    // ---------------------------- UI control ----------------------------

    // ---------------------------- Sign In Sign Up ----------------------------
    get signInUrl(){
        if (resolveSupportHubEnvironment() === "production"){
             return './login/?startURL=%2Fs%2Ffiltering-portal';
        }
        return './login/?startURL=%2Fschoolictsupport%2Fs%2Ffiltering-portal';
    }

    get signUpUrl(){
        if (resolveSupportHubEnvironment() === "production"){
             return 'https://support.n4l.co.nz/SupportHubSignUp';
        }
        return `${partialURL(true)}SupportHubSignUp`;
    }

    

    navigateToSupportHubSignUp() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                pageName: 'SupportHubSignUp'
            }
        });
    }
    

    // ---------------------------- Request Access Prerequisite ----------------------------
    checkRequestAccessPrerequisite(){
        this.isLoading = true; //start spinner
        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            REQUEST_ACCESS_PREREQUISITE({ productName: this.p , userId: USER_ID})
                .then(result => {
                    this.response = JSON.parse(result); //result is json string
                    console.log('checkRequestAccessPrerequisite() JSON.stringify(this.response): ', JSON.stringify(this.response));
                    this.error = undefined;

                    console.log(this.response.statusCode);
                    if (this.response.statusCode === 200){
                        this.ToggleShowRequestAccess();
                    }
                    if (this.response.statusCode === 400){
                        this.ToggleForbidRequestAccess();
                        this.prerequisiteEmail = this.response.email; //json object.element response.email comes from Apex methodresponse: request_access_prerequisite
                        this.prerequisiteDomain = this.response.domain;//json object.element response.domain comes from Apex methodresponse: request_access_prerequisite
                    }
                    if (this.response.statusCode === 401){
                        //UNAUTHORIZED: this school has not signed up for filtering portal yet. Do not let them sign up
                        this.message1 = 'Register your interest';
                        this.message2 = 'To register your interest, please email our Helpdesk team at support@n4l.co.nz or give them a call them on 0800 LEARNING.'
                        this.showMessage = true; 
                        this.showSignUp = false;
                        this.showTakeMeThere = false;
                        this.showRequestAccess = false;
                        this.showForbidRequestAccess = false; 
                    }
                    this.isLoading = false; //stop spinner
                })
                .catch(error => {
                    this.error = error;
                    this.response = undefined;
                    this.isLoading = false; //stop spinner
                });
        }, DELAY);
        
    }
    // ---------------------------- Request Access Prerequisite ----------------------------
    
    // ---------------------------- Request Access ----------------------------
    handleRequestAccess(){
        this.IsRequestAccessDisabled = true;
        this.isLoading = true; //start spinner
        console.log('handleRequestAccess() partialURL(): ' , partialURL());
        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            REQUEST_ACCESS({ productName: this.p , userId: USER_ID, partialURL: partialURL()})
                .then(result => {
                    this.response = JSON.parse(result); //result is json string
                    console.log('handleRequestAccess() JSON.stringify(this.response): ', JSON.stringify(this.response));
                    this.error = undefined;
                    if (this.response.statusCode === 200){
                        console.log(this.response.statusCode);
                        console.log('navigate to: ',  `${partialURL()}request-authorisation?m=filtering-portal-request-received`);
                        this.navigateToWebPage_toShowOnScreenMessage(`${partialURL()}request-authorisation?m=filtering-portal-request-received`);
                        
                        //temporary solution
                        this.message1 = 'Thanks! We’ve received your request';
                        this.message2 = 'We’ve sent an email to the Principal to make sure that they’re happy for you to use the Filtering Portal - as there are some risks and responsibilities involved that they need to be aware of.';
                        this.showRequestAccess = false;
                        this.showMessage = true; 
                        //temporary solution
                    }
                    if (this.response.statusCode >= 400){
                        console.log(this.response.statusCode);
                        console.log('navigate to: ',  `${partialURL()}request-authorisation?m=request-error`);
                        this.navigateToWebPage_toShowOnScreenMessage(`${partialURL()}request-authorisation?m=request-error`);
                    }
                    this.isLoading = false; //stop spinner: must be inside .then()
                })
                .catch(error => {
                    console.log('handleRequestAccess() error(): ' , error);
                    this.error = error;
                    this.response = undefined;
                });
        }, DELAY);
    }
    
    get displayResponse(){
        //console.log('in displayResponse() this.response', this.response)
        return JSON.stringify(this.response);
    }

            
    navigateToWebPage_toShowOnScreenMessage(toURL) {
        // Navigate to a URL
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: toURL
            }
        },
        true // Replaces the current page in your browser history with the URL
      );
    }

    // ---------------------------- Request Access ----------------------------

    
    
}