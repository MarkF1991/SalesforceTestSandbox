import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from "lightning/platformResourceLoader";
import retrieveColumns from '@salesforce/apex/N4LDataTableScreen.retrieveColumns';
import retrieveRecords from '@salesforce/apex/N4LDataTableScreen.retrieveRecords';
import retrieveBusinessRoles from '@salesforce/apex/N4LDataTableScreen.retrieveBusinessRoles';
import retrieveOutageNotif from '@salesforce/apex/N4LDataTableScreen.retrieveOutageNotif';
import getRelatedFieldName from '@salesforce/apex/N4LDataTableScreen.getRelatedFieldName';
import updateRelationship from '@salesforce/apex/N4LDataTableScreen.updateRelationship';
import checkShowAddNewContact from '@salesforce/apex/n4lAutoCompleteContact.checkShowAddNewContact';
import COMMUNITY_RESOURCE from '@salesforce/resourceUrl/ContactManagementScreens';

import Screen_AllContacts from '@salesforce/label/c.Screen_AllContacts';
import Screen_BusinessContacts from '@salesforce/label/c.Screen_BusinessContacts';
import Screen_ActiveWarningMessage from '@salesforce/label/c.Screen_ActiveWarningMessage';
import Screen_ShowActiveContacts from '@salesforce/label/c.Screen_ShowActiveContacts';

import { getRecord } from 'lightning/uiRecordApi';

import USER_ID from '@salesforce/user/Id';
import PROFILE_UserLicense_Name_FIELD from '@salesforce/schema/User.Profile.UserLicense.Name';

export default class N4lTableScreen extends LightningElement {

    @api recordId;
    @api objectName;
    @api relatedObjectApiName;
    @api relationshipField;
    @api title;
    @api subTitle;
    @api subTitle2;
    @api N4LDataTableFieldsSettingName;
    @api N4LDataTableFieldsSettingNameAllContacts;
    @api showTableAction;
    @api pageSize;
    @api previousButtonName;
    @api nextButtonName;
    @api showMissingMessage;
    @api emptyMessageText;
    @api showAddButton;
    @api addButtonText;
    @api showRelatedFieldName;
    @api headerTitle;
    @api showFilter;
    @api saveRelButton;
    @api searchPlaceHolderText;
    @api hideEditAction;
    @api hideReplaceAction;
    @api sortQuery;
    @api isSupportHub;
    @api isAdvancedView;
    @api queryFilter;
    @api filterByManagedContacts;
    @api showActiveContactsFilter;
    @api updateContactActionLabel;
    @api replaceContactActionLabel;
    @api deactivateContactActionLabel;
    @api reactivateContactActionLabel;

