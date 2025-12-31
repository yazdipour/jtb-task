import jetbrains.buildServer.configs.kotlin.*
import _Self.buildTypes.*

version = "2025.11"

/*
 * TeamCity Project Configuration - Reproducible Documentation Build
 */
project {
    description = "Automated documentation pipeline with byte-for-byte reproducible builds"

    buildType(FetchReleaseNotes)
    buildType(DocsBuild)
    buildType(ArchiveBuild)
    buildType(TestBuild)

    // Build order in UI
    buildTypesOrder = listOf(FetchReleaseNotes, DocsBuild, ArchiveBuild, TestBuild)
}
