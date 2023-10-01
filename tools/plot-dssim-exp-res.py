from skimage import data, img_as_float
from skimage.metrics import structural_similarity as ssim
from skimage.metrics import mean_squared_error
import csv
import cv2
from matplotlib import pyplot as plt
import numpy as np
import pandas as pd
import math
import argparse

parser=argparse.ArgumentParser(description="plot query exp result",
                               formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("-i","--input",help="input result csv path")
parser.add_argument("-o","--output",help="output directory")
args = parser.parse_args()
config = vars(args)
res=str(config.get('input'))
print(res)

output=str(config.get('output'))

# plot dssim res
with open(res,"r") as i:
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

plt.figure(1,dpi=120)

plt.xticks(fontsize=20)
plt.yticks(fontsize=20)
plt.xlabel("w",fontsize=20)
plt.ylabel("DSSIM",fontsize=20)

plt.xscale("log")
plt.yscale("log")

plt.plot(w,dssim_m4_raw,label="M4",marker='s',markersize=12,linewidth=2.5)
plt.plot(w,dssim_m4_lsm_raw,label="M4-LSM",marker='X',markersize=12,linewidth=2.5)
plt.plot(w,dssim_minmax_raw,label="MinMax",marker='o',markersize=12,linewidth=2.5)
plt.plot(w,dssim_minmax_raw,label="MinMax-LSM",marker='^',markersize=12,linewidth=2.5)
plt.plot(w,dssim_lttb_raw,label="LTTB",marker='P',markersize=12,linewidth=2.5)

# plt.plot(x,python,label="Python",marker='o',markersize=15,linewidth=2.5,color='red') #0
# plt.plot(x,grafana,label="Grafana",marker='P',markersize=15,linewidth=2.5,color='#9467bd') #1
# plt.plot(x,grafanaM4,label="Grafana with M4-LSM",marker='s',markersize=15,linewidth=2.5,color='green') #2
# plt.plot(x,pythonM4,label="Python with M4-LSM",marker='X',markersize=15,linewidth=2.5,color='#ff7f0e') #3

#plt.legend(ncol=3,fontsize=20,bbox_to_anchor=(0.5,1.20), loc='upper center');
plt.legend(fontsize=20);
plt.savefig("{}/dssim-vary-w.eps".format(output),bbox_inches='tight')
plt.savefig("{}/dssim-vary-w.png".format(output),bbox_inches='tight')
plt.show()
plt.close()

plt.figure(1,dpi=120)

plt.xticks(fontsize=20)
plt.yticks(fontsize=20)
plt.xlabel("w",fontsize=20)
plt.ylabel("number of points",fontsize=20)

plt.xscale("log")
plt.yscale("log")

plt.plot(w,n_m4,label="M4",marker='s',markersize=12,linestyle='--',linewidth=2.5)
plt.plot(w,n_m4_lsm,label="M4-LSM",marker='X',markersize=12,linewidth=2.5)
plt.plot(w,n_minmax,label="MinMax",marker='o',markersize=12,linewidth=2.5)
plt.plot(w,n_minmax,label="MinMax-LSM",marker='^',markersize=12,linewidth=2.5)
plt.plot(w,n_lttb,label="LTTB",marker='P',markersize=12,linewidth=2.5)
plt.plot(w,n_raw,label="raw",marker='+',markersize=12,linewidth=2.5)

# plt.plot(x,python,label="Python",marker='o',markersize=15,linewidth=2.5,color='red') #0
# plt.plot(x,grafana,label="Grafana",marker='P',markersize=15,linewidth=2.5,color='#9467bd') #1
# plt.plot(x,grafanaM4,label="Grafana with M4-LSM",marker='s',markersize=15,linewidth=2.5,color='green') #2
# plt.plot(x,pythonM4,label="Python with M4-LSM",marker='X',markersize=15,linewidth=2.5,color='#ff7f0e') #3

#plt.legend(ncol=3,fontsize=20,bbox_to_anchor=(0.5,1.20), loc='upper center');
plt.legend(fontsize=20);
plt.savefig("{}/n-vary-w.eps".format(output),bbox_inches='tight')
plt.savefig("{}/n-vary-w.png".format(output),bbox_inches='tight')
plt.show()
plt.close()