/**
* My BDD Test
*/
component extends="testbox.system.BaseSpec"{

	property name="testOutputDir" default="/tests/resources/tmp/json";

/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){
		variables.docbox = new docbox.DocBox(
			strategy = "docbox.strategy.json.JSONAPIStrategy",
			properties={ 
				projectTitle 	= "DocBox Tests",
				outputDir 		= variables.testOutputDir
			}
		);
	}

	// executes after all suites+specs in the run() method
	function afterAll(){
		structDelete( variables, "docbox" );
	}

/*********************************** BDD SUITES ***********************************/

	function run(){
		// all your suites go here.
		describe( "JSONAPIStrategy", function(){

			beforeEach( function() {
				// empty the directory so we know if it has been populated
				if ( directoryExists( variables.testOutputDir ) ){
					directoryDelete( variables.testOutputDir, true );
				}
				directoryCreate( variables.testOutputDir );
			});

			it( "can run without failure", function(){
				expect( function() {
					variables.docbox.generate(
						source = expandPath( "/tests" ),
						mapping = "tests",
						excludes="(coldbox|build\-docbox)"
					)
				}
				).notToThrow();
			});

			it( "produces JSON output in the correct directory", function() {
				variables.docbox.generate(
					source = expandPath( "/tests" ),
					mapping = "tests",
					excludes="(coldbox|build\-docbox)"
				);

				var results = directoryList( variables.testOutputDir, true, "name" );
				debug( results );
				expect( results.len() ).toBeGT( 0 );

				expect( arrayContainsNoCase( results, "index.json" ) )
					.toBeTrue( "should generate index.json class index file" );
				expect( arrayContainsNoCase( results, "classes" ) )
					.toBeTrue( "should generate classes/ directory for class documentation");
				expect( arrayContainsNoCase( results, "JSONAPIStrategyTest.json" ) )
					.toBeTrue( "should generate classes/JSONAPIStrategyTest.json to document JSONAPIStrategyTest.cfc")

			});

			it( "Produces the correct hierarchy of class documentation files", function() {
				variables.docbox.generate(
					source = expandPath( "/tests" ),
					mapping = "tests",
					excludes="(coldbox|build\-docbox)"
				);

				expect( directoryExists( variables.testOutputDir & "/classes/tests/specs/JSONAPIStrategyTest.json" ) )
					.toBeTrue( "should generate documentation in nested hierarchy according to source .cfc file" );

				expect( directoryExists( variables.testOutputDir & "/classes/tests/specs/HTMLAPIStrategyTest.json" ) )
					.toBeTrue( "should generate documentation in nested hierarchy according to source .cfc file" );

			});

			it( "produces package-summary.json file for each 'package' level", function() {
				variables.docbox.generate(
					source = expandPath( "/tests" ),
					mapping = "tests",
					excludes="(coldbox|build\-docbox)"
				);

				var results = directoryList( variables.testOutputDir, true, "name" );
				debug( results );
				expect( results.len() ).toBeGT( 0 );

				expect( directoryExists( variables.testOutputDir & "/classes/tests/specs/index.json" ) )
					.toBeTrue( "should generate package summary file" );

				var packageSummary = fileRead( variables.testOutputDir & "/classes/tests/specs/index.json" );

				expect( deSerializeJSON( packageSummary ) ).toBeTypeOf( "struct" );

			});

		});
	}

}

