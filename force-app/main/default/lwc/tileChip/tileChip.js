import { LightningElement, api } from 'lwc';

export default class tileChip extends LightningElement {
    @api line1;
    line1 = 'boris.butler@school.nz';
    //line1 = 'epicgames.com/fortnite';
    //line1 = '';

    @api line2;
    //line2 = 'ssss lakjsdf lkajs df;lkajs dflkaj sd;flj dfla ljldkfasdj ';
    //line2 = 'Gaming';

    @api initial;
    @api materialicon;
    @api iconclass;
    
    get avatarClass(){
        //return "slds-avatar slds-avatar_circle slds-avatar_medium slds-align_absolute-center " + this.iconclass;
        return "slds-avatar slds-avatar_circle slds-avatar_medium slds-align_absolute-center " + this.obj.data.image.class;
    }

    

    @api object;
    object = {
        "data": {
          "image": {
            "type": "icon",
            "name": "videogame_asset",
            "class": "security"
          },
          "label": "Youtube",
          "description": "Streaming Media and Download",
        }
      };

    get isIcon(){
        return this.object.data.image.type==='icon';
    }
    get isAvatar(){
        return this.object.data.image.type==='avatar';
    }
    
}