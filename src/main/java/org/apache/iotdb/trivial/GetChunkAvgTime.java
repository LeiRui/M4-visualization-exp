package org.apache.iotdb.trivial;

import java.io.BufferedReader;
import java.io.FileReader;

public class GetChunkAvgTime {

  public static void main(String[] args) throws Exception {
    String sketchFile = "D:\\3\\debug\\TsFile_sketch_view.txt";
    BufferedReader reader = new BufferedReader(new FileReader(sketchFile));
    String line;
    long sum = 0;
    int cnt = 0;
    while ((line = reader.readLine()) != null) {
      if (line.contains("time range:")) { // [Chunk] of s6, numOfPoints:100, time range:[0,50687600], tsDataType:INT64,
        line = line.substring(line.indexOf("[", line.indexOf("[") + 1) + 1);
        line = line.substring(0, line.indexOf("]"));
        System.out.println(line);
        String[] splits = line.split(",");
        long startTime = Long.parseLong(splits[0]);
        long endTime = Long.parseLong(splits[1]);
        long length = endTime - startTime;
        sum += length;
        cnt++;
      }
    }
    reader.close();
    System.out.println("chunkAvgTimeLen=" + sum / cnt);
  }
}
