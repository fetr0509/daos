pipeline {
    agent none

    environment {
        SHELL = '/bin/bash'
    }

    // triggers {
        // Jenkins instances behind firewalls can't get webhooks
        // sadly, this doesn't seem to work
        // pollSCM('* * * * *')
        // See if cron works since pollSCM above isn't
        // cron('H 22 * * *')
    // }

    options {
        // preserve stashes so that jobs can be started at the test stage
        preserveStashes(buildCount: 5)
    }

    stages {
        stage('Pre-build') {
            parallel {
                stage('check_modules.sh') {
                    agent {
                        dockerfile {
                            filename 'Dockerfile.centos:7'
                            dir 'utils/docker'
                            label 'docker_runner'
                            additionalBuildArgs  '--build-arg NOBUILD=1 --build-arg UID=$(id -u)'
                        }
                    }
                    steps {
                        checkout scm
                        // Need the jenkins module to do linting
                        checkout([
                            $class: 'GitSCM',
                            branches: [[name: 'refs/heads/master']],
                            doGenerateSubmoduleConfigurations: false,
                            extensions: [],
                            submoduleCfg: [],
                            userRemoteConfigs: [[credentialsId: '084f0cb4-6db2-4fc7-86f2-3b890d98a9f2',
                                                 url: 'https://review.hpdd.intel.com/exascale/jenkins']]
                        ])
                        sh '''git submodule update --init --recursive
                              ls -l
                              utils/check_modules.sh'''
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'pylint.log', allowEmptyArchive: true
                        }
                    }
                }
            }
        }
        stage('Build') {
            parallel {
                stage('Build on CentOS 7') {
                    agent {
                        dockerfile {
                            filename 'Dockerfile.centos:7'
                            dir 'utils/docker'
                            label 'docker_runner'
                            additionalBuildArgs  '--build-arg NOBUILD=1 --build-arg UID=$(id -u)'
                        }
                    }
                    steps {
                        checkout scm
                        sh '''git submodule update --init --recursive
                              if git show -s --format=%B | grep "^Skip-build: true"; then
                                  exit 0
                              fi
                              scons -c
                              # scons -c is not perfect so get out the big hammer
                              rm -rf _build.external install build
                              utils/fetch_go_packages.sh -i .
                              SCONS_ARGS="--update-prereq=all --build-deps=yes USE_INSTALLED=all install"
                              # the config cache is unreliable so always force a reconfig
                              if ! scons --config=force $SCONS_ARGS; then
                                  rc=\${PIPESTATUS[0]}
                                  cat config.log || true
                                  exit \$rc
                              fi'''
                        stash name: 'CentOS-install', includes: 'install/**'
                        stash name: 'CentOS-build-vars', includes: '.build_vars.*'
                        stash name: 'CentOS-tests', includes: 'build/src/rdb/raft/src/tests_main, build/src/common/tests/btree_direct, build/src/common/tests/btree, src/common/tests/btree.sh, build/src/common/tests/sched, build/src/client/api/tests/eq_tests, src/vos/tests/evt_ctl.sh, build/src/vos/vea/tests/vea_ut, src/rdb/raft_tests/raft_tests.py'
                    }
                }
                stage('Build on Ubuntu 18.04') {
                    agent {
                        dockerfile {
                            filename 'Dockerfile.ubuntu:18.04'
                            dir 'utils/docker'
                            label 'docker_runner'
                            additionalBuildArgs  '--build-arg NOBUILD=1 --build-arg UID=$(id -u) --build-arg DONT_USE_RPMS=false'
                        }
                    }
                    steps {
                        checkout scm
                        sh '''git submodule update --init --recursive
                              if git show -s --format=%B | grep "^Skip-build: true"; then
                                  exit 0
                              fi
                              scons -c
                              # scons -c is not perfect so get out the big hammer
                              rm -rf _build.external install build
                              utils/fetch_go_packages.sh -i .
                              SCONS_ARGS="--update-prereq=all --build-deps=yes USE_INSTALLED=all install"
                              # the config cache is unreliable so always force a reconfig
                              if ! scons --config=force $SCONS_ARGS; then
                                  rc=\${PIPESTATUS[0]}
                                  cat config.log || true
                                  exit \$rc
                              fi'''
                    }
                }
            }
        }
        stage('Test') {
            parallel {
                stage('Functional quick') {
                    agent {
                        label 'cluster_provisioner'
                    }
                    steps {
                        dir('install') {
                            deleteDir()
                        }
                        unstash 'CentOS-install'
                        unstash 'CentOS-build-vars'
                        sh '''if git show -s --format=%B | grep "^Skip-test: true"; then
                                  exit 0
                              fi
                              bash ftest.sh quick
                              rm -rf src/tests/ftest/avocado/job-results/*/html/ "Functional quick"/
                              mkdir "Functional quick"/
                              [ -f install/tmp/daos.log ] && mv install/tmp/daos.log "Functional quick"/
                              mv src/tests/ftest/avocado/job-results/** "Functional quick"/'''
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'Functional quick/**'
                            junit 'Functional quick/*/results.xml'
                        }
                    }
                }
                stage('run_test.sh') {
                    agent {
                        label 'single'
                    }
                    steps {
                        dir('install') {
                            deleteDir()
                        }
                        unstash 'CentOS-tests'
                        unstash 'CentOS-install'
                        unstash 'CentOS-build-vars'
                        sh '''if git show -s --format=%B | grep "^Skip-test: true"; then
                                  exit 0
                              fi
                              HOSTPREFIX=wolf-53 bash -x utils/run_test.sh --init
                              rm -rf run_test.sh/
                              mkdir run_test.sh/
                              [ -f /tmp/daos.log ] && mv /tmp/daos.log run_test.sh/'''
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'run_test.sh/**'
                        }
                    }
                }
                stage('DaosTestMulti All') {
                    agent {
                        label 'cluster_provisioner'
                    }
                    steps {
                        dir('install') {
                            deleteDir()
                        }
                        unstash 'CentOS-install'
                        sh '''if git show -s --format=%B | grep "^Skip-test: true"; then
                                  exit 0
                              fi
                              trap 'rm -rf DaosTestMulti-All/
                                    mkdir DaosTestMulti-All/
                                    [ -f daos.log ] && mv daos.log DaosTestMulti-All
                                    ls *results.xml && mv -f *results.xml DaosTestMulti-All' EXIT
                              bash DaosTestMulti.sh || true'''
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'DaosTestMulti-All/**'
                            junit allowEmptyResults: false, testResults: 'DaosTestMulti-All/*results.xml'
                        }
                    }
                }
                stage('DaosTestMulti Degraded') {
                    agent {
                        label 'cluster_provisioner'
                    }
                    steps {
                        dir('install') {
                            deleteDir()
                        }
                        unstash 'CentOS-install'
                        sh '''if git show -s --format=%B | grep "^Skip-test: true"; then
                                  exit 0
                              fi
                              trap 'rm -rf DaosTestMulti-Degraded/
                                    mkdir DaosTestMulti-Degraded/
                                    [ -f daos.log ] && mv daos.log DaosTestMulti-Degraded
                                    ls *results.xml && mv -f *results.xml DaosTestMulti-Degraded' EXIT
                              bash DaosTestMulti.sh -d || true'''
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'DaosTestMulti-Degraded/**'
                            junit allowEmptyResults: false, testResults: 'DaosTestMulti-Degraded/*results.xml'
                        }
                    }
                }
                stage('DaosTestMulti Rebuild') {
                    agent {
                        label 'cluster_provisioner'
                    }
                    steps {
                        dir('install') {
                            deleteDir()
                        }
                        unstash 'CentOS-install'
                        sh '''if git show -s --format=%B | grep "^Skip-test: true"; then
                                  exit 0
                              fi
                              trap 'rm -rf DaosTestMulti-Rebuild/
                                    mkdir DaosTestMulti-Rebuild/
                                    [ -f daos.log ] && mv daos.log DaosTestMulti-Rebuild
                                    ls *results.xml && mv -f *results.xml DaosTestMulti-Rebuild' EXIT
                              bash DaosTestMulti.sh -r || true'''
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'DaosTestMulti-Rebuild/**'
                            junit allowEmptyResults: false, testResults: 'DaosTestMulti-Rebuild/*results.xml'
                        }
                    }
                }
            }
        }
    }
}
