import { LightningElement, track } from 'lwc';
import { fireEvent } from 'c/pubsub';
import { getQueryParams } from "c/communitiesNavigation";
import { registerListener, unregisterAllListeners } from 'c/pubsub';
import { getIdFromTarget } from "c/utilitiesFunction";
import ReportingNavigationService from "./reportingNavigationService";

export default class ReportingNavigation extends LightningElement {
    @track selectedItem = 'dashboard';
    pageRef  = { attributes: { name: "nav" } };
    service = new ReportingNavigationService("dashboard");

    constructor() {
        super();
        this.onPopState = this.onPopState.bind(this);
    }

    connectedCallback() {
        this.queryParams = getQueryParams(window.location.search);
        const p = this.queryParams.p;
        this.setSelectedItem(p);
        registerListener('navigateToPage', this.handleNavigateToPage, this);
        window.addEventListener('popstate', this.onPopState);
    }

    onPopState() {
        let params = getQueryParams(window.location.search);
        if(this.selectedItem !== params.p) {
            this.setSelectedItem(params.p);
        }
    }

    handleNavigateToPage(selectedItem) {
        this.setSelectedItem(selectedItem.route);
    }

    setSelectedItem(p) {
        this.selectedItem = this.service.getSelectedItem(p);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
        window.removeEventListener('popstate', this.onPopState);
    }

    handleClick(event) {
        let routeLink = getIdFromTarget(event.target.id);
        // eslint-disable-next-line no-console
        console.log('link clicked', routeLink);
        this.setSelectedItem(routeLink);
        fireEvent(this.pageRef, 'navigateToPage', { route: this.selectedItem, args: {} });
    }
}