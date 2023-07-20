import LightningDatatable from 'lightning/datatable';
import imageTableControl from './imageControl.html';
import textTableControl from './textControl.html';
import phoneTableControl from './phoneControl.html';

export default class N4lCustomDatatable extends LightningDatatable  {
    static customTypes = {
        image: {
            template: imageTableControl
        },
        text: {
            template: textTableControl
        },
        phone: {
            template: phoneTableControl
        }
    };
}