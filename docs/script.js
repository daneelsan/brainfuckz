const inputLine = document.querySelector('.input-line');
const outputDiv = document.querySelector('.output');
let inputHistory = [];
let historyIndex = -1;

// Event listener to ensure the terminal input always has focus
// when a click event occurs outside the .input-container and .output.
document.addEventListener('click', function (event) {
	// Check if the clicked element or its parent is the .input-container or .output
	if (event.target.closest('.input-container') || event.target.closest('.output')) {
		// Allow default behavior (e.g., text selection, copying)
		return;
	}

	// If the click is outside the .input-container or .output, refocus the input field
	inputLine.focus();
});

inputLine.addEventListener('keydown', function (event) {
	switch (event.key) {
		case 'Enter':
			const input = inputLine.value;
			executeCommand(input);
			inputHistory.push(input);
			historyIndex = inputHistory.length;  // Reset the history index after a new command
			inputLine.value = '';  // Clear the input line
			break;
		case 'ArrowUp':
			if (historyIndex > 0) {
				historyIndex--;
				inputLine.value = inputHistory[historyIndex];
			}
			break;
		case 'ArrowDown':
			if (historyIndex < inputHistory.length - 1) {
				historyIndex++;
				inputLine.value = inputHistory[historyIndex];
			} else {
				inputLine.value = ''; // Clear the input line if at the most recent command
			}
			break;
	}
});

const commandTable = {
	'hello': () => {
		return 'Hello, User!'
	},
	'date': () => {
		return new Date().toLocaleString()
	},
	'clear': () => {
		outputDiv.innerHTML = '';  // Clear the terminal output
		return '';  // Return an empty string as the response since we don't want to display anything
	},
	'help': () => {
		// Return a list of available commands
		return 'Available commands: ' + Object.keys(commandTable).join(', ');
	},
	'echo': (arg) => {
		return arg;
	},
};

function executeCommand(input) {
	const parts = parseInput(input);
	const command = parts[0];
	const args = parts.slice(1);  // This will hold the arguments, if any

	let response;
	// Check if the command exists in the commandTable
	if (commandTable.hasOwnProperty(command)) {
		response = commandTable[command](...args);  // Execute the lambda to get the response
	} else {
		response = 'Unknown command: ' + command;
	}

	// If the command is 'clear', we don't want to append anything to the output
	if (command !== 'clear') {
		// Wrap the response in a div with a class "command-response"
		outputDiv.innerHTML += `<div class="command-response"> ${input}\n${response}</div>\n`;
	}

	// Refocus the input field
	inputLine.focus();
}

function parseInput(input) {
	// This regex matches three possible patterns:
	// 1. Sequences of characters that aren't spaces or quotes: [^\s"']+
	// 2. Sequences of characters inside double quotes: "([^"]*)"
	// 3. Sequences of characters inside single quotes: '([^']*)'
	const regex = /[^\s"']+|"([^"]*)"|'([^']*)'/g;

	const parts = [];  // This array will hold the parsed parts of the input
	let match;

	// The exec() method of a RegExp object returns an array of matched results.
	// It returns null when no more matches are found. 
	// Each time it's called, it continues from where it left off in the string.
	while (match = regex.exec(input)) {
		// If the match is inside double quotes, use that. 
		// Otherwise, if it's inside single quotes, use that. 
		// If neither, use the entire match.
		parts.push(match[1] ? match[1] : match[2] ? match[2] : match[0]);
	}

	return parts;  // Return the parsed parts as an array
}
