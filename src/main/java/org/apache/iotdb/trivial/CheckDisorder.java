package org.apache.iotdb.trivial;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;

public class CheckDisorder {

  // to check disorder
  public static void main(String[] args) throws Exception {
    DateFormat dateFormat = new SimpleDateFormat(
        "yyyy-MM-dd'T'HH:mm:ss.SSS"); // 2020-06-09T23:51:07.194+08:00

    String dataDir = args[0]; // E.g., /disk/zc_csv
    System.out.println("dataDir=" + dataDir);

    // iteratively get all files under dataDir
    List<File> res = listAllFiles(dataDir, new ArrayList<>());

    // extract the column with the targetSensorName, and attach them together
    long lastTimestamp = -1;
    for (File f : res) {
      System.out.println("file: " + f);
      BufferedReader reader = new BufferedReader(new FileReader(f));
      String line;
      line = reader.readLine(); // read header
      String[] splits;
      // get the index of the targetSensorName
      while ((line = reader.readLine()) != null) {
        splits = line.split(",");
        long timestamp;
        try {
          timestamp = dateFormat.parse(splits[0]).getTime();
        } catch (ParseException e) {
          timestamp = Long.parseLong(splits[0]);
        }
        if (timestamp < lastTimestamp) {
          System.out.println("disorder: " + timestamp + " < " + lastTimestamp);
        }
        lastTimestamp = timestamp;
      }
      reader.close();
    }
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
