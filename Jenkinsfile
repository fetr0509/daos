// To use a test branch (i.e. PR) until it lands to master
// I.e. for testing library changes
@Library(value="pipeline-lib@debug") _

pipeline {
    agent any

    environment {
        GITHUB_USER = credentials('aa4ae90b-b992-4fb6-b33b-236a53a26f77')
        BAHTTPS_PROXY = "${env.HTTP_PROXY ? '--build-arg HTTP_PROXY="' + env.HTTP_PROXY + '" --build-arg http_proxy="' + env.HTTP_PROXY + '"' : ''}"
        BAHTTP_PROXY = "${env.HTTP_PROXY ? '--build-arg HTTPS_PROXY="' + env.HTTPS_PROXY + '" --build-arg https_proxy="' + env.HTTPS_PROXY + '"' : ''}"
        UID=sh(script: "id -u", returnStdout: true)
        BUILDARGS = "--build-arg NOBUILD=1 --build-arg UID=$env.UID $env.BAHTTP_PROXY $env.BAHTTPS_PROXY"
    }

    options {
        // preserve stashes so that jobs can be started at the test stage
        preserveStashes(buildCount: 5)
    }

    stages {
        stage('Pre-build') {
            parallel {
                stage('checkpatch') {
                    agent {
                        dockerfile {
                            filename 'Dockerfile.centos:7'
                            dir 'utils/docker'
                            label 'docker_runner'
                            additionalBuildArgs '$BUILDARGS'
                        }
                    }
                    steps {
                        checkPatch user: GITHUB_USER_USR,
                                   password: GITHUB_USER_PSW,
                                   jenkins_review: '20/33420/3'
                    }
                    post {
                        /* temporarily moved into stepResult due to JENKINS-39203
                        success {
                            githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'checkpatch',  context: 'pre-build/checkpatch', status: 'SUCCESS'
                        }
                        unstable {
                            githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'checkpatch',  context: 'pre-build/checkpatch', status: 'FAILURE'
                        }
                        failure {
                            githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'checkpatch',  context: 'pre-build/checkpatch', status: 'ERROR'
                        }
                        */
                        always {
                            archiveArtifacts artifacts: 'pylint.log', allowEmptyArchive: true
                        }
                    }
                }
            }
        }
        stage('Build') {
            // abort other builds if/when one fails to avoid wasting time
            // and resources
            failFast true
            parallel {
                stage('Build on CentOS 7') {
                    agent {
                        dockerfile {
                            filename 'Dockerfile.centos:7'
                            dir 'utils/docker'
                            label 'docker_runner'
                            additionalBuildArgs '$BUILDARGS'
                        }
                    }
                    steps {
                        sconsBuild()
                        stash name: 'CentOS-install', includes: 'install/**'
                        stash name: 'CentOS-build-vars', includes: '.build_vars.*'
                        stash name: 'CentOS-tests', includes: 'build/src/rdb/raft/src/tests_main, build/src/common/tests/btree_direct, build/src/common/tests/btree, src/common/tests/btree.sh, build/src/common/tests/sched, build/src/client/api/tests/eq_tests, src/vos/tests/evt_ctl.sh, build/src/vos/vea/tests/vea_ut, src/rdb/raft_tests/raft_tests.py'
                    }
                    /* temporarily moved into stepResult due to JENKINS-39203
                    post {
                        success {
                            githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'CentOS 7 Build',  context: 'build/centos7', status: 'SUCCESS'
                        }
                        unstable {
                            githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'CentOS 7 Build',  context: 'build/centos7', status: 'FAILURE'
                        }
                        failure {
                            githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'CentOS 7 Build',  context: 'build/centos7', status: 'ERROR'
                        }
                    }
                    */
                }
                stage('Build on Ubuntu 18.04') {
                    agent {
                        dockerfile {
                            filename 'Dockerfile.ubuntu:18.04'
                            dir 'utils/docker'
                            label 'docker_runner'
                            additionalBuildArgs '$BUILDARGS'
                        }
                    }
                    steps {
                        sconsBuild()
                    }
                    /* temporarily moved into stepResult due to JENKINS-39203
                    post {
                        success {
                            githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'Ubuntu 18 Build',  context: 'build/ubuntu18', status: 'SUCCESS'
                        }
                        unstable {
                            githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'Ubuntu 18 Build',  context: 'build/ubuntu18', status: 'FAILURE'
                        }
                        failure {
                            githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'Ubuntu 18 Build',  context: 'build/ubuntu18', status: 'ERROR'
                        }
                    }
                    */
                }
            }
            post {
                always {
                    recordIssues enabledForFailure: true,
                                 aggregatingResults: true,
                                 tools: [
                                     [tool: [$class: 'GnuMakeGcc']],
                                     [tool: [$class: 'CppCheck']],
                                 ],
                                 filters: [excludeFile('.*\\/_build\\.external\\/.*'),
                                           excludeFile('_build\\.external\\/.*')]
                }
            }
        }
        stage('run_test.sh') {
            agent {
                label 'single'
            }
            steps {
                runTest stashes: [ 'CentOS-tests', 'CentOS-install', 'CentOS-build-vars' ],
                        script: 'LD_LIBRARY_PATH=install/lib64:install/lib HOSTPREFIX=wolf-53 bash -x utils/run_test.sh --init && echo "run_test.sh exited successfully with ${PIPESTATUS[0]}" || echo "run_test.sh exited failure with ${PIPESTATUS[0]}"',
                      junit_files: null
            }
            post {
                /* temporarily moved into runTest->stepResult due to JENKINS-39203
                success {
                    githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'run_test.sh',  context: 'test/run_test.sh', status: 'SUCCESS'
                }
                unstable {
                    githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'run_test.sh',  context: 'test/run_test.sh', status: 'FAILURE'
                }
                failure {
                    githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'run_test.sh',  context: 'test/run_test.sh', status: 'ERROR'
                }
                */
                always {
                    sh '''rm -rf run_test.sh/
                          mkdir run_test.sh/
                          [ -f /tmp/daos.log ] && mv /tmp/daos.log run_test.sh/ || true'''
                    archiveArtifacts artifacts: 'run_test.sh/**'
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
                        runTest stashes: [ 'CentOS-install', 'CentOS-build-vars' ],
                                script: 'bash ftest.sh quick; echo "rc: $?"',
                                junit_files: "src/tests/ftest/avocado/job-results/*/*.xml"
                    }
                    post {
                        /* temporarily moved into runTest->stepResult due to JENKINS-39203
                        success {
                            githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'Functional quick',  context: 'test/functional_quick', status: 'SUCCESS'
                        }
                        unstable {
                            githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'Functional quick',  context: 'test/functional_quick', status: 'FAILURE'
                        }
                        failure {
                            githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'Functional quick',  context: 'test/functional_quick', status: 'ERROR'
                        }
                        */
                        always {
                            sh '''rm -rf src/tests/ftest/avocado/job-results/*/html/ "Functional quick"/
                                  mkdir "Functional quick"/
                                  [ -f install/tmp/daos.log* ] && mv install/tmp/daos.log* "Functional quick"/ || true
                                  mv src/tests/ftest/avocado/job-results/** "Functional quick"/'''
                            junit 'Functional quick/*/results.xml'
                            archiveArtifacts artifacts: 'Functional quick/**'
                        }
                    }
                }
                stage('Functional daos_test') {
                    agent {
                        label 'cluster_provisioner'
                    }
                    steps {
                        runTest stashes: [ 'CentOS-install', 'CentOS-build-vars' ],
                                script: 'bash ftest.sh daos_test; echo "rc: $?"',
                                // Hrm.  I wonder if there is any way to tell Avocado
                                // to put daos_test's own JUnit files into a job-results
                                // dir
                                junit_files: "install/tmp/*results.xml"
                    }
                    post {
                        /* temporarily moved into runTest->stepResult due to JENKINS-39203
                        success {
                            githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'Functional daos_test',  context: 'test/functional_daos_test', status: 'SUCCESS'
                        }
                        unstable {
                            githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'Functional daos_test',  context: 'test/functional_daos_test', status: 'FAILURE'
                        }
                        failure {
                            githubNotify credentialsId: 'daos-jenkins-commit-status', description: 'Functional daos_test',  context: 'test/functional_daos_test', status: 'ERROR'
                        }
                        */
                        always {
                            sh '''rm -rf src/tests/ftest/avocado/job-results/*/html/ "Functional daos_test"/
                                  mkdir "Functional daos_test"/
                                  mv src/tests/ftest/avocado/job-results/** "Functional daos_test"/
                                  pwd
                                  ls install/tmp/*daos.log* && mv -f install/tmp/*daos.log* "Functional daos_test"/ || true
                                  ls "Functional daos_test"/ || true'''
                            //junit 'Functional daos_test/*/results.xml'
                            junit 'install/tmp/*results.xml'
                            archiveArtifacts artifacts: 'Functional daos_test/**'
                        }
                    }
                }
            }
        }
    }
}
