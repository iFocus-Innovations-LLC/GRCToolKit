/**
 * GRC Compliance Engine
 * Maps user scenarios to OSCAL controls and generates Ansible playbooks
 * Integrates with NIST OSCAL framework for automated compliance validation
 */

class GRCComplianceEngine {
    constructor() {
        this.oscalCatalog = null;
        this.ansiblePlaybooks = new Map();
        this.scenarioMappings = new Map();
        this.initializeEngine();
    }

    /**
     * Initialize the compliance engine with OSCAL catalog and playbook mappings
     */
    async initializeEngine() {
        try {
            // Load OSCAL catalog
            this.oscalCatalog = await this.loadOSCALCatalog();
            
            // Load available Ansible playbooks
            await this.loadAnsiblePlaybooks();
            
            // Initialize scenario mappings
            this.initializeScenarioMappings();
            
            console.log('✅ GRC Compliance Engine initialized successfully');
        } catch (error) {
            console.error('❌ Failed to initialize GRC Compliance Engine:', error);
        }
    }

    /**
     * Load OSCAL catalog from JSON file
     */
    async loadOSCALCatalog() {
        try {
            const response = await fetch('/oscal/catalog/nist-800-53-r5-catalog.json');
            return await response.json();
        } catch (error) {
            console.error('Failed to load OSCAL catalog:', error);
            return null;
        }
    }

    /**
     * Load available Ansible playbooks
     */
    async loadAnsiblePlaybooks() {
        // Standard GRC playbooks
        const playbooks = [
            'ac-3-access-enforcement',
            'ac-6-least-privilege',
            'au-2-audit-events',
            'sc-7-boundary-protection'
        ];

        for (const playbook of playbooks) {
            this.ansiblePlaybooks.set(playbook, {
                name: playbook,
                path: `/ansible/playbooks/${playbook}.yml`,
                controls: this.extractControlsFromPlaybook(playbook)
            });
        }

        // PQC-specific playbooks
        const pqcPlaybooks = [
            'pqc/inventory',
            'pqc/assess',
            'pqc/deploy-mlkem',
            'pqc/deploy-mldsa',
            'pqc/deploy-slhdsa',
            'pqc/hybrid-crypto',
            'pqc/validate'
        ];

        for (const playbook of pqcPlaybooks) {
            const playbookName = playbook.replace('pqc/', '');
            this.ansiblePlaybooks.set(playbook, {
                name: playbook,
                path: `/ansible/playbooks/${playbook}.yml`,
                controls: this.extractPQCControlsFromPlaybook(playbookName)
            });
        }
    }

    /**
     * Initialize scenario-to-control mappings
     */
    initializeScenarioMappings() {
        this.scenarioMappings.set('access_control', {
            keywords: ['access', 'authentication', 'authorization', 'login', 'user', 'permission'],
            controls: ['AC-3', 'AC-6', 'AC-7', 'AC-8'],
            playbooks: ['ac-3-access-enforcement', 'ac-6-least-privilege']
        });

        this.scenarioMappings.set('audit_logging', {
            keywords: ['audit', 'log', 'monitoring', 'tracking', 'compliance'],
            controls: ['AU-2', 'AU-3', 'AU-4', 'AU-5'],
            playbooks: ['au-2-audit-events']
        });

        this.scenarioMappings.set('network_security', {
            keywords: ['network', 'firewall', 'boundary', 'traffic', 'connection'],
            controls: ['SC-7', 'SC-8', 'SC-9', 'SC-10'],
            playbooks: ['sc-7-boundary-protection']
        });

        this.scenarioMappings.set('data_protection', {
            keywords: ['data', 'encryption', 'privacy', 'sensitive', 'confidential'],
            controls: ['SC-28', 'SC-29', 'SC-30', 'SC-31'],
            playbooks: ['sc-28-data-protection']
        });

        // PQC-specific scenario mappings
        this.scenarioMappings.set('pqc_migration', {
            keywords: ['post-quantum', 'quantum', 'pqc', 'cryptography', 'cryptographic', 'migration', 'fips 203', 'fips 204', 'fips 205', 'ml-kem', 'ml-dsa', 'slh-dsa', 'rsa', 'ecc', 'elliptic curve', 'harvest now decrypt later'],
            controls: ['SC-12', 'SC-13', 'SC-17', 'SC-28'],
            playbooks: ['pqc/inventory', 'pqc/assess', 'pqc/deploy-mlkem', 'pqc/deploy-mldsa', 'pqc/deploy-slhdsa']
        });

        this.scenarioMappings.set('quantum_risk', {
            keywords: ['quantum risk', 'quantum threat', 'quantum computing', 'quantum vulnerability', 'quantum resistant', 'quantum safe'],
            controls: ['SC-12', 'SC-13', 'SC-17'],
            playbooks: ['pqc/assess', 'pqc/validate']
        });
    }

