'use strict';
var path = require("path");
var webpack = require("webpack");
var CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = {
	entry: [
		"./src/main.jsx"
	],
	output: {
		path: path.join(__dirname, "build"),
		publicPath: "http://localhost:8080/build",
		filename: "bundle.js"
	},
	module: {
		loaders: [
			{ test: /\.jsx$/, loader: 'jsx-loader?harmony' },
			{ test: /\.html?$/, loader: 'raw-loader' },
		    { test: /\.less$/, loader: 'style-loader!css-loader!less-loader' }, // use ! to chain loaders
		    { test: /\.css$/, loader: 'style-loader!css-loader' },
		    //{ test: /\.(png|jpg)$/, loader: 'url-loader?limit=104192' }, // inline base64 URLs for <=8k images, direct URLs for the rest
		    { test: /\.woff2?$/,   loader: "url-loader?prefix=font/&limit=5000&mimetype=application/font-woff" },
		    { test: /\.png$/, loader: "url-loader?mimetype=image/png" },
		    { test: /\.jpg$/, loader: "url-loader?mimetype=image/jpg" },
		    { test: /\.gif$/, loader: "url-loader?mimetype=image/gif" },
		    { test: /\.ttf$/,    loader: "file-loader" },
		    { test: /\.eot$/,    loader: "file-loader" },
		    { test: /\.svg$/,    loader: "file-loader" }
		]
	},
	resolve: {
	    extensions: ['', '.webpack.js', '.web.js', '.ts', '.tsx', '.js', '.jsx', '.json']
	},
	plugins: [
	    //把指定文件夹下的文件复制到指定的目录
	    new CopyWebpackPlugin([
		        {from: './src/index.html', to: '../index.html'}
	      	]
	    ),
	    new webpack.optimize.UglifyJsPlugin({
	      	compress: {
	        	warnings: false
	      	},
	      	output: {
	        	comments: false
	      	}
	    })
	]
};