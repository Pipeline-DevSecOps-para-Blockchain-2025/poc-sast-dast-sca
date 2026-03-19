def images = [
    foundry: 'ghcr.io/pipeline-devsecops-para-blockchain-2025/poc-sast-dast-sca/foundry:1.5.1',
    slither: 'ghcr.io/pipeline-devsecops-para-blockchain-2025/poc-sast-dast-sca/slither:0.11.5',
    mythril: 'ghcr.io/pipeline-devsecops-para-blockchain-2025/poc-sast-dast-sca/mythril:0.24.8',
]

def reportCheck(Closure body) {
    withChecks(name: 'Jenkins CI', includeStage: true) {
        try {
            body()
            publishChecks(conclusion: 'SUCCESS')
        } catch (err) {
            publishChecks(conclusion: 'FAILURE', summary: "${err}")
            throw err
        }
    }
}

@NonCPS
def extractSettingsJson(String json) {
    def config = new groovy.json.JsonSlurper().parseText(json)
    def settings = [remappings: config.remappings]
    return groovy.json.JsonOutput.toJson(settings)
}

// Maps tool severity labels to GitHub Checks annotation levels.
@NonCPS
def mapSeverity(String severity) {
    switch (severity?.toLowerCase()) {
        case 'high':   return 'FAILURE'
        case 'medium': return 'WARNING'
        default:       return 'NOTICE'
    }
}

// Pushes Prometheus exposition-format metrics to VictoriaMetrics.
// Errors are logged as warnings and never propagate.
@NonCPS
def pushMetrics(String url, String body) {
    try {
        def client   = java.net.http.HttpClient.newHttpClient()
        def request  = java.net.http.HttpRequest.newBuilder()
            .uri(java.net.URI.create(url))
            .header('Content-Type', 'text/plain')
            .POST(java.net.http.HttpRequest.BodyPublishers.ofString(body))
            .build()
        def response = client.send(request, java.net.http.HttpResponse.BodyHandlers.ofString())
        if (response.statusCode() >= 400) {
            println "WARN: VictoriaMetrics returned HTTP ${response.statusCode()}: ${response.body()}"
        }
    } catch (Exception e) {
        println "WARN: Failed to push metrics to VictoriaMetrics: ${e.message}"
    }
}

@NonCPS
def escapePromLabel(String value) {
    def v = value == null ? '' : value.toString()
    v = v.replace('\\', '\\\\')
    v = v.replace('"', '\\"')
    v = v.replace('\n', '\\n')
    return v
}

@NonCPS
def formatPromLabels(Map labels) {
    def parts = []
    labels.each { k, v ->
        parts << "${k}=\"${escapePromLabel(v)}\""
    }
    return parts.join(',')
}

