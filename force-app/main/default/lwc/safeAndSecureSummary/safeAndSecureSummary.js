// wireGetRecordDynamicaccount.js
import { LightningElement, api, wire, track } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'; // import toast message event .
import { getRecord } from 'lightning/uiRecordApi';


export default class SafeAndSecureSummary extends LightningElement {
    @api recordId;
    
}