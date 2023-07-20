/* eslint-disable no-console */
import { LightningElement, wire, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import TYPE_FIELD from '@salesforce/schema/Account.Waiver_Default_Categories__c';
//import TYPE_FIELD from '@salesforce/schema/Account.Type';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class picklistValues extends LightningElement {
    version = '8';

    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    objectInfo;

    @track picklistValues;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: TYPE_FIELD
    })
    picklistValues;


    get displaypicklistvalue() {
        return JSON.stringify(this.picklistValues);
    }

    connectedCallback() {
        Promise.all([
            this.initializeUnselectedValue(this.picklistValues)
        ])
            .then(() => {
                
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading Picklist Value',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });

    }

    @track displaypicklistvalue2;
    initializeUnselectedValue(obj) {
        var unselectedValues = [];
        var selectedValues = ['Discrimination', 'Phishing', 'Spam URLs'];
        if (obj.data) { //Defensive programming! to prevent obj.data being 'undefined' because, there could be delayed when the page is loaded. Api may not be able to immediately.
            obj.data.values.forEach(function (data) {
                if (selectedValues.findIndex((item) => item === data.value) < 0) {
                    unselectedValues.push(data.value);

                }
            });
        }
        this.displaypicklistvalue2 = unselectedValues;

    }
    
        

        
    



}