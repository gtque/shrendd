const path = require('path');

module.exports = {
    entry: './src/webview.ts',
    output: {
        filename: 'bundle.js',
        path: path.resolve(__dirname, 'media/bundled'),
        publicPath: '',
    },
    resolve: {
        extensions: ['.ts', '.js'],
    },
    module: {
        rules: [
            { test: /\.ts$/, use: 'ts-loader' },
            {
                test: /\.css$/,
                use: ['style-loader', 'css-loader'],
            },
        ],
    },
    mode: 'production'
};