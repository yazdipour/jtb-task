import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.ScriptBuildStep
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.vcs

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
            scriptContent = "apk add -q curl && sh scripts/fetch_release_notes.sh '%commit.hash%' '%env.MARKETING_URL%'"
            dockerImage = DOCKER_IMAGE_ALPINE
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
