node('riscv64-admin') {
    stage('Clean Workspace') {
        cleanWs()
    }
    // stage('Installing Dependencies') {
    //     sh '''#!/bin/bash
    //         sudo apt-get update
    //         sudo apt-get install git curl pkg-config g++ libssl-dev ninja-build make cmake -y
    //     '''
    // }
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
            git clone --branch master --single-branch --depth=1 https://github.com/ninja-build/ninja.git
        '''
    }

    // stage('Run configure') {
    //     sh '''#!/bin/bash -l
    //         cd rust
    //         ./configure --set install.prefix=$(readlink -f ../installed_binaries)
    //     '''
    // }
    stage('Build and transfer') {
        sh '''#!/bin/bash -l
            cd ninja || exit
            ./configure.py --bootstrap
            cp ./ninja ../installed_binaries/
        '''
    }
    stage('Test binaries') {
        sh '''#!/bin/bash -l
            ./installed_binaries/ninja --version
        '''
    }
    stage('Compress Binaries and transfer to Cloud') {
        sshagent(credentials: ['SSH_CLOUD_V_STORE_ID']){
            sh '''#!/bin/bash -l
                export FILENAME="ninja-build_$(date -u +"%H%M%S_%d%m%Y").tar.gz"
                tar -cvf ./$FILENAME ./installed_binaries
                eval $(keychain --eval --agents ssh ~/.ssh/cloud-store-key)
                ssh cloud-store 'mkdir -p /var/www/nextcloud/data/admin/files/cloud-v-builds/ninja-build'
                scp $FILENAME cloud-store:/var/www/nextcloud/data/admin/files/cloud-v-builds/ninja-build/
                ssh cloud-store 'sudo -u www-data php /var/www/nextcloud/occ files:scan --path="admin/files"'
            '''
        }
    }
}