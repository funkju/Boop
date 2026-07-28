/**
	{
		"api":1,
		"name":"Format JSON",
		"description":"Cleans and format JSON documents. Accepts JS-style object literals.",
		"author":"Ivan",
		"icon":"broom",
		"tags":"json,prettify,clean,indent,sloppy,literal"
	}
**/

function main(state) {
	try {
		state.text = JSON.stringify(JSON.parse(state.text), null, 2);
		return;
	}
	catch(error) {
		// Not strict JSON — try the lenient path below.
	}

	try {
		// JS-style literals: unquoted keys, single quotes, trailing commas.
		// Evaluate and re-serialize, which normalizes all of that away.
		// The Proxy scope makes bare-word *values* ({ happy: day }) resolve
		// to their own name as a string. Needs `with`, so no strict mode.
		const words = new Proxy({}, {
			has: function() { return true; },
			get: function(target, key) {
				if (typeof key !== "string") return undefined; // Symbol.unscopables
				return key === "undefined" ? undefined : key;
			}
		});
		const value = Function("scope", "with (scope) { return (" + state.text + ") }")(words);
		if (value === undefined || typeof value === "function") {
			throw new Error("not a value");
		}
		state.text = JSON.stringify(value, null, 2);
		state.postInfo("Sloppy JSON — normalized");
	}
	catch(error) {
		state.postError("Invalid JSON");
	}
}
