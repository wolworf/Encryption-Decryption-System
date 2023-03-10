%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%----------------------------- 主函数 -----------------------------%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [data_encrypt,data_length] = DES_Encrypt(r,key1)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  功能： DES加密
%  输入：      r        原始数据信号
%             key1      加密密钥
%  输出： data_encrypt  加密后的数据信号
%         data_length   原始数据信号长度
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%---------------- 变量赋初值 ----------------%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global irt endrt ert iprt pt

%%%%%%%--- DES加（解）密置换表 ----%%%%%%%
irt = ...                           % 明文初始置换表
       [58 50 42 34 26 18 10 2 ...
        60 52 44 36 28 20 12 4 ...
        62 54 46 38 30 22 14 6 ...
        64 56 48 40 32 24 16 8 ...
        57 49 41 33 25 17  9 1 ...
        59 51 43 35 27 19 11 3 ...
        61 53 45 37 29 21 13 5 ...
        63 55 47 39 31 23 15 7];
endrt = ...                         % 明文逆置换表
       [40 8 48 16 56 24 64 32 ...
        39 7 47 15 55 23 63 31 ...
        38 6 46 14 54 22 62 30 ...
        37 5 45 13 53 21 61 29 ...
        36 4 44 12 52 20 60 28 ...
        35 3 43 11 51 19 59 27 ...
        34 2 42 10 50 18 58 26 ...
        33 1 41  9 49 17 57 25];
ert = ...                           % 明文扩展置换表
       [32  1  2  3  4  5  4  5 ...
         6  7  8  9  8  9 10 11 ...
        12 13 12 13 14 15 16 17 ...
        16 17 18 19 20 21 20 21 ...
        22 23 24 25 24 25 26 27 ...
        28 29 28 29 30 31 32 1];
iprt = ...                          % 密钥初始置换表
       [57 49 41 33 25 17  9  1 ...
        58 50 42 34 26 18 10  2 ...
        59 51 43 35 27 19 11  3 ...
        60 52 44 36 63 55 47 39 ...
        31 23 15  7 62 54 46 38 ...
        30 22 14  6 61 53 45 37 ...
        29 21 13  5 28 20 12  4];
pt = ...                            % P置换表
       [16  7 20 21 29 12 28 17 ...
         1 15 23 26  5 18 31 10 ...
         2  8 24 14 32 27  3  9 ...
        19 13 30  6 22 11  4 25];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%----------------- DES加密 -----------------%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%--- 读取需要加密的数据 ---%%%%%%%%%
data = r;                           % 提取需要加密的数据
data_length = length(data);         % 求取字符长度
adds = 64-mod(data_length,64);      % 求取需要补充的字符数
if adds ~= 0
    for i = 1:adds
        data(data_length+i) = 0;    % 不足64位的分组数据后面补零
    end
    data_length1 = data_length+adds; % 补零后的位数
end
temp = data;
data = [];
for i = 1:data_length1
    data = [data,dec2bin(temp(i))]; % 将双精度二进制数据转换为字符串格式
end

%%%%%%%%%%%%---- 读取密钥 -----%%%%%%%%%%%%
key = key1;                         % 提取密钥字符
keylength = length(key);            % 求取字符长度
keytemp0 = uint8(key);              % 将字符转换为八位二进制整型
keys = [149 57 208 147 21 183 27];  % 密钥不足7位时的补充密钥

%%%%%%%%%%--- 将密钥调整为7位 ---%%%%%%%%%%
if keylength < 7                    % 延长小于七位的密钥
   for i = keylength+1:7
       keytemp0(i) = keys(i);
   end
end
for i=1:7                           % 缩短大于七位的密钥
      keyusetemp(i) = keytemp0(i);
end
keyuse = char(keyusetemp);          % 将密钥转换字符型数据

%%%%%%%%%%--- 形成16轮子密钥 ---%%%%%%%%%%%
pwb = str2bin(keyuse,7,2);          % 密钥转二进制,并加入偶校验位
pwb = rebit(pwb,iprt);              % 密钥初始置换
ki = gerkey(pwb);                   % 计算16轮子密钥

%%%%%%%%%%%--- 加密文件数据 ---%%%%%%%%%%%%
times = data_length1/64;            % 分组加密的组数
for i = 0:times-1
    for j = 1:64
        tempdata(j) = data(64*i+j); % 提取第i组数据
    end
    encrydata = des(tempdata,ki);   % 调用des函数利用密钥ki对tempdata加密
    data_encrypt(i*64+1:(i+1)*64) = encrydata; % 加密后的二进制数据（字符串格式）
