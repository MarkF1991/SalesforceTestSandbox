import { LightningElement, api } from 'lwc';

import { TileItemClass } from "c/utilitiesClass";
import { formatNumber, bytesToUnit, getReadableDuration, iconName } from "c/utilitiesFunction";

export default class DeviceUsageTileList extends LightningElement {
    @api isLoading;

    //input
    @api object;
    @api param;
    @api header;

    getDeviceName = (name, mac) => {
        return name ? name : mac;
    }

    getHref = (view) => {
        return `devices-list-view?schoolId=${this.param.schoolId}&view=${view}&start=${this.param.start}&end=${this.param.end}`;
    }

    iconNameForCategory(category) {
        return iconName(category);
    }

    //output - fields mapping
    get items() {
        var array = [];
        var item1 = TileItemClass();
        var item2 = TileItemClass();
        var item3 = TileItemClass();

        if (this.object && this.param) {
            const deviceByBandwidth = this.object.data.deviceByBandwidth;
            const deviceByBrowsingTime = this.object.data.deviceByBrowsingTime;
            const deviceByBlocked = this.object.data.deviceByBlocked;

            if(deviceByBrowsingTime) {
                //top user by browsing time
                item1.id = 101;
                item1.title = "Top Device by Browsing Time";
                item1.value = getReadableDuration(deviceByBrowsingTime.value); 
                item1.unit = "(HH:MM:SS)";
                item1.path = this.getHref('devices-browsing-time');
                item1.chip.label = this.getDeviceName(deviceByBrowsingTime.deviceName, deviceByBrowsingTime.deviceMac);
                item1.chip.description = deviceByBrowsingTime.deviceCategory;
                item1.chip.image.type = "icon";
                item1.chip.image.name = this.iconNameForCategory(deviceByBrowsingTime.deviceCategory);
                item1.chip.image.class = "devices";
                array.push(item1);
            }
            
            if(deviceByBandwidth) {
            //top user by Bandwidth Usage
            item2.id = 102;
            item2.title = "Top Device by Bandwidth Usage";
            item2.value = bytesToUnit(deviceByBandwidth.value, "GB"); //display number with , seperator
            item2.unit = "(GB)";
            item2.path = this.getHref('devices-bandwidth-usage');
            item2.chip.label = this.getDeviceName(deviceByBandwidth.deviceName, deviceByBandwidth.deviceMac);
            item2.chip.description = deviceByBandwidth.deviceCategory;
            item2.chip.image.type = "icon";
            item2.chip.image.name = this.iconNameForCategory(deviceByBandwidth.deviceCategory);
            item2.chip.image.class = "devices";
            
            array.push(item2);
            }

            if(deviceByBlocked){
            //top user by Blocked Attempts
            item3.id = 103;
            item3.title = "Top Device by Blocked Attempts";
            item3.value = formatNumber(deviceByBlocked.value); //display number with , seperator
            item3.unit = " "; //nothing to display, but occupy the top space
            item3.path = this.getHref('devices-blocked-attempts');
            item3.chip.label = this.getDeviceName(deviceByBlocked.deviceName, deviceByBlocked.deviceMac);
            item3.chip.description = deviceByBlocked.deviceCategory;
            item3.chip.image.type = "icon";
            item3.chip.image.name = this.iconNameForCategory(deviceByBlocked.deviceCategory);
            item3.chip.image.class = "devices";
            
            array.push(item3);
            }
            // array.push(item1);
            // array.push(item2);
            // array.push(item3);
        }
        return array;
    }
}