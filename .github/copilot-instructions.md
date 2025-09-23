# CBElasticsearch Module Development Instructions

CBElasticsearch is a CFML (ColdFusion/Lucee) module that provides a fluent API for Elasticsearch integration with the ColdBox Framework. It includes CacheBox cache providers and LogBox appenders for Elasticsearch.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Prerequisites and Dependencies
- Install Java 17+ (OpenJDK Temurin recommended)
- Install Docker and Docker Compose
- Install CommandBox CLI for CFML development

### Bootstrap and Setup Commands
Execute these commands in exact order to set up the development environment:

```bash
# 1. Install CommandBox (if not available, use Docker approach below)
curl -fsSL https://downloads.ortussolutions.com/debs/gpg | sudo apt-key add -
echo "deb https://downloads.ortussolutions.com/debs/noarch /" | sudo tee -a /etc/apt/sources.list.d/commandbox.list
sudo apt-get update && sudo apt-get install -y commandbox

# 2. Install project dependencies (takes 2-5 minutes depending on network)
box install
cd test-harness && box install && cd ../

# 3. Start Elasticsearch with Docker Compose (takes 30-45 seconds)
# NEVER CANCEL: Elasticsearch startup takes 30-45 seconds. Set timeout to 90+ seconds.
docker compose up -d elasticsearch

# 4. Wait for Elasticsearch to be ready (critical - wait for green status)
sleep 30
curl -s http://localhost:9200/_cluster/health | jq '.status'  # Should return "green"
```

### Alternative Setup (when CommandBox installation fails)
If CommandBox installation fails due to network restrictions:

```bash
# Use Docker for CommandBox operations (NOTE: ForgeBox access may still fail)
docker run --rm -v $(pwd):/app ortussolutions/commandbox:lucee5 box install
cd test-harness && docker run --rm -v $(pwd):/app ortussolutions/commandbox:lucee5 box install && cd ../

# If ForgeBox access fails completely, document this limitation:
# "box install -- fails due to network restrictions preventing ForgeBox access"
```

### Build and Test Commands
- **NEVER CANCEL**: Build operations take 5-15 minutes. Set timeout to 30+ minutes.
- **NEVER CANCEL**: Test suite takes 3-8 minutes per engine. Set timeout to 20+ minutes.

```bash
# Format code (ALWAYS run before committing and pushing any files)
# CRITICAL: This command MUST be run before any commit to ensure code formatting compliance
# NOTE: Requires cfformat module - may fail if dependencies unavailable
box run-script format

# Check code formatting
# NOTE: Requires cfformat module - may fail if dependencies unavailable  
box run-script format:check

# Lint code (if cflint is available)
cflint

# Start test server (takes 60-90 seconds to fully boot)
# NEVER CANCEL: Server startup takes 60-90 seconds. Set timeout to 180+ seconds.
box start

# Run complete test suite (takes 3-8 minutes)
# NEVER CANCEL: Tests take 3-8 minutes to complete. Set timeout to 15+ minutes.
box testbox run

# Build module for distribution (takes 5-15 minutes)
# NEVER CANCEL: Build takes 5-15 minutes. Set timeout to 30+ minutes.
box run-script build:module

# Build documentation only
box run-script build:docs
```

### Development Workflow Commands
```bash
# Start development environment
docker compose up -d                    # Starts Elasticsearch + app containers
box start                              # Starts local CommandBox server

# Run tests during development
box testbox run --verbose              # Run all tests with verbose output
box testbox run --directory=tests/specs/unit  # Run only unit tests

# Stop everything
box stop                               # Stop CommandBox server
docker compose down                    # Stop all Docker services
```

## Validation

### Required Validation Steps
ALWAYS run these validation steps after making code changes:

1. **Elasticsearch Health Validation**:
   ```bash
   # Verify Elasticsearch is running and healthy (takes 5-10 seconds)
   curl -s http://localhost:9200/_cluster/health | jq '.status'  # Should return "green"
   ```

2. **Code Quality Validation** (if dependencies available):
   ```bash
   box run-script format:check           # Verify code formatting
   box run-script format                 # Auto-fix formatting issues
   # CRITICAL: Always run format command before committing any files
   ```

3. **Build Validation** (if dependencies available):
   ```bash
   # NEVER CANCEL: Build takes 5-15 minutes
   box run-script build:module
   ```

4. **Test Validation** (if dependencies available):
   ```bash
   # Ensure Elasticsearch is running first
   curl -s http://localhost:9200/_cluster/health | jq '.status'
   
   # NEVER CANCEL: Tests take 3-8 minutes per engine
   box testbox run --verbose
   ```

4. **End-to-End Scenario Testing**:
   After making changes, always test these core scenarios:
   - **Search Operations**: Create index, add documents, search, retrieve results
   - **Cache Operations**: Store/retrieve data via CacheBox provider
   - **Logging**: Verify LogBox appender logs to Elasticsearch
   - **Index Management**: Create/update/delete indices and mappings

### CI/CD Validation
The GitHub Actions CI will fail if:
- Code formatting is incorrect (ALWAYS run `box run-script format` before committing)
- Tests fail on any supported engine (Lucee 5/6, Adobe CF 2018/2021/2023/2025, BoxLang)
- Build process fails
- Security scans detect high-severity issues

## Environment Configuration

