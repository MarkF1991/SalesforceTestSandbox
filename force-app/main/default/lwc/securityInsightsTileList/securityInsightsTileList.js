import { LightningElement, track, api } from "lwc";
import { TileItemClass, TileChipClass } from "c/utilitiesClass";
import { formatNumber, iconName, getIdFromTarget } from "c/utilitiesFunction";
import { fireEvent } from 'c/pubsub';

export default class securityInsightsTileList extends LightningElement {
  
  @api get object() {
    return this._object;
  }
  set object(val) {
    this._object = val;
    if(val) {
      this.items = this.build();
    }
  }

  pageRef  = { attributes: { name: "nav" } };

  @api param;
  @api isLoading;

  @track items = [];

  get cardIconName() {
    return iconName("security");
  }

  //output - fields mapping
  build() {
    var array = [];
    var item1 = TileItemClass();
    var item2 = TileItemClass();
    if (this.object && this.param) {
      const deviceInfection = this.object.data.deviceInfection;
      const attackCount = this.object.data.attackCount;

      //top user by browsing time
      item1.id = '1001';
      item1.identifier = this.getDeviceLabel(deviceInfection.deviceTypes);
      item1.title = "Top Infection by Devices Infected";
      item1.value = deviceInfection.value;
      item1.unit = "";
      item1.path = `infections-list-view`;
      item1.chip.label = this.getDeviceLabel(deviceInfection.deviceTypes);
      item1.chip.description = deviceInfection.category;
      item1.chip.image.type = "icon";
      item1.chip.image.name = iconName(deviceInfection.category);
      item1.chip.image.class = "security"; //fixed as user - this will affect class to render colour based on tileChip.css

      //top user by Bandwidth Usage
      item2.id = '1002';
      item2.identifier = attackCount.label;
      item2.title = "Top Attack by Attack Count";
      item2.value = formatNumber(attackCount.value); //display number with , seperator
      item2.unit = "";
      item2.path = `attacks-list-view`;
      item2.chip.label = attackCount.label;
      item2.chip.description = attackCount.description;
      item2.chip.image.type = "icon";
      item2.chip.image.name = iconName("attack");
      item2.chip.image.class = "security";

      array.push(item1);
      array.push(item2);
    }

    return array;
  }

  get alertContent() {
    var alert = TileChipClass();
    if (this.object) {
      const securityAlert = this.object.data.securityAlert;
      let isAlert = securityAlert.value > 0;
      alert.label = securityAlert.value > 0 ? `${securityAlert.value} infected devices have been found` : 'All Clear';
      alert.description = "";
      alert.image.type = "icon";
      alert.image.name = iconName(isAlert ? "alert" : "thumbUp");
      alert.image.class = isAlert ? "slds-theme--error" : "slds-theme--success";
    }
    return alert;
  }

  getDeviceLabel(types) {
    if(!types || types.length <= 0) {
      return "Unknown";
    }

    return types[0].value;
  }

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
        console.log('click not registered', route, itemId);
      }
  }
}