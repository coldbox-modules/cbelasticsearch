# GitHub Copilot Instructions for cbElasticsearch

This document provides instructions for AI coding assistants working on the cbElasticsearch module - an Elasticsearch integration for the ColdBox Framework.

## Project Overview

cbElasticsearch is a ColdBox module that provides:
- Fluent API for Elasticsearch operations
- SearchBuilder for complex queries
- Document management with full CRUD operations
- CacheBox cache provider
- LogBox appender for centralized logging
- Index management and mapping builders
- Data stream and ILM (Index Lifecycle Management) support

## Architecture and Key Components

### Core Components
- **SearchBuilder** (`models/SearchBuilder.cfc`) - Fluent API for building Elasticsearch queries
- **Document** (`models/Document.cfc`) - Represents Elasticsearch documents with metadata
- **IndexBuilder** (`models/IndexBuilder.cfc`) - Manages index creation and configuration
- **Config** (`models/Config.cfc`) - Module configuration management
- **Client** (`models/io/HyperClient.cfc`) - HTTP client for Elasticsearch communication

### Directory Structure
- `models/` - Core business logic and domain objects
- `models/io/` - Input/output clients and communication layers
- `models/cache/` - CacheBox provider implementation
- `models/logging/` - LogBox appender for Elasticsearch logging
- `models/mappings/` - Elasticsearch mapping builders
- `models/util/` - Utility functions and helpers
- `test-harness/` - Test application and integration tests
- `docs/` - Documentation files

## Language and Framework

### ColdFusion/CFML
This project uses **ColdFusion Markup Language (CFML)** with the following conventions:

#### File Extensions
- `.cfc` - ColdFusion Components (classes)
- `.cfm` - ColdFusion pages/templates

#### Component Structure
```cfml
component accessors="true" {
    // Property declarations with dependency injection
    property name="config" inject="Config@cbelasticsearch";
    
    // Public methods
    public function methodName() {
        // Implementation
    }
    
    // Private methods
    private function helperMethod() {
        // Implementation
    }
}
```

### ColdBox Framework Integration
- Uses **WireBox** for dependency injection
- Follows **ColdBox module** conventions
- Configuration in `ModuleConfig.cfc`
- Uses **TestBox** for unit testing

## Code Style and Conventions

### Formatting (follows .cfformat.json)
- **4-space indentation** (tab_indent: true)
- **Double quotes** for strings
- **Spaces around operators** and inside parentheses/brackets
- **115 character line limit**
- **Consecutive alignment** for assignments, properties, and parameters

### Naming Conventions
- **camelCase** for variables, methods, and user-defined functions
- **PascalCase** for components and built-in functions
- **Property names** should be descriptive and follow camelCase
- **Method names** should be verbs describing the action

### Documentation Standards
```cfml
/**
 * Component description
 *
 * @package cbElasticsearch.models
 * @author Jon Clausen <jclausen@ortussolutions.com>
 * @license Apache v2.0 <http://www.apache.org/licenses/>
 */
component accessors="true" {
    /**
     * Property description
     **/
    property name="propertyName";
    
    /**
     * Method description
     * @param1 Description of parameter
     * @returns Description of return value
     */
    public function methodName( required string param1 ) {
        // Implementation
    }
}
```

## Development Environment

### Prerequisites
- ColdBox Framework >= v6
- Elasticsearch >= v6.0
- Lucee >= v5 or Adobe ColdFusion >= v2018
- CommandBox for package management and testing

### Setup Commands
```bash
# Clone and install dependencies
git clone git@github.com:coldbox-modules/cbox-elasticsearch.git
box install

# Start Elasticsearch (Docker)
docker-compose up --build

# Start development server
box start

# Run tests
box testbox run
```

### Environment Variables
```ini
ELASTICSEARCH_PROTOCOL=http
ELASTICSEARCH_HOST=127.0.0.1
ELASTICSEARCH_PORT=9200
ELASTICSEARCH_USERNAME=
ELASTICSEARCH_PASSWORD=
ELASTICSEARCH_INDEX=cbElasticsearch
ELASTICSEARCH_SHARDS=5
ELASTICSEARCH_REPLICAS=0
```

## Testing

### Framework: TestBox
- Test files in `test-harness/tests/specs/`
- Unit tests extend `coldbox.system.testing.BaseTestCase`
- Integration tests use actual Elasticsearch instance

### Test Structure
```cfml
component extends="coldbox.system.testing.BaseTestCase" {
    function beforeAll() {
        this.loadColdbox = true;
        super.beforeAll();
        variables.model = getWirebox().getInstance("ComponentName@cbElasticsearch");
    }
    
    function run() {
        describe("Component behavior", function() {
            it("should perform expected action", function() {
                // Test implementation
            });
        });
    }
}
```

## Key Patterns and Practices

### Dependency Injection
- Use WireBox DSL: `inject="ComponentName@cbelasticsearch"`
- Configuration injection: `inject="Config@cbelasticsearch"`
- Client injection: `inject="HyperClient@cbelasticsearch"`

### Error Handling
- Use try/catch blocks for external service calls
- Throw descriptive exceptions with context
- Log errors appropriately based on severity

### Fluent API Pattern
The SearchBuilder and other builders use method chaining:
```cfml
var searchResults = getInstance("SearchBuilder@cbelasticsearch")
    .new(index="myindex")
    .match("field", "value")
    .sort("timestamp", "desc")
    .execute();
```

### Configuration Management
- Use `getSystemSetting()` for environment variables
- Provide sensible defaults
- Support both module settings and environment configuration

## Building and Deployment

### Build Commands
```bash
# Format code
box run-script format

# Check formatting
box run-script format:check

# Build module
box run-script build:module

# Build documentation
box run-script build:docs
```

### Release Process
1. Update `changelog.md` with version changes
2. Update version in `box.json`
3. Run `box recipe build/release.boxr`

## Common Tasks

### Adding New Search Methods
1. Add method to `SearchBuilder.cfc`
2. Update DSL building in private methods
3. Add tests in `test-harness/tests/specs/unit/`
4. Document in `docs/Searching/`

### Adding New Index Operations
1. Add method to `IndexBuilder.cfc` or create new builder
2. Implement client communication
3. Add corresponding tests
4. Update documentation

### Configuration Changes
1. Update defaults in `ModuleConfig.cfc`
2. Add environment variable support
3. Update documentation in `docs/Getting-Started/Configuration.md`

## Security Considerations

- Always use CFQUERYPARAM equivalent for dynamic queries
- Validate input parameters
- Sanitize user input before building Elasticsearch queries
- Use environment variables for sensitive configuration
- Follow principle of least privilege for Elasticsearch permissions

## Performance Guidelines

- Use connection pooling (configured in module settings)
- Implement proper timeout handling
- Use bulk operations for multiple documents
- Consider index design for query performance
- Monitor and log slow queries

## When Modifying This Project

1. **Follow existing patterns** - Look at similar implementations before creating new ones
2. **Test thoroughly** - Both unit tests and integration tests with real Elasticsearch
3. **Document changes** - Update relevant documentation files
4. **Format code** - Run `box run-script format` before committing
5. **Check dependencies** - Ensure compatibility with supported CFML engines
6. **Consider backwards compatibility** - This is a widely-used module

Remember: This module serves as a bridge between ColdBox applications and Elasticsearch, so both CFML/ColdBox patterns and Elasticsearch best practices should be considered in development decisions.