package org.apache.iotdb.trivial;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.PrintWriter;

public class ScaleData {

  // 253762109838,253762575209,254379530220,86514,155372,3780[254267403127],527076[253868558352]
  public static void main(String[] args) throws Exception {
    String input = "D:\\3\\plotRawData_ExpRes_Motivation\\MOTIVATION\\motivation\\M4_data_w_1000_part.csv";
    String output = "scaled_M4_data_w_1000_part.csv";
    double k = 0.4;
    BufferedReader reader = new BufferedReader(new FileReader(input));
    PrintWriter writer = new PrintWriter(output);
    String line;
    while ((line = reader.readLine()) != null) {
      System.out.println(line);
      String[] splits = line.split(",");
      long firstValue = (long) (Long.parseLong(splits[3]) * k);
      long lastValue = (long) (Long.parseLong(splits[4]) * k);
      long minValue = (long) (Long.parseLong(splits[5].substring(0, splits[5].indexOf("["))) * k);
      String bottomTime = splits[5].substring(splits[5].indexOf("["));
      long maxValue = (long) (Long.parseLong(splits[6].substring(0, splits[6].indexOf("["))) * k);
      String topTime = splits[6].substring(splits[6].indexOf("["));

      writer.print(splits[0]);
      writer.print(",");

      writer.print(splits[1]);
      writer.print(",");

      writer.print(splits[2]);
      writer.print(",");

      writer.print(firstValue);
      writer.print(",");

      writer.print(lastValue);
      writer.print(",");

      writer.print(minValue);
      writer.print(bottomTime);
      writer.print(",");

      writer.print(maxValue);
      writer.print(topTime);

      writer.println();
    }
    reader.close();
    writer.close();
  }
}
