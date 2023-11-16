% QPSK���ƽ���������̷���(��costas��·�˲�, ��Ҫ���������ز����ó�������ʱ����Խϳ�)
% ����costas loop�Ļ������̷���ű���� qpsk_modem_basic.m
clear all;                  % ������б���
close all;                  % �ر����д���
clc;                        % ����
%% ��������
M=240;                      % ������Ԫ��    
L=100;                      % ÿ����Ԫ��������
fc=50e3;                    % �ز�Ƶ��50kHz 
% flocal = 50010;           % ���ն˵ı����ز�Ƶ��
flocal = 50100;             % ģ����ն��ز�Ƶ�ʲ�ͬ�������
Rb =10e3;                   % ��Ԫ����                   
Ts=1/Rb;                    % ��Ԫ�ĳ���ʱ��
dt=Ts/L;                    % �������
TotalT=M*Ts;                % ��ʱ��
t=0:dt:TotalT-dt;           % ʱ��
Fs=L*Rb;                    % ����Ƶ��
C1 = 2^(-4);                % costas���˲���ϵ��c1
C2 = C1 * 2^(-3);           % costas���˲���ϵ��c2


%% �����ź�Դ
wave=randi([0,1],1,M);      % ��������ź�
%֡ͷoxcc,23ʱ24��25���һ�����ݰ������һ�ֽ�ΪУ���
%wave=[1 1 0 0 1 1 0 0 0 0 0 1 0 1 1 1 0 0 0 1 1 0 0 0 0 0 0 1 1 0 0 1 0 0 0 1 0 1 0 0];
wave=2*wave-1;              % �����Ա�˫����
fz=ones(1,L);               % ���帴�ƵĴ���L,LΪÿ��Ԫ�Ĳ�������
x1=wave(fz,:);              % ��ԭ��wave�ĵ�һ�и���L�Σ���ΪL*M�ľ���
baseband=reshape(x1,1,L*M); % ����˫���Բ�����������岨�Σ����յõ���L*M���󣬰������������γ�1*(L*M)�ľ���

%% I��Q·��Ԫ
% I·��Ԫ�ǻ�����Ԫ������λ����Ԫ��Q·��Ԫ�ǻ�����Ԫ��ż��λ����Ԫ
I=[]; Q=[];
for i=1:M
    if mod(i, 2)~=0
        I = [I, wave(i)];
    else
        Q = [Q, wave(i)];
    end
end
fz2 = ones(1,2*L);
x2 = I(fz2,:);               % ��ԭ��I�ĵ�һ�и���2L�Σ���Ϊ2L*(M/2)�ľ���
I_signal = reshape(x2,1,L*M);% ���յõ���L*(M/2)���󣬰������������γ�1*(L*M)�ľ���
x3 = Q(fz2,:);               % ��ԭ��Q�ĵ�һ�и���2L�Σ���Ϊ2L*(M/2)�ľ���
Q_signal = reshape(x3,1,L*M);% ���յõ���L*(M/2)���󣬰������������γ�1*(L*M)�ľ���


%% �����˲�
% ͨ��Filter Designer������40��(41����ͷϵ��)��������ƽ�����˲���rcosfilter
% ����Ƶ��ΪFs,��ֹƵ��ΪRb/2
Q_filtered = filter(rcosfilter,Q_signal);   %Q·�����˲�
I_filtered = filter(rcosfilter,I_signal);   %I·�����˲�
Q_filtered = double(Q_filtered);
I_filtered = double(I_filtered);
%% QPSK����      
carry_cos=cos(2*pi*fc*t);        % �ز�1
psk1=I_filtered.*carry_cos;        % PSK1�ĵ���
carry_sin=sin(2*pi*fc*t);        % �ز�2
psk2=Q_filtered.*carry_sin;        % PSK1�ĵ���
qpsk=psk1+psk2;                 % QPSK��ʵ��
%% �źž�����˹�������ŵ�
%qpsk_n = qpsk;              %������
qpsk_n=awgn(qpsk,20);       % �ź�qpsk�м���������������ΪSNR=20dB

