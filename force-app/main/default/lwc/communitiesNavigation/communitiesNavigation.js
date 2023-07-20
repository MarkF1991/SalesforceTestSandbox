const getQueryParams = (queryStringFromUrl) => {
    let queryString = decodeURIComponent(queryStringFromUrl.substring(1));

    if (!queryString || queryString.trim().length <= 0) {
        return {};
    }

    let splitParams = queryString.split('&');
    let result = {};
    for (let i = 0; i < splitParams.length; i++) {
        let tmp = splitParams[i].split('=');
        if (tmp[0] && tmp[0].length > 0) {
            result[tmp[0]] = tmp.length > 1 ? tmp[1] : undefined;
        }
    }
    return result;
};

const queryParamsToString = (params) => {
    var str = [];
    for (let p in params)
        if (params.hasOwnProperty(p)) {
            str.push(encodeURIComponent(p) + "=" + encodeURIComponent(params[p]));
        }
    return str.join("&");
}

const pushStateToUrl = (queryParams) => {
    let nUrl = `${window.location.pathname}?${queryParamsToString(queryParams)}`;
    window.history.pushState({}, "Title", nUrl);
}

export { getQueryParams, pushStateToUrl, queryParamsToString };