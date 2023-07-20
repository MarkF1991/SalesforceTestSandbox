import { LightningElement, api, track } from 'lwc';

export default class LinkTile extends LightningElement {
    @api link;
    //example:
    //          {
    //             id: 'os3te',
    //             title: 'SLDS Grid',
    //             url: 'https://www.lightningdesignsystem.com/utilities/grid/#Content-centered-2',
    //             description: 'The SLDS grid system provides a flexible, mobile-first, device-agnostic layout system. It has features to control alignment, order, flow, and gutters.'
    //         };
    @api readOnly = false;
    @track elements = [];
    @track header = 'Edit Link'; //default
    @track mode = 'edit';
    @track submitButtonName = 'Save';
    @track cancelButtonName = 'Cancel';
    @track confirmationMessage = '';

    @api
    handleNew(){
        this.header = 'New Link';
        this.mode = 'create';
        this.submitButtonName = 'Save';
        this.cancelButtonName = 'Cancel';
        this.handleShowModal();
    }
    
    
    handleEdit(){
        this.header = 'Edit Link';
        this.mode = 'edit';
        this.submitButtonName = 'Save';
        this.cancelButtonName = 'Cancel';
        this.handleShowModal();
    }
    
    handleDelete(){
        this.header = 'Delete Link';
        this.mode = 'confirmToDelete';
        this.submitButtonName = 'Yes';
        this.cancelButtonName = 'No';
        this.confirmationMessage = 'Are you sure you want to delete the link: ' + this.link.title + ' ?';
        this.handleShowModal();
    }
    
    handleShowModal(){
        let array = [];
        
        //prepare json elements
        let jsonTitle = {
            'id': Math.random().toString(36).substr(2, 5),
            'label': 'title',
            'value': this.link.title,
            'type': 'text',
            'required': true
        };

        let jsonURL = {
            'id': Math.random().toString(36).substr(2, 5),
            'label': 'url',
            'value': this.link.url,
            'type': 'url',
            'required': true
        };

        let jsonDescription = {
            'id': Math.random().toString(36).substr(2, 5),
            'label': 'description',
            'value': this.link.description,
            'type': 'text',
            'required': false
        };

        array.push(jsonTitle);
        array.push(jsonURL);
        array.push(jsonDescription);

        //pass array back to this.elements
        this.elements = array;
        
      
        const modal = this.template.querySelector('c-modal');
        modal.show();
    }
    
}