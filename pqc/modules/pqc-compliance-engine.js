/**
 * PQC Compliance Engine
 * Extends GRC Compliance Engine with Post-Quantum Cryptography capabilities
 * Integrates PQC migration scenarios with NIST 800-53 and OSCAL framework
 */

class PQCComplianceEngine extends GRCComplianceEngine {
    constructor() {
        super();
        this.pqcControls = new Map();
        this.quantumRiskScoring = new Map();
        this.migrationRoadmap = null;
        this.initializePQCEngine();
    }

    /**
     * Initialize PQC-specific capabilities
     */
    async initializePQCEngine() {
        try {
            // Load PQC control mappings
            await this.loadPQCControls();
            
            // Initialize quantum risk scoring
            this.initializeQuantumRiskScoring();
            
            // Initialize migration roadmap structure
            this.initializeMigrationRoadmap();
            
            console.log('✅ PQC Compliance Engine initialized successfully');
        } catch (error) {
            console.error('❌ Failed to initialize PQC Compliance Engine:', error);
        }
    }

    /**
     * Load PQC control mappings (FIPS 203, 204, 205 to NIST 800-53)
     */
    async loadPQCControls() {
        // Map PQC standards to NIST 800-53 controls
        this.pqcControls.set('FIPS-203', {
            standard: 'NIST FIPS 203',
            title: 'Module-Lattice-Based Key-Encapsulation Mechanism (ML-KEM)',
            nistControls: ['SC-12', 'SC-13', 'SC-17'],
            description: 'Key encapsulation mechanism for post-quantum cryptography',
            quantumResistant: true
        });

        this.pqcControls.set('FIPS-204', {
            standard: 'NIST FIPS 204',
            title: 'Module-Lattice-Based Digital Signature Algorithm (ML-DSA)',
            nistControls: ['SC-12', 'SC-13', 'SC-17', 'SI-7'],
            description: 'Digital signature algorithm for post-quantum cryptography',
            quantumResistant: true
        });

        this.pqcControls.set('FIPS-205', {
            standard: 'NIST FIPS 205',
            title: 'Stateless Hash-Based Digital Signature Algorithm (SLH-DSA)',
            nistControls: ['SC-12', 'SC-13', 'SC-17', 'SI-7'],
            description: 'Hash-based digital signature for post-quantum cryptography',
            quantumResistant: true
        });

        // Map vulnerable algorithms to risk levels
        this.pqcControls.set('RSA', {
            algorithm: 'RSA',
            quantumVulnerability: 'high',
            riskLevel: 'critical',
            migrationPriority: 'high',
            deprecatedDate: '2030-12-31',
            disallowedDate: '2035-12-31'
        });

        this.pqcControls.set('ECC', {
            algorithm: 'ECC',
            quantumVulnerability: 'high',
            riskLevel: 'critical',
            migrationPriority: 'high',
            deprecatedDate: '2030-12-31',
            disallowedDate: '2035-12-31'
        });

        this.pqcControls.set('DSA', {
            algorithm: 'DSA',
            quantumVulnerability: 'high',
            riskLevel: 'critical',
            migrationPriority: 'high',
            deprecatedDate: '2030-12-31',
            disallowedDate: '2035-12-31'
        });
    }

    /**
     * Initialize quantum risk scoring parameters
     */
    initializeQuantumRiskScoring() {
        this.quantumRiskScoring.set('algorithmRisk', {
            'RSA': 10,
            'ECC': 10,
            'DSA': 10,
            'AES-256': 3,
            'SHA-256': 2,
            'ML-KEM': 1,
            'ML-DSA': 1,
            'SLH-DSA': 1
        });

        this.quantumRiskScoring.set('dataSensitivity', {
            'classified': 10,
            'confidential': 8,
            'internal': 5,
            'public': 1
        });

        this.quantumRiskScoring.set('systemCriticality', {
            'critical': 10,
            'high': 7,
            'medium': 4,
            'low': 1
        });
    }

