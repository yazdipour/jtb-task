package com.example;

/**
 * Main application class.
 */
public class App {
    
    /**
     * Returns a greeting message.
     * @return greeting string
     */
    public static String getGreeting() {
        return "Hello World!";
    }

    /**
     * Main method to run the application.
     * @param args command line arguments
     */
    public static void main(String[] args) {
        System.out.println(getGreeting());
    }
}
