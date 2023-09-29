import csv
from matplotlib import pyplot as plt
import numpy as np
import pandas as pd
import argparse

parser=argparse.ArgumentParser(description="plot query exp result",
                               formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("-i","--input",help="input query result csv path")
parser.add_argument("-o","--output",help="output directory")
args = parser.parse_args()
config = vars(args)
res=str(config.get('input'))
# res="D:\github\mid\res.csv"
print(res)

output=str(config.get('output'))

df=pd.read_csv(res)
print(df)

w=df.iloc[:,0]
query_m4=df.iloc[:,2].div(1000000000) # ns to s
query_m4_lsm=df.iloc[:,3].div(1000000000) # ns to s
query_minmax=df.iloc[:,4].div(1000000000) # ns to s
query_lttb=df.iloc[:,5].div(1000000000) # ns to s


plt.figure(1,dpi=120)

plt.xticks(fontsize=20)
plt.yticks(fontsize=20)
plt.xlabel("w",fontsize=20)
plt.ylabel("time (s)",fontsize=20)

plt.xscale("log")
plt.yscale("log")

plt.plot(w,query_m4,label="M4",marker='s',markersize=12,linewidth=2.5)
plt.plot(w,query_m4_lsm,label="M4-LSM",marker='X',markersize=12,linewidth=2.5)
plt.plot(w,query_minmax,label="MinMax",marker='o',markersize=12,linewidth=2.5)
plt.plot(w,query_lttb,label="LTTB",marker='P',markersize=12,linewidth=2.5)

# plt.plot(x,python,label="Python",marker='o',markersize=15,linewidth=2.5,color='red') #0
# plt.plot(x,grafana,label="Grafana",marker='P',markersize=15,linewidth=2.5,color='#9467bd') #1
# plt.plot(x,grafanaM4,label="Grafana with M4-LSM",marker='s',markersize=15,linewidth=2.5,color='green') #2
# plt.plot(x,pythonM4,label="Python with M4-LSM",marker='X',markersize=15,linewidth=2.5,color='#ff7f0e') #3

#plt.legend(ncol=3,fontsize=20,bbox_to_anchor=(0.5,1.20), loc='upper center');
plt.legend(fontsize=20);
plt.savefig("{}/query-vary-w.eps".format(output),bbox_inches='tight')
plt.savefig("{}/query-vary-w.png".format(output),bbox_inches='tight')
plt.show()
plt.close()