import { fetchData } from "c/utilitiesFunction";

export default class UserProfileService {
  getUserDetails = (schoolId, start, end, userId) => {
    return fetchData(`/user/${userId}/${start}/${end}`, schoolId).then(res => {
      let data = res.data;

      return {
        id: data.userId,
        groups: data.userGroup || []
      }
    });
  }
}