package com.example;

/**
 * Simple demo app for Javadoc generation.
 */
public class App {
    
    private final String name;

    public App() {
        this("Demo App");
    }

    public App(String name) {
        this.name = name;
    }

    /**
     * Returns a greeting message.
     * @return greeting string
     */
    public String getGreeting() {
        return "Hello from " + name + "!";
    }

    public static void main(String[] args) {
        App app = new App();
        System.out.println(app.getGreeting());
    }
}
