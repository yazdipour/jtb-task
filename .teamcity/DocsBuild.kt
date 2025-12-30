/*
 * TeamCity Build Configuration for Reproducible Documentation
 */

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.dockerSupport
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.vcs

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
        param("docker.image.tag", "docs-builder:%build.counter%")
        param("env.TEAMCITY_BUILD_CHECKOUTDIR", "%teamcity.build.checkoutDir%")
    }

    steps {
        script {
            id = "JAVADOC"
            name = "Build Image & Generate Javadoc"
            scriptContent = "bash scripts/generate_javadoc.sh '%docker.image.tag%'"
        }

        script {
            id = "FETCH_NOTES"
            name = "Fetch Release Notes"
            scriptContent = "bash scripts/run_in_docker.sh '%docker.image.tag%' bash scripts/fetch_release_notes.sh '%commit.hash%' || true"
        }

        script {
            id = "ARCHIVE"
            name = "Create Reproducible Archive"
            scriptContent = "bash scripts/run_in_docker.sh '%docker.image.tag%' bash scripts/create_archive.sh '%commit.hash%'"
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
