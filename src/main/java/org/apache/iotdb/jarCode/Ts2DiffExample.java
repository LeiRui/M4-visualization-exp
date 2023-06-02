package org.apache.iotdb.jarCode;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import org.apache.iotdb.tsfile.encoding.encoder.Encoder;
import org.apache.iotdb.tsfile.file.metadata.enums.TSDataType;
import org.apache.iotdb.tsfile.utils.PublicBAOS;

public class Ts2DiffExample {

  public static void main(String[] args) throws IOException {
    TSDataType dataType = TSDataType.INT64;
    Encoder timeEncoder = null;
    if (dataType == TSDataType.INT32) {
      timeEncoder = new MyDeltaBinaryEncoder.IntDeltaEncoder();
    } else {
      timeEncoder = new MyDeltaBinaryEncoder.LongDeltaEncoder();
    }
    PublicBAOS timeOut = new PublicBAOS();

    String f = "src/main/java/org/apache/iotdb/datasets/timedata.csv";
    String line;
    BufferedReader reader = new BufferedReader(new FileReader(f));
    while ((line = reader.readLine()) != null) {
      String[] split = line.split("\\s+");
      long timestamp = Long.parseLong(split[0]);
      timeEncoder.encode(timestamp,timeOut);
    }
    timeEncoder.flush(timeOut);
    System.out.println(timeOut.size());
  }
}
