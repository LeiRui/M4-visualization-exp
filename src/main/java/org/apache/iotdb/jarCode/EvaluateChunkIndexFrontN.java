package org.apache.iotdb.jarCode;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;

// use the first N points instead of sliding window
// nohup java -jar EvaluateChunkIndexFrontN-jar-with-dependencies.jar 10000 BallSpeed.csv 2>&1 &
public class EvaluateChunkIndexFrontN {

  public static List<Double> maxErrorList = new ArrayList<>();
  public static List<Double> avgErrorList = new ArrayList<>();
  public static List<Double> segmentNumList = new ArrayList<>();
  public static List<Double> buildTimeList = new ArrayList<>(); // nanosecond

  public static List<Double> accessTimeList = new ArrayList<>(); // nanosecond
  public static long accessResultCheckSum = 0; // nanosecond
  public static int repeatRoundCnt = 0;

  public static String expResultFile = "evaluateIndexExp.csv";

  public static void main(String[] args) throws Exception {
    int[] testN = new int[]{100, 100, 500, 1000, 2000, 4000, 6000, 10000, 15000, 20000, 25000,
        30000, 35000, 40000, 45000, 50000}; // the first 100 for warm up codes
    int repeatRound = Integer.parseInt(args[0]);
    String filePath = args[1];
    //    String csvData = "D:\\github\\reply\\BallSpeed.csv"; // no header
    for (int N : testN) {
      System.out.println("testing N=" + N);
      reset();
      testWithN(N, repeatRound, filePath);
    }
    System.out.println("ALL FINISH!");
  }

  public static void reset() {
    maxErrorList = new ArrayList<>();
    avgErrorList = new ArrayList<>();
    segmentNumList = new ArrayList<>();
    buildTimeList = new ArrayList<>(); // nanosecond

    accessTimeList = new ArrayList<>(); // nanosecond
    accessResultCheckSum = 0; // nanosecond

//    repeatCount = 0;
    repeatRoundCnt = 0;
  }

  public static void testWithN(int chunkPointNumArg, int repeatRound, String csvData)
      throws Exception {
    if (chunkPointNumArg <= 0) {
      throw new IOException("N should be positive!");
    }
    String line;
    while (repeatRoundCnt < repeatRound) {
      List<Long> timestampList = new ArrayList<>();
      try (BufferedReader reader = new BufferedReader(new FileReader(csvData))) {
        while ((line = reader.readLine()) != null) {
          if (timestampList.size() < chunkPointNumArg) {
            // prepare next round of test data with N points
            long timestamp = Long.parseLong(line.split(",")[0]);
            timestampList.add(timestamp);
          } else {
            // reach N points, then trigger a test
            singleTest(timestampList);
            break;
          }
        }
      }
      repeatRoundCnt++;
    }

    // for correctness check
    System.out.println("repeat test num = " + maxErrorList.size());
    if (maxErrorList.size() != accessResultCheckSum) {
      System.out.println("Something is wrong with access tests");
    }

    // output results
    PrintWriter printWriter;
    File exp = new File(expResultFile);
    if (exp.exists()) {
      printWriter = new PrintWriter(new FileOutputStream(exp, true /* append = true */));
    } else {
      printWriter = new PrintWriter(expResultFile);
      printWriter.println(
          "N,maxError,avgError,segmentNum,spaceOverhead(bytes),spaceOverheadRatio,buildTime(ns),accessTime(ns)");
    }
    printWriter.print(chunkPointNumArg);
    printWriter.print(",");

    double maxError = Collections.max(maxErrorList);
    System.out.println("max error = " + maxError); // max of max
    printWriter.print(maxError);
    printWriter.print(",");

    double avgError = calculateAverage(avgErrorList);
    System.out.println("avg error = " + avgError); // avg of avg
    printWriter.print(avgError);
    printWriter.print(",");

    double segmentNum = calculateAverage(segmentNumList);
    System.out.println("segment number = " + segmentNum);
    printWriter.print(segmentNum);
    printWriter.print(",");

    double spaceOverhead = getSpaceOverhead(segmentNum + 1);
    System.out.println("space overhead (bytes) = " + spaceOverhead);
    printWriter.print(spaceOverhead);
    printWriter.print(",");

    double relativeSpaceOverhead = spaceOverhead / (chunkPointNumArg * 16);
    System.out.println("space overhead ratio = " + relativeSpaceOverhead);
    printWriter.print(relativeSpaceOverhead);
    printWriter.print(",");

    double buildTime = calculateAverage(buildTimeList);
    System.out.println("build time (ns) = " + buildTime);
    printWriter.print(buildTime);
    printWriter.print(",");

    double accssTime = calculateAverage(accessTimeList);
    System.out.println("access time (ns) = " + accssTime);
    System.out.println("access result sum = " + accessResultCheckSum);
    printWriter.print(accssTime);
    printWriter.println();
    printWriter.close();
  }

