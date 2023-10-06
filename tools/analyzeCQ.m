clear all;close all;clc
format long g
filename = 'D:\\github\\mid\\dataset_with_updates\\d1.xlsx';
sheet = 1;
[data,text] = xlsread(filename,sheet);

S_arrivalTime=data(:,1); % sorted by this
C_sendTime=data(:,12);

S_sendTime=data(:,16);
C_arrivalTime=data(:,13);

durationMetric=data(:,17);

deviceID=text(2:end,4);
seqID=data(:,4);

tmp=find(strcmp(deviceID, 'dev_15'));
S_arrivalTime=S_arrivalTime(tmp); 
C_sendTime=C_sendTime(tmp);
S_sendTime=S_sendTime(tmp); 
C_arrivalTime=C_arrivalTime(tmp);

%figure,plot(S_arrivalTime(1:100),C_sendTime(1:100))
%figure,plot(C_arrivalTime(1:100),S_sendTime(1:100))

% sort by arrivalTime
% tmp=[C_arrivalTime,S_sendTime];
tmp=[S_arrivalTime,C_sendTime];
tmp=sortrows(tmp,1);
arrivalTime=tmp(:,1);
sendTime=tmp(:,2);
figure,plot(arrivalTime(1:1000),sendTime(1:1000))

% make some observations
a=diff(arrivalTime);
median(a); % 41ms
b=diff(sendTime);
median(b); % 58ms

% set continuous query parameters
step=100*50; % 5s
k_factor=2; % look back 10s
lookBack=k_factor*step;% so most of the groups will be computed k_factor times. now()-10s ~ now()
group=step; % 5s

startRightEnd=arrivalTime(40);
res_t=[];
res_v=[];
i=1;
while true
    x2=startRightEnd+(i-1)*step;
    if x2>arrivalTime(end)
        break
    end
    x1=x2-lookBack;
    sumRes=zeros(1,k_factor);
    cntRes=zeros(1,k_factor);
    for j=1:1:length(arrivalTime)
        % find all points with arrivalTime smaller than x2
        if arrivalTime(j)>=x2
            break
        end
        % group points by their sendTime
        for k=1:1:k_factor 
            tmp1=x1+(k-1)*group;
            tmp2=x1+k*group;
            if sendTime(j)>=tmp1 && sendTime(j)<tmp2
                sumRes(k)=sumRes(k)+durationMetric(j);
                cntRes(k)=cntRes(k)+1;
            end
        end
    end
    % record results for this moment
    for k=1:1:k_factor
        tmp1=x1+(k-1)*group;
        res_t=[res_t;tmp1];
        res_v=[res_v;sumRes(k)/cntRes(k)];
    end
    i=i+1;
end
figure,scatter(res_t,res_v,'MarkerFaceColor','r','MarkerEdgeColor','r',...
    'MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2)
xlabel('t')
ylabel('v')
%saveas(gcf,'scatter_plot_showing_updates.png')

M=[res_t,res_v];
fid = fopen('result.csv','wt');
fprintf(fid, '%s,%s\n', 'Time','Value');  % header
dlmwrite('result.csv',M,'precision',20)
fclose(fid);

for i=1:1:length(M)
    tmp=M(find(M(:,1)==M(i,1)),2);
    tmp2=diff(tmp);
    tmp2=tmp2(~isnan(tmp2));
    if length(find(tmp2~=0))>1 % except 2nd different from 1st
        disp(i)
    end
end
