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

parser=argparse.ArgumentParser(description="plot and compute DSSIM",
                               formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("-i","--input",help="input csv directory")
args = parser.parse_args()
config = vars(args)
home_path=str(config.get('input'))
# home_path="D:\github\mid"
print(home_path)

def full_frame(width=None, height=None, dpi=None):
  import matplotlib as mpl
  # First we remove any padding from the edges of the figure when saved by savefig.
  # This is important for both savefig() and show(). Without this argument there is 0.1 inches of padding on the edges by default.
  mpl.rcParams['savefig.pad_inches'] = 0
  figsize = None if width is None else (width/dpi, height/dpi) # so as to control pixel size exactly
  fig = plt.figure(figsize=figsize,dpi=dpi)
  # Then we set up our axes (the plot region, or the area in which we plot things).
  # Usually there is a thin border drawn around the axes, but we turn it off with `frameon=False`.
  ax = plt.axes([0,0,1,1], frameon=False)
  # Then we disable our xaxis and yaxis completely. If we just say plt.axis('off'),
  # they are still used in the computation of the image padding.
  ax.get_xaxis().set_visible(False)
  ax.get_yaxis().set_visible(False)
  # Even though our axes (plot region) are set to cover the whole image with [0,0,1,1],
  # by default they leave padding between the plotted data and the frame. We use tigher=True
  # to make sure the data gets scaled to the full extents of the axes.
  plt.autoscale(tight=True)

def myplot(csvPath,width,anti,lw):
  height=width
  full_frame(width,height,16)
  df=pd.read_csv(csvPath,engine="pyarrow") # the first line is header; use engine="pyarrow" to accelerate read_csv otherwise is slow
  t=df.iloc[:,0]
  v=df.iloc[:,1]

  v_min=min(v)
  v_max=max(v)

  t_min=511996 # BallSpeed dataset, corresponds to tqs in run-python-query-save-exp.sh
  t_max_temp=4259092178974 # BallSpeed dataset, corresponds to tqe in run-python-query-save-exp.sh
  t_max=math.ceil((t_max_temp-t_min)/(2*width))*2*width+t_min # corresponds to tqe in query-save.py

  plt.plot(t,v,color='k',linewidth=lw,antialiased=anti)
  plt.xlim(t_min, t_max)
  plt.ylim(v_min, v_max)
  plt.savefig("{}-{}.png".format(csvPath,width),backend='agg')
  # plt.show()
  plt.close()
  return df.shape[0] # number of points

def mymse(imfil1,imfil2): # mse=mse_in_255/(255*255)
  img1 = cv2.imread(imfil1)
  img2 = cv2.imread(imfil2)
  img1 = img_as_float(cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY))
  img2 = img_as_float(cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY))
  squared_diff = (img1-img2) ** 2
  summed = np.sum(squared_diff)
  num_pix = img1.shape[0] * img1.shape[1] #img1 and 2 should have same shape
  err = summed / num_pix
  return err

def myssim(imfil1,imfil2):
  img1=cv2.imread(imfil1)
  (h,w)=img1.shape[:2]
  img2=cv2.imread(imfil2)
  resized=cv2.resize(img2,(w,h))
  (h1,w1)=resized.shape[:2]
  # print(img1.dtype)
  img1=img_as_float(cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)) # img_as_float: the dtype is uint8, means convert [0, 255] to [0, 1]
  img2=img_as_float(cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY))
  return ssim(img1,img2)

def mydssim(imfil1,imfil2):
  return (1-myssim(imfil1,imfil2))/2

output="{}/dssim.csv".format(home_path)
# wArray = [10,20,50,100,200,400,800,1200,1600,2000,3000,4000]
wArray = [10,50]
with open(output, 'w', newline='') as f:
  writer = csv.writer(f)
  header = ['w', 'DSSIM(M4,raw)', 'DSSIM(M4-LSM,raw)', 'DSSIM(MinMax,raw)','DSSIM(LTTB,raw)','n_raw','n_m4','n_m4_lsm','n_minmax','n_lttb']
  writer.writerow(header)
  for w in wArray:
    # plot figure according to specified w
    n_raw=myplot("{}/data-rawQuery-1.csv".format(home_path),w,False,0.1)
    n_m4=myplot("{}/data-mac-{}.csv".format(home_path,w),w,False,0.1)
    n_m4_lsm=myplot("{}/data-cpv-{}.csv".format(home_path,w),w,False,0.1)
    n_minmax=myplot("{}/data-minmax-{}.csv".format(home_path,w),w,False,0.1)
    n_lttb=myplot("{}/data-lttb-{}.csv".format(home_path,w),w,False,0.1)

    # compute dssim
    data=[
      w,
      mydssim("{}/data-rawQuery-1.csv-{}.png".format(home_path,w),"{}/data-mac-{}.csv-{}.png".format(home_path,w,w)),
      mydssim("{}/data-rawQuery-1.csv-{}.png".format(home_path,w),"{}/data-cpv-{}.csv-{}.png".format(home_path,w,w)),
      mydssim("{}/data-rawQuery-1.csv-{}.png".format(home_path,w),"{}/data-minmax-{}.csv-{}.png".format(home_path,w,w)),
      mydssim("{}/data-rawQuery-1.csv-{}.png".format(home_path,w),"{}/data-lttb-{}.csv-{}.png".format(home_path,w,w)),
      n_raw,n_m4,n_m4_lsm,n_minmax,n_lttb
    ]
    writer.writerow(data)

# plot dssim res
with open(output,"r") as i:
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
dssim_lttb_raw=a[:,4]
n_raw=a[:,5]
n_m4=a[:,6]
n_m4_lsm=a[:,7]
n_minmax=a[:,8]
n_lttb=a[:,9]

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
plt.plot(w,dssim_lttb_raw,label="LTTB",marker='P',markersize=12,linewidth=2.5)

# plt.plot(x,python,label="Python",marker='o',markersize=15,linewidth=2.5,color='red') #0
# plt.plot(x,grafana,label="Grafana",marker='P',markersize=15,linewidth=2.5,color='#9467bd') #1
# plt.plot(x,grafanaM4,label="Grafana with M4-LSM",marker='s',markersize=15,linewidth=2.5,color='green') #2
# plt.plot(x,pythonM4,label="Python with M4-LSM",marker='X',markersize=15,linewidth=2.5,color='#ff7f0e') #3

#plt.legend(ncol=3,fontsize=20,bbox_to_anchor=(0.5,1.20), loc='upper center');
plt.legend(fontsize=20);
plt.savefig("{}/dssim-vary-w.eps".format(home_path),bbox_inches='tight')
plt.savefig("{}/dssim-vary-w.png".format(home_path),bbox_inches='tight')
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
plt.plot(w,n_lttb,label="LTTB",marker='P',markersize=12,linewidth=2.5)
plt.plot(w,n_raw,label="raw",marker='+',markersize=12,linewidth=2.5)

# plt.plot(x,python,label="Python",marker='o',markersize=15,linewidth=2.5,color='red') #0
# plt.plot(x,grafana,label="Grafana",marker='P',markersize=15,linewidth=2.5,color='#9467bd') #1
# plt.plot(x,grafanaM4,label="Grafana with M4-LSM",marker='s',markersize=15,linewidth=2.5,color='green') #2
# plt.plot(x,pythonM4,label="Python with M4-LSM",marker='X',markersize=15,linewidth=2.5,color='#ff7f0e') #3

#plt.legend(ncol=3,fontsize=20,bbox_to_anchor=(0.5,1.20), loc='upper center');
plt.legend(fontsize=20);
plt.savefig("{}/n-vary-w.eps".format(home_path),bbox_inches='tight')
plt.savefig("{}/n-vary-w.png".format(home_path),bbox_inches='tight')
plt.show()
plt.close()

