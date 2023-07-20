import { fetchData } from "c/utilitiesFunction";
  
export default class ContentProfileService {
    getWebsiteInformation = (schoolId, websiteid, start, end) => {
        return fetchData(`/website/${websiteid}/${start}/${end}`, schoolId).then(res => {
            let data = res.data;

            return {
                name : data.name,
                categories: data.categories.map((cat) => cat.value)
            }
        });
    };
}