import { track, api } from "lwc";
import { getQueryParams, pushStateToUrl } from "c/communitiesNavigation";
import { fetchData } from "c/utilitiesFunction";
import { mapResponse, getMaxValue } from "./contentListViewMapper";
import { items } from './contentListViewMenuDefinition';
import GenericListViewComponent from 'c/genericListViewComponent';
import { registerListener, unregisterAllListeners } from "c/pubsub";
import { cleanId } from "c/utilitiesFunction";

export default class ContentListView extends GenericListViewComponent {
    pageHeaderLabel = "Content";
    @track view = "websites-browsing-time";
    userid = null;
    deviceId = null;
    categoryId = null;
    appId = null;
    @api disableHeader = false;
    @api disableHeaderFilter = false;
    @api overrideCssClass = "list-container";
    pageRef = { attributes: { name: "nav" } };
    menuItems = items;
    
    constructor() {
        super();
        this.onScoll = this.onScoll.bind(this);
    }

    async connectedCallback() {
        this.queryParams = getQueryParams(window.location.search);

        if(this.overrideView) {
            this.view = this.overrideView;
            this.disableSelectionMenu = true;
        }

        if (this.queryParams.schoolId) {
            this.schoolId = this.queryParams.schoolId;
            this.start = this.queryParams.start;
            this.end = this.queryParams.end;
            this.page = this.queryParams.page ? parseInt(this.queryParams.page, 10) : parseInt(this.page, 10);
            this.perPage = this.queryParams.perPage ? this.queryParams.perPage : parseInt(this.perPage, 10);
            this.selectedfilter.dateFilter.start = this.start;
            this.selectedfilter.dateFilter.end = this.end;

            this.refresh();
        }

        window.addEventListener('scroll', this.onScoll);

        if(this.disableHeader) {
            this.disableHeaderFilter = true;
        }

        if(this.disableHeaderFilter) {
            registerListener("filterChanged", this.handleFilterChanged, this);
            registerListener('navigationChanged', this.handleNavigationChanged, this);
        }
    }

    refresh() {
        if(this.queryParams.view) {
            this.view = this.overrideView ? this.view : this.queryParams.view;
        }
        this.deviceId = cleanId(this.queryParams.deviceid);
        this.userid = cleanId(this.queryParams.userid);
        this.categoryId = cleanId(this.queryParams.categoryid);
        this.appId = cleanId(this.queryParams.appid);
        this.data = [];
        this.load();
    }

    handleNavigationChanged(event) {
        if(event.args && event.args.params
            && event.args.params.curtab === 'websites'
            && event.args.params.view !== this.view) {
            this.queryParams = getQueryParams(window.location.search);
            this.maxValue = 0;
            this.refresh();
        }
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
        window.removeEventListener('scroll', this.onScoll);
    }

    onScoll() {
        if(!this.disableInfiteScroll) {
            if(this.resultsTotal > this.page * this.perPage && !this.tableLoadingState && (window.scrollY > this.template.querySelector("c-reporting-data-table[id^='content-table']").height - ( window.screen.height))) {
                this.page += 1;
                this.load();
                this.sendAnalyticsEvent('WebsitesListView', 'scroll', `Page ${this.page}`);
            }
        }
    }

    handleFilterChanged(event) {
        if(this.disableHeaderFilter) {
            this.doFilter(event.filters);

            this.load();
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
        let sort = "bandwidth";
        let context = "website";
        let item = this.getMenuItemForView(this.view);
        if(item) {
            sort = item.sort;
            context = item.context;
            this.columns = item.columns;
            this.overridePageHeaderTitle = this.overrideView ? item.label : null;
        }

        let url = `/content/${context}/list/${this.start}/${this.end}?sort=${sort}&page=${this.page}&perPage=${this.perPage}`;

        if(this.deviceId) {
            url += `&device=${this.deviceId}`;
        }

        if(this.userid) {
            url += `&user=${this.userid}`;
        }

        if(this.categoryId) {
            url += `&category=${this.categoryId}`;
        }

        // eslint-disable-next-line no-unused-vars
        fetchData(url, this.schoolId).then(res => {

            if(this.maxValue === 0) {
                this.maxValue = getMaxValue(res.data, sort);
                this.resultsTotal = res.metadata.total;
            }

            this.data = this.data.concat(res.data.map(obj => mapResponse(obj, sort, this.maxValue, this.queryParams)));
            this.tableLoadingState = false;
        });
    }

    applyFilter(event) {
        if(!this.disableHeaderFilter) {
            this.doFilter(event.detail.value);

            this.load();
        }
    }
}