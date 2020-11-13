/**
* Default Document Strategy for DocBox
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
	* Run this strategy
	* @qMetaData The metadata
	*/
	component function run( required query qMetadata ){
		ensureDirectory( getOutputDir() );
		ensureDirectory( getOutputDir() & "/classes" );

		//write the index template
		var args = {
			path 		 = getOutputDir() & "/index.json", 
			template 	 = "#variables.static.TEMPLATE_PATH#/index.cfm", 
			projectTitle = getProjectTitle()
		};

		// consider chainable methods, since that's how HTMLAPIStrategy works.
		var classData = normalize( queryToArray( arguments.qMetadata ) );

		serializeToFile(
			getOutputDir() & "/index.json",
			generateClassIndex( classData )
		);

		classData.each( ( class ) => {
			serializeToFile(
				getOutputDir() & "/classes/#class.name#.json",
				class
			);
		});

		return this;
	}

	/**
	 * Marshall component metadata into a class index file.
	 * This will be spit into an `index.json` file at the root of the output directory.
	 *
	 * @classData 
	 */
	package struct function generateClassIndex( required array classData ){
		var classMap = arguments.classData.map( ( class ) => {
			return {
				"name" : class.name,
				"path" : "#getOutputDir()#/classes/#class.name#.json"
			}
		});
		return {
			"packages" : classMap
		}
	}

	package array function normalize( required array classData ){
		return arguments.classData.map( function( row ) {
			/**
			 * Marshall functions to match the designed schema;
			 */
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
			return {
				"name" : row.name,
				"package" : row.package,
				"type" : row.type,
				"extends" : row.extends,
				"fullextends" : row.fullextends,
				"hint" : row.metadata.hint,
				"functions" : metaFunctions
			};
		});
	}


	/**
	 * Convert a query object to an array of structs.
	 *
	 * @data source query object
	 */
	private array function queryToArray( required query data ){
		var converted = [];
		for( var i = 1; i <= arguments.data.recordCount; i++ ){
			converted.append( queryGetRow( arguments.data, i ) );
		}
		return converted;
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