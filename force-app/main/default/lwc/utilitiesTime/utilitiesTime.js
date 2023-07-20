import { LightningElement, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import MOMENTJS from '@salesforce/resourceUrl/momentjs';
import { resolveEnvironment } from "c/utilitiesFunction";

export default class TimeElement extends LightningElement {
    isMomentInitialized = false;
    @track environment = null;

    initMoment() {
        if(!this.environment) {
            this.environment = resolveEnvironment();
        }
        
        try {
            // eslint-disable-next-line no-undef
            let t = moment();
            this.isMomentInitialized = !!t;
        // eslint-disable-next-line no-empty
        } catch(err) {}

        if(this.isMomentInitialized) {
            return Promise.resolve({});
        } 

        return Promise.all([
            loadScript(this, MOMENTJS + '/moment.min.js'),
            loadScript(this, MOMENTJS + '/en-nz.js'),
        // eslint-disable-next-line no-unused-vars
        ]).then((rs) => {
            this.isMomentInitialized = true;
        });
    }

    get now() {
        // eslint-disable-next-line no-undef
        return this.environment === "demo" ? moment("2019-07-27T13:17:09.959Z") : moment();
    }
}