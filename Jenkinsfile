def images = [
    foundry: 'ghcr.io/pipeline-devsecops-para-blockchain-2025/poc-sast-dast-sca/foundry:1.4.4',
    slither: 'ghcr.io/pipeline-devsecops-para-blockchain-2025/poc-sast-dast-sca/slither:0.11.3',
    mythril: 'ghcr.io/pipeline-devsecops-para-blockchain-2025/poc-sast-dast-sca/mythril:0.24.8',
]

def reportCheck(Closure body) {
    withChecks(name: 'Jenkins CI', includeStage: true) {
        try {
            body()
            publishChecks(conclusion: 'SUCCESS')
        } catch (err) {
            publishChecks(conclusion: 'FAILURE', summary: "${err}")
        }
    }
}

@NonCPS
def extractSettingsJson(String json) {
    def config = new groovy.json.JsonSlurper().parseText(json)
    def settings = [remappings: config.remappings]
    return groovy.json.JsonOutput.toJson(settings)
}

pipeline {
    agent any
    options {
        skipDefaultCheckout()
    }
    stages {
        stage('Checkout with Submodules') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: scm.branches,
                    userRemoteConfigs: scm.userRemoteConfigs,
                    extensions: [
                        [$class: 'SubmoduleOption', recursiveSubmodules: true, parentCredentials: true]
                    ]
                ])
            }
        }
        stage('Build Contracts') {
            agent {
                docker {
                    image images.foundry
                    reuseNode true
                }
            }
            steps {
                // --build-info: additional output files, used by Slither
                sh 'forge build --build-info'
                sh 'forge config --json > .forge-config.json'
            }
        }
        stage('Analysis') {
            parallel {
                stage('Forge Format') {
                    agent {
                        docker {
                            image images.foundry
                            reuseNode true
                        }
                    }
                    steps {
                        reportCheck {
                            sh 'forge fmt --check'
                        }
                    }
                }
                stage('Forge Lint') {
                    agent {
                        docker {
                            image images.foundry
                            reuseNode true
                        }
                    }
                    steps {
                        reportCheck {
                            sh 'forge lint'
                        }
                    }
                }
                stage('Foge Tests') {
                    agent {
                        docker {
                            image images.foundry
                            reuseNode true
                        }
                    }
                    steps {
                        reportCheck {
                            sh 'forge test -vvv'
                        }
                    }
                }
                stage('Slither') {
                    agent {
                        docker {
                            image images.slither
                            args '--entrypoint=' // shell for Docker Pipeline
                            reuseNode true
                        }
                    }
                    steps {
                        reportCheck {
                            sh 'mkdir -p reports'
                            // --ignore-compile: already compiled with build info
                            // --no-fail-pedantic: only fail in case of runtime issues
                            sh 'slither --ignore-compile --no-fail-pedantic . --json reports/slither.json'
                            stash name: 'slither-report', includes: 'reports/slither.json', allowEmpty: true
                        }
                    }
                }
                stage('Mythril') {
                    agent {
                        docker {
                            image images.mythril
                            args '--entrypoint=' // shell for Docker Pipeline
                            reuseNode true
                        }
                    }
                    steps {
                        script {
                            def config = readFile file: '.forge-config.json'
                            writeFile file: '.solc-config.json', text: extractSettingsJson(config)
                        }
                        sh 'mkdir -p reports/mythril'
                        script {
                            def files = sh(script: "find contracts/ -name '*.sol' -print0", returnStdout: true)
                                .split('\0')
                                .findAll { it }

                            def branches = [:]
                            files.each { filePath ->
                                def safePath = "'" + filePath.replace("'", "'\"'\"'") + "'"
                                def shortName = filePath.replaceFirst(/^contracts[\\/]/, '')
                                def safeName  = shortName.replaceAll(/[^A-Za-z0-9_.-]/, '_')

                                branches[shortName] = {
                                    reportCheck {
                                        script {
                                            def exitCode = sh(
                                                // --solv, --solc-json: try to match foundry.toml
                                                script: """
                                                    myth analyze ${safePath} \
                                                        --solv 0.8.26 --solc-json .solc-config.json \
                                                        --outform jsonv2 | tee reports/mythril/${safeName}.json
                                                """,
                                                returnStatus: true
                                            )
                                            println "Mythril reports for ${filePath}: ${exitCode}"
                                        }
                                    }
                                }
                            }

                            if (!branches.isEmpty()) {
                                parallel branches
                            }
                        }
                        stash name: 'mythril-report', includes: 'reports/mythril/*.json', allowEmpty: true
                    }
                }
            }
        }
    }
    post {
        always {
            cleanWs()
            catchError { unstash 'slither-report' }
            catchError { unstash 'mythril-report' }
            archiveArtifacts artifacts: 'reports/*', allowEmptyArchive: true
        }
    }
}
