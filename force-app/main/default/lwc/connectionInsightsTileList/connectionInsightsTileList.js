import { LightningElement, api } from 'lwc';
import { TileItemClass, TileChipClass }  from 'c/utilitiesClass';
import {formatNumber, iconName} from 'c/utilitiesFunction';
export default class connectionInsightsTileList extends LightningElement {

    //input
    @api object;

    @api param;
    param = {
        "schoolId": 100,
        "period": 7,
        "type": 'browsing-time'
    };

    get cardIconName(){
        return iconName('connections');
    }

    //output - fields mapping
    get insightContent(){
        var array = [];
        var item1 = TileItemClass();
        var item2 = TileItemClass();
        if(this.object){
            const networkResponseTime = this.object.data.networkResponseTime;
            const networkBandwidthUtilisation = this.object.data.networkBandwidthUtilisation;
            
            //Network Response Time
            item1.id = 301;
            item1.title = 'Network Response Time';
            item1.value = networkResponseTime.value; 
            item1.unit = (networkResponseTime.unit)? `(${networkResponseTime.unit})` : '';
            item1.path = `connection-dashboard?schoolId=${this.param.schoolId}&period=${this.param.period}`;
            item1.chip.label = networkResponseTime.label;
            item1.chip.description = networkResponseTime.description;
            item1.chip.image.type = 'icon';
            item1.chip.image.name = iconName(networkResponseTime.category);
            item1.chip.image.class = 'connection'; //fixed as user - this will affect class to render colour based on tileChip.css 
            

            //Network Bandwidth Utilisation
            item2.id = 302;
            item2.title = 'Network Bandwidth Utilisation';
            item2.value = formatNumber(networkBandwidthUtilisation.value); //display number with , seperator
            item2.unit = (networkBandwidthUtilisation.unit)? `(${networkBandwidthUtilisation.unit})` : '';
            item2.path = `connection-dashboard?schoolId=${this.param.schoolId}&period=${this.param.period}`;
            item2.chip.label = networkBandwidthUtilisation.label;
            item2.chip.description = networkBandwidthUtilisation.description;
            item2.chip.image.type = 'icon';
            item2.chip.image.name = iconName(networkBandwidthUtilisation.category);
            item2.chip.image.class = 'connection'; 
            
        
            array.push(item1);
            array.push(item2);
        }
       
        return array;
    }

    get alertContent(){
        var alert = TileChipClass();
        if(this.object){
            const connectionAlert = this.object.data.connectionAlert;
            alert.label = connectionAlert.label;
            alert.description = connectionAlert.description;
            alert.image.type = 'icon';
            alert.image.name = iconName(connectionAlert.category);
            alert.image.class = (connectionAlert.category === 'thumbUp')? 'slds-theme--success' : 'slds-theme--error'; //followin slds theme: https://archive-1_0_5.lightningdesignsystem.com/components/utilities/themes
        }
        return alert; 
    }

  
}