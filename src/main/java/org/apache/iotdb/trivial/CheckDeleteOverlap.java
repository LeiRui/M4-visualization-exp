package org.apache.iotdb.trivial;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.PrintWriter;

public class CheckDeleteOverlap {

  public static void main(String[] args) throws Exception {
//    String modFile = "D:\\3\\debug\\1656254471662-2-0-0.tsfile.mods";
    String sketchFile = "D:\\3\\debug\\TsFile_sketch_view.txt";

    // read sketchFile to get start and end time of all chunks
    BufferedReader reader = new BufferedReader(new FileReader(sketchFile));
    PrintWriter writer = new PrintWriter("sketchFile.csv");
    String line;
    while ((line = reader.readLine()) != null) {
      if (line.contains("\tstartTime:")) {
        System.out.println(line);
        String[] splits = line.split("\\s+");
        long startTime = Long.parseLong(splits[2]);
        long endTime = Long.parseLong(splits[4]);
        writer.println(startTime + "," + endTime);
      }
    }
    reader.close();
    writer.close();

//    // read modFile to get start and end time of all deletes
//    reader = new BufferedReader(new FileReader(modFile));
//    writer = new PrintWriter("modFile.csv");
//    while ((line = reader.readLine()) != null) {
//      String[] splits = line.split(",");
//      long startTime = Long.parseLong(splits[3]);
//      long endTime = Long.parseLong(splits[4]);
//      writer.println(startTime + "," + endTime);
//    }
//    reader.close();
//    writer.close();

  }

}
