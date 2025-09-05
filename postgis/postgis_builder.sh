#!/usr/bin/env bash
set -xe
# Versions and other variables
source ../versions.sh "postgis"
# Common functions
source ../common-functions.sh

get_sources(){
    cd "${WORKDIR}"
    if [ "${SOURCE}" = 0 ]
    then
        echo "Sources will not be downloaded"
        return 0
    fi
    PRODUCT=percona-postgis
    VERSION=${POSTGIS_VERSION}
    echo "PRODUCT=${PRODUCT}" > percona-postgis.properties

    PRODUCT_FULL=${PRODUCT}-${VERSION}.${RELEASE}
    echo "PRODUCT_FULL=${PRODUCT_FULL}" >> percona-postgis.properties
    echo "VERSION=${POSTGIS_VERSION}" >> percona-postgis.properties
    echo "BUILD_NUMBER=${BUILD_NUMBER}" >> percona-postgis.properties
    echo "BUILD_ID=${BUILD_ID}" >> percona-postgis.properties
    git clone "$POSTGIS_GITREPO"
    retval=$?
    if [ $retval != 0 ]
    then
        echo "There were some issues during repo cloning from github. Please retry one more time"
        exit 1
    fi
    mv postgis ${PRODUCT_FULL}
    cd ${PRODUCT_FULL}
    if [ ! -z "$POSTGIS_BRANCH" ]
    then
        git reset --hard
        git clean -xdf
        git checkout "$POSTGIS_BRANCH"
    fi
    REVISION=$(git rev-parse --short HEAD)
    echo "REVISION=${REVISION}" >> ${WORKDIR}/percona-postgis.properties
    rm -fr debian rpm

    git clone https://salsa.debian.org/debian-gis-team/postgis.git deb_packaging
    cd deb_packaging
        #git checkout -b 12 debian/12.9-1
    cd ../
    mv deb_packaging/debian ./
    rm -rf deb_packaging
    cd debian
        for file in $(ls | grep postgis); do
            mv $file "percona-$file"
        done
        rm -f rules* control* percona-postgis.install patches/sfcgal*
        wget https://raw.githubusercontent.com/percona/postgres-packaging/${PPG_VERSION}/postgis/debian/rules
        wget https://raw.githubusercontent.com/percona/postgres-packaging/${PPG_VERSION}/postgis/debian/control
        wget https://raw.githubusercontent.com/percona/postgres-packaging/${PPG_VERSION}/postgis/debian/percona-postgis.install
        wget https://raw.githubusercontent.com/percona/postgres-packaging/${PPG_VERSION}/postgis/debian/percona-postgresql-15-postgis-3-scripts.install
        wget https://raw.githubusercontent.com/percona/postgres-packaging/${PPG_VERSION}/postgis/debian/percona-postgresql-15-postgis-3-scripts.lintian-overrides
        wget https://raw.githubusercontent.com/percona/postgres-packaging/${PPG_VERSION}/postgis/debian/percona-postgresql-15-postgis-3-scripts.postinst
        wget https://raw.githubusercontent.com/percona/postgres-packaging/${PPG_VERSION}/postgis/debian/percona-postgresql-15-postgis-3-scripts.prerm
        wget https://raw.githubusercontent.com/percona/postgres-packaging/${PPG_VERSION}/postgis/debian/percona-postgresql-15-postgis-3.install
        wget https://raw.githubusercontent.com/percona/postgres-packaging/${PPG_VERSION}/postgis/debian/percona-postgresql-15-postgis-3.lintian-overrides
	cp control control.in
        # Remove the sfcgal patch entry from patches/series
        sed -i '/sfcgal/d' patches/series
       # sed -i 's/postgresql-12/percona-postgresql-12/' percona-postgresql-12.templates
        echo "9" > compat
    cd ../
    #{relax-test-timing-constraints.patch
    sed -i 's:200:500:g' regress/core/interrupt_relate.sql
    sed -i 's:250:500:g' regress/core/interrupt.sql
    sed -i 's:200:500:g' regress/core/interrupt_buffer.sql
    sed -i '1d' debian/patches/series
    #relax-test-timing-constraints.patch}
    git clone https://git.postgresql.org/git/pgrpms.git
    mkdir rpm
    mv pgrpms/rpm/redhat/main/non-common/postgis33/main/* rpm/
    rm -rf pgrpms
    cd rpm
        rm -f postgis33.spec postgis33-3.3.0-gdalfpic.patch
        wget https://raw.githubusercontent.com/percona/postgres-packaging/${PPG_VERSION}/postgis/rpm/percona-postgis33.spec
        wget https://raw.githubusercontent.com/percona/postgres-packaging/${PPG_VERSION}/postgis/rpm/postgis33-3.3.0-gdalfpic.patch
    cd ../
    cd ${WORKDIR}
    #
    source percona-postgis.properties
    #

    tar --owner=0 --group=0 --exclude=.* -czf ${PRODUCT_FULL}.tar.gz ${PRODUCT_FULL}
    DATE_TIMESTAMP=$(date +%F_%H-%M-%S)
    echo "UPLOAD=UPLOAD/experimental/BUILDS/${PRODUCT}/${PRODUCT_FULL}/${PSM_BRANCH}/${REVISION}/${DATE_TIMESTAMP}/${BUILD_ID}" >> percona-postgis.properties
    mkdir $WORKDIR/source_tarball
    mkdir $CURDIR/source_tarball
    cp ${PRODUCT_FULL}.tar.gz $WORKDIR/source_tarball
    cp ${PRODUCT_FULL}.tar.gz $CURDIR/source_tarball
    cd $CURDIR
    rm -rf percona-postgis*
    return
}

install_gdal(){
    wget http://download.osgeo.org/gdal/3.5.3/gdal-3.5.3.tar.gz -O $CURDIR/gdal-3.5.3.tar.gz
    tar xvf $CURDIR/gdal-3.5.3.tar.gz -C $CURDIR
    cd $CURDIR/gdal-3.5.3
    mkdir build
    cd build
    cmake -DGDAL_BUILD_OPTIONAL_DRIVERS=OFF -DOGR_BUILD_OPTIONAL_DRIVERS=OFF ..
    cmake --build .
    cmake --build . --target install
    ln /usr/local/bin/gdal-config /usr/bin/gdal-config
}

install_sfcgal_el8(){
    wget https://gitlab.com/Oslandia/SFCGAL/-/archive/v1.4.1/SFCGAL-v1.4.1.tar.gz -O $CURDIR/SFCGAL-v1.4.1.tar.gz
    tar xvf $CURDIR/SFCGAL-v1.4.1.tar.gz -C $CURDIR
    cd $CURDIR/SFCGAL-v1.4.1
    cmake -DCGAL_DIR=$CURDIR/CGAL-5.5.2 . && make --include-dir=$CURDIR/CGAL-5.5.2 && make install
    chmod 777 /usr/local/lib64/libSFCGAL.*
    ln /usr/local/bin/sfcgal-config /usr/bin/sfcgal-config
}

install_cgal(){
    wget https://github.com/CGAL/cgal/releases/download/v5.5.2/CGAL-5.5.2.tar.xz -O $CURDIR/CGAL-5.5.2.tar.xz
    tar xf $CURDIR/CGAL-5.5.2.tar.xz -C $CURDIR
    cd $CURDIR/CGAL-5.5.2
    cmake .
    make install
}

install_sfcgal(){
    wget https://gitlab.com/Oslandia/SFCGAL/-/archive/v1.3.10/SFCGAL-v1.3.10.tar.gz -O $CURDIR/SFCGAL-v1.3.10.tar.gz
    tar xvf $CURDIR/SFCGAL-v1.3.10.tar.gz -C $CURDIR
    cd $CURDIR/SFCGAL-v1.3.10
    cmake . && make && make install
    chmod 777 /usr/local/lib/libSFCGAL.*
    cp /usr/local/lib/libSFCGAL.* /usr/lib/postgresql/15/lib
    ldconfig -v | grep -i sfcgal
    ln /usr/local/bin/sfcgal-config /usr/bin/sfcgal-config
}

get_deb_sources(){
    param=$1
    echo $param
    FILE=$(basename $(find $WORKDIR/source_deb -name "percona-postgis*.$param" | sort | tail -n1))
    if [ -z $FILE ]
    then
        FILE=$(basename $(find $CURDIR/source_deb -name "percona-postgis*.$param" | sort | tail -n1))
        if [ -z $FILE ]
        then
            echo "There is no sources for build"
            exit 1
        else
            cp $CURDIR/source_deb/$FILE $WORKDIR/
        fi
    else
        cp $WORKDIR/source_deb/$FILE $WORKDIR/
    fi
    return
}

build_srpm(){
    if [ $SRPM = 0 ]
    then
        echo "SRC RPM will not be created"
        return;
    fi
    if [ "x$OS" = "xdeb" ]
    then
        echo "It is not possible to build src rpm here"
        exit 1
    fi
    cd $WORKDIR
    get_tar "source_tarball" "percona-postgis"
    rm -fr rpmbuild
    ls | grep -v tar.gz | xargs rm -rf
    TARFILE=$(find . -name 'percona-postgis*.tar.gz' | sort | tail -n1)
    SRC_DIR=${TARFILE%.tar.gz}
    #
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    tar vxzf ${WORKDIR}/${TARFILE} --wildcards '*/rpm' --strip=1
    #
    cp -av rpm/* rpmbuild/SOURCES
    cd rpmbuild/SOURCES
    wget https://raw.githubusercontent.com/percona/postgres-packaging/${PPG_VERSION}/postgis/postgis-3.3.8.pdf
    #wget --no-check-certificate https://download.osgeo.org/postgis/docs/postgis-3.3.8.pdf
    #wget --no-check-certificate https://www.postgresql.org/files/documentation/pdf/12/postgresql-12-A4.pdf
    cd ../../
    cp -av rpmbuild/SOURCES/percona-postgis33.spec rpmbuild/SPECS
    #
    mv -fv ${TARFILE} ${WORKDIR}/rpmbuild/SOURCES
    if [ -f /opt/rh/devtoolset-7/enable ]; then
        source /opt/rh/devtoolset-7/enable
        source /opt/rh/llvm-toolset-7/enable
    fi
    rpmbuild -bs --define "_topdir ${WORKDIR}/rpmbuild" --define "dist .generic" \
        --define "version ${VERSION}" --define "pginstdir /usr/pgsql-15"  \
        rpmbuild/SPECS/percona-postgis33.spec
    mkdir -p ${WORKDIR}/srpm
    mkdir -p ${CURDIR}/srpm
    cp rpmbuild/SRPMS/*.src.rpm ${CURDIR}/srpm
    cp rpmbuild/SRPMS/*.src.rpm ${WORKDIR}/srpm
    return
}

build_rpm(){
    if [ $RPM = 0 ]
    then
        echo "RPM will not be created"
        return;
    fi
    if [ "x$OS" = "xdeb" ]
    then
        echo "It is not possible to build rpm here"
        exit 1
    fi
    SRC_RPM=$(basename $(find $WORKDIR/srpm -name 'percona-postgis*.src.rpm' | sort | tail -n1))
    if [ -z $SRC_RPM ]
    then
        SRC_RPM=$(basename $(find $CURDIR/srpm -name 'percona-postgis*.src.rpm' | sort | tail -n1))
        if [ -z $SRC_RPM ]
        then
            echo "There is no src rpm for build"
            echo "You can create it using key --build_src_rpm=1"
            exit 1
        else
            cp $CURDIR/srpm/$SRC_RPM $WORKDIR
        fi
    else
        cp $WORKDIR/srpm/$SRC_RPM $WORKDIR
    fi
    cd $WORKDIR
    rm -fr rpmbuild
    mkdir -vp rpmbuild/{SOURCES,SPECS,BUILD,SRPMS,RPMS}
    cp $SRC_RPM rpmbuild/SRPMS/

    cd rpmbuild/SRPMS/
    #
    cd $WORKDIR
    RHEL=$(rpm --eval %rhel)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    if [ -f /opt/rh/devtoolset-7/enable ]; then
        source /opt/rh/devtoolset-7/enable
        source /opt/rh/llvm-toolset-7/enable
    fi
    if [[ "${RHEL}" -eq 10 ]]; then
        export QA_RPATHS=0x0002
    fi
    rpmbuild --define "_topdir ${WORKDIR}/rpmbuild" --define "dist .$OS_NAME" --define "version ${VERSION}" --define "pginstdir /usr/pgsql-15" --rebuild rpmbuild/SRPMS/$SRC_RPM

    return_code=$?
    if [ $return_code != 0 ]; then
        exit $return_code
    fi
    mkdir -p ${WORKDIR}/rpm
    mkdir -p ${CURDIR}/rpm
    cp rpmbuild/RPMS/*/*.rpm ${WORKDIR}/rpm
    cp rpmbuild/RPMS/*/*.rpm ${CURDIR}/rpm
}

build_source_deb(){
    if [ $SDEB = 0 ]
    then
        echo "source deb package will not be created"
        return;
    fi
    if [ "x$OS" = "xrpm" ]
    then
        echo "It is not possible to build source deb here"
        exit 1
    fi
    rm -rf percona-postgis*
    get_tar "source_tarball" "percona-postgis"
    rm -f *.dsc *.orig.tar.gz *.debian.tar.gz *.changes
    #
    TARFILE=$(basename $(find . -name 'percona-postgis*.tar.gz' | sort | tail -n1))
    DEBIAN=$(lsb_release -sc)
    ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    tar zxf ${TARFILE}
    BUILDDIR=${TARFILE%.tar.gz}
    #
    
    mv ${TARFILE} ${PRODUCT}_${VERSION}.${RELEASE}.orig.tar.gz
    cd ${BUILDDIR}

    cd debian
    rm -rf changelog
    echo "percona-postgis (${VERSION}.${RELEASE}) unstable; urgency=low" >> changelog
    echo "  * Initial Release." >> changelog
    echo " -- SurabhiBhat <surabhi.bhat@percona.com> $(date -R)" >> changelog
 
    cd ../
    
    dch -D unstable --force-distribution -v "${VERSION}.${RELEASE}-${DEB_RELEASE}" "Update to new Percona Platform for PostgreSQL version ${VERSION}.${RELEASE}-${DEB_RELEASE}"
    dpkg-buildpackage -S
    cd ../
    mkdir -p $WORKDIR/source_deb
    mkdir -p $CURDIR/source_deb
    cp *.debian.tar.* $WORKDIR/source_deb
    cp *_source.changes $WORKDIR/source_deb
    cp *.dsc $WORKDIR/source_deb
    cp *.orig.tar.gz $WORKDIR/source_deb
    cp *.debian.tar.* $CURDIR/source_deb
    cp *_source.changes $CURDIR/source_deb
    cp *.dsc $CURDIR/source_deb
    cp *.orig.tar.gz $CURDIR/source_deb
}

build_deb(){
    if [ $DEB = 0 ]
    then
        echo "source deb package will not be created"
        return;
    fi
    if [ "x$OS" = "xrmp" ]
    then
        echo "It is not possible to build source deb here"
        exit 1
    fi
    for file in 'dsc' 'orig.tar.gz' 'changes' 'debian.tar*'
    do
        get_deb_sources $file
    done
    cd $WORKDIR
    rm -fv *.deb
    #
    export DEBIAN=$(lsb_release -sc)
    export ARCH=$(echo $(uname -m) | sed -e 's:i686:i386:g')
    #
    echo "DEBIAN=${DEBIAN}" >> percona-postgis.properties
    echo "ARCH=${ARCH}" >> percona-postgis.properties

    #
    DSC=$(basename $(find . -name '*.dsc' | sort | tail -n1))
    #
    dpkg-source -x ${DSC}
    #
    cd ${PRODUCT}-${VERSION}.${RELEASE}
    dch -m -D "${DEBIAN}" --force-distribution -v "2:${VERSION}.${RELEASE}-${DEB_RELEASE}.${DEBIAN}" 'Update distribution'
    unset $(locale|cut -d= -f1)
#    if [ "x${DEBIAN}" = "xjammy" -o "x${DEBIAN}" = "xbionic" ]
#    then
        sed -i '15i DEB_BUILD_OPTIONS=nocheck' debian/rules
	sed -i '1d' debian/percona-postgis-doc.install
#    fi
    if [ "x${DEBIAN}" = "xbionic" ]
    then
        sed -i '/libsfcgal/d' debian/control
        cp debian/control debian/control.in
	sed -i "248i override_dh_shlibdeps:\n\tdh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info" debian/rules
    fi
    dpkg-buildpackage -rfakeroot -us -uc -b
    mkdir -p $CURDIR/deb
    mkdir -p $WORKDIR/deb
    cd $WORKDIR/
    for file in $(ls | grep ddeb); do
        mv "$file" "${file%.ddeb}.deb";
    done
    cp $WORKDIR/*.*deb $WORKDIR/deb
    cp $WORKDIR/*.*deb $CURDIR/deb
}
#main
export GIT_SSL_NO_VERIFY=1
CURDIR=$(pwd)
VERSION_FILE=$CURDIR/percona-postgis.properties
args=
WORKDIR=
SRPM=0
SDEB=0
RPM=0
DEB=0
SOURCE=0
OS_NAME=
ARCH=
OS=
INSTALL=0
RPM_RELEASE=${RPM_RELEASE}
DEB_RELEASE=${DEB_RELEASE}
REVISION=0
POSTGIS_BRANCH=${POSTGIS_BRANCH}
POSTGIS_GITREPO=${POSTGIS_GITREPO}
PRODUCT=percona-postgis
DEBUG=0
parse_arguments PICK-ARGS-FROM-ARGV "$@"
VERSION=${POSTGIS_VERSION}
RELEASE='8'
PRODUCT_FULL=${PRODUCT}-${VERSION}-${RELEASE}
PPG_VERSION=15.14

check_workdir
get_system
#install_deps
if [ $INSTALL = 0 ]; then
    echo "Dependencies will not be installed"
else
    source ../install-deps.sh "postgis"
fi
get_sources
build_srpm
build_source_deb
build_rpm
build_deb
