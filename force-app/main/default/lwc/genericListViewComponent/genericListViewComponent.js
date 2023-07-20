import { LightningElement, track, api } from 'lwc';
import { pushStateToUrl } from "c/communitiesNavigation";
import { iconName } from "c/utilitiesFunction";

export default class GenericListViewComponent extends LightningElement {
    @track schoolId;
    @track selectedfilter = { dateFilter: { start: null, end: null } };
    @track start = "";
    @track end = "";
    @track error;
    @track tableLoadingState = true;
    @track data = [];
    @track page = 1;
    @track perPage = 50;
    @track overridePageHeaderTitle = null;
    @api overrideView = null;
    @api disableSelectionMenu = false;
    maxValue = 0;
    resultsTotal = 0;
    queryParams = {};
    menuItems = [];

    @track columns = [
        // Your column data here
        {
            label: 'Website',
            type: 'inlineChip',
            fieldName: 'id',
            typeAttributes: {
              imagetype: { fieldName: 'imageType' },
              imagename: { fieldName: 'imageName' },
              imageclass: { fieldName: 'imageClass' },
              label: { fieldName: 'website' },
              description: {fieldName: 'category'},
            },
        },
        { label: "# Users", fieldName: "num_users", type: "number", initialWidth: 120 },
        {
            label: "Bandwidth Usage",
            type: "inlineBar",
            fieldName: "id",
            typeAttributes: {
                total: { fieldName: "value" },
                sub: { fieldName: "sub" },
                max: { fieldName: "max" },
                category: { fieldName: "type" }
            }
        },
        { label: "(GB)", fieldName: "displayvalue", type: "number", initialWidth: 150 }
    
    ];


    @api get disableInfiteScroll() {
        return this._disableInfiteScroll;
    }

    set disableInfiteScroll(val) {
        if(val && this._disableInfiteScroll !== val) {
            window.removeEventListener('scroll', this.onScoll);
        } else if(this._disableInfiteScroll && !val) {
            window.addEventListener('scroll', this.onScoll);
        }
        this._disableInfiteScroll = val;
    }

    resolveIcon(category) {
        return iconName(category);
    }

    sendAnalyticsEvent(category, action, label) {
        // eslint-disable-next-line no-undef
        if(ga) {
            // eslint-disable-next-line no-undef
            ga('send', {
                hitType: 'event',
                eventCategory: category,
                eventAction: action,
                eventLabel: label
            });
        }
    }

    getMenuItemForView(view) {
        if(view) {
            return this.menuItems.find(x => x.value === view);    
        }
        return null;
    }
    
    resetState() {
        this.page = 1;
        this.perPage = 50;
        this.maxValue = 0;
        this.data = [];
    }

    doFilter(filters) {
        //1. update URL Param.
        filters.forEach((data) => {
            if (data.type === "Date Range") {
                this.start = data.option.start;
                this.end = data.option.end;
                this.queryParams.start = this.start;
                this.queryParams.end = this.end;
                this.selectedfilter.dateFilter.start = this.start;
                this.selectedfilter.dateFilter.end = this.end;
            }
        }, this); //must add ,this at the end when we are updating this.start, this.end, etc within a for loop
        
        this.resetState();
        this.queryParams.page = this.page;
        this.queryParams.perPage = this.perPage;
        pushStateToUrl(this.queryParams);
    }
}