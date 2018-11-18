const path = require("path");
const HtmlWebPackPlugin = require("html-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const autoprefixer = require("autoprefixer");
const cssnano = require("cssnano");
const UglifyJsPlugin = require("uglifyjs-webpack-plugin");

// https://webpack.js.org/plugins/html-webpack-plugin/
const htmlPlugin = new HtmlWebPackPlugin({
  template: "public/index.html",
  favicon: "public/favicon.png",
  // filename: "index.html",
  minify: {
    removeComments: true,
    collapseWhitespace: true,
    useShortDoctype: true,
    removeRedundantAttributes: true,
    removeEmptyAttributes: true,
    removeStyleLinkTypeAttributes: true,
    keepClosingSlash: true,
    minifyJS: true,
    minifyCSS: true,
    minifyURLs: true,
  },
});

const extractCssPlugin = new MiniCssExtractPlugin({
  filename: "[name].[hash:8].css",
  chunkFilename: "[id].[hash:8].css",
});

module.exports = (env, argv) => {
  const isProduction = argv.mode === "production";
  const plugins = [htmlPlugin, extractCssPlugin];
  const devtool = isProduction ? false : "eval-source-map";
  const elmLoaderOptions = isProduction ? { optimize: true } : { debug: true };

  return {
    entry: "./src/index.js",

    output: {
      path: path.resolve(__dirname, "build"),
      filename: "[name].[hash:8].js",
      publicPath: "/",
    },

    plugins,

    devtool,

    module: {
      rules: [
        {
          test: /\.elm$/,
          exclude: [/elm-stuff/, /node_modules/],
          use: [
            "elm-hot-webpack-loader",
            {
              loader: "elm-webpack-loader",
              options: elmLoaderOptions,
            },
          ], // order matters
        },
        {
          test: /\.(css|scss)$/,
          use: [
            isProduction ? MiniCssExtractPlugin.loader : "style-loader",
            "css-loader",
            {
              loader: "postcss-loader",
              options: { ident: "postcss", plugins: [autoprefixer(), cssnano()] },
            },
            "sass-loader",
          ],
        },
        {
          test: /\.(eot|woff|woff2|ttf|svg|png|jpg|gif)$/,
          loader: "url-loader",
          options: { limit: 4096, name: "[name].[hash:8].[ext]" },
        },
      ],
    },

    devServer: {
      // host: "0.0.0.0", //makes server accessible over local network
      port: 3000,
      compress: true,
      overlay: true,
      historyApiFallback: true, // redirect 404 to index.html
      stats: "minimal",
    },

    stats: { children: false, modules: false, moduleTrace: false },

    performance: { hints: false },

    optimization: {
      minimizer: [
        // https://github.com/webpack-contrib/uglifyjs-webpack-plugin#options
        new UglifyJsPlugin({
          parallel: true,
          uglifyOptions: {
            compress: {
              // prettier-ignore
              pure_funcs: ['F2','F3','F4','F5','F6','F7','F8','F9','A2','A3','A4','A5','A6','A7','A8','A9'],
              pure_getters: true,
              keep_fargs: false,
              unsafe_comps: true,
              unsafe: true,
            },
            mangle: false,
          },
        }),
        new UglifyJsPlugin({
          parallel: true,
          uglifyOptions: {
            mangle: true,
          },
        }),
      ],
    },
  };
};
