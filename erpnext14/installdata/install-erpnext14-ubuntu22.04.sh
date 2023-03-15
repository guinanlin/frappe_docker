#!/bin/bash
# v0.3 2022.09.23   ��ӹ���Ա�˺�������ʾ��
set -e
# �ű����л������
# ����Ƿ�ubuntu22.04
cat /etc/os-release
osVer=$(cat /etc/os-release | grep 'Ubuntu 22.04' || true)
if [[ ${osVer} == '' ]]; then
    echo '�ű�ֻ��ubuntu22.04�汾����ͨ��������ϵͳ�汾��Ҫ�������䡣�˳���װ��'
    exit 1
else
    echo 'ϵͳ�汾���ͨ��...'
fi
# ����Ƿ�ʹ��bashִ��
if [[ 1 == 1 ]]; then
    echo 'bash���ͨ��...'
else
    echo 'bash���δͨ��...'
    echo '�ű���Ҫʹ��bashִ�С�'
    exit 1
fi
# ����Ƿ�ʹ��root�û�ִ��
if [ "$(id -u)" != "0" ]; then
   echo "�ű���Ҫʹ��root�û�ִ��"
   exit 1
else
    echo 'ִ���û����ͨ��...'
fi
# �趨����Ĭ��ֵ������㲻֪������ľͱ�ġ�
# ֻ�����ڴ�����ubuntu22.04��ʹ��root�û����У�����ϵͳ�������������䡣
# �ᰲװpython3.10��mariadb��redis�Լ�erpnext������ϵͳ����
# �Զ���ѡ��ʹ�÷�������./install.erpnext.sh benchVersion=5.12.1 frappePath=https://gitee.com/mirrors/frappe branch=version-14-beta
# -q���þ�Ĭģʽ��-d����docker ubuntu22.04�����ڰ�װ��
# ��Ĭģʽ��Ĭ��ɾ���Ѵ��ڵİ�װĿ¼�͵�ǰ����վ�����������ݿ⼰�û��������ʹ�á�
# branch������ͬʱ�޸�frappe��erpnext�ķ�֧��
# Ҳ����ֱ���޸����б���
mariadbPath=""
mariadbPort="3306"
mariadbRootPassword="Pass1234"
adminPassword="admin"
installDir="frappe-bench"
userName="frappe"
benchVersion=""
frappePath="https://gitee.com/mirrors/frappe"
frappeBranch="version-14"
erpnextPath="https://gitee.com/mirrors/erpnext"
erpnextBranch="version-14"
siteName="site1.local"
siteDbPassword="Pass1234"
webPort=""
productionMode="yes"
# �Ƿ��޸�apt��װԴ��������Ʒ��������鲻�޸ġ�
altAptSources="yes"
# �Ƿ�����ȷ�ϲ���ֱ�Ӱ�װ
quiet="no"
# �Ƿ�Ϊdocker����
inDocker="no"
# �Ƿ�ɾ���ظ��ļ�
removeDuplicate="yes"
# �����������������Ѿ��ǹ���Դ���޸�apt��װԴ
hostAddress=("mirrors.tencentyun.com" "mirrors.tuna.tsinghua.edu.cn" "cn.archive.ubuntu.com")
for h in ${hostAddress[@]}; do
    n=$(cat /etc/apt/sources.list | grep -c ${h} || true)
    if [[ ${n} -gt 0 ]]; then
        altAptSources="no"
    fi
done
# ���������޸�Ĭ��ֵ
# �ű�����Ӳ������г�ͻ������Ĳ�����Ч��
echo "===================��ȡ����==================="
argTag=""
for arg in $*
do
    if [[ ${argTag} != "" ]]; then
        case "${argTag}" in
        "webPort")
            t=$(echo ${arg}|sed 's/[0-9]//g')
            if [[ (${t} == "") && (${arg} -ge 80) && (${arg} -lt 65535) ]]; then
                webPort=${arg}
                echo "�趨web�˿�Ϊ${webPort}��"
                # ֻ���յ���ȷ�Ķ˿ڲ�������ת��һ�����������򽫼���ʶ��ǰ������
                continue
            else
                # ֻ��-pû����ȷ�Ĳ����ὫwebPort�����ÿ�
                webPort=""
            fi
            ;;
        esac
        argTag=""
    fi
    if [[ ${arg} == -* ]];then
        arg=${arg:1:${#arg}}
        for i in `seq ${#arg}`
        do
            arg0=${arg:$i-1:1}
            case "${arg0}" in
            "q")
                quiet='yes'
                removeDuplicate="yes"
                echo "����ȷ�ϲ�����ֱ�Ӱ�װ��"
                ;;
            "d")
                inDocker='yes'
                echo "���docker����װ��ʽ���䡣"
                ;;
            "p")
                argTag='webPort'
                echo "���docker����װ��ʽ���䡣"
                ;;
            esac
        done
    elif [[ ${arg} == *=* ]];then
        arg0=${arg%=*}
        arg1=${arg#*=}
        echo "${arg0} Ϊ�� ${arg1}"
        case "${arg0}" in
        "benchVersion")
            benchVersion=${arg1}
            echo "����bench�汾Ϊ�� ${benchVersion}"
            ;;
        "mariadbRootPassword")
            mariadbRootPassword=${arg1}
            echo "�������ݿ������Ϊ�� ${mariadbRootPassword}"
            ;;
        "adminPassword")
            adminPassword=${arg1}
            echo "���ù���Ա����Ϊ�� ${adminPassword}"
            ;;
        "frappePath")
            frappePath=${arg1}
            echo "����frappe��ȡ��ַΪ�� ${frappePath}"
            ;;
        "frappeBranch")
            frappeBranch=${arg1}
            echo "����frappe��֧Ϊ�� ${frappeBranch}"
            ;;
        "erpnextPath")
            erpnextPath=${arg1}
            echo "����erpnext��ȡ��ַΪ�� ${erpnextPath}"
            ;;
        "erpnextBranch")
            erpnextBranch=${arg1}
            echo "����erpnext��֧Ϊ�� ${erpnextBranch}"
            ;;
        "branch")
            frappeBranch=${arg1}
            erpnextBranch=${arg1}
            echo "����frappe��֧Ϊ�� ${frappeBranch}"
            echo "����erpnext��֧Ϊ�� ${erpnextBranch}"
            ;;
        "siteName")
            siteName=${arg1}
            echo "����վ������Ϊ�� ${siteName}"
            ;;
        "installDir")
            installDir=${arg1}
            echo "���ð�װĿ¼Ϊ�� ${installDir}"
            ;;
        "userName")
            userName=${arg1}
            echo "���ð�װ�û�Ϊ�� ${userName}"
            ;;
        "siteDbPassword")
            siteDbPassword=${arg1}
            echo "����վ�����ݿ�����Ϊ�� ${siteDbPassword}"
            ;;
        "webPort")
            webPort=${arg1}
            echo "����web�˿�Ϊ�� ${webPort}"
            ;;
        "altAptSources")
            altAptSources=${arg1}
            echo "�Ƿ��޸�apt��װԴ��${altAptSources}���Ʒ��������Լ��İ�װ�����鲻�޸ġ�"
            ;;
        "quiet")
            quiet=${arg1}
            if [[ ${quiet} == "yes" ]];then
                removeDuplicate="yes"
            fi
            echo "����ȷ�ϲ�����ֱ�Ӱ�װ��"
            ;;
        "inDocker")
            inDocker=${arg1}
            echo "���docker����װ��ʽ���䡣"
            ;;
        "productionMode")
            productionMode=${arg1}
            echo "�Ƿ�������ģʽ�� ${productionMode}"
            ;;
        esac
    fi