%% �������
err_phase = zeros(1,length(t));
phase_ctrl= zeros(1,length(t));
carry_cos_local = zeros(1, length(t));
carry_sin_local = zeros(1, length(t));
demo_I = zeros(1, length(t));
demo_Q = zeros(1, length(t));
filtered_I = zeros(1, length(t));
filtered_Q = zeros(1, length(t));
pd_I = zeros(1, length(t));
pd_Q = zeros(1, length(t));
inv_Q = zeros(1, length(t));
inv_I = zeros(1, length(t));
%% �ز�ͬ�����±�Ƶ
for i = 1:length(t)
    carry_cos_local(i) = cos(2*pi*flocal*t(i)-err_phase(i));  % �����ز�����λ������err_phase����
    carry_sin_local(i) = sin(2*pi*flocal*t(i)-err_phase(i));  % �����ز�����λ������err_phase����
    % ���ÿɵ���Ƶ�ʵı����ز���QPSK�ź����
    demo_I(i)=qpsk_n(i)*carry_cos_local(i);         % ��ɽ�������Ա�������ز�
    demo_Q(i)=qpsk_n(i)*carry_sin_local(i);  
    %��ͨ�˲�
    filtered_Q = double(filter(demo_lowpass,demo_Q));   %Q·��ͨ�˲�
    filtered_I = double(filter(demo_lowpass,demo_I));   %I·��ͨ�˲�
    % ��ͨ�˲�������ز�ͬ�����࣬ģ��costas��������
    inv_Q(i) = -1*filtered_Q(i);
    inv_I(i) = -1*filtered_I(i);

    % ����I·����ѡ��I·����˵ļ���ֵ
    if filtered_I(i)>=0 
        pd_I(i) = filtered_Q(i);
    else 
        pd_I(i) = inv_Q(i);
    end
    
%     ind = find(filtered_I>=0);
%     pd_I(ind) = filtered_Q(ind); 
%     ind = find(filtered_I<0);
%     pd_I(ind) = inv_Q(ind);


    %����Q·����ѡ��Q·����˵ļ���ֵ
    if filtered_Q(i)>=0 
        pd_Q(i) = filtered_I(i);
    else 
        pd_Q(i) = inv_I(i);
    end

    % ������ԭʼ���(δ�˲�)
    pd(i) = pd_I(i) - pd_Q(i);
    
    %�����������·�˲�
    if i==1
         err_phase(i+1) = C1*pd(i);  
    elseif i ~= length(t)
         err_phase(i+1) = err_phase(i) + C1*pd(i)+(C2-C1)*pd(i-1);  
    end
    
%     ind = find(filtered_Q>=0);
%     pd_Q(ind) = filtered_I(ind);
%     ind = find(filtered_Q<0);
%     pd_Q(ind) = inv_I(ind);
    
end



% err_phase(1) = C1*pd(1); % �˲������������һ��������һ����
% for i=2:length(t)
%     err_phase(i) = err_phase(i-1) + C1*pd(i)+(C2-C1)*pd(i-1);
% end
%% �����о�
k=0;                        % ���ó�����ֵ
sample_d_I=1*(filtered_I>k);     % �˲����������ÿ��Ԫ�غ�0���бȽϣ�����0Ϊ1������Ϊ0
sample_d_Q=1*(filtered_Q>k);      % �˲����������ÿ��Ԫ�غ�0���бȽϣ�����0Ϊ1������Ϊ0

%% I��Q·�ϲ�
I_comb = [];
Q_comb = [];
% ȡ��Ԫ���м�λ���ϵ�ֵ�����о�
for j=L:2*L:(L*M)
    if sample_d_I(j)>0
        I_comb=[I_comb,1];
    else
        I_comb=[I_comb,-1];
    end
end
% ȡ��Ԫ���м�λ���ϵ�ֵ�����о�
for k=L:2*L:(L*M)
    if sample_d_Q(k)>0
        Q_comb=[Q_comb,1];
    else
        Q_comb=[Q_comb,-1];
    end
