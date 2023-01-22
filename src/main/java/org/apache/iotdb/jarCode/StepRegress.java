package org.apache.iotdb.jarCode;

import java.io.IOException;
import org.eclipse.collections.impl.list.mutable.primitive.DoubleArrayList;
import org.eclipse.collections.impl.list.mutable.primitive.IntArrayList;
import org.eclipse.collections.impl.list.mutable.primitive.LongArrayList;

public class StepRegress {

  private double slope;

  // when learning parameters, we first determine segmentIntercepts and then determine segmentKeys;
  // when using functions, we read segmentKeys and then infer segmentIntercepts.
  // fix that the first segment is always tilt,
  // so for indexes starting from 0, even id is tilt, odd id is level.
  private DoubleArrayList segmentIntercepts = new DoubleArrayList(); // b1,b2,...,bm-1

  // fix that the first segment [t1,t2) is always tilt,
  // so t2=t1 in fact means that the first status is level
  private DoubleArrayList segmentKeys = new DoubleArrayList(); // t1,t2,...,tm
  // TODO deal with the last key tm

  private LongArrayList timestamps = new LongArrayList(); // Pi.t
  private LongArrayList intervals = new LongArrayList(); // Pi+1.t-Pi.t

  enum IntervalType {
    tilt,
    level
  }

  private IntArrayList intervalsType = new IntArrayList();
  private long previousTimestamp = -1;

  private double mean = 0; // mean of intervals
  private double stdDev = 0; // standard deviation of intervals
  private long count = 0;
  private double sumX2 = 0.0;
  private double sumX1 = 0.0;

  private double median = 0; // median of intervals
  private double mad = 0; // median absolute deviation of intervals
  TimeExactOrderStatistics statistics = new TimeExactOrderStatistics();

  /**
   * load data, record timestamps and intervals, preparing to calculate mean,std,median,mad along
   * the way
   */
  public void insert(long timestamp) {
    timestamps.add(timestamp); // record
    if (previousTimestamp > 0) {
      long delta = timestamp - previousTimestamp;
      intervals.add(delta); // record
      // prepare for mean and stdDev
      count++;
      sumX1 += delta;
      sumX2 += delta * delta;
      // prepare for median and mad
      statistics.insert(delta);
    }
    previousTimestamp = timestamp;
  }

  private void initForLearn() {
    this.mean = getMean();
    this.stdDev = getStdDev();
    this.median = getMedian();
    this.mad = getMad();
    this.slope = 1 / this.median;
    this.segmentKeys.add(timestamps.get(0)); // t1
    this.segmentIntercepts.add(1 - slope * timestamps.get(0)); // b1
  }

  /**
   * learn the parameters of the step regression function for the loaded data.
   */
  public void learn() {
    initForLearn();

    int tiltLatestSegmentID = 0;
    IntervalType previousIntervalType = IntervalType.tilt;

    for (int i = 0; i < intervals.size(); i++) {
      long delta = intervals.get(i);

      // the current point (t,pos). t is the left endpoint of the current interval.
      long t = timestamps.get(i);
      int pos = i + 1;

      // 1) determine the type of the current interval
      // level condition: big interval && position not smaller than tilt prediction.
      // or equally, tilt condition: !big interval || position bigger than tilt prediction.
      boolean isLevel =
          isBigInterval(delta) && (pos <= slope * t + segmentIntercepts.get(tiltLatestSegmentID));

      // 2) determine if starting a new segment
      if (isLevel) {
        intervalsType.add(IntervalType.level.ordinal());
        if (previousIntervalType == IntervalType.tilt) { // else do nothing, still level
          // [[[translate from tilt to level]]]
          previousIntervalType = IntervalType.level;
          // 3) to determine the intercept, let the level function run through (t,pos)
          double intercept = pos; // b2i=pos
          // 4) to determine the segment key, let the level function and the previous tilt function intersect
          segmentKeys.add((intercept - segmentIntercepts.getLast()) / slope); // x2i=(b2i-b2i-1)/K
          // then add intercept to segmentIntercepts, do not change the order of codes here
          segmentIntercepts.add(
              intercept); // TODO debug if the first status is actually level works
        }
      } else {
        intervalsType.add(IntervalType.tilt.ordinal());
        if (previousIntervalType == IntervalType.level) { // else do nothing, still tilt
          // [[[translate form level to tilt]]]
          previousIntervalType = IntervalType.tilt;
          // 3) to determine the intercept, let the tilt function run through (t,pos)
          double intercept = pos - slope * t; // b2i+1=pos-K*t
          // 4) to determine the segment key, let the level function and the previous tilt function intersect
          segmentKeys.add((segmentIntercepts.getLast() - intercept) / slope); // x2i+1=(b2i-b2i+1)/K
          // then add intercept to segmentIntercepts, do not change the order of codes here
          segmentIntercepts.add(intercept);
          // remember to update tiltLatestSegmentID
          tiltLatestSegmentID += 2;
        }
      }
    }
    segmentKeys.add(timestamps.getLast()); // tm
  }