@NonCPS
def buildSecurityMetricLines(List findings, List contracts, String tool, Map commonLabels) {
    def severities = ['High', 'Medium', 'Low', 'Informational', 'Optimization']
    def byContract = [:]

    contracts.each { contract ->
        def severityCounts = [:]
        severities.each { sev -> severityCounts[sev] = 0 }
        byContract[contract] = [total: 0, severityCounts: severityCounts]
    }

    findings.each { f ->
        def contract = f.file.replaceFirst(/^contracts\//, '')
        if (!byContract.containsKey(contract)) {
            def severityCounts = [:]
            severities.each { sev -> severityCounts[sev] = 0 }
            byContract[contract] = [total: 0, severityCounts: severityCounts]
        }

        byContract[contract].total += 1
        def sev = f.severity ?: 'Low'
        if (!byContract[contract].severityCounts.containsKey(sev)) {
            byContract[contract].severityCounts[sev] = 0
        }
        byContract[contract].severityCounts[sev] += 1
    }

    def lines = []
    byContract.each { contract, stats ->
        def base = commonLabels + [tool: tool, contract: contract]
        lines << "ci_security_contract_scanned{${formatPromLabels(base)}} 1"
        lines << "ci_security_contract_findings_total{${formatPromLabels(base)}} ${stats.total}"

        severities.each { sev ->
            def labels = base + [severity: sev]
            lines << "ci_security_findings{${formatPromLabels(labels)}} ${stats.severityCounts[sev] ?: 0}"
        }
    }

    return lines
}

// Parses reports/slither.json into a list of normalized finding maps.
// Filters to findings whose primary element is under contracts/ only.
// Returns a plain List<Map> safe to pass back into CPS context.
@NonCPS
def parseSlitherReport(String json) {
    def data     = new groovy.json.JsonSlurper().parseText(json)
    def findings = []

    data?.results?.detectors?.each { det ->
        def el  = det.elements?.find { it.source_mapping?.filename_relative?.startsWith('contracts/') }
        if (!el) return

        def lines = el.source_mapping?.lines ?: [1]
        def startLine = 1
        def endLine = 1
        // Can't use .min() nor .max()
        if (lines) {
            startLine = lines[0] as int
            endLine = lines[0] as int
            lines.each { line ->
                int n = line as int
                if (n < startLine) startLine = n
                if (n > endLine) endLine = n
            }
        }
        findings << [
            tool      : 'slither',
            detector  : det.check ?: 'unknown',
            severity  : det.impact ?: 'Informational',
            confidence: det.confidence ?: 'Low',
            file      : el.source_mapping.filename_relative,
            startLine : startLine,
            endLine   : endLine,
            message   : det.description?.replaceAll(/\n/, ' ')?.take(512) ?: '',
        ]
    }

    return findings
}

// Parses all reports/mythril/<name>.json files.
// reportEntries is a List of [name: String, path: String] maps (from findFiles).
// Returns a plain List<Map> safe to pass back into CPS context.
@NonCPS
def parseMythrilReports(List reportEntries) {
    def findings = []

    reportEntries.each { entry ->
        def baseName = entry.name                               // e.g. vulnerable_ReEntrancy.sol.json
        def srcFile  = baseName
            .replaceFirst(/\.json$/, '')                        // vulnerable_ReEntrancy.sol
            .replaceFirst(/^(vulnerable|clean)_/, '')           // ReEntrancy.sol
        def srcPath  = baseName.startsWith('clean_')
            ? "contracts/clean/${srcFile}"
            : "contracts/vulnerable/${srcFile}"

        def data = new groovy.json.JsonSlurper().parseText(entry.content)
        def issues = data instanceof List ? data[0]?.issues : data?.issues
        issues?.each { issue ->
            findings << [
                tool      : 'mythril',
                detector  : issue.swcID ?: 'unknown',
                severity  : issue.severity ?: 'Low',
                confidence: 'N/A',
                file      : srcPath,
                startLine : 1,
                endLine   : 1,
                message   : issue.description?.head?.take(512) ?: '',
            ]
        }
    }

    return findings
}

// Builds per-tool aggregated counts and markdown summary tables.
// Returns a plain Map safe to use in CPS context.
@NonCPS
def buildSummary(List slitherFindings, List mythrilFindings) {
    def aggregate = { List findings ->
        def bySeverity = findings.groupBy { it.severity }
            .collectEntries { sev, list -> [(sev): list.size()] }
        def byContract = findings.groupBy { it.file }
            .collectEntries { file, list ->
                [(file.replaceFirst(/^contracts\//, '')): list.size()]
            }
            .sort { -it.value }
        [
            total     : findings.size(),
            bySeverity: bySeverity,
            byContract: byContract,
        ]
    }

    def slither = aggregate(slitherFindings)
    def mythril = aggregate(mythrilFindings)

    // Severity order for display
    def sevOrder = ['High', 'Medium', 'Low', 'Informational', 'Optimization']

    def severityTable = { Map stats, String toolName ->
        def lines = ["### ${toolName} — ${stats.total} findings\n"]
        lines << "| Severity | Count |"
        lines << "| :------- | ----: |"
        sevOrder.each { sev ->
            def count = stats.bySeverity[sev]
            if (count) lines << "| ${sev} | ${count} |"
        }
        lines << ""
        lines << "| Contract | Findings |"
        lines << "| :------- | -------: |"
        stats.byContract.each { contract, count ->
            lines << "| `${contract}` | ${count} |"
        }
        lines.join('\n')
    }

    return [
        slither        : slither,
        mythril        : mythril,
        slitherMarkdown: severityTable(slither, 'Slither'),
        mythrilMarkdown: severityTable(mythril, 'Mythril'),
        markdown       : severityTable(slither, 'Slither') + '\n\n' + severityTable(mythril, 'Mythril'),
    ]
}

// Orders findings by severity (High, Medium, then the rest) and caps them.
// Implemented without CPS-hostile sort/take chains.
@NonCPS
def prioritizeFindings(List findings, int limit = 50) {
    def high = []
    def medium = []
    def other = []

    findings.each { f ->
        switch (f.severity?.toLowerCase()) {
            case 'high':
                high << f
                break
            case 'medium':
                medium << f
                break
            default:
                other << f
                break
        }
    }

    def ordered = []
    [high, medium, other].each { bucket ->
        bucket.each { f ->
            if (ordered.size() < limit) {
                ordered << f
            }
        }
    }

    return ordered
}

// ---------------------------------------------------------------------------
// Pipeline
// ---------------------------------------------------------------------------

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
                stage('Forge Tests') {
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
                            // --exclude-dependencies: don't report issues from 'lib/*'
                            // --no-fail-pedantic: only fail in case of runtime issues
                            sh '''
                                slither . \
                                    --ignore-compile --exclude-dependencies \
                                    --no-fail-pedantic --json reports/slither.json
                            '''
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
            catchError { unstash 'slither-report' }
            catchError { unstash 'mythril-report' }

            script {
                // Parse reports
                def slitherFindings = []
                if (fileExists('reports/slither.json')) {
                    slitherFindings = parseSlitherReport(readFile('reports/slither.json'))
                }

                def mythrilEntries = []
                findFiles(glob: 'reports/mythril/*.json').each { f ->
                    def text = readFile(f.path).trim()
                    if (text) {
                        mythrilEntries << [name: f.name, content: text]
                    } else {
                        echo "Skipping empty mythril report: ${f.path}"
                    }
                }
                def mythrilFindings = parseMythrilReports(mythrilEntries)

                // Display results
                def summary = buildSummary(slitherFindings, mythrilFindings)

                echo "=== SAST Results ===\n${summary.markdown}"

                // GitHub Checks API limit: 50 annotations per call.
                // Priority: High first, then Medium, then the rest.
                // Only publish when findings are actually present.

                if (slitherFindings) {
                    publishChecks(
                        name      : 'Slither SAST',
                        title     : "Slither: ${summary.slither.total} findings",
                        summary   : summary.slitherMarkdown,
                        conclusion: 'NEUTRAL',
                        annotations: prioritizeFindings(slitherFindings, 50).collect { f -> [
                            path            : f.file,
                            startLine       : f.startLine,
                            endLine         : f.endLine,
                            annotationLevel : mapSeverity(f.severity),
                            title           : f.detector,
                            message         : f.message,
                            rawDetails      : "Confidence: ${f.confidence}",
                        ]}
                    )
                }

                if (mythrilFindings) {
                    publishChecks(
                        name      : 'Mythril SAST',
                        title     : "Mythril: ${summary.mythril.total} findings",
                        summary   : summary.mythrilMarkdown,
                        conclusion: 'NEUTRAL',
                        annotations: prioritizeFindings(mythrilFindings, 50).collect { f -> [
                            path            : f.file,
                            startLine       : f.startLine,
                            endLine         : f.endLine,
                            annotationLevel : mapSeverity(f.severity),
                            title           : f.detector,
                            message         : f.message,
                        ]}
                    )
                }

                // VictoriaMetrics — emit per-contract metrics so repos of different
                // sizes remain comparable and downstream dashboards can aggregate.
                def contracts = findFiles(glob: 'contracts/**/*.sol')
                    .collect { it.path.replaceFirst(/^contracts\//, '') }
                def commonLabels = [
                    branch: env.BRANCH_NAME,
                    job: env.JOB_NAME,
                    build_number: env.BUILD_NUMBER,
                ]
                def metricLines = []
                if (slitherFindings) {
                    metricLines += buildSecurityMetricLines(slitherFindings, contracts, 'slither', commonLabels)
                }
                if (mythrilFindings) {
                    metricLines += buildSecurityMetricLines(mythrilFindings, contracts, 'mythril', commonLabels)
                }
                if (metricLines) {
                    pushMetrics('http://victoriametrics:8428/api/v1/import/prometheus', metricLines.join('\n'))
                }
            }

            archiveArtifacts artifacts: 'reports/**', allowEmptyArchive: true
            cleanWs()
        }
    }
}
