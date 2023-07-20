import { LightningElement, api } from 'lwc';
import { TileItemClass, TileChipClass } from "c/utilitiesClass";
import { formatNumber, iconName } from "c/utilitiesFunction";

export default class AssociatedDevicesList extends LightningElement {
    @api isLoading;

    //input
    @api object;
    @api param;
    @api header;   
    @api context;

    get iconClass(){
        return `material-icons md-18 custom-icon ${this.context}`;
    }

    get cardIconName() {
        return iconName("devices");
    }

    get alertContent() {
        var alert = TileChipClass();
        if (this.object) {
        
          const securityAlert = this.object.alert;
          let isAlert = securityAlert.isAlert;
          alert.label = isAlert ? securityAlert.label : 'All Clear';
          alert.description = securityAlert.description;
          alert.image.type = "icon";
          alert.image.name = iconName(isAlert ? "alert" : "thumbUp");
          alert.image.class = isAlert ? "slds-theme--error" : "slds-theme--success";
        }
        return alert;
      }

      get insightContent(){
        if(this.object) {
            // eslint-disable-next-line no-console
            let href = "#";
            let result = [];
            result = result.concat(this.object.data.devices.map(obj => this.ObjectMapping(obj, href))).sort((a, b) => { return b.value - a.value; });
            return result;
            
        }
        return [];
    }

    ObjectMapping(objectData, href) {
        //prepare json object arrays for tileItemObject component.
        var currentObject = TileItemClass();
        currentObject.id = `${Math.random()}`;
        currentObject.title = null;
        currentObject.value = formatNumber(objectData.value);
        currentObject.unit = null;
        currentObject.path = href; 
        currentObject.chip.label = objectData.label;
        currentObject.chip.description = objectData.description
        currentObject.chip.image.type = "icon";
        if (objectData.category) {
          currentObject.chip.image.name = iconName(objectData.category);
        } else {
          currentObject.chip.image.name = null;
        }
        currentObject.chip.image.class = this.context;
        return currentObject;
      }

}