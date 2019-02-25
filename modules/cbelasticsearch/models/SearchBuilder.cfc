/**
*
* Elasticsearch Search Builder Object
*
* @package cbElasticsearch.models
* @author Jon Clausen <jclausen@ortussolutions.com>
* @license Apache v2.0 <http://www.apache.org/licenses/>
*
*/
component accessors="true" {

    property name="configObject" inject="Config@cbElasticsearch";

    /**
    * Property containing the index name of the active builder search
    **/
    property name="index";
    /**
    * Property containing the object type within the index
    **/
    property name="type";
    /**
    * Property containing a document `_id`
    **/
    property name="id";
    /**
    * Property containing the struct representation of the query being built
    **/
    property name="query";
    /**
    * Property containing the struct representation of any query aggregations
    **/
    property name="aggregations";
    /**
    * Property containing the struct representation of any _source properties
    **/
    property name="source";

    /**
    * Property containing an array of sort commands
    **/
    property name="sorting";

    /**
    * Property containing an elasticsearch scripting dsl string
    **/
    property name="script";

    /**
    * When performing matching searches, the type of match to specify
    **/
    property name="matchType";

    /**
    * Whether to preflight the query prior to execution( recommended ) - ensures consistent formatting to prevent errors
    **/
    property name="preflight"
                type="boolean";

    // Optional search defaults
    property name="maxRows";
    property name="startRow";


    function onDIComplete(){
        reset();

    }

    function reset(){

        variables.index        	= variables.configObject.get( "defaultIndex" );

        var nullDefaults = [ "id","sorting","aggregations","script","sortRows" ];

        //ensure defaults, in case we are re-using a search builder with new()
        variables.matchType    	= "any";
        variables.query 		= {};
        variables.source        = {
            "includes" = [],
            "excludes" = []
        };

        variables.maxRows 		= 25;
        variables.startRow		= 0;

        variables.preflight     = true;

        for( var nullable in nullDefaults ){
            if( !structKeyExists( variables, nullable ) || !isNull( variables[ nullable ] ) ){
                variables[ nullable ] = javacast( "null", 0 );
            }
        }
    }

    /**
    * Client provider
    **/
    Client function getClient() provider="Client@cbElasticsearch"{}

    /**
    * Persists the document to Elasticsearch
    **/
    function execute(){
        if( preflight ){
            preflightQuery();
        }

        return getClient().executeSearch( this );
    }

    /**
    * Deletes all documents matching the currently build search query
    **/
    function deleteAll(){
        return getClient().deleteByQuery( this );
    }


    /**
    * Populates a new SearchBuilder object
    * @index 		string 		the name of the index to search
    * @type 		string 		the index type identifier
    * @properties 	struct		a struct representation of the search
    **/
    SearchBuilder function new(
        string index,
        string type,
        struct properties
    ){
        reset();

        if( !isNull( arguments.index ) ){
            variables.index = arguments.index;
        }

        if( !isNull( arguments.type ) ){
            variables.type = arguments.type;
        }

        if( !isNull( arguments.properties ) ){

            for( var propName in arguments.properties ){

                switch( propName ){
                    case "offset":
                    case "startRow":{
                        variables.startRow = arguments.properties[ propName ];
                    }
                    case "maxRows":{
                        variables.maxRows = arguments.properties[ propName ];
                    }
                    case "query":{
                        variables.query = arguments.properties[ propName ];
                        break;
                    }
                    case "match":{

                        if( !structKeyExists( variables.query, "match" ) ){
                            variables.query[ "match" ] = {};
                        }

                        structAppend( variables.query.match, arguments.properties[ propName ] );

                        break;

                    }
                    case "aggregations":{

                        if( !isStruct( arguments.properties[ propName ] ) ){
                            throw(
                                type    = "cbElasticsearch.SearchBuilder.AggregationException",
                                message = "The value #serializeJSON( arguments.properties[ propName ] )# could not be converted to a valid aggregation"
                            );
                        }

                        for( var aggregationKey in arguments.properties[ propName ] ){
                            aggregation( aggregationKey, arguments.properties[ propName ][ aggregationKey ] );
                        }

                        break;

                    }
                    case "sort":{

                        sort( arguments.properties[ propName ] );

                        break;

                    }
                    default:{

                        //Assume it's a match value if providing a simple value.  Otherwise, assume it is raw DSL
                        if( isSimpleValue( arguments.properties[ propName ] ) ){

                            match(
                                propName,
                                arguments.properties[ propName ]
                            );

                        } else {

                            variables.query[ propName ] = arguments.properties[ propName ];

                        }

                    }

                }
            }

        }

        return this;
    }

    /**
    * Adds an exact value restriction ( elasticsearch: term ) to the query
    * @name 		string 		the name of the parameter to match
    * @value 		any 		the value of the parameter to match
    * @boost 		numeric		A numeric boost option for any exact matches
    *
    **/
    SearchBuilder function term(
        required string name,
        required any value,
        numeric boost
    ){
        if( !structKeyExists( variables.query, "term" ) ){

            variables.query[ "term" ] = {};

        }

        if( !isNull( arguments.boost ) ){

            variables.query[ "term" ][ arguments.name ] = {
                "value" : arguments.value,
                "boost" : javacast( "float", arguments.boost )
            };

        } else {

            variables.query[ "term" ][ arguments.name ] = arguments.value;

        }

        return this;

    }

    function filterTerms(
        required string name,
        required any value
    ){
        if( isSimpleValue( value ) ) arguments.value = listToArray( value );

        if( isArray( value ) && arrayLen( value ) == 1 ){
            return term( name=arguments.name, value=value[ 1 ] );
        }

        param variables.query.bool = {};
        param variables.query.bool.filter = {};
        param variables.query.bool.filter.bool = {};
        param variables.query.bool.filter.bool.must = [];
        arrayAppend( variables.query.bool.filter.bool.must, {
            "terms": {
                "#name#": value
            }
        });
    }

    /**
    * `must` query alias for match()
    *
    * @name 		string 		the name of the key to search
    * @value 		string 		the value of the key
    **/
    SearchBuilder function shouldMatch(
        required string name,
        required any value,
        numeric boost
    ){

        arguments[ "matchType" ] = "should";
        return match( argumentCollection=arguments );

    }

    /**
    * `must` query alias for match()
    *
    * @name 		string 		the name of the key to search
    * @value 		string 		the value of the key
    **/
    SearchBuilder function mustMatch(
        required string name,
        required any value,
        numeric boost
    ){

        arguments[ "matchType" ] = "must";
        return match( argumentCollection=arguments );

    }

    /**
    * `must_not` query alias for match()
    *
    * @name 		string 		the name of the key to search
    * @value 		string 		the value of the key
    **/
    SearchBuilder function mustNotMatch(
        required string name,
        required any value,
        numeric boost
    ){

        arguments[ "matchType" ] = "must_not";
        return match( argumentCollection=arguments );

    }

    /**
    * 'multi_match' query alias for match()
    *
    * @names 		array 		an array of keys to search
    * @value 		string 		the value of the key
    * @boost 		numeric	  	an optional boost value
    **/
    SearchBuilder function multiMatch(
        required array names,
        required any value,
        numeric boost,
        string type = "best_fields"
    ){
        arguments.name = arguments.names;
        arguments.matchType = "multi_match";
        return match( argumentCollection = arguments );
    }

    /**
    * `range` match for dates
    * @name 		string 		the key to match
    * @start 		string 		the preformatted date string to start the range
    * @end 			string 		the preformatted date string to end the range
    * @boost 		numeric	    the boost value of the match
    **/
    SearchBuilder function dateMatch(
        required string name,
        string start,
        string end,
        numeric boost
    ){
        if( isNull( arguments.start ) && isNull( arguments.end ) ){
            throw(
                type    = "",
                message = ""
            );
        }

        var properties = {
             "gte" : !isNull( arguments.start ) ? arguments.start : javacast( "null", 0 ),
             "lte" : !isNull( arguments.end ) ? arguments.end : javacast( "null", 0 ),
             "boost" : !isNull( arguments.boost ) ? arguments.boost : javacast( "null", 0 )
        };

        return match(
            name      = arguments.name,
            value     = properties,
            matchType = 'range'
        );

    }


    /**
    * Applies a match requirement to the search builder query
    * https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-match-query.html
    *
    * @name 		string|array 		the name of the key to search
    * @value 		string 				the value of the key
    * @boost 		numeric				A numeric boost option for any exact matches
    * @options 		struct 				An additional struct map of Elasticsearch query options to
    *									pass in to the match parameters ( e.g. - operator, zero_terms_query, etc )
    * @matchType 	string 				a match type ( default="any" )
    * 									Valid options:
    * 							 		- "any"
    * 							 		- "all"
    * 							 		- "phrase" - requires an exact match of a given phrase
    * 							 		- "must" | "must_not" - specifies that any document returned must or must not match
    * 							 		- "should" - specifies that any documents returned should match the value(s) provided
    *
    **/
    SearchBuilder function match(
        required any name,
        required any value,
        numeric boost,
        struct options,
        string matchType="any",
        string type = "best_fields",
        string minimumShouldMatch
    ){

        //Auto-magically make a multi-match query if our name argument is an array
        if( isArray( arguments.name ) ){
            arguments.matchType = 'multi_match';
        }

        switch( arguments.matchType ){

            case "phrase":{
                matchKey = "match_phrase";
                break;
            }
            case "all":{
                variables.query[ "match_all" ] = {};
                matchKey = "match";
                break;
            }
            default:{
                matchKey = "match";
            }
        }

        var match = {};

        if( !isNull( arguments.boost ) && isSimpleValue( arguments.name ) ){

            match[ arguments.name ] = {
                "query" : arguments.value,
                "boost" : javacast( "float", arguments.boost )
            };

        } else if( isSimpleValue( arguments.name ) ) {

            match[ arguments.name ] = arguments.value;

        }

        if( !isNull( arguments.options ) && isSimpleValue( arguments.name ) ){

            //convert our query to the long form DSL so we can append options
            if( !isStruct( match[ arguments.name ] ) ){

                match[ arguments.name ] = {
                    "query" : arguments.value
                };

            }



            for( var optionKey in arguments.options ){

                match[ arguments.name ][ optionKey ]=arguments.options[ optionKey ];

            }
        }

        var booleanMatchTypes = [ 'must', 'must_not', 'multi_match', 'should', 'terms', 'range' ];

        if( arrayFind( booleanMatchTypes, arguments.matchType ) ){

            if( !structKeyExists( variables.query, "bool" ) ){
                variables.query[ "bool" ] = {};
            }

            switch( arguments.matchType ){
                case "should":{
                    // array-based boolean matches
                    if( !structKeyExists( variables.query.bool, arguments.matchType ) ){
                        variables.query.bool[ arguments.matchType ] = [];
                    }
                    arrayAppend(
                        variables.query.bool[ arguments.matchType ],
                        {
                            "#matchKey#" : match
                        }
                    );
                    break;
                }

                case "multi_match":{

                    if( !structKeyExists( variables.query.bool, "must" ) ){
                        variables.query.bool[ "must" ] = [];
                    }

                    var matchCriteria = {
                        "query" : arguments.value,
                        "fields" : isArray( arguments.name ) ? arguments.name : listToArray( arguments.name ),
                        "type": arguments.type
                    };

                    if ( ! isNull( arguments.minimumShouldMatch ) ) {
                        matchCriteria[ "minimum_should_match" ] = arguments.minimumShouldMatch;
                    }

                    if( !isNull( arguments.boost ) ) matchCriteria[ "boost" ] = arguments.boost;

                    arrayAppend(
                        variables.query.bool.must,
                        {
                            "#arguments.matchType#" : matchCriteria
                        }
                    );

                    break;

                }

                case "range":{

                    if( !structKeyExists( variables.query.bool, "must" ) ){
                        variables.query.bool[ "must" ] = [];
                    }

                    arrayAppend(
                        variables.query.bool.must,
                        {
                            "#arguments.matchType#" : {
                                "#arguments.name#" : arguments.value
                            }
                        }
                    );

                    break;

                }

                case "must":
                case "must_not":{

                    if( !structKeyExists( variables.query.bool, arguments.matchType ) ){
                        variables.query.bool[ arguments.matchType ] = [];
                    }

                    arrayAppend(
                        variables.query.bool[ arguments.matchType ], {
                            "match" : {
                                "#arguments.name#" : arguments.value
                            }
                        }

                    );

                    break;
                }

                case "terms":{

                    if( !structKeyExists( variables.query.bool, "must" ) ){
                        variables.query.bool[ "must" ] = [];
                    }

                    arrayAppend(
                        variables.query.bool.must, {
                            "terms" : {
                                "#arguments.name#" : arguments.value
                            }
                        }

                    );

                    break;
                }

                default:{

                    if( !structKeyExists( variables.query.bool, arguments.matchType ) ){
                        variables.query.bool[ arguments.matchType ] = {};
                    }

                    structAppend( variables.query.bool[ arguments.matchType ], match, true );
                }
            }

        } else {

            if( !structKeyExists( variables.query, matchKey ) ){

                variables.query[ matchKey ] = {};

            }

            structAppend( variables.query[ matchKey ], match, true );
        }

        return this;


    }

    /**
    * Performs a disjunctive search ( https://www.elastic.co/guide/en/elasticsearch/guide/current/_tuning_best_fields_queries.html )
    *
    * @matches 		struct 		A struct containing the matches
    * @tieBreakder 	numeric     A tie breaker value to boost more relevant matches
    *
    **/
    SearchBuilder function disjunction( required struct matches, numeric tieBreaker ){

        if( !structKeyExists( variables.query, "dis_max" ) ){
            variables.query[ "dis_max" ] = {
                "queries" : []
            };
        }

        for( var key in matches ){
            arrayAppend(
                variables.query[ "dis_max" ].queries,
                {
                    "match" :{
                        "#key#" : matches[ key ]
                    }
                }
             );
        }

        return this;


    }


    /**
    * Adds an aggregation directive to the search parameters
    *
    * https://www.elastic.co/guide/en/elasticsearch/reference/current/search-aggregations.html
    *
    * @name 	string 		the key of the aggregation
    * @options 	struct      the elasticsearch aggregation DSL struct
    **/
    SearchBuilder function aggregation( required string name, required struct options ){

        if( isNull( variables.aggregations ) ){
            variables.aggregations = {};
        }

        variables.aggregations[ name ] = arguments.options;

        return this;
    }

    /**
    * Applies a custom sort to the search query
    * @sort 		any 	If passed as a string, the sortConfig argument is required,
    * 						may also accept a full struct representation, which will be appended to the custom sort
    * @sortConfig 	string 	A configuration - either a string or a full es-compatible sort configuration struct
    **/
    SearchBuilder function sort( required any sort, any sortConfig ){

        if( isNull( variables.sorting ) ){
            variables.sorting = [];
        }

        // represents the actual sort array passed to the client
        if( isArray( arguments.sort ) ){

            arrayAppend( variables.sorting, arguments.sort, true );

        // a friendly `[fieldName] [ORDER]` like we would use with SQL ( e.g. `name ASC` )
        } else if( isSimpleValue( arguments.sort ) && isNull( arguments.sortConfig ) ) {

            var sortDirectives = listToArray( arguments.sort, "," );

            for( var sortDirective in sortDirectives ){
                var directiveItems = listToArray( sortDirective, " " );

                arrayAppend(
                    variables.sorting,
                    {
                        "#directiveItems[ 1 ]#" : { "order" : arrayLen( directiveItems ) > 1 ? lcase( directiveItems[ 2 ] ) : "asc" }
                    }
                );

            }

        // name value argument pair
        } else if( isSimpleValue( arguments.sort ) && !isNull( arguments.sortConfig ) ) {

            // Our sort config argument can be a complex struct or a simple value
            arrayAppend( variables.sorting, {
                arguments.sort : isStruct( arguments.sortConfig ) ? arguments.sortConfig : { "order" : arguments.sortConfig }
            } );

        // Structural representation, which will be treated as individual items in the sort array
        } else if( isStruct( arguments.sort ) ){

            for( var sortKey in arguments.sort ){

                arrayAppend(
                    variables.sorting,
                    {
                        "#sortKey#" : { "order"	: arguments.sort[ sortKey ] }
                    }
                );

            }

        // Throw hard if we have no idea how to handle the provided search configuration
        } else {

            throw(
                type    = "cbElasticsearch.SearchBuilder.InvalidSortArgumentException",
                message = "The provided sort argument #serializeJSON( arguments.sort )# could not be parsed to a valid SearchBuilder sort configuration"
            );

        }


        return this;


    }

    /**
    * Performs a preflight on the search
    * ensures that a dynamically assembled query is well formatted before being passed on to elasticsearch
    **/
    void function preflightQuery(){

        var searchQuery = getQuery();

        //move terms in to the boolean node as they won't play well together otherwise
        if( structKeyExists( searchQuery, "term" ) && ( structKeyExists( searchQuery, "bool" ) || arrayLen( structKeyArray( searchQuery.term ) ) > 1 ) ){

            if( !structKeyExists( searchQuery, "bool" ) ){
                searchQuery[ "bool" ] = {};
            }

            if( !structKeyExists( searchQuery.bool, "must" ) ){
                searchQuery.bool[ "must" ] = [];
            }

            for( var key in searchQuery.term ){
                arrayAppend(
                    searchQuery.bool.must,
                    {
                        "term" : { "#key#" : searchQuery.term[ key ] }
                    }
                );
            }

            structDelete( searchQuery, "term" );

        }

        // move match directives in to boolean node if exists
        if( structKeyExists( searchQuery, "match" ) && structKeyExists( searchQuery, "bool" ) && structKeyExists( searchQuery.bool, "must" ) ){

            if( !structKeyExists( searchQuery.bool, "should" ) ){
                searchQuery.bool[ "should" ] = [];
            }

            for( var key in searchQuery.match ){
                arrayAppend(
                    searchQuery.bool.should,
                    {
                        "match" : {
                          "#key#": searchQuery.match[ key ]
                        }
                    }
                );
            }

            structDelete( searchQuery, "match" );
        }

        //if we have multiple term filters, move them in to the "must" array
        if( structKeyExists( searchQuery, "bool" ) && structKeyExists( searchQuery.bool, "filter" ) && structKeyExists( searchQuery.bool.filter, "terms" ) ){
            if( arrayLen( structKeyArray( searchQuery.bool.filter.terms ) ) > 1 ){

               if( !structKeyExists( searchQuery, "bool" ) ){
                    searchQuery[ "bool" ] = {};
                }

                if( !structKeyExists( searchQuery.bool, "must" ) ){
                    searchQuery.bool[ "must" ] = [];
                }

                for( var termKey in searchQuery.bool.filter.terms ){

                    arrayAppend(
                        searchQuery.bool.must,
                        {
                            "terms" : {
                                "#termKey#" : searchQuery.bool.filter.terms[ termKey ]
                            }
                        }

                    );

                }

                structDelete( searchQuery.bool.filter, "terms" );
                if( structIsEmpty( searchQuery.bool.filter ) ) structDelete( searchQuery.bool, "filter" );
                if( structIsEmpty( searchQuery.bool ) ) structDelete( searchQuery, "bool" );

            }
        }

    }

    struct function getDSL(){

        var dsl = {
            "from"    : variables.startRow,
            "size"    : variables.maxRows,
            "query"   : variables.query,
            "_source" : variables.source
        };

        if( !isNull( variables.aggregations ) ){
            dsl[ "aggs" ] = variables.aggregations;
        }

        if( !isNull( variables.script ) ){
            dsl[ "script" ] = variables.script;
        }

        if( !isNull( variables.sorting ) ){

            //we used a linked hashmap for sorting to maintain order
            dsl[ "sort" ] = createObject( "java", "java.util.LinkedHashMap" ).init();

            for( var sort in variables.sorting ){
                dsl.sort.putAll( sort );
            }
        }

        if( variables.matchType != 'any' ){
            switch( variables.matchType ){
                case "all":{
                    dsl["query"][ "match_all" ] = {};
                    if( !isNull( varibles.matchBoost ) ){
                        dsl["query"][ "match_all" ][ "boost" ] = variables.matchBoost;
                    }
                    break;
                }
                case "none":{
                    dsl["query"][ "match_none" ] = {};
                    if( !isNull( varibles.matchBoost ) ){
                        dsl["query"][ "match_none" ][ "boost" ] = variables.matchBoost;
                    }
                    break;
                }
            }
        }

        return dsl;
    }

    string function getJSON(){

        return serializeJSON( getDSL() );
    }

    function setSource( struct source = {} ) {
        param arguments.source.includes = [];
        param arguments.source.excludes = [];
        variables.source = arguments.source;
        return this;
    }

    function setSourceIncludes( array includes = [] ) {
        variables.source.includes = arguments.includes;
        return this;
    }

    function setSourceExcludes( array excludes = [] ) {
        variables.source.excludes = arguments.excludes;
        return this;
    }

}
