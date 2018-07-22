#!/bin/bash
# software
if [ -x "$(command -v yum)" ]; then
  yum makecache fast
  yum install -y ipset ipvsadm
fi
if [ -x "$(command -v apt-get)" ]; then
  apt-get update
  apt-get install -y ipset ipvsadm
fi
# kernel modules
NAME=ipvs-mod
BIN=${NAME}.sh
SVC=${NAME}.service
cat > /usr/local/bin/${BIN} << "EOF"
#!/bin/bash
ipvs_modules="ip_vs ip_vs_lc ip_vs_wlc ip_vs_rr ip_vs_wrr ip_vs_lblc ip_vs_lblcr ip_vs_dh ip_vs_sh ip_vs_nq ip_vs_sed ip_vs_ftp nf_conntrack_ipv4"
for kernel_module in ${ipvs_modules}; do
  /sbin/modprobe ${kernel_module}
done
lsmod | grep ip_vs
MODS=" \
net.ipv4.ip_forward^=^1
net.bridge.bridge-nf-call-iptables^=^1
net.bridge.bridge-nf-call-ip6tables^=^1"
FILE=/etc/sysctl.conf
[ -f $FILE ] || touch $FILE
for MOD in $MODS; do
  MOD=$(echo $MOD | tr "^" " ")
  if ! cat $FILE | grep "$MOD"; then
    echo $MOD >> $FILE
  fi
done
sysctl -p
EOF
chmod +x /usr/local/bin/${BIN}
# mk mod-for-glusterfs.service 
cat > /etc/systemd/system/${SVC} << EOF
[Unit]
Description=Switch-on Kernel Modules Needed by IPVS 

[Service]
Type=oneshot
ExecStart=/usr/local/bin/${BIN}

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable ${SVC} 
systemctl restart ${SVC} 
