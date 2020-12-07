/**
 * JSON API Strategy for DocBox
 * <br>
 * <small><em>Copyright 2015 Ortus Solutions, Corp <a href="www.ortussolutions.com">www.ortussolutions.com</a></em></small>
 */
component extends="docbox.strategy.AbstractTemplateStrategy" accessors="true"{

	/**
	 * The output directory
	 */
	property name="outputDir" type="string";

	/**
	 * The project title to use
	 */
	property name="projectTitle" default="Untitled" type="string";

	// Static variables.
	variables.static.TEMPLATE_PATH	= "/docbox/strategy/json/resources/templates";
	variables.static.ASSETS_PATH 	= "/docbox/strategy/json/resources/static";

	/**
	 * Constructor
	 * 
	 * @outputDir The output directory
	 * @projectTitle The title used in the HTML output
	 */
	component function init( required outputDir, string projectTitle="Untitled" ){
		super.init();

		variables.outputDir 	= arguments.outputDir;
		variables.projectTitle 	= arguments.projectTitle;

		return this;
	}

	/**
	 * Generate JSON documentation
	 * 
	 * @metadata All component metadata, sourced from DocBox.
	 */
	component function run( required query metadata ){
		ensureDirectory( getOutputDir() );

		var classes = normalizePackages(
			arguments.metadata.reduce( ( results, row ) => {
				results.append( row );
				return results;
			}, [])
		);

		/**
		 * Generate hierarchical JSON package indices with classes
		 */
		var packages = classes.reduce( function( results, class ) {
			if ( !results.keyExists( class.package ) ){
				results[ class.package ] = [];
			}
			results[ class.package ].append( class );
			return results;
		}, {});

		/**
		 * Generate top-level JSON package index
		 */
		serializeToFile(
			getOutputDir() & "/overview-summary.json",
			buildOverviewSummary( classes, packages )
		);

		/**
		 * Output a hierarchical folder structure which matches the original package structure -
		 * Including an index.json file for each package level.
		 */
		packages.each( ( package, classes ) => {
			var path = getOutputDir() & "/" & replace( package, ".", "/", "all" );
			if ( !directoryExists( path ) ){
				directoryCreate( path );
			}
			classes.each( ( class ) => {
				serializeToFile(
					"#path#/#class.name#.json",
					class
				);
			});

			/**
			 * Generate JSON package index for this package level
			 */
			serializeToFile(
				path & "/package-summary.json",
				buildPackageSummary( classes )
			);
		});

		return this;
	}

	/**
	 * Marshall component names and paths into a package-summary.json file for each package hierarchy level
	 *
	 * @classData Component metadata sourced from DocBox
	 * @packages Array of packages for linking to package summary files
	 */
	package struct function buildOverviewSummary( required array classData, required struct packages ){
		return {
			"classes" : buildPackageSummary( arguments.classData ).classes,
			"packages" : arguments.packages.map( ( package ) => {
				return {
					"name" : package,
					"path" : "#replace( package , ".", "/", "all" )#/package-summary.json"
				}
			}),
			"title" : getProjectTitle()
		};
	}

	/**
	 * Marshall component names and paths into a package-summary.json file for each package hierarchy level
	 *
	 * @classData Component metadata sourced from DocBox
	 */
	package struct function buildPackageSummary( required array classData ){
		return {
			"classes" : arguments.classData.map( ( class ) => {
				return {
					"name" : class.name,
					"path" : "#replace( class.package , ".", "/", "all" )#/#class.name#.json"
				}
			})
		};
	}

	/**
	 * Normalize component metadata into a serializable package-component data format.
	 *
	 * @classData Component metadata, courtesy of DocBox
	 */
	package array function normalizePackages( required array classData ){
		return arguments.classData.map( function( row ) {
			/**
			 * Marshall functions to match the designed schema;
			 */
			if ( !isNull( row.metadata.functions ) ){
				var metaFunctions = row.metadata.functions.map( ( method ) => {
					return {
						"returnType" : method.returnType,
						"returnFormat" : method.returnFormat,
						"parameters" : method.parameters,
						"name" : method.name,
						"hint" : method.keyExists( "hint" ) ? method.hint : "",
						"description" : method.keyExists( "description" ) ? method.description : "",
						"access" : method.access,
						"position" : method.position
					}
				} );
			}
			return {
				"name" : row.name,
				"package" : row.package,
				"type" : row.type,
				"extends" : structKeyExists( row.metadata, "extends" ) ? row.extends : "",
				"fullextends" : structKeyExists( row.metadata, "fullextends" ) ? row.fullextends : "",
				"hint" : structKeyExists( row.metadata, "hint" ) ? row.metadata.hint : "",
				"functions" : structKeyExists( row.metadata, "functions" ) ? metaFunctions : []
			};
		});
	}

	package struct function reducePackages( classData ){
		return classData.reduce( function( result, class ) {
			if ( !classData.keyExists( class.package ) ){
				result[ class.package ] = [];
			}
			arrayAppend( result[ class.package ], class );
			return result;
		}, {});
	}

	/**
	 * Serialize the given @data into JSON and write to @path.
	 *
	 * @path Full path and filename of the file to create or overwrite.
	 * @data Must be JSON-compatible... so either an array or a struct.
	 */
	package function serializeToFile( required string path, required any data ){
        fileWrite( arguments.path, serializeJSON( arguments.data, true ) );
	}
}