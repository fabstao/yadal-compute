#!/bin/bash

if [ $# -lt 5 ]; then
	echo "USAGE: $0 <vm name> <network> <ram (in MB)> <VCPUs> <disk size> <key>"	
	exit 1
fi

BASEDIR=/opt/yadal
POOL=/opt/cloudstg
BASE=basec9.qcow2
VMNAME=$1
VIRSH="virsh -c qemu:///system "

#sed -e "s/MYSSHKEY/${SSHKEY}/g" -e 's/MYHOSTNAME/'${VMNAME}'/g' ${BASEDIR}/user-data.tmp > ${BASEDIR}/user-data
source venv/bin/activate
./renderTemplates.py --ssh-key $6.pub --hostname $1

cat ${BASEDIR}/user-data
echo
cat ${BASEDIR}/meta-data

let GROWTH=$5
if [ ${GROWTH} -lt 15 ]; then
	echo "FATAL: Need larger disk size, minimum 15G"
	exit 1
fi

truncate -r ${POOL}/${BASE} ${POOL}/${VMNAME}.qcow2
truncate -s +${GROWTH}G ${POOL}/${VMNAME}.qcow2

virt-resize --expand /dev/sda1 ${POOL}/${BASE} ${POOL}/${VMNAME}.qcow2 

virt-filesystems --partitions --long -h --all -a ${POOL}/${VMNAME}.qcow2

ls -lrth ${POOL}

virt-install --connect qemu:///system --name $1 --memory $3 --vcpus $4 --network network=$2,model=virtio \
 --cloud-init user-data=${BASEDIR}/user-data,meta-data=${BASEDIR}/meta-data,root-password-file=./.cowboy,ssh-key=$6 --import \
  --disk ${POOL}/${VMNAME}.qcow2 --graphics vnc --os-variant linux2020  --noautoconsole

sleep 8
DOMN=$(${VIRSH} list | grep $VMNAME | grep -v grep |  awk '{print $1}')
${VIRSH} domifaddr ${DOMN}
sleep 9
${VIRSH} domifaddr ${DOMN}
