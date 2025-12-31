import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.parallelTests
import jetbrains.buildServer.configs.kotlin.triggers.vcs
import buildTypes.*

version = "2025.11"

/*
 * TeamCity Project Configuration - Reproducible Documentation Build
 *
 * Build chain:
 *                    ┌─> ReleaseNoteBuild ─┐
 *   TestBuild ───────┤                     ├──> ArchiveBuild
 *                    └─> DocsBuild ────────┘
 */
project {
    description = "Automated documentation pipeline with byte-for-byte reproducible builds"

    // Define build chain with sequential/parallel
    val builds = sequential {
        buildType(TestBuild)
        parallel {
            buildType(ReleaseNoteBuild)
            buildType(DocsBuild)
        }
        buildType(ArchiveBuild)
    }.buildTypes()

    // Register all build types
    builds.forEach { buildType(it) }

    // VCS trigger on the last build triggers the whole chain
    builds.last().triggers {
        vcs { }
    }
}
