package org.apache.iotdb.jarCode;

import java.io.IOException;
import org.apache.iotdb.rpc.IoTDBConnectionException;
import org.apache.iotdb.rpc.StatementExecutionException;
import org.apache.iotdb.session.Session;
import org.apache.iotdb.session.SessionDataSet;
import org.apache.iotdb.session.SessionDataSet.DataIterator;
import org.apache.thrift.TException;

public class SimpleRawQuery {

  public static Session session;

  public static void main(String[] args)
      throws IoTDBConnectionException, StatementExecutionException, TException, IOException {
    String sql = args[0];

    session = new Session("127.0.0.1", 6667, "root", "root");
    session.open(false);

    // Set it big to avoid multiple fetch, which is very important.
    // Because the IOMonitor implemented in IoTDB does not cover the fetchResults operator yet.
    // As M4 already does data reduction, so even the w is very big such as 8000, the returned
    // query result size is no more than 8000*4=32000.
    session.setFetchSize(100000);

    long c = 0;
    long start = System.nanoTime();
    SessionDataSet dataSet = session.executeQueryStatement(sql);
    DataIterator ite = dataSet.iterator();
    while (ite.next()) { // this way avoid constructing rowRecord
      c++;
    }
    long duration = System.nanoTime() - start;
    dataSet = session.executeFinish();
    String info = dataSet.getFinishResult();
    System.out.println(info);
    System.out.println("[QueryData] query result line number=" + c);
    System.out.println("elapsedTime(ms)=" + duration * 1.0 / 1000000);
    dataSet.closeOperationHandle();
    session.close();
  }
}

