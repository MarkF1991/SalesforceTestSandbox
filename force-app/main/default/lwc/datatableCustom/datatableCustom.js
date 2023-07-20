import LightningDatatable from 'lightning/datatable';
import picklist from './picklist.html';
import navigate from './navigate.html';
import currency from './currency.html';

export default class DatatableCustom extends LightningDatatable {

    static customTypes = {
        picklist: {
            template: picklist,
            typeAttributes: ['value', 'context', 'options', 'fieldName'],
        },
        navigation: {
            template: navigate,
            typeAttributes: ['label', 'recordId'],
        },
        currencyColoured: {
            template: currency,
            typeAttributes: ['value']
        }
    };

}