package org.apache.iotdb.tools;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class ProcessResult {

  public static void main(String[] args) throws IOException {

    String inFilePath = args[0]; // complete running repetition test log
    String sumOutFilePath = args[1]; // average metrics appending file

    BufferedReader reader = new BufferedReader(new FileReader(inFilePath));
    FileWriter sumWriter = new FileWriter(sumOutFilePath, true); // append
    File file = new File(sumOutFilePath);
    if (!file.exists() || file.length() == 0) { // write header for sumOutFilePath
      sumWriter.write("time(ns)\n");
    }

    String readLine;
    int repetition = 0;
    long total = 0;
    while ((readLine = reader.readLine()) != null) {
      repetition++;
      long time_ns = Long.parseLong(readLine);
      total += time_ns;
    }

    sumWriter.write((double) total / repetition + "");
    sumWriter.write("\n");

    reader.close();
    sumWriter.close();
  }

  public static String whichMetric(String line) {
    for (String metricName : QueryDataPrint) {
      if (line.contains(metricName)) {
        return metricName;
      }
    }
    return null;
  }

  public static void sumMetric(String metric, long ns_or_cnt, Map<String, Long> metrics_ns) {
    if (metrics_ns.containsKey(metric)) {
      metrics_ns.put(metric, ns_or_cnt + metrics_ns.get(metric));
    } else {
      metrics_ns.put(metric, ns_or_cnt);
    }
  }

//  public static void sumMetric(String metric, long op_cnt, Map<String, Long> metrics_cnt) {
//    if (metrics_cnt.containsKey(metric)) {
//      metrics_cnt.put(metric, op_cnt + metrics_cnt.get(metric));
//    } else {
//      metrics_cnt.put(metric, op_cnt);
//    }
//  }
}
