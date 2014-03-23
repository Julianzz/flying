module.exports = function(grunt) {
  require('load-grunt-tasks')(grunt);  
  grunt.loadNpmTasks('grunt-mocha');
  // Project configuration.
  grunt.initConfig({
    jasmine_node: {
      options: {
        forceExit: true,
        match: '.',
        matchall: false,
        extensions: 'coffee',
        coffee: true,
        specNameMatcher: 'Spec',
        jUnit: {
          report: true,
          savePath : "./build/reports/jasmine/",
          useDotNotation: true,
          consolidate: true
        }
      },
      
      all: ['specs/']
    },
    watch: {
      options: {
        livereload: true,
      },
      express: {
        files:  [ 'index.js' ,"*.coffee", "server/*.coffee","server/*/*.coffee" ],
        tasks:  [ 'express:dev' ],
        options: {
          spawn: false
        }
      }
    },
    express: {
      options: {
        // Override defaults here
      },
      dev: {
        options: {
          script: 'index.js'
        }
      }
    }
  });

  grunt.registerTask('default', ['express:dev','watch:express' ]);
  
};