// wireGetRecordDynamicaccount.js
import { LightningElement, api, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import getContactList_RoleBased from '@salesforce/apex/ContactController.getContactList_RoleBased';
import getAccount from '@salesforce/apex/AccountController.getAccount';
import getNHRFeedbackResponses from '@salesforce/apex/AccountController.getNHRFeedbackResponses';
import getNSEFeedbackResponses from '@salesforce/apex/AccountController.getNSEFeedbackResponses';
import getEmailProtectionFeedbackResponses from '@salesforce/apex/AccountController.getEmailProtectionFeedbackResponses'
import get_IEM_ATP_Link_Responses from '@salesforce/apex/AccountController.get_IEM_ATP_Link_Responses';
import get_ICT_Providers from '@salesforce/apex/AccountController.get_ICT_Providers';
import get_ER_Opportunity_Id from '@salesforce/apex/AccountController.get_ER_Opportunity_Id'
export default class AccountLWC extends NavigationMixin(LightningElement){
   // Flexipage provides recordId and objectApiName
   @api recordId = '';// = '001N000001Q8e7dIAB';
   @api objectApiName = 'Account';

   @track contacts;
   @track accounts;
   @track event;
   @track nhrFeedbackResponseTime;
   @track nseFeedbackResponseTime;
   @track emailProtectionFeedbackResponseTime;
   @track iemATPlinkResponseTime;
   @track MOUReceivedDate;
   @track MOE_Id;
   @track selectButtonDisabled = true;
   @track displayIctProviders;
   @track EROpportunityId;

//    @track contacts = {
//     data: [
//         {
//             id: Math.random(),
//             Name: 'Sandy Pasley', 
//             Initial: 'SP',
//             BusinessRole: 'Principal',
//             Title: 'Principal',
//             // Picture__c: 'https://baradene.ibcdn.nz/media/2016_12_05_portrait-1.jpg',
//             //Picture: 'https://baradene.ibcdn.nz/media/2017_05_17_sp2017.jpg',
//             Picture: '/sfc/servlet.shepherd/version/download/068N0000001S3PLIA0',
//             IsShowInitial: false,
//             Phone: '03 443 0499',
//             Mobile: '021 816 332',
//             Email: 'principal@school.nz'
//             },
//             {
//             id: Math.random(),
//             Name: 'John Wayne', 
//             Initial: 'JW',
//             BusinessRole: 'ICT Leader',
//             Title: 'Business Manager',
//             Picture: null,
//             IsShowInitial: true,
//             Phone: '03 593 2851',
//             Mobile: '021 123 123',
//             Email: 'john@school.nz'
//             }
//     ]
// };

@wire(CurrentPageReference) pageRef; //afterRender threw an error in 'c:accountLWC' [pubsub listeners need a "@wire(CurrentPageReference) pageRef" property]

@wire(getContactList_RoleBased, { accountId: '$recordId' })
wiredContactList(value) {
    // Hold on to the provisioned value so we can refresh it later.
    this.wiredContacts = value; // track the provisioned value
    const { error, data } = value; // destructure the provisioned value
    if (data) {
        console.log('getContactList_RoleBased returns: ', data);
        this.contacts = data;
        //this.contacts = JSON.parse(data); //data is returned as string
        console.log('getContactList_RoleBased returns this.contacts stringify: ', JSON.stringify(this.contacts));
        // this.hasRecords = (this.contacts.length > 0);
        this.error = undefined;
    } else if (error) {
        this.error = error;
        this.contacts = undefined;
        // this.hasRecords = false;
    }
}

@wire(getAccount, { accountId: '$recordId' })
    wiredAccountList(value) {
        const { error, data } = value; // destructure the provisioned value
        if (data) {
            console.log('getContactList_RoleBased returns: ', data);
            this.accounts = data;
            this.MOUReceivedDate = this.accounts.CC_MOU_Received_Date__c;
            this.MOE_Id = this.accounts.MoE_School_ID__c;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.accounts = undefined;
            // this.hasRecords = false;
        }
    }

    //ITS - 892
    @wire(getNHRFeedbackResponses, { accountId: '$recordId' })
    wiredEventGetNHRFeedback(value) {
        const { error, data } = value; // destructure the provisioned value
        if (data) {
            console.log('getNHRFeedbackResponses returns: ', data);
            this.event = data;
            this.nhrFeedbackResponseTime = this.event.EndDateTime;
            console.log('>>>>>>>this.event'+JSON.stringify(this.event)+'>>>>>nhrFeedbackResponseTime:'+JSON.stringify(this.nhrFeedbackResponseTime));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.event = undefined;
            // this.hasRecords = false;
        }
    }

    @wire(getNSEFeedbackResponses, { accountId: '$recordId' })
    wiredEventGetNSEFeedback(value) {
        const { error, data } = value; // destructure the provisioned value
        if (data) {
            console.log('getNSEFeedbackResponses returns: ', data);
            this.event = data;
            this.nseFeedbackResponseTime = this.event.EndDateTime;
            console.log('>>>>>>>this.event'+JSON.stringify(this.event)+'>>>>>nseFeedbackResponseTime:'+JSON.stringify(this.nseFeedbackResponseTime));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.event = undefined;
            // this.hasRecords = false;
        }
    }

    //ATP for Email Protection 12/05/2022
    @wire(getEmailProtectionFeedbackResponses, { accountId: '$recordId' })
    wiredEventGetEmailProtectionFeedback(value) {
        const { error, data } = value; // destructure the provisioned value
        if (data) {
            console.log('getEmailProtectionFeedbackResponses returns: ', data);
            this.event = data;
            this.emailProtectionFeedbackResponseTime = this.event.EndDateTime;
            console.log('>>>>>>>this.event'+JSON.stringify(this.event)+'>>>>>emailProtectionFeedbackResponseTime:'+JSON.stringify(this.emailProtectionFeedbackResponseTime));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.event = undefined;
            // this.hasRecords = false;
        }
    }

    //ATP for Email Protection 13/10/2022
    @wire(get_IEM_ATP_Link_Responses, { accountId: '$recordId' })
    wiredEventGet_IEM_ATP_Link(value) {
        const { error, data } = value; // destructure the provisioned value
        if (data) {
            console.log('get_IEM_ATP_Link_Responses returns: ', data);
            this.event = data;
            this.iemATPlinkResponseTime = this.event.EndDateTime;
            console.log('>>>>>>>this.event'+JSON.stringify(this.event)+'>>>>>iemATPlinkResponseTime:'+JSON.stringify(this.iemATPlinkResponseTime));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.event = undefined;
            // this.hasRecords = false;
        }
    }

    //Get ICT providers 18/05/2023
    @wire(get_ICT_Providers, { accountId: '$recordId' })
    wiredget_ICT_Providers(value) {
        const { error, data } = value; // destructure the provisioned value
        if (data) {
            console.log('get_ICT_Providers returns: ', data);
            this.event = data;
            this.displayIctProviders = this.event;

            console.log('>>>>>>>this.displayIctProviders'+JSON.stringify(this.displayIctProviders));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.event = undefined;
            // this.hasRecords = false;
        }
    }

     //Get ER Opportunity for ATP Link 22/06/2023 (Carolyn Hayward - Micado)
     @wire(get_ER_Opportunity_Id, { accountId: '$recordId' })
     wiredget_Opportunity_Id(value) {
         const { error, data } = value; // destructure the provisioned value
         if (data) {
             console.log('ER Opportunity ID returns: ', data);
             this.event = data;
             this.EROpportunityId = this.event;
 
             console.log('>>>>>>>this.EROpportunityId'+JSON.stringify(this.EROpportunityId));
             this.error = undefined;
         } else if (error) {
             this.error = error;
             this.event = undefined;
         }
     }

connectedCallback() {
    // subscribe to AccountSelected event
    registerListener('accountSelected', this.handleAccountSelected, this);
}

disconnectedCallback() {
    // unsubscribe from AccountSelected event
    unregisterAllListeners(this);
}

get getFeedback_NHR_ATP_URL(){
        
    if (this.contacts) { //Defensive programming! to prevent obj.data being 'undefined' because, there could be delayed when the page is loaded. Api may not be able to immediately.
    //     let principal = this.contacts.find(item => item.Roles.toLowerCase() === 'principal');
    //     if (principal){
    //         let url = `https://n4l.getfeedback.com/r/7NB2tmBO?&gf_q[8346340][16623239]=${principal.Name}`;
    //         url += `&gf_q[8346340][16623240]=Principal`;
    //         url += `&SchoolName=${principal.Account.Name}`;
    //         url += `&MoE_ID=${principal.Account.MoE_School_ID__c}`;
    //         url += `&Account_ID=${principal.AccountId}`;
    //         url += `&Contact_ID=${principal.Id}`;
    //         return url;
    //     }
    // }

        //updated 22/06/2023 for new automated ATP process MNTC-1349
        if(this.contacts.principal && this.contacts.principal.length > 0){
            let principal = this.contacts.principal[0];
            let url = `https://n4l.getfeedback.com/r/7MfSZTPN?&gf_q[12495342][23899710]=${principal.Name}`;
                url += `&gf_q[12495342][23899711]=Principal`;
                url += `&gf_q[12495342][23899712]=${principal.Email}`;
                url += `&SchoolName=${this.accounts.Name}`;
                url += `&MoE_ID=${this.accounts.MoE_School_ID__c}`;
                url += `&Account_ID=${this.recordId}`;
                url += `&Contact_ID=${principal.Id}`;
                url += `&Opportunity_ID=${this.EROpportunityId}`;
            return url;
        }
    }

    return '#';
}

get getFeedback_NSE_ATP_URL(){
        
    if (this.contacts) { 
        if(this.contacts.principal && this.contacts.principal.length > 0){
            let principal = this.contacts.principal[0];
            let url = `https://n4l.getfeedback.com/r/75cKLckG?&gf_q[7792816][15611918]=${this.accounts.Name}`;
                url += `&gf_q[7792816][15611919]=Principal`;
                url += `&SchoolName=${this.accounts.Name}`;
                url += `&MoE_ID=${this.accounts.MoE_School_ID__c}`;
                url += `&Account_ID=${this.recordId}`;
                url += `&Contact_ID=${principal.Id}`;
            return url;
        }
    }

    return '#';
}

get getFeedback_EmailProtection_ATP_URL(){
        
    if (this.contacts) {
        if(this.contacts.principal && this.contacts.principal.length > 0){
            let principal = this.contacts.principal[0];
            let url = `https://n4l.getfeedback.com/r/ZFoyNEz4?`;
                url += `AccountId=${this.recordId}`;
                url += `&SchoolName=${this.accounts.Name}`;

            return url;
        }
    }

    return '#';
}

get getFeedback_IEM_ATP_URL(){
        
    if (this.contacts) {
        if(this.contacts.principal && this.contacts.principal.length > 0){
            let principal = this.contacts.principal[0];
            let url = `https://n4l.getfeedback.com/r/qeNp2Bya?`;
                url += `AccountId=${this.recordId}`;
                url += `&SchoolName=${this.accounts.Name}`;

            return url;
        }
    }

    return '#';
}

get educountURL(){
    return 'https://www.educationcounts.govt.nz/find-school/school/profile?school=' + this.MOE_Id;
}


handleAccountSelected(accountId) {
    this.recordId = accountId;
    this.selectButtonDisabled = false;
}
// handleAccountSelected(account) {
//     this.recordId = account.id;
// }

handleAccountClick(){
     // Navigate to Account record page
		this[NavigationMixin.Navigate]({
			type: 'standard__recordPage',
			attributes: {
				recordId: this.recordId,
				objectApiName: 'Account',
				actionName: 'view',
			},
		});
}
}