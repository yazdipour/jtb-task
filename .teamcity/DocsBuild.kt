/*
 * TeamCity Build Configuration for Reproducible Documentation
 */

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.maven
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
        root(DslContext.settingsRoot)
        cleanCheckout = true
    }

    params {
        param("commit.hash", "%build.vcs.number%")
        param("env.TEAMCITY_BUILD_CHECKOUTDIR", "%teamcity.build.checkoutDir%")
    }

    steps {
        maven {
            id = "JAVADOC"
            name = "Generate Javadoc"
            goals = "clean javadoc:javadoc"
            runnerArgs = "-B"
            dockerImage = "maven:3.9-eclipse-temurin-21"
        }

        script {
            id = "FETCH_NOTES"
            name = "Fetch Release Notes"
            scriptContent = "bash scripts/run_in_docker.sh bash scripts/fetch_release_notes.sh '%commit.hash%' || true"
        }

        script {
            id = "ARCHIVE"
            name = "Create Reproducible Archive"
            scriptContent = "bash scripts/run_in_docker.sh bash scripts/create_archive.sh '%commit.hash%'"
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
