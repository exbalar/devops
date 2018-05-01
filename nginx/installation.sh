#!/usr/bin/bash
#############################
## Author : Balasubramanian Ramar
############################

targetFile=/etc/nginx/conf.d/default.conf
osVersion=0
osName=X
function checkOSDetails(){
   osDetails=$(cat /etc/redhat-release)
   if [[ $osDetails = *"Linux"* ]]
        then
        osName=RHEL
   else
        osName=OTHER
   fi

   if [[ $osDetails = *"release 7"* ]] 
	then
	osVersion=7
   else
	osVersion=6
   fi

}
function addHeader(){
   echo -e "\tproxy_set_header X-Forwarded-Host  $1:$2;" >> $targetFile 
   echo -e  "\tproxy_set_header Host  $4;" >> $targetFile
   echo -e  "\tproxy_set_header X-Forwarded-Proto  http;" >> $targetFile
}

function buildLocation(){
  echo -e "location $1  {" >>$targetFile
  echo -e "\n"
  echo -e "        proxy_pass $3://$2:$4$1;" >> $targetFile
  addHeader $rpHost $rpPort $6 $2 >> $targetFile
  echo -e "\n"
  echo -e "}" >> $targetFile

}

function generateCerts(){
  echo -e "\n\n\n\n\n\n\n\n\n" | $(openssl req -out CSR.csr -new -newkey rsa:2048 -nodes -keyout privateKey.key)
  echo -e "\n\n\n\n\n\n" |$(openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout privateKey.key -out cert.pem)
}

curdir=$(pwd)
checkOSDetails
os=$osName
os_subversion=$osVersion

if [ -z "$1" -o -z "$2" ]
	then
	echo "2 parameters are needed!  <Protocol> <Backend Host> Example : (http 10.33.32.44)" 
	exit
fi

echo "Welcome to Nginx installation!!"

rpmURL=null
if [ $os == "RHEL" ]
	then
	if [ $os_subversion == 6 ]
		then
		rpmURL=http://nginx.org/packages/rhel/6/x86_64/RPMS/nginx-1.12.2-1.el6.ngx.x86_64.rpm
        else
                rpmURL=http://nginx.org/packages/rhel/7/x86_64/RPMS/nginx-1.12.2-1.el7_4.ngx.x86_64.rpm

        fi
else
	echo "only RHEL is supported!"
	exit
fi

echo $(curl $rpmURL >> nginx.rpm) > /dev/null


echo $(rpm -ivh --force nginx.rpm) > /dev/null

echo $(mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.backup)
echo $(touch /etc/nginx/conf.d/default.conf)
echo $(chmod 777 /etc/nginx/conf.d/default.conf)
rpHost=$HOSTNAME
rpPort=81
rpProto=$1
backendPort=8080
backendHost=$2
backendURL=appURL
echo "       server { " >> $targetFile

if [ $rpProto == "https" ]
	then 
	generateCerts
	rpPort=443
	echo "listen       $rpPort  ssl;" >> $targetFile
	echo "ssl_certificate $curdir/cert.pem;" >> $targetFile
   	echo "ssl_certificate_key  $curdir/privateKey.key;" >> $targetFile
else
	echo "listen $rpPort  default_server;" >> $targetFile
fi

echo "server_name  $rpHost;"  >> $targetFile

buildLocation /$backendURL/ $backendHost $rpProto $backendPort $rpHost $rpPort

echo "}"  >> $targetFile

echo $($(which nginx) -s quit)
echo $($(which nginx))

echo "Installed successfully!!"
