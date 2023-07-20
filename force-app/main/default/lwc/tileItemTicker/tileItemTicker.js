import { LightningElement, api } from "lwc";
import { iconName } from "c/utilitiesFunction";
export default class tileItemTicker extends LightningElement {
  @api object;
  @api hideTrend = false;

  get tickerClass() {
    var sldsTextTheme = "slds-text-color_error";
    if(this.object && this.object.ticker) {
        if (this.object.ticker.trend === "up" || this.object.ticker.trend === "neutral") {
            sldsTextTheme = "slds-text-color_success";
        }
    }

    //html: <p class="slds-col slds-grow-none slds-p-left_medium slds-align-middle slds-truncate tickerText  slds-text-color_error">
    return `slds-col slds-grow-none slds-p-left_medium slds-align-middle slds-truncate tickerText ${sldsTextTheme}`;
  }

  get tickerIconName() {
    if (this.object && this.object.ticker) {
      return iconName(this.object.ticker.trend);
    }
    return "";
  }

  get chipImageName() {
    if (this.object && this.object.chip && this.object.chip.image) {
      return this.object.chip.image.name;
    }
    return '';
  }

  get showChipImage() {
    return this.object && this.object.chip && this.object.chip.image && this.object.chip.image.name;
  }

  get label() {
    if (this.object && this.object.chip) {
      return this.object.chip.label;
    }
    return '';
  }

  get tickerValue() {
    if (this.object && this.object.ticker) {
      return this.object.ticker.value;
    }
    return 0;
  }

  get value() {
    if (this.object) {
      return this.object.value;
    }
    return 0;
  }
}