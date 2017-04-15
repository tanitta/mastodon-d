module mastodon;

import std.net.curl:HTTP, post, get, patch, del;
import std.json:JSONValue, parseJSON;
import std.conv:to;

///
ClientConfig createApp(in string url, in string clientName, in string scopes, in string redirectUris = "urn:ietf:wg:oauth:2.0:oob"){
    auto res = post(url ~ "/api/v1/apps", [ "client_name"   : clientName,
                                            "redirect_uris" : redirectUris,
                                            "scope"         : scopes]).parseJSON;
    auto result = ClientConfig();
    result.url = url;
    result.id = res["client_id"].str;
    result.secret = res["client_secret"].str;
    return result;
}

///
JSONValue signIn(in string url, in string clientId, in string clientIdSeclet, in string email, in string password, in string scopes = "read write follow"){
    string[string] option = ["client_id" : clientId, 
                   "client_secret" : clientIdSeclet, 
                   "grant_type" : "password", 
                   "username" : email, 
                   "password" : password,
                   "scope" : scopes];
    auto response = post(url ~ "/oauth/token", option).parseJSON;
    return response;
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

        JSONValue request(Method M, T)(in string endPoint, T arg = null){
            auto http = HTTP(_clientToken.url);
            http.addRequestHeader("Authorization", "Bearer " ~ _userToken["access_token"].str);
            // http.handle.set(CurlOption.ssl_verifypeer, false);
            string url = _clientToken.url ~ endPoint;
            JSONValue response;

            static if(M == Method.GET){
                response = get(url, http).parseJSON;
            }
            static if(M == Method.POST){
                response = post(url, arg, http).parseJSON;
            }
            static if(M == Method.PATCH){
                response = patch(url, arg, http).parseJSON;
            }
            static if(M == Method.DELETE){
                del(url, http);
            }
        
            return response;
        }

        ///
        JSONValue account(in uint id){
            return request!(Method.GET)("/api/v1/accounts/" ~ id.to!string);
        }

        JSONValue verifyAccountCredentials(){
            return request!(Method.GET)("/api/v1/accounts/verify_credentials");
        }

        // JSONValue updateAccountCredentials(in string arg){
        // TODO doesn't work
        //     return request!(Method.PATCH)("/api/v1/accounts/update_credentials", arg);
        // }

        ///
        JSONValue accountFollowers(in uint id){
            return request!(Method.GET)("/api/v1/accounts/" ~ id.to!string ~ "/followers");
        }

        /// 
        JSONValue accountFollowing(in uint id){
            return request!(Method.GET)("/api/v1/accounts/" ~ id.to!string ~ "/following");
        }

        ///
        JSONValue accountStatuses(in uint id){
            return request!(Method.GET)("/api/v1/accounts/" ~ id.to!string ~ "/statuses");
        }

        ///
        JSONValue followAccount(in uint id){
            return request!(Method.GET)("/api/v1/accounts/" ~ id.to!string ~ "/follow");
        }

        ///
        JSONValue unfollowAccount(in uint id){
            return request!(Method.GET)("/api/v1/accounts/" ~ id.to!string ~ "/unfollow");
        }

        ///
        // GET /api/v1/accounts/:id/block
        JSONValue blockAccount(in uint id){
            return request!(Method.GET)("/api/v1/accounts/" ~ id.to!string ~ "/block");
        }

        ///
        JSONValue unblockAccount(in uint id){
            return request!(Method.GET)("/api/v1/accounts/" ~ id.to!string ~ "/unblock");
        }

        ///
        JSONValue muteAccount(in uint id){
            return request!(Method.GET)("/api/v1/accounts/" ~ id.to!string ~ "/mute");
        }

        ///
        JSONValue unmuteAccount(in uint id){
            return request!(Method.GET)("/api/v1/accounts/" ~ id.to!string ~ "/unmute");
        }

        /// 
        JSONValue accountRelationships(in uint[] id...){
            return accountRelationships(id);
        }

        ///
        JSONValue accountRelationships(in uint[] arr){
            import std.algorithm:map;
            import std.string:join;
            import std.conv:to;
            string qArray = arr.map!(e => "id[]=" ~ e.to!string).join("&");
            return request!(Method.GET)("/api/v1/accounts/relationships/?" ~ qArray);
        }

        ///
        JSONValue searchAccount(in string q, in uint limit = 40){
            import std.conv:to;
            return request!(Method.GET)("/api/v1/accounts/search/?q="~q~"&limit"~limit.to!string);
        }

        ///
        JSONValue blocks(){
            return request!(Method.GET)("/api/v1/blocks");
        }

        ///
        JSONValue favourites(){
            return request!(Method.GET)("/api/v1/favourites");
        }

        ///
        JSONValue followRequests(){
            return request!(Method.GET)("/api/v1/follow_requests");
        }

        /// TODO
        // POST /api/v1/follow_requests/authorize

        /// TODO
        // POST /api/v1/follow_requests/reject

        /// TODO
        // POST /api/v1/follows

        ///
        JSONValue instance(){
            return request!(Method.GET)("/api/v1/instance");
        }

        /// TODO
        // POST /api/v1/media

        ///
        JSONValue mutes(){
            return request!(Method.GET)("/api/v1/mutes");
        }

        ///
        JSONValue notifications(){
            return request!(Method.GET)("/api/v1/notifications");
        }

        ///
        JSONValue notifications(in uint id){
            import std.conv:to;
            return request!(Method.GET)("/api/v1/notifications/" ~ id.to!string);
        }

        ///
        JSONValue clearNotifications(){
            import std.conv:to;
            return request!(Method.GET)("/api/v1/notifications/clear");
        }

        ///
        JSONValue reports(){
            return request!(Method.GET)("/api/v1/reports");
        }

        /// TODO
        // POST /api/v1/reports

        /// TODO
        // GET /api/v1/search
        // JSONValue search(in string q, bool resolve = false){
        //     import std.conv:to;
        //     string qArray = "q="~q ~ resolve?"&resolve":"";
        //     return request!(Method.GET)("/api/v1/search/?" ~ qArray);
        // }

        ///
        JSONValue status(in uint id){
            import std.conv:to;
            return request!(Method.GET)("/api/v1/statuses/" ~ id.to!string);
        }

        ///
        JSONValue statusContext(in uint id){
            import std.conv:to;
            return request!(Method.GET)("/api/v1/statuses/" ~ id.to!string ~ "/context");
        }

        ///
        JSONValue statusCard(in uint id){
            import std.conv:to;
            return request!(Method.GET)("/api/v1/statuses/" ~ id.to!string ~ "/card");
        }

        ///
        JSONValue rebloggedBy(in uint id){
            import std.conv:to;
            return request!(Method.GET)("/api/v1/statuses/" ~ id.to!string ~ "/reblogged_by");
        }


        ///
        JSONValue favouritedBy(in uint id){
            import std.conv:to;
            return request!(Method.GET)("/api/v1/statuses/" ~ id.to!string ~ "/favourited_by");
        }

        /// TODO add params
        JSONValue postStatus(in string status){
            string[string] arg = ["status" : status];
            return request!(Method.POST)("/api/v1/statuses", arg);
        }

        /// TODO
        // DELETE /api/v1/statuses/:id
        JSONValue deleteStatus(in uint statusId){
            import std.conv:to;
            return request!(Method.DELETE)("/api/v1/statuses/"~statusId.to!string);
        }

        ///
        JSONValue reblog(in uint statusId){
            import std.conv:to;
            return request!(Method.POST)("/api/v1/statuses/"~statusId.to!string~"/reblog");
        }

        ///
        JSONValue unreblog(in uint statusId){
            import std.conv:to;
            return request!(Method.POST)("/api/v1/statuses/"~statusId.to!string~"/unreblog");
        }

        ///
        JSONValue favourite(in uint statusId){
            import std.conv:to;
            return request!(Method.POST)("/api/v1/statuses/"~statusId.to!string~"/favourite");
        }

        ///
        JSONValue unfavourite(in uint statusId){
            import std.conv:to;
            return request!(Method.POST)("/api/v1/statuses/"~statusId.to!string~"/unfavourite");
        }

        ///
        JSONValue timelineHome(){
            return request!(Method.GET)("/api/v1/timelines/home");
        }

        ///
        JSONValue timelinePublic(){
            return request!(Method.GET)("/api/v1/timelines/public");
        }

        ///
        JSONValue timelineHashtag(in string tag){
            return request!(Method.GET)("/api/v1/timelines/tag/" ~ tag);
        }
    }//public

    private{
        ClientConfig _clientToken;
        JSONValue _userToken;
    }//private
}//class Client

// /++
// +/
// struct Account {
//     // TODO
// }//struct Account
//
// /++
// +/
// struct Application {
//     // TODO
// }//struct Application
//
// /++
// +/
// struct Attachment {
//     // TODO
// }//struct Attachment
//
// /++
// +/
// struct Card {
//     // TODO
// }//struct Card
//
// /++
// +/
// struct Context {
//     // TODO
// }//struct Context
//
// /++
// +/
// struct Error {
//     // TODO
// }//struct Error
//
// /++
// +/
// struct Instance {
//     // TODO
// }//struct Instance
//
// /++
// +/
// struct Mention {
//     // TODO
// }//struct Mention
//
// /++
// +/
// struct Notification {
//     // TODO
// }//struct Notification
//
// /++
// +/
// struct Relationship {
//     // TODO
// }//struct Relationship
//
// /++
// +/
// struct Report {
//     // TODO
// }//struct Report
//
// /++
// +/
// struct Result {
//     // TODO
// }//struct Result
//
// /++
// +/
// struct Status {
//     // TODO
// }//struct Status
//
// /++
// +/
// struct Tag {
//     // TODO
// }//struct Tag