  public static void singleTest(List<Long> timestamps) throws Exception {
//    repeatCount++;
    long start = System.nanoTime();
    StepRegress stepRegress = new StepRegress();
    for (long t : timestamps) {
      stepRegress.insert(t);
    }
    stepRegress.learn();
    // test build time
    buildTimeList.add(System.nanoTime() - start * 1.0);

    // test accuracy
    double[] maxAndAvgError = evaluateAccuracy(stepRegress, timestamps);
    maxErrorList.add(maxAndAvgError[0]);
    avgErrorList.add(maxAndAvgError[1]);

    // test space: space consumption can be deferred from the number of segments
    segmentNumList.add(stepRegress.getSegmentKeys().size() - 1.0);

    // test access time (all in memory)
    Random rand = new Random();
    long queryTimestamp = timestamps.get(rand.nextInt(timestamps.size()));
    start = System.nanoTime();
    boolean ifExist = accessInMemory(stepRegress, timestamps, queryTimestamp);
    accessTimeList.add(System.nanoTime() - start * 1.0);
    accessResultCheckSum += ifExist ? 1 : 0;
  }

  public static boolean accessInMemory(StepRegress stepRegress, List<Long> timestamps,
      long targetTimestamp) throws Exception {

    int estimatedPos = (int) Math.round(stepRegress.infer(targetTimestamp)) - 1;

    // search from estimatePos to find the closet timestamp equal to or smaller
    // than the given timestamp
    if (timestamps.get(estimatedPos) > targetTimestamp) {
      while (timestamps.get(estimatedPos) > targetTimestamp) {
        estimatedPos--;
      }
    } else if (timestamps.get(estimatedPos) < targetTimestamp) {
      while (timestamps.get(estimatedPos) < targetTimestamp) {
        estimatedPos++;
      }
      if (timestamps.get(estimatedPos) > targetTimestamp) {
        estimatedPos--;
      } // else equal
    } // else equal

    // return if exists, true to exist
    return timestamps.get(estimatedPos) == targetTimestamp;
  }

  /**
   * return the maximal and average error
   */
  public static double[] evaluateAccuracy(StepRegress stepRegress, List<Long> timestamps)
      throws Exception {
    int pos_true = 0;
    List<Double> absErrors = new ArrayList<>();
    for (long t : timestamps) {
      pos_true++;
      absErrors.add(Math.abs(stepRegress.infer(t) - pos_true));
    }
    double[] maxandAvg = new double[2];
    maxandAvg[0] = Collections.max(absErrors);
    maxandAvg[1] = calculateAverage(absErrors);
    return maxandAvg;
  }

  public static double calculateAverage(List<Double> data) {
    double sum = 0;
    if (!data.isEmpty()) {
      for (double x : data) {
        sum += x;
      }
      return sum / data.size();
    }
    return sum;
  }

  // 8 bytes slope, 4 bytes segmentKeyNum m, m segment keys each 8 bytes
  public static double getSpaceOverhead(double segmentKeyNum) {
    return 12 + segmentKeyNum * 8;
  }

}
