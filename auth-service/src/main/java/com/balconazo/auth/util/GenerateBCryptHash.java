package com.balconazo.auth.util;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/**
 * Utilidad para generar hash BCrypt de contraseñas
 * Ejecutar: mvn exec:java -Dexec.mainClass="com.balconazo.auth.util.GenerateBCryptHash"
 */
public class GenerateBCryptHash {

    public static void main(String[] args) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

        String plainPassword = "password123";
        String hash = encoder.encode(plainPassword);

        System.out.println("=".repeat(80));
        System.out.println("HASH BCRYPT GENERADO");
        System.out.println("=".repeat(80));
        System.out.println();
        System.out.println("Password: " + plainPassword);
        System.out.println();
        System.out.println("Hash BCrypt:");
        System.out.println(hash);
        System.out.println();
        System.out.println("=".repeat(80));
        System.out.println("SQL UPDATE:");
        System.out.println("=".repeat(80));
        System.out.println();
        System.out.println("UPDATE users SET password_hash = '" + hash + "' WHERE email = 'host1@balconazo.com';");
        System.out.println();

        // Verificar que el hash funciona
        boolean matches = encoder.matches(plainPassword, hash);
        System.out.println("Verificación: " + (matches ? "✅ CORRECTO" : "❌ ERROR"));
        System.out.println();
    }
}

