package buildTypes

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.ScriptBuildStep
import jetbrains.buildServer.configs.kotlin.buildSteps.script

/**
 * Runs tests to verify reproducibility and fallback behavior.
 * Runs in parallel with the main build chain.
 */
object TestBuild : BuildType({
    id("TestBuild")
    name = "Test Reproducibility"
    description = "Verifies byte-for-byte reproducibility and fallback behavior"

    vcs {
        root(DslContext.settingsRoot)
        cleanCheckout = true
    }

    steps {
        script {
            id = "TEST"
            name = "Run Tests"
            scriptContent = "bash test.sh"
            dockerImage = DOCKER_IMAGE_MAVEN
            dockerImagePlatform = ScriptBuildStep.ImagePlatform.Linux
        }
    }

    failureConditions {
        executionTimeoutMin = 15
    }
})
