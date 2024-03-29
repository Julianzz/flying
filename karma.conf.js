// Karma configuration
// Generated on Wed Mar 05 2014 01:03:45 GMT+0800 (CST)

module.exports = function(config) {
  config.set({

    // base path, that will be used to resolve files and exclude
    basePath: '',


    // frameworks to use
    frameworks: ['mocha',"chai"],


    // list of files / patterns to load in the browser
    files: [
      "public/lib/jquery.js",
      "public/lib/q.js",
      "public/lib/socket.io.js",
      "public/lib/bootstrap.min.js",
      "public/lib/ace/*.js",
      "public/javascripts/vendor.js",
      "public/javascripts/app.js",
      "public/lib/sinon-1.9.1.js",
      "./specs/web/*.coffee",
      "./specs/web/*.js"
    ],


    preprocessors: {
      './specs/web/*.coffee': ['coffee']
    },

    coffeePreprocessor: {
      // options passed to the coffee compiler
      options: {
        bare: true,
        sourceMap: false
      },
      // transforming the filenames
      transformPath: function(path) {
        return path.replace(/\.coffee$/, '.js');
      }
    },

    // list of files to exclude
    exclude: [
      
    ],

    client: {
      mocha: {
        ui: 'bdd'
      }
    },


    // test results reporter to use
    // possible values: 'dots', 'progress', 'junit', 'growl', 'coverage'
    reporters: ['progress'],


    // web server port
    port: 9876,


    // enable / disable colors in the output (reporters and logs)
    colors: true,


    // level of logging
    // possible values: config.LOG_DISABLE || config.LOG_ERROR || config.LOG_WARN || config.LOG_INFO || config.LOG_DEBUG
    logLevel: config.LOG_INFO,


    // enable / disable watching file and executing tests whenever any file changes
    autoWatch: true,


    // Start these browsers, currently available:
    // - Chrome
    // - ChromeCanary
    // - Firefox
    // - Opera (has to be installed with `npm install karma-opera-launcher`)
    // - Safari (only Mac; has to be installed with `npm install karma-safari-launcher`)
    // - PhantomJS
    // - IE (only Windows; has to be installed with `npm install karma-ie-launcher`)
    browsers: ['Firefox'],


    // If browser does not capture in given timeout [ms], kill it
    captureTimeout: 60000,


    // Continuous Integration mode
    // if true, it capture browsers, run tests and exit
    singleRun: false
  });
};
