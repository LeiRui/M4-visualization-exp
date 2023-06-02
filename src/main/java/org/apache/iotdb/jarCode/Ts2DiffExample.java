package org.apache.iotdb.jarCode;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.io.PrintWriter;
import org.apache.iotdb.tsfile.encoding.encoder.Encoder;
import org.apache.iotdb.tsfile.file.metadata.enums.TSDataType;
import org.apache.iotdb.tsfile.utils.PublicBAOS;

public class Ts2DiffExample {

  public static void main(String[] args) throws IOException {
    PrintWriter printWriter = new PrintWriter("blockSizeExp.csv");
    printWriter.println("blockSize,average bytes per value");
    for (int blockSize = 10; blockSize <= 1500; blockSize += 10) {
      TSDataType dataType = TSDataType.INT64;
      Encoder timeEncoder = null;
      if (dataType == TSDataType.INT32) {
        timeEncoder = new MyDeltaBinaryEncoder.IntDeltaEncoder(blockSize);
      } else {
        timeEncoder = new MyDeltaBinaryEncoder.LongDeltaEncoder(blockSize);
      }
      PublicBAOS timeOut = new PublicBAOS();

      String f = "src/main/java/org/apache/iotdb/datasets/timedata.csv";
      String line;
      BufferedReader reader = new BufferedReader(new FileReader(f));
      int count = 0;
      while ((line = reader.readLine()) != null) {
        String[] split = line.split("\\s+");
        long timestamp = Long.parseLong(split[0]);
        timeEncoder.encode(timestamp, timeOut);
        count++;
      }
      timeEncoder.flush(timeOut);
      System.out.println("number of points=" + count);
      System.out.println("bytes in total=" + timeOut.size());
      System.out.println("bytes per timestamp=" + timeOut.size() * 1.0 / count);
      printWriter.println(blockSize + "," + timeOut.size() * 1.0 / count);
    }
    printWriter.close();
  }
}
