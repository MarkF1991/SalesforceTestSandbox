import { fetchData } from "c/utilitiesFunction";

export default class InfectionProfileService {
    infectionInformationFetchData = (schoolId, infection, start, end) => {
        return fetchData(`/security/infection/${infection}/${start}/${end}`, schoolId).then(res => {
            let data = res.data || [];
            let result = {
                infectionType: data.length > 0 ? data[0].threatType : "Unknown",
                deviceCount: data.length > 0 ? data[0].deviceCount : "-"
            };
            return result;
        });
    };
}