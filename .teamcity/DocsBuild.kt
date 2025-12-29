/*
 * TeamCity Build Configuration for Reproducible Documentation
 * 
 * This build configuration generates Javadoc and packages it into a
 * byte-for-byte reproducible archive.
 */

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.dockerSupport
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.vcs

/**
 * Build configuration for generating reproducible documentation archives.
 * 
 * Build Steps:
 * 1. Build Docker image (Toolchain)
 * 2. Fetch release notes (inside Docker)
 * 3. Generate Javadoc (inside Docker)
 * 4. Create reproducible archive (inside Docker)
 * 
 * Artifacts:
 * - docs.tar.gz: Reproducible archive containing Javadoc and release notes
 */
object DocsBuild : BuildType({
    id("DocsBuild")
    name = "Build Documentation"
    description = "Generates Javadoc and creates a byte-for-byte reproducible archive"

    // Build number includes short commit hash for traceability
    buildNumberPattern = "%build.counter%-%build.vcs.number.DocsRepository%"

    // Artifact rules - publish the reproducible archive
    artifactRules = """
        docs.tar.gz => .
    """.trimIndent()

    vcs {
        root(DocsVcsRoot)
        cleanCheckout = true
    }

    params {
        // Commit hash from VCS (full hash for scripts)
        param("commit.hash", "%build.vcs.number%")
        
        // Commit timestamp - will be set by first build step
        param("commit.timestamp", "")

        // Docker image tag (unique per build to avoid collisions)
        param("docker.image.tag", "docs-builder:%build.counter%")
    }

    steps {
        // Step 1: Build Docker image and extract commit metadata
        script {
            id = "BUILD_ENV"
            name = "Prepare Build Environment"
            scriptContent = """
                #!/bin/bash
                set -euo pipefail
                
                # Extract commit timestamp for reproducible builds
                COMMIT_TS=$(git log -1 --format='%ci' HEAD | cut -d' ' -f1,2)
                echo "Commit timestamp: ${'$'}COMMIT_TS"
                
                # Export for subsequent steps via TeamCity service message
                echo "##teamcity[setParameter name='commit.timestamp' value='${'$'}COMMIT_TS']"
                
                echo "Building Docker image: %docker.image.tag%"
                docker build --pull -t "%docker.image.tag%" -f Dockerfile .
            """.trimIndent()
        }

        // Step 2: Fetch release notes (run directly via docker run)
        script {
            id = "FETCH_NOTES"
            name = "Fetch Release Notes"
            scriptContent = """
                #!/bin/bash
                set -euo pipefail
                
                echo "Fetching release notes for commit %commit.hash%"
                echo "Marketing URL: %env.MARKETING_URL%"
                
                # Create persistent cache directory on the agent (survives clean checkouts)
                CACHE_DIR="/opt/buildagent/cache/release-notes"
                mkdir -p "${'$'}CACHE_DIR"
                
                # Run fetch script inside Docker container
                # Mount both workspace and persistent cache
                docker run --rm \
                    -v "%teamcity.build.checkoutDir%:/workspace" \
                    -v "${'$'}CACHE_DIR:/cache" \
                    -w /workspace \
                    -e RELEASE_NOTES_CACHE_DIR=/cache \
                    -e MARKETING_URL="%env.MARKETING_URL%" \
                    "%docker.image.tag%" \
                    bash -c "chmod +x scripts/fetch_release_notes.sh && ./scripts/fetch_release_notes.sh '%commit.hash%'" \
                    || echo "Warning: Release notes fetch failed, continuing with fallback"
            """.trimIndent()
        }

        // Step 3: Run Javadoc generation (run maven inside Docker)
        script {
            id = "JAVADOC"
            name = "Generate Javadoc"
            scriptContent = """
                #!/bin/bash
                set -euo pipefail
                
                echo "Generating Javadoc"
                
                docker run --rm \
                    -v "%teamcity.build.checkoutDir%:/workspace" \
                    -w /workspace \
                    "%docker.image.tag%" \
                    mvn -B -q clean javadoc:javadoc
            """.trimIndent()
        }

        // Step 4: Create reproducible archive using commit timestamp
        script {
            id = "ARCHIVE"
            name = "Create Reproducible Archive"
            scriptContent = """
                #!/bin/bash
                set -euo pipefail
                
                echo "Creating archive for commit %commit.hash%"
                echo "Using timestamp: %commit.timestamp%"
                
                # Use same persistent cache directory
                CACHE_DIR="/opt/buildagent/cache/release-notes"
                
                docker run --rm \
                    -v "%teamcity.build.checkoutDir%:/workspace" \
                    -v "${'$'}CACHE_DIR:/cache" \
                    -w /workspace \
                    -e RELEASE_NOTES_CACHE_DIR=/cache \
                    "%docker.image.tag%" \
                    bash -c "chmod +x scripts/create_archive.sh && ./scripts/create_archive.sh '%commit.hash%' '%commit.timestamp%'"
                
                # Verify
                if [ -f "docs.tar.gz" ]; then
                    echo "Archive created successfully."
                    sha256sum docs.tar.gz || md5 docs.tar.gz
                else
                    echo "Error: Archive not found!"
                    exit 1
                fi
            """.trimIndent()
        }
    }

    triggers {
        vcs {
            id = "VCS_TRIGGER"
            branchFilter = "+:*"
        }
    }

    failureConditions {
        executionTimeoutMin = 30
        errorMessage = true
    }

    features {
        dockerSupport {
            id = "DockerSupport"
            // Enables cleanup of Docker images created during the build
            cleanupPushedImages = true
        }
    }
})
