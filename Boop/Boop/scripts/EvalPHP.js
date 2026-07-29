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
	const code = state.text.replace(/\n+\/\/ (=>|!!) [^\n]*(\n\/\/    [^\n]*)*\s*$/, '');

	const result = __evalPHP(code);
	const marker = result.ok ? '// => ' : '// !! ';
	const lines = (result.ok ? result.output : result.error).split('\n');

	state.text = code + '\n' + marker + lines.shift() +
		lines.map(function (l) { return '\n//    ' + l; }).join('');

	if (!result.ok) {
		state.postError(result.error.split('\n')[0]);
	}
}
