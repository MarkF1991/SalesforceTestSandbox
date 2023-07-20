import { LightningElement, track, api } from 'lwc';

import { loadScript } from 'lightning/platformResourceLoader';
import CHARTJS from '@salesforce/resourceUrl/chart';

export default class DonutChart extends LightningElement {

    @track error;
    chart;
    chartjsInitialized = false;
    config = {
        type: 'doughnut',
        data: {
            datasets: [],
            labels: []
        },
        options: {
            responsive: true,
            legend: {
                position: 'right',
                boxWidth: 10,
                padding: 100,
            },
            animation: {
                animateScale: true,
                animateRotate: true
            }
        }
    };
    
    @api get object() {
        return this._object;
    }

    set object(val) {
        this._object = val;
        if(this._object) {
            this.updateChart(this._object);
        }
    }

    updateChart(obj) {
        if(obj && this.chart) {

            let data = {
                dataset: {
                    data: [].concat(obj.series),
                    backgroundColor: [].concat(obj.backgroundColor),
                    label: 'Dataset 1'
                },
                labels: [].concat(obj.labels)
            }

            data.labels.forEach((label) => {
                if(!this.chart.data.labels.includes(label)) {
                    this.chart.data.labels.push(label);
                }
            }, this);
    
            if(this.chart.data.datasets.length === 0) {
                this.chart.data.datasets.push(data.dataset);
            }
            
            this.chart.update();
        }
    }

    connectedCallback() {
        
    }
    

    renderedCallback() {
    if (this.chartjsInitialized) {
        return;
    }

    this.chartjsInitialized = true;

    loadScript(this, CHARTJS)
            .then(() => {
                const ctx = this.template
                    .querySelector('canvas.donut')
                    .getContext('2d');

                this.chart = new window.Chart(ctx, this.config);
                this.updateChart(this._object);
            })
            .catch(error => {
                this.error = error;
            });

    }
}