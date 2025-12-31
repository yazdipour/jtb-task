import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.ScriptBuildStep
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.triggers.vcs

/**
 * Runs tests to verify reproducibility and fallback behavior.
 * Triggered on every push, runs after DocsBuild.
 */
object TestBuild : BuildType({
    id("TestBuild")
    name = "Test Reproducibility"
    description = "Verifies byte-for-byte reproducibility and fallback behavior"

    vcs {
        root(DslContext.settingsRoot)
        cleanCheckout = true
    }

    dependencies {
        snapshot(DocsBuild) {
            onDependencyFailure = FailureAction.FAIL_TO_START
        }
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

    triggers {
        vcs { }
    }

    failureConditions {
        executionTimeoutMin = 15
    }
})
