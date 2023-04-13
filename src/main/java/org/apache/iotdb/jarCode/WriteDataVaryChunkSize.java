package org.apache.iotdb.jarCode;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.apache.iotdb.session.Session;
import org.apache.iotdb.tsfile.file.metadata.enums.TSDataType;
import org.apache.iotdb.tsfile.file.metadata.enums.TSEncoding;
import org.apache.iotdb.tsfile.write.record.Tablet;
import org.apache.iotdb.tsfile.write.schema.MeasurementSchema;

// write different sizes of chunks
public class WriteDataVaryChunkSize {

  /**
   * Before writing data, make sure check the server parameter configurations.
   */
  // Usage: java -jar WriteDataVaryChunkSize-0.12.4.jar
  //String device,
  //String measurement,
  //TSDataType tsDataType,
  //String timestamp_precision,
  //long queryStartTime,
  //long queryEndTime,
  //int iotdb_chunk_point_size,
  //String filePath,
  //int timeIdx,,
  //int valueIdx,
  //String valueEncoding,
  //int M
  public static void main(String[] args) throws Exception {
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

    long queryStartTime = Long.parseLong(args[4]);
    System.out.println("[WriteData] query start time=" + queryStartTime);
    long queryEndTime = Long.parseLong(args[5]);
    System.out.println("[WriteData] query end time=" + queryEndTime);

    int iotdb_chunk_point_size = Integer.parseInt(args[6]);
    System.out.println("[WriteData] iotdb_chunk_point_size=" + iotdb_chunk_point_size);

    // 乱序数据源
    String filePath = args[7];
    System.out.println("[WriteData] filePath=" + filePath);

    // 时间戳idx，从0开始
    int timeIdx = Integer.parseInt(args[8]);
    System.out.println("[WriteData] timeIdx=" + timeIdx);
    // 值idx，从0开始
    int valueIdx = Integer.parseInt(args[9]);
    System.out.println("[WriteData] valueIdx=" + valueIdx);
    // value encoder
    String valueEncoding = args[10]; // RLE, GORILLA, PLAIN
    System.out.println("[WriteData] valueEncoding=" + valueEncoding);

    // number of chunks in a tsfile
    int M = Integer.parseInt(args[11]);
    System.out.println("[WriteData] number of chunks in a TsFile=" + M);

    List<Long> minTimestamps = new ArrayList<>();
    List<Long> maxTimestamps = new ArrayList<>();
    getMinMaxTimeForEachChunk(minTimestamps, maxTimestamps, filePath, timeIdx, valueIdx,
        iotdb_chunk_point_size);

    writeData(device,
        measurement,
        tsDataType,
        timestamp_precision,
        queryStartTime,
        queryEndTime,
        iotdb_chunk_point_size,
        filePath,
        timeIdx,
        valueIdx,
        valueEncoding,
        M);
  }

  public static void getMinMaxTimeForEachChunk(List<Long> minTime, List<Long> maxTime,
      String filePath, int timeIdx, int valueIdx, int iotdb_chunk_point_size) throws IOException {
    try (BufferedReader reader = new BufferedReader(new FileReader(filePath))) {
      String line;
      while ((line = reader.readLine()) != null) {
        String[] split = line.split(",");
        long timestamp = Long.parseLong(split[timeIdx]);

      }
    }
  }

  public static void writeData(String device,
      String measurement,
      TSDataType tsDataType,
      String timestamp_precision,
      long queryStartTime,
      long queryEndTime,
      int iotdb_chunk_point_size,
      String filePath,
      int timeIdx,
      int valueIdx,
      String valueEncoding,
      int M) throws Exception {
    //"CREATE TIMESERIES root.vehicle.d0.s0 WITH DATATYPE=INT32, ENCODING=RLE"
    String createSql = String.format("CREATE TIMESERIES %s.%s WITH DATATYPE=%s, ENCODING=%s",
        device,
        measurement,
        tsDataType,
        valueEncoding
    );

    Session session = new Session("127.0.0.1", 6667, "root", "root");
    session.open(false);
    session.executeNonQueryStatement(createSql);

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

    List<MeasurementSchema> schemaList = new ArrayList<>();
    schemaList.add(
        new MeasurementSchema(measurement, tsDataType, TSEncoding.valueOf(valueEncoding)));
    Tablet tablet = new Tablet(device, schemaList, iotdb_chunk_point_size);
    long[] timestamps = tablet.timestamps;
    Object[] values = tablet.values;

    while ((line = reader.readLine()) != null) {
      String[] split = line.split(",");
      long timestamp = Long.parseLong(split[timeIdx]);

      int row = tablet.rowSize++;
      timestamps[row] = timestamp;
      switch (tsDataType) {
        case INT64:
          long long_value = Long.parseLong(split[valueIdx]); // get value from real data
          long[] long_sensor = (long[]) values[0];
          long_sensor[row] = long_value;
          break;
        case DOUBLE:
          double double_value = Double.parseDouble(split[valueIdx]); // get value from real data
          double[] double_sensor = (double[]) values[0];
          double_sensor[row] = double_value;
          break;
        default:
          throw new IOException("not supported data type!");
      }
      if (tablet.rowSize == tablet.getMaxRowNumber()) { // chunk point size
        session.insertTablet(tablet, false);
        tablet.reset();
      }
    }
    // flush the last Tablet
    if (tablet.rowSize != 0) {
      session.insertTablet(tablet, false);
      tablet.reset();
    }
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
}
