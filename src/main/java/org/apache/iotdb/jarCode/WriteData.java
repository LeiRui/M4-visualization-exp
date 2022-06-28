package org.apache.iotdb.jarCode;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.apache.iotdb.rpc.IoTDBConnectionException;
import org.apache.iotdb.rpc.StatementExecutionException;
import org.apache.iotdb.session.Session;
import org.apache.iotdb.tsfile.file.metadata.enums.TSDataType;
import org.apache.iotdb.tsfile.file.metadata.enums.TSEncoding;
import org.apache.iotdb.tsfile.write.record.Tablet;
import org.apache.iotdb.tsfile.write.schema.MeasurementSchema;

public class WriteData {

  /**
   * Before writing data, make sure check the server parameter configurations.
   */
  // Usage: java -jar WriteData-0.12.4.jar device measurement dataType timestamp_precision total_time_length total_point_number iotdb_chunk_point_size filePath deleteFreq deleteLen timeIdx valueIdx
  public static void main(String[] args)
      throws IoTDBConnectionException, StatementExecutionException, IOException {
    String device = args[0];
    System.out.println("[WriteData] device=" + device);
    String measurement = args[1];
    System.out.println("[WriteData] measurement=" + measurement);
    String dataType = args[2]; // long or double
    System.out.println("[WriteData] dataType=" + dataType);
    TSDataType tsDataType;
    if (dataType.toLowerCase().equals("long")) {
      tsDataType = TSDataType.INT64;
    } else if (dataType.toLowerCase().equals("double")) {
      tsDataType = TSDataType.DOUBLE;
    } else {
      throw new IOException("Data type only accepts long or double.");
    }

    String timestamp_precision = args[3]; // ns, us, ms
    System.out.println("[WriteData] timestamp_precision=" + timestamp_precision);
    if (!timestamp_precision.toLowerCase().equals("ns") && !timestamp_precision.toLowerCase()
        .equals("us") && !timestamp_precision.toLowerCase().equals("ms")) {
      throw new IOException("timestamp_precision only accepts ns,us,ms.");
    }

    long total_time_length = Long.parseLong(args[4]); // in corresponding timestamp precision
    System.out.println("[WriteData] total_time_length=" + total_time_length);
    int total_point_number = Integer.parseInt(args[5]);
    System.out.println("[WriteData] total_point_number=" + total_point_number);
    int iotdb_chunk_point_size = Integer.parseInt(args[6]);
    System.out.println("[WriteData] iotdb_chunk_point_size=" + iotdb_chunk_point_size);

    long chunkAvgTimeLen =
        (long) Math
            .ceil(total_time_length / Math.ceil(total_point_number * 1.0 / iotdb_chunk_point_size));
    System.out.println("[WriteData] derived estimated chunkAvgTimeLen =" + chunkAvgTimeLen);

    // 乱序数据源
    String filePath = args[7];
    System.out.println("[WriteData] filePath=" + filePath);
    // delete percentage
    int deletePercentage = Integer.parseInt(args[8]); // 0 means no deletes. 0-100
    System.out.println("[WriteData] deletePercentage=" + deletePercentage);
    // 每次删除的时间长度，用chunkAvgTimeLen的百分比表示
    int deleteLenPercentage = Integer.parseInt(args[9]); // 0-100
    System.out.println("[WriteData] deleteLenPercentage=" + deleteLenPercentage);
    // 时间戳idx，从0开始
    int timeIdx = Integer.parseInt(args[10]);
    System.out.println("[WriteData] timeIdx=" + timeIdx);
    // 值idx，从0开始
    int valueIdx = Integer.parseInt(args[11]);
    System.out.println("[WriteData] valueIdx=" + valueIdx);

    // 控制insertTablet的tablet内行数
    int fixedBatchInsertSize = Integer.parseInt(args[12]);
    System.out.println("[WriteData] fixedBatchInsertSize=" + fixedBatchInsertSize);

    if (deletePercentage < 0 || deletePercentage > 100) {
      throw new IOException("WRONG deletePercentage!");
    }
    if (deleteLenPercentage < 0 || deleteLenPercentage > 100) {
      throw new IOException("WRONG deleteLenPercentage!");
    }

    int deletePeriod =
        (int) Math.floor(100 * 1.0 / deletePercentage
            * iotdb_chunk_point_size); // use period to control percentage
    long deleteLen = (long) Math.floor(chunkAvgTimeLen * deleteLenPercentage * 1.0 / 100);

    List<String> deletePaths = new ArrayList<>();
    deletePaths.add(device + "." + measurement);

    Session session = new Session("127.0.0.1", 6667, "root", "root");
    session.open(false);

    // this is to make all following inserts unseq chunks
    if (timestamp_precision.toLowerCase().equals("ns")) {
      session.insertRecord(
          device,
          1644181628000000000L, // ns
          // NOTE UPDATE TIME DATATYPE! [[update]]. DONT USE System.nanoTime()!
          Collections.singletonList(measurement),
          Collections.singletonList(tsDataType), // NOTE UPDATE VALUE DATATYPE!
          parseValue("0", tsDataType)); // NOTE UPDATE VALUE DATATYPE!
    } else if (timestamp_precision.toLowerCase().equals("us")) {
      session.insertRecord(
          device,
          1644181628000000L, // us
          // NOTE UPDATE TIME DATATYPE! [[update]]. DONT USE System.nanoTime()!
          Collections.singletonList(measurement),
          Collections.singletonList(tsDataType), // NOTE UPDATE VALUE DATATYPE!
          parseValue("0", tsDataType)); // NOTE UPDATE VALUE DATATYPE!
    } else { // ms
      session.insertRecord(
          device,
          1644181628000L, // ms
          // NOTE UPDATE TIME DATATYPE! [[update]]. DONT USE System.nanoTime()!
          Collections.singletonList(measurement),
          Collections.singletonList(tsDataType), // NOTE UPDATE VALUE DATATYPE!
          parseValue("0", tsDataType)); // NOTE UPDATE VALUE DATATYPE!
    }
    session.executeNonQueryStatement("flush");

    File f = new File(filePath);
    String line = null;
    BufferedReader reader = new BufferedReader(new FileReader(f));

    long lastDeleteMinTime = Long.MAX_VALUE;
    long lastDeleteMaxTime = Long.MIN_VALUE;
    int cnt4Delete = 0;  // count the number of inserts between two deletes, used to satisfy the specified delete percentage
    List<Long> deleteStartTimes = new ArrayList<>();
    List<Long> deleteEndTimes = new ArrayList<>();

    int cnt4BatchInsert = 0;
    List<Long> timestamps = new ArrayList<>();
    List<Object> values = new ArrayList<>();

    while ((line = reader.readLine()) != null) {
      String[] split = line.split(",");
      long timestamp = Long.parseLong(split[timeIdx]);
      Object value = parseValue(split[valueIdx], tsDataType);

      // for inserts
      cnt4BatchInsert++;
      timestamps.add(timestamp);
      values.add(value);
      if (cnt4BatchInsert >= fixedBatchInsertSize) {
        // insert Tablet
        Tablet tablet = convertToTablet(timestamps, values, device, measurement, tsDataType);
        session.insertTablet(tablet);
        tablet.reset();
        timestamps = new ArrayList<>();
        values = new ArrayList<>();
        cnt4BatchInsert = 0;
      }

      // for deletes
      cnt4Delete++;
      if (timestamp > lastDeleteMaxTime) {
        lastDeleteMaxTime = timestamp;
      }
      if (timestamp < lastDeleteMinTime) {
        lastDeleteMinTime = timestamp;
      }
      if (deletePercentage != 0) {
        if (cnt4Delete >= deletePeriod) {
          cnt4Delete = 0;
          // randomize deleteStartTime in [lastMinTime, max(lastMaxTime-deleteLen,lastMinTime+1)]
          long rightBound = Math.max(lastDeleteMaxTime - deleteLen, lastDeleteMinTime + 1);
          long deleteStartTime =
              (long)
                  Math.ceil(
                      lastDeleteMinTime + Math.random() * (rightBound - lastDeleteMinTime + 1));
          long deleteEndTime = deleteStartTime + deleteLen - 1;

          session.deleteData(deletePaths, deleteStartTime, deleteEndTime);
//          deleteStartTimes.add(deleteStartTime);
//          deleteEndTimes.add(deleteEndTime);
          System.out.println("[[[[delete]]]]]" + deleteStartTime + "," + deleteEndTime);

          lastDeleteMinTime = Long.MAX_VALUE;
          lastDeleteMaxTime = Long.MIN_VALUE;
        }
      }
    }

//    for (int i = 0; i < deleteStartTimes.size(); i++) {
//      session.deleteData(deletePaths, deleteStartTimes.get(i), deleteEndTimes.get(i));
//    }

    session.executeNonQueryStatement("flush");
    session.close();
  }

