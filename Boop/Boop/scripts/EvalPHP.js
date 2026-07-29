/**
	{
		"api":1,
		"name":"Eval PHP",
		"description":"Runs your text as PHP and appends the output.",
		"author":"Justin's fork",
		"icon":"command",
		"tags":"php,eval,run,execute,script"
	}
**/

function main(state) {
	// Same trailing block as ⌘↩ Run Buffer, so the two compose.
	const code = state.text.replace(/\n+\/\/ => [^\n]*(\n\/\/    [^\n]*)*\s*$/, '');

	const result = __evalPHP(code);
	if (!result.ok) {
		state.postError(result.error);
		return;
	}

	const lines = result.output.split('\n');
	state.text = code + '\n// => ' + lines.shift() +
		lines.map(function (l) { return '\n//    ' + l; }).join('');
}
