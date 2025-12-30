/*
 * TeamCity Build Configuration for Reproducible Documentation
 */

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.ScriptBuildStep
import jetbrains.buildServer.configs.kotlin.buildSteps.maven
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.vcs

private const val DOCKER_IMAGE = "alpine:3.19"
private const val CACHE_MOUNT = "-v /opt/buildagent/cache/release-notes:/cache -e RELEASE_NOTES_CACHE_DIR=/cache"

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
        root(DslContext.settingsRoot)
        cleanCheckout = true
    }

    params {
        param("commit.hash", "%build.vcs.number%")
        param("build.timestamp", "")
    }

    steps {
        script {
            id = "FETCH_NOTES"
            name = "Fetch Release Notes"
            scriptContent = "apk add -q curl && sh scripts/fetch_release_notes.sh '%commit.hash%' || true"
            dockerImage = DOCKER_IMAGE
            dockerRunParameters = CACHE_MOUNT
            dockerImagePlatform = ScriptBuildStep.ImagePlatform.Linux
        }

        maven {
            id = "JAVADOC"
            name = "Generate Javadoc"
            goals = "clean javadoc:javadoc"
            runnerArgs = "-B -Dproject.build.outputTimestamp=%build.timestamp%"
            dockerImage = "maven:3.9-eclipse-temurin-21"
        }

        script {
            id = "ARCHIVE"
            name = "Create Reproducible Archive"
            scriptContent = "apk add -q tar && sh scripts/create_archive.sh '%commit.hash%'"
            dockerImage = DOCKER_IMAGE
            dockerRunParameters = CACHE_MOUNT
            dockerImagePlatform = ScriptBuildStep.ImagePlatform.Linux
        }
    }

    triggers {
        vcs {
        }
    }

    failureConditions {
        executionTimeoutMin = 10
    }
})
