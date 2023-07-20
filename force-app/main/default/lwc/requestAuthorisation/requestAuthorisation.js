import { LightningElement, track } from 'lwc';
import requestAuth from '@salesforce/apex/JWTController.request_authorisation';
import { getQueryParams, pushStateToUrl } from "c/communitiesNavigation";

import { NavigationMixin } from 'lightning/navigation';
import { partialURL, resolveSupportHubEnvironment } from "c/utilitiesURL";

/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;

export default class RequestAuthorisation extends NavigationMixin(LightningElement) {
    @track isLoading = false;
    @track p = ''; //url parameter - product name
    @track t = ''; //url parameter - token
    @track m = ''; //url parameter - mode
    @track camid = ''; //url parameter - delegate camgaign id
    @track accid = ''; //url parameter - delegate account id
    @track messageTitle = '';
    @track messageDescription1 = '';
    @track messageDescription2 = '';

    @track response = {};  //responsed from Apex method: {"statusCode":401,"status":"UNAUTHORIZED","request_authorisation":"Token Expired"}
    @track showApproved = false;
    @track showDeclined = false;
    @track showUnauthorised = false;
    @track showOnScreenMessage = false;
    @track showRedirectingMessage = false;
    @track showLink = false;

    connectedCallback() {
        this.queryParams = getQueryParams(window.location.search);
        this.p = this.queryParams.p;
        this.t = this.queryParams.t;
        this.m = this.queryParams.m;
        this.camid = this.queryParams.camid;
        this.accid = this.queryParams.accid;
        if (!this.p) {
            this.p = "filtering-portal";
        }
        if (!this.camid) {
            this.camid = "null";
        }
        if (!this.accid) {
            this.accid = "null";
        }
        if (this.p === 'delegate-completed') {
            this.showOnScreenMessage = true;
            this.messageTitle = 'Great!'
            this.messageDescription1 = 'An email has been sent to the person you delegated to.';

        }
        if (this.m) {
            this.showOnScreenMessage = true;
            if (this.m === 'filtering-portal-request-received') {
                this.messageTitle = 'Thanks! We’ve received your request';
                this.messageDescription1 = 'We’ve sent an email to the Principal to make sure that they’re happy for you to use the Filtering Portal - as there are some risks and responsibilities involved that they need to be aware of.';
            }
            if (this.m === 'request-error') {
                this.messageTitle = 'Oh no! It looks like there’s been an error.'
                this.messageDescription1 = 'This could be because you don’t have access. Head over to Support Hub to find out more and to request access.';
                this.messageDescription2 = 'If you think it’s a different kind of error, give our Helpdesk team a call on 0800 LEARNING.';
            }

        } else if (this.p && this.t) {
            this.handleRequestAuth();
        }
    }

