package buildTypes

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.ScriptBuildStep
import jetbrains.buildServer.configs.kotlin.buildSteps.script

/**
 * Fetches release notes and publishes as artifact.
 */
object ReleaseNoteBuild : BuildType({
    id("ReleaseNoteBuild")
    name = "Fetch Release Notes"
    description = "Downloads release notes and caches as artifact"

    artifactRules = RELEASE_NOTES_FILE

    vcs {
        root(DslContext.settingsRoot)
    }

    params {
        param("commit.hash", "%build.vcs.number%")
        param("env.MARKETING_URL", "https://example.XXXXX")
    }

    steps {
        script {
            id = "FETCH"
            name = "Fetch Release Notes"
            scriptContent = "apk add -q curl && sh scripts/fetch_release_notes.sh '%commit.hash%' '%env.MARKETING_URL%'"
            dockerImage = DOCKER_IMAGE_ALPINE
            dockerImagePlatform = ScriptBuildStep.ImagePlatform.Linux
            dockerRunParameters = "-v /opt/buildagent/cache/release-notes:/cache -e RELEASE_NOTES_CACHE_DIR=/cache"
        }
    }

    failureConditions {
        executionTimeoutMin = 5
    }
})
