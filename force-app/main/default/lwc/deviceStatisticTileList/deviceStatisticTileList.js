/* eslint-disable vars-on-top */
import { LightningElement, api } from 'lwc';
import { TileChipClass } from "c/utilitiesClass";
import { iconName } from "c/utilitiesFunction";

export default class DeviceStatisticTileList extends LightningElement {
  @api isLoading;

  //input
  @api object;
  @api header;
  @api context = 'device';

  get iconClass(){
    return `slds-icon_container ${this.context}`;
  }

  get cardIconName() {
    return iconName("devices");
  }

  get cardTitle() {
    return this.header;
  }

  get chartTitle() {
    return this.object ? this.object.data.title : "";
  }

  get alert() {
    var alert = TileChipClass();
    if (this.object) {
      const alertItem = this.object.alert;
      let isAlert = alertItem.isAlert;
      alert.label = alertItem.label;
      alert.description = alertItem.description;
      alert.image.type = "icon";
      alert.image.name = iconName(isAlert ? "error" : "thumbUp");
      alert.image.class = isAlert ? "slds-theme--warning" : "slds-theme--success";
    }
    return alert;
  }

  get chartData() {
   //prepare collections
    var collection = null;
    if(this.object) {
      collection = {
        labels: [],
        series: [],
        backgroundColor: []
      };
      var colorRange = [];
      if(this.context === 'device'){colorRange = this.backgroundColorRange.blue;}
      if(this.context === 'security'){colorRange = this.backgroundColorRange.red;}
  
      if(this.object.data.statistic.length < 6){
        colorRange = colorRange.slice(3,15); //reduce the scope to the original range so that it become easier on the eye
      }

      var valueColors = [];
      this.object.data.statistic.forEach((item) => {
          valueColors.push({value: item.value, color: ''});
      });
      valueColors.sort((a, b) => { return b.value - a.value; }); //decending
  
      //assign color to values: higher value has darker color
      var length = colorRange.length;
      var space = length/(this.object.data.statistic.length-1);
      valueColors.forEach((item, index) => {
                  item.color = colorRange[(Math.floor(index*space) < length)? Math.floor(index*space) : (length-1)];
              });
  
      this.object.data.statistic.forEach((item) => {
          collection.labels.push(item.label);
          collection.series.push(item.value);
          collection.backgroundColor.push(valueColors.find( vc => vc.value === item.value).color);
        }, this);
    }
    return collection;
  }
  
  backgroundColorRange =  {
    blue: ['#12193b', '#18224e', '#1e2a62', '#243375', '#2a3b89', '#30449c', '#364cb0', '#3c55c3', '#4f66c9', '#6377cf', '#7688d5', '#8a99db', '#9daae1', '#b1bbe7', '#c4cced', '#d8ddf3', '#ebeef9'],
    red: ['#3e100f', '#521614', '#671b19', '#7b211e', '#902623', '#a42c28', '#b9312d', '#cd3732', '#d24b46', '#d75f5b', '#dc736f', '#e18784', '#e69b98', '#ebafad', '#f0c3c1', '#f5d7d6', '#faebea']
  };

  connectedCallback(){
  }

}