    handleRequestAuth() {
        window.clearTimeout(this.delayTimeout);
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            //requestAuth({ productName: 'filtering-portal' , token: this.input})
            requestAuth({ productName: this.p, token: this.t })
                .then(result => {
                    this.response = JSON.parse(result); //result is json string
                    console.log('handleRequestAuth() JSON.stringify(this.response): ', JSON.stringify(this.response));
                    this.error = undefined;

                    console.log(this.response.request_authorisation);
                    if (this.response.request_authorisation === 'approved') {
                        this.showOnScreenMessage = true;
                        this.messageTitle = 'Great! You’ve approved this user.'
                        this.messageDescription1 = 'We’ve sent an email to let them know that they can now access the Filtering Portal.';

                    } else if (this.response.request_authorisation === 'declined') {
                        this.showOnScreenMessage = true;
                        this.messageTitle = 'You’ve declined access for this user.'
                        this.messageDescription1 = 'We’ve sent an email to let them know. If at any time you’d like to change this decision, you can contact our Helpdesk team on 0800 LEARNING or email support@n4l.co.nz to let us know.';

                    } else if (this.response.request_authorisation === 'Token Expired') {
                        this.showOnScreenMessage = true;
                        this.messageTitle = 'Sorry! The link has expired.'
                        this.messageDescription1 = 'For security reasons the link expires after 7 days. Please contact N4L on 0800 LEARNING or support@N4L.co.nz to let the team know whether you approve or decline the user.';

                    } else if (this.response.request_authorisation === 'school contact update - confirm') {
                        this.showOnScreenMessage = true;
                        this.messageTitle = 'Thanks!'
                        this.messageDescription1 = 'Your school details have been confirmed as being up to date.';

                    } else if (this.response.request_authorisation === 'school contact update - confirmed') {
                        this.showOnScreenMessage = true;
                        this.showLink = true;
                        this.messageTitle = 'Previously completed'
                        this.messageDescription1 = 'It looks like you’ve already confirmed your school’s contact information. If you need to make any changes please click the link ';

                    } else if (this.response.request_authorisation === 'school contact update - no user yet') {
                        this.showOnScreenMessage = true;
                        this.messageTitle = 'Redirecting...'
                        //this.messageDescription1 = 'we are getting ready to create an N4L user account for you.';
                        //this.messageDescription2 = 'please allow pop-up and redirect from this page on your browser.';
                        this.messageDescription1 = '';
                        this.messageDescription2 = '';
                        //navigate_to_url gets it value from SupportHubUserSetupController.SchoolContactUpdate_Confirm_or_Update()
                        let toURL = this.supportHubVisualforcePageUrl(this.response.navigate_to_url);
                        console.log('toUrl =', toURL);
                        //this.navigateToWebPage_toDestination(toURL);
                        window.location.replace(toURL);

                    } else if (this.response.request_authorisation === 'school contact update - already has user') {
                        this.showOnScreenMessage = true;
                        this.messageTitle = 'Redirecting...'
                        //this.messageDescription1 = 'we are getting ready for you to manage your school contacts.';
                        //this.messageDescription2 = 'please allow pop-up and redirect from this page on your browser.';
                        this.messageDescription1 = '';
                        this.messageDescription2 = '';
                        //this.navigateToWebPage_toDestination(`${partialURL()}${this.response.navigate_to_url}`); //navigate_to_url gets it value from SupportHubUserSetupController.SchoolContactUpdate_Confirm_or_Update()
                        window.location.replace(`${partialURL()}${this.response.navigate_to_url}`);

                    } else if (this.response.request_authorisation === 'invite signup - no user yet') {
                        this.showOnScreenMessage = true;
                        this.messageTitle = 'Redirecting...'
                        //this.messageDescription1 = 'we are getting ready to create an N4L user account for you.';
                        //this.messageDescription2 = 'please allow pop-up and redirect from this page on your browser.';
                        this.messageDescription1 = '';
                        this.messageDescription2 = '';
                        //navigate_to_url gets it value from SupportHubUserSetupController.RespondedToCreateUserByInvitation()
                        let toURL = this.supportHubVisualforcePageUrl(this.response.navigate_to_url);
                        console.log('toUrl =', toURL);
                        //this.navigateToWebPage_toDestination(toURL);
                        window.location.replace(toURL);

                    } else if (this.response.request_authorisation === 'invite signup - already has user') {
                        this.showOnScreenMessage = true;
                        this.messageTitle = 'Redirecting...'
                        //this.messageDescription1 = 'welcome to Support Hub.';
                        //this.messageDescription2 = 'please allow pop-up and redirect from this page on your browser.';
                        this.messageDescription1 = '';
                        this.messageDescription2 = '';
                        //this.navigateToWebPage_toDestination(`${partialURL()}${this.response.navigate_to_url}`); //navigate_to_url gets it value from SupportHubUserSetupController.RespondedToCreateUserByInvitation()
                        window.location.replace(`${partialURL()}${this.response.navigate_to_url}`);
                    } else if (this.response.request_authorisation === 'school contact delegate') {
                        this.showOnScreenMessage = true;
                        this.messageTitle = 'Redirecting...'
                        this.messageDescription1 = '';
                        this.messageDescription2 = '';
                        //window.location.replace(`${partialURL(true)}${this.response.navigate_to_url}`);
                        //this.navigateToWebPage_toDestination(`${partialURL()}${this.response.navigate_to_url}`); //navigate_to_url gets it value from SupportHubUserSetupController.SchoolContactUpdate_Confirm_or_Update()
                        let toURL = this.supportHubVisualforcePageUrl(this.response.navigate_to_url + '&camid=' + this.camid + '&accid=' + this.accid);
                        console.log('toUrl =', toURL);
                        //this.navigateToWebPage_toDestination(toURL);
                        window.location.replace(toURL);
                    } else {
                        console.log('else....this.response.statusCode = ', this.response.statusCode);
                        this.showUnauthorised = ((this.response.statusCode >= 400) ? true : false);
                    }

                })
                .catch(error => {
                    this.error = error;
                    this.response = undefined;
                });
        }, DELAY);
    }

    get errorMessage() {
        return (this.response.request_authorisation ? this.response.request_authorisation : this.response.error)
    }

    supportHubVisualforcePageUrl(visualforcePageName_urlparam) {
        if (resolveSupportHubEnvironment() === "production") {
            return `https://support.n4l.co.nz/${visualforcePageName_urlparam}`;
        }
        return `${partialURL(true)}${visualforcePageName_urlparam}`;
    }

    navigateToWebPage_toDestination(toURL) {
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



}