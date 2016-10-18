#!/bin/sh

function getRootUUID() {
  # cat /proc/partitionsから、/が割り当てられている区画を
  # ROOTUUID=へ割り当てる。
  ROOTUUID=""
  for arg in `cat /proc/cmdline`;
    do
      if [ ${arg} != "${arg##root=UUID=}" ]; then
        ROOTUUID=${arg##root=UUID=}
      elif [ ${arg} != "${arg##root=live:UUID=}" ] ; then
        ROOTUUID=${arg##root=live:UUID=}
      fi
    done
  echo ${ROOTUUID}
  return
}

function hasRootUUID() {
  # 引数として与えたデバイスが、RootUUIDを持つかどうかを確認する。
  getRootUUID 1> /dev/null  # ${ROOTUUID}を取得。
  RESULT="False"
  if [ ${1} ]; then
    for line in `udevadm info --name=${1}`;
      do
        if [ ${line} != "${line##ID_FS_UUID=}" ]; then
          if [ ${ROOTUUID} == ${line##ID_FS_UUID=} ]; then
            RESULT="True"
          fi
        fi
      done
  fi
  echo ${RESULT}
  return
}

function isSystemDisk() {
  # 引数として与えたデバイスが、システムデバイス（起動デバイス）であるかを確認する。
  RESULT='False'
  if [ ${1} ];then
    for part in `cat /proc/partitions | tail -n +3 | awk '{print $4}' | egrep ${1}[1-9]$`;
      do
        if [ `hasRootUUID ${part}` == 'True' ]; then
          RESULT='True'
        fi
      done
  fi
  echo ${RESULT}
  return
}

function hasBootFlag() {
  # 引数として与えたデバイスがブートデバイスかどうかを確認
  # hadBootFlag sda --> True or False
  RESULT="False"
  if [ ${1} ]; then
    if [ `parted /dev/${1} print 2> /dev/dull | egrep -i "boot|bios_grub"| sed -e "s/^.*\(boot\|bios_grub\).*$/\1/"` ]; then
      RESULT="True"
    fi
  fi
  echo ${RESULT}
  return
}

function hasPartitions() {
  # 引数として与えたデバイスが区画を設定されているか確認する。
  RESULT="False"
  if [ ${1} ]; then
    for part in `cat /proc/partitions | tail -n +3 | awk '{print $4}' | egrep ${1}[1-9]$`;
      do
        if [ ${part} ]; then
          RESULT='True'
        fi
      done

  fi
  echo ${RESULT}
  return
}

function getModelName() {
  # 引数として与えたデバイスのモデル名を返す。
  RESULT=""
  if [ ${1} ]; then
    for line in `udevadm info --name ${1}`;
      do
        if [ ${line} != "${line##ID_MODEL=}" ]; then
           RESULT=${line##ID_MODEL=}
        fi
      done
  fi
  echo ${RESULT}
  return
}

function getBlockDevices() {
  # サーバに接続されているディスクの内、bootフラグを持っているディスクの一覧を取得
  BLOCKDEVICES=()
  for dev in `cat /proc/partitions | tail -n +3 | awk '{print $4}' | egrep sd[a-z]$`;
    do
      BLOCKDEVICES+=(${dev})
    done
  echo ${BLOCKDEVICES[@]}
  return
}

function FSchecker() {
  # 引数として与えたデバイスの区画が、引数として与えたファイルシステムを持つか確認する。
  # Ex) FSchecker /dev/sda 3 xfs 
  #     sda3のファイルシステムがxfsか確認。
  result=False
  FS=$(parted $1 print 2> /dev/null | egrep "^\s$2" | sed -e "s/^.*\($3\).*$/\1/")
  if [ ${FS} ] ; then
    result=True
  fi
  echo ${result}
  return
}

function getCapacity() {
  # 引数として与えたデバイスの容量を返す。デバイスが存在しなければ、Noneを返す。 
  RESULT=None
  if [ -e /dev/${1} ]; then
    RESULT=$(parted /dev/${1} print | egrep -i "[0-9].*GB\$"| sed -e 's/^.*\s\([0-9].*GB\)$/\1/')
  fi
  echo ${RESULT}
  return
}