    /**
     * Analyze user scenario and generate compliance validation plan
     */
    async analyzeScenario(userScenario) {
        try {
            console.log('🔍 Analyzing scenario:', userScenario);
            
            // Extract keywords from scenario
            const keywords = this.extractKeywords(userScenario);
            
            // Map to relevant controls
            const relevantControls = this.mapScenarioToControls(keywords);
            
            // Generate validation plan
            const validationPlan = await this.generateValidationPlan(relevantControls);
            
            // Create OSCAL assessment plan
            const assessmentPlan = this.createOSCALAssessmentPlan(validationPlan);
            
            return {
                scenario: userScenario,
                keywords: keywords,
                relevantControls: relevantControls,
                validationPlan: validationPlan,
                assessmentPlan: assessmentPlan,
                timestamp: new Date().toISOString()
            };
            
        } catch (error) {
            console.error('Error analyzing scenario:', error);
            throw error;
        }
    }

    /**
     * Extract keywords from user scenario
     */
    extractKeywords(scenario) {
        const text = scenario.toLowerCase();
        const keywords = [];
        
        // Check against scenario mappings
        for (const [category, mapping] of this.scenarioMappings) {
            for (const keyword of mapping.keywords) {
                if (text.includes(keyword)) {
                    keywords.push({
                        keyword: keyword,
                        category: category,
                        controls: mapping.controls,
                        playbooks: mapping.playbooks
                    });
                }
            }
        }
        
        return keywords;
    }

    /**
     * Map scenario keywords to relevant controls
     */
    mapScenarioToControls(keywords) {
        const controls = new Set();
        const playbooks = new Set();
        
        for (const kw of keywords) {
            kw.controls.forEach(control => controls.add(control));
            kw.playbooks.forEach(playbook => playbooks.add(playbook));
        }
        
        return {
            controls: Array.from(controls),
            playbooks: Array.from(playbooks)
        };
    }

    /**
     * Generate validation plan with Ansible playbooks
     */
    async generateValidationPlan(relevantControls) {
        const validationPlan = {
            controls: [],
            playbooks: [],
            estimatedDuration: 0,
            complexity: 'medium'
        };

        for (const controlId of relevantControls.controls) {
            const control = this.findControlInCatalog(controlId);
            if (control) {
                validationPlan.controls.push({
                    id: controlId,
                    title: control.title,
                    description: control.statements[0]?.description,
                    priority: this.getControlPriority(control),
                    playbook: this.getPlaybookForControl(controlId)
                });
            }
        }

        for (const playbookName of relevantControls.playbooks) {
            const playbook = this.ansiblePlaybooks.get(playbookName);
            if (playbook) {
                validationPlan.playbooks.push({
                    name: playbookName,
                    path: playbook.path,
                    controls: playbook.controls,
                    estimatedTime: this.estimatePlaybookRuntime(playbookName)
                });
                validationPlan.estimatedDuration += playbook.estimatedTime || 5;
            }
        }

        return validationPlan;
    }

