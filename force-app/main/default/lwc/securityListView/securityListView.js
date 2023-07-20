/* eslint-disable no-console */
import { track, api } from "lwc";
import { getQueryParams, pushStateToUrl } from "c/communitiesNavigation";
import { fetchData } from "c/utilitiesFunction";
import { mapResponse, getMaxValue } from "./securityListViewMapper";
import { items } from "./securityListViewMenuDefinition";
import GenericListViewComponent from 'c/genericListViewComponent';

export default class SecurityListView extends GenericListViewComponent {
    pageHeaderLabel = "Security";
    @api view = "infected-devices";
    menuItems = items;
    @track listViewTitle = "Security";
    @api disableInfiteScroll = false;
    @api overrideCssClass = "list-container";

    constructor() {
        super();
        this.onScoll = this.onScoll.bind(this);
    }

    async connectedCallback() {
        this.queryParams = getQueryParams(window.location.search);

        if (this.queryParams.schoolId) {
            this.schoolId = this.queryParams.schoolId;
            this.start = this.queryParams.start;
            this.end = this.queryParams.end;
            this.page = this.queryParams.page ? parseInt(this.queryParams.page, 10) : parseInt(this.page, 10);
            this.perPage = this.queryParams.perPage ? this.queryParams.perPage : parseInt(this.perPage, 10);
            this.selectedfilter.dateFilter.start = this.start;
            this.selectedfilter.dateFilter.end = this.end;
            if(this.queryParams.view) {
                this.view = this.overrideView ? this.view : this.queryParams.view;
            }
            this.load();
        }
        
        window.addEventListener('scroll', this.onScoll);
    }

    disconnectedCallback() {
        window.removeEventListener('scroll', this.onScoll);
    }

    onScoll() {
        if(!this.disableInfiteScroll) {
            if(this.resultsTotal > this.page * this.perPage && !this.tableLoadingState && (window.scrollY > this.template.querySelector("c-reporting-data-table[id^='security-table']").height - ( window.screen.height))) {
                this.page += 1;
                this.load();
                this.sendAnalyticsEvent('SecurityListView', 'scroll', `Page ${this.page}`);
            }
        }
    }

    handleMenuChanged(event) {
        this.view = event.detail.value; //value of selected menu item in child component pageHeader

        //update URL param
        this.queryParams.view = this.view;
        this.resetState();
        this.queryParams.page = this.page;
        this.queryParams.perPage = this.perPage;
        pushStateToUrl(this.queryParams);
        this.load();
    }

    load() {
        this.tableLoadingState = true;
        let context = "infection";
        let item = this.getMenuItemForView(this.view);
        if(item) {
            context = item.context;
            this.columns = item.columns;
            this.listViewTitle = item.label;
            this.pageHeaderLabel = item.value === "attacks-blocked" ? "Success" : "Security";
        }

        let url = `/security/${context}/list/${this.start}/${this.end}?page=${this.page}&perPage=${this.perPage}`;
        fetchData(url, this.schoolId).then(res => {

            if(this.maxValue === 0) {
                this.maxValue = getMaxValue(res.data, context);
                this.resultsTotal = res.metadata.total;
            }

            this.data = this.data.concat(res.data.map(obj => mapResponse(obj, context, this.maxValue)));
            this.tableLoadingState = false;
        });
    }

    applyFilter(event) {
        this.doFilter(event.detail.value);
        this.load();
    }
}