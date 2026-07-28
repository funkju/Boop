/**
    {
        "api":1,
        "name":"Current ISO Time",
        "description":"Inserts the current time as ISO 8601 at the cursor.",
        "author":"Justin Funk",
        "icon":"watch",
        "tags":"now,iso,8601,date,time,current,insert,utc"
    }
**/

function main(state) {
    state.insert(new Date().toISOString());
}
