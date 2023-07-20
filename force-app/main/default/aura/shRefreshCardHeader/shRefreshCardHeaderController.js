({  
    showSubheading: function(component, event, helper) {
       // Set isModalOpen attribute to true
       component.set('v.isSubheadingVisible', true);
    },
   
    hideSubheading: function(component, event, helper) {
       // Set isModalOpen attribute to false  
       component.set('v.isSubheadingVisible', false);
    }, 
});
({  
    showButton: function(component, event, helper) {
       // Set isModalOpen attribute to true
       component.set('v.isButtonVisible', true);
    },
   
    hideButton: function(component, event, helper) {
       // Set isModalOpen attribute to false  
       component.set('v.isButtonVisible', false);
    }, 
});
({   
    showBottomBorder: function(component, event, helper) {
        // Set isModalOpen attribute to true
        component.set('v.isBorderVisible', true);
     },
    
     hideBottomBorder: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set('v.isBorderVisible', false);
     }, 
 })