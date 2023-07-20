import LightningDatatable from "lightning/datatable";
import { api } from "lwc";
import ctypeBar from "./ctypeBar.html";
import ctypeChip from "./ctypeChip.html";
import ctypeChipList from "./ctypeChipList.html";
import ctypeString from "./ctypeString.html";

export default class ReportingDatatable extends LightningDatatable {

  @api
  get height() {
    let v = this.template.querySelector("table");
    return v ? v.getBoundingClientRect().height : 0;
  }

  static customTypes = {
    inlineText: {
      template: ctypeString,
      typeAttributes: ["text", "align"]
    },
    inlineBar: {
      template: ctypeBar,
      typeAttributes: ["total", "sub", "max", "category"]
    },
    inlineChip: {
      template: ctypeChip,
      typeAttributes: [
        "imagetype",
        "imagename",
        "imageclass",
        "label",
        "description",
        "href",
        "identifier"
      ]
    },
    chipList: {
      template: ctypeChipList,
      typeAttributes: [
          "items"
      ]
    }
  };
}