    /**
     * Initialize four-phase migration roadmap structure
     */
    initializeMigrationRoadmap() {
        this.migrationRoadmap = {
            phase1: {
                name: 'Preparation',
                description: 'Stakeholder alignment, team formation, budget planning',
                milestones: [],
                status: 'pending'
            },
            phase2: {
                name: 'Baseline Understanding',
                description: 'Inventory, prioritization, gap analysis',
                milestones: [],
                status: 'pending'
            },
            phase3: {
                name: 'Planning and Execution',
                description: 'Solution selection, implementation, testing',
                milestones: [],
                status: 'pending'
            },
            phase4: {
                name: 'Monitoring and Evaluation',
                description: 'Validation, continuous monitoring, performance metrics',
                milestones: [],
                status: 'pending'
            }
        };
    }

    /**
     * Analyze PQC migration scenario
     */
    async analyzePQCScenario(userScenario) {
        try {
            console.log('🔍 Analyzing PQC migration scenario:', userScenario);
            
            // Check if scenario is PQC-related
            const isPQCScenario = this.detectPQCScenario(userScenario);
            if (!isPQCScenario) {
                // Fall back to standard GRC analysis
                return await super.analyzeScenario(userScenario);
            }

            // Extract PQC-specific keywords
            const pqcKeywords = this.extractPQCKeywords(userScenario);
            
            // Identify cryptographic assets
            const assets = await this.identifyCryptographicAssets(userScenario);
            
            // Perform quantum risk assessment
            const riskAssessment = await this.performQuantumRiskAssessment(assets);
            
            // Map to PQC controls
            const pqcControls = this.mapToPQCControls(pqcKeywords, riskAssessment);
            
            // Generate migration roadmap
            const roadmap = this.generateMigrationRoadmap(riskAssessment);
            
            // Create PQC assessment plan
            const assessmentPlan = this.createPQCAssessmentPlan(pqcControls, roadmap);
            
            return {
                scenario: userScenario,
                scenarioType: 'PQC Migration',
                pqcKeywords: pqcKeywords,
                assets: assets,
                riskAssessment: riskAssessment,
                pqcControls: pqcControls,
                migrationRoadmap: roadmap,
                assessmentPlan: assessmentPlan,
                timeline: {
                    deprecatedDate: '2030-12-31',
                    disallowedDate: '2035-12-31',
                    daysRemaining: this.calculateDaysRemaining('2030-12-31')
                },
                timestamp: new Date().toISOString()
            };
            
        } catch (error) {
            console.error('Error analyzing PQC scenario:', error);
            throw error;
        }
    }

    /**
     * Detect if scenario is PQC-related
     */
    detectPQCScenario(scenario) {
        const pqcKeywords = [
            'post-quantum', 'quantum', 'pqc', 'cryptography', 'cryptographic',
            'migration', 'fips 203', 'fips 204', 'fips 205', 'ml-kem', 'ml-dsa',
            'slh-dsa', 'rsa', 'ecc', 'elliptic curve', 'digital signature',
            'key exchange', 'harvest now decrypt later', 'quantum computing'
        ];
        
        const text = scenario.toLowerCase();
        return pqcKeywords.some(keyword => text.includes(keyword));
    }

    /**
     * Extract PQC-specific keywords
     */
    extractPQCKeywords(scenario) {
        const keywords = [];
        const text = scenario.toLowerCase();
        
        // Algorithm detection
        const algorithms = ['rsa', 'ecc', 'dsa', 'aes', 'sha', 'ml-kem', 'ml-dsa', 'slh-dsa'];
        algorithms.forEach(alg => {
            if (text.includes(alg)) {
                keywords.push({ type: 'algorithm', value: alg });
            }
        });
        
        // PQC standard detection
        const standards = ['fips 203', 'fips 204', 'fips 205', 'nist sp 800-53'];
        standards.forEach(std => {
            if (text.includes(std)) {
                keywords.push({ type: 'standard', value: std });
            }
        });
        
        // Risk indicators
        const riskIndicators = ['classified', 'confidential', 'critical', 'sensitive', 'long-term'];
        riskIndicators.forEach(indicator => {
            if (text.includes(indicator)) {
                keywords.push({ type: 'risk', value: indicator });
            }
        });
        
        return keywords;
    }

