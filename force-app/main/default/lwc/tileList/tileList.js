import { LightningElement, api } from "lwc";
import { fireEvent } from 'c/pubsub';
import {
  getIdFromTarget
} from "c/utilitiesFunction";

export default class TileList extends LightningElement {
  @api isLoading;

  //input
  @api param;
  @api items = [];

  @api iconName;
  @api header;
  @api footer;
  @api context = 'device';
  pageRef  = { attributes: { name: "nav" } };

  get iconClass(){
      return `slds-icon_container ${this.context}`;
  }

  notifyClick(event) {
    let itemId = getIdFromTarget(event.target.id);
    let data = this.items.find((item) => item.id === itemId);
    let route = data.route;
    let path = data.path;
    if(itemId && data) {
      this.sendAnalyticsEvent('Widget', 'viewitem', this.header);
      let nav = null;
      if(route && route.page) {
        nav = { route: route.page, args: { params: route.params } };
      } else {
        nav = { route: path, args: { data: data, identifier: data.identifier ? data.identifier : itemId } }
      }
      fireEvent(this.pageRef, 'navigateToPage', nav);
    } else {
      // eslint-disable-next-line no-console
      console.log('click not registered', path, itemId);
    }
  }

  handleViewAllClick() {
    this.sendAnalyticsEvent('Widget', 'viewall', this.header);
    fireEvent(this.pageRef, 'navigateToPage', { route: this.footer.route, args: { params: this.footer.params } });
  }

  sendAnalyticsEvent(category, action, label) {
      // eslint-disable-next-line no-undef
      if(ga) {
          // eslint-disable-next-line no-undef
          ga('send', {
              hitType: 'event',
              eventCategory: category,
              eventAction: action,
              eventLabel: label
          });
      }
  }
}