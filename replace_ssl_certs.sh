#gwyd!0n

#check if nagios path exists
printf  "\n"
echo "#############################################################################################################################################"
echo "###################################################        Replace SSL       ################################################################"
echo "#############################################################################################################################################"
printf  "\n"

dir_path="/usr/local/nagios/etc"

if [ -d "$dir_path/ssl/" ]; then
    echo "ssl certifcates exist! moving them to backed up folder!"
    ssl_path=$dir_path/ssl
    timestamp=$(date "+%Y%m%d%H%M%S")
    new_ssl_path="${ssl_path}_${timestamp}"

    mv "$ssl_path" "$new_ssl_path"
    echo "new scripts placed at $ssl_path"
    nrpe_cfg="$dir_path/nrpe.cfg"
    tar -xf  ssl.tar
    mv ssl "$ssl_path"
    echo "new scripts copied to config folder"
    sed -i "/^ssl_cacert_file/c\ssl_cacert_file=${dir_path}/ssl/ca/ca_cert.pem" $nrpe_cfg
    sed -i "/^ssl_cert_file/c\ssl_cert_file=${dir_path}/etc/ssl/client_certs/client_cert.pem" $nrpe_cfg
    sed -i "/^ssl_privatekey_file/c\ssl_privatekey_file=${dir_path}/etc/ssl/client_certs/client_cert.key" $nrpe_cfg
    echo "new scripts have been confgured in the nrpe.cfg!"
    exit 0
else
    echo "ssl directoy does not exist!"
    exit 2
fi