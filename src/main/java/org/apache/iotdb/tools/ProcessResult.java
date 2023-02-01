package org.apache.iotdb.tools;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

public class ProcessResult {

  /**
   * select min_time(s6), max_time(s6), first_value(s6), last_value(s6), min_value(s6),
   * max_value(s6) from root.game group by ([0, 617426057627), 617426057627ns)     meta IO: 14674123
   * meta num:      1        data IO:       0        data num:      0 readMemChunk IO: 0
   * readMemChunk num:      0        total:         46054921        pointsTraversed: 1200000
   */
  public static void main(String[] args) throws IOException {

    String inFilePath = args[0];
    String outFilePath = args[1];
    String sumOutFilePath = args[2];

    BufferedReader reader = new BufferedReader(new FileReader(inFilePath));
    FileWriter writer = new FileWriter(outFilePath);

    FileWriter sumWriter = new FileWriter(sumOutFilePath, true); // append
    File file = new File(sumOutFilePath);
    if (!file.exists() || file.length() == 0) { // write header for sumOutFilePath
      sumWriter.write(
          "meta_num,avg_meta,data_num,avg_data,read_mem_chunk_num,avg_read_mem_chunk_time,avg_total,pointsTraversed\n");
    }

    String readLine = null;
    boolean firstTime = true;
    int metaNum = 0, dataNum = 0, readMemChunkNum = 0;
    long pointsTravered = 0;
    long metaTime = 0;
    long dataTime = 0;
    long totalTime = 0;
    long readMemChunkTime = 0;
    int counter = 0;
    while ((readLine = reader.readLine()) != null) {
      if (readLine.startsWith("select")) {
        String[] values = readLine.split("\t");
        if (firstTime) {
          metaNum = Integer.parseInt(values[4]);
          dataNum = Integer.parseInt(values[8]);
          readMemChunkNum = Integer.parseInt(values[12]);
          pointsTravered = Long.parseLong(values[16]);
        }
        metaTime += Long.parseLong(values[2]);
        dataTime += Long.parseLong(values[6]);
        readMemChunkTime += Long.parseLong(values[10]);
        totalTime += Long.parseLong(values[14]);
        counter++;
        writer.write(readLine + "\n");
      }
    }

    writer.write(
        "meta_num\t avg_meta\t data_num\t avg_data\t read_mem_chunk_num\t avg_read_mem_chunk_time\t avg_total\t pointsTraversed\n"
            + metaNum
            + "\t"
            + (double) metaTime / 1000000 / counter
            + "\t"
            + dataNum
            + "\t"
            + (double) dataTime / 1000000 / counter
            + "\t"
            + readMemChunkNum
            + "\t"
            + (double) readMemChunkTime / 1000000 / counter
            + "\t"
            + (double) totalTime / 1000000 / counter
            + "\t"
            + pointsTravered
    );

    sumWriter.write(
        metaNum
            + ","
            + (double) metaTime / 1000000 / counter
            + ","
            + dataNum
            + ","
            + (double) dataTime / 1000000 / counter
            + ","
            + readMemChunkNum
            + ","
            + (double) readMemChunkTime / 1000000 / counter
            + ","
            + (double) totalTime / 1000000 / counter
            + ","
            + pointsTravered
            + "\n");

    reader.close();
    writer.close();
    sumWriter.close();
  }
}
