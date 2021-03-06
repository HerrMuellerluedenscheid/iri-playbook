#!/usr/bin/env bash
# This script will auto-detect the OS and Version
# It will update system packages and install Ansible and git
# Then it will clone the iri-playbook and run it.

# Iri playbook: https://github.com/nuriel77/iri-playbook
# By Nuriel Shem-Tov (https://github.com/nuriel77), December 2017

set -o pipefail
set -e

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   echo "Please change to root: 'sudo su -' and re-run"
   exit 1
fi

clear
cat <<'EOF'
                                                                   .odNMMmy:                       
                                                                   /MMMMMMMMMy                      
                                                                  `NMMMMMMMMMM:                     
                                                                   mMMMMMMMMMM-                     
                                `::-                               -dMMMMMMMN/                      
                    `+sys/`    sNMMMm/   /ydho`                      :oyhhs/`                       
                   :NMMMMMm-  -MMMMMMm  :MMMMMy  .+o/`                                              
                   hMMMMMMMs   sNMMMm:  `dMMMN/ .NMMMm                                              
                   -mMMMMMd.    `-:-`     .:-`  `hMMNs -syo`          .odNNmy/        `.            
                    `:oso:`                       `.`  mMMM+         -NMMMMMMMy    :yNNNNh/         
                       `--.      :ydmh/    `:/:`       -os+`/s+`     sMMMMMMMMM`  +MMMMMMMMs        
                     .hNNNNd/   /MMMMMM+  :mMMMm-   ``     -MMM+     -NMMMMMMMy   hMMMMMMMMN        
            ``       mMMMMMMM-  :MMMMMM/  oMMMMM/ .hNNd:    -/:`      .odmmdy/`   :NMMMMMMN+        
         -sdmmmh/    dMMMMMMN.   -shhs:   `/yhy/  /MMMMs `--`           ````       .ohddhs-         
        :NMMMMMMMy   `odmNmy-                      /ss+``dNNm.         .-.`           ``            
        yMMMMMMMMM`    ``.`                             `hNNh.       /dNNNms`      `-:-`            
        :NMMMMMMMs          .--.      /yddy:    .::-`    `..`       /MMMMMMMh    `smNNNms`          
         .ohdmdy:         -hmNNmh:   +MMMMMM/  /mMMNd.   ``         :MMMMMMMy    oMMMMMMMs   `-::.  
            ```  ``      `NMMMMMMN.  +MMMMMN:  yMMMMM- -hmmh-        /hmNNdo`    +MMMMMMM+  +mNMNNh-
              -sdmmdy:   `mMMMMMMN`   :yhhs-   `+hhy:  oMMMMo          ...`       /hmmmh/  :MMMMMMMm
             /NMMMMMMNo   .sdmmmy-                     `+yy/`     -+ss+.            `.`    .NMMMMMMh
             dMMMMMMMMN     `..`                                 /NMMMMm-      :shyo.       -sdmmh+`
     `       /NMMMMMMMo                 .-.                      oMMMMMM/     sMMMMMm.        ```   
 `/ydddho-    -sdmmdy:                `hNNms                     `odmmd+      yMMMMMN-   -shhs:     
