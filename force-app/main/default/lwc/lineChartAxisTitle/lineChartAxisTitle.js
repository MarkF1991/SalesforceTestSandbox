import { LightningElement, track } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import ChartistResource from '@salesforce/resourceUrl/chartistjs';
import ChartistAxisTitle from '@salesforce/resourceUrl/chartistAxisTitle';
import DATA from './data';

export default class lineChart extends LightningElement {

    @track error;
    


    @track chartistdata ;
   

    renderedCallback(){
      Promise.all([
        loadScript(this, ChartistResource + '/chartist.js'),
        loadStyle(this, ChartistResource + '/chartist.css'),
        loadScript(this, ChartistAxisTitle + '/chartistpluginaxistitle.js'),
        
      ])

      .then(() => {
        //line chart
        let canvas = this.template.querySelector('.ct-chart');

        this.chart = new Chartist.Line(canvas, 
          {
            labels: DATA.labels,
            series: DATA.series
          }
          , {
          fullWidth: true,
          showPoint: false,
          showArea: true,
          lineSmooth: false,
          chartPadding: {
            right: 40
          }
          
          ,plugins: [
            Chartist.plugins.ctAxisTitle({
              axisX: {
                axisTitle: 'Time (mins)',
                axisClass: 'ct-axis-title',
                offset: {
                  x: 0,
                  y: 50
                },
                textAnchor: 'middle'
              },
              axisY: {
                axisTitle: 'Goals',
                axisClass: 'ct-axis-title',
                offset: {
                  x: 0,
                  y: 0
                },
                textAnchor: 'middle',
                flipTitle: false
              }
            })
          ]
        });


      })
      .catch(error => {
        this.error = error;
      });

    }//reloadChartist




   
    ver = 'ver 1 line chart';
}