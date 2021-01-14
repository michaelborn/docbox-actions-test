/**
 * My BDD Test
 */
component extends="testbox.system.BaseSpec" {

	property name="testOutputDirectory" default="/tests/resources/tmp/uml/";
	property name="testOutputFile"      default="XMITestFile.uml";

	/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){
		variables.testOutputFile = expandPath( variables.testOutputDirectory ) & variables.testOutputFile;

		variables.docbox = new docbox.DocBox(
			strategy   = "docbox.strategy.uml2tools.XMIStrategy",
			properties = {
				projectTitle : "DocBox Tests",
				outputFile   : variables.testOutputFile
			}
		);
	}

	// executes after all suites+specs in the run() method
	function afterAll(){
		if ( fileExists( variables.testOutputFile ) ) {
			fileDelete( variables.testOutputFile );
		}

		if ( directoryExists( expandPath( variables.testOutputDirectory ) ) ) {
			directoryDelete( expandPath( variables.testOutputDirectory ) );
		}

		structDelete( variables, "docbox" );
	}

	/*********************************** BDD SUITES ***********************************/

	function run(){
		// all your suites go here.
		describe( "XMLStrategy", function(){
			beforeEach( function(){
				// delete the test file so we know if it has been created during test runs
				if ( fileExists( variables.testOutputFile ) ) {
					fileDelete( variables.testOutputFile );
				}
			} );

			it( "can run without failure", function(){
				expect( function(){
					variables.docbox.generate(
						source   = expandPath( "/tests" ),
						mapping  = "tests",
						excludes = "(coldbox|build\-docbox)"
					)
				} ).notToThrow();
			} );

			it( "produces UML output in the correct file", function(){
				variables.docbox.generate(
					source   = expandPath( "/tests" ),
					mapping  = "tests",
					excludes = "(coldbox|build\-docbox)"
				);

				expect( fileExists( variables.testOutputFile ) ).toBeTrue( "Should generate the UML diagram file " );

				var umlContent = fileRead( variables.testOutputFile );
				expect( UMLContent ).toInclude(
					"name=""XMIStrategyTest"">",
					"should find and document the XMIStrategyTest.cfc class in tests/specs directory"
				);
			} );
		} );
	}

}
