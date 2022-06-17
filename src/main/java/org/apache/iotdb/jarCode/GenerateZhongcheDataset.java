package org.apache.iotdb.jarCode;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.PrintWriter;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;

public class GenerateZhongcheDataset {

  public static void main(String[] args) throws Exception {
    DateFormat dateFormat = new SimpleDateFormat(
        "yyyy-MM-dd'T'HH:mm:ss.SSS"); // 2020-06-09T23:51:07.194+08:00

    String dataDir = args[0]; // E.g., /disk/zc_csv
    String targetSensorName = args[1]; // E.g., ZT765

    PrintWriter writer = new PrintWriter(targetSensorName + ".csv");

    // iteratively get all files under dataDir
    List<File> res = listAllFiles(dataDir, new ArrayList<>());

    // extract the column with the targetSensorName, and attach them together
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
      while ((line = reader.readLine()) != null) {
        splits = line.split(",");

        long timestamp;
        try {
          timestamp = dateFormat.parse(splits[0]).getTime();
        } catch (ParseException e) {
          timestamp = Long.parseLong(splits[0]);
        }

        double value = Double.parseDouble(splits[index]);
        writer.print(timestamp);
        writer.print(",");
        writer.print(value);
        writer.println();
      }
      reader.close();
    }

    writer.close();
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
