<cfscript>
/**
 * Manual validation script for BooleanQueryBuilder
 * This tests the new fluent API functionality
 */

try {
	// Get the SearchBuilder instance (this should work if the module is properly configured)
	searchBuilder = new cbelasticsearch.models.SearchBuilder();
	
	writeOutput("<h1>BooleanQueryBuilder Manual Validation</h1>");
	
	// Test 1: Basic fluent must() method
	writeOutput("<h2>Test 1: Basic must().term() fluent API</h2>");
	testBuilder1 = new cbelasticsearch.models.SearchBuilder();
	testBuilder1.new( "test_index", "test_type" );
	
	// This should work: must().term()
	testBuilder1.must().term( "status", "active" );
	query1 = testBuilder1.getQuery();
	
	writeOutput("<h3>Query Structure:</h3>");
	writeOutput("<pre>" & serializeJSON( query1, false, true ) & "</pre>");
	
	// Verify structure
	hasCorrectStructure1 = structKeyExists( query1, "bool" ) 
		&& structKeyExists( query1.bool, "must" ) 
		&& isArray( query1.bool.must )
		&& arrayLen( query1.bool.must ) == 1
		&& structKeyExists( query1.bool.must[1], "term" )
		&& structKeyExists( query1.bool.must[1].term, "status" )
		&& query1.bool.must[1].term.status == "active";
		
	writeOutput("<h3>Validation: " & (hasCorrectStructure1 ? "PASS" : "FAIL") & "</h3>");
	
	// Test 2: Nested fluent API - bool().filter().bool().must()
	writeOutput("<h2>Test 2: Nested bool().filter().bool().must().wildcard() API</h2>");
	testBuilder2 = new cbelasticsearch.models.SearchBuilder();
	testBuilder2.new( "test_index", "test_type" );
	
	// This tests the original issue case
	testBuilder2.bool().filter().bool().must().wildcard( "title", "*test*" );
	query2 = testBuilder2.getQuery();
	
	writeOutput("<h3>Query Structure:</h3>");
	writeOutput("<pre>" & serializeJSON( query2, false, true ) & "</pre>");
	
	// Verify nested structure
	hasCorrectStructure2 = structKeyExists( query2, "bool" ) 
		&& structKeyExists( query2.bool, "filter" )
		&& structKeyExists( query2.bool.filter, "bool" )
		&& structKeyExists( query2.bool.filter.bool, "must" )
		&& isArray( query2.bool.filter.bool.must )
		&& arrayLen( query2.bool.filter.bool.must ) == 1
		&& structKeyExists( query2.bool.filter.bool.must[1], "wildcard" )
		&& structKeyExists( query2.bool.filter.bool.must[1].wildcard, "title" );
		
	writeOutput("<h3>Validation: " & (hasCorrectStructure2 ? "PASS" : "FAIL") & "</h3>");
	
	// Test 3: Multiple chained operations
	writeOutput("<h2>Test 3: Multiple chained operations</h2>");
	testBuilder3 = new cbelasticsearch.models.SearchBuilder();
	testBuilder3.new( "test_index", "test_type" );
	
	// Chain multiple operations
	testBuilder3
		.must().term( "status", "active" )
		.should().match( "title", "elasticsearch" )
		.filter().range( "price", gte = 10, lte = 100 );
	
	query3 = testBuilder3.getQuery();
	
	writeOutput("<h3>Query Structure:</h3>");
	writeOutput("<pre>" & serializeJSON( query3, false, true ) & "</pre>");
	
	// Verify multiple structures
	hasCorrectStructure3 = structKeyExists( query3, "bool" ) 
		&& structKeyExists( query3.bool, "must" )
		&& structKeyExists( query3.bool, "should" )
		&& structKeyExists( query3.bool, "filter" )
		&& isArray( query3.bool.must )
		&& isArray( query3.bool.should )
		&& structKeyExists( query3.bool.filter, "range" );
		
	writeOutput("<h3>Validation: " & (hasCorrectStructure3 ? "PASS" : "FAIL") & "</h3>");
	
	// Test 4: Comparison with original manual approach
	writeOutput("<h2>Test 4: Comparison with Manual Approach</h2>");
	
	// Manual approach (what we're replacing)
	manualBuilder = new cbelasticsearch.models.SearchBuilder();
	manualBuilder.new( "test_index", "test_type" );
	var q = manualBuilder.getQuery();
	param q.bool = {};
	param q.bool.filter = {};
	param q.bool.filter.bool.must = [];
	arrayAppend( q.bool.filter.bool.must, {
		"wildcard" : {
			"title" : {
				"value" : "*test*"
			}
		}
	} );
	
	writeOutput("<h3>Manual Query Structure:</h3>");
	writeOutput("<pre>" & serializeJSON( manualBuilder.getQuery(), false, true ) & "</pre>");
	
	writeOutput("<h3>Fluent Query Structure (from Test 2):</h3>");
	writeOutput("<pre>" & serializeJSON( query2, false, true ) & "</pre>");
	
	// Compare structures
	manualJSON = serializeJSON( manualBuilder.getQuery(), false, false );
	fluentJSON = serializeJSON( query2, false, false );
	structuresMatch = manualJSON == fluentJSON;
	
	writeOutput("<h3>Structures Match: " & (structuresMatch ? "PASS" : "FAIL") & "</h3>");
	
	if (!structuresMatch) {
		writeOutput("<h4>Manual JSON:</h4><pre>" & manualJSON & "</pre>");
		writeOutput("<h4>Fluent JSON:</h4><pre>" & fluentJSON & "</pre>");
	}
	
	// Test 5: Backward compatibility
	writeOutput("<h2>Test 5: Backward Compatibility</h2>");
	testBuilder4 = new cbelasticsearch.models.SearchBuilder();
	testBuilder4.new( "test_index", "test_type" );
	
	// Mix old and new APIs
	testBuilder4.mustMatch( "title", "elasticsearch" );  // Old API
	testBuilder4.must().term( "status", "active" );      // New API
	
	query4 = testBuilder4.getQuery();
	writeOutput("<h3>Mixed API Query Structure:</h3>");
	writeOutput("<pre>" & serializeJSON( query4, false, true ) & "</pre>");
	
	// Should have 2 items in must array
	backwardCompatible = structKeyExists( query4, "bool" ) 
		&& structKeyExists( query4.bool, "must" )
		&& isArray( query4.bool.must )
		&& arrayLen( query4.bool.must ) == 2;
		
	writeOutput("<h3>Backward Compatibility: " & (backwardCompatible ? "PASS" : "FAIL") & "</h3>");
	
	// Summary
	writeOutput("<h1>Summary</h1>");
	allTestsPass = hasCorrectStructure1 && hasCorrectStructure2 && hasCorrectStructure3 && structuresMatch && backwardCompatible;
	writeOutput("<h2>Overall Result: " & (allTestsPass ? "ALL TESTS PASS" : "SOME TESTS FAILED") & "</h2>");
	
	if (allTestsPass) {
		writeOutput("<p style='color: green; font-weight: bold;'>✓ BooleanQueryBuilder implementation is working correctly!</p>");
		writeOutput("<p>The fluent API successfully replaces manual query structure manipulation.</p>");
	}
	
} catch (any e) {
	writeOutput("<h1>Error in Manual Validation</h1>");
	writeOutput("<h2>Error Details:</h2>");
	writeOutput("<pre>" & serializeJSON( e, false, true ) & "</pre>");
	
	writeOutput("<h2>Troubleshooting:</h2>");
	writeOutput("<ul>");
	writeOutput("<li>Check if BooleanQueryBuilder.cfc exists in models/ directory</li>");
	writeOutput("<li>Verify SearchBuilder.cfc has the new fluent methods</li>");
	writeOutput("<li>Ensure module mapping is correct</li>");
	writeOutput("</ul>");
}
</cfscript>