  private boolean isBigInterval(long interval) {
    int bigIntervalParam = 3;
    return interval > this.mean + bigIntervalParam * this.stdDev;
  }

  public double getMedian() {
    return statistics.getMedian();
  }

  public double getMad() {
    return statistics.getMad();
  }

  public double getMean() { // sample mean
    return sumX1 / count;
  }

  public double getStdDev() { // sample standard deviation
    double std = Math.sqrt(this.sumX2 / this.count - Math.pow(this.sumX1 / this.count, 2));
    return Math.sqrt(Math.pow(std, 2) * this.count / (this.count - 1));
  }

  public DoubleArrayList getSegmentIntercepts() {
    return segmentIntercepts;
  }

  public double getSlope() {
    return slope;
  }

  public DoubleArrayList getSegmentKeys() {
    return segmentKeys;
  }

  public IntArrayList getIntervalsType() {
    return intervalsType;
  }

  public LongArrayList getIntervals() {
    return intervals;
  }

  public LongArrayList getTimestamps() {
    return timestamps;
  }

  /**
   * infer m-1 intercepts b1,b2,...,bm-1 given the slope and m segmentKeys t1,t2,...,tm (tm is not
   * used)
   */
  public static DoubleArrayList inferInterceptsFromSegmentKeys(double slope,
      DoubleArrayList segmentKeys) {
    DoubleArrayList segmentIntercepts = new DoubleArrayList();
    segmentIntercepts.add(1 - slope * segmentKeys.get(0)); // b1=1-K*t1
    for (int i = 1; i < segmentKeys.size() - 1; i++) { // b2,b3,...,bm-1
      if (i % 2 == 0) { // b2i+1=b2i-1-K*(t2i+1-t2i)
        double b = segmentIntercepts.get(segmentIntercepts.size() - 2);
        segmentIntercepts.add(b - slope * (segmentKeys.get(i) - segmentKeys.get(i - 1)));
      } else { // b2i=K*t2i+b2i-1
        double b = segmentIntercepts.getLast();
        segmentIntercepts.add(slope * segmentKeys.get(i) + b);
      }
    }
    return segmentIntercepts;
  }

  /**
   * @param t input
   * @return output the value of the step regression function f(t)
   */
  public double infer(double t) throws IOException {
    if (t < segmentKeys.get(0) || t > segmentKeys.getLast()) {
      throw new IOException(
          String.format("t out of range. input within [%s,%s]", segmentKeys.get(0),
              segmentKeys.getLast()));
    }
    int seg = 0;
    for (; seg < segmentKeys.size() - 1; seg++) {
      if (t <= segmentKeys.get(seg + 1)) { // t < the right end of the segment interval
        break;
      }
    }
    // we have fixed that the first status is always tilt,
    // so for indexes starting from 0, even id is tilt, odd id is level.
    if (seg % 2 == 0) { // tilt
      return slope * t + segmentIntercepts.get(seg);
    } else {
      return segmentIntercepts.get(seg);
    }
  }
}