done
# ��ʾ����
if [[ ${quiet} != "yes" && ${inDocker} != "yes" ]]; then
    clear
fi
echo "���ݿ��ַ��"${mariadbPath}
echo "���ݿ�˿ڣ�"${mariadbPort}
echo "���ݿ�root�û����룺"${mariadbRootPassword}
echo "����Ա���룺"${adminPassword}
echo "��װĿ¼��"${installDir}
echo "ָ��bench�汾��"${benchVersion}
echo "��ȡfrappe��ַ��"${frappePath}
echo "ָ��frappe�汾��"${frappeBranch}
echo "��ȡerpnext��ַ��"${erpnextPath}
echo "ָ��erpnext�汾��"${erpnextBranch}
echo "��վ���ƣ�"${siteName}
echo "��վ���ݿ����룺"${siteDbPassword}
echo "web�˿ڣ�"${webPort}
echo "�Ƿ��޸�apt��װԴ��"${altAptSources}
echo "�Ƿ�Ĭģʽ��װ��"${quiet}
echo "��������Ŀ¼�����ݿ��Ƿ�ɾ����"${removeDuplicate}
echo "�Ƿ�Ϊdocker�����ڰ�װ���䣺"${inDocker}
echo "�Ƿ�������ģʽ��"${productionMode}
# �ȴ�ȷ�ϲ���
if [[ ${quiet} != "yes" ]];then
    echo "===================��ȷ�����趨������ѡ��װ��ʽ==================="
    echo "1. ��װΪ����ģʽ"
    echo "2. ��װΪ����ģʽ"
    echo "3. ����ѯ�ʣ����յ�ǰ�趨��װ��������Ĭģʽ"
    echo "4. ��Docker�����ﰲװ��������Ĭģʽ"
    echo "*. ȡ����װ"
    echo -e "˵����������Ĭģʽ�����������Ŀ¼�����ݿ����supervisor���������ļ�������ɾ���������װ����ע�����ݱ��ݣ� \n \
        ����ģʽ��Ҫ�ֶ�������bench start�������������8000�˿ڡ�\n \
        ����ģʽ�����ֶ�������ʹ��nginx����������80�˿�\n \
        ��������ģʽ��ʹ��supervisor���������ǿ�ɿ��ԣ���Ԥ������뿪��redis���棬���Ӧ�����ܡ�\n \
        ��Docker�����ﰲװ�����������������ʽ��mariadb��nginx����Ҳ����supervisor���� \n \
        docker�������̣߳���sudo supervisord -n -c /etc/supervisor/supervisord.conf�������������õ�����"
    read -r -p "��ѡ�� " input
    case ${input} in
        1)
            productionMode="no"
    	    ;;
        2)
            productionMode="yes"
    	    ;;
        3)
            quiet="yes"
            removeDuplicate="yes"
    	    ;;
        4)
            quiet="yes"
            removeDuplicate="yes"
            inDocker="yes"
    	    ;;
        *)
            echo "ȡ����װ..."
            exit 1
    	    ;;
    esac
fi
# ��������ӹؼ���
echo "===================����Ҫ�Ĳ�����ӹؼ���==================="
if [[ ${benchVersion} != "" ]];then
    benchVersion="==${benchVersion}"
fi
if [[ ${frappePath} != "" ]];then
    frappePath="--frappe-path ${frappePath}"
fi
if [[ ${frappeBranch} != "" ]];then
    frappeBranch="--frappe-branch ${frappeBranch}"
fi
if [[ ${erpnextBranch} != "" ]];then
    erpnextBranch="--branch ${erpnextBranch}"
fi
if [[ ${siteDbPassword} != "" ]];then
    siteDbPassword="--db-password ${siteDbPassword}"
fi

# ��ʼ��װ������������������ʹ�����Ҫ��
# �޸İ�װԴ���ٹ��ڰ�װ��
if [[ ${altAptSources} == "yes" ]];then
    # ��ִ��ǰȷ���в���Ȩ��
    if [[ ! -e /etc/apt/sources.list.bak ]]; then
        cp /etc/apt/sources.list /etc/apt/sources.list.bak
    fi
    rm -f /etc/apt/sources.list
    bash -c "cat << EOF > /etc/apt/sources.list && apt update 
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
# deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
# deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
# deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
# deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-security main restricted universe multiverse
EOF"
    echo "===================apt���޸�Ϊ����Դ==================="