end
temp = data_encrypt;
data_encrypt = zeros(size(temp));   % 加密后的二进制数据（双精度格式）
for i = 1:length(data_encrypt)
    if temp(i) == '1'
        data_encrypt(i) = 1;
    else
        data_encrypt(i) = 0;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%----------------------------- 子函数 -----------------------------%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%-------------- 子函数str2bin --------------%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function bin = str2bin(str,k,flag)

% 功能：字符串转二进制串,字符串中每个字符对应8位二进制字符
% 输入：str   字符向量  ASCII字符串
%       k     正整数   参与每次奇偶校验位运算的bit位数
%       flag  正整数   用以说明是否在二进制串中每隔k位加一位奇偶校验位，0表示不加，1表示加奇校验位，2表示加偶校验位
% 输出：bin   字符向量  二进制字符串
% 说明：当length(str)*8 mod k!=0时，对bin二进制串最后length(str)*8 mod k 位补零到k位后再做奇校验

l = length(str);
bin = [];
temp = [];

for x = 1:l
     temp = [temp,dec2bin(str(x),8)];  % 将字符串转换为二进制串
end

if flag ~= 0                           % 判断是否需要加奇偶校验位
     n = ceil(l*8/k);                  % 校验位总位数
     rb = mod(l*8,k);
     sb = 0;
     if rb ~= 0
     sb = k-rb;                        % 算出当二进制串做奇偶校验位时，在串尾补零的个数
     for i = 1:sb
         z(i) = '0';
     end
     temp = [temp z];
     end     
     for x = 0:n-1
        temp1 = temp(x*k+1:(x+1)*k);
        lone = length(find(temp1 == '1')); % 求k位二进制串中1的个数 
        if flag == 1                   % 计算奇校验位值
            if mod(lone,2) == 0
                opb = '1';
            else
                opb = '0';
            end
        else if flag == 2              % 计算偶校验位值
                if mod(lone,2) == 0
                    opb = '0';
                else
                    opb = '1';
                end
            end
        end
       temp1 = [temp1 opb];            % 添加校验位
       bin = [bin temp1];
    end
else
        bin = temp;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%--------------- 子函数rebit ---------------%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function so = rebit(si,k)

%功能：将si中的位根据置换表k进行置换
%输入：si 一维字符类型向量 要做位置换处理的串
%      k 一维字符类型向量 置换表
%输出：so 一维字符类型向量 si置换后的结果

lk=length(k);
for i=1:lk
    so(i)=si(k(i));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%--------------- 子函数gerkey ---------------%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ki=gerkey(k)

%功能：实现des加密过程中从56位的K密钥产生16个48位Ki子密钥
%输入：k 56位长的行向量 存储56位主密钥K
%     mt 矩阵 大小2*16 每轮循环左移位数表 
%     eg.
%     mt=[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16;1 1 2 2 2 2 2 2 1 2 2 2 2 2 2 1];
%     移位表第一行为轮数，第二行为第一行对应轮数左移的位数
%     rt 一维向量 长度48 置换表
%输出：ki 16*48的矩阵存储16个48位子密钥，ki的第一行代表第一个子密钥，第二行代表第二个子密钥......

mt = ...                               % 移位表（第一行为轮数，第二行为第一行对应轮数左移的位数）
    [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16;
     1 1 2 2 2 2 2 2 1  2  2  2  2  2  2  1];
rt = ...                               % 56位到48位压缩置换表
    [14 17 11 24  1  5  3 28 ...
     15  6 21 10 23 19 12  4 ...
     26  8 16  7 27 20 13  2 ...
     41 52 31 37 47 55 30 40 ...
     51 45 33 48 44 49 39 56 ...
     34 53 46 42 50 36 29 32];
kl = k(1:28);                          % k的左半部分
kr = k(29:56);                         % k的右半部分
for i = mt(1,1):mt(1,16)               % 进行16轮运算，产生16个子密钥
    kl = mr(kl,mt(2,i));               % 根据移位表对k的左部分进行循环左移
    kr = mr(kr,mt(2,i));               % 根据移位表对k的右部分进行循环左移
    k = [kl kr];                       % 进左移运算后的k
    for j = 1:48                       % 根据压缩置换表产生子密钥
        ki(i,j) = k(fix(rt(j)));
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%----------------- 子函数mr -----------------%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function nk = mr(k,n)

%功能：实现对输入向量k，循环左移n位
%输入：k  一维向量
%输出：nk 一维向量 循环左移结果

l = length(k);
k1 = k(n+1:l);
k2 = k(1:n);
nk = [k1 k2];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%---------------- 子函数des -----------------%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ef = des(pf,ki)

%函数形式:ef = des(pf,ki)
%功能：用密钥ki对pf做des加密
%输入：pf 一维向量 64位二进制长，字符串的形式
%      ki 16轮子密钥，二进行形式
%输出：ef 一维向量 加密结果

global irt endrt ert iprt pt

