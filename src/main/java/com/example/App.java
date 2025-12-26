package com.example;

/**
 * Main application class demonstrating Javadoc generation for reproducible builds.
 * 
 * <p>This class serves as the entry point for the application and provides
 * examples of well-documented Java code that can be processed by the Javadoc tool.</p>
 * 
 * <h2>Reproducible Build Features</h2>
 * <ul>
 *   <li>Fixed timestamps in generated documentation</li>
 *   <li>Deterministic file ordering in archives</li>
 *   <li>Consistent output across different build environments</li>
 * </ul>
 * 
 * @author Documentation Team
 * @version 1.0.0
 * @since 1.0.0
 */
public class App {

    /**
     * Default application name used when no custom name is provided.
     */
    public static final String DEFAULT_NAME = "Reproducible Docs";

    /**
     * Current version of the application.
     * This value is used in documentation and build artifacts.
     */
    public static final String VERSION = "1.0.0";

    private final String name;

    /**
     * Constructs a new App instance with the default name.
     * 
     * <p>This constructor initializes the application using the
     * {@link #DEFAULT_NAME} constant.</p>
     */
    public App() {
        this(DEFAULT_NAME);
    }

    /**
     * Constructs a new App instance with a custom name.
     * 
     * @param name the name to use for this application instance;
     *             must not be {@code null} or empty
     * @throws IllegalArgumentException if name is null or empty
     */
    public App(String name) {
        if (name == null || name.trim().isEmpty()) {
            throw new IllegalArgumentException("Name must not be null or empty");
        }
        this.name = name;
    }

    /**
     * Returns the name of this application instance.
     * 
     * @return the application name, never {@code null}
     */
    public String getName() {
        return name;
    }

    /**
     * Generates a greeting message for the application.
     * 
     * <p>The greeting includes both the application name and version.</p>
     * 
     * <pre>{@code
     * App app = new App("MyApp");
     * String greeting = app.getGreeting();
     * // Returns: "Hello from MyApp (v1.0.0)!"
     * }</pre>
     * 
     * @return a formatted greeting string
     */
    public String getGreeting() {
        return String.format("Hello from %s (v%s)!", name, VERSION);
    }

    /**
     * Checks if this application instance is using the default name.
     * 
     * @return {@code true} if using the default name, {@code false} otherwise
     */
    public boolean isDefaultName() {
        return DEFAULT_NAME.equals(name);
    }

    /**
     * Returns build information for reproducibility verification.
     * 
     * <p>This method provides metadata that can be used to verify
     * that builds are reproducible across different environments.</p>
     * 
     * @return a string containing build metadata
     */
    public static String getBuildInfo() {
        return String.format(
            "Build Info: %s v%s | Java %s | %s",
            DEFAULT_NAME,
            VERSION,
            System.getProperty("java.version"),
            System.getProperty("os.name")
        );
    }

    /**
     * Main entry point for the application.
     * 
     * <p>When run, this method displays a greeting and build information
     * to demonstrate the application is working correctly.</p>
     * 
     * @param args command-line arguments (currently unused)
     */
    public static void main(String[] args) {
        App app = new App();
        System.out.println(app.getGreeting());
        System.out.println(getBuildInfo());
    }
}
