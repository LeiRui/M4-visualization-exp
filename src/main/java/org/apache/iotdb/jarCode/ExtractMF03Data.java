package org.apache.iotdb.jarCode;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.time.Instant;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

public class ExtractMF03Data {

  // java ExtractMF03Data /data3/raw_data/data/debs2012/allData.txt MF03.csv 0 4
  // 1329955200000000000 1329966000000000000
  public static void main(String[] args) throws IOException {
    String inPath = "D:\\DEBS2012-ChallengeData.txt\\allData.txt";
    String outPath = "D:\\DEBS2012-ChallengeData.txt\\MF03.csv";
    int timeIdx = 0; // 0
    int valueIdx = 4; // mf03: 4
    // [1329955200000000000 Thursday, February 23, 2012 0:00:00~1329966000000000000 Thursday,
    // February 23, 2012 3:00:00)
//    long startTime = 1329955200000000000L;
//    long endTime = 1338966000000000000L;

    File f = new File(inPath);
    FileWriter fileWriter = new FileWriter(outPath);
    String line;
    BufferedReader reader = new BufferedReader(new FileReader(f));
    PrintWriter printWriter = new PrintWriter(fileWriter);
    int cnt = 0;
    long lastTimestamp = -1;

    while ((line = reader.readLine()) != null) {
      String[] split = line.split("\\s+");
      String timestampStr = split[timeIdx];
      long timestamp = getInstantWithPrecision(timestampStr, "ns");
//      if (timestamp >= endTime) {
//        break;
//      }
//      if (timestamp < startTime) {
//        continue;
//      }
      long value = Long.parseLong(split[valueIdx]);

      if (timestamp <= lastTimestamp) {
        System.out.println("out-of-order! " + timestamp);
      } else {
        printWriter.print(timestamp);
        printWriter.print(",");
        printWriter.print(value);
        printWriter.println();
        cnt++;
        lastTimestamp = timestamp;
      }
      if (cnt >= 10000000) {
        break;
      }
    }
    reader.close();
    printWriter.close();
    System.out.println("lines=" + cnt);
  }

  //  private static long convertDatetimeStrToLong(String str, ZoneOffset offset, int depth)
  //      throws LogicalOperatorException {
  //
  //    String timestampPrecision =
  // IoTDBDescriptor.getInstance().getConfig().getTimestampPrecision();
  //
  //    if (depth >= 2) {
  //      throw new DateTimeException(
  //          String.format(
  //              "Failed to convert %s to millisecond, zone offset is %s, "
  //                  + "please input like 2011-12-03T10:15:30 or 2011-12-03T10:15:30+01:00",
  //              str, offset));
  //    }
  //    if (str.contains("Z")) {
  //      return convertDatetimeStrToLong(str.substring(0, str.indexOf('Z')) + "+00:00", offset,
  // depth);
  //    } else if (str.length() == 10) {
  //      return convertDatetimeStrToLong(str + "T00:00:00", offset, depth);
  //    } else if (str.length() - str.lastIndexOf('+') != 6
  //        && str.length() - str.lastIndexOf('-') != 6) {
  //      return convertDatetimeStrToLong(str + offset, offset, depth + 1);
  //    } else if (str.contains("[") || str.contains("]")) {
  //      throw new DateTimeException(
  //          String.format(
  //              "%s with [time-region] at end is not supported now, "
  //                  + "please input like 2011-12-03T10:15:30 or 2011-12-03T10:15:30+01:00",
  //              str));
  //    }
  //    return getInstantWithPrecision(str, timestampPrecision);
  //  }

  private static long getInstantWithPrecision(String str, String timestampPrecision)
      throws IOException {
    try {
      DateTimeFormatter formatter = DateTimeFormatter.ISO_OFFSET_DATE_TIME;
      ZonedDateTime zonedDateTime = ZonedDateTime.parse(str, formatter);
      Instant instant = zonedDateTime.toInstant();
      if (timestampPrecision.equals("us")) {
        if (instant.getEpochSecond() < 0 && instant.getNano() > 0) {
          // adjustment can reduce the loss of the division
          long millis = Math.multiplyExact(instant.getEpochSecond() + 1, 1000_000);
          long adjustment = instant.getNano() / 1000 - 1L;
          return Math.addExact(millis, adjustment);
        } else {
          long millis = Math.multiplyExact(instant.getEpochSecond(), 1000_000);
          return Math.addExact(millis, instant.getNano() / 1000);
        }
      } else if (timestampPrecision.equals("ns")) {
        long millis = Math.multiplyExact(instant.getEpochSecond(), 1000_000_000L);
        return Math.addExact(millis, instant.getNano());
      }
      return instant.toEpochMilli();
    } catch (DateTimeParseException e) {
      throw new IOException(e.getMessage());
    }
  }
}
