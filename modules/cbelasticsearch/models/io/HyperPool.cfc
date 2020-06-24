component{
    /**
     * Hyper injection
     */
    property name="hyper" inject="HyperBuilder@Hyper";

    property name="nodes"
                type="array";

    property name="authenticationScheme";

    property name="currentIndexes";

    property name="instanceConfig";

    function init(){
        variables.authenticationScheme = "none";
        variables.currentIndexes = {};
        variables.nodes = [];
        return this;
    }
    

    /**
     * Configures the hyper pool for usage
     */
    
    HyperPool function configure( required cbelasticsearch.models.Config config ){
        variables.instanceConfig = arguments.config;

        var configSettings = variables.instanceConfig.getConfigStruct();

        lock type="exclusive" name="HyperPoolConfigurationLock" timeout="10"{

            if( 
                structKeyExists( configSettings, "defaultCredentials" )
				&& len( configSettings.defaultCredentials.username )
            ){
                variables.authenticationScheme = "basic";
                var username = configSettings.defaultCredentials.username;
                var password = configSettings.defaultCredentials.password;
            } else if( structKeyExists( configSettings, "clientCertificatePath" ) && len( configSettings.clientCertificatePath ) ){
                variables.authenticationScheme = "certificate";
                var certificatePath = expandPath( configSettings.clientCertificatePath );
            }

            configSettings.hosts.each( function( host ){
                
                var node = {
                    "url" : host.serverProtocol & "://" & host.serverName & ":" & host.serverPort,
                    "usage" : host.keyExists( "usage" ) ? host.usage : "read-write"
                };

                switch( variables.authenticationScheme ){
                    case "basic":{
                        node.username = username;
                        node.password = password;
                        break;
                    }
                    case "certificate":{
                        node.certificatePath = certificatePath;
                        node.certificatePassword = structKeyExists( configSettings, "clientCertificatePassword" )
                                                    ? configSettings.clientCertificatePassword
                                                    : javacast( "null", 0 );
                        break;
                        
                    }
                }
                variables.nodes.append( node );
            } );
        }

        return this;
    }

    /**
     * Retreives a pre-configured hyper request for an available node
     *
     * @route the relative URI to the route 
     * @method the HTTP Request method
     */
    public Hyper.models.HyperRequest function newRequest(
        required string route,
        string method = "GET"
    ){

        var requestObj = hyper.new();

        var nodeUsage = "write";
        switch( arguments.method ){
            case "GET":{
                nodeUsage = "read";
                break;
            }
            case "POST":
                if( findNoCase( '_search', arguments.route ) || findNoCase( '_mget', arguments.route ) ){
                    nodeUsage = "read";
                }
                break;
        }

        var node = getAvailableNode( nodeUsage );

        requestObj.setMethod( arguments.method )
            .setThrowOnError( false )
            .setTimeout( variables.instanceConfig.get( "readTimeout" ) );

        var uriParts = listToArray( route, '/' );
        uriParts.prepend( node.url );
        requestObj.setUrl( uriParts.toList( '/' ) );

        if( variables.authenticationScheme == 'basic' && node.username && node.password ){
            if( node.username && node.password ){
                requestObj.withBasicAuth( node.username, node.password );   
            } else {
                throw(
                    type="cbElasticsearch.InvalidAuthenticationType",
                    message="The authentication type #variables.authenticationScheme# requires a username and password.  None was provided in the configuration.  Could not continue." 
                );
            }
        } else if( variables.authenticationScheme == 'certificate' ){
            requestObj.withCertificateAuth( 
                node.certificatePath, 
                node.keyExists( "certificatePassword" ) 
                ? node.certificatePassword
                : javacast( "null", 0 )
            );
        } else if( len( variables.authenticationScheme ) && variables.authenticationScheme != 'none' ){
            throw(
                type="cbElasticsearch.UnsupportedAuthenticationType",
                message="The authentication type #variables.authenticationScheme# is not currently supported" 
            );
        }
        return requestObj;
    }

    /**
     * Retreieves a relevant node to use using a simple round-robin increment of the index
     *
     * @nodeUsage  string - the type off usage/action which the node should accept ( read | write )
     */
    private function getAvailableNode( required string nodeUsage ){
        if( variables.nodes.len() == 1 ) return variables.nodes[ 1 ];

        var relevantNodes = variables.nodes.filter( function( node ){
            return findNoCase( nodeUsage, node.usage );
        } );

        if( !relevantNodes.len() ){
            writeDump( nodeUsage );
            writeDump( variables.nodes );
        }

        // simple round robin on node usage
        if( !structKeyExists( variables.currentIndexes, nodeUsage ) ){ variables.currentIndex[ nodeUsage ] = 0; }

        if( variables.currentIndex[ nodeUsage ] <= relevantNodes.len() ){
            variables.currentIndex[ nodeUsage ]++;
        } else {
            variables.currentIndex[ nodeUsage ] = 1;
        }

        return relevantNodes[ variables.currentIndex[ nodeUsage ] ];

    }





}