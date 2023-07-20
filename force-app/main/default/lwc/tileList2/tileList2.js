import { LightningElement, api } from 'lwc';
import { iconName } from "c/utilitiesFunction";
import { fireEvent } from 'c/pubsub';
import {
  getIdFromTarget
} from "c/utilitiesFunction";

export default class SecurityInsightsRankedList extends LightningElement {
    @api isLoading = false;
    @api param;
    @api object;
    //input
    @api header;
    @api items = []; //items comes in an array of JSON objects
    @api alert; //alert comes in JSON object
    @api subject; //subject comes in string - just to show a grey subject on  top of a list of narrow tileItemObject
    @api disableItemLinks = false;
    @api context = 'security';
    @api cardLink;
    @api canNavigate = false;
    @api isNarrow = false;
    @api footer;

    @api get noData() {
      return this._noData;
    }

    set noData(val) {
      this._noData = val; 
    }

    pageRef  = { attributes: { name: "nav" } };

    get iconClass() {
      return `slds-icon_container ${this.context}`;
    }

    get cardIconName() {
        return iconName(this.context);
    }

    get cardTitle() {
      return this.header;
    }

    get getAlert() {
      return (this.object? this.object.alert : this.alert);
    }

    get showAlert() {
      return this.getAlert ? true : false;
    }

    get getSubject() {
      return (this.object? this.object.data.subject : this.subject);
    }

    get showSubject() {
      return this.getSubject ? true : false;
    }
    
    get getInformation() {
      return (this.object? this.object.data.information : null);
    }

    get showInformation() {
      return this.getInformation ? true : false;
    }

    get getItems() {
      return (this.object? this.object.data.items : this.items);
    }

    get cardClass() {
      return this.disableItemLinks ? "card slds-card__body highlight" : "card slds-card__body";
    }


    get tileItemClassFirst() {
      return (this.isNarrow ? 'highlight slds-p-horizontal_medium slds-p-vertical_x-small' : 'highlight slds-p-horizontal_medium slds-p-vertical_medium');
    }

    get tileItemClass() {
        return (this.isNarrow ? 'highlight slds-p-horizontal_medium slds-p-vertical_x-small' : 'highlight slds-p-horizontal_medium slds-p-vertical_medium listItem');
    }

    notifyClick(event) {
      let itemId = getIdFromTarget(event.target.id);
      let data = this.getItems.find((item) => item.id === itemId);
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