module.exports = function (grunt) {
	// config grunt
	var config = {
		coffee: {
			compile: {
				files: {
					'build/resync.js': 'coffee/resync.coffee',

					'build/config/config.js': 'coffee/config/config.coffee',
                    'build/config/validation.js': 'coffee/config/validation.coffee',

					'build/parsing/parsers.js': 'coffee/parsing/parsers.coffee',

					'build/sync/sync_def.js': 'coffee/sync/sync_def.coffee',
                    'build/sync/sync_run.js': 'coffee/sync/sync_run.coffee',

					'test/parsing_test.js': 'test/parsing_test.coffee',

					'build/ssh/ssh_utils.js': 'coffee/ssh/ssh_utils.coffee',
					'build/ssh/explode.js': 'coffee/ssh/explode.coffee',

					'build/watch/watch.js': 'coffee/watch/watch.coffee'
				},
				options: {
					bare: true
				}
			}
		},
		clean: {
			build: [
                'build'
            ]
		},
		watch: {
			coffee: {
				files: ['**/*.coffee'],
				tasks: ['newer:coffee']
			}
		},
		copy: {
			jison_files: {
				flatten: true,
				expand: true,
				src: 'coffee/parsing/*.jison',
				dest: 'build/parsing/'
			}
		}
	};
	grunt.initConfig(config);

	// load tasks
	grunt.loadNpmTasks('grunt-contrib-coffee');
	grunt.loadNpmTasks('grunt-contrib-clean');
	grunt.loadNpmTasks('grunt-contrib-watch');
	grunt.loadNpmTasks('grunt-contrib-copy');
	grunt.loadNpmTasks('grunt-newer');

	// register tasks
	grunt.registerTask('default', ['init', 'watch']);
    grunt.registerTask('init', ['clean', 'coffee', 'copy']);
};
