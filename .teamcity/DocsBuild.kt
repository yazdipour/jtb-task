/*
 * TeamCity Build Configuration for Reproducible Documentation
 */

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.ScriptBuildStep
import jetbrains.buildServer.configs.kotlin.buildSteps.maven
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.vcs

private const val DOCKER_IMAGE = "alpine:3.19"

/**
 * Fetches release notes and publishes as artifact.
 * Runs once per commit, result is shared with dependent builds.
 */
object FetchReleaseNotes : BuildType({
    id("FetchReleaseNotes")
    name = "Fetch Release Notes"
    description = "Downloads release notes and caches as artifact"

    artifactRules = "release-notes.txt"

    vcs {
        root(DslContext.settingsRoot)
    }

    params {
        param("commit.hash", "%build.vcs.number%")
    }

    steps {
        script {
            id = "FETCH"
            name = "Fetch Release Notes"
            scriptContent = "apk add -q curl && sh scripts/fetch_release_notes.sh '%commit.hash%'"
            dockerImage = DOCKER_IMAGE
            dockerRunParameters = "-e MARKETING_URL=%env.MARKETING_URL%"
            dockerImagePlatform = ScriptBuildStep.ImagePlatform.Linux
        }
    }

    triggers {
        vcs { }
    }

    failureConditions {
        executionTimeoutMin = 5
    }
})

/**
 * Builds documentation archive.
 * Depends on FetchReleaseNotes to get consistent release notes across all agents.
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

    dependencies {
        dependency(FetchReleaseNotes) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }
            artifacts {
                artifactRules = "release-notes.txt => release-notes/"
            }
        }
    }

    steps {
        script {
            id = "COMMIT_TS"
            name = "Get Commit Timestamp"
            scriptContent = "sh scripts/get_commit_timestamp.sh"
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
            scriptContent = "apk add -q tar && sh scripts/create_archive.sh '%commit.hash%' '%build.timestamp%'"
            dockerImage = DOCKER_IMAGE
            dockerImagePlatform = ScriptBuildStep.ImagePlatform.Linux
        }
    }

    triggers {
        vcs { }
    }

    failureConditions {
        executionTimeoutMin = 10
    }
})
