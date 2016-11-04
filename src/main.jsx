'use strict'; 
var React = require("react"),
	ReactDom = require("react-dom"),
	App = require("./app");

ReactDom.render(
	<App />,
	document.querySelector(".container")
);