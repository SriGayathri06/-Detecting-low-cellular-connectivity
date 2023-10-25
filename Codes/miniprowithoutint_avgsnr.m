%******user association*****
clc;
clear;
prompt='Enter number of users: ';
users=input(prompt);
bs="Enter total number of base stations: ";  
bss=input(bs);
pt_uhf=10;%transmitting power of uhf base station(in watts)
pt_mm=0.1;%transmitting power of mm wave base station(in watts)
a=500;b=20;% max and minimum distance in meters taken as a random number without loss of genrality
n1=4;n2=2;%pathloss exponents
Npower_UHV=(10)^-14;%noise power for uhf bs
Npower_mm=(10)^-10;%noise power for mm wave 
wc=0.33;wdbs=0.33;wsnr=0.33;%weights of parameters in cost function
d_uhf=10^-6;%density of uhf base stations
d_mm=10^-5;%density of uhf base stations
Buhf=20*(10^6);%Hz(bandwidth of uhf bs)
Bmm=500*(10^6);%Hz(bandwidth of mm wave)
q_mm=20;%(quota of each mm wave bs)
q_uhf=15;%(quota of each uhf bs)
rej=double.empty;%declaring rejected list of users as an empty set
ej=double.empty;k=0;%temperory variables used
rejcnt=0;%declaring a variable to store no. of rejected users
index=double.empty;%declaring a variable that stores base station number to which particular UE sent request.
thrpt=0;
%*******************************************************************************
for i=1:users
    for j=1:bss
  %*****generating distances between base stations and users********
       R(i,j)=(a-b).*rand(1,1)+b;
       
       %******SNR calculation at each user********
       
       if j==1%indicates that the bs is UHF bs
           C=Buhf;%channel parameter
           dbs=1;%density of bs
           SNR(i,j)=((pt_uhf*((R(i,j))^(-n1))/Npower_UHV));    
       else%indicates bs is mwbs
           C=Bmm;%channel parameter
           dbs=bss-1;%density of bs
           SNR(i,j)=((pt_mm*((R(i,j))^(-n2))/Npower_mm));  
       end
       %*****cost function for each user*****
       J(i,j)=log2(1+SNR(i,j));
       %J(i,j)=(wc*C)+(wdbs*dbs)+(wsnr*SNR(i,j)); 
    end
end
%****finding argmax of cost functions & storing them*********
for i=1:users
    temp=J(i,:);
    [argvalue,k]=max(temp);
    if k==0
        index=k;
    else
        index=[index k];%index contains base station numbers as elements of array & their indices represent users.
    end
end
%***********counting number of requests for each base station*************
bsn=sort(unique(index));
cnt=zeros(1,length(bsn));%temperory variable
for i1=1:length(index)
    c=0;
    for j=1:length(bsn)
        if index(i1)==bsn(j)
            c=c+1;
            if cnt(1,j)==0
                cnt(1,j)=c;
            else
                cnt(1,j)=cnt(1,j)+c;
            end
        else
            c=0;
        end
    end
end
%******downlink data rates of each bs at the user******
for i=1:users
    for j=1:bss
        if j==1
            dldr(i,j)=Buhf.*(log2(1+SNR(i,j)));
        else
            dldr(i,j)=Bmm.*(log2(1+SNR(i,j)));
        end
    end
end
 %******** association and rejection list*************
x=double.empty;%temperory variable
cc=double.empty;
 
%**** storing datarates offered by bs to UE that sent request in 'x'*******
for i=1:bss
    for j=1:length(index)
        if i==index(j)
            x(i,end+1)=dldr(j,i);   
        end
    end
end
%**********%prioritizing datarates stored in x**********
[xs,indices]=sort(x,2,'descend'); 
%'indices' stores the prioritized users (datarates offered by i th bs are arranged in decsending order)
%'xs'  stores the prioritized value of datarate
 
%***counting no. of requests to each bs and rejecting users based on quota of each bs***
for i=1:bss
    count=0;
    for j=1:users
        if i==1
            if xs(i,j)~=0
                if count<q_uhf
                for m=1:users  
                    for n=1:bss
                        if xs(i,j)==dldr(m,n)
                            %fprintf('UE %d is connected to UHF base station %d\n',m,i);
                            count=count+1;
                            thrpt=thrpt+dldr(m,n);
                        end
                    end
                end
                else
                    for m=1:users  
                    for n=1:bss
                        if xs(i,j)==dldr(m,n)
                            ej=m;
                            rej=[rej ej];
                            %fprintf('UE %d is rejected by UHF base station %d\n',m,i);
                        end
                    end
                    end
                end
            end
        else
            if xs(i,j)~=0
                if count<q_mm
                    for m=1:users
                        for n=1:bss
                            if xs(i,j)==dldr(m,n)
                                %fprintf('UE %d is connected to mmWave base station %d\n',m,i);
                                count=count+1;
                                thrpt=thrpt+dldr(m,n);
                            end
                        end
                    end   
                else
                    for m=1:users  
                        for n=1:bss
                            if xs(i,j)==dldr(m,n)
                                ej=m;
                                rej=[rej ej];
                                %fprintf('UE %d is REJECTED by mmWave base station %d\n',m,i);
                            end
                        end
                    end
                end
            end
        end
    end
    cc(end+1)=count;
end    
tmbs=4.7;
tmm=8.0;
sp_uhf=130;
sp_mm=4.8;
td=0.8;
pc_mbs=(pt_uhf*tmbs*td)+(sp_uhf*td);
pc_mm=(pt_mm*tmm*td)+(sp_mm*td);
EE=(thrpt)/(((1)*(pc_mbs))+((bss-1)*(pc_mm)));
rejcnt=length(rej);
% figure(1);
% title('REJECTED USERS');
% xlabel('NO. OF USERS--->');
% ylabel('NO. OF REJECTED USERS----->');
% stem(users,rejcnt);
% hold on;
for j=1:length(cc)
   fprintf('no of users connected to base station %d are : %d\n',j,cc(j));
end
figure(2);
title('SYS THRPT');
xlabel('NO. OF USERS--->');
ylabel('Sys Thrpt----->');
scatter(users,thrpt);
hold on;
% figure(3);
% title('Energy Efficiency');
% xlabel('NO. OF USERS--->');
% ylabel('EE----->');
% scatter(users,EE);
% hold on;