end
code = [];
% ��I·��ԪΪ�������������λ����Ԫ����Q·��ԪΪ���������ż��λ����Ԫ
for n=1:M
    if mod(n, 2)~=0
        code = [code, I_comb((n+1)/2)];
    else
        code = [code, Q_comb(n/2)];
    end
end

x4=code(fz,:);             % ��ԭ��code�ĵ�һ�и���L�Σ���ΪL*M�ľ���
dout=reshape(x4,1,L*M);    % ���������Բ�����������岨�Σ����յõ���L*M���󣬰������������γ�1*(L*M)�ľ���

%% ����ԭʼ�ź�
figure();                   
subplot(311);                   % ���ڷָ��3*1�ģ���ǰ�ǵ�1����ͼ 
plot(t,baseband,'LineWidth',2); % ���ƻ�����Ԫ���Σ��߿�Ϊ2
title('�����źŲ���');      
xlabel('ʱ��/s');           
ylabel('����');            

subplot(312);                   % ���ڷָ��3*1�ģ���ǰ�ǵ�2����ͼ 
plot(t,I_signal,'LineWidth',2); % ���ƻ�����Ԫ���Σ��߿�Ϊ2
title('I·�źŲ���');       
xlabel('ʱ��/s');           
ylabel('����');             

subplot(313);                   % ���ڷָ��3*1�ģ���ǰ�ǵ�3����ͼ 
plot(t,Q_signal,'LineWidth',2); % ���ƻ�����Ԫ���Σ��߿�Ϊ2
title('Q·�źŲ���');            % ����
xlabel('ʱ��/s');                % x���ǩ
ylabel('����');                   % y���ǩ
axis([0,TotalT,-1.1,1.1])       % ���귶Χ����


%% ���Ƴ����˲����ź�
figure();                  
subplot(211);                
plot(t,Q_filtered,'LineWidth',2);% ���Ƴ����˲���Q·�ź�
title('�����˲���Q·����');      % ����
xlabel('ʱ��/s');           % x���ǩ
ylabel('����');             % y���ǩ
axis([0,TotalT,-1,1]);      % �������귶Χ
              
subplot(212);                
plot(t,I_filtered,'LineWidth',2);% ���Ƴ����˲���I·�ź�
title('�����˲���I·����');      % ����
xlabel('ʱ��/s');           % x���ǩ
ylabel('����');             % y���ǩ
axis([0,TotalT,-1,1]);      % �������귶Χ

%% ����QPSK�����ź��Լ�������ź�
figure();                  
subplot(211);                
plot(t,qpsk,'LineWidth',2); % ���ƻ�����Ԫ���Σ��߿�Ϊ2
title('QPSK�źŲ���');      % ����
xlabel('ʱ��/s');           % x���ǩ
ylabel('����');             % y���ǩ
axis([0,TotalT,-1,1]);      % �������귶Χ
subplot(212);               % ���ڷָ��2*1�ģ���ǰ�ǵ�2����ͼ 
plot(t,qpsk_n,'LineWidth',2);  % ����QPSK�źż���������Ĳ���
axis([0,TotalT,-1,1]);      % �������귶Χ
title('ͨ����˹�������ŵ�����ź�');% ����
xlabel('ʱ��/s');           % x���ǩ
ylabel('����');             % y���ǩ

%% ���ƻ���IQ��·���Ա�������ز�����ź�
figure();     
subplot(211)                             % ���ڷָ��2*1�ģ���ǰ�ǵ�1����ͼ 
plot(t,demo_I,'LineWidth',2)             % ����I·��������ز�����ź�
axis([0,TotalT,-1,1]);                   % �������귶Χ
title("I·��������ز�����ź�")          % ����
xlabel('ʱ��/s');                        % x���ǩ
ylabel('����');                          % y���ǩ

