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
		const value = Function('"use strict"; return (' + state.text + ')')();
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
