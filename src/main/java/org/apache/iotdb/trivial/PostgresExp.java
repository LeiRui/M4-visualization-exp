package org.apache.iotdb.trivial;

import java.io.BufferedReader;
import java.io.FileReader;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class PostgresExp {

  private static Logger logger = LoggerFactory.getLogger(PostgresExp.class);
  private static final String defaultDatabase = "postgres";
  private static final String POSTGRESQL_JDBC_NAME = "org.postgresql.Driver";
  private static final String POSTGRESQL_URL = "jdbc:postgresql://%s:%s/%s";

  private static String TIMESCALEDB_HOST = "127.0.0.1";
  private static int TIMESCALEDB_PORT = 5432;
  private static String TIMESCALEDB_USERNAME = "postgres";
  private static String TIMESCALEDB_PASSWORD = "123";
  private static long TIMESCALEDB_CHUNK_TIME_INTERVAL = 604800000000L;
  private static String TIMESCALEDB_DATABASE = "mydb1";
  private static int TIMESCALEDB_QUERY_FETCH_SIZE = 5000;

  public static void main(String[] args) {
    String mode = args[0];
    if (mode.equals("w")) {
      writeData();
    } else if (mode.equals("r")) {
      queryData();
    } else {
      System.out.println("only accept 'w' or 'r'");
    }
  }

  private static void writeData() {
    String rawData = "D:\\3\\M4-visualization-exp\\src\\main\\java\\org\\apache\\iotdb\\datasets\\BallSpeed.csv";
    boolean hasHeader = false;

    try {
      // 创建数据库
      Class.forName(POSTGRESQL_JDBC_NAME);
      String defaultUrl = String
          .format(POSTGRESQL_URL, TIMESCALEDB_HOST, TIMESCALEDB_PORT, defaultDatabase);
      logger.info("connecting url: " + defaultUrl);
      Connection connection = DriverManager
          .getConnection(defaultUrl, TIMESCALEDB_USERNAME, TIMESCALEDB_PASSWORD);
      Statement statement = connection.createStatement();
      statement.execute(String.format("DROP DATABASE IF EXISTS %s;", TIMESCALEDB_DATABASE));
      logger.info(
          "Done: " + String.format("DROP DATABASE IF EXISTS %s;", TIMESCALEDB_DATABASE));
      statement.execute(String.format("CREATE database %s;", TIMESCALEDB_DATABASE));
      statement.close();
      logger.info("Done: " + String.format("CREATE database %s;", TIMESCALEDB_DATABASE));

      // 注册表结构
      String url = String
          .format(POSTGRESQL_URL, TIMESCALEDB_HOST, TIMESCALEDB_PORT, TIMESCALEDB_DATABASE);
      logger.info("connecting url: " + url);
      connection = DriverManager.getConnection(url, TIMESCALEDB_USERNAME, TIMESCALEDB_PASSWORD);
      statement = connection.createStatement();
      String createSQL = "CREATE TABLE mytable(time BIGINT NOT NULL, myts DOUBLE PRECISION NULL);"; // TODO check
      logger.info("CreateTableSQL Statement:  {}", createSQL);
      statement.execute(createSQL);

      // 写数据
      BufferedReader reader = new BufferedReader(new FileReader(rawData));
      if (hasHeader) {
        reader.readLine();
      }
      String line;
      while ((line = reader.readLine()) != null) {
        String[] splits = line.split(",");
        long timestamp = Long.parseLong(splits[0]);
        long value = Long.parseLong(splits[1]); // TODO check data type
        String sql = getInsertSql(timestamp, value);
        statement.addBatch(sql);
//        logger.debug(sql);
      }
      statement.executeBatch();

      statement.close();
      connection.close();
    } catch (Exception e) {
      logger.error("Initialize TimescaleDB failed because ", e);
    }
  }

  /**
   * eg.
   *
   * <p>INSERT INTO conditions(time, group, device, s_0, s_1) VALUES (1535558400000, 'group_0',
   * 'd_0', 70.0, 50.0);
   */
  private static String getInsertSql(long timestamp, Object value) {
    return "insert into mytable(time,myts) values(" // TODO check
        + timestamp + "," + value + ");";
  }

  public static void queryData() {
    // select time,myts from mytable

  }

}
