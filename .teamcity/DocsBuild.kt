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
        
        // Marketing URL for release notes
        param("env.MARKETING_URL", "%env.MARKETING_URL%")
        
        // Timeout for external requests (seconds)
        param("fetch.timeout", "10")
    }

    // Build steps
    steps {
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
        dockerCommand {
            id = "RUN_JAVADOC_BUILD"
            name = "Generate Javadoc in Docker"
            commandType = other {
                subCommand = "run"
                commandArgs = """
                    --rm 
                    -v "%teamcity.build.checkoutDir%":/workspace 
                    -w /workspace 
                    %docker.image.tag% 
                    mvn clean javadoc:javadoc -B -q
                """.trimIndent().replace("\n", " ")
            }
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

    // Requirements
    requirements {
        // Require Docker on the build agent
        contains("docker.server.version", "")
        
        // Require bash shell
        exists("env.SHELL")
    }
})