    /**
     * Create OSCAL assessment plan
     */
    createOSCALAssessmentPlan(validationPlan) {
        return {
            "assessment-plan": {
                "uuid": `urn:uuid:${this.generateUUID()}`,
                "metadata": {
                    "title": "GRC Compliance Assessment Plan",
                    "last-modified": new Date().toISOString(),
                    "version": "1.0.0",
                    "oscal-version": "1.0.0"
                },
                "import-profile": {
                    "href": "/oscal/catalog/nist-800-53-r5-catalog.json"
                },
                "assessment-subjects": [
                    {
                        "type": "system",
                        "title": "Target System for Compliance Assessment",
                        "description": "System under assessment for GRC compliance validation"
                    }
                ],
                "assessment-activities": validationPlan.controls.map(control => ({
                    "uuid": `urn:uuid:${this.generateUUID()}`,
                    "title": `Validate ${control.id}: ${control.title}`,
                    "description": control.description,
                    "props": [
                        {
                            "name": "control-id",
                            "value": control.id
                        },
                        {
                            "name": "priority",
                            "value": control.priority
                        },
                        {
                            "name": "ansible-playbook",
                            "value": control.playbook
                        }
                    ],
                    "steps": [
                        {
                            "uuid": `urn:uuid:${this.generateUUID()}`,
                            "title": "Execute Ansible Playbook",
                            "description": `Run ${control.playbook} to validate ${control.id} implementation`,
                            "props": [
                                {
                                    "name": "playbook-path",
                                    "value": control.playbook
                                }
                            ]
                        }
                    ]
                })),
                "reviewed-controls": {
                    "control-selections": validationPlan.controls.map(control => ({
                        "include-controls": [
                            {
                                "control-id": control.id
                            }
                        ]
                    }))
                }
            }
        };
    }

    /**
     * Execute compliance validation
     */
    async executeComplianceValidation(validationPlan, targetHosts) {
        try {
            console.log('🚀 Executing compliance validation...');
            
            const results = {
                executionId: this.generateUUID(),
                startTime: new Date().toISOString(),
                targetHosts: targetHosts,
                playbookResults: [],
                overallStatus: 'pending'
            };

            for (const playbook of validationPlan.playbooks) {
                console.log(`📋 Executing playbook: ${playbook.name}`);
                
                const playbookResult = await this.executeAnsiblePlaybook(
                    playbook.path,
                    targetHosts
                );
                
                results.playbookResults.push({
                    playbook: playbook.name,
                    status: playbookResult.status,
                    output: playbookResult.output,
                    findings: playbookResult.findings,
                    timestamp: new Date().toISOString()
                });
            }

            results.endTime = new Date().toISOString();
            results.overallStatus = this.calculateOverallStatus(results.playbookResults);
            
            // Generate compliance report
            const complianceReport = await this.generateComplianceReport(results);
            
            return {
                results: results,
                complianceReport: complianceReport
            };
            
        } catch (error) {
            console.error('Error executing compliance validation:', error);
            throw error;
        }
    }

    /**
     * Execute Ansible playbook (simulated - in production, this would call Ansible API)
     */
    async executeAnsiblePlaybook(playbookPath, targetHosts) {
        // Simulate playbook execution
        console.log(`🔧 Simulating execution of ${playbookPath} on ${targetHosts.join(', ')}`);
        
        // In a real implementation, this would:
        // 1. Call Ansible API or execute ansible-playbook command
        // 2. Parse the output
        // 3. Extract compliance findings
        
        return {
            status: 'completed',
            output: 'Playbook executed successfully',
            findings: [
                {
                    control: 'AC-3',
                    status: 'PASS',
                    message: 'Access enforcement controls properly configured',
                    evidence: 'Authentication services running, ACLs configured'
                }
            ]
        };
    }