pfb = rebit(pf,irt);                   % 明文初始置换
lpfb = pfb(1:32);                      % 明文左32位
rpfb = pfb(33:64);                     % 明文右32位

for i = 0:15
    templ = lpfb;
    lpfb = rpfb;                       % 下一轮新的左数据输入
    tempr = rebit(rpfb,ert);           % rpfb扩展置换成48位
    rpfb = char(xor(ki(i+1,:)-48,tempr-48)+48); % 48位rpfb与48位子密钥ki(i+1,:)进行异或
    rpfb = sbox(rpfb);                 % S盒置换
    rpfb = rebit(rpfb,pt);             % P置换
    rpfb = char(xor(templ-48,rpfb-48)+48); % 32位templ与32位rpfb进行异或
end
pfb = [rpfb lpfb];
pfb = rebit(pfb,endrt);                % 末置换处理
ef = pfb;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%---------------- 子函数sbox ----------------%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function so = sbox(si)

%功能：模拟si通过s盒处理
%输入: si 一维向量 48位长
%输出: so 一维向量 32位长 

sbox1 = ...                            % S1盒
       [14  4 13 1  2 15 11  8  3 10  6 12  5  9 0  7;
         0 15  7 4 14  2 13  1 10  6 12 11  9  5 3  8;
         4  1 14 8 13  6  2 11 15 12  9  7  3 10 5  0;
        15 12  8 2  4  9  1  7  5 11  3 14 10  0 6 13];
sbox2 = ...                            % S2盒
       [15  1  8 14  6 11  3  4  9 7  2 13 12 0  5 10;
         3 13  4  7 15  2  8 14 12 0  1 10  6 9 11  5;
         0 14  7 11 10  4 13  1  5 8 12  6  9 3  2 15;
        13  8 10  1  3 15  4  2 11 6  7 12  0 5 14  9];
sbox3 = ...                            % S3盒
       [10  0  9 14 6  3 15  5  1 13 12  7 11  4  2  8;
        13  7  0  9 3  4  6 10  2  8  5 14 12 11  5  1;
        13  6  4  9 8 15  3  0 11  1  2 12  5 10 14  7;
         1 10 13  0 6  9  8  7  4 15 14  3 11  5  2 12];
sbox4 = ...                            % S4盒
       [ 7 13 14 3  0  6  9 10  1 2 8  5 11 12  4 15;
        13  8 11 5  6  5  0  3  4 7 2 12  1 10 14  9;
        10  6  9 0 12 11  7 13 15 1 3 14  5  2  8  4;
         3 15  0 6 10  1 13  8  9 4 5 11 12  7  2 14];
sbox5 = ...                            % S5盒
       [ 2 12  4  1  7 10 11  6  8  5  3 15 13 0 14  9;
        14 11  2 12  4  7 13  1  5  0 15 10  3 9  8  6;
         4  2  1 11 10 13  7  8 15  9 12  5  6 3  0 14;
         1  8 12  7  1 14  2 13  6 15  0  9 10 4  5  3];
sbox6 = ...                            % S6盒
       [12  1 10 15 9  2  6  8  0 13  3  4 14  7  5 11;
        10 15  4  2 7 12  9  5  6  1 13 14  0 11  3  8;
         9 14 15  5 2  8 12  3  7  0  4 10  1 13 11  6;
         4  3  2 12 9  5 15 10 11 14  1  7  6  0  8 13];
sbox7 = ...                            % S7盒
       [ 4 11  2 14 15 0  8 13  3 12 9  7  5 10 6  1;
        13  0 11  7  4 9  1 10 14  3 5 12  2 15 8  6;
         1  4 11 13 12 3  7 14 10 15 6  8  0  5 9  2;
         6 11 13  8  1 4 10  7  9  5 0 15 14  2 3 12];
sbox8 = ...                            % S8盒
       [13  2  8 4  6 15 11  1 10  9  3 14  5  0 12  7;
         1 15 13 8 10  3  7  4 12  5  6 11  0 14  9  2;
         7 11  4 1  9 12 14  2  0  6 10 13 15  3  5  8;
         2  1 14 7  4 10  8 13 15 12  9  0  3  5  6 11];
sbox = [sbox1 sbox2 sbox3 sbox4 sbox5 sbox6 sbox7 sbox8];
sboxout = [ ];
for i = 0:7
    sboxin(i+1,1:6) = si(i*6+1:(i+1)*6); % 第i+1个s盒输入,盒号从零开始计数
    rind = bin2dec([sboxin(i+1,1),sboxin(i+1,6)])+1; % 行号
    nind = bin2dec(sboxin(i+1,2:5))+1+i*16; % 列号
    sboxout = [sboxout dec2bin(sbox(rind,nind),4)]; % 根据行列号计算出第i+1个s盒的输出
end
so = sboxout;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%