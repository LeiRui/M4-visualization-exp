package org.apache.iotdb.jarCode;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

// java ExtractBallSpeedData /data3/raw_data/data/full-game BallSpeed.csv 1 5 8 2000000 3200000
public class ExtractBallSpeedData {

  // sid, ts, x, y, z, |v|, |a|, vx, vy, vz, ax, ay, az
  public static void main(String[] args) throws IOException {
//    String inPath = args[0];
//    String outPath = args[1];
//    int timeIdx = Integer.parseInt(args[2]);
//    int valueIdx = Integer.parseInt(args[3]);
//    int sid = Integer.parseInt(args[4]); // -1 means all sid
//    int startNum = Integer.parseInt(args[5]);
//    int endNum = Integer.parseInt(args[6]);

    String inPath = "D:\\baseline\\full-game\\full-game";
    String outPath = "tmp.csv";
    int timeIdx = 1;
    int valueIdx = 5;
    int sid = 8;
    int startNum = 2000000;
    int endNum = 3200000;

    File f = new File(inPath);
    FileWriter fileWriter = new FileWriter(outPath);
    String line;
    BufferedReader reader = new BufferedReader(new FileReader(f));
    PrintWriter printWriter = new PrintWriter(fileWriter);
    int cnt = 0;
    long lastTimestamp = -1;
    long minTime = -1;
    while ((line = reader.readLine()) != null) {
      String[] split = line.split(",");
      if (sid != -1) {
        int lineSid = Integer.parseInt(split[0]);
        if (lineSid != sid) {
          continue;
        }
      }
      cnt++;
      if (cnt < startNum) {
        continue;
      }
      if (cnt >= endNum) {
        break;
      }
      long timestamp = Long.parseLong(split[timeIdx]);
      if (minTime == -1) {
        minTime = timestamp; // assume first timestamp is never disordered. is global minimal.
        timestamp = 0;
      } else {
        timestamp = timestamp - minTime;
      }
      timestamp = (long) (timestamp / 1000); // turn to ns. original time unit is ps. IoTDB only ns.
      long value = Long.parseLong(split[valueIdx]);

      printWriter.print(timestamp);
      printWriter.print(",");
      printWriter.print(value);
      printWriter.println();
      if (timestamp < lastTimestamp) {
        System.out.println("out-of-order! " + timestamp);
      }
      lastTimestamp = timestamp;
    }
    reader.close();
    printWriter.close();
  }
}