    @track currentPageData = [];
    @track allData = [];
    @track page = 1;
    @track isLoaded = false;
    @track sortBy;
    @track sortDirection;
    @track columns = [];
    @track missingMessage;
    @track missingOutageNotif;
    @track invokePopup = false;
    @track recordRelationId;
    @track isReplace = false;
    @track settingName;
    @track formFunction;
    @track accountName;
    @track userlicense;
    @track activeCheckbox;
    @track showActivationWarning = false;

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [PROFILE_UserLicense_Name_FIELD]
    }) wireuser({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.userlicense = data.fields.Profile.value.fields.UserLicense.value.fields.Name.value;
        }
    }

    label = { Screen_AllContacts, Screen_BusinessContacts, Screen_ActiveWarningMessage, Screen_ShowActiveContacts };

    filterValue = 'AllContacts';
    filterLabel = this.label.Screen_AllContacts;

    connectedCallback() {
        this.checkShowAddNewButton();
        this.activeCheckbox = true;
        const urlParams = this.getQueryParameters();
        this.settingName = this.N4LDataTableFieldsSettingNameAllContacts;
        if (this.recordId == '{recId}' || this.recordId == undefined) { this.recordId = urlParams.recId; }
        console.log('===>' + this.recordId);

        if (!!this.recordId) { this.createTitleName(); }

        if (this.filterByManagedContacts) {
            this.filterValue = 'BusinessContacts';
            this.filterLabel = this.label.Screen_BusinessContacts;
        }

        this.refreshErrorMessage();

        if (this.isSupportHub) {
            loadStyle(this, COMMUNITY_RESOURCE + '/CSS/communityTableScreen.css');
        } else {
            loadStyle(this, COMMUNITY_RESOURCE + '/CSS/tablescreen.css');
        }

        this.createHeaderColumns();
    }
    checkShowAddNewButton() {
        console.log('this.recordId = ' + this.recordId);
        checkShowAddNewContact({
            accountId: this.recordId
        }).then((result) => {
            console.log('add new contact button = ' + result);
            this.showAddButton = result;
        }).catch((error) => {
            console.log(error);
        });
    }
    get filterOptions() {
        if (this.filterByManagedContacts) {
            return [
                { label: this.label.Screen_BusinessContacts, value: 'BusinessContacts' },
                { label: this.label.Screen_AllContacts, value: 'AllContacts' }
            ];
        } else {
            return [
                { label: this.label.Screen_AllContacts, value: 'AllContacts' },
                { label: this.label.Screen_BusinessContacts, value: 'BusinessContacts' }
            ];
        }
    }

    get isBusinessContact() {
        return this.filterValue == 'BusinessContacts' && this.showFilter ? true : false;
    }

    handleFilterChange(event) {
        this.filterValue = event.detail.value;
        this.filterLabel = this.filterValue == 'BusinessContacts' ? this.label.Screen_AllContacts : this.label.Screen_AllContacts;
        this.settingName = this.filterValue == 'BusinessContacts' ? this.N4LDataTableFieldsSettingName : this.N4LDataTableFieldsSettingNameAllContacts;
        this.createHeaderColumns();
    }

    getQueryParameters() {
        let params = {};
        let search = location.search.substring(1);
        if (search) {
            params = JSON.parse('{"' + search.replace(/&/g, '","').replace(/=/g, '":"') + '"}', (key, value) => {
                return key === "" ? value : decodeURIComponent(value)
            });
        }
        return params;
    }

    createMissingMessage() {
        retrieveBusinessRoles({
            recordId: this.recordId
        })
            .then((result) => {

                let lowerCaseReleatedObject = this.relatedObjectApiName.charAt(0).toLowerCase() + this.relatedObjectApiName.slice(1);

                if (result.length > 0) {
                    if (result.length == 1) {
                        this.missingMessage = 'Active relationship role "' + result.join() + '" is missing for this ' + lowerCaseReleatedObject;
                    } else {
                        this.missingMessage = 'Active relationship roles "' + result.join(', ') + '" are missing for this ' + lowerCaseReleatedObject;
                    }
                }
            }).catch((error) => {
                console.log(error);
            });
    }

    checkOutageNotification() {
        retrieveOutageNotif({
            recordId: this.recordId
        })
            .then((result) => {
                this.missingOutageNotif = result;
            }).catch((error) => {
                console.log(error);
            });
    }

    createTitleName() {
        getRelatedFieldName({
            recordId: this.recordId,
            relatedObjectApiName: this.relatedObjectApiName
        })
            .then((result) => {
                if (this.showRelatedFieldName) { this.title = this.title + ' - ' + result; }
                this.accountName = result;
            }).catch((error) => {
                console.log(error);
            });
    }

    createHeaderColumns() {
        retrieveColumns({
            settingName: this.settingName,
            objectName: this.objectName
        })
            .then((result) => {
                let currentColumns = [];

                result.forEach((setting) => {
                    let currentColumn = {};

                    if (setting.Column_Type__c == 'url') {
                        if (this.isSupportHub && (setting.Field_API_Name__c == 'Contact.Account.Name' || this.isSupportHub && setting.Field_API_Name__c == 'Contact.Name')) {
                            currentColumn = {
                                fieldName: setting.Field_API_Name__c, label: setting.Column_Title__c,
                                sortable: setting.Column_Sortable__c, type: 'text'
                            };
                        } else {
                            currentColumn = {
                                fieldName: setting.Field_API_Name__c + '.url', label: setting.Column_Title__c,
                                sortable: setting.Column_Sortable__c, type: setting.Column_Type__c,
                                typeAttributes: {
                                    label: { fieldName: setting.Field_API_Name__c }, target: '_self',
                                    tooltip: { fieldName: setting.Field_API_Name__c }
                                }
                            };
                        }
                    } else if (setting.Column_Type__c == 'date') {
                        currentColumn = {
                            fieldName: setting.Field_API_Name__c, label: setting.Column_Title__c,
                            sortable: setting.Column_Sortable__c, type: setting.Column_Type__c,
                            typeAttributes: { month: 'short', day: 'numeric', year: 'numeric' }
                        };
                    } else {
                        currentColumn = {
                            fieldName: setting.Field_API_Name__c, label: setting.Column_Title__c,
                            sortable: setting.Column_Sortable__c, type: setting.Column_Type__c
                        };
                    }

                    if (this.isSupportHub) {
                        if (setting.Is_Visible_in_Support_Hub__c) {
                            currentColumns.push(currentColumn);
                        }
                    } else {
                        currentColumns.push(currentColumn);
                    }
                });

                if (this.showTableAction) {
                    currentColumns.push({ type: 'action', typeAttributes: { rowActions: { fieldName: "rowActions" } } });
                }

                this.columns = currentColumns;

                this.createRecordsData();
            }).catch((error) => {
                console.log(error);
                this.handleError(error.body.message);
            });
    }

    get accountContactRecords() {
        return this.currentPageData ? this.pageData() : [];
    }

    get hasRecords() {
        return this.currentPageData.length > 0 ? true : false;
    }

    pageData = () => {
        let endIndex = this.page * this.pageSize;
        let startIndex = endIndex - this.pageSize;
        return this.currentPageData.slice(startIndex, endIndex);
    }

    createRecordsData() {
        this.isLoaded = true;
        if (this.recordId != null && this.recordId != '') {
            retrieveRecords({
                settingName: this.settingName,
                objectName: this.objectName,
                recordId: this.recordId,
                relationshipField: this.relationshipField,
                isBusinessContact: this.isBusinessContact,
                sortQuery: this.sortQuery
            })
                .then((result) => {
                    this.allData = [];

                    result.forEach((rowValue) => {
                        rowValue.rowActions = [];

                        if (!this.hideEditAction) { rowValue.rowActions.push({ label: 'View/Edit Contact', name: 'edit_relationship' }); }

                        if (rowValue.isActive == true || rowValue.isActive == 'true') {
                            if (!this.hideReplaceAction) { rowValue.rowActions.push({ label: this.replaceContactActionLabel, name: 'relation_replace' }); }
                            if (!this.hideEditAction) { rowValue.rowActions.push({ label: 'Remove Contact', name: 'relation_active' }); }
                        } else {
                            if (!this.hideEditAction) { rowValue.rowActions.push({ label: this.reactivateContactActionLabel, name: 'relation_active' }); }
                        }

                        this.allData.push(rowValue);
                    });

                    if (this.activeCheckbox) {
                        this.currentPageData = [];
                        this.allData.forEach((contactData) => {
                            if (contactData.isActive == true || contactData.isActive == 'true') {
                                this.currentPageData.push(contactData);
                            }
                        });
                    } else {
                        this.currentPageData = this.allData;
                    }

                    this.isLoaded = false;
                }).catch((error) => {
                    console.log(error);
                    this.handleError(error.body.message);
                    this.isLoaded = false;
                });
        } else {
            this.isLoaded = false;
        }
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;

        let originalFieldName = this.sortBy;

        if (this.sortBy.includes('.url')) {
            originalFieldName = this.sortBy;
            this.sortBy = this.sortBy.substring(0, this.sortBy.lastIndexOf("."));
        }

        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection, originalFieldName);
        this.sortBy = event.detail.fieldName;
    }

    sortData(fieldname, direction, originalFieldName) {
        this.isLoaded = true;
        let parseData = JSON.parse(JSON.stringify(this.currentPageData));

        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };

        let isReverse = direction === 'asc' ? 1 : -1;

        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // Handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // Sorting values based on direction

            console.log(x);

            return isReverse * ((x > y) - (y > x));
        });

        // Set the sorted data to data table data
        this.currentPageData = parseData;
        this.isLoaded = false;
    }

    refreshTable() {
        this.page = 1;
        this.sortBy = null;
        this.sortDirection = null;
        this.createRecordsData();

        this.refreshErrorMessage();
    }

    refreshErrorMessage() {
        if (this.showMissingMessage) {
            this.createMissingMessage();
            this.checkOutageNotification();
        }
    }

    get hasPrev() {
        return this.currentPageData ? (this.page > 1) : false;
    }

    get hasNext() {
        return this.currentPageData ? (this.page < Math.ceil(this.currentPageData.length / this.pageSize)) : false;
    }

    get lastPage() {
        if (this.currentPageData.length == 0) {
            return this.page;
        } else {
            return this.currentPageData ? Math.ceil(this.currentPageData.length / this.pageSize) : this.page;
        }
    }

    onNext = () => {
        ++this.page;
    }

    onPrev = () => {
        --this.page;
    }

    showToast({ title, message, variant, mode }) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title || 'Success',
                message: message,
                variant: variant || 'success',
                mode: mode || 'dismissable'
            })
        );
    }

    handleActiveContacts(event) {
        this.activeCheckbox = event.target.checked;
        this.createRecordsData();
    }

    handleError(errorMessage) {
        console.error(errorMessage);
        this.showToast({
            title: 'Error',
            message: errorMessage,
            variant: 'error',
            mode: 'dismissable'
        });
    }

    handleRowAction(event) {
        const row = event.detail.row;

        switch (event.detail.action.name) {
            case 'edit_relationship':
                this.navigateToEditRelationship(row);
                break;
            case 'relation_replace':
                this.navigateToReplaceRelationship(row);
                break;
            case 'relation_active':
                this.navigateToActivateDeactivateRelationship(row);
                break;
        }
    }

    navigateToReplaceRelationship(row) {
        this.formFunction = 'Replace';
        this.isReplace = true;
        this.invokePopup = true;
        this.recordRelationId = row.Id;
    }

    navigateToEditRelationship(row) {
        this.formFunction = 'Update';
        this.isReplace = false;
        this.invokePopup = true;
        this.recordRelationId = row.Id;
    }

    navigateToActivateDeactivateRelationship(row) {
        this.recordRelationId = row.Id;
        this.showActivationWarning = true;
    }

    cancelWarningMessage() {
        this.showActivationWarning = false;
    }

    updateRelationship() {
        this.showActivationWarning = false;
        this.isLoaded = true;

        updateRelationship({
            relationId: this.recordRelationId
        })
            .then((result) => {
                this.refreshTable();
            }).catch((error) => {
                this.isLoaded = false;
                console.log(error);
                this.handleError(error.body.message);
            });
    }

    handleAddRelationshipButton() {
        this.formFunction = 'Add';
        this.isReplace = false;
        this.recordRelationId = null;
        this.invokePopup = true;
    }

    handleCloseForm(event) {
        this.invokePopup = event.detail;
        this.refreshTable();
    }
}