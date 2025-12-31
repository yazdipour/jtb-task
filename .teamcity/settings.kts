import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.triggers.vcs
import buildTypes.*

version = "2025.11"

/*
 * TeamCity Project Configuration - Reproducible Documentation Build
 *
 * Build chain on VCS trigger:
 *   FetchReleaseNotes ──┐
 *                       ├──> ArchiveBuild
 *   DocsBuild ──────────┘
 *
 *   TestBuild (runs in parallel, independent)
 */
project {
    description = "Automated documentation pipeline with byte-for-byte reproducible builds"

    // Register all build types
    buildType(FetchReleaseNotes)
    buildType(DocsBuild)
    buildType(ArchiveBuild)
    buildType(TestBuild)

    // Single VCS trigger on ArchiveBuild triggers the whole chain
    // (FetchReleaseNotes and DocsBuild run in parallel via snapshot dependencies)
    ArchiveBuild.triggers {
        vcs { }
    }

    // TestBuild runs independently in parallel
    TestBuild.triggers {
        vcs { }
    }
}
