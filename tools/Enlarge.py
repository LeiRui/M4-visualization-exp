from matplotlib import pyplot as plt
import numpy as np
import csv
import pandas as pd
import random
import numpy as np
import argparse

parser=argparse.ArgumentParser(description="enlarge",
                               formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("-i","--input")
parser.add_argument("-o","--output")
parser.add_argument("-r","--ratio")
args = parser.parse_args()
config = vars(args)
inputFile=str(config.get('input'))
print(inputFile)
outputFile=str(config.get('output'))
ratio=int(config.get('ratio'))

df=pd.read_csv(inputFile,header=None)
V = [0] * (len(df)*ratio*2)
num=0
for i in range(len(df)-1):
  v1 = df.iloc[i,1]
  v2 = df.iloc[i+1,1]
  deltaV=v2-v1
  V[num]=v1
  num=num+1
  for j in range(ratio-1): # 0,1,...,ratio-2
    V[num]=v1+deltaV/ratio*(j+1)
    num=num+1

v1=np.array(V[0:num])
t1=np.arange(1,len(v1)+1)
print(len(t1))

t1=t1.reshape(num,1)
v1=v1.reshape(num,1)
arr = np.hstack([t1, v1])
pd.DataFrame(arr).to_csv(outputFile, index=False, header = False)