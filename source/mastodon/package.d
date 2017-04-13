module mastodon;

import std.net.curl;
import std.json;
import std.conv:to;

///
ClientConfig createApp(in string url, in string clientName, in string scopes, in string redirectUris = "urn:ietf:wg:oauth:2.0:oob"){
    auto res = post(url ~ "/api/v1/apps", [ "client_name" : clientName,
                                               "redirect_uris" : redirectUris,
                                               "scope" : scopes]).parseJSON;
    auto result = ClientConfig();
    result.url = url;
    result.id = res["client_id"].str;
    result.secret = res["client_secret"].str;
    return result;
}

///
JSONValue signIn(in string url, in string clientId, in string clientIdSeclet, in string email, in string password){
    string[string] option = ["client_id" : clientId, 
                   "client_secret" : clientIdSeclet, 
                   "grant_type" : "password", 
                   "username" : email, 
                   "password" : password,];
    return post(url ~ "/oauth/token", option).parseJSON;
}

///
JSONValue signIn(in JSONValue clientConfig, in string email, in string password){
    import std.algorithm:filter;
    import std.array:array;
    return signIn(clientConfig["url"].str.filter!(e => e!='\\').to!string, clientConfig["client_id"].str, clientConfig["client_secret"].str, email, password);
}

JSONValue signIn(in ClientConfig clientConfig, in string email, in string password){
    return signIn(clientConfig.url, clientConfig.id, clientConfig.secret, email, password);
}

//TODO
// auto signInAndSaveTokens(in string clientId, in string clientIdSeclet, in string config, in string email, in string password, in string path){
// }

/++
+/
class Auth {
    public{
    }//public

    private{
    }//private
}//class Auth

/++
+/
struct ClientConfig {
    public{
        this(in string url, in string id, in string secret){
            this.url    = url;
            this.id     = id;
            this.secret = secret;
        }
        this(JSONValue v){
            url    = v["url"].str;
            id     = v["client_id"].str;
            secret = v["client_secret"].str;
        }
        string url;
        string id;
        string secret;
    }//public

    private{
    }//private
}//struct ClientConfig

/++
+/
class Client {
    private alias This = typeof(this);
    public{
        this(in ClientConfig clientToken){
            _clientToken = clientToken;
        }

        This signIn(in string email, in string password){
            _userToken = _clientToken.signIn(email, password);
            return this;
        };

        JSONValue request(){
            auto http = HTTP(_clientToken.url);
            http.addRequestHeader("Authorization", "Bearer " ~ _userToken["access_token"].str);
            string url = _clientToken.url ~ "/api/v1/timelines/home";
            return get(url, http).parseJSON;
        }
    }//public

    private{
        ClientConfig _clientToken;
        JSONValue _userToken;
    }//private
}//class Client
