import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class TestPostgresConnection {
    public static void main(String[] args) {
        String url = "jdbc:postgresql://localhost:5433/catalog_db";
        String user = "postgres";
        String password = "postgres";

        try {
            Class.forName("org.postgresql.Driver");
            System.out.println("✅ Driver PostgreSQL cargado");

            Connection conn = DriverManager.getConnection(url, user, password);
            System.out.println("✅ CONEXIÓN EXITOSA a PostgreSQL");

            Statement stmt = conn.createStatement();
            ResultSet rs = stmt.executeQuery("SELECT current_database(), current_user, version()");

            if (rs.next()) {
                System.out.println("Database: " + rs.getString(1));
                System.out.println("User: " + rs.getString(2));
                System.out.println("Version: " + rs.getString(3));
            }

            rs.close();
            stmt.close();
            conn.close();
            System.out.println("✅ Test completado correctamente");

        } catch (Exception e) {
            System.err.println("❌ ERROR: " + e.getMessage());
            e.printStackTrace();
        }
    }
}

