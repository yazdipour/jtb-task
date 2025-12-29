/*
 * TeamCity Kotlin DSL Settings
 * 
 * This is the entry point for TeamCity's Kotlin DSL configuration.
 * It imports and initializes the project structure defined in separate files.
 * 
 * For more information, see:
 * https://www.jetbrains.com/help/teamcity/kotlin-dsl.html
 */

package _Self

import jetbrains.buildServer.configs.kotlin.*

version = "2025.11"

project(ReproducibleDocsProject)