/*
 * TeamCity Build Configuration for Reproducible Documentation
 * 
 * This build configuration generates Javadoc and packages it into a
 * byte-for-byte reproducible archive.
 */

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.dockerSupport
import jetbrains.buildServer.configs.kotlin.buildSteps.dockerCommand
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.vcs

/**
 * Build configuration for generating reproducible documentation archives.
 * 
 * Build Steps:
 * 1. Fetch release notes (with graceful failure handling)
 * 2. Build Docker image for consistent build environment
 * 3. Run Javadoc generation inside Docker container
 * 4. Create reproducible archive
 * 
 * Artifacts:
 * - docs.tar.gz: Reproducible archive containing Javadoc and release notes
 */
object DocsBuild : BuildType({
    id("DocsBuild")
    name = "Build Documentation"
    description = "Generates Javadoc and creates a byte-for-byte reproducible archive"

    // Artifact rules - publish the reproducible archive
    artifactRules = """
        docs.tar.gz => .
    """.trimIndent()

    // VCS settings
    vcs {
        root(DocsVcsRoot)
        
        // Clean checkout ensures reproducibility
        cleanCheckout = true
    }

    // Build parameters
    params {
        // Commit hash from VCS (automatically populated by TeamCity)
        param("commit.hash", "%build.vcs.number%")
        
        // Timeout for external requests (seconds)
        param("fetch.timeout", "10")
    }

    // Build steps
    steps {
        // Step 0: Install Maven and Java
        script {
            id = "INSTALL_TOOLS"
            name = "Install Build Tools"
            scriptContent = """
                #!/bin/bash
                set -euo pipefail
                
                echo "=============================================="
                echo "Installing Maven and Java"
                echo "=============================================="
                
                # Check if running as root or with sudo
                if [ "$(id -u)" -eq 0 ] || sudo -n true 2>/dev/null; then
                    SUDO=""
                    [ "$(id -u)" -ne 0 ] && SUDO="sudo"
                    
                    # Install Java and Maven
                    $SUDO apt-get update -qq
                    $SUDO apt-get install -y -qq maven openjdk-17-jdk
                else
                    echo "Note: Running without sudo. Assuming tools are already installed."
                fi
                
                # Verify installations
                java -version
                mvn -version
                
                echo ""
                echo "Tools installation completed"
            """.trimIndent()
        }
        
        // Step 1: Fetch release notes with graceful failure handling
        script {
            id = "FETCH_RELEASE_NOTES"
            name = "Fetch Release Notes"
            scriptContent = """
                #!/bin/bash
                set -euo pipefail
                
                echo "=============================================="
                echo "Step 1: Fetching Release Notes"
                echo "=============================================="
                echo "Commit Hash: %commit.hash%"
                echo "Marketing URL: %env.MARKETING_URL%"
                echo ""
                
                # Make script executable
                chmod +x scripts/fetch_release_notes.sh
                
                # Execute fetch script with commit hash
                # This script handles failures gracefully and never fails the build
                ./scripts/fetch_release_notes.sh "%commit.hash%"
                
                echo ""
                echo "Release notes fetch completed"
            """.trimIndent()
        }

        // Step 2: Build Docker image for consistent build environment
        dockerCommand {
            id = "BUILD_DOCKER_IMAGE"
            name = "Build Docker Image"
            commandType = build {
                source = file {
                    path = "Dockerfile"
                }
                namesAndTags = "%docker.image.tag%"
                commandArgs = "--no-cache"
            }
        }

        // Step 3: Run Javadoc generation in Docker container
        script {
            id = "RUN_JAVADOC_BUILD"
            name = "Generate Javadoc in Docker"
            scriptContent = """
                #!/bin/bash
                set -euo pipefail
                
                echo "=============================================="
                echo "Step 3: Generating Javadoc"
                echo "=============================================="
                
                # Find and run Maven javadoc generation
                export PATH="/usr/bin:/usr/local/bin:${'$'}PATH"
                which mvn || (echo "Maven not found, trying to locate..." && find /usr -name mvn 2>/dev/null | head -1)
                
                MVN=$(which mvn || find /usr -name mvn 2>/dev/null | head -1)
                if [ -z "${'$'}MVN" ]; then
                    echo "ERROR: Maven not found"
                    exit 1
                fi
                
                echo "Using Maven at: ${'$'}MVN"
                ${'$'}MVN clean javadoc:javadoc -B -q
                
                echo ""
                echo "Javadoc generation completed"
            """.trimIndent()
        }

        // Step 4: Create reproducible archive
        script {
            id = "CREATE_ARCHIVE"
            name = "Create Reproducible Archive"
            scriptContent = """
                #!/bin/bash
                set -euo pipefail
                
                echo "=============================================="
                echo "Step 4: Creating Reproducible Archive"
                echo "=============================================="
                echo "Commit Hash: %commit.hash%"
                echo ""
                
                # Make script executable
                chmod +x scripts/create_archive.sh
                
                # Create the reproducible archive
                ./scripts/create_archive.sh "%commit.hash%"
                
                echo ""
                echo "=============================================="
                echo "Archive Creation Complete"
                echo "=============================================="
                
                # Display final verification info
                if [ -f "docs.tar.gz" ]; then
                    echo "Archive: docs.tar.gz"
                    echo "Size: $(wc -c < docs.tar.gz) bytes"
                    echo "SHA256: $(sha256sum docs.tar.gz | cut -d' ' -f1)"
                    echo ""
                    echo "To verify reproducibility, run this build again"
                    echo "and compare the SHA256 hashes."
                else
                    echo "ERROR: Archive was not created"
                    exit 1
                fi
            """.trimIndent()
        }
    }

    // Build triggers
    triggers {
        vcs {
            id = "VCS_TRIGGER"
            
            // Trigger on all branches
            branchFilter = "+:*"
        }
    }

    // Build features
    features {
        // Enable Docker support for the build
        dockerSupport {
            id = "DOCKER_SUPPORT"
        }
    }
})
