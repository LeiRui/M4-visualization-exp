package org.apache.iotdb.jarCode;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.PrintWriter;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.DoubleSummaryStatistics;
import java.util.List;
import java.util.LongSummaryStatistics;

public class GenerateZhongcheDataset {

  public static void main(String[] args) throws Exception {
    DateFormat dateFormat = new SimpleDateFormat(
        "yyyy-MM-dd'T'HH:mm:ss.SSS"); // 2020-06-09T23:51:07.194+08:00

    String dataDir = args[0]; // E.g., /disk/zc_csv
    String targetSensorName = args[1]; // E.g., ZT765, ZT17

    PrintWriter writer = new PrintWriter(targetSensorName + ".csv");
    writer.println("Time,root.group_69.1701." + targetSensorName); // header

    // iteratively get all files under dataDir
    List<File> res = listAllFiles(dataDir, new ArrayList<>());

    // extract the column with the targetSensorName, and attach them together
    long t1 = -1;
    long t2 = -1;
    long delta = -1;
    long tmax = -1;
    long lastTimestamp = -1;
    List<Long> lastTimestamps = new ArrayList<>();
    for (File f : res) {
      BufferedReader reader = new BufferedReader(new FileReader(f));
      String line;
      line = reader.readLine(); // read header
      String[] splits = line.split(",");
      // get the index of the targetSensorName
      int index = 0;
      for (int i = 0; i < splits.length; i++) {
        if (splits[i].contains(targetSensorName)) {
          index = i;
          break; // assume only one series contains the sensor name per file
        }
      }
      long ta = -1;
      tmax = lastTimestamp;
      lastTimestamps.add(tmax);
      while ((line = reader.readLine()) != null) {
        splits = line.split(",");

        if (splits[index].toLowerCase().equals("null")) {
          continue;
        }
        double value = Double.parseDouble(splits[index]);

        long timestamp;
        try {
          timestamp = dateFormat.parse(splits[0]).getTime();
        } catch (ParseException e) {
          timestamp = Long.parseLong(splits[0]);
        }

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
          writer.print(timestamp);
          writer.print(",");
          writer.print(value);
          writer.println();
          lastTimestamp = timestamp;
        } else {
          long newTimestamp = timestamp + (tmax + delta - ta);
          writer.print(newTimestamp);
          writer.print(",");
          writer.print(value);
          writer.println();
          lastTimestamp = newTimestamp;
        }
      }
      reader.close();
    }
    writer.close();
    System.out.println(lastTimestamps);

    // 检查确认 check the Monotonicity of timestamps
    BufferedReader reader = new BufferedReader(new FileReader(targetSensorName + ".csv"));
    reader.readLine(); // skip header
    long previousTimestamp = -1;
    List<Long> deltas = new ArrayList<>();
    List<Float> values = new ArrayList<>();
    String line;
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

  public static List<File> listAllFiles(String path, List<File> fileList) {

    File root = new File(path);
    File[] list = root.listFiles();

    if (list != null) {  // In case of access error, list is null
      for (File f : list) {
        if (f.isDirectory()) {
          fileList = listAllFiles(f.getAbsolutePath(), fileList);
        } else {
          fileList.add(f.getAbsoluteFile());
        }
      }
    }
    return fileList;
  }
}
