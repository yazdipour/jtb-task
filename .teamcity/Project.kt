/*
 * TeamCity Project Configuration
 * 
 * Defines the main project structure for the Reproducible Documentation Build.
 */

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.vcs.GitVcsRoot

/**
 * Main project configuration for reproducible documentation builds.
 * 
 * This project demonstrates:
 * - Byte-for-byte reproducible archive generation
 * - Graceful handling of unreliable external dependencies
 * - Docker-based deterministic build environment
 * - Release notes snapshotting per commit
 */
object ReproducibleDocsProject : Project({
    description = "Automated documentation pipeline with byte-for-byte reproducible builds"

    // VCS Root configuration
    vcsRoot(DocsVcsRoot)

    // Build configurations
    buildType(DocsBuild)

    // Project parameters (can be overridden per build)
    params {
        // Marketing website URL for release notes
        param("env.MARKETING_URL", "https://example.com/release-notes.txt")
    }
})

/**
 * Git VCS Root for the documentation repository.
 * 
 * Configure this to point to your actual repository.
 * The commit hash from this VCS root is used for:
 * - Release notes caching (snapshot per commit)
 * - Build artifact identification
 */
object DocsVcsRoot : GitVcsRoot({
    id("DocsRepository")
    name = "Documentation Repository"
    url = "https://github.com/yazdipour/jtb-task.git"
    branch = "refs/heads/master"
    // Branch specification for builds
    branchSpec = """
        +:refs/heads/*
        +:refs/tags/*
    """.trimIndent()
    
    // Checkout settings
    checkoutPolicy = GitVcsRoot.AgentCheckoutPolicy.USE_MIRRORS
    
    // Authentication (configure as needed)
    authMethod = anonymous()
})
