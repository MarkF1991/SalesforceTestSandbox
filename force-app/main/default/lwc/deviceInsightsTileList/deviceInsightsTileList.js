/* eslint-disable no-console */
import { LightningElement, api } from "lwc";
import { TileItemClass } from "c/utilitiesClass";
import { formatNumber, iconName } from "c/utilitiesFunction";
import { fireEvent } from 'c/pubsub';

export default class deviceInsightsTileList extends LightningElement {
  
  pageRef  = { attributes: { name: "nav" } };

  get cardIconName() {
    return iconName("devices");
  }

  //input
  @api object;
  @api isLoading;
  @api param;

  get totalDevices() {
    var result;
    if (this.object && this.param) {
      let data = this.object.data.Total;
      result = this.deviceObjectmapping({value: data.value, trend: data.trend}, 'Total No. Devices');
    }
    return result;
  }

  get deviceComputers() {
    var result;
    if (this.object && this.param) {
      let data = this.object.data.Computer;
      result = this.deviceObjectmapping({value: data.value, category: 'Computer', trend: data.trend }, 'Computers');
    }
    return result;
  }

  get deviceTablets() {
    var result;
    if (this.object && this.param) {
      let data = this.object.data.Tablet;
      result = this.deviceObjectmapping({value: data.value, category: 'Tablet', trend: data.trend }, 'Tablets');
    }
    return result;
  }

  get deviceCellPhones() {
    var result;
    if (this.object && this.param) {
      let data = this.object.data['Cell Phone'];
      result = this.deviceObjectmapping({value: data.value, category: 'Cell Phone', trend: data.trend }, 'Cell Phones');
    }
    return result;
  }

  get deviceOther() {
    var result;
    if (this.object && this.param) {
      let data = this.object.data.Other;
      result = this.deviceObjectmapping({value: data.value, category: 'Other', trend: data.trend }, 'Other');
    }
    return result;
  }

  // eslint-disable-next-line no-unused-vars
  notifyClick(event) {
    fireEvent(this.pageRef, 'navigateToPage', { route: "devices-list-view", args: { data: null, identifier: null } });
  }

  deviceObjectmapping(objectData, label) {
    var deviceObject = TileItemClass();
    //Total No. Devices
    deviceObject.title = null;
    deviceObject.value = formatNumber(objectData.value);
    deviceObject.unit = null;
    deviceObject.identifier = label;
    deviceObject.path = `devices-list-view`;
    deviceObject.chip.label = label;
    deviceObject.chip.description = objectData.description;
    deviceObject.chip.image.type = "icon";
    if (objectData.category) {
      deviceObject.chip.image.name = iconName(objectData.category);
    } else {
      deviceObject.chip.image.name = null;
    }
    deviceObject.chip.image.class = "devices"; //fixed as user - this will affect class to render colour based on tileChip.css
    deviceObject.ticker.trend = objectData.trend > 0 ? 'up' : 'down';
    deviceObject.ticker.value = Math.abs(objectData.trend);
    return deviceObject;
  }
}