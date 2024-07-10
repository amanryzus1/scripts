#gwyd!0n

# Check if xinetd is running
printf  "\n"
echo "#############################################################################################################################################"
echo "###################################################       NAGIOS CHECK       ################################################################"
echo "#############################################################################################################################################"
printf  "\n"
ok_msg="WORKING:"
err_msg="ERROR!:"
NAGIOS_CONFIG_PATH=/usr/local/nagios/etc/
IP=127.0.0.1
SERVER_IP='127.0.0.1'
CLIENT_IP='127.0.0.1'
PROGNAME=$(basename "$0")
REVISION="1.0.0"
print_revision() {
        echo "          #####$1 v$2 (Version)#####         "
}

print_usage() {
    echo "######################################################################"
    echo "Usage: $PROGNAME server"
    echo "Usage: $PROGNAME client"
    echo "Usage: $PROGNAME --help or -h"
    echo "Usage: $PROGNAME --version or -V"
    echo "######################################################################"
}
print_help() {
    print_revision "$PROGNAME" $REVISION
    echo ""
    print_usage
}
# Make sure the correct number of command line arguments have been supplied

if [ $# -lt 1 ]; then
    print_usage
    exit -1
fi

status=0
xinetd_process_is_running () {
    xinetd_pid=$(pidof xinetd)
    if [ -z "$xinetd_pid" ]; then
      err_msg="$err_msg \nxinetd : not running"
      status=2
    else
      ok_msg="$ok_msg \nxinetd is running"
    fi
}
# Check if xinetd service is enabled and running
xinetd_is_enabled () {
    xinetd_service_status=$(systemctl is-enabled xinetd.service)
    if [ "$xinetd_service_status" != "enabled" ]; then
      err_msg="$err_msg \nxinetd service is not enabled, enabling it"
      systemctl enable xinetd
      status=2
    else
      ok_msg="$ok_msg \nxinetd service is enabled"
    fi
}

crond_service_check () {
    crond_service_status=$(systemctl is-active crond.service)
    if [ "$crond_service_status" != "active" ]; then
      err_msg="$err_msg \ncrond service is not active, starting it"
      systemctl start crond
      status=2
    else
      ok_msg="$ok_msg \ncrond is active"
    fi
}

xinetd_service_check () {
    xinetd_service_status=$(systemctl is-active xinetd.service)
    if [ "$xinetd_service_status" != "active" ]; then
      err_msg="$err_msg \nxinetd service is not active, starting it"
      systemctl start xinetd
      status=2
    else
      ok_msg="$ok_msg \nxinetd is active"
    fi
}
nagios_service_check () {
    nagios_service_error=$(/usr/local/nagios/bin/nagios -v ${NAGIOS_CONFIG_PATH}nagios.cfg|grep Errors | awk '{print $3}')
    nagios_service_warning=$(/usr/local/nagios/bin/nagios -v ${NAGIOS_CONFIG_PATH}nagios.cfg|grep Warnings | awk '{print $3}')
    if [ "$nagios_service_error" != "0" -o "$nagios_service_warning" != "0"  ]; then
      err_msg="$err_msg \nServices configured in NAGIOS have error; Please check in detail with the command '/usr/local/nagios/bin/nagios -v ${NAGIOS_CONFIG_PATH}nagios.cfg' "
      status=2
    else
      ok_msg="$ok_msg \nall nagios services are configured correctly"
    fi
}
check_nrpe () {
    /usr/local/nagios/libexec/check_nrpe -H  $1 &>/dev/null
    if [ $? -eq 2 ]; then
        err_msg="$err_msg \nerror in check nrpe binary"
        status=2
    else
         ok_msg="$ok_msg \ncheck_nrpe binary working fine for IP $1"
    fi
}
check_nrpe_generate() {
    /usr/local/nagios/libexec/check_nrpe -H  $CLIENT_IP -c generate_nrpe_cfg &>/dev/null
    if [ $? -eq 2 ]; then
        err_msg="$err_msg \nerror while generate config"
        status=2
    else
         ok_msg="$ok_msg \nGenerate_config binary working fine"
    fi
}
nagios_dir_permissions () {
    DIR="/usr/local/nagios"
    for file in $(find $DIR); do
        if [ "$(stat -c %U $file)" != "nagios" ]; then
            err_msg="$err_msg \nFile $file is not owned by nagios therefore changing it to nagios"
            chown nagios:nagios $file
            status=2
        fi
    done
}
nagios_var_directory_structure_check_for_older_nagios () {
    expected_structure="archives  nagios.log  nrpe.log  objects.cache  perfdata.log  retention.dat  rrd  rw  spool  status.dat"
    current_output=$(ls /usr/local/nagios/var/)
    my_array=()
    for file in /usr/local/nagios/var/*; do
      my_array+=("$file")
    done
    var_files=("/usr/local/nagios/var/rrd" "/usr/local/nagios/var/rw" "/usr/local/nagios/var/spool" "/usr/local/nagios/var/status.dat")
    for i in "${var_files[@]}"; do
      if [[ ! " ${my_array[*]} " =~ " $i " ]]; then
        err_msg="$err_msg \n$i is not present in the filepath array"
        status=2
      fi
    done
}

verify_ip_in_nrpe_cfg_client () {
    IP_CONFIGURED=$(cat ${NAGIOS_CONFIG_PATH}nrpe.cfg |grep  generate_nrpe_cfg | awk '{print $2,$3}')
    cmp_ip="$SERVER_IP $CLIENT_IP"
    if [[ $cmp_ip != $IP_CONFIGURED ]]; then
        err_msg="$err_msg \nIPs in nrpe.cfg do not matching with the IPs configured in the script. "
        status=2
    else
        ok_msg="$ok_msg \nIPs are configured correctly on nagios CLIENT"
    fi
}

verify_ip_in_nrpe_cfg () {
    IP_CONFIGURED=$(cat ${NAGIOS_CONFIG_PATH}nrpe.cfg |grep  generate_nrpe_cfg | awk '{print $2,$3}')
    cmp_ip="$SERVER_IP $SERVER_IP"
    if [[ $cmp_ip != $IP_CONFIGURED ]]; then
        err_msg="$err_msg \nIPs in nrpe.cfg do not matching with the IPs configured in the script. "
        status=2
    else
        ok_msg="$ok_msg \nIPs are configured correctly on nagios SERVER"
    fi
}
check_ssl_certificate () {
    SSL_YEAR=$(openssl x509 -in ${NAGIOS_CONFIG_PATH}ssl/nagios_server_certs/nagios_server.pem -noout -text | grep -i "not after" | awk '{print $7}')
    if [[ $SSL_YEAR < 2026 ]]; then
        err_msg="$err_msg \nSSL certificate has expired "
        status=2
        if [ ! -f "replace_ssl_certs.sh" ]; then
            echo "ssh automation script doesnt exists. Automatic updradation of script not possible"
        else
            exit_status=0
            source replace_ssl_certs.sh
            $exit_status=$?
            if [ $exit_status -eq 0 ]; then
                ok_msg="$ok_msg \nCertificates replaced successfully"
            else
                err_msg="$err_msg \nCertificates replaced with an error: $exit_status"
            fi
        fi
    else
        ok_msg="$ok_msg \nSSl certificates are configured correctly"
    fi
}
verify_nagios_service () {
    if [ ! -f "/usr/local/nagios/var/nagios.lock" ]; then
        /etc/init.d/nagios status
        echo 'starting nagios as its not running'
        /etc/init.d/nagios start
        ok_msg="$ok_msg \nNagios service started successfully running !"
    else
        /etc/init.d/nagios status
        ok_msg="$ok_msg \nNagios service is running !"
        
    fi

}
while test -n "$1"; do
    case "$1" in
      --help)
            print_help
            exit 0
            ;;
      -h)
            print_help
            exit 0
            ;;
      --version)
            print_revision "$PROGNAME" $REVISION
            exit 0
            ;;
      -V)
            print_revision "$PROGNAME" $REVISION
            exit 0
            ;;
      server)
            echo "Checking server side nrpe/nagios"
            xinetd_process_is_running
            xinetd_is_enabled
            crond_service_check
            xinetd_service_check
            nagios_service_check
            check_nrpe $SERVER_IP
            nagios_dir_permissions
            nagios_var_directory_structure_check_for_older_nagios
            verify_ip_in_nrpe_cfg
            check_nrpe_generate
            check_ssl_certificate
            verify_nagios_service
            echo -e $ok_msg
            if [ $status -eq 2 ]; then
                echo -e $err_msg
            fi
            echo -e "End of Debugging No Issues Found Congratulations!\n"
            exit $status
            ;;
      client)
            echo "Checking client side nrpe/nagios"
            xinetd_process_is_running
            xinetd_is_enabled
            xinetd_service_check
            check_nrpe $CLIENT_IP
            check_nrpe $SERVER_IP
            verify_ip_in_nrpe_cfg_client
            nagios_dir_permissions
            check_ssl_certificate
            echo -e $ok_msg
            if [ $status -eq 2 ]; then
                echo -e $err_msg
            fi
            echo -e "End of Debugging No Issues Found Congratulations!\n"
            exit $status
            ;;
        esac
        shift
done