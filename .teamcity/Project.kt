/*
 * TeamCity Project Configuration - Reproducible Documentation Build
 */

import jetbrains.buildServer.configs.kotlin.*

object ReproducibleDocsProject : Project({
    description = "Automated documentation pipeline with byte-for-byte reproducible builds"

    buildType(DocsBuild)

    params {
        param("env.MARKETING_URL", "https://example.XXXXX")
    }
})
