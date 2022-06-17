package org.apache.iotdb.jarCode;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.DoubleSummaryStatistics;
import java.util.List;
import java.util.LongSummaryStatistics;

public class GenerateYanchangDataset {

  public static void main(String[] args) throws Exception {
    // 删掉dump13.csv里的坏点
    String f1 = "D:\\3\\m4\\dump13.csv";
    String f2 = "D:\\3\\m4\\dump13_new.csv";
    PrintWriter writer = new PrintWriter(f2);
    BufferedReader reader = new BufferedReader(new FileReader(f1));
    String line;
    line = reader.readLine(); // skip header
    writer.println(line);
    while ((line = reader.readLine()) != null) {
      String[] splits = line.split(",");
      long timestamp = Long.parseLong(splits[0]);
      float value = Float.parseFloat(splits[1]);
      if (timestamp < 1600827686005L) {
        writer.print(timestamp);
        writer.print(",");
        writer.print(value);
        writer.println();
      }
    }
    writer.close();
    reader.close();

    // 拼接序列
    String fileDir = "D:\\3\\m4";
    String outFile = "yanchang.csv";
    PrintWriter printWriter = new PrintWriter(outFile);
    printWriter.println("Time,root.T000100010002.14020.TInternalStop"); // header

    File dir = new File(fileDir);
    File[] directoryListing = dir.listFiles();
    long t1 = -1;
    long t2 = -1;
    long delta = -1;
    long tmax = -1;
    long lastTimestamp = -1;
    List<Long> lastTimestamps = new ArrayList<>();
    if (directoryListing != null) {
      for (File f : directoryListing) {
        if (f.getAbsolutePath().equals(f1)) { // skip this file
          continue;
        }
        System.out.println(f);
        long ta = -1;
        tmax = lastTimestamp;
        lastTimestamps.add(tmax);
        reader = new BufferedReader(new FileReader(f));
        reader.readLine(); // skip header
        int cnt = 0;
        while ((line = reader.readLine()) != null) {
          String[] splits = line.split(",");
          long timestamp = Long.parseLong(splits[0]);
          float value = Float.parseFloat(splits[1]);

          if (t1 < 0) {
            t1 = timestamp; // the global first timestamp
          } else if (t2 < 0) {
            t2 = timestamp; // the global second timestamp
          } else if (delta < 0) {
            delta = t2 - t1;
          }

          if (ta < 0) {
            ta = timestamp; // the local first timestamp
          }

          if (tmax < 0) { // the first file does not need shifting timestamps
            printWriter.println(line);
            lastTimestamp = timestamp;
          } else {
            long newTimestamp = timestamp + (tmax + delta - ta);
//            long newTimestamp = timestamp + (tmax + delta - ta) + 100000000; // TODO tmp for debug
            printWriter.print(newTimestamp);
            printWriter.print(",");
            printWriter.print(value);
            printWriter.println();
            lastTimestamp = newTimestamp;
          }
        }
        reader.close();
      }
    }
    printWriter.close();
    System.out.println(lastTimestamps);

    // 检查确认 check the Monotonicity of timestamps
    reader = new BufferedReader(new FileReader(outFile));
    reader.readLine(); // skip header
    long previousTimestamp = -1;
    List<Long> deltas = new ArrayList<>();
    List<Float> values = new ArrayList<>();
    while ((line = reader.readLine()) != null) {
      String[] splits = line.split(",");
      long timestamp = Long.parseLong(splits[0]);
      float value = Float.parseFloat(splits[1]);
      if (timestamp <= previousTimestamp) {
        System.out.println("Timestamps are not mononically increasing!");
        System.out.println(timestamp + "<=" + previousTimestamp);
      }
      if (previousTimestamp > 0) {
        values.add(value);

        long tmp = timestamp - previousTimestamp;
        deltas.add(tmp);
        if (tmp == 1 || tmp == 1021502636) {
          System.out.println(tmp + "ms:" + previousTimestamp + "," + timestamp);
        }
      }
      previousTimestamp = timestamp;
    }
    reader.close();

    LongSummaryStatistics stats = deltas.stream()
        .mapToLong((x) -> x)
        .summaryStatistics();
    System.out.println(stats);
    DoubleSummaryStatistics stats2 = values.stream()
        .mapToDouble((x) -> x)
        .summaryStatistics();
    System.out.println(stats2);
  }

  // 扩展500倍到1亿个点

}
