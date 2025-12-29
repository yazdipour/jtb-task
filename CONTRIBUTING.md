# Contributing to Reproducible TeamCity Build

Thank you for your interest in contributing! This document provides guidelines and best practices for contributing to this project.

## Development Setup

### Prerequisites

- Java 17 or later
- Maven 3.6+
- Docker and Docker Compose
- Bash 4.0+ (for script development)
- ShellCheck (for bash script linting)

### Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/yazdipour/jtb-task.git
   cd jtb-task
   ```

2. Build the project:
   ```bash
   mvn clean javadoc:javadoc
   ```

3. Run the tests:
   ```bash
   bash test.sh
   ```

## Code Standards

### Bash Scripts

All bash scripts must follow these standards:

1. **Strict Mode**: Always start with `set -euo pipefail`
2. **ShellCheck**: All scripts must pass `shellcheck` without warnings
3. **Documentation**: Include usage/help messages
4. **Error Handling**: 
   - Use descriptive error messages
   - Include proper exit codes (0 for success, 1+ for errors)
   - Implement graceful failure handling
5. **Logging**: Use structured logging (INFO/WARN/ERROR)
6. **Constants**: Use readonly variables for constants
7. **Validation**: Validate all inputs and parameters
8. **Cleanup**: Use trap for cleanup of temporary files

**Example:**
```bash
#!/bin/bash
set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

error() {
    echo "ERROR: $*" >&2
}

main() {
    # Your code here
    :
}

main "$@"
```

### TeamCity Kotlin DSL

1. **Package Declaration**: Always include package declaration (`package _Self`)
2. **Imports**: Only import what you use
3. **IDs**: Use clear, descriptive IDs for build configurations
4. **Parameters**: 
   - Use descriptive parameter names
   - Include descriptions for all parameters
   - Set appropriate defaults
5. **Requirements**: Specify all agent requirements explicitly
6. **Documentation**: Comment complex configurations

### Testing

1. **All Changes**: Test all changes locally before committing
2. **Bash Scripts**: Run shellcheck on modified scripts
3. **Integration Tests**: Run the full test suite (`test.sh`)
4. **Reproducibility**: Verify archive reproducibility after changes

## Commit Guidelines

### Commit Message Format

```
<type>: <short description>

<detailed description if needed>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Test additions or changes
- `chore`: Build process or auxiliary tool changes

**Examples:**
```
feat: Add retry logic to release notes fetching

Added 3-attempt retry mechanism with exponential backoff to improve
reliability when fetching release notes from unreliable sources.

fix: Correct timestamp normalization in archive script

docs: Update README with new configuration parameters
```

## Pull Request Process

1. **Create Branch**: Create a feature branch from `master`
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Changes**: Implement your changes following the code standards

3. **Test**: Run all tests and ensure they pass
   ```bash
   shellcheck scripts/*.sh
   bash test.sh
   ```

4. **Commit**: Make clear, atomic commits with descriptive messages

5. **Push**: Push your branch and create a pull request
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Review**: Address any feedback from code review

## Code Review Checklist

Before submitting a PR, verify:

- [ ] Code follows project style guidelines
- [ ] All tests pass
- [ ] ShellCheck passes for bash scripts
- [ ] Documentation is updated (if applicable)
- [ ] Commit messages are clear and descriptive
- [ ] No unnecessary files are committed
- [ ] Changes are minimal and focused
- [ ] Reproducibility is maintained (for build changes)

## TeamCity DSL Best Practices

### 1. Use Parameters for Configuration

**Bad:**
```kotlin
scriptContent = """
    curl https://example.com/releases.txt
""".trimIndent()
```

**Good:**
```kotlin
scriptContent = """
    curl %env.MARKETING_URL%
""".trimIndent()
```

### 2. Specify Agent Requirements

```kotlin
requirements {
    exists("docker.server.version")
    exists("maven")
    moreThanOrEqual("teamcity.agent.hardware.diskSpace.available", "5")
}
```

### 3. Add Failure Conditions

```kotlin
failureConditions {
    executionTimeoutMin = 30
    errorMessage = true
}
```

### 4. Use Cleanup Policies

```kotlin
cleanup {
    artifacts(days = 30)
    history(days = 90)
    preventDependencyCleanup = true
}
```

## Bash Best Practices

### 1. Input Validation

```bash
validate_params() {
    if [[ -z "${PARAM:-}" ]]; then
        error "PARAM is required"
        usage
        exit 1
    fi
}
```

### 2. Structured Logging

```bash
info() { echo "INFO: $*"; }
warn() { echo "WARNING: $*" >&2; }
error() { echo "ERROR: $*" >&2; }
```

### 3. Atomic File Operations

```bash
TMP_FILE="$(mktemp)"
trap 'rm -f "${TMP_FILE}"' EXIT
curl -o "${TMP_FILE}" "${URL}"
mv "${TMP_FILE}" "${FINAL_FILE}"
```

### 4. Retry Logic

```bash
attempt=1
while [[ ${attempt} -le 3 ]]; do
    if command_that_might_fail; then
        return 0
    fi
    ((attempt++))
    sleep 2
done
return 1
```

## Resources

- [TeamCity Kotlin DSL Documentation](https://www.jetbrains.com/help/teamcity/kotlin-dsl.html)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [ShellCheck Wiki](https://www.shellcheck.net/wiki/)
- [Reproducible Builds](https://reproducible-builds.org/)

## Getting Help

If you have questions or need help:

1. Check the [README.md](README.md) for documentation
2. Review existing issues and pull requests
3. Open a new issue with your question

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.
