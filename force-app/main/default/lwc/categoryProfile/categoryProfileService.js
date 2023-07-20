import { fetchData } from "c/utilitiesFunction";

const categoryInformationFetchData = (schoolId, category) => {
  // eslint-disable-next-line no-unused-vars
  return fetchData(`/content/category/${category}`, schoolId).then(res => {
    let data = res.data;

    let result = {
      information: data.description,
      blocked: data.blocked,
    };
    return result;
  });

};

export { categoryInformationFetchData};