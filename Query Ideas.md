// Something that matches any of these?

// -> function when( boolean condition, ifTrue, ifFalse )
// -> function raw( string text )

// -> matchAll

// -> constantScore

// BooleanQuery.cfc
// -> must
// -> filter
// -> should
// -> mustNot

// FullTextQuery.cfc
// -> match
// -> matchPhrase
// -> matchPhrasePrefix
// -> multiMatch
// -> common
// -> queryString
// -> simpleQueryString

// TermQuery.cfc
// -> term
// -> terms
// -> range
// -> exists
// -> prefix
// -> wildcard
// -> regexp
// -> fuzzy
// -> type
// -> ids

// RangeQuery.cfc
// -> gte
// -> gt
// -> lte
// -> lt

// can we be opinionated and only offer either equal or non-equal varities?
// query.range( "date", 10, 20 );
// { "range" = { "date" = { "gte" = 10, "lte" = 20 } } }

// query.range( "date", 10, 20, greaterThanEqual = false );
// { "range" = { "date" = { "gt" = 10, "lte" = 20 } } }

// query.range( "date" ).gte( 10 ).lte( 20 );

// JoinQuery.cfc


// GeoQuery.cfc
