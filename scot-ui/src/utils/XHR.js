import axios from 'axios'

export async function get_data (endpoint, params) {
    if (params === null) {
        return await axios.get(endpoint)
    } else{
        return await axios.get(endpoint, {params: params});
    }
};

export async function post_data (endpoint, body) {
    if (body !== null){
        return await axios.post(endpoint, body);
    } else{
        return await axios.post(endpoint);
    }

}

export async function  put_data (endpoint, body){
    return await axios.put(endpoint, body);
};

export async function delete_data (endpoint){
     return await axios.delete(endpoint);
};