  public static Object parseValue(String value, TSDataType tsDataType) throws IOException {
    if (tsDataType == TSDataType.INT64) {
      return Long.parseLong(value);
    } else if (tsDataType == TSDataType.DOUBLE) {
      return Double.parseDouble(value);
    } else {
      throw new IOException("data type wrong");
    }
  }

  public static Tablet convertToTablet(List<Long> timestamps, List<Object> values, String device,
      String measurement, TSDataType tsDataType) throws IOException {
    List<MeasurementSchema> schemaList = new ArrayList<>();
    schemaList.add(new MeasurementSchema(measurement, tsDataType, toTsEncoding(tsDataType)));
    Tablet tablet = new Tablet(device, schemaList, timestamps.size());
    for (int i = 0; i < timestamps.size(); i++) {
      int rowIndex = tablet.rowSize++;
      tablet.addTimestamp(rowIndex, timestamps.get(i));
      tablet.addValue(measurement, rowIndex, values.get(i));
    }
    return tablet;
  }

  private static TSEncoding toTsEncoding(TSDataType tsDataType) throws IOException {
    if (tsDataType == TSDataType.INT64) {
      return TSEncoding.RLE;
    } else if (tsDataType == TSDataType.DOUBLE) {
      return TSEncoding.GORILLA;
    } else {
      throw new IOException("Data type only accepts long or double.");
    }
  }


}
