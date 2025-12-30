/*
 * TeamCity Project Configuration - Reproducible Documentation Build
 */

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.vcs.GitVcsRoot

object ReproducibleDocsProject : Project({
    description = "Automated documentation pipeline with byte-for-byte reproducible builds"

    vcsRoot(DocsVcsRoot)
    buildType(DocsBuild)

    params {
        param("env.MARKETING_URL", "https://example.com/release-notes.txt")
    }
})

object DocsVcsRoot : GitVcsRoot({
    id("DocsRepository")
    name = "Documentation Repository"
    url = "https://github.com/yazdipour/jtb-task.git"
    branch = "refs/heads/master"
    branchSpec = """
        +:refs/heads/*
        +:refs/tags/*
    """.trimIndent()
    checkoutPolicy = AgentCheckoutPolicy.USE_MIRRORS
    authMethod = anonymous()
})
