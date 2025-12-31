import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.ScriptBuildStep
import jetbrains.buildServer.configs.kotlin.buildSteps.script

/**
 * Creates reproducible archive from Javadoc and release notes.
 * Depends on both FetchReleaseNotes and DocsBuild.
 */
object ArchiveBuild : BuildType({
    id("ArchiveBuild")
    name = "Create Archive"
    description = "Creates byte-for-byte reproducible archive"

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
                artifactRules = "$RELEASE_NOTES_FILE => release-notes/"
            }
        }
        dependency(DocsBuild) {
            snapshot {
                onDependencyFailure = FailureAction.FAIL_TO_START
            }
            artifacts {
                artifactRules = "$JAVADOC_DIR => target/reports/"
            }
        }
    }

    steps {
        script {
            id = "COMMIT_TS"
            name = "Get Commit Timestamp"
            scriptContent = "sh scripts/get_commit_timestamp.sh"
        }

        script {
            id = "ARCHIVE"
            name = "Create Reproducible Archive"
            scriptContent = "apk add -q tar && sh scripts/create_archive.sh '%commit.hash%' '%build.timestamp%' 'release-notes/$RELEASE_NOTES_FILE'"
            dockerImage = DOCKER_IMAGE_ALPINE
            dockerImagePlatform = ScriptBuildStep.ImagePlatform.Linux
        }
    }

    failureConditions {
        executionTimeoutMin = 5
    }
})
