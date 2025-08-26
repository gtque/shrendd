    // Example webpack.config.js snippet
    const MonacoWebpackPlugin = require('monaco-editor-webpack-plugin');
    const path = require('path');

    module.exports = {
        entry: './src/webview.ts', // Your webview entry point
        output: {
            filename: 'bundle.js',
            // libraryTarget: 'commonjs2',
            path: path.resolve(__dirname, 'media/bundled'),
            publicPath: '', // Important for VS Code webview
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
                    // Do NOT add 'exclude: /node_modules/' here for Monaco Editor's CSS
                },
            ],
        },
        // ... other configurations like resolve, module rules
        plugins: [
            new MonacoWebpackPlugin({
                // Specify languages you need to include, e.g., 'typescript', 'javascript'
                languages: ['plaintext', 'shell'] 
            })
        ],
        mode: 'production'
    };