%******user association*****
clc;
clear;
prompt='Enter number of users: ';
users=input(prompt);
bs="Enter number of base stations: ";
bss=input(bs);
bsss=1:bss;
pt_uhf=10;%transmitting power of uhf base station(in watts)
pt_mm=1;%transmitting power of mm wave base station(in watts)
a=700;b=10;% max and minimum distance in meters.
n1=4;n2=2;%pathloss exponents
Npower_UHV=(10)^-14;%noise ower for uhf bs
Npower_mm=(10)^-10;%noise power for mm wave 
wc=0.33;
wdbs=0.33;
wsnr=0.33;
d_uhf=10^-6;%density of uhf base stations
d_mm=10^-3;%density of uhf base stations
Buhf=20*(10^6);%Hz(bandwidth of uhf bs)
Bmm=10^9;%Hz(bandwidth of mm wave)
q_mm=20;%(quota of each mm wave bs)
q_uhf=15;%(quota of each uhf bs)
rej=double.empty;
ej=0;k=0;
index=double.empty;
for i=1:users
    for j=1:bss
  %*****generating distances between base stations and users********
       R(i,j)=(a-b).*rand(1,1)+b;
       
       %******SNR calculation at each user********
       
       if j<=2
           C=Buhf;
           dbs=d_uhf;
           SNR(i,j)=(pt_uhf*((R(i,j))^(-n1))/Npower_UHV);    
       else
           C=Bmm;
           dbs=d_mm;
           SNR(i,j)=(pt_mm*((R(i,j))^(-n2))/Npower_mm);  
       end
       %*****cost function for each user*****
       J(i,j)=(wc*C)+(wdbs*dbs)+(wsnr*SNR(i,j)); 
    end
end
%****finding argmax of cost functions & storing them*********
for i=1:users
    temp=J(i,:);
    [argvalue,k]=max(temp);
    if k==0
        index=k;
    else
        index=[index k];%index contains base station numbers as elements &
        % their indices represent users.
    end
end
%***********counting number of requests for each base station*************
bsn=sort(unique(index));
cnt=zeros(1,length(bsn));
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
            %break;
        else
            c=0;
        end
    end
end
%******downlink data rates of each bs at the user******
for i=1:users
    for j=1:bss
        if j<=2
            dldr(i,j)=Buhf.*(log2(1+SNR(i,j)));
        else
            dldr(i,j)=Bmm.*(log2(1+SNR(i,j)));
        end
    end
end
% %******** association and rejection list*************
x=double.empty;
cc=double.empty;
for i=1:bss
    for j=1:length(index)
        if i==index(j)
            x(i,end+1)=dldr(j,i);   
        end
    end
end
[xs,indices]=sort(x,2,'descend');
for i=1:bss
    count=0;
    for j=1:users
        if i<=2
            if xs(i,j)~=0
                if count<q_uhf
                for m=1:users  
                    for n=1:bss
                        if xs(i,j)==dldr(m,n)
                            fprintf('UE %d is connected to UHF base station %d\n',m,i);
                            count=count+1;
                        end
                    end
                end
                else
                    for m=1:users  
                    for n=1:bss
                        if xs(i,j)==dldr(m,n)
                            rej(i,end+1)=m;
                            fprintf('UE %d is rejected by UHF base station %d\n',m,i);
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
                                fprintf('UE %d is connected to mmWave base station %d\n',m,i);
                                count=count+1;
                            end
                        end
                    end   
                else
                    for m=1:users  
                        for n=1:bss
                            if xs(i,j)==dldr(m,n)
                                %rej(i,end+1)=m;
                                ej=m;
                                rej=[rej ej];
                                fprintf('UE %d is REJECTED by mmWave base station %d\n',m,i);
                            end
                        end
                    end
                end
            end
        end
    end
    cc(end+1)=count;
end    
for j=1:length(cc)
    fprintf('no of users connected to base station %d are : %d\n',j,cc(j));
end
