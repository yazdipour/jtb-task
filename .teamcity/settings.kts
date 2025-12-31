import jetbrains.buildServer.configs.kotlin.*

version = "2025.11"

/*
 * TeamCity Project Configuration - Reproducible Documentation Build
 */
project {
    id("ReproducibleDocsProject")
    name = "Reproducible Documentation"
    description = "Automated documentation pipeline with byte-for-byte reproducible builds"

    buildType(FetchReleaseNotes)
    buildType(DocsBuild)
    buildType(ArchiveBuild)
    buildType(TestBuild)

    // Build order in UI
    buildTypesOrder = listOf(FetchReleaseNotes, DocsBuild, ArchiveBuild, TestBuild)

    params {
        // Prevent UI edits that would conflict with DSL
        param("teamcity.ui.settings.readOnly", "true")
    }
}
