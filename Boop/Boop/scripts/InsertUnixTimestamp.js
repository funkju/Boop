/**
    {
        "api":1,
        "name":"Current Unix Time",
        "description":"Inserts the current Unix timestamp at the cursor.",
        "author":"Justin Funk",
        "icon":"watch",
        "tags":"now,unix,timestamp,epoch,time,current,insert",
        "bias": 0.1
    }
**/

function main(state) {
    const now = Math.floor(Date.now() / 1000);
    state.insert(String(now));
    state.postInfo(new Date(now * 1000).toUTCString());
}
