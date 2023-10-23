import csv
from matplotlib import pyplot as plt
import numpy as np
import pandas as pd
import argparse

# usage: python plot-dssim-query-exp-res.py -q res.csv -d dssim.csv -o .

parser=argparse.ArgumentParser(description="plot query exp result",
                               formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("-q","--query",help="input query result csv path")
parser.add_argument("-d","--dssim",help="input DSSIM result csv path")
parser.add_argument("-o","--output",help="output directory")
args = parser.parse_args()
config = vars(args)
query_res=str(config.get('query')) # res.csv
dssim_res=str(config.get('dssim')) # dssim.csv

output=str(config.get('output'))

# --------------------------------------------
font=80
marker=60
lw=10
fig, (ax1,ax2) = plt.subplots(1,2,figsize=(60,20))
fig.subplots_adjust(wspace=.3)

# --------------------------------------------
plt.sca(ax1)

# plot dssim res
with open(dssim_res,"r") as i:
  # rawdata = list(csv.reader(i,delimiter=","))
  reader=csv.reader(i,delimiter=",")
  next(reader, None)  # skip the headers
  rawdata = list(reader)

a=np.array(rawdata[:],dtype=float)
print(a)
w=a[:,0]
dssim_m4_raw=a[:,1]
dssim_m4_lsm_raw=a[:,2]
dssim_minmax_raw=a[:,3]
dssim_minmax_lsm_raw=a[:,4]
dssim_lttb_raw=a[:,5]
n_raw=a[:,6]
n_m4=a[:,7]
n_m4_lsm=a[:,8]
n_minmax=a[:,9]
n_minmax_lsm=a[:,10]
n_lttb=a[:,11]


plt.xticks(fontsize=font)
plt.yticks(fontsize=font)
plt.xlabel("w",fontsize=font)
plt.ylabel("DSSIM",fontsize=font)

plt.xscale("log")
plt.yscale("log")

plt.plot(w,dssim_m4_raw,marker='s',markersize=marker,linewidth=lw)
plt.plot(w,dssim_m4_lsm_raw,marker='X',markersize=marker,linewidth=lw)
plt.plot(w,dssim_minmax_raw,marker='o',markersize=marker,linewidth=lw)
plt.plot(w,dssim_minmax_lsm_raw,marker='^',markersize=marker,linewidth=lw)
plt.plot(w,dssim_lttb_raw,marker='P',markersize=marker,linewidth=lw)

ax1.tick_params(axis='x', pad=20)
plt.title('(a) DSSIM',y=-0.3,fontsize=font)

# plt.figure(1,dpi=120)

# plt.xticks(fontsize=20)
# plt.yticks(fontsize=20)
# plt.xlabel("w",fontsize=20)
# plt.ylabel("number of points",fontsize=20)

# plt.xscale("log")
# plt.yscale("log")

# plt.plot(w,n_m4,label="M4",marker='s',markersize=12,linestyle='--',linewidth=2.5)
# plt.plot(w,n_m4_lsm,label="M4-LSM",marker='X',markersize=12,linewidth=2.5)
# plt.plot(w,n_minmax,label="MinMax",marker='o',markersize=12,linewidth=2.5)
# plt.plot(w,n_minmax,label="MinMax-LSM",marker='^',markersize=12,linewidth=2.5)
# plt.plot(w,n_lttb,label="LTTB",marker='P',markersize=12,linewidth=2.5)
# plt.plot(w,n_raw,label="raw",marker='+',markersize=12,linewidth=2.5)


# --------------------------------------------
plt.sca(ax2)

df=pd.read_csv(query_res)
print(df)

w=df.iloc[:,0]
# M4(ns),M4-LSM(ns),MINMAX(ns),MINMAX_LSM(ns),LTTB(ns)
query_m4=df.iloc[:,2].div(1000000000) # ns to s
query_m4_lsm=df.iloc[:,3].div(1000000000) # ns to s
query_minmax=df.iloc[:,4].div(1000000000) # ns to s
query_minmax_lsm=df.iloc[:,5].div(1000000000) # ns to s
query_lttb=df.iloc[:,6].div(1000000000) # ns to s


plt.xticks(fontsize=font)
plt.yticks(fontsize=font)
plt.xlabel("w",fontsize=font)
plt.ylabel("time (s)",fontsize=font)

plt.xscale("log")
plt.yscale("log")

plt.plot(w,query_m4,marker='s',markersize=marker,linewidth=lw)
plt.plot(w,query_m4_lsm,marker='X',markersize=marker,linewidth=lw)
plt.plot(w,query_minmax,marker='o',markersize=marker,linewidth=lw)
plt.plot(w,query_minmax_lsm,marker='^',markersize=marker,linewidth=lw)
plt.plot(w,query_lttb,marker='P',markersize=marker,linewidth=lw)

ax2.tick_params(axis='x', pad=20)
plt.title('(b) Query time',y=-0.3,fontsize=font)

# --------------------------------------------
labels=["M4","M4-LSM","MinMax","MinMax-LSM","LTTB"]
fig.legend(fontsize=font, labels=labels, ncol=5,bbox_to_anchor=(0.5,1.1), loc='upper center')
fig.savefig("{}/dssim-query-vary-w.eps".format(output),bbox_inches='tight')
fig.savefig("{}/dssim-query-vary-w.png".format(output),bbox_inches='tight')
fig.show()