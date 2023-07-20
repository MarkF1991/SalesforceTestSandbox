import { LightningElement, api, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'; // import toast message event .

import approveOrder1 from '@salesforce/apex/OrderController.approveOrder1';
import approveOrder2 from '@salesforce/apex/OrderController.approveOrder2';
import CancelOrder from '@salesforce/apex/OrderController.cancelOrder';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import ORDER_ACCOUNTID_FIELD from '@salesforce/schema/Order.AccountId';
import ORDER_OWNERID_FIELD from '@salesforce/schema/Order.OwnerId'
import ORDER_STATUS_FIELD from '@salesforce/schema/Order.Status';

import ORDER_COMPANYAUTHORIZEDBYID_FIELD from '@salesforce/schema/Order.CompanyAuthorizedById';
import ORDER_COMPANYAUTHORIZEDDATE_FIELD from '@salesforce/schema/Order.CompanyAuthorizedDate';
import ORDER_PROVIDERID_FIELD from '@salesforce/schema/Order.Provider__c';
import ORDER_PROVIDER_BILLING_CONTACTID_FIELD from '@salesforce/schema/Order.Provider__r.Billing_Contact__c';
import ORDER_PROVIDER_BILLING_CONTACT_EMAIL_FIELD from '@salesforce/schema/Order.Provider__r.Billing_Contact__r.Email';
import ORDER_PLANNED_INSTALL_DATE_FIELD from '@salesforce/schema/Order.Planned_Install_Date__c';
import ORDER_EARLIEST_DELIVERY_DATE_FIELD from '@salesforce/schema/Order.Earliest_Delivery_Date__c';
import ORDER_LATEST_DELIVERY_DATE_FIELD from '@salesforce/schema/Order.Latest_Delivery_Date__c';
//import ORDER_UUID_FIELD from '@salesforce/schema/Order.uuid__c';
import ORDER_PoNumber_FIELD from '@salesforce/schema/Order.PoNumber';
import ORDER_EQUIPMENT_RETURNS_NOT_REQUIRED from '@salesforce/schema/Order.Equipment_Returns_not_required__c';
import ORDER_RELINQUISHED_EQUIPMENT_RETURN_TO from '@salesforce/schema/Order.ReturnTo__c';
import ORDER_CONTRACT_STATUS_FIELD from '@salesforce/schema/Order.Contract.Status';
import ORDER_TYPE_FIELD from '@salesforce/schema/Order.Type';
import ORDER_PoDate_FIELD from '@salesforce/schema/Order.PoDate';
import ORDER_ORDERITEM_COUNT_FIELD from '@salesforce/schema/Order.OrderItemsCount__c';
import ORDER_ICT_Date_onsite_FIELD from '@salesforce/schema/Order.Case__r.ICT_Date_onsite__c';
import ICT_ONSITE_DATE from '@salesforce/schema/Order.ICT_Onsite_Date__c';




const ORDER_FIELDS = [ORDER_ACCOUNTID_FIELD, ORDER_OWNERID_FIELD, ORDER_STATUS_FIELD, ORDER_PoNumber_FIELD, ORDER_COMPANYAUTHORIZEDBYID_FIELD, ORDER_COMPANYAUTHORIZEDDATE_FIELD, ORDER_PROVIDERID_FIELD, ICT_ONSITE_DATE, ORDER_PROVIDER_BILLING_CONTACTID_FIELD, ORDER_PROVIDER_BILLING_CONTACT_EMAIL_FIELD, ORDER_PLANNED_INSTALL_DATE_FIELD, ORDER_EARLIEST_DELIVERY_DATE_FIELD, ORDER_LATEST_DELIVERY_DATE_FIELD, ORDER_EQUIPMENT_RETURNS_NOT_REQUIRED, ORDER_RELINQUISHED_EQUIPMENT_RETURN_TO, ORDER_CONTRACT_STATUS_FIELD, ORDER_TYPE_FIELD, ORDER_PoDate_FIELD, ORDER_ORDERITEM_COUNT_FIELD, ORDER_ICT_Date_onsite_FIELD];
//Missed , ORDER_UUID_FIELD
//const ORDER_FIELDS = [ORDER_ACCOUNTID_FIELD, ORDER_OWNERID_FIELD, ORDER_STATUS_FIELD, ORDER_PROVIDERID_FIELD];

/** The delay used when debouncing event handlers before invoking Apex. */
const DELAY = 350;


export default class ApproveOrder extends LightningElement {
    @api recordId;    
    @api title = 'Order Approval';
    @api description = '';
    @api currentContactId;
    
 
    options;
    currentContactElement;
 
    error;
    messageTitle = '';
    messageDescription1 = '';
    messageDescription2 = '';
    isLoading = false; //remember to put it back to true when retrieving data.
    
    modal = {header: '',
                    id: '',
                    elements: [], 
                    mode: '', 
                    cancelButtonName: '',
                    submitButtonName: '',
                    confirmationMessage: '',
                    confirmationMessage2: ''
                    };

    //get order record
    @wire(getRecord, { recordId: '$recordId', fields: ORDER_FIELDS })
    order;
    
    get showOrderFields(){
        //return (this.orderFields.length > 0);
        return false;
    }
    get orderFields() {
        
     let displayFieldValues = [];
     displayFieldValues.push('ORDER_COMPANYAUTHORIZEDBYID_FIELD :' + getFieldValue(this.order.data, ORDER_COMPANYAUTHORIZEDBYID_FIELD));
     displayFieldValues.push('ORDER_COMPANYAUTHORIZEDDATE_FIELD :' + getFieldValue(this.order.data, ORDER_COMPANYAUTHORIZEDDATE_FIELD));
     displayFieldValues.push('provider :' + getFieldValue(this.order.data, ORDER_PROVIDERID_FIELD));
     displayFieldValues.push('billingContact :' + getFieldValue(this.order.data, ORDER_PROVIDER_BILLING_CONTACTID_FIELD));
     displayFieldValues.push('billingContactEmail :' + getFieldValue(this.order.data, ORDER_PROVIDER_BILLING_CONTACT_EMAIL_FIELD));
     displayFieldValues.push('ORDER_PLANNED_INSTALL_DATE_FIELD :' + getFieldValue(this.order.data, ORDER_PLANNED_INSTALL_DATE_FIELD));
     //displayFieldValues.push('ORDER_UUID_FIELD :' + getFieldValue(this.order.data, ORDER_UUID_FIELD));
     displayFieldValues.push('ORDER_PoNumber_FIELD :' + getFieldValue(this.order.data, ORDER_PoNumber_FIELD));

     return displayFieldValues;
     }
 
     
     
  isSuccess = false;
  response;
  response1;
  response2;
  goodResults = [];
  badResults = [];

  handleApproveOrder(){
     //validate fields in order record before starting Xero and NMS integrations
     this.validateTheOrder();
 
     if(!this.showOrderValidationErrors){
         this.isLoading = true; //start spinner
    
         window.clearTimeout(this.delayTimeout);
         // eslint-disable-next-line @lwc/lwc/no-async-operation
         this.delayTimeout = setTimeout(() => {
             //this.approveTheOrder();
             this.approveTheOrderPart1();
             
         }, DELAY);

        //  this.delayTimeout = setTimeout(() => {
        //  console.log('just finished part 1');
        //      console.log('about to do part2. this.isSuccess should be = true :', this.isSuccess);
        //      if(this.isSuccess){
        //         console.log('in this.isSuccess = true line 263');
        //          this.approveTheOrderPart2();
        //      }
        //     }, DELAY);

     }
   }

   handleCancelOrder(){

        this.modal.header = 'Cancel Order';
        this.modal.id = this.recordId;
        this.modal.elements = [];
        this.modal.mode = 'ToCancelOrder';
        this.modal.cancelButtonName = 'No';
        this.modal.submitButtonName = 'Yes';
        this.modal.confirmationMessage = 'Are you sure you want to cancel this order?';
        this.modal.confirmationMessage2 = '';
                   
        const modal = this.template.querySelector('c-modal');
        modal.show();
   }

   handleproceedToCancelOrder(){
    CancelOrder({ orderId: this.recordId})
    .then(result => {
        this.response = JSON.parse(result.response); //result is json string
        // this.messageDescription1 = JSON.stringify(this.response);
        
        this.error = undefined;
        if (this.response.statusCode === 200){
            //this.isSuccess = true;
            //console.log('part1 this.isSuccess should be = true :', this.isSuccess);
            console.log('>>>>>>>>>>> in CancelOrder() 200! ');
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.title,
                    message: 'Order now has Canceled',
                    variant: 'success'
                })

            );
        }
        if (this.response.statusCode >= 400){
            //this.isSuccess = false;
            //console.log('part1 this.isSuccess should be = false :', this.isSuccess);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Cancel Order failed ',
                    message: this.response.message,
                    variant: 'error'
                })
            );

        }
        this.isLoading = false; //stop spinner: must be inside .then()

    })

    
   }
 
   get CancelButtonDisabled(){
        if(getFieldValue(this.order.data, ORDER_PoNumber_FIELD)){
            return !(getFieldValue(this.order.data, ORDER_PoNumber_FIELD) !== ''); //if PoNumber !==Null, return disabled = false
        }
        return true;
}

 
   get showOrderValidationErrors(){
     return (this.orderValidationErrors.length > 0);
     }
 
   orderValidationErrors = [];
 
   validateTheOrder(){
     this.response = undefined;
     this.orderValidationErrors = [];
 
     if(!getFieldValue(this.order.data, ORDER_COMPANYAUTHORIZEDBYID_FIELD)){
         this.orderValidationErrors.push('Order must be have a value in Company Authorized By field');
     }
     if(!getFieldValue(this.order.data, ORDER_COMPANYAUTHORIZEDDATE_FIELD)){
         this.orderValidationErrors.push('Order must have a valid Company Authorized Date');
     }
     if(!getFieldValue(this.order.data, ORDER_PROVIDERID_FIELD)){
         this.orderValidationErrors.push('Order must have a valid provider');
     }
     if(!getFieldValue(this.order.data, ORDER_PROVIDER_BILLING_CONTACTID_FIELD)){
         this.orderValidationErrors.push('Order Provider must have a Billing Contact');
     }
     if(!getFieldValue(this.order.data, ORDER_PROVIDER_BILLING_CONTACT_EMAIL_FIELD)){
         this.orderValidationErrors.push('Order Provider Billing Contact must have a valid Email address');
     }

     //MNTC-566 changes on planned install date and earlist and latest delivery date VALIDATION
     const orderType = getFieldValue(this.order.data, ORDER_TYPE_FIELD);

    //  if(!getFieldValue(this.order.data, ORDER_PLANNED_INSTALL_DATE_FIELD) && orderType !=='Equipment - RMA' && orderType !=='Equipment - DOA' && orderType !=='Equipment - Equipment Only' && orderType !=='Software - License'){
    //      this.orderValidationErrors.push('Order must have a valid Planned Install Date');
    //  }else if(new Date() > new Date(getFieldValue(this.order.data, ORDER_PLANNED_INSTALL_DATE_FIELD)) && orderType !=='SOW - ICT' && orderType !=='Equipment - RMA' && orderType !=='Equipment - DOA' && orderType !=='Equipment - Equipment Only' && orderType !=='Support - License') {
    //     this.orderValidationErrors.push('Planned Install Date must be greater than current date');
    //  }
    
    // if(orderType !=='SOW - Installer' && orderType !=='SOW - ICT'){
    //  if(getFieldValue(this.order.data, ORDER_EARLIEST_DELIVERY_DATE_FIELD)){
    //      //this.orderValidationErrors.push('Order must have a valid Earliest Delivery Date');
    //      if(new Date() > new Date(getFieldValue(this.order.data, ORDER_EARLIEST_DELIVERY_DATE_FIELD))) {
    //         this.orderValidationErrors.push('Earliest Delivery Date must be greater than current date');
    //  }
    //  }
    // }

    //ITS-894
    if(!getFieldValue(this.order.data, ICT_ONSITE_DATE) && orderType ==='SOW 2 - ICT' || (orderType ==='SOW 2 - ICT' && new Date() > new Date(getFieldValue(this.order.data, ORDER_ICT_Date_onsite_FIELD)))){
     
            this.orderValidationErrors.push('Order must have a valid ICT onsite date');
   
    }
    

    if(orderType !=='SOW - Installer' && orderType !=='SOW - ICT' && orderType !=='SOW 1 - ICT' && orderType !=='SOW 2 - ICT' && orderType !=='Variation' && orderType !=='Equipment - Equipment Only' && orderType !=='Complex MAC'){
        if(!getFieldValue(this.order.data, ORDER_EARLIEST_DELIVERY_DATE_FIELD)){
            this.orderValidationErrors.push('Order must have a valid Earliest Delivery Date');
        } else if(new Date() > new Date(getFieldValue(this.order.data, ORDER_EARLIEST_DELIVERY_DATE_FIELD))) {
               this.orderValidationErrors.push('Earliest Delivery Date must be greater than current date');
        }
    }
       
    // if(orderType !=='SOW - Installer' && orderType !=='SOW - ICT'){
    //  if(getFieldValue(this.order.data, ORDER_LATEST_DELIVERY_DATE_FIELD)){
    //      //this.orderValidationErrors.push('Order must have a valid Latest Delivery Date');
    //      if(new Date() > new Date(getFieldValue(this.order.data, ORDER_LATEST_DELIVERY_DATE_FIELD))) {
    //         this.orderValidationErrors.push('Latest Delivery Date must be greater than current date');
    //     }else if(new Date(getFieldValue(this.order.data, ORDER_LATEST_DELIVERY_DATE_FIELD)) < new Date(getFieldValue(this.order.data, ORDER_EARLIEST_DELIVERY_DATE_FIELD))) {
    //        this.orderValidationErrors.push('Latest Delivery Date must be greater than Earliest Delivery Date');
    //     }
    //  }
    // } 

    if(orderType !=='SOW - Installer' && orderType !=='SOW - ICT' && orderType !=='SOW 1 - ICT' && orderType !=='SOW 2 - ICT' && orderType !=='Variation' && orderType !=='Equipment - Equipment Only' && orderType !=='Complex MAC'){
        if(!getFieldValue(this.order.data, ORDER_LATEST_DELIVERY_DATE_FIELD)){
            this.orderValidationErrors.push('Order must have a valid Latest Delivery Date');
        } else if(new Date() > new Date(getFieldValue(this.order.data, ORDER_LATEST_DELIVERY_DATE_FIELD))) {
               this.orderValidationErrors.push('Latest Delivery Date must be greater than current date');
           }else if(new Date(getFieldValue(this.order.data, ORDER_LATEST_DELIVERY_DATE_FIELD)) < new Date(getFieldValue(this.order.data, ORDER_EARLIEST_DELIVERY_DATE_FIELD))) {
              this.orderValidationErrors.push('Latest Delivery Date must be greater than Earliest Delivery Date');
           }
        }
       


     //if(!getFieldValue(this.order.data, ORDER_UUID_FIELD)){
     //    this.orderValidationErrors.push('Order must have a valid uuid of Network Design');
    // }
    if(getFieldValue(this.order.data, ORDER_TYPE_FIELD) ==='Equipment - New' || getFieldValue(this.order.data, ORDER_TYPE_FIELD) ==='Equipment - RMA' || getFieldValue(this.order.data, ORDER_TYPE_FIELD) ==='Equipment - DOA'){
        //if(getFieldValue(this.order.data, ORDER_TYPE_FIELD).includes("Equipment")){
    if(!getFieldValue(this.order.data, ORDER_EQUIPMENT_RETURNS_NOT_REQUIRED) && !getFieldValue(this.order.data, ORDER_RELINQUISHED_EQUIPMENT_RETURN_TO)){
             this.orderValidationErrors.push('Please specify a valid organisation in the field Relinquished Equipment Return to');
     }
    }
    if(getFieldValue(this.order.data, ORDER_CONTRACT_STATUS_FIELD) !== 'Activated' && orderType =='Equipment - New'){
        this.orderValidationErrors.push('Order must have an activated contract');
    }

    //if(getFieldValue(this.order.data, ORDER_PoNumber_FIELD) !== null || getFieldValue(this.order.data, ORDER_PoDate_FIELD) !== null){
    //    this.orderValidationErrors.push('This order has been approved, so you cannot approve it again');
    //}

    if(getFieldValue(this.order.data, ORDER_STATUS_FIELD) !== 'Draft'){
            this.orderValidationErrors.push('This order has been approved, so you cannot approve it again');
    }

    if(getFieldValue(this.order.data, ORDER_ORDERITEM_COUNT_FIELD) === 0){
        this.orderValidationErrors.push('Order must have a product');
    }
    
    // if((!getFieldValue(this.order.data, ORDER_ICT_Date_onsite_FIELD) && (getFieldValue(this.order.data, ORDER_TYPE_FIELD) =='SOW - ICT' || getFieldValue(this.order.data, ORDER_TYPE_FIELD) =='SOW 1 - ICT' ||
    // getFieldValue(this.order.data, ORDER_TYPE_FIELD) =='SOW 2 - ICT' || getFieldValue(this.order.data, ORDER_TYPE_FIELD) =='Variation')) || (getFieldValue(this.order.data, ORDER_TYPE_FIELD) =='SOW - ICT' || getFieldValue(this.order.data, ORDER_TYPE_FIELD) =='SOW 1 - ICT' ||
    // getFieldValue(this.order.data, ORDER_TYPE_FIELD) =='SOW 2 - ICT' || getFieldValue(this.order.data, ORDER_TYPE_FIELD) =='Variation') && new Date() > new Date(getFieldValue(this.order.data, ORDER_ICT_Date_onsite_FIELD))){
    //     this.orderValidationErrors.push('Order must have a valid date for ICT Date Onsite');
    // }
 
   }
 
   get showOrderApprovalResults(){
     if(this.response1)  {
        if (this.response1.statusCode === 200) { //do not show success message on LWC NP-972.
            return false;
        }
        //return (this.response1.results.length > 0);
        return (this.response1.messages.length > 0);
     }
     return false;
   }

   get orderApprovalResults(){
       let result = [];
       if(this.response1){
        //result.push(this.response1.results);
        result.push(this.response1.messages);
       }
       if(this.response2){
        //result.push(this.response2.results);
        result.push(this.response2.messages);
       }
       
       return result;
       
       //return this.response.results;
   }
 
   get orderApprovalResultClass(){
     if (this.response1.statusCode === 200){
         return "slds-text-color_success";
     }
     return "slds-text-color_error";
   }

   get showGoodResults(){
    return (this.goodResults);
  }
 
  get showBadResults(){
    return (this.badResults);
  }
   
    
   approveTheOrderPart1(){
     //window.clearTimeout(this.delayTimeout);
     // eslint-disable-next-line @lwc/lwc/no-async-operation
     //this.delayTimeout = setTimeout(() => {
 
         // this.messageTitle = 'Response from Network Design callout';
         approveOrder1({ orderId: this.recordId})
             .then(result => {
                 this.response1 = JSON.parse(result.response); //result is json string
                 // this.messageDescription1 = JSON.stringify(this.response);
                 
                 this.error = undefined;
                 if (this.response1.statusCode === 200){
                     //this.isSuccess = true;
                     //console.log('part1 this.isSuccess should be = true :', this.isSuccess);
                     console.log('>>>>>>>>>>> in approveOrder() 200! ');
                     this.dispatchEvent(
                         new ShowToastEvent({
                             title: this.title,
                             message: 'Order now has PO Number',
                             variant: 'success'
                         })
 
                     );
                 }
                 if (this.response1.statusCode >= 400){
                     //this.isSuccess = false;
                     //console.log('part1 this.isSuccess should be = false :', this.isSuccess);
                     this.dispatchEvent(
                         new ShowToastEvent({
                             title: 'Order approval failed ',
                             message: this.response1.message,
                             variant: 'error'
                         })
                     );
 
                 }
                 this.isLoading = false; //stop spinner: must be inside .then()
                //  this.isSuccess = (this.response1.statusCode === 200);
                //  console.log('part1 this.isSuccess should be = true :', this.isSuccess);
             // }).then(result => {
             //     approveOrder2({ orderId: this.recordId});
             }).then(result => {
                 console.log('.then approach here... its running');
             if(this.response1.statusCode === 200){
                console.log('in .then.... this.isSuccess = true line 432: about to run Part2');
                 this.approveTheOrderPart2();
             }
            

             })
             .catch(error => {
                console.log('part1 .catch error :', error);
                 this.error = error;
                 this.response1 = undefined;
                 this.dispatchEvent(
                     new ShowToastEvent({
                         title: 'Error in Order Approval',
                         message: error.message,
                         variant: 'error'
                     })
                 );
             });
     //}, DELAY);
   }
 
   approveTheOrderPart2(){
     //window.clearTimeout(this.delayTimeout);
     // eslint-disable-next-line @lwc/lwc/no-async-operation
     //this.delayTimeout = setTimeout(() => {
 
         // this.messageTitle = 'Response from Network Design callout';
         approveOrder2({ orderId: this.recordId})
             .then(result => {
                 this.response2 = JSON.parse(result.response); //result is json string
                 // this.messageDescription1 = JSON.stringify(this.response2);
                 console.log('in part 2 this.response2 =  :', this.response2);
                 this.error = undefined;
                 if (this.response2.statusCode === 200){
                     console.log('>>>>>>>>>>> in part2 approveOrder() 200! ');
                     this.dispatchEvent(
                         new ShowToastEvent({
                             title: this.title,
                             message: 'Order has been approved and email has been sent',
                             variant: 'success'
                         })
 
                     );
                 }
                 if (this.response2.statusCode >= 400){
                     this.dispatchEvent(
                         new ShowToastEvent({
                             title: 'Order approval failed ',
                             message: this.response2.message,
                             variant: 'error'
                         })
                     );
                     this.orderValidationErrors.push(this.response2.messages);
                 }
                 this.isLoading = false; //stop spinner: must be inside .then()
                 
                // if (this.response2.statusCode === 200){
                //     setTimeout(() => {
                //                             location.reload();
                //     }, 3000); //delay for 2 seconds
                // }
                
             // }).then(result => {
             //     approveOrder2({ orderId: this.recordId});
             })
             .catch(error => {
                 this.error = error;
                 this.response2 = undefined;
                 this.dispatchEvent(
                     new ShowToastEvent({
                         title: 'Error in Order Approval',
                         message: error.message,
                         variant: 'error'
                     })
                 );
             });
     //}, DELAY);
   }
 }