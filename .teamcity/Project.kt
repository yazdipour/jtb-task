/*
 * TeamCity Project Configuration - Reproducible Documentation Build
 */

import jetbrains.buildServer.configs.kotlin.*

object ReproducibleDocsProject : Project({
    description = "Automated documentation pipeline with byte-for-byte reproducible builds"

    buildType(FetchReleaseNotes)
    buildType(DocsBuild)

    // Build order in UI
    buildTypesOrder = listOf(FetchReleaseNotes, DocsBuild)

    params {
        param("env.MARKETING_URL", "https://example.XXXXX")
    }
})
