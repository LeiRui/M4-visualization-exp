package org.apache.iotdb.jarCode;

import java.io.IOException;
import java.io.PrintWriter;

public class GenerateLinearData_deprecated {

  public static void main(String[] args) throws IOException {
    int N = Integer.parseInt(args[0]);
    String outPath = args[1];

    PrintWriter writer = new PrintWriter(outPath);
    for (int i = 1; i <= N; i++) {
      writer.println(i + "," + i);
    }
    writer.close();
  }

}