### Elasticsearch Configuration
The module supports both Elasticsearch 7.x and 8.x. Default configuration:
```ini
ELASTICSEARCH_PROTOCOL=http
ELASTICSEARCH_HOST=127.0.0.1
ELASTICSEARCH_PORT=9200
```

### Multi-Version Testing
The CI tests against multiple configurations:
- **Elasticsearch**: 7.17.10, 8.14.1, 8.17.1
- **CFML Engines**: Lucee 5/6, Adobe CF 2018/2021/2023/2025, BoxLang 1.0
- **ColdBox Versions**: 6.x, 7.x

### Docker Compose Services
Available services via `docker compose up`:
- `elasticsearch`: Elasticsearch 8.17.1 on port 9200
- `elasticsearch7`: Elasticsearch 7.17.6 on port 9201
- `app`: Adobe CF 2018 with module on port 8080
- `app-lucee5`: Lucee 5 with module on port 8081

## Critical Timing Information

### Build Times and Timeouts
- **Elasticsearch startup**: 5-10 seconds (timeout: 30+ seconds)
- **CommandBox server startup**: 60-90 seconds (timeout: 180+ seconds)
- **Dependency installation**: 2-5 minutes (timeout: 10+ minutes) *[may fail due to network restrictions]*
- **Test suite execution**: 3-8 minutes per engine (timeout: 15+ minutes)
- **Module build**: 5-15 minutes (timeout: 30+ minutes)
- **Documentation build**: 2-5 minutes (timeout: 10+ minutes)
- **Docker Compose full startup**: 25-30 seconds (timeout: 60+ seconds)
- **Docker Compose shutdown**: 10-15 seconds (timeout: 30+ seconds)

### **CRITICAL: NEVER CANCEL LONG-RUNNING OPERATIONS**
All build and test operations may take significant time. Canceling prematurely will result in incomplete builds and failed tests.

## Key Project Structure

### Core Module Files
- `ModuleConfig.cfc` - Module configuration and dependencies
- `models/` - Core module classes (SearchBuilder, IndexBuilder, etc.)
- `models/cache/` - CacheBox provider implementation
- `models/logging/` - LogBox appender implementation

### Testing Infrastructure
- `test-harness/` - Complete test application
- `test-harness/tests/specs/unit/` - Unit tests
- `test-harness/config/Coldbox.cfc` - Test app configuration

### Build System
- `box.json` - Project dependencies and scripts
- `build/Build.cfc` - Build automation scripts
- `build/release.boxr` - Release automation recipe
- `.github/workflows/` - CI/CD pipeline definitions

### Configuration Files
- `docker-compose.yml` - Development environment setup
- `.cfformat.json` - Code formatting rules
- `.cflintrc` - Code linting configuration
- `.env.template` - Environment variable template

## Common Tasks

### Creating New Features
1. Write unit tests first in `test-harness/tests/specs/unit/`
2. Implement feature in appropriate `models/` subdirectory
3. Update `ModuleConfig.cfc` if adding new mappings
4. Run validation steps (ALWAYS run `box run-script format` before committing, then build, test)
5. Update documentation in `docs/` if needed

### Debugging Test Failures
1. Check Elasticsearch status: `curl http://localhost:9200/_cluster/health`
2. Review server logs: `box server log`
3. Check Docker logs: `docker compose logs elasticsearch`
4. Run specific test suites: `box testbox run --directory=tests/specs/unit/SpecificTest.cfc`

### Adding Dependencies
1. Update `box.json` dependencies section
2. Run `box install` to install
3. Update test-harness: `cd test-harness && box install`
4. Test build process: `box run-script build:module`

### Release Process
Releases are automated via GitHub Actions, but manual releases use:
```bash
# Update changelog.md with new version info
# Update box.json version number
box recipe build/release.boxr
```

## Network and Access Limitations

If you encounter network restrictions preventing access to ForgeBox or other external resources:
- Use Docker-based CommandBox operations when possible
- Document any commands that fail due to network restrictions
- Focus on testing local functionality that doesn't require external dependencies
- The CI environment has full network access and will validate complete builds

### Commands That May Fail Due to Network Restrictions
```bash
# These commands require ForgeBox/external access:
box install                    # "forgebox ran into an issue" 
box run-script format          # Requires cfformat module
box run-script format:check    # Requires cfformat module
```

### Working Commands in Restricted Environments
```bash
# These commands work without external access:
docker compose up -d elasticsearch              # Uses local/cached Docker images
docker compose logs elasticsearch               # Local Docker logs
curl http://localhost:9200/_cluster/health      # Local Elasticsearch API
docker run --rm -v $(pwd):/app ortussolutions/commandbox:lucee5 box version  # Basic CommandBox
```

## Error Recovery

### Common Issues and Solutions
1. **"CommandBox not found"** - Use Docker approach or install from GitHub releases
2. **"Elasticsearch connection failed"** - Verify `docker compose up -d elasticsearch` succeeded
3. **"ForgeBox connection failed"** - Network restrictions, use cached dependencies or Docker
4. **"Tests hanging"** - Increase timeout values, Elasticsearch may still be starting
5. **"Build fails"** - Check code formatting first: `box run-script format` (ALWAYS run before committing)

### Recovery Commands
```bash
# Reset development environment
box stop
docker compose down
docker compose up -d elasticsearch
sleep 30
box start
```