import { LightningElement, api } from 'lwc';
import { fireEvent } from 'c/pubsub';
import { getIdFromTarget } from "c/utilitiesFunction";

export default class HorizontalTileList extends LightningElement {
    @api items = [];

    @api get noData() {
        return this._noData;
    }

    set noData(val) {
        this._noData = val; 
    }

    pageRef  = { attributes: { name: "nav" } };

    notifyClick(event) {
        let itemId = getIdFromTarget(event.target.id);

        let data = this.items.find((item) => item.id === itemId);
        let route = null;
        if(data) {
            route = data.path;
        }
        if(itemId && data) {
            fireEvent(this.pageRef, 'navigateToPage', { route: route, args: { data: data, identifier: data.identifier ? data.identifier : itemId } });
        } else {
            // eslint-disable-next-line no-console
            console.log('click not registered', route, itemId, data);
        }
    }
}