/**
*
* Elasticsearch Abstract Mapping Object
*
* @package cbElasticsearch.models.mappings
* @author Eric Peterson <eric@ortussolutions.com>
* @license Apache v2.0 <http://www.apache.org/licenses/>
*
*/
component
	accessors="true"
{

    property name="name";
    property name="type" default="object";
    property name="parameters";

    function init() {
        variables.parameters = {};
        return this;
    }

    function onMissingMethod( missingMethodName, missingMethodArguments ) {
        variables.parameters[ snakeCase( missingMethodName ) ] = missingMethodArguments[ 1 ];
        return this;
    }

    private function snakeCase( str ) {
        return arrayToList( words( capitalize( str, true ) ).map( function( w ) {
            return lCase( w );
        } ), "_" );
    }

    private function capitalize( str, preserveCase = false ) {
        var strArray = listToArray( preserveCase ? str : lcase( str ), "" );
        strArray[ 1 ] = uCase( strArray[ 1 ] );
        return arrayToList( strArray, "" );
    }

    private function words( str ) {
        return listToArray(
            addSpaceBetweenCapitalLetters(
                REReplace( str , "[\_\-]", " ", "ALL" )
            ),
            " "
        );
    }

    private function addSpaceBetweenCapitalLetters( str ) {
        var pattern = createObject( "java", "java.util.regex.Pattern" );
        var matches = pattern.compile( "[A-Z]" ).matcher( str );
        var newString = "";
        var start = 0;
        while( matches.find() ) {
            if ( start == 0 ) {
                start = matches.start() + 1;
                continue;
            }
            newString &= mid( str, start, matches.start() - start + 1 ) & " ";
            start = matches.start() + 1;
        }

        if ( newString == "" ) {
            return str;
        }

        return newString & mid( str, start, len( str ) );
    }

}
