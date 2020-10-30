/**
* My BDD Test
*/
component extends="testbox.system.BaseSpec"{

	property name="testOutputDir" default="/tests/resources/tmp";

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

	function run( testResults, testBox, foo = "yellow" ) testRole="Administrator"{
		// all your suites go here.
		describe( "JSONAPIStrategy", function(){

			it( "can run without failure", function(){
				variables.docbox.generate(
					source = expandPath( "/tests" ),
					mapping = "tests",
					excludes="(coldbox|build\-docbox)"
				);
			});

			it( "produces JSON output in the correct directory", function() {
				// empty the directory so we know if it has been populated
				directoryDelete( variables.testOutputDir, true );
				directoryCreate( variables.testOutputDir );


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

		});
	}

}

