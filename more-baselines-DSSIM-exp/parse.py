from matplotlib import pyplot as plt
import numpy as np
import csv
import datetime
import pandas as pd
import time
import argparse
import sys
import os
import math
import re
import subprocess

# read csv, parse, plot

def myDeduplicate(seq): # deduplicate list seq by comparing the first element, e.g. l=[(1,1),(1,2)] => l=[(1,1)]
  seen = set()
  seen_add = seen.add
  return [x for x in seq if not (x[0] in seen or seen_add(x[0]))]

# remote node has not exported the environment variables, so passing them using args
parser=argparse.ArgumentParser(description="remote query to csv",
                               formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("-i","--input",help="input directory")
parser.add_argument("-a","--approach",help="approach")
parser.add_argument("-w","--w",help="w parameter")
# parser.add_argument("-h","--header",help="has header")
parser.add_argument("-o","--output",help="output directory")

args = parser.parse_args()
config = vars(args)

inputDir=str(config.get('input'))
approach=str(config.get('approach'))
w=str(config.get('w'))
# hasHeader=str(config.get('header'))
outputDir=str(config.get('output'))

# --------------------input path--------------------------
inputCsvPath="{}/data-{}-{}.csv".format(inputDir,approach,w)

# --------------------output path--------------------------
outputCsvPath="{}/ts-{}-{}.csv".format(outputDir,approach,w)

# --------------------parse--------------------------
if approach == 'rawQuery': # hasHeader
  os.system("cp {} {}".format(inputCsvPath,outputCsvPath))
else: # no header
  df = pd.read_csv(inputCsvPath, sep='\t', header=None)

  if approach == 'mac':
    # for each row, extract four points, sort and deduplicate, deal with empty
    ts=[]
    for ir in df.itertuples():
      string = ir[2] # ir[0] is idx
      # deal with "empty" string
      if str(string)=="empty":
        # print("empty")
        continue
      # deal with "FirstPoint=(t,v), LastPoint=(t,v), BottomPoint=(t,v), TopPoint=(t,v)"
      numberStrList = re.findall(r'\d+(?:\.\d+)?',string) # find int or float str

      FP_t=int(numberStrList[0])
      FP_v=float(numberStrList[1])
      LP_t=int(numberStrList[2])
      LP_v=float(numberStrList[3])
      BP_t=int(numberStrList[4])
      BP_v=float(numberStrList[5])
      TP_t=int(numberStrList[6])
      TP_v=float(numberStrList[7])

      ts.append((FP_t,FP_v))
      ts.append((LP_t,LP_v))
      ts.append((BP_t,BP_v))
      ts.append((TP_t,TP_v))

    # sort
    ts.sort(key=lambda x: x[0])

    # deduplicate
    ts=myDeduplicate(ts)

    df = pd.DataFrame(ts,columns=['time','value']) # output csv has header
    df.to_csv(outputCsvPath, sep=',',index=False)
  elif approach == 'cpv':
    # for each row, extract four points, sort and deduplicate, deal with None
    ts=[]
    for ir in df.itertuples():
      # deal with "None" string
      string=ir[2] # ir[0] is idx
      if str(string)=="None" or pd.isnull(ir[2]):
        # print("None/NaN")
        continue

      # deal with minTime,maxTime,firstValue,lastValue,minValue[bottomTime],maxValue[TopTime]
      FP_t=int(ir[2])
      FP_v=float(ir[4])
      LP_t=int(ir[3])
      LP_v=float(ir[5])
      BP_str=ir[6]
      numberStrList = re.findall(r'\d+(?:\.\d+)?',BP_str) # find int or float str
      BP_t=int(numberStrList[1])
      BP_v=float(numberStrList[0])
      TP_str=ir[7]
      numberStrList = re.findall(r'\d+(?:\.\d+)?',TP_str) # find int or float str
      TP_t=int(numberStrList[1])
      TP_v=float(numberStrList[0])

      ts.append((FP_t,FP_v))
      ts.append((LP_t,LP_v))
      ts.append((BP_t,BP_v))
      ts.append((TP_t,TP_v))

    # sort
    ts.sort(key=lambda x: x[0])

    # deduplicate
    ts=myDeduplicate(ts)

    df = pd.DataFrame(ts,columns=['time','value'])
    df.to_csv(outputCsvPath, sep=',',index=False)

  elif approach == 'minmax':
    # for each row, extract two points, sort and deduplicate, deal with empty
    ts=[]
    for ir in df.itertuples():
      string = ir[2] # ir[0] is idx
      # deal with "empty" string
      if str(string)=="empty":
        # print("empty")
        continue
      # deal with "FirstPoint=(t,v), LastPoint=(t,v), BottomPoint=(t,v), TopPoint=(t,v)"
      numberStrList = re.findall(r'\d+(?:\.\d+)?',string) # find int or float str

      BP_t=int(numberStrList[0])
      BP_v=float(numberStrList[1])
      TP_t=int(numberStrList[2])
      TP_v=float(numberStrList[3])

      ts.append((BP_t,BP_v))
      ts.append((TP_t,TP_v))

    # sort
    ts.sort(key=lambda x: x[0])

    # deduplicate
    ts=myDeduplicate(ts)

    df = pd.DataFrame(ts,columns=['time','value'])
    df.to_csv(outputCsvPath, sep=',',index=False)

  elif approach == 'minmax_lsm':
    # for each row, extract two points, sort and deduplicate, deal with None
    ts=[]
    for ir in df.itertuples():
      # deal with "None" string
      string=ir[2] # ir[0] is idx
      if str(string)=="None" or pd.isnull(ir[2]):
        # print("None/NaN")
        continue

      # deal with minValue[bottomTime],maxValue[TopTime]
      BP_str=ir[2]
      numberStrList = re.findall(r'\d+(?:\.\d+)?',BP_str) # find int or float str
      BP_t=int(numberStrList[1])
      BP_v=float(numberStrList[0])
      TP_str=ir[3]
      numberStrList = re.findall(r'\d+(?:\.\d+)?',TP_str) # find int or float str
      TP_t=int(numberStrList[1])
      TP_v=float(numberStrList[0])

      ts.append((BP_t,BP_v))
      ts.append((TP_t,TP_v))

    # sort
    ts.sort(key=lambda x: x[0])

    # deduplicate
    ts=myDeduplicate(ts)

    df = pd.DataFrame(ts,columns=['time','value'])
    df.to_csv(outputCsvPath, sep=',',index=False)

  elif approach == 'lttb':
    # print(df)
    df.to_csv(outputCsvPath, sep=',',index=False,header=['time','value'])
  else:
    print("unsupported approach!")

