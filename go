node('pioneer-1-admin') {
    stage('Clean Workspace') {
        cleanWs()
    }
    stage('Installing Dependencies') {
        sh '''#!/bin/bash
            export DEBIAN_FRONTEND=noninteractive
sudo apt-get update && sudo apt-get upgrade -y
            sudo apt-get install golang gcc -y
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
            git clone --single-branch --depth=1 https://go.googlesource.com/go
        '''
    }
    stage('Build') {
        sh '''#!/bin/bash -l
            set -x
          cd go/src
          ./all.bash
        '''
    }
    stage('Check Version') {
        sh '''#!/bin/bash -l
            set -x
            ./go/bin/go version
        '''
    }
    stage('Compress Binaries and transfer to Cloud') {
        sshagent(credentials: ['SSH_CLOUD_V_STORE_ID']){
            sh '''#!/bin/bash -l
            set -x
                export FILENAME="go_$(date -u +"%H%M%S_%d%m%Y").tar.gz"
                tar -cvf ./$FILENAME ./go
                eval $(keychain --eval --agents ssh ~/.ssh/cloud-store-key)
                ssh cloud-store 'mkdir -p /var/www/nextcloud/data/admin/files/cloud-v-builds/go'
                ssh cloud-store 'rm /var/www/nextcloud/data/admin/files/cloud-v-builds/go/*' # Removing older builds
                scp $FILENAME cloud-store:/var/www/nextcloud/data/admin/files/cloud-v-builds/go/
                ssh cloud-store 'sudo -u www-data php /var/www/nextcloud/occ files:scan --path="admin/files"'
            '''
        }
    }
}