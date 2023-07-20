import { LightningElement, api, track} from 'lwc';

export default class DatatablePaginated extends LightningElement {

    // All records passed to the component
    @api records;
    @api columns;

    // Manage changed values
    @track draftValues = [];

    // Default current page to 1
    @track currentPageNumber = 1;

    // The # records to show per page
    recordsPerPage = 50;

    get maxPageNumber () {
        return Math.ceil(this.records.length / this.recordsPerPage);
    }

    get showPagination () {
        return this.maxPageNumber > 1;
    }

    get currentPageLabel () {
        return this.currentPageNumber + ' / ' + this.maxPageNumber;
    }

    get canGoPrevPage () {
        return !(this.currentPageNumber > 1);
    }

    get canGoNextPage () {
        return !(this.currentPageNumber < this.maxPageNumber);
    }

    get pageRecordList() {
        return this.records
            .slice(this.recordsPerPage * (this.currentPageNumber - 1), this.recordsPerPage * this.currentPageNumber);
    }

    goToFirstPage() {
        this.currentPageNumber = 1;
    }

    goToPrevPage() {
        this.currentPageNumber -= 1;
    }

    goToNextPage() {
        this.currentPageNumber += 1;
    }

    goToLastPage() {
        this.currentPageNumber = this.maxPageNumber;
    }

    updateDraftValues(updateItem) {
        let draftValueChanged = false;
        let copyDraftValues = [...this.draftValues];
        //store changed value to do operations
        //on save. This will enable inline editing &
        //show standard cancel & save button
        copyDraftValues.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
                draftValueChanged = true;
            }
        });

        if (draftValueChanged) {
            this.draftValues = [...copyDraftValues];
        } else {
            this.draftValues = [...copyDraftValues, updateItem];
        }
    }

    // When a picklist value changes, pass it to the draft values list
    handlePicklistChange(event) {

        let recordForUpdate = Object.assign({}, event.detail.data);

        // Update the reocrd to the draft values
        this.updateDraftValues(recordForUpdate);
    }

    // When any other normal cell changes, add to update list
    handleCellChange(event) {
        this.updateDraftValues(event.detail.draftValues[0]);
    }

    handleSave(event) {

        // Prevents the anchor element from navigating to a URL.
        event.preventDefault();

        // Creates the event with the contact ID data.
        const saveEvent = new CustomEvent('save', { detail: this.draftValues });

        // Dispatches the event.
        this.dispatchEvent(saveEvent);
    }

}