import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.ScriptBuildStep
import jetbrains.buildServer.configs.kotlin.buildSteps.maven
import jetbrains.buildServer.configs.kotlin.buildSteps.script

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
            dockerImage = DOCKER_IMAGE_MAVEN
        }

        script {
            id = "ARCHIVE"
            name = "Create Reproducible Archive"
            scriptContent = "apk add -q tar && sh scripts/create_archive.sh '%commit.hash%' '%build.timestamp%'"
            dockerImage = DOCKER_IMAGE_ALPINE
            dockerImagePlatform = ScriptBuildStep.ImagePlatform.Linux
        }
    }

    failureConditions {
        executionTimeoutMin = 10
    }
})
