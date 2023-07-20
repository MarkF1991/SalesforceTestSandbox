import { LightningElement, api } from 'lwc';
import { TileItemClass, TileChipClass } from "c/utilitiesClass";
import { iconName, formatNumber } from "c/utilitiesFunction";

export default class SecurityInsightsRankedList extends LightningElement {
    @api isLoading = false;
    @api object; //example: {"data":[{"category":"Pornography","rank":"1","blocked_requests":11640},{"category":"Explicit Violence","rank":"1","blocked_requests":296},{"category":"Drug Abuse","rank":"1","blocked_requests":132},{"category":"Extremist Groups","rank":"1","blocked_requests":36},{"category":"Discrimination","rank":"1","blocked_requests":8}]}
    @api param;

      //input
    @api header;
    // @api listTitle;
    @api context = 'security';
    @api view = 'infected-devices';
    @api canNavigate = false;
    @api isNarrow;

    get iconClass(){
        return `material-icons md-18 custom-icon ${this.context}`;
    }

    get cardIconName() {
        return iconName(this.context);
    }

    get cardTitle() {
            return this.header;
    }

    get tileItemClass(){
        return (this.isNarrow ? 'slds-p-horizontal_medium slds-p-vertical_x-small' : 'slds-p-horizontal_medium slds-p-vertical_medium listItem');
    }

    get insightContent(){
        if(this.object) {
            // eslint-disable-next-line no-console
            let href = "";
            if(this.param && this.canNavigate) {
                href = `${this.context}-list-view?schoolId=${this.param.schoolId}&start=${this.param.start}&end=${this.param.end}&view=${this.view}&id=${this.context}`;
            }

            let result = [];
            result = result.concat(this.object.data.items.map(obj => this.securityObjectmapping(obj, href))).sort((a, b) => { return b.value - a.value; });
            return result.slice(0, 5);
            
        }
        return [];
    }

    securityObjectmapping(objectData, href) {
        //prepare json object arrays for tileItemObject component.
        var securityObject = TileItemClass();
        securityObject.id = `${Math.random()}`;
        securityObject.title = null;
        securityObject.value = objectData.value ? formatNumber(objectData.value) : null;
        securityObject.unit = null;
        securityObject.path = href;
        securityObject.chip.label = objectData.label;
        securityObject.chip.description = objectData.description;
        securityObject.chip.image.type = "icon";
        if (objectData.category) {
          securityObject.chip.image.name = iconName(objectData.category);
        } else {
          securityObject.chip.image.name = null;
        }
        securityObject.chip.image.class = this.context;
        return securityObject;
      }

      get showAlert(){
        if (this.object && this.object.alert) {
          if(this.object.alert.isAlert){
            return true;
          }
        }
        return false;
      }

      get alertContent(){
        // var alert = TileChipClass();
        if (this.object && this.object.alert) {
          let alert = TileChipClass();
          const securityAlert = this.object.alert;
          let isAlert = securityAlert.isAlert;
          alert.label = isAlert ? securityAlert.label : 'All Clear';
          alert.description = securityAlert.description;
          alert.image.type = "icon";
          alert.image.name = iconName(isAlert ? "alert" : "thumbUp");
          alert.image.class = isAlert ? "slds-theme--error" : "slds-theme--success";
          return alert;
        }
        return null;
      }

      get listTitle(){
        if(this.object) {
          return this.object.data.title ? this.object.data.title : '';
        }
       return '';
      }

      get showTitle(){
        if(this.object) {
          return this.object.data.title ? true : false;
        }
        return false;
      }
    
}