    /**
     * Identify cryptographic assets from scenario
     */
    async identifyCryptographicAssets(scenario) {
        // In production, this would scan infrastructure
        // For now, simulate asset discovery
        const assets = [];
        
        // Extract potential asset types from scenario
        const assetTypes = ['database', 'api', 'application', 'network', 'storage', 'key management'];
        const text = scenario.toLowerCase();
        
        assetTypes.forEach(type => {
            if (text.includes(type)) {
                assets.push({
                    id: this.generateUUID(),
                    name: `${type} asset`,
                    type: type,
                    algorithm: this.detectAlgorithm(scenario),
                    quantumVulnerability: 'high',
                    dataShelfLife: this.estimateDataShelfLife(scenario),
                    businessCriticality: this.assessBusinessCriticality(scenario),
                    discoveredDate: new Date().toISOString()
                });
            }
        });
        
        return assets;
    }

    /**
     * Perform quantum risk assessment
     */
    async performQuantumRiskAssessment(assets) {
        const assessments = [];
        
        for (const asset of assets) {
            const algorithmRisk = this.quantumRiskScoring.get('algorithmRisk')[asset.algorithm] || 5;
            const dataSensitivity = this.quantumRiskScoring.get('dataSensitivity')[asset.dataSensitivity] || 5;
            const systemCriticality = this.quantumRiskScoring.get('systemCriticality')[asset.businessCriticality] || 5;
            
            const riskScore = (algorithmRisk * 0.4) + (dataSensitivity * 0.3) + (systemCriticality * 0.3);
            const riskLevel = this.calculateRiskLevel(riskScore);
            
            assessments.push({
                assetId: asset.id,
                riskScore: Math.round(riskScore * 10) / 10,
                riskLevel: riskLevel,
                algorithmRisk: algorithmRisk,
                dataSensitivity: dataSensitivity,
                systemCriticality: systemCriticality,
                harvestNowRisk: algorithmRisk >= 8 ? 'high' : 'medium',
                timelineToThreat: this.estimateTimelineToThreat(riskScore),
                migrationPriority: this.determineMigrationPriority(riskScore),
                assessmentDate: new Date().toISOString()
            });
        }
        
        return {
            overallRiskScore: this.calculateOverallRisk(assessments),
            overallRiskLevel: this.calculateOverallRiskLevel(assessments),
            assetAssessments: assessments,
            criticalAssets: assessments.filter(a => a.riskLevel === 'critical'),
            highPriorityAssets: assessments.filter(a => a.migrationPriority === 'high')
        };
    }

    /**
     * Map to PQC controls
     */
    mapToPQCControls(keywords, riskAssessment) {
        const controls = [];
        
        // Always include core PQC controls
        controls.push({
            id: 'SC-12',
            title: 'Cryptographic Key Establishment and Management',
            pqcRelevance: 'high',
            fipsStandards: ['FIPS-203', 'FIPS-204', 'FIPS-205'],
            description: 'Establishes and manages cryptographic keys using quantum-resistant algorithms'
        });
        
        controls.push({
            id: 'SC-13',
            title: 'Cryptographic Protection',
            pqcRelevance: 'high',
            fipsStandards: ['FIPS-203', 'FIPS-204', 'FIPS-205'],
            description: 'Uses quantum-resistant cryptographic mechanisms for data protection'
        });
        
        controls.push({
            id: 'SC-17',
            title: 'Public Key Infrastructure Certificates',
            pqcRelevance: 'high',
            fipsStandards: ['FIPS-204', 'FIPS-205'],
            description: 'Uses PQC algorithms for digital signatures in PKI certificates'
        });
        
        // Add controls based on risk assessment
        if (riskAssessment.overallRiskLevel === 'critical' || riskAssessment.overallRiskLevel === 'high') {
            controls.push({
                id: 'SC-28',
                title: 'Protection of Information at Rest',
                pqcRelevance: 'medium',
                description: 'Protects data at rest using quantum-resistant encryption'
            });
        }
        
        return controls;
    }

