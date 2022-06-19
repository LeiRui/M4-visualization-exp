package org.apache.iotdb.jarCode;

import java.io.IOException;
import org.apache.iotdb.rpc.IoTDBConnectionException;
import org.apache.iotdb.rpc.StatementExecutionException;
import org.apache.iotdb.session.Session;
import org.apache.iotdb.session.SessionDataSet;
import org.apache.iotdb.session.SessionDataSet.DataIterator;
import org.apache.thrift.TException;

public class QueryData {

  // * (1) min_time(%s), max_time(%s), first_value(%s), last_value(%s), min_value(%s), max_value(%s)
  //       => Don't change the sequence of the above six aggregates!
  // * (2) group by ([tqs,tqe),IntervalLength) => Make sure (tqe-tqs) is divisible by
  // IntervalLength!
  // * (3) NOTE the time unit of interval. Update for different datasets!
  private static final String queryFormat =
      "select min_time(%s), max_time(%s), first_value(%s), last_value(%s), min_value(%s), max_value(%s) "
          + "from %s "
          + "group by ([%d, %d), %d%s)"; // note the time precision unit is also parameterized

  private static final String queryFormat_UDF =
      "select M4(%1$s,'tqs'='%3$d','tqe'='%4$d','w'='%5$d') from %2$s where time>=%3$d and time<%4$d";

  public static Session session;

  // Usage: java -jar QueryData-0.12.4.jar device measurement timestamp_precision dataMinTime dataMaxTime range w approach
  public static void main(String[] args)
      throws IoTDBConnectionException, StatementExecutionException, TException, IOException {
    String device = args[0];
    System.out.println("[QueryData] device=" + device);
    String measurement = args[1];
    System.out.println("[QueryData] measurement=" + measurement);

    String timestamp_precision = args[2]; // ns, us, ms
    timestamp_precision = timestamp_precision.toLowerCase();
    System.out.println("[QueryData] timestamp_precision=" + timestamp_precision);
    if (!timestamp_precision.toLowerCase().equals("ns") && !timestamp_precision.toLowerCase()
        .equals("us") && !timestamp_precision.toLowerCase().equals("ms")) {
      throw new IOException("timestamp_precision only accepts ns,us,ms.");
    }

    // used to bound tqs random position
    long dataMinTime = Long.parseLong(args[3]);
    System.out.println("[QueryData] dataMinTime=" + dataMinTime);
    long dataMaxTime = Long.parseLong(args[4]);
    System.out.println("[QueryData] dataMaxTime=" + dataMaxTime);

    // [tqs,tqe) range length, i.e., tqe-tqs
    long range = Long.parseLong(args[5]);
    System.out.println("[QueryData] query range=" + range);
    // w数量
    int w = Integer.parseInt(args[6]);
    System.out.println("[QueryData] w=" + w);

    // 选择查询执行算法: 1: MAC, 2: MOC, 3: CPV
    String approach = args[7].toLowerCase();
    if (!approach.equals("mac") && !approach.equals("moc") && !approach.equals("cpv")) {
      throw new IOException("Approach wrong. Only accepts mac/moc/cpv");
    }
    System.out.println("[QueryData] approach=" + approach);
    if (approach.equals("moc")) {
      System.out.println(
          "MAKE SURE you have set the enable_CPV as false in `iotdb-engine.properties` for MOC!");
    } else if (approach.equals("cpv")) {
      System.out.println(
          "MAKE SURE you have set the enable_CPV as true in `iotdb-engine.properties` for CPV!");
    }

    long minTime;
    long maxTime;
    long interval;
    if (range >= (dataMaxTime - dataMinTime)) {
      minTime = dataMinTime;
      interval = (long) Math.ceil((double) (dataMaxTime - dataMinTime) / w);
    } else {
      // randomize between [dataMinTime, dataMaxTime-range]
      minTime =
          (long) Math.ceil(dataMinTime + Math.random() * (dataMaxTime - range - dataMinTime + 1));
      interval = (long) Math.ceil((double) range / w);
    }
    maxTime = minTime + interval * w;

    session = new Session("127.0.0.1", 6667, "root", "root");
    session.open(false);

    // Set it big to avoid multiple fetch, which is very important.
    // Because the IOMonitor implemented in IoTDB does not cover the fetchResults operator yet.
    // As M4 already does data reduction, so even the w is very big such as 8000, the returned
    // query result size is no more than 8000*4=32000.
    session.setFetchSize(1000000);

    String sql;
    if (approach.equals("mac")) {
      // MAC UDF
      sql =
          String.format(queryFormat_UDF, measurement, device, minTime, maxTime, w); // MAC
    } else {
      // MOC and CPV sql use the same sql queryFormat.
      sql =
          String.format(
              queryFormat,
              measurement,
              measurement,
              measurement,
              measurement,
              measurement,
              measurement,
              device,
              minTime,
              maxTime,
              interval,
              timestamp_precision);  // note the time precision unit
    }
    System.out.println("[QueryData] sql=" + sql);

    long c = 0;
    SessionDataSet dataSet = session.executeQueryStatement(sql);
    DataIterator ite = dataSet.iterator();
    while (ite.next()) { // this way avoid constructing rowRecord
      c++;
    }
//    session.executeNonQueryStatement("clear cache");
    dataSet = session.executeFinish();
    String info = dataSet.getFinishResult();
    System.out.println(
        info); // don't add more string to this output, as ProcessResult code depends on this.
    System.out.println("[QueryData] query result line number=" + c);
    dataSet.closeOperationHandle();
    session.close();
  }
}
