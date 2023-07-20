import { LightningElement, api } from 'lwc';
import { TileChipClass } from 'c/utilitiesClass';
import { fireEvent } from 'c/pubsub';

export default class tileChip extends LightningElement {
    @api imageType = '';
    @api imageName = '';
    @api imageClass = '';
    @api label = '';
    @api description = '';
    @api href;
    @api object;
    @api identifier;
    @api entityType = null;

    pageRef  = { attributes: { name: "nav" } };

    connectedCallback() {
        if (!this.object) {
            let newObject = TileChipClass();

            newObject.image.type = this.imageType;
            newObject.image.name = this.imageName;
            newObject.image.class = this.imageClass;
            newObject.label = this.label;
            newObject.description = this.description;

            this.object = newObject;
        }
    }

    get avatarClass() {
        return "slds-avatar slds-avatar_circle slds-avatar_medium slds-align_absolute-center " + this.object.image.class;
    }

    get isIcon() {
        return this.object.image && this.object.image.type === 'icon';
    }

    get isAvatar() {
        return this.object.image &&  this.object.image.type === 'avatar';
    }

    navigateClick(event) {
        event.preventDefault();
        const navigateEvent = new CustomEvent('navigate', { detail: { identifier: this.identifier, entityType: this.entityType }, bubbles: true });

        // Dispatches the event.
        this.dispatchEvent(navigateEvent);

        fireEvent(this.pageRef, 'navigateToPage', { route: this.href, args: { data: this.object, identifier: this.identifier } });
    }
}