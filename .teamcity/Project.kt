/*
 * TeamCity Project Configuration
 * 
 * Defines the main project structure for the Reproducible Documentation Build.
 */

package _Self

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

    // Project parameters
    params {
        // Marketing website URL (can be overridden per build)
        param("env.MARKETING_URL", "https://example.com")
        text("env.MARKETING_URL", "https://example.com", 
             label = "Marketing Website URL",
             description = "URL to fetch release notes from. The build will gracefully handle failures.",
             allowEmpty = false)
        
        // Fixed timestamp for reproducibility
        param("env.BUILD_TIMESTAMP", "1980-01-01T00:00:00Z")
        
        // Docker image tag
        param("docker.image.tag", "docs-builder:latest")
        
        // Release notes cache directory (relative to agent home)
        param("env.RELEASE_NOTES_CACHE_DIR", "%teamcity.agent.home.dir%/.cache/jtb-task/release-notes")
    }
    
    // Cleanup settings to prevent disk space issues
    cleanup {
        // Keep artifacts for 30 days
        artifacts(days = 30)
        
        // Keep build history for 90 days
        history(days = 90)
        
        // Prevent accidental deletion of builds with specific tags
        preventDependencyCleanup = true
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
