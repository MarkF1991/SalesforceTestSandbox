function partialURL(exclude_s) {
    let origin = window.location.origin;
    let urlPath = window.location.pathname;
    let community= '';
    
    if(exclude_s){
        community = urlPath.substring(0,urlPath.indexOf("/s/") + 1); //for visualforce page in community
    } else {
        community = urlPath.substring(0,urlPath.indexOf("/s/") + 3); //for common community pages
    }
    
    return `${origin}${community}`;
}

function resolveSupportHubEnvironment() {
    var hostname = window.location.hostname;
 
    if (hostname.includes("support.n4l.co.nz")) {
      return "production";
    }
  
    if(hostname.startsWith("test-n4lportal")) {
      return "test";
    }
  
    return "development";
  }

export {
    partialURL,
    resolveSupportHubEnvironment
};