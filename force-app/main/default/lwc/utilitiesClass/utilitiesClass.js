//TODO these need to be named to Model as Class is not a good name and should be refactored to separate model js files

const TileItemClass = () => {
    class myClass {
        constructor() {
            this.class = {
                id:null,
                title: null,
                value: "0",
                unit: null,
                path: '#',
                identifier: null,
                chip: {
                    label: null,
                    description: null,
                    image: {
                        type: null,
                        name: null,
                        classname: null,
                    }
                },
                ticker: {
                    trend: null,
                    value: 0,
                },
                route: {
                    page: null,
                    params: null
                },
                percentage: null
            }
        }
    }
    return new myClass().class;
};

const TileChipClass = () => {
    class myClass {
        constructor(){
            this.class = {
                id: null,
                label: null,
                description: null,
                image: {
                    type: null,
                    name: null,
                    class: null,
                }  
            }
        }
    }
    return new myClass().class;
};

const FilterItemClass = () => {
    class myClass {
        constructor(){
            this.class = {
                id: null,
                type: null,
                label: null,
                description: null,
                option: {
                    id: null, 
                    value: null, 
                    type: null,
                    label: null, 
                    description: null, 
                    alternativeText: null,
                    isChecked: false,
                    urlParam: {
                        start: null,
                        end: null
                        }
                    }
                
            }
        }
    }
    return new myClass().class;
};

export { TileItemClass, TileChipClass, FilterItemClass } ;