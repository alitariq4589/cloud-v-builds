node('pioneer-1-admin') {
    stage('Clean Workspace') {
        cleanWs()
    }
    stage('Installing Dependencies') {
        sh '''#!/bin/bash
            set -x
            export DEBIAN_FRONTEND=noninteractive
            sudo apt-get update
            sudo apt-get install autoconf git -y
        '''
    }
    stage('Run system_info') {
        sh '''#!/bin/bash
            echo '============================================================='
            echo '                       CPU INFO START                        '
            echo '============================================================='
            cat /proc/cpuinfo
            echo '============================================================='
            echo '                       CPU INFO END                          '
            echo '============================================================='

            echo '============================================================='
            echo '                       Kernel Info Start                        '
            echo '============================================================='
            uname -a
            echo '============================================================='
            echo '                       Kernel Info End                          '
            echo '============================================================='
            echo '============================================================='
            echo '                       Glibc Version Start                        '
            echo '============================================================='
            ldd --version
            echo '============================================================='
            echo '                       Glibc Version End                          '
            echo '============================================================='
            echo '============================================================='
            echo '                       OS Info Start                        '
            echo '============================================================='
            cat /etc/os-release
            echo '============================================================='
            echo '                       OS Info End                        '
            echo '============================================================='
        '''
    }
    stage('Setting Directories and clone') {
        sh '''#!/bin/bash
            mkdir installed_binaries
            git clone --branch master --single-branch --depth=1 https://git.savannah.gnu.org/git/make.git
        '''
    }

    stage('Run configure') {
        sh '''#!/bin/bash -l
            set -x
            cd make
            ./bootstrap
            ./configure --prefix=$(readlink -f ../installed_binaries)
        '''
    }
    stage('make and make check') {
        sh '''#!/bin/bash -l
            set -x
          cd make
          make -j32
          # make check # Takes too much time so I am skipping this
          make install
        '''
    }
    stage('Check Version') {
        sh '''#!/bin/bash -l
            set -x
            ./installed_binaries/bin/make --version
        '''
    }
    stage('Compress Binaries and transfer to Cloud') {
        sshagent(credentials: ['SSH_CLOUD_V_STORE_ID']){
            sh '''#!/bin/bash -l
            set -x
                export FILENAME="make_$(date -u +"%H%M%S_%d%m%Y").tar.gz"
                tar -cvf ./$FILENAME ./installed_binaries
                eval $(keychain --eval --agents ssh ~/.ssh/cloud-store-key)
                ssh cloud-store 'mkdir -p /var/www/nextcloud/data/admin/files/cloud-v-builds/make'
                ssh cloud-store 'rm /var/www/nextcloud/data/admin/files/cloud-v-builds/make/*' # Removing older builds
                scp $FILENAME cloud-store:/var/www/nextcloud/data/admin/files/cloud-v-builds/make/
                ssh cloud-store 'sudo -u www-data php /var/www/nextcloud/occ files:scan --path="admin/files"'
            '''
        }
    }
}