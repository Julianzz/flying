sysPath = require 'path'
startsWith = (string, substring) ->
  string.lastIndexOf(substring, 0) is 0

exports.config =
  server:
    path: 'server.coffee'
  paths:
    'public': 'public'
  conventions:
    ignored: (path) -> startsWith(sysPath.basename(path), '_')
  workers:
    enabled: false  # turned out to be much, much slower than without workers
  files:
    javascripts:
      #defaultExtension: 'coffee'
      joinTo:
        'javascripts/app.js': /^app/
        'javascripts/vendor.js': /^bower_components/
        'test/javascripts/test.js': /^test[\/\\](?!vendor)/
        'test/javascripts/test-vendor.js': /^test[\/\\](?=vendor)/
      order:
        before: [
          'bower_components/jquery/jquery.js'
          'bower_components/underscore/underscore.js'
          "bower_components/underscore.string/lib/underscore.string.js"
          'bower_components/backbone/backbone.js'
        ]
    stylesheets:
      defaultExtension: 'sass'
      joinTo:
        'stylesheets/app.css': /^(app|vendor)/
      order:
        before: ['app/styles/bootstrap.scss']
    templates:
      defaultExtension: 'jade'
      joinTo: 'javascripts/app.js'
      
  framework: 'backbone'

  plugins:
    uglify:
      output:
        semicolons: false
