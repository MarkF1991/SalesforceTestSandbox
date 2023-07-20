export default function fetchDataHelper({ url }) {
    const fetchParams = {  
        method: 'GET',
        mode: 'cors'
        };

    return fetch(url, fetchParams).then(response => response.json());
    
}