subplot(212)                            % ���ڷָ��2*1�ģ���ǰ�ǵ�2����ͼ 
plot(t,demo_Q,'LineWidth',2)            % ����Q·��������ز�����ź�
axis([0,TotalT,-1,1]);                  % �������귶Χ
title("Q·��������ز�����ź�")         % ����
xlabel('ʱ��/s');                       % x���ǩ
ylabel('����');                         % y���ǩ
%% ���Ƽ��������
figure();   
subplot(311)                             
plot(t,pd,'LineWidth',2)                
title("������������");                 % ����
xlabel('ʱ��/s');                        % x���ǩ
ylabel('����');                          % y���ǩ

subplot(312)                            
plot(t,pd_I,'LineWidth',2)            
title("I·����������");         
xlabel('ʱ��/s');                        % x���ǩ
ylabel('����');                          % y���ǩ

subplot(313)                             
plot(t,pd_Q,'LineWidth',2)         
title("I·����������");            
xlabel('ʱ��/s');                        % x���ǩ
ylabel('����');                          % y���ǩ

% %% �ز�ͬ�����������չʾ
% figure();   
% subplot(411)                             
% plot(t,filtered_I,'LineWidth',2)     % ����I·��������ز�����ź�
% title("I·");                 % ����
% xlabel('ʱ��/s');                        % x���ǩ
% ylabel('����');                          % y���ǩ
% 
% subplot(413)                            
% plot(t,filtered_Q,'LineWidth',2)          % �����ز�ͬ����·�˲������
% title("Q·");         
% xlabel('ʱ��/s');                        % x���ǩ
% ylabel('����');                          % y���ǩ
% 
% subplot(414)                            
% plot(t,pd_Q,'LineWidth',2)          % �����ز�ͬ����·�˲������
% title("������Q·");         
% xlabel('ʱ��/s');                        % x���ǩ
% ylabel('����');                          % y���ǩ
% 
% subplot(412)                            
% plot(t,pd_I,'LineWidth',2)          % �����ز�ͬ����·�˲������
% title("������I·");         
% xlabel('ʱ��/s');                        % x���ǩ
% ylabel('����');                          % y���ǩ
%% �ز�ͬ�����������չʾ
figure();   
subplot(211)                             
plot(t,pd,'LineWidth',2)     % ����I·��������ز�����ź�
title("������������");                 % ����
xlabel('ʱ��/s');                        % x���ǩ
ylabel('����');                          % y���ǩ

subplot(212)                            
plot(t,err_phase,'LineWidth',2)          % �����ز�ͬ����·�˲������
title("�ز�ͬ����·�˲������");         
xlabel('ʱ��/s');                        % x���ǩ
ylabel('����');                          % y���ǩ

%% ��ͼ�Ƚϱ����ز��ͷ��Ͷ��ز�
figure()
nop=300;     %�������ݺܶ࣬Ϊ�˱��ڹ۲�ѡȡǰnop����л�ͼ
start=1000;  %��ʼ�۲�ĵ������
subplot(211) % ���ڷָ��2*1�ģ���ǰ�ǵ�1����ͼ 
% ���������ز�
plot(t(start+1:start+nop),carry_sin(start+1:start+nop),'LineWidth',2)          
hold on
% ���ƽ��ն������ز�
plot(t(start+1:start+nop),carry_sin_local(start+1:start+nop),'LineWidth',2)
hold on
legend('���ƶ������ز�','���ն˱��������ز�');
title("�����ز�")   % ����
xlabel('ʱ��/s');   % x���ǩ
ylabel('����');     % y���ǩ

subplot(212) % ���ڷָ��2*1�ģ���ǰ�ǵ�1����ͼ 
% ���������ز�
plot(t(start+1:start+nop),carry_cos(start+1:start+nop),'LineWidth',2)          
hold on
% ���Ʊ��������ز�
plot(t(start+1:start+nop),carry_cos_local(start+1:start+nop),'LineWidth',2)
hold on
legend('���ƶ������ز�','���ն˱��������ز�');
title("�����ز�")   % ����
xlabel('ʱ��/s');   % x���ǩ
ylabel('����');     % y���ǩ


