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
    /++
        +/
    private enum Method {
        GET, POST, DELETE, PATCH
    }//enum Method
    public{
        this(in ClientConfig clientToken){
            _clientToken = clientToken;
        }

        This signIn(in string email, in string password){
            _userToken = _clientToken.signIn(email, password);
            return this;
        };

        JSONValue request(in Method method, in string endPoint, in JSONValue arg = null){
            auto http = HTTP(_clientToken.url);
            http.addRequestHeader("Authorization", "Bearer " ~ _userToken["access_token"].str);
            string url = _clientToken.url ~ endPoint;
            JSONValue response;
            switch (method) {
                case Method.GET:
                    response = get(url, http).parseJSON;
                    break;
                case Method.PATCH:
                    response = patch(url, arg.str, http).parseJSON;
                    break;
                default:
                    assert(false);
            }
            return response;
        }

        ///
        JSONValue account(in uint id){
            return request(Method.GET, "/api/v1/accounts/" ~ id.to!string);
        }

        /// TODO accountVerify

        /// TODO accountUpdateCredentials

        /// TODO accountFollowers

        /// TODO accountFollowing
        // GET /api/v1/accounts/:id/following

        /// TODO accountStatuses
        // GET /api/v1/accounts/:id/statuses

        /// TODO 
        // GET /api/v1/accounts/:id/follow

        /// TODO 
        // GET /api/v1/accounts/:id/unfollow

        /// TODO
        // GET /api/v1/accounts/:id/block

        /// TODO
        // GET /api/v1/accounts/:id/unblock

        /// TODO
        // GET /api/v1/accounts/:id/mute

        /// TODO
        // GET /api/v1/accounts/:id/unmute

        /// TODO
        // GET /api/v1/accounts/relationships

        /// TODO
        // GET /api/v1/accounts/search

        /// TODO
        // GET /api/v1/blocks

        /// TODO
        // GET /api/v1/favourites

        /// TODO
        // GET /api/v1/follow_requests

        /// TODO
        // POST /api/v1/follow_requests/authorize

        /// TODO
        // POST /api/v1/follow_requests/reject

        /// TODO
        // POST /api/v1/follows

        /// TODO
        // GET /api/v1/instance

        /// TODO
        // POST /api/v1/media

        /// TODO
        // GET /api/v1/mutes

        /// TODO
        // GET /api/v1/notifications

        /// TODO
        // GET /api/v1/notifications/:id

        /// TODO
        // POST /api/v1/notifications/clear

        /// TODO
        // GET /api/v1/reports

        /// TODO
        // POST /api/v1/reports

        /// TODO
        // GET /api/v1/search

        /// TODO
        // GET /api/v1/statuses/:id

        /// TODO
        // GET /api/v1/statuses/:id/context

        /// TODO
        // GET /api/v1/statuses/:id/card

        /// TODO
        // GET /api/v1/statuses/:id/reblogged_by

        /// TODO
        // GET /api/v1/statuses/:id/favourited_by

        /// TODO
        // POST /api/v1/statuses

        /// TODO
        // DELETE /api/v1/statuses/:id

        /// TODO
        // POST /api/v1/statuses/:id/reblog

        /// TODO
        // POST /api/v1/statuses/:id/unreblog

        /// TODO
        // POST /api/v1/statuses/:id/favourite

        /// TODO
        // POST /api/v1/statuses/:id/unfavourite

        /// TODO
        //GET /api/v1/timelines/home

        /// TODO
        // GET /api/v1/timelines/public

        /// TODO
        // GET /api/v1/timelines/tag/:hashtag
    }//public

    private{
        ClientConfig _clientToken;
        JSONValue _userToken;
    }//private
}//class Client
