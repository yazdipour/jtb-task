import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.triggers.vcs
import buildTypes.*

version = "2025.11"

/*
 * TeamCity Project Configuration - Reproducible Documentation Build
 *
 * Build chain on VCS trigger:
 *   FetchReleaseNotes ──┐
 *   DocsBuild ──────────┼──> ArchiveBuild
 *   TestBuild ──────────┘
 */
project {
    description = "Automated documentation pipeline with byte-for-byte reproducible builds"

    // Register all build types
    buildType(ReleaseNoteBuild)
    buildType(DocsBuild)
    buildType(TestBuild)
    buildType(ArchiveBuild)

    // VCS trigger on ArchiveBuild triggers the whole chain
    // (FetchReleaseNotes, DocsBuild, TestBuild run in parallel via snapshot dependencies)
    ArchiveBuild.triggers {
        vcs { }
    }
}
