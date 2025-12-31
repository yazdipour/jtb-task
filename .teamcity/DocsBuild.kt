import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildSteps.ScriptBuildStep
import jetbrains.buildServer.configs.kotlin.buildSteps.maven
import jetbrains.buildServer.configs.kotlin.buildSteps.script

/**
 * Generates Javadoc documentation.
 * Runs in parallel with FetchReleaseNotes.
 */
object DocsBuild : BuildType({
    id("DocsBuild")
    name = "Generate Javadoc"
    description = "Generates Javadoc documentation"

    artifactRules = "$JAVADOC_DIR => target/reports/"

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
    }

    triggers {
        vcs { }
    }

    failureConditions {
        executionTimeoutMin = 10
    }
})
