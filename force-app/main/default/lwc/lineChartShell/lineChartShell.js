import { LightningElement, track, api } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import ChartistResource from '@salesforce/resourceUrl/chartistjs';
//import ChartistLegend from '@salesforce/resourceUrl/chartistlegend';


export default class lineChartShell extends LightningElement {
    @api labels;
    @api series;
    @api charttitle;

    @track error;
    chartjsInitialized = false;

    @api
    refresh() {
      let canvas = this.template.querySelector('.ct-chart');

      this.chart = new Chartist.Line(canvas, 
        {
          labels: this.labels,
          series: this.series
        }, {
        fullWidth: true,
        showPoint: false,
        showArea: true,
        lineSmooth: false,
        chartPadding: {
          right: 40
        }
        
      });  

        
    }


    renderedCallback(){
      
      if (this.chartjsInitialized) {
        return;
      }
      this.chartjsInitialized = true;
      
     
      Promise.all([
        loadScript(this, ChartistResource + '/chartist.js'),
        loadStyle(this, ChartistResource + '/chartist.css'),
        //loadScript(this, ChartistLegend + '/chartist-plugin-legend.js'),
        //loadStyle(this, ChartistLegend + '/chartist-plugin-legend.css'),
      ])

      .then(() => {
        //line chart
        let canvas = this.template.querySelector('.ct-chart');

        this.chart = new Chartist.Line(canvas, 
          {
            labels: this.labels,
            series: this.series
          }, {
          fullWidth: true,
          showPoint: false,
          showArea: true,
          lineSmooth: false,
          chartPadding: {
            right: 40
          }
          /*,
          plugins: [
              Chartist.plugins.legend({
                  legendNames: ['Blue pill', 'Red pill', 'Purple pill'],
              })
          ]*/
        });

        
      })
      .catch(error => {
        this.error = error;
      });


    }

    

    
   
}