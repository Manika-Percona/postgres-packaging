#!/usr/bin/env bash

COMPONENT=$1

if [ $( id -u ) -ne 0 ]; then
  echo "It is not possible to install dependencies. Please run as root"
  exit 1
fi
CURPLACE=$(pwd)

# postgresql
if [ "$COMPONENT" = "postgresql" ]; then
if [ "x$OS" = "xrpm" ]; then
  yum -y install wget
  yum clean all
  RHEL=$(rpm --eval %rhel)
  if [ x"$RHEL" = x6 -o x"$RHEL" = x7 ]; then
    until yum -y install centos-release-scl; do
      echo "waiting"
      sleep 1
    done
    yum -y install epel-release
    INSTALL_LIST="bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel llvm-toolset-7-clang llvm5.0-devel openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed python2-devel readline-devel rpm-build rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel python3-devel lz4-devel libzstd-devel perl-IPC-Run perl-Test-Simple rpmdevtools"
    yum -y install ${INSTALL_LIST}
    source /opt/rh/devtoolset-7/enable
    source /opt/rh/llvm-toolset-7/enable
  else
	  dnf config-manager --set-enabled ol${RHEL}_codeready_builder
    INSTALL_LIST="chrpath clang-devel clang llvm-devel python3-devel perl-generators bison e2fsprogs-devel flex gettext git glibc-devel krb5-devel libicu-devel libselinux-devel libuuid-devel libxml2-devel libxslt-devel openldap-devel openssl-devel pam-devel patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed readline-devel rpmdevtools selinux-policy systemd systemd-devel systemtap-sdt-devel tcl-devel vim wget zlib-devel lz4-devel libzstd-devel perl-IPC-Run perl-Test-Simple rpmdevtools"
  	yum -y install rpmbuild || yum -y install rpm-build || true
    yum -y install ${INSTALL_LIST}
    yum -y install binutils gcc gcc-c++
	  if [ x"$RHEL" = x8 ]; then
	    yum -y install python2-devel
    else
	    yum -y install python-devel
    fi
      yum clean all
      if [ ! -f  /usr/bin/llvm-config ]; then
        ln -s /usr/bin/llvm-config-64 /usr/bin/llvm-config
      fi
  fi
    yum -y install bzip2-devel gcc gcc-c++ rpm-build || true
    yum -y install cmake cyrus-sasl-devel make openssl-devel zlib-devel libcurl-devel || true
    yum -y install perl-IPC-Run perl-Test-Simple
    yum -y install docbook-xsl libxslt-devel
  if [ x"$RHEL" = x9 ]; then
    yum -y install gcc-toolset-14
  fi
else
  apt-get update || true
  DEBIAN_FRONTEND=noninteractive apt-get -y install gnupg2 curl wget lsb-release quilt
  apt-get update || true
  export DEBIAN=$(lsb_release -sc)
  export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
  ENV export DEBIAN_FRONTEND=noninteractive
  DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata
  ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
  dpkg-reconfigure --frontend noninteractive tzdata
  add_percona_apt_repo
  apt-get update
  if [ "x${DEBIAN}" != "xfocal" -a "x${DEBIAN}" != "xbullseye" -a "x${DEBIAN}" != "xjammy" -a "x${DEBIAN}" != "xbookworm" -a "x${DEBIAN}" != "xnoble" ]; then
    INSTALL_LIST="bison build-essential ccache cron debconf debhelper devscripts dh-exec dh-systemd docbook-xml docbook-xsl dpkg-dev flex gcc gettext git krb5-multidev libbsd-resource-perl libedit-dev libicu-dev libipc-run-perl libkrb5-dev libldap-dev libldap2-dev libmemchan-tcl-dev libpam0g-dev libperl-dev libpython-dev libreadline-dev libselinux1-dev libssl-dev libsystemd-dev libwww-perl libxml2-dev libxml2-utils libxslt-dev libxslt1-dev llvm-dev perl pkg-config python python-dev python3-dev systemtap-sdt-dev tcl-dev tcl8.6-dev uuid-dev vim wget xsltproc zlib1g-dev rename clang gdb liblz4-dev libipc-run-perl libzstd-dev"
  else
    INSTALL_LIST="bison build-essential ccache cron debconf debhelper devscripts dh-exec docbook-xml docbook-xsl dpkg-dev flex gcc gettext git krb5-multidev libbsd-resource-perl libedit-dev libicu-dev libipc-run-perl libkrb5-dev libldap-dev libldap2-dev libmemchan-tcl-dev libpam0g-dev libperl-dev libpython3-dev libreadline-dev libselinux1-dev libssl-dev libsystemd-dev libwww-perl libxml2-dev libxml2-utils libxslt-dev libxslt1-dev llvm-dev perl pkg-config python3 python3-dev systemtap-sdt-dev tcl-dev tcl8.6-dev uuid-dev vim wget xsltproc zlib1g-dev rename clang gdb liblz4-dev libipc-run-perl libzstd-dev"
  fi
  until DEBIAN_FRONTEND=noninteractive apt-get -y --allow-unauthenticated install ${INSTALL_LIST}; do
    sleep 1
    echo "waiting"
  done
fi
fi


# postgresql-common
if [ "$COMPONENT" = "postgresql-common" ]; then
    if [ "x$OS" = "xrpm" ]; then
      yum -y install wget
      yum clean all
      RHEL=$(rpm --eval %rhel)
      if [[ "${RHEL}" -eq 10 ]]; then
        yum install oracle-epel-release-el10
      else
        yum -y install epel-release
      fi
      INSTALL_LIST="git patch perl perl-ExtUtils-MakeMaker perl-ExtUtils-Embed rpmdevtools wget perl-podlators sudo make"
      yum -y install ${INSTALL_LIST}
    else
      apt-get update || true
      apt-get -y install lsb-release
      export DEBIAN=$(lsb_release -sc)
      export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
      apt-get -y install gnupg2
      apt-get update || true
      INSTALL_LIST="git wget debhelper libreadline-dev lsb-release rename devscripts sudo"
      until DEBIAN_FRONTEND=noninteractive apt-get -y install ${INSTALL_LIST}; do
        sleep 1
        echo "waiting"
      done
    fi
fi