fi
# ��װ�������
echo "===================��װ�������==================="
apt update
DEBIAN_FRONTEND=noninteractive apt upgrade -y
DEBIAN_FRONTEND=noninteractive apt install -y \
    ca-certificates \
    sudo \
    locales \
    tzdata \
    cron \
    wget \
    curl \
    python3.10-dev \
    python3.10-venv \
    python3-setuptools \
    python3-pip \
    python3-testresources \
    git \
    software-properties-common \
    mariadb-server \
    mariadb-client \
    libmysqlclient-dev \
    xvfb \
    libfontconfig \
    wkhtmltopdf \
    supervisor
# ����������
rteArr=()
warnArr=()
# ����Ƿ���֮ǰ��װ��Ŀ¼
while [[ -d "/home/${userName}/${installDir}" ]]; do
    if [[ ${quiet} != "yes" && ${inDocker} != "yes" ]]; then
        clear
    fi
    echo "��⵽�Ѵ��ڰ�װĿ¼��/home/${userName}/${installDir}"
    if [[ ${quiet} != "yes" ]];then
        echo '1. ɾ���������װ�����Ƽ���'
        echo '2. ����һ���µİ�װĿ¼��'
        read -r -p "*. ȡ����װ" input
        case ${input} in
            1)
                echo "ɾ��Ŀ¼���³�ʼ����"
                rm -rf /home/${userName}/${installDir}
                rm -f /etc/supervisor/conf.d/${installDir}.conf
                rm -f /etc/nginx/conf.d/${installDir}.conf
                ;;
            2)
                while true
                do
                    echo "��ǰĿ¼���ƣ�"${installDir}
                    read -r -p "�������µİ�װĿ¼���ƣ�" input
                    if [[ ${input} != "" ]]; then
                        installDir=${input}
                        read -r -p "ʹ���µİ�װĿ¼����${siteName}��yȷ�ϣ�n�������룺" input
                        if [[ ${input} == [y/Y] ]]; then
                            echo "��ʹ�ð�װĿ¼����${installDir}���ԡ�"
                            break
                        fi
                    fi
                done
                continue
                ;;
            *)
                echo "ȡ����װ��"
                exit 1
                ;;
        esac
    else
        echo "��Ĭģʽ��ɾ��Ŀ¼���³�ʼ����"
        rm -rf /home/${userName}/${installDir}
    fi
