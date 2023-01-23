clc;clear all;close all;
format long g

dataset=4; %1-ballspeed,2-kob,3-mf03,4-rcvtime
if dataset==1
    M=csvread('D:\github\m4-lsm\M4-visualization-exp\src\main\java\org\apache\iotdb\datasets\BallSpeed.csv');
    x=4232;
elseif dataset==2
    M=csvread('D:\github\m4-lsm\M4-visualization-exp\src\main\java\org\apache\iotdb\datasets\KOB.csv');
    x=4232;
elseif dataset==3
    M=csvread('D:\github\m4-lsm\M4-visualization-exp\src\main\java\org\apache\iotdb\datasets\MF03.csv');
    x=4232;
elseif dataset==4
    M=csvread('D:\github\m4-lsm\M4-visualization-exp\src\main\java\org\apache\iotdb\datasets\RcvTime.csv');
    x=10542;
    x=12741;
end

k=3;
%控制outlier判断宽松程度 >vmean(x)+k*vstd(x)
% k大一点意味着只对time interval大得夸张的时候才进行step向右平移的补偿
% k小一点意味着只要time interval稍微大点就进行step向右平移的补偿

range=100; %模拟一个chunk里的点数
j=1;
for startPos=1:range:length(M)-range+1
    endPos=startPos+range-1;
    T=M(startPos:endPos,1);
    chunkTimestamps(j,:)=T; %chunkTimestamps每行是一个包含range个点的chunk的range个时间戳

    dt=zeros(length(T)-1,1);
    for i=1:1:length(T)-1
        dt(i)=T(i+1)-T(i);
    end
    chunk(j,:)=dt; %chunk每行是一个包含range个点的chunk的range-1个time intervals

    vmedian(j)=median(dt);
    vmad(j)=mad(dt,1);
    vmean(j)=mean(dt);
    vstd(j)=std(dt);

    %type每行是一个包含range个点的chunk的range-1个time intervals的outlier类型判断
    for i=1:1:length(dt)
        if dt(i)>vmean(j)+k*vstd(j)
            type(j,i)=1; % outlier & level
        else
            type(j,i)=0; % non-outlier & tilt
        end
    end

    j=j+1;
end

sum(sum(type)) % outlier intervals的数量
sum(sum(type))/(size(type,1)*size(type,2))*100 % percentage of outliers intervals

%%%%% 现在挑一个chunk进行可视化
%x=randsample(1:size(chunkTimestamps,1),1)
figure, plot(chunkTimestamps(x,:),1:range),
for i=1:1:range-1
    if type(x,i)==0
        hold on,plot(chunkTimestamps(x,i),i,'b+') % non-outlier & tilt
    else
        hold on,plot(chunkTimestamps(x,i),i,'r+') % outlier & level
    end
end
hold on,plot(chunkTimestamps(x,range),range,'g+') % the last point

vmean(x)
vstd(x)
vmedian(x)
vmad(x)

disp('finish')

%%
figure, plot(chunkTimestamps(x,:),1:range),
for i=1:1:range-1
    if intervalsType(i)==0
        hold on,plot(chunkTimestamps(x,i),i,'b+') % non-outlier & tilt
    else
        hold on,plot(chunkTimestamps(x,i),i,'r+') % outlier & level
    end
end
hold on,plot(chunkTimestamps(x,range),range,'g+') % the last point

K=1/vmedian(x);

for i=1:1:length(keys)
    hold on,xline(keys(i))
end

step=(chunkTimestamps(x,100)-chunkTimestamps(x,1))/300;
hold on,plot(chunkTimestamps(x,1):step:chunkTimestamps(x,100),predict2)

y=1:1:range;
max(abs(y-predict))
