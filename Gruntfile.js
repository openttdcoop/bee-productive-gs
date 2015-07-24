module.exports = function(grunt) {

  grunt.registerTask('build', function() {
    shell = require('shelljs');
    var done = this.async();

    shell.exec('make'); // synchronous

    done();
  });

  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    watch: {
      scripts: {
        files: ['*.nut', 'lang/*.txt', '*.txt'],
        tasks: ['build'],
      },
    },
  });

  // Load the plugin that provides the "watch" task.
  grunt.loadNpmTasks('grunt-contrib-watch');

  // Default task(s).
  grunt.registerTask('default', ['build']);

};