done
# ����������,python3
if type python3 >/dev/null 2>&1; then
    result=$(python3 -V | grep "3.10" || true)
    if [[ "${result}" == "" ]]
    then
        echo '==========�Ѱ�װpython3���������Ƽ���3.10�汾��=========='
        warnArr[${#warnArr[@]}]="Python�����Ƽ���3.10�汾��"
    else
        echo '==========�Ѱ�װpython3.10=========='
    fi
    rteArr[${#rteArr[@]}]=$(python3 -V)
else
    echo "==========python��װʧ���˳��ű���=========="
    exit 1
fi
# ����������,wkhtmltox
if type wkhtmltopdf >/dev/null 2>&1; then
    result=$(wkhtmltopdf -V | grep "0.12.6" || true)
    if [[ ${result} == "" ]]
    then
        echo '==========�Ѵ���wkhtmltox���������Ƽ���0.12.6�汾��=========='
        warnArr[${#warnArr[@]}]='wkhtmltox�����Ƽ���0.12.6�汾��'
    else
        echo '==========�Ѱ�װwkhtmltox_0.12.6=========='
    fi
    rteArr[${#rteArr[@]}]=$(wkhtmltopdf -V)
else
    echo "==========wkhtmltox��װʧ���˳��ű���=========="
    exit 1
fi
# ����������,MariaDB
# https://mirrors.aliyun.com/mariadb/mariadb-10.6.8/bintar-linux-systemd-x86_64/mariadb-10.6.8-linux-systemd-x86_64.tar.gz
if type mysql >/dev/null 2>&1; then
    result=$(mysql -V | grep "10.6" || true)
    if [[ "${result}" == "" ]]
    then
        echo '==========�Ѱ�װMariaDB���������Ƽ���10.6�汾��=========='
        warnArr[${#warnArr[@]}]='MariaDB�����Ƽ���10.6�汾��'
    else
        echo '==========�Ѱ�װMariaDB10.6=========='
    fi
    rteArr[${#rteArr[@]}]=$(mysql -V)
else
    echo "==========MariaDB��װʧ���˳��ű���=========="
    exit 1
fi
# �޸����ݿ������ļ�
# ���֮ǰ�޸Ĺ�������
n=$(cat /etc/mysql/my.cnf | grep -c "# ERPNext install script added" || true)
if [[ ${n} == 0 ]]; then
    echo "===================�޸����ݿ������ļ�==================="
    echo "# ERPNext install script added" >> /etc/mysql/my.cnf
    echo "[mysqld]" >> /etc/mysql/my.cnf
    echo "character-set-client-handshake=FALSE" >> /etc/mysql/my.cnf
    echo "character-set-server=utf8mb4" >> /etc/mysql/my.cnf
    echo "collation-server=utf8mb4_unicode_ci" >> /etc/mysql/my.cnf
    echo "bind-address=0.0.0.0" >> /etc/mysql/my.cnf
    echo "" >> /etc/mysql/my.cnf
    echo "[mysql]" >> /etc/mysql/my.cnf
    echo "default-character-set=utf8mb4" >> /etc/mysql/my.cnf
fi
/etc/init.d/mariadb restart
# �ȴ�2��
for i in $(seq -w 2); do
    echo ${i}
    sleep 1
done
# ��ȨԶ�̷��ʲ��޸�����
if mysql -uroot -e quit >/dev/null 2>&1
then
    echo "===================�޸����ݿ�root���ط�������==================="
    mysqladmin -v -uroot password ${mariadbRootPassword}
elif mysql -uroot -p${mariadbRootPassword} -e quit >/dev/null 2>&1
then
    echo "===================���ݿ�root���ط�������������==================="
else
    echo "===================���ݿ�root���ط����������==================="
    exit 1
fi
echo "===================�޸����ݿ�rootԶ�̷�������==================="
mysql -u root -p${mariadbRootPassword} -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '${mariadbRootPassword}' WITH GRANT OPTION;"
echo "===================ˢ��Ȩ�ޱ�==================="
mysqladmin -v -uroot -p${mariadbRootPassword} reload
sed -i 's/^password.*$/password='"${mariadbRootPassword}"'/' /etc/mysql/debian.cnf
echo "===================���ݿ��������==================="
# ������ݿ��Ƿ���ͬ���û������У�ѡ����ʽ��
echo "==========������ݿ����=========="
while true
do
    siteSha1=$(echo -n ${siteName} | sha1sum)
    siteSha1=_${siteSha1:0:16}
    dbUser=$(mysql -u root -p${mariadbRootPassword} -e "use mysql;SELECT User,Host FROM user;" | grep ${siteSha1} || true)
    if [[ ${dbUser} != "" ]]; then
        if [[ ${quiet} != "yes" && ${inDocker} != "yes" ]]; then
            clear
        fi
        echo '��ǰվ�����ƣ�'${siteName}
        echo '���ɵ����ݿ⼰�û���Ϊ��'${siteSha1}
        echo '�Ѵ���ͬ�����ݿ��û�����ѡ����ʽ��'
        echo '1. ���������µ�վ�����ơ����Զ������µ����ݿ⼰�û���������У�顣'
        echo '2. ɾ�����������ݿ⼰�û���'
        echo '3. ʲôҲ����ʹ�����õ�����ֱ�Ӱ�װ�������Ƽ���'
        echo '*. ȡ����װ��'
        if [[ ${quiet} == "yes" ]]; then
            echo '��ǰΪ��Ĭģʽ�����Զ�����2��ִ�С�'
            # ɾ���������ݿ�
            mysql -u root -p${mariadbRootPassword} -e "drop database ${siteSha1};"
            arrUser=(${dbUser})
            # ��������û��ж��host���Բ���2ȡ�û������û�host��ɾ����
            for ((i=0; i<${#arrUser[@]}; i=i+2))
            do
                mysql -u root -p${mariadbRootPassword} -e "drop user ${arrUser[$i]}@${arrUser[$i+1]};"
            done
            echo "��ɾ�����ݿ⼰�û���������װ��"
            continue
        fi
        read -r -p "������ѡ��" input
        case ${input} in
            '1')
                while true
                do
                    read -r -p "�������µ�վ�����ƣ�" inputSiteName
                    if [[ ${inputSiteName} != "" ]]; then
                        siteName=${inputSiteName}
                        read -r -p "ʹ���µ�վ������${siteName}��yȷ�ϣ�n�������룺" input
                        if [[ ${input} == [y/Y] ]]; then
                            echo "��ʹ��վ������${siteName}���ԡ�"
                            break
                        fi
                    fi
                done
                continue
                ;;
            '2')
                mysql -u root -p${mariadbRootPassword} -e "drop database ${siteSha1};"
                arrUser=(${dbUser})
                for ((i=0; i<${#arrUser[@]}; i=i+2))
                do
                    mysql -u root -p${mariadbRootPassword} -e "drop user ${arrUser[$i]}@${arrUser[$i+1]};"
                done
                echo "��ɾ�����ݿ⼰�û���������װ��"
                continue
                ;;
            '3')
                echo "ʲôҲ����ʹ�����õ�����ֱ�Ӱ�װ��"
                warnArr[${#warnArr[@]}]="��⵽�������ݿ⼰�û�${siteSha1},ѡ���˸��ǰ�װ����������޷����ʣ����ݿ��޷����ӵ����⡣"
                break
                ;;
            *)
            echo "ȡ����װ..."
            exit 1
            ;;
        esac
    else
        echo "���������ݿ���û���"
        break
    fi
done
# ȷ�Ͽ��õ�����ָ��
echo "ȷ��supervisor��������ָ�"
supervisorCommand=""
if type supervisord >/dev/null 2>&1; then
    if [[ $(grep -E "[ *]reload)" /etc/init.d/supervisor) != '' ]]; then
        supervisorCommand="reload"
    elif [[ $(grep -E "[ *]restart)" /etc/init.d/supervisor) != '' ]]; then
        supervisorCommand="restart"
    else
        echo "/etc/init.d/supervisor��û���ҵ�reload��restartָ��"
        echo "�������ִ�У���������Ϊʹ�ò�����ָ�����������ʧ�ܡ�"
        echo "�����û�����У��볢���ֶ�����supervisor"
        warnArr[${#warnArr[@]}]="û���ҵ����õ�supervisor����ָ����н�������ʧ�ܣ��볢���ֶ�������"
    fi
else
    echo "supervisorû�а�װ"
    warnArr[${#warnArr[@]}]="supervisorû�а�װ��װʧ�ܣ�����ʹ��supervisor������̡�"
fi
echo "����ָ�"${supervisorCommand}
# ��װ���°�redis
# ����Ƿ�װredis
if ! type redis-server >/dev/null 2>&1; then
    # ��ȡ���°�redis������װ
    echo "==========��ȡ���°�redis������װ=========="
    rm -rf /var/lib/redis
    rm -rf /etc/redis
    rm -rf /etc/default/redis-server
    rm -rf /etc/init.d/redis-server
    rm -f /usr/share/keyrings/redis-archive-keyring.gpg
    curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list
    apt update
    # redisV=($(apt-cache madison redis | grep -o 6:6.2.*jammy1 | head -1))
    # echo "redis6.2���°汾Ϊ��${redisV[0]}"
    echo "������װredis"
    DEBIAN_FRONTEND=noninteractive apt install -y \
        redis-tools \
        redis-server \
        redis
fi
# ����������,redis
if type redis-server >/dev/null 2>&1; then
    result=$(redis-server -v | grep "7" || true)
    if [[ "${result}" == "" ]]
    then
        echo '==========�Ѱ�װredis���������Ƽ���7�汾��=========='
        warnArr[${#warnArr[@]}]='redis�����Ƽ���7�汾��'
    else
        echo '==========�Ѱ�װredis7=========='
    fi
    rteArr[${#rteArr[@]}]=$(redis-server -v)
else
    echo "==========redis��װʧ���˳��ű���=========="
    exit 1
fi
# �޸�pipĬ��Դ���ٹ��ڰ�װ
# ��ִ��ǰȷ���в���Ȩ��
# pip3 config list
mkdir -p /root/.pip
echo '[global]' > /root/.pip/pip.conf
echo 'index-url=https://pypi.tuna.tsinghua.edu.cn/simple' >> /root/.pip/pip.conf
echo '[install]' >> /root/.pip/pip.conf
echo 'trusted-host=mirrors.tuna.tsinghua.edu.cn' >> /root/.pip/pip.conf
echo "===================pip���޸�Ϊ����Դ==================="
# ��װ������pip�����߰�
echo "===================��װ������pip�����߰�==================="
cd ~
python3 -m pip install --upgrade pip
python3 -m pip install --upgrade setuptools cryptography psutil
alias python=python3
alias pip=pip3
# �������û�����û�
echo "===================�������û�����û�==================="
result=$(grep "${userName}:" /etc/group || true)
if [[ ${result} == "" ]]; then
    gid=1000
    while true
    do
        result=$(grep ":${gid}:" /etc/group || true)
        if [[ ${result} == "" ]]
        then
            echo "�������û���: ${gid}:${userName}"
            groupadd -g ${gid} ${userName}
            echo "���½��û���${userName}��gid: ${gid}"
            break
        else
            gid=$(expr ${gid} + 1)
        fi
    done
else
    echo '�û����Ѵ���'
fi
result=$(grep "${userName}:" /etc/passwd || true)
if [[ ${result} == "" ]]
then
    uid=1000
    while true
    do
        result=$(grep ":x:${uid}:" /etc/passwd || true)
        if [[ ${result} == "" ]]
        then
            echo "�������û�: ${uid}:${userName}"
            useradd --no-log-init -r -m -u ${uid} -g ${gid} -G  sudo ${userName}
            echo "���½��û�${userName}��uid: ${uid}"
            break
        else
            uid=$(expr ${uid} + 1)
        fi
    done
else
    echo '�û��Ѵ���'
fi
# ���û����sudoȨ��
sed -i "/^${userName}.*/d" /etc/sudoers
echo "${userName} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
mkdir -p /home/${userName}
sed -i "/^export.*${userName}.*/d" /etc/sudoers
echo "export PATH=/home/${userName}/.local/bin:\$PATH" >> /home/${userName}/.bashrc
# �޸��û�pipĬ��Դ���ٹ��ڰ�װ
cp -af /root/.pip /home/${userName}/
# �����û�Ŀ¼Ȩ��
chown -R ${userName}.${userName} /home/${userName}
# �����û�shell
usermod -s /bin/bash ${userName}
# �������Ի���
echo "===================�������Ի���==================="
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
sed -i "/^export.*LC_ALL=.*/d" /root/.bashrc
sed -i "/^export.*LC_CTYPE=.*/d" /root/.bashrc
sed -i "/^export.*LANG=.*/d" /root/.bashrc
echo -e "export LC_ALL=en_US.UTF-8\nexport LC_CTYPE=en_US.UTF-8\nexport LANG=en_US.UTF-8" >> /root/.bashrc
sed -i "/^export.*LC_ALL=.*/d" /home/${userName}/.bashrc
sed -i "/^export.*LC_CTYPE=.*/d" /home/${userName}/.bashrc
sed -i "/^export.*LANG=.*/d" /home/${userName}/.bashrc
echo -e "export LC_ALL=en_US.UTF-8\nexport LC_CTYPE=en_US.UTF-8\nexport LANG=en_US.UTF-8" >> /home/${userName}/.bashrc
# ����ʱ��Ϊ�Ϻ�
echo "===================����ʱ��Ϊ�Ϻ�==================="
ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
dpkg-reconfigure -f noninteractive tzdata
# ���ü���ļ���������
echo "===================���ü���ļ���������==================="
sed -i "/^fs.inotify.max_user_watches=.*/d" /etc/sysctl.conf
echo fs.inotify.max_user_watches=524288 | tee -a /etc/sysctl.conf
# ʹ��������Ч
/sbin/sysctl -p
# ����Ƿ�װnodejs16
source /etc/profile
if ! type node >/dev/null 2>&1; then
    # ��ȡ���°�nodejs-v16������װ
    echo "==========��ȡ���°�nodejs-v16������װ=========="
    nodejs0=$(curl -sL https://nodejs.org/download/release/latest-v16.x/ | grep -o node-v16.*-linux-x64.tar.xz)
    nodejs1=${nodejs0%%.tar*}
    echo "nodejs16���°汾Ϊ��${nodejs1}"
    echo "������װnodejs16��/usr/local/lib/nodejs/${nodejs1}"
    wget https://nodejs.org/download/release/latest-v16.x/${nodejs1}.tar.xz -P /tmp/
    mkdir -p /usr/local/lib/nodejs
    tar -xJf /tmp/${nodejs1}.tar.xz -C /usr/local/lib/nodejs/
    echo "export PATH=/usr/local/lib/nodejs/${nodejs1}/bin:\$PATH" >> /etc/profile.d/nodejs.sh
    echo "export PATH=/usr/local/lib/nodejs/${nodejs1}/bin:\$PATH" >> ~/.bashrc
    export PATH=/usr/local/lib/nodejs/${nodejs1}/bin:$PATH
    source /etc/profile
fi
# ����������,node
if type node >/dev/null 2>&1; then
    result=$(node -v | grep "v16." || true)
    if [[ ${result} == "" ]]
    then
        echo '==========�Ѵ���node��������v16�档�⽫�п��ܵ���һЩ���⡣����ж��node�����ԡ�=========='
        warnArr[${#warnArr[@]}]='node�����Ƽ���v16�汾��'
    else
        echo '==========�Ѱ�װnode16=========='
    fi
    rteArr[${#rteArr[@]}]='node '$(node -v)
else
    echo "==========node��װʧ���˳��ű���=========="
    exit 1
fi
# �޸�npmԴ
# ��ִ��ǰȷ���в���Ȩ��
# npm get registry
npm config set registry https://registry.npmmirror.com -g
echo "===================npm���޸�Ϊ����Դ==================="
# ����npm
echo "===================����npm==================="
npm install -g npm
# ��װyarn
echo "===================��װyarn==================="
npm install -g yarn
# �޸�yarnԴ
# ��ִ��ǰȷ���в���Ȩ��
# yarn config list
yarn config set registry https://registry.npmmirror.com --global
echo "===================yarn���޸�Ϊ����Դ==================="
# ��������װ��ϡ�
echo "===================��������װ��ϡ�==================="
# �л��û�
su - ${userName} <<EOF
# �������л�������
echo "===================�������л�������==================="
cd ~
alias python=python3
alias pip=pip3
source /etc/profile
export PATH=/home/${userName}/.local/bin:$PATH
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LANG=en_US.UTF-8
# �޸��û�yarnԴ
# ��ִ��ǰȷ���в���Ȩ��
# yarn config list
yarn config set registry https://registry.npmmirror.com --global
echo "===================�û�yarn���޸�Ϊ����Դ==================="
EOF
# ����redis-server��mariadb
echo "===================����redis-server��mariadb==================="
# service redis-server restart
# service mariadb restart
/etc/init.d/redis-server restart
/etc/init.d/mariadb restart
# �ȴ�2��
for i in $(seq -w 2); do
    echo ${i}
    sleep 1
done
# ����docker
echo "�ж��Ƿ�����docker"
if [[ ${inDocker} == "yes" ]]; then
    # �������docker�����У�ʹ��supervisor����mariadb��nginx����
    echo "================Ϊdocker�������mariadb��nginx���������ļ�==================="
    supervisorConfigDir=/home/${userName}/.config/supervisor
    mkdir -p ${supervisorConfigDir}
    f=${supervisorConfigDir}/mariadb.conf
    rm -f ${f}
    echo "[program:mariadb]" > ${f}
    echo "command=/usr/sbin/mariadbd --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib/mysql/plugin --user=mysql --skip-log-error" >> ${f}
    # echo "user=mysql" >> ${f}
    echo "priority=1" >> ${f}
    echo "autostart=true" >> ${f}
    echo "autorestart=true" >> ${f}
    echo "numprocs=1" >> ${f}
    echo "startretries=10" >> ${f}
    # echo "exitcodes=0,2" >> ${f}
    # echo "stopsignal=INT" >> ${f}
    echo "stopwaitsecs=10" >> ${f}
    echo "redirect_stderr=true" >> ${f}
    echo "stdout_logfile_maxbytes=1024MB" >> ${f}
    echo "stdout_logfile_backups=10" >> ${f}
    echo "stdout_logfile=/var/run/log/supervisor_mysql.log" >> ${f}
    f=${supervisorConfigDir}/nginx.conf
    rm -f ${f}
    echo "[program: nginx]" > ${f}
    echo "command=/usr/sbin/nginx -g 'daemon off;'" >> ${f}
    echo "autorestart=true" >> ${f}
    echo "autostart=true" >> ${f}
    echo "stderr_logfile=/var/run/log/supervisor_nginx_error.log" >> ${f}
    echo "stdout_logfile=/var/run/log/supervisor_nginx_stdout.log" >> ${f}
    echo "environment=ASPNETCORE_ENVIRONMENT=Production" >> ${f}
    echo "user=root" >> ${f}
    echo "stopsignal=INT" >> ${f}
    echo "startsecs=10" >> ${f}
    echo "startretries=5" >> ${f}
    echo "stopasgroup=true" >> ${f}
    # �ر�mariadb���̣�����supervisor���̲�����mariadb����
    echo "�ر�mariadb���̣�����supervisor���̲�����mariadb����"
    /etc/init.d/mariadb stop
    # �ȴ�2��
    for i in $(seq -w 2); do
        echo ${i}
        sleep 1
    done
    if [[ ! -e /etc/supervisor/conf.d/mysql.conf ]]; then
        echo "�������ݿ������ļ�������"
        ln -fs ${supervisorConfigDir}/mariadb.conf /etc/supervisor/conf.d/mariadb.conf
    fi
    i=$(ps aux | grep -c supervisor || true)
    if [[ ${i} -le 1 ]]; then
        echo "����supervisor����"
        /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
    else
        echo "����supervisor����"
        /usr/bin/supervisorctl reload
    fi
    # �ȴ�2��
    for i in $(seq -w 2); do
        echo ${i}
        sleep 1
    done
fi
# ��װbench
su - ${userName} <<EOF
echo "===================��װbench==================="
sudo -H pip3 install frappe-bench${benchVersion}
# ����������,bench
if type bench >/dev/null 2>&1; then
    benchV=\$(bench --version)
    echo '==========�Ѱ�װbench=========='
    echo \${benchV}
else
    echo "==========bench��װʧ���˳��ű���=========="
    exit 1
fi
EOF
rteArr[${#rteArr[@]}]='bench '$(bench --version 2>/dev/null)
# bensh�ű�����docker
if [[ ${inDocker} == "yes" ]]; then
    # �޸�bensh�ű�����װfail2ban
    echo "��������docker�����У���ע�Ͱ�װfail2ban�Ĵ��롣"
    # ȷ��bensh�ű�ʹ��supervisorָ�������
    f="/usr/local/lib/python3.10/dist-packages/bench/config/production_setup.py"
    n=$(sed -n "/^[[:space:]]*if not which.*fail2ban-client/=" ${f})
    # ���ҵ�����ע���ж��м�ִ����
    if [ ${n} ]; then
        echo "�ҵ�fail2ban��װ�����У����ע�ͷ���"
        sed -i "${n} s/^/#&/" ${f}
        let n++
        sed -i "${n} s/^/#&/" ${f}
    fi
fi
# ��ʼ��frappe
su - ${userName} <<EOF
echo "===================��ʼ��frappe==================="
# �����ʼ��ʧ�ܣ�����5�Ρ�
for ((i=0; i<5; i++)); do
    rm -rf ~/${installDir}
    set +e
    bench init ${frappeBranch} --python /usr/bin/python3 --ignore-exist ${installDir} ${frappePath}
    err=\$?
    set -e
    if [[ \${err} == 0 ]]; then
        echo "ִ�з�����ȷ\${i}"
        sleep 1
        break
    elif [[ \${i} -ge 4 ]]; then
        echo "==========frappe��ʼ��ʧ��̫��\${i}���˳��ű���=========="
        exit 1
    else
        echo "==========frappe��ʼ��ʧ�ܵ�"\${i}"�Σ��Զ����ԡ�=========="
    fi
done
echo "frappe��ʼ���ű�ִ�н���..."
EOF
# ȷ��frappe��ʼ��
su - ${userName} <<EOF
cd ~/${installDir}
# ����������,frappe
frappeV=\$(bench version | grep "frappe" || true)
if [[ \${frappeV} == "" ]]; then
    echo "==========frappe��ʼ��ʧ���˳��ű���=========="
    exit 1
else
    echo '==========frappe��ʼ���ɹ�=========='
    echo \${frappeV}
fi
EOF
# ��ȡerpnextӦ��
su - ${userName} <<EOF
cd ~/${installDir}
echo "===================��ȡerpnextӦ��==================="
bench get-app ${erpnextBranch} ${erpnextPath}
# cd ~/${installDir} && ./env/bin/pip3 install -e apps/erpnext/
EOF
# ��ȡPaymentsӦ��
su - ${userName} <<EOF
cd ~/${installDir}
echo "===================��ȡPaymentsӦ��==================="
# bench get-app payments
bench get-app https://gitee.com/phipsoft/payments
EOF
# ��������վ
su - ${userName} <<EOF
cd ~/${installDir}
echo "===================��������վ==================="
bench new-site --mariadb-root-password ${mariadbRootPassword} ${siteDbPassword} --admin-password ${adminPassword} ${siteName}
EOF
# ��װerpnextӦ�õ�����վ
su - ${userName} <<EOF
cd ~/${installDir}
echo "===================��װerpnextӦ�õ�����վ==================="
bench --site ${siteName} install-app payments
bench --site ${siteName} install-app erpnext
EOF
# վ������
su - ${userName} <<EOF
cd ~/${installDir}
# ������վ��ʱʱ��
echo "===================������վ��ʱʱ��==================="
bench config http_timeout 6000
# ����Ĭ��վ�㲢����Ĭ��վ��
bench config serve_default_site on
bench use ${siteName}
EOF
# ��װ���ı��ػ�,ֻ�п�ܣ���Ҫ���б༭zh.csv�ļ���ӷ��������
# ���������https://gitee.com/phipsoft/zh_chinese_language
su - ${userName} <<EOF
cd ~/${installDir}
echo "===================��װ���ı��ػ�==================="
bench get-app https://gitee.com/yuzelin/erpnext_chinese.git
bench --site ${siteName} install-app erpnext_chinese
EOF
# ������̨
su - ${userName} <<EOF
cd ~/${installDir}
echo "===================������̨==================="
bench clear-cache
bench clear-website-cache
EOF
# ����ģʽ����
if [[ ${productionMode} == "yes" ]]; then
    echo "================��������ģʽ==================="
    # ���ܻ��Զ���װһЩ�����ˢ�������
    apt update
    # Ԥ�Ȱ�װnginx����ֹ�Զ��������
    DEBIAN_FRONTEND=noninteractive apt install nginx -y
    rteArr[${#rteArr[@]}]=$(nginx -v 2>/dev/null)
    if [[ ${inDocker} == "yes" ]]; then
        # ʹ��supervisor����nginx����
        /etc/init.d/nginx stop
        if [[ ! -e /etc/supervisor/conf.d/nginx.conf ]]; then
            ln -fs ${supervisorConfigDir}/nginx.conf /etc/supervisor/conf.d/nginx.conf
        fi
        echo "��ǰsupervisor״̬"
        /usr/bin/supervisorctl status
        echo "����supervisor����"
        /usr/bin/supervisorctl reload
        # �ȴ�����supervisor����
        echo "�ȴ�����supervisor����"
        for i in $(seq -w 15 -1 1); do
            echo -en ${i}; sleep 1
        done
        echo "���غ�supervisor״̬"
        /usr/bin/supervisorctl status
    fi
    # ����м�⵽��supervisor��������ָ��޸�bensh�ű�supervisor����ָ��Ϊ����ָ�
    echo "�����ű�����..."
    if [[ ${supervisorCommand} != "" ]]; then
        echo "���õ�supervisor����ָ��Ϊ��"${supervisorCommand}
        # ȷ��bensh�ű�ʹ��supervisorָ�������
        f="/usr/local/lib/python3.10/dist-packages/bench/config/supervisor.py"
        n=$(sed -n "/service.*supervisor.*reload\|service.*supervisor.*restart/=" ${f})
        # ���ҵ��滻Ϊ����ָ��
        if [ ${n} ]; then
            echo "�滻bensh�ű�supervisor����ָ��Ϊ��"${supervisorCommand}
            sed -i "${n} s/reload\|restart/${supervisorCommand}/g" ${f}
        fi
    fi
    # ׼��ִ�п�������ģʽ�ű�
    # ����Ƿ�����frappe�����ļ���û�����ظ�ִ�С�
    # ������ʼ��ʱ���֮ǰsupervisorû�а�װ��װʧ�ܻ��ٴγ��԰�װ����������Ϊû���޸�Ϊ��ȷ������ָ���������
    f="/etc/supervisor/conf.d/${installDir}.conf"
    i=0
    while [[ i -lt 9 ]]; do
        echo "���Կ�������ģʽ${i}..."
        set +e
        su - ${userName} <<EOF
        cd ~/${installDir}
        sudo bench setup production ${userName} --yes
EOF
        set -e
        i=$((${i} + 1))
        echo "�ж�ִ�н��"
        sleep 1
        if [[ -e ${f} ]]; then
            echo "�����ļ�������..."
            break
        elif [[ ${i} -ge 9 ]]; then
            echo "ʧ�ܴ�������${i}���볢���ֶ�������"
            break
        else
            echo "�����ļ�����ʧ��${i}���Զ����ԡ�"
        fi
    done
    # echo "����supervisor����"
    # /usr/bin/supervisorctl reload 
    # sleep 2
fi
# ������趨�˿ڣ��޸�Ϊ�趨�˿�
if [[ ${webPort} != "" ]]; then
    echo "===================����web�˿�Ϊ��${webPort}==================="
    # �ٴ���֤�˿ںŵ���Ч��
    t=$(echo ${webPort}|sed 's/[0-9]//g')
    if [[ (${t} == "") && (${webPort} -ge 80) && (${webPort} -lt 65535) ]]; then
        if [[ ${productionMode} == "yes" ]]; then
            f="/home/${userName}/${installDir}/config/nginx.conf"
            if [[ -e ${f} ]]; then
                echo "�ҵ������ļ���"${f}
                n=($(sed -n "/^[[:space:]]*listen/=" ${f}))
                # ���ҵ��滻Ϊ����ָ��
                if [ ${n} ]; then
                    sed -i "${n} c listen ${webPort};" ${f}
                    sed -i "$((${n}+1)) c listen [::]:${webPort};" ${f}
                    /etc/init.d/nginx reload
                    echo "web�˿ں��޸�Ϊ��"${webPort}
                else
                    echo "�����ļ���û�ҵ������С��޸�ʧ�ܡ�"
                    warnArr[${#warnArr[@]}]="�ҵ������ļ���"${f}",û�ҵ������С��޸�ʧ�ܡ�"
                fi
            else
                echo "û���ҵ������ļ���"${f}",�˿��޸�ʧ�ܡ�"
                warnArr[${#warnArr[@]}]="û���ҵ������ļ���"${f}",�˿��޸�ʧ�ܡ�"
            fi
        else
            echo "����ģʽ�޸Ķ˿ں�"
            f="/home/${userName}/${installDir}/Procfile"
            echo "�ҵ������ļ���"${f}
            if [[ -e ${f} ]]; then
                n=($(sed -n "/^web.*port.*/=" ${f}))
                # ���ҵ��滻Ϊ����ָ��
                if [[ ${n} ]]; then
                    sed -i "${n} c web: bench serve --port ${webPort}" ${f}
                    su - ${userName} bash -c "cd ~/${installDir}; bench restart"
                    echo "web�˿ں��޸�Ϊ��"${webPort}
                else
                    echo "�����ļ���û�ҵ������С��޸�ʧ�ܡ�"
                    warnArr[${#warnArr[@]}]="�ҵ������ļ���"${f}",û�ҵ������С��޸�ʧ�ܡ�"
                fi
            else
                echo "û���ҵ������ļ���"${f}",�˿��޸�ʧ�ܡ�"
                warnArr[${#warnArr[@]}]="û���ҵ������ļ���"${f}",�˿��޸�ʧ�ܡ�"
            fi
        fi
    else
        echo "���õĶ˿ں���Ч�򲻷���Ҫ��ȡ���˿ں��޸ġ�ʹ��Ĭ�϶˿ںš�"
        warnArr[${#warnArr[@]}]="���õĶ˿ں���Ч�򲻷���Ҫ��ȡ���˿ں��޸ġ�ʹ��Ĭ�϶˿ںš�"
    fi
else
    # û���趨�˿ںţ���ʾĬ�϶˿ںš�
    if [[ ${productionMode} == "yes" ]]; then
        webPort="80"
    else
        webPort="8000"
    fi
fi
# ����Ȩ��
echo "===================����Ȩ��==================="
chown -R ${userName}:${userName} /home/${userName}/
chmod 755 /home/${userName}
# ��������,ERPNext��װ���
echo "===================��������,ERPNext��װ���==================="
apt clean
apt autoremove -y
rm -rf /var/lib/apt/lists/*
pip cache purge
npm cache clean --force
yarn cache clean
su - ${userName} <<EOF
cd ~/${installDir}
npm cache clean --force
yarn cache clean
EOF
# ȷ�ϰ�װ
su - ${userName} <<EOF
cd ~/${installDir}
echo "===================ȷ�ϰ�װ==================="
bench version
EOF
echo "===================��Ҫ���л���==================="
for i in "${rteArr[@]}"
do
    echo ${i}
done
if [[ ${#warnArr[@]} != 0 ]]; then
    echo "===================����==================="
    for i in "${warnArr[@]}"
    do
        echo ${i}
    done
fi
echo "����Ա�˺ţ�administrator�����룺${adminPassword}��"
if [[ ${productionMode} == "yes" ]]; then
    if [[ -e /etc/supervisor/conf.d/${installDir}.conf ]]; then
        echo "�ѿ�������ģʽ��ʹ��ip������������վ������${webPort}�˿ڡ�"
    else
        echo "�����ÿ�������ģʽ����supervisor�����ļ�����ʧ�ܣ����ų�������ֶ�������"
    fi
else
    echo "ʹ��su - ${userName}ת��${userName}�û�����~/${installDir}Ŀ¼"
    echo "����bench start������Ŀ��ʹ��ip������������վ������${webPort}�˿ڡ�"
fi
if [[ ${inDocker} == "yes" ]]; then
    echo "��ǰsupervisor״̬"
    /usr/bin/supervisorctl status
    # echo "ֹͣ���н��̡�"
    # /usr/bin/supervisorctl stop all
fi
exit 0