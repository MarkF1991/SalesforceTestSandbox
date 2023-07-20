import { LightningElement, api, track } from 'lwc';

export default class CustomDateRangePicker extends LightningElement {
    @api fromDate = null;
    @api toDate = null;
    @track maxToDate = null;
    @track maxFromDate = null;
    @track isMomentInitialized = false;

    async connectedCallback() {
        try {
            // eslint-disable-next-line no-undef
            let t = moment();
            this.isMomentInitialized = !!t;
            if(this.isMomentInitialized) {
                if(this.fromDate === null && this.toDate === null) {
                    // eslint-disable-next-line no-undef
                    this.fromDate = this.getDateWithTimeZone(new Date(moment().subtract(1, "day").startOf('day').toISOString()));
                    // eslint-disable-next-line no-undef
                    this.toDate = this.getDateWithTimeZone(new Date(moment().subtract(1, "day").endOf('day').toISOString()));
                } else {
                    // eslint-disable-next-line no-undef
                    this.fromDate = this.getDateWithTimeZone(new Date(moment(this.fromDate).toISOString()));
                    // eslint-disable-next-line no-undef
                    this.toDate = this.getDateWithTimeZone(new Date(moment(this.toDate).toISOString()));
                }
                // eslint-disable-next-line no-undef
                this.maxToDate = moment().format("YYYY-MM-DD");
                // eslint-disable-next-line no-undef
                this.maxFromDate = moment().format("YYYY-MM-DD");
            }
        // eslint-disable-next-line no-empty
        } catch(err) {}
    }

    getDateWithTimeZone(d) {
        var timezone_offset_min = d.getTimezoneOffset(),
        offset_hrs = parseInt(Math.abs(timezone_offset_min/60), 10),
        offset_min = Math.abs(timezone_offset_min%60), timezone_standard;

        if(offset_hrs < 10)
            offset_hrs = '0' + offset_hrs;

        if(offset_min < 10)
            offset_min = '0' + offset_min;

        // Add an opposite sign to the offset
        // If offset is 0, it means timezone is UTC
        if(timezone_offset_min < 0)
            timezone_standard = '+' + offset_hrs + ':' + offset_min;
        else if(timezone_offset_min > 0)
            timezone_standard = '-' + offset_hrs + ':' + offset_min;
        else if(timezone_offset_min === 0)
            timezone_standard = 'Z';

        let dt = d,
            current_date = dt.getDate(),
            current_month = dt.getMonth() + 1,
            current_year = dt.getFullYear(),
            current_hrs = dt.getHours(),
            current_mins = dt.getMinutes(),
            current_secs = dt.getSeconds(),
            current_datetime;
        
        // Add 0 before date, month, hrs, mins or secs if they are less than 0
        current_date = current_date < 10 ? '0' + current_date : current_date;
        current_month = current_month < 10 ? '0' + current_month : current_month;
        current_hrs = current_hrs < 10 ? '0' + current_hrs : current_hrs;
        current_mins = current_mins < 10 ? '0' + current_mins : current_mins;
        current_secs = current_secs < 10 ? '0' + current_secs : current_secs;
        
        // Current datetime
        // String such as 2016-07-16T19:20:30
        current_datetime = current_year + '-' + current_month + '-' + current_date + 'T' + current_hrs + ':' + current_mins + ':' + current_secs;
        return current_datetime + timezone_standard;
    }

    getStartDate(d) {
        // eslint-disable-next-line no-undef
        return moment(d).startOf("day")
        .toISOString();
    }

    getEndDate(d) {
        // eslint-disable-next-line no-undef
        return moment(d).endOf("day")
            .toISOString();
    }

    handleFromChanged(event) {
        this.fromDate = event.detail.value;
        const selectedEvent = new CustomEvent('customdaterange', {detail: { from: this.getStartDate(this.fromDate), to: this.getEndDate(this.toDate) } });
        this.dispatchEvent(selectedEvent);
    }

    handleToChanged(event) {
        this.toDate = event.detail.value;
        const selectedEvent = new CustomEvent('customdaterange', {detail: { to: this.getEndDate(this.toDate), from: this.getStartDate(this.fromDate) } });
        this.dispatchEvent(selectedEvent);
    }
}