-mMMMMMMMNo     ````           `--.   `mMMMm                 `-//- `..        `odddy:   :NMMMMN/    
mMMMMMMMMMM:            .//.   yNMN/   .+o/.                `dMMMNo       ./o+-  ``     /MMMMMM+    
mMMMMMMMMMM:            dMMd   ommd:     -+o/.              .NMMMMy      -mMMMN+         /hddh/     
:mMMMMMMMNs             -oo-    .:.     +NMMMm-         .//- -shy+`      -NMMMMo    `/oo:`  `       
 `+ydmmdo-            `ohy/    smmdo    oMMMMN:        /NMMN+       `:++- -oso:    `dMMMMh          
     ``               /MMMm   `NMMMN`    :oso-         :mMMN/       oMMMM/         `mMMMMh          
                       :o+-    -oyo-         -+oo:`     .::.   -oo: /mNNm-     -+o/``/ss/`          
                      `:oo:      .:/-`      oMMMMMh`          `NMMM- `--`     :MMMMy                
                      oMMMM/    :mMMMm-     mMMMMMM.           +hho`     .+s+`.dNNm+                
                      :mNNd-    oMMMMM/     -hmNNd/                 -o+. hMMMo  .-`                 
                       `..``    `/yhy/        `.`  `:oss+.          mMMh -shs.                      
                        :ydds.       .://.        `hMMMMMN+         -+/.                            
                       .MMMMMm      +NMMMMy       /MMMMMMMm                                         
                        yNNNN+      mMMMMMM-      `dMMMMMN+    ````                                 
                         .--` ``    :dNNNmo         :oss+.   -ydNNmh/                               
                            /hmmh+`   .--`  ./++:`          /MMMMMMMMy                              
                           :MMMMMMs        yMMMMMm/         hMMMMMMMMM      `-::-`                  
                           -NMMMMM+       /MMMMMMMN         :NMMMMMMMo    -yNMMMMMh:                
                            .oyys-   ``   `mMMMMMMs          .ohmmds-    -NMMMMMMMMM+               
                                  `+dNNmy- `+yhhs:   `ohmmds-            sMMMMMMMMMMd               
                                  hMMMMMMM-         -NMMMMMMMs           :MMMMMMMMMMo               
                                  dMMMMMMM:         yMMMMMMMMM`           :dMMMMMMm+                
                                  .hMMMMm+          :MMMMMMMMy              .:++/.                  
                                    `--.             -ymMMNh/                         

EOF


echo "Welcome to IOTA FullNode Installer!"
echo "This script is going to install IOTA full node."
read -p "Do you wish to proceed? [y/N] " yn
if echo "$yn" | grep -v -iq "^y"; then
    echo Cancelled
    exit 1
fi


function set_dist() {
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        echo "Unsupported OS."
        exit 1
    elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        echo "Old OS version. Minimum required is 7."
        exit 1
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS=$(uname -s)
        VER=$(uname -r)
    fi
}

function init_centos(){
    echo "Updating system packages..."
    yum update -y

    echo "Install yum utils..."
    yum install -y yum-utils

    set +e
    set +o pipefail
    if $(needs-restarting -r 2>&1 | grep -q "Reboot is required"); then
        inform_reboot
        exit 0
    fi
    set -o pipefail
    set -e

    echo "Installing Ansible and git..."
    yum install ansible git expect-devel -y

}

function init_ubuntu(){
    echo "Updating system packages..."
    apt update -qqy --fix-missing
    apt-get upgrade -y
    apt-get clean
    apt-get autoremove -y --purge

    echo "Check reboot required..."
    if [ -f /var/run/reboot-required ]; then
        inform_reboot
        exit 0
    fi

    echo "Installing Ansible and git..."
    apt-get install software-properties-common -y
    apt-add-repository ppa:ansible/ansible -y
    apt-get update -y
    apt-get install ansible git expect-dev -y
}

function inform_reboot() {
cat <<EOF


======================== PLEASE REBOOT AND RE-RUN THIS SCRIPT =========================

Some system packages have been updated which require a reboot
and allow the node installer to proceed with the installation.

*** Please reboot this machine and re-run this script ***


>>> To reboot run: 'shutdown -r now', when back online:
bash <(curl https://raw.githubusercontent.com/nuriel77/iri-playbook/master/fullnode_install.sh)

!! Remember to re-run this script inside a "screen" session: 'screen -S iota' !!


EOF
}

function get_password() {
    unset PASSWORD
    unset CHARCOUNT
    stty -echo

    CHARCOUNT=0
    while IFS= read -p "$PROMPT" -r -e -s -n 1 CHAR; do
        # Enter - accept password
        if [[ $CHAR == $'\0' ]]; then
            break
        fi
        # Backspace (BUG: Doesn't work, no big deal)
        # If user had a mistake he will have to re-enter
        if [[ $CHAR == $'\177' ]] ; then
            if [ $CHARCOUNT -gt 0 ] ; then
                CHARCOUNT=$((CHARCOUNT-1))
                PROMPT=$'\b \b'
                PASSWORD="${PASSWORD%?}"
            else
                PROMPT=''
            fi
        else
            CHARCOUNT=$((CHARCOUNT+1))
            PROMPT='*'
            PASSWORD+="$CHAR"
        fi
    done

    stty echo
    echo $PASSWORD
}

function set_password() {
    echo "--------------"
    echo "Please enter the password with which you will connect to IOTA Peer Mananger"
    echo "Use a stong password!!! Not 'hello123' or 'iota8181', you get the point ;)"
    echo -n "Password: "
    PASSWORD_A=$(get_password)
    echo
    echo -n "Please repeat: "
    PASSWORD_B=$(get_password)
    if [ "$PASSWORD_A" != "$PASSWORD_B" ]; then
        echo -e "\n\nPasswords do not match!\n"
        set_password
    fi
    PASSWORD=$(echo ${PASSWORD_A} | sed 's|\\|\\\\|g' | sed 's|/|\\/|g' | sed 's|\&|\\&|g')
    sed -i "s/^iotapm_nginx_password:.*$/iotapm_nginx_password: '${PASSWORD}'/" group_vars/all/iotapm.yml
}

# Get primary IP from ICanHazIP, if it does not validate, fallback to local hostname
function set_primary_ip()
{
  echo "Getting external IP address..."
  local ip=$(curl -s -f --max-time 10 --retry 2 -4 'https://icanhazip.com')
  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "Got IP $ip"
    PRIMARY_IP=$ip
  else
    PRIMARY_IP=$(hostname -I|tr ' ' '\n'|head -1)
    echo "Failed to get external IP... using local IP $PRIMARY_IP instead"
  fi
}

function display_requirements_url() {
    echo "Please check requirements here: http://iri-playbook.readthedocs.io/en/master/requirements.html#the-requirements"
}

function check_arch() {
    # Check architecture
    ARCH=$(uname -m)
    if [ "$ARCH" != "x86_64" ]; then
        echo "ERROR: $ARCH architecture not supported"
        display_requirements_url
        exit 1
    fi
}

# Get OS and version
set_dist

# Check OS version compatibility
if [[ "$OS" =~ ^(CentOS|Red) ]]; then
    if [ "$VER" != "7" ]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    init_centos
elif [[ "$OS" =~ ^Ubuntu ]]; then
    if [[ ! "$VER" =~ ^(16|17) ]]; then
        echo "ERROR: $OS version $VER not supported"
        display_requirements_url
        exit 1
    fi
    check_arch
    init_ubuntu
else
    echo "$OS not supported"
    exit 1
fi

echo "Verifying Ansible version..."
ANSIBLE_VERSION=$(ansible --version|head -1|awk {'print $2'}|cut -d. -f1-2)
if (( $(awk 'BEGIN {print ("'2.4'" > "'$ANSIBLE_VERSION'")}') )); then
    echo "Error: Ansible minimum version 2.4 required."
    echo "Please remove Ansible: (yum remove ansible -y for CentOS, or apt-get remove -y ansible for Ubuntu)."
    echo
    echo "Then refer to the documentation on how to get latest Ansible installed:"
    echo "http://docs.ansible.com/ansible/latest/intro_installation.html#latest-release-via-yum"
    exit 1
fi

echo "Git cloning iri-playbook repository..."
cd /opt

if [ -d iri-playbook ]; then
    rm -rf iri-playbook
fi

# Clone the repository (optional branch)
git clone $GIT_OPTIONS https://github.com/nuriel77/iri-playbook.git
cd iri-playbook

# Set password for web access (ipm and grafana)
set_password
echo -e "\nRunning playbook..."

# Ansible output log file
LOGFILE=/tmp/iri-playbook-$(date +%Y%m%d%H%M).log

# Run the playbook
set +e
unbuffer ansible-playbook -i inventory -v site.yml -e "memory_autoset=true" | tee "$LOGFILE"
RC=$?
if [ $RC -ne 0 ]; then
    echo "ERROR! The playbook exited with failure(s). A log has been save here '$LOGFILE'"
    exit $RC
fi
set -e

# Calling set_primary_ip
set_primary_ip

cat <<EOF
*** Installation done! ***

A log of this installation has been saved to: $LOGFILE


You should be able to connect to IOTA Peer Manager pointing your browser to:

http://${PRIMARY_IP}:8811


You can reach the monitoring (grafana) graphs at:

http://${PRIMARY_IP}:5555


Note that your IP might be different as this one has been auto-detected in best-effort.
You can use the username 'iotapm' and the password you entered during the installation.


Please refer to the tutorial for post-installation information:
http://iri-playbook.readthedocs.io/en/master/post-installation.html

EOF
