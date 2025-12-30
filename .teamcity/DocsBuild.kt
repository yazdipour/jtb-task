/*
 * TeamCity Build Configuration for Reproducible Documentation
 * 
 * Generates Javadoc and packages it into a byte-for-byte reproducible archive.
 */

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.dockerSupport
import jetbrains.buildServer.configs.kotlin.buildSteps.ScriptBuildStep
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.vcs

/** Persistent cache path on the build agent (survives clean checkouts). */
private const val CACHE_DIR = "/opt/buildagent/cache/release-notes"

/**
 * Helper to generate a docker run command with standard workspace/cache mounts.
 */
private fun dockerRun(imageTag: String, command: String, withCache: Boolean = false, extraEnv: String = ""): String {
    val cacheMount = if (withCache) "-v \"$CACHE_DIR:/cache\" -e RELEASE_NOTES_CACHE_DIR=/cache" else ""
    return """
        docker run --rm \
            -v "%teamcity.build.checkoutDir%:/workspace" \
            $cacheMount \
            -w /workspace \
            $extraEnv \
            "$imageTag" \
            $command
    """.trimIndent()
}

/**
 * Build configuration for generating reproducible documentation archives.
 * 
 * Steps: Build Docker image → Fetch release notes → Generate Javadoc → Create archive
 * Artifact: docs.tar.gz (reproducible archive with Javadoc and release notes)
 */
object DocsBuild : BuildType({
    id("DocsBuild")
    name = "Build Documentation"
    description = "Generates Javadoc and creates a byte-for-byte reproducible archive"

    buildNumberPattern = "%build.counter%-%build.vcs.number%"
    artifactRules = "docs.tar.gz"

    vcs {
        root(DocsVcsRoot)
        cleanCheckout = true
    }

    params {
        param("commit.hash", "%build.vcs.number%")
        param("commit.timestamp", "")
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
                
                # Extract commit timestamp (YYYY-MM-DD HH:MM:SS)
                COMMIT_TS=${'$'}(git log -1 --format='%ci' HEAD 2>/dev/null | cut -d' ' -f1,2 || echo "")
                
                if [[ ! "${'$'}COMMIT_TS" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
                    echo "Warning: Could not extract commit timestamp, using fallback"
                    COMMIT_TS="1980-01-01 00:00:00"
                fi
                
                echo "Commit timestamp: ${'$'}COMMIT_TS"
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
                mkdir -p "$CACHE_DIR"
                
                ${dockerRun(
                    imageTag = "%docker.image.tag%",
                    command = """bash -c "chmod +x scripts/fetch_release_notes.sh && ./scripts/fetch_release_notes.sh '%commit.hash%'"""",
                    withCache = true,
                    extraEnv = """-e MARKETING_URL="%env.MARKETING_URL%""""
                )} || echo "Warning: Release notes fetch failed, continuing with fallback"
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
                ${dockerRun("%docker.image.tag%", "mvn -B -q clean javadoc:javadoc")}
            """.trimIndent()
        }

        // Step 4: Create reproducible archive using commit timestamp
        script {
            id = "ARCHIVE"
            name = "Create Reproducible Archive"
            scriptContent = """
                #!/bin/bash
                set -euo pipefail
                
                echo "Creating archive for commit %commit.hash% with timestamp %commit.timestamp%"
                
                ${dockerRun(
                    imageTag = "%docker.image.tag%",
                    command = """bash -c "chmod +x scripts/create_archive.sh && ./scripts/create_archive.sh '%commit.hash%' '%commit.timestamp%'"""",
                    withCache = true
                )}
                
                [ -f "docs.tar.gz" ] && sha256sum docs.tar.gz || { echo "Error: Archive not found!"; exit 1; }
            """.trimIndent()
        }
    }

    triggers {
        vcs {
            branchFilter = "+:*"
        }
    }

    failureConditions {
        executionTimeoutMin = 30
    }

    features {
        dockerSupport {
            cleanupPushedImages = true
        }
    }
})
