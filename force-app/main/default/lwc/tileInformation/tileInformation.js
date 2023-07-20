import { LightningElement, api } from 'lwc';
import { TileChipClass } from "c/utilitiesClass";
import { iconName } from "c/utilitiesFunction";

export default class TileInformation extends LightningElement {
    @api isLoading = false;
    @api object;

    get cardIconName() {
        return "public";
    }

    get cardTitle() {
        return "Category Information";
    }

    get infoDescription() {
        return this.object && this.object.data ? this.object.data.description : "";
    }

    get infoTitle() {
        return this.object && this.object.data ? this.object.data.title : "";
    }

    get alert() {
        var alert = TileChipClass();
        if (this.object) {
          const alertItem = this.object.alert;
          let isAlert = alertItem.isAlert;
          alert.label = alertItem.label;
          alert.description = alertItem.description;
          alert.image.type = "icon";
          alert.image.name = iconName(isAlert ? "alert" : "thumbUp");
          alert.image.class = isAlert ? "slds-theme--error" : "slds-theme--success";
        }
        return alert;
      }
}