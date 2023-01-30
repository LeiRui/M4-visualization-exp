package org.apache.iotdb.jarCode;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import org.eclipse.collections.impl.list.mutable.primitive.DoubleArrayList;

public class StepRegressExample {

  public static void main(String[] args) throws Exception {
    // read data into memory, assuming that the data is small enough to fit in memory
    // read csvData from row start(inclusive) to end(exclusive), counting from 1

//    String csvData = "D:\\github\\m4-lsm\\plotRawData_ExpRes_Motivation\\plotTimestamps\\RcvTime.csv";
//    int x = 12741; //4232;
//    int range = 100;
//    int start = (x - 1) * range + 1;
//    int end = start + range;

//    String csvData = "D:\\github\\m4-lsm\\M4-visualization-exp\\src\\main\\java\\org\\apache\\iotdb\\jarCode\\test1.csv";
//    int start = 1;
//    int end = 81;

    int dataset = 2; // 1-ballspeed,2-mf03,3-kob,4-rcvtime
    String csvData = null;
    int start = 0; // inclusive, counting from 1
    int range = 0;
    int end = 0; // exclusive, counting from 1
    if (dataset == 1) {
      csvData = "D:\\github\\m4-lsm\\plotRawData_ExpRes_Motivation\\plotTimestamps\\datasets\\BallSpeed.csv";
      start = 423000;
      range = 1000;
      end = start + range;
    } else if (dataset == 2) {
      csvData = "D:\\github\\m4-lsm\\plotRawData_ExpRes_Motivation\\plotTimestamps\\datasets\\MF03.csv";
      start = 450000;
      range = 1000;
      end = start + range;
    } else if (dataset == 3) {
      csvData = "D:\\github\\m4-lsm\\plotRawData_ExpRes_Motivation\\plotTimestamps\\datasets\\KOB.csv";
      start = 1650012;
      range = 1000;
      end = start + range;
    } else if (dataset == 4) {
      csvData = "D:\\github\\m4-lsm\\plotRawData_ExpRes_Motivation\\plotTimestamps\\datasets\\RcvTime-custom.csv";
      start = 1; // 1273764
      range = 1000;
      end = start + range;
    } else {
      throw new IOException("wrong parameter!");
    }

    StepRegress stepRegress = new StepRegress();
    String line;
    List<Long> timestampList = new ArrayList<>();
    List<Long> intervalList = new ArrayList<>();
    long previousTimestamp = -1;
    long count = 0;
    try (BufferedReader reader = new BufferedReader(new FileReader(csvData))) {
      while ((line = reader.readLine()) != null) {
        count++;
        if (count >= start && count < end) {
          long timestamp = Long.parseLong(line.split(",")[0]);
          stepRegress.insert(timestamp);
          timestampList.add(timestamp);
          if (previousTimestamp > 0) {
            long delta = timestamp - previousTimestamp;
            intervalList.add(delta);
          }
          previousTimestamp = timestamp;
        } else if (count >= end) {
          break;
        }
      }
    }

    stepRegress.learn();
    System.out.println(csvData);
    System.out.println("position=[" + start + "," + end + ")");
    System.out.printf("slope=%.10f%n", stepRegress.getSlope());
    System.out.printf("mean=%.2f%n", stepRegress.getMean());
    System.out.printf("std=%.2f%n", stepRegress.getStdDev());
    System.out.printf("median=%.2f%n", stepRegress.getMedian());
    System.out.printf("mad=%.2f%n", stepRegress.getMad());
    System.out.println("timestamps=" + stepRegress.getTimestamps() + ";");
    System.out.println("intervalsType=" + stepRegress.getIntervalsType() + ";");
    System.out.println("intercepts=" + stepRegress.getSegmentIntercepts() + ";");
    System.out.println(
        "intercepts=" + StepRegress.inferInterceptsFromSegmentKeys(stepRegress.getSlope(),
            stepRegress.getSegmentKeys()) + ";");

    DoubleArrayList segmentKeysPos = new DoubleArrayList();
    for (double t : stepRegress.getSegmentKeys().toArray()) {
      segmentKeysPos.add(stepRegress.infer(t));
    }
    System.out.println("segmentKeys=" + stepRegress.getSegmentKeys() + ";");
    System.out.println("segmentKeysPos=" + segmentKeysPos + ";");
    System.out.println("passingTimestamps=" + stepRegress.passingTimestamps);
    System.out.println("passingPos=" + stepRegress.passingPos);

    DoubleArrayList predicts = new DoubleArrayList();
    for (long t : stepRegress.getTimestamps().toArray()) {
      predicts.add(stepRegress.infer(t));
    }
    System.out.println("predict=" + predicts + ";");

//    DoubleArrayList predictsFineGrain = new DoubleArrayList();
//    long step =
//        (stepRegress.getTimestamps().getLast() - stepRegress.getTimestamps().get(0)) / (range);
//    for (long t = stepRegress.getTimestamps().get(0); t <= stepRegress.getTimestamps().getLast();
//        t = t + step) {
//      predictsFineGrain.add(stepRegress.infer(t));
//    }
//    System.out.println("predict2=" + predictsFineGrain + ";");
  }

}

/**
 * figure, plot(chunkTimestamps(x,:),1:range), for i=1:1:range-1 if intervalsType(i)==0 hold
 * on,plot(chunkTimestamps(x,i),i,'b+') % non-outlier & tilt else hold
 * on,plot(chunkTimestamps(x,i),i,'r+') % outlier & level end end hold
 * on,plot(chunkTimestamps(x,range),range,'g+') % the last point
 * <p>
 * K=1/vmedian(x);
 * <p>
 * for i=1:1:length(keys) hold on,xline(keys(i)) end
 * <p>
 * hold on,plot(chunkTimestamps(x,1):30:chunkTimestamps(x,100),predict2)
 * <p>
 * y=1:1:range; max(abs(y-predict))
 */
