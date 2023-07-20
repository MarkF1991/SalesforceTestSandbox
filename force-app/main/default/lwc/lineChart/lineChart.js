import { LightningElement, track } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import ChartistResource from '@salesforce/resourceUrl/chartistjs';
//import ChartistLegend from '@salesforce/resourceUrl/chartistlegend';
//import DATA from './data';

export default class lineChart extends LightningElement {
    
    @track error;
    chartjsInitialized = false;


    @track chartistdata ;
    @track chart1labels = [];
    @track chart1series = [];

    @track output4;
    fetchChartData(){
      //const url = "https://swapi.co/api/people/";
      //const url = "https://afternoon-gorge-62478.herokuapp.com/chartdata/1";
      //const url = "https://afternoon-gorge-62478.herokuapp.com/chartdata/" + this.selectedParamId ;
      const url = "https://boris.n4l.co.nz/n4l61baradenecoll-fw01/websites/daily/1550314800/1550833200/apple.com";
      const fetchParams = {  
          method: 'GET',
          mode: 'cors'
          };
      
      fetch(url, fetchParams)
      
      .then(res => {
        if (!res.ok) {
          throw new Error(res.statusText);
        }
        return res.json();
      }) 
      
      .then(data => {
          this.chartistdata = data;
          this.output4 = JSON.stringify(this.chartistdata);
          
          this.chart1labels = data.labels;
          this.chart1series.push(data.series);
          return data;
      })
      
      .catch(error => {
        this.error = error;
      });
    }

    fetchHerokuData(){
      const url = "https://afternoon-gorge-62478.herokuapp.com/chartdata/1";
      const fetchParams = {  
          method: 'GET',
          mode: 'cors'
          };
      
      fetch(url, fetchParams)
      
      .then(res => {
        if (!res.ok) {
          throw new Error(res.statusText);
        }
        return res.json();
      }) 
      
      .then(results => {
        this.chartistdata = results;
        this.output4 = JSON.stringify(this.chartistdata);
        
        this.chart1labels = results.labels;
        this.chart1series = results.series; //from Heroku, no need to make 2 dimension array
      })
      
      .catch(error => {
        this.error = error;
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
        //var dataSeries = [];

        this.fetchChartData(); //call funtion to fetch data: this my happen asynchronously!

        //this.fetchHerokuData(); //call funtion to fetch data: this my happen asynchronously!
        
        
        //prepare chart series in 2 dimensional array
        
        //dataSeries.push(DATA.series);
        //dataSeries.push(this.chartistdata.series);

        //this.output4 = JSON.stringify(this.chartistdata) + ' after fetchChartData dataSeries.jsonstringify = ' + dataSeries + ' | ';


        //line chart
        let canvas = this.template.querySelector('.ct-chart');

        this.chart = new Chartist.Line(canvas, 
          {
            //labels: DATA.labels,
            //series: DATA.series
            //labels: this.chartistdata.labels,
            labels: this.chart1labels,
            series: this.chart1series
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

        

        //this.output4 = JSON.stringify(this.chartistdata) + 'yes, chart is now generated   dataSeries.jsonstringify = ' + dataSeries + ' this error = ' + this.error;
      })
      .catch(error => {
        this.error = error;
      });

    }//reloadChartist




   
    ver = 'ver 1 line chart';
}