    /**
     * Generate compliance report in OSCAL format
     */
    async generateComplianceReport(results) {
        return {
            "assessment-results": {
                "uuid": `urn:uuid:${this.generateUUID()}`,
                "metadata": {
                    "title": "GRC Compliance Assessment Results",
                    "last-modified": new Date().toISOString(),
                    "version": "1.0.0",
                    "oscal-version": "1.0.0"
                },
                "import-ap": {
                    "href": "/oscal/assessment-plans/grc-assessment-plan.json"
                },
                "results": [
                    {
                        "uuid": `urn:uuid:${this.generateUUID()}`,
                        "title": "GRC Compliance Assessment",
                        "description": "Automated compliance assessment using Ansible playbooks",
                        "start": results.startTime,
                        "end": results.endTime,
                        "reviewed-controls": {
                            "control-selections": results.playbookResults.map(result => ({
                                "include-controls": [
                                    {
                                        "control-id": result.playbook.split('-')[0].toUpperCase() + '-' + result.playbook.split('-')[1]
                                    }
                                ]
                            }))
                        },
                        "findings": results.playbookResults.flatMap(result => 
                            result.findings.map(finding => ({
                                "uuid": `urn:uuid:${this.generateUUID()}`,
                                "title": finding.message,
                                "description": finding.evidence,
                                "props": [
                                    {
                                        "name": "status",
                                        "value": finding.status
                                    },
                                    {
                                        "name": "control-id",
                                        "value": finding.control
                                    }
                                ]
                            }))
                        )
                    }
                ]
            }
        };
    }

    // Helper methods
    findControlInCatalog(controlId) {
        if (!this.oscalCatalog) return null;
        
        for (const group of this.oscalCatalog.catalog.groups) {
            for (const control of group.controls) {
                if (control.id === controlId.toLowerCase()) {
                    return control;
                }
            }
        }
        return null;
    }

    getControlPriority(control) {
        const priorityProp = control.props?.find(prop => prop.name === 'priority');
        return priorityProp?.value || 'medium';
    }

    getPlaybookForControl(controlId) {
        const control = this.findControlInCatalog(controlId);
        if (control) {
            const playbookProp = control.props?.find(prop => prop.name === 'ansible-playbook');
            return playbookProp?.value || null;
        }
        return null;
    }

    estimatePlaybookRuntime(playbookName) {
        const runtimeMap = {
            'ac-3-access-enforcement': 3,
            'ac-6-least-privilege': 5,
            'au-2-audit-events': 2,
            'sc-7-boundary-protection': 4,
            // PQC playbook runtime estimates
            'pqc/inventory': 5,
            'pqc/assess': 3,
            'pqc/deploy-mlkem': 10,
            'pqc/deploy-mldsa': 10,
            'pqc/deploy-slhdsa': 10,
            'pqc/hybrid-crypto': 8,
            'pqc/validate': 5
        };
        return runtimeMap[playbookName] || 5;
    }

    calculateOverallStatus(playbookResults) {
        const hasFailures = playbookResults.some(result => result.status === 'failed');
        return hasFailures ? 'failed' : 'passed';
    }

    generateUUID() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            const r = Math.random() * 16 | 0;
            const v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }

    extractControlsFromPlaybook(playbookName) {
        // Extract control IDs from playbook name
        const parts = playbookName.split('-');
        if (parts.length >= 2) {
            return [parts[0].toUpperCase() + '-' + parts[1]];
        }
        return [];
    }

    /**
     * Extract PQC controls from playbook name
     */
    extractPQCControlsFromPlaybook(playbookName) {
        // Map PQC playbooks to their associated NIST controls
        const pqcControlMap = {
            'inventory': ['SC-12', 'SC-13'],
            'assess': ['SC-12', 'SC-13', 'SC-17'],
            'deploy-mlkem': ['SC-12', 'SC-13'],
            'deploy-mldsa': ['SC-17', 'SI-7'],
            'deploy-slhdsa': ['SC-17', 'SI-7'],
            'hybrid-crypto': ['SC-12', 'SC-13'],
            'validate': ['SC-13', 'CA-7']
        };
        
        return pqcControlMap[playbookName] || [];
    }
}

// Export for use in the main application
window.GRCComplianceEngine = GRCComplianceEngine;