    /**
     * Generate migration roadmap
     */
    generateMigrationRoadmap(riskAssessment) {
        const roadmap = JSON.parse(JSON.stringify(this.migrationRoadmap));
        
        // Set milestones based on risk assessment
        roadmap.phase1.milestones = [
            {
                name: 'Stakeholder Alignment',
                targetDate: this.calculateTargetDate(30),
                status: 'pending'
            },
            {
                name: 'Team Formation',
                targetDate: this.calculateTargetDate(45),
                status: 'pending'
            }
        ];
        
        roadmap.phase2.milestones = [
            {
                name: 'Complete Asset Inventory',
                targetDate: this.calculateTargetDate(90),
                status: 'pending',
                assetsCount: riskAssessment.assetAssessments.length
            },
            {
                name: 'Risk Assessment Complete',
                targetDate: this.calculateTargetDate(120),
                status: 'pending'
            }
        ];
        
        roadmap.phase3.milestones = [
            {
                name: 'PQC Solution Selection',
                targetDate: this.calculateTargetDate(180),
                status: 'pending'
            },
            {
                name: 'Begin Migration',
                targetDate: this.calculateTargetDate(240),
                status: 'pending'
            }
        ];
        
        roadmap.phase4.milestones = [
            {
                name: 'Validation Complete',
                targetDate: this.calculateTargetDate(365),
                status: 'pending'
            },
            {
                name: 'Continuous Monitoring Established',
                targetDate: this.calculateTargetDate(400),
                status: 'pending'
            }
        ];
        
        return roadmap;
    }

    /**
     * Create PQC-specific OSCAL assessment plan
     */
    createPQCAssessmentPlan(pqcControls, roadmap) {
        const basePlan = super.createOSCALAssessmentPlan({
            controls: pqcControls.map(c => ({
                id: c.id,
                title: c.title,
                description: c.description,
                priority: 'high',
                playbook: `pqc-${c.id.toLowerCase()}`
            })),
            playbooks: []
        });
        
        // Add PQC-specific properties
        basePlan['assessment-plan'].props = basePlan['assessment-plan'].props || [];
        basePlan['assessment-plan'].props.push({
            name: 'pqc-migration',
            value: 'true'
        });
        basePlan['assessment-plan'].props.push({
            name: 'deprecated-date',
            value: '2030-12-31'
        });
        basePlan['assessment-plan'].props.push({
            name: 'disallowed-date',
            value: '2035-12-31'
        });
        
        return basePlan;
    }

    // Helper methods
    detectAlgorithm(scenario) {
        const text = scenario.toLowerCase();
        if (text.includes('rsa')) return 'RSA';
        if (text.includes('ecc') || text.includes('elliptic')) return 'ECC';
        if (text.includes('dsa')) return 'DSA';
        if (text.includes('aes')) return 'AES-256';
        return 'Unknown';
    }

    estimateDataShelfLife(scenario) {
        const text = scenario.toLowerCase();
        if (text.includes('20 year') || text.includes('long-term')) return 20;
        if (text.includes('10 year')) return 10;
        if (text.includes('5 year')) return 5;
        return 1;
    }

    assessBusinessCriticality(scenario) {
        const text = scenario.toLowerCase();
        if (text.includes('critical') || text.includes('classified')) return 'critical';
        if (text.includes('high') || text.includes('confidential')) return 'high';
        if (text.includes('medium')) return 'medium';
        return 'low';
    }

    calculateRiskLevel(riskScore) {
        if (riskScore >= 8) return 'critical';
        if (riskScore >= 6) return 'high';
        if (riskScore >= 4) return 'medium';
        return 'low';
    }

    calculateOverallRisk(assessments) {
        if (assessments.length === 0) return 0;
        const sum = assessments.reduce((acc, a) => acc + a.riskScore, 0);
        return Math.round((sum / assessments.length) * 10) / 10;
    }

    calculateOverallRiskLevel(assessments) {
        const overallScore = this.calculateOverallRisk(assessments);
        return this.calculateRiskLevel(overallScore);
    }

    estimateTimelineToThreat(riskScore) {
        if (riskScore >= 8) return '5-10 years';
        if (riskScore >= 6) return '10-15 years';
        return '15+ years';
    }

    determineMigrationPriority(riskScore) {
        if (riskScore >= 8) return 'high';
        if (riskScore >= 6) return 'medium';
        return 'low';
    }

    calculateDaysRemaining(targetDate) {
        const target = new Date(targetDate);
        const now = new Date();
        const diff = target - now;
        return Math.ceil(diff / (1000 * 60 * 60 * 24));
    }

    calculateTargetDate(daysFromNow) {
        const date = new Date();
        date.setDate(date.getDate() + daysFromNow);
        return date.toISOString().split('T')[0];
    }
}

// Export for use in the main application
window.PQCComplianceEngine = PQCComplianceEngine;