%% ���Ƽ����źž�����ͨ�˲�������ź�
figure();                  
subplot(211)                 
plot(t,filtered_I,'LineWidth',2); % ����I·������ͨ�˲�������ź�
axis([0,TotalT,-1.1,1.1]);  % �������귶Χ
title("I·������ͨ�˲�������ź�");
xlabel('ʱ��/s');           
ylabel('����');             

subplot(212)               
plot(t,filtered_Q,'LineWidth',2); % ����Q·������ͨ�˲�������ź�
axis([0,TotalT,-1.1,1.1]);  
title("Q·������ͨ�˲�������ź�");
xlabel('ʱ��/s');          
ylabel('����');    

%% ���Ƴ����о����
figure();
subplot(311)                % ���ڷָ��3*1�ģ���ǰ�ǵ�1����ͼ 
plot(t,sample_d_I,'LineWidth',2)% �������������о�����ź�
axis([0,TotalT,-0.1,1.1]); % �������귶Χ
title("I·���������о�����ź�");
xlabel('ʱ��/s');           
ylabel('����');            

subplot(312)                % ���ڷָ��3*1�ģ���ǰ�ǵ�2����ͼ 
plot(t,sample_d_Q,'LineWidth',2)% �������������о�����ź�
axis([0,TotalT,-0.1,1.1]); % �������귶��
title("Q·���������о�����ź�")% ����
xlabel('ʱ��/s');           % x���ǩ
ylabel('����');             % y���ǩ


%% ��ͼ�Ƚϵ��ƽ�����ź�
figure()     
subplot(411)               
plot(t,I_signal,'LineWidth',2);% ���ƻ�����Ԫ���Σ��߿�Ϊ2
title('I·�źŲ���');       
xlabel('ʱ��/s');           
ylabel('����');  

subplot(412)                
plot(t,sample_d_I,'LineWidth',2);
title("I·���������о�����ź�");

subplot(413)               
plot(t,Q_signal,'LineWidth',2);
title('Q·�źŲ���');       
xlabel('ʱ��/s');           
ylabel('����');  

subplot(414)                
plot(t,sample_d_Q,'LineWidth',2);
title("Q·���������о�����ź�");

figure()     
subplot(211)               
plot(t,baseband,'LineWidth',2);% ���ƻ�����Ԫ���Σ��߿�Ϊ2
title('�����źŲ���');      
xlabel('ʱ��/s');           
ylabel('����');   
subplot(212)   
plot(t,dout,'LineWidth',2);% ���ƻ�����Ԫ����
title('QPSK����о����ź�'); % ����
xlabel('ʱ��/s');          % x���ǩ
ylabel('����');            % y���ǩ
axis([0,TotalT,-1.1,1.1])  % ���귶Χ����

subplot(313);              % ���ڷָ��3*1�ģ���ǰ�ǵ�3����ͼ 
plot(t,dout,'LineWidth',2);% ���ƻ�����Ԫ����
title('QPSK����о����ź�'); % ����
xlabel('ʱ��/s');          % x���ǩ
ylabel('����');            % y���ǩ
axis([0,TotalT,-1.1,1.1])  % ���귶Χ����


%% �����沨�����Ϊtxt�ı���Ϊtestbench��������
Width = 15; %����λ��
I_n=round(filtered_I*(2^(Width)-1));
Q_n=round(filtered_Q*(2^(Width)-1));
fid=fopen('dataI.txt','w');     
for k=1:length(I_n)
    B_s=dec2bin(I_n(k)+((I_n(k))<0)*2^Width,Width);
    for j=1:Width
        if B_s(j)=='1'
            tb=1;
        else
            tb=0;
        end
        fprintf(fid,'%d',tb);
    end
    fprintf(fid,'\r\n');
end
fprintf(fid,';');
fclose(fid);

fid=fopen('dataQ.txt','w');     
for k=1:length(Q_n)
    B_s=dec2bin(Q_n(k)+((Q_n(k))<0)*2^Width,Width);
    for j=1:Width
        if B_s(j)=='1'
            tb=1;
        else
            tb=0;
        end
        fprintf(fid,'%d',tb);
    end
    fprintf(fid,'\r\n');
end
fprintf(fid,';');
fclose(fid);