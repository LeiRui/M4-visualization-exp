from iotdb.Session import Session
from iotdb.utils.IoTDBConstants import TSDataType, TSEncoding, Compressor
from iotdb.utils.Tablet import Tablet

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

def myDeduplicate(seq): # deduplicate list seq by comparing the first element, e.g. l=[(1,1),(1,2)] => l=[(1,1)]
    seen = set()
    seen_add = seen.add
    return [x for x in seq if not (x[0] in seen or seen_add(x[0]))]

# remote node has not exported the environment variables, so passing them using args
parser=argparse.ArgumentParser(description="remote query to csv",
	formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("-r","--read",help="READ_METHOD")
parser.add_argument("-o","--output",help="output directory")
parser.add_argument("-s","--tqs",help="query start time")
parser.add_argument("-e","--tqe",help="query end time")
parser.add_argument("-w","--w",help="number of time spans")
parser.add_argument("-t","--tool",help="export csv tool directory path")
parser.add_argument("-d","--device",help="device")
parser.add_argument("-m","--measurement",help="measurement")
args = parser.parse_args()
config = vars(args)

read_method=str(config.get('read'))
outputDir=str(config.get('output'))
exportToolPath=str(config.get('tool'))
device=str(config.get('device'))
measurement=str(config.get('measurement'))

tqs=int(config.get('tqs'))
tqe=int(config.get('tqe'))
w=int(config.get('w'))
# post-process, make divisible
# note multiple integer of 2w because MinMax need interval/2
interval=math.ceil((tqe-tqs)/(2*w))*2
tqe=tqs+interval*w

# --------------------output path--------------------------
outputCsvPath="{}/data-{}-{}.csv".format(outputDir,read_method,w)
outputFigPath="{}/plot-{}-{}.png".format(outputDir,read_method,w)

# --------------------sql--------------------------
# rawQuery/mac/cpv/minmax/lttb/minmax_lsm
timePrecision = "ns"
if read_method == 'mac': # M4 UDF
	sql="SELECT M4({},'tqs'='{}','tqe'='{}','w'='{}') FROM {} where time>={} and time<{}".\
		format(measurement,tqs,tqe,w,device,tqs,tqe)
elif read_method == 'cpv': # M4-LSM
	sql="select min_time({}), max_time({}), first_value({}), last_value({}), min_value({}), max_value({}) \
		from {} group by ([{}, {}), {}{})".\
		format(measurement,measurement,measurement,measurement,measurement,measurement,\
					 device,tqs,tqe,interval,timePrecision)
elif read_method == "rawQuery":
	sql="select {} from {} where time>={} and time<{}".format(measurement,device,tqs,tqe)
elif read_method == "minmax":
	sql="SELECT MinMax({},'tqs'='{}','tqe'='{}','w'='{}') FROM {} where time>={} and time<{}". \
		format(measurement,tqs,tqe,w*2,device,tqs,tqe)
elif read_method == "lttb":
	sql="SELECT Sample({},'method'='triangle','k'='{}') FROM {} where time>={} and time<{}". \
		format(measurement,4*w,device,tqs,tqe)
elif read_method == "minmax_lsm":
	sql="select min_value({}), max_value({}) \
		from {} group by ([{}, {}), {}{})". \
		format(measurement,measurement,device,tqs,tqe,interval/2,timePrecision)
else:
	print("unsupported read_method!")

print(sql)

# --------------------query--------------------------
if read_method == 'mac' or read_method == 'cpv':
	ip = "127.0.0.1"
	port_ = "6667"
	username_ = "root"
	password_ = "root"
	fetchsize = 100000 # make it big enough to ensure no second fetch, for result.todf_noFetch
	session = Session(ip, port_, username_, password_, fetchsize)
	session.open(False)

	result = session.execute_query_statement(sql) # server execute metrics have been collected by session.execute_finish()

	df = result.todf_noFetch() # Transform to Pandas Dataset
	if read_method == 'mac':
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

		df = pd.DataFrame(ts,columns=['time','value'])
		df.to_csv(outputCsvPath, sep=',',index=False)
	elif read_method == 'cpv':
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
	else:
		print("unsupported read_method!")

	# result = session.execute_finish()
	# print(result) # print metrics from IoTDB server
	session.close()

else: # rawQuery
	os.system("bash {}/export-csv.sh -h 127.0.0.1 -p 6667 -u root -pw root -q '{}' -td {} -tf timestamp".format(exportToolPath,sql,exportToolPath))
	os.system("cp {}/dump0.csv {}".format(exportToolPath,outputCsvPath))


# --------------------plot--------------------------
df = pd.read_csv(outputCsvPath,engine="pyarrow") # the first line is header; use engine="pyarrow" to accelerate read_csv otherwise is slow
convert_dict = {
	df.columns[0]:np.int64,
	df.columns[1]:np.double,
}
df = df.astype(convert_dict)
x=df[df.columns[0]] # time
y=df[df.columns[1]] # value

fig=plt.figure(1,dpi=120)
plt.plot(x,y,linewidth=0.5)
plt.savefig(outputFigPath,bbox_inches='tight') #specify absolute fig path
plt.close(fig)