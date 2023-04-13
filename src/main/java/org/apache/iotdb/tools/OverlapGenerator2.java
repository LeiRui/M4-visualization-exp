package org.apache.iotdb.tools;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class OverlapGenerator2 {

  public static void main(String[] args) throws IOException {
    String dataType = args[0]; // long or double
    if (!dataType.toLowerCase().equals("long") && !dataType.toLowerCase().equals("double")) {
      throw new IOException("Data type only accepts long or double.");
    }
    dataType = dataType.toLowerCase();

    String inPath = args[1];
    String outPath = args[2];
    int timeIdx = Integer.parseInt(args[3]);
    int valueIdx = Integer.parseInt(args[4]);
    int pointNum = Integer.parseInt(args[5]);

    File f = new File(inPath);
    FileWriter fileWriter = new FileWriter(outPath);
    String line;
    BufferedReader reader = new BufferedReader(new FileReader(f));
    PrintWriter printWriter = new PrintWriter(fileWriter);
    List<Integer> idx = new ArrayList<>();
    for (int i = 0; i < pointNum; i++) {
      idx.add(i);
    }
    Collections.shuffle(idx);
    long[] timestampArray = new long[pointNum];
    Object[] valueArray = new Object[pointNum];
    int cnt = 0;
    while ((line = reader.readLine()) != null && cnt < pointNum) {
      String[] split = line.split(",");
      timestampArray[cnt] = Long.parseLong(split[timeIdx]); // time
      valueArray[cnt] = parseValue(split[valueIdx], dataType); // value
      cnt++;
    }
    for (int k : idx) {
      printWriter.print(timestampArray[k]);
      printWriter.print(",");
      printWriter.print(valueArray[k]);
      printWriter.println();
    }
    System.out.println(cnt);
    reader.close();
    printWriter.close();
  }

  public static Object parseValue(String value, String dataType) throws IOException {
    if (dataType.toLowerCase().equals("long")) {
      return Long.parseLong(value);
    } else if (dataType.toLowerCase().equals("double")) {
      return Double.parseDouble(value);
    } else {
      throw new IOException("Data type only accepts long or double.");
    }
  }
}
