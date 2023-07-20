import { LightningElement, api } from 'lwc';

export default class TileRowThreeBar extends LightningElement {
    @api object;
    object = {
        chip:{
            "image": {
                "type": "icon",
                "name": "videogame_asset",
                "class": "security"
              },
              "label": "Youtube",
              "description": "Streaming Media and Download"
        }, 
        count:123,
        bar1:{  
                category:'browsingTime',
                type:'duration',
                value:'1:46:17',
                max:'2:00:00',
                fillpercentage:100,
                widthpercentage:94
            },
        bar2:{  
                category:'bandwidthUsage',
                type:'data-size',
                value:'15.2',
                max:'20.1',
                fillpercentage:80,
                widthpercentage:100
            },
        bar3:{  
                category:'blockedAttempts',
                type:'count',
                value:'499446',
                max:'500100',
                fillpercentage:100,
                widthpercentage:90
            }
      };
    
     
}