package org.apache.iotdb.jarCode;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.text.DecimalFormat;
import java.util.Map;
import java.util.TreeMap;

public class GetRegularTimeIntervalStatistic {

  public static void main(String[] args) throws IOException {
    String inPath = "D:\\github\\m4-lsm\\M4-visualization-exp\\src\\main\\java\\org\\apache\\iotdb\\datasets\\MF03_3.csv";
    String outPath = "D:\\github\\m4-lsm\\M4-visualization-exp\\src\\main\\java\\org\\apache\\iotdb\\datasets\\MF03_3_timeIntervalCountFreq.csv";

    File f = new File(inPath);
    String line;
    BufferedReader reader = new BufferedReader(new FileReader(f));
    long lastTimestamp = -1;
    Map<Long, Integer> countFreq = new TreeMap<>();
    long totalCnt = 0;
    while ((line = reader.readLine()) != null) { // 没有header
      String[] split = line.split(",");
      long timestamp = Long.parseLong(split[0]);
      if (lastTimestamp == -1) {
        lastTimestamp = timestamp;
      } else {
        totalCnt++;
        long interval = timestamp - lastTimestamp;
        lastTimestamp = timestamp;
        if (!countFreq.containsKey(interval)) {
          countFreq.put(interval, 1);
        } else {
          countFreq.put(interval, countFreq.get(interval) + 1);
        }
      }
    }
    reader.close();
    System.out.println("The frequency of each time interval is as follows.");
    System.out.println(countFreq);

    FileWriter fileWriter = new FileWriter(outPath);
    PrintWriter printWriter = new PrintWriter(fileWriter);
    int maxCnt = -1; // find the time interval that appears the most frequent as the regular time interval
    long regularTimeInterval = -1;
    DecimalFormat df = new DecimalFormat("0.00");
    for (Map.Entry<Long, Integer> entry : countFreq.entrySet()) {
      long timeInterval = entry.getKey();
      int cnt = entry.getValue();
      printWriter.print(timeInterval);
      printWriter.print(",");
      printWriter.print(cnt);
      printWriter.print(",");
      printWriter.println(df.format(cnt * 1.0 / totalCnt * 100));
      if (cnt > maxCnt) {
        maxCnt = cnt;
        regularTimeInterval = timeInterval;
      }
    }
    System.out.println("The regular time interval is: " + regularTimeInterval + ", appear " + maxCnt
        + " times out of the total " + totalCnt + " intervals (" + df
        .format(maxCnt * 1.0 / totalCnt * 100) + "%).");
    printWriter.close();

  }
}
