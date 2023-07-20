import { LightningElement, track } from 'lwc';
import fetchDataHelper from './fetchDataHelper';

const columns = [
    { label: 'Label', fieldName: 'label' },
    { label: 'Value', fieldName: 'value', type: 'number' },
    { label: 'Units', fieldName: 'units' },
];

export default class contentDataTable extends LightningElement {
    @track data = [];
    @track columns = columns;
    @track tableLoadingState = true;
    @track url = 'https://boris.n4l.co.nz/n4l61baradenecoll-fw01/websites/1550314800/1550833200';

    async connectedCallback() {
        const data = await fetchDataHelper({ url: this.url });
        this.data = data.items;
        this.tableLoadingState = false;
    }
  


}