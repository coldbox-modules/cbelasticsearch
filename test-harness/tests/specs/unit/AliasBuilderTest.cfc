component extends="coldbox.system.testing.BaseTestCase" {

	function beforeAll(){
		this.loadColdbox = true;

		super.beforeAll();

		variables.client        = getWireBox().getInstance( "Client@cbElasticSearch" );
		variables.testIndexName = lCase( "AliasBuilderTests" );
		variables.client.deleteIndex( variables.testIndexName );
	}

	function run(){
		describe( "aliases", function(){
			beforeEach( function(){
				variables.client.deleteIndex( variables.testIndexName );
				// create an index
				getWireBox()
					.getInstance( "IndexBuilder@cbElasticSearch" )
					.new( variables.testIndexName )
					.save();
			} );

			it( "can add an alias", function(){
				// create an alias
				var aliasName = lCase( "AliasBuilderTestsAlias" );

				var addAliasAction = getWireBox()
					.getInstance( "AliasBuilder@cbElasticSearch" )
					.add( indexName = variables.testIndexName, aliasName = aliasName );

				variables.client.applyAliases( aliases = addAliasAction );

				// verify the alias as an index
				expect( variables.client.indexExists( aliasName ) ).toBeTrue();
			} );

			it( "can remove an alias", function(){
				// create an alias
				var aliasName = lCase( "AliasBuilderTestsAlias" );

				var addAliasAction = getWireBox()
					.getInstance( "AliasBuilder@cbElasticSearch" )
					.add( indexName = variables.testIndexName, aliasName = aliasName );

				variables.client.applyAliases( aliases = addAliasAction );

				// now remove the alias
				var removeAliasAction = getWireBox()
					.getInstance( "AliasBuilder@cbElasticSearch" )
					.remove( indexName = variables.testIndexName, aliasName = aliasName );

				variables.client.applyAliases( aliases = removeAliasAction );

				// verify the alias as an index
				expect( variables.client.indexExists( aliasName ) ).toBeFalse();
			} );

			it( "can add and remove an alias at the same time", function(){
				// create an alias
				var aliasNameOne = lCase( "AliasBuilderTestsAliasOne" );

				var addAliasAction = getWireBox()
					.getInstance( "AliasBuilder@cbElasticSearch" )
					.add( indexName = variables.testIndexName, aliasName = aliasNameOne );

				variables.client.applyAliases( aliases = addAliasAction );

				// now remove the first alias and add the second alias
				var aliasNameTwo = lCase( "AliasBuilderTestsAliasTwo" );

				var removeAliasAction = getWireBox()
					.getInstance( "AliasBuilder@cbElasticSearch" )
					.remove( indexName = variables.testIndexName, aliasName = aliasNameOne );
				var addNewAliasAction = getWireBox()
					.getInstance( "AliasBuilder@cbElasticSearch" )
					.add( indexName = variables.testIndexName, aliasName = aliasNameTwo );

				variables.client.applyAliases( aliases = [ removeAliasAction, addNewAliasAction ] );

				// verify the alias as an index
				expect( variables.client.indexExists( aliasNameOne ) ).toBeFalse();
				expect( variables.client.indexExists( aliasNameTwo ) ).toBeTrue();
			} );

			it( "tests the save() ability to create an alias", function(){
				// create an alias
				var aliasName = lCase( "AliasBuilderTestsAlias" );

				var addAliasAction = getWireBox()
					.getInstance( "AliasBuilder@cbElasticSearch" )
					.new(
						action    = "add",
						indexName = variables.testIndexName,
						aliasName = aliasName
					)
					.save();
				// verify the alias as an index
				expect( variables.client.indexExists( aliasName ) ).toBeTrue();
			} );

			it( "tests the save() ability to remove an alias", function(){
				// create an alias
				var aliasName = lCase( "AliasBuilderTestsAlias" );

				var addAliasAction = getWireBox()
					.getInstance( "AliasBuilder@cbElasticSearch" )
					.new(
						action    = "add",
						indexName = variables.testIndexName,
						aliasName = aliasName
					)
					.save();

				// now remove the alias
				var removeAliasAction = getWireBox()
					.getInstance( "AliasBuilder@cbElasticSearch" )
					.new(
						action    = "remove",
						indexName = variables.testIndexName,
						aliasName = aliasName
					)
					.save();

				// verify the alias as an index
				expect( variables.client.indexExists( aliasName ) ).toBeFalse();
			} );
		} );
	}

}
