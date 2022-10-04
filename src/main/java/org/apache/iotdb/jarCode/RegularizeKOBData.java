package org.apache.iotdb.jarCode;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

public class RegularizeKOBData {

  // turn ms to s
  public static void main(String[] args) throws IOException {
    String inPath = "D:\\github\\m4-lsm\\M4-visualization-exp\\src\\main\\java\\org\\apache\\iotdb\\datasets\\KOB.csv";
    String outPath = "D:\\github\\m4-lsm\\M4-visualization-exp\\src\\main\\java\\org\\apache\\iotdb\\datasets\\KOB_2.csv";

    FileWriter fileWriter = new FileWriter(outPath);
    PrintWriter printWriter = new PrintWriter(fileWriter);

    File f = new File(inPath);
    String line;
    BufferedReader reader = new BufferedReader(new FileReader(f));
    int cnt = 0;
    long lastTimestamp = -1;
    while ((line = reader.readLine()) != null) {
      String[] split = line.split(",");
      long timestamp = Long.parseLong(split[0]); // ms
      // turn ms to s
      long tmp = (long) Math.floor(timestamp / 1000.0);
      timestamp = tmp * 1000; // s

      long value = Long.parseLong(split[1]);
      if (timestamp > lastTimestamp) {
        cnt++;
        lastTimestamp = timestamp;
        printWriter.print(timestamp);
        printWriter.print(",");
        printWriter.print(value);
        printWriter.println();
      }
    }
    reader.close();
    printWriter.close();
    System.out.println("write " + cnt + " points");
  }

}
