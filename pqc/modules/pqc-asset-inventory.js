/**
 * PQC Asset Inventory Module
 * Discovers and catalogs cryptographic implementations
 * Integrates with OSCAL catalog structure for asset classification
 */

class PQCAssetInventory {
    constructor() {
        this.assets = [];
        this.algorithmTypes = new Map();
        this.quantumVulnerabilities = new Map();
        this.initializeInventory();
    }

    /**
     * Initialize asset inventory system
     */
    initializeInventory() {
        // Define algorithm types and quantum vulnerabilities
        this.algorithmTypes.set('RSA', {
            type: 'Public Key',
            keySize: [1024, 2048, 4096],
            quantumVulnerable: true,
            vulnerabilityLevel: 'critical'
        });

        this.algorithmTypes.set('ECC', {
            type: 'Public Key',
            curve: ['P-256', 'P-384', 'P-521'],
            quantumVulnerable: true,
            vulnerabilityLevel: 'critical'
        });

        this.algorithmTypes.set('DSA', {
            type: 'Digital Signature',
            keySize: [1024, 2048, 3072],
            quantumVulnerable: true,
            vulnerabilityLevel: 'critical'
        });

        this.algorithmTypes.set('AES-256', {
            type: 'Symmetric',
            keySize: 256,
            quantumVulnerable: false,
            vulnerabilityLevel: 'low'
        });

        this.algorithmTypes.set('ML-KEM', {
            type: 'Public Key (PQC)',
            standard: 'FIPS-203',
            quantumVulnerable: false,
            vulnerabilityLevel: 'none'
        });

        this.algorithmTypes.set('ML-DSA', {
            type: 'Digital Signature (PQC)',
            standard: 'FIPS-204',
            quantumVulnerable: false,
            vulnerabilityLevel: 'none'
        });

        this.algorithmTypes.set('SLH-DSA', {
            type: 'Digital Signature (PQC)',
            standard: 'FIPS-205',
            quantumVulnerable: false,
            vulnerabilityLevel: 'none'
        });
    }

    /**
     * Discover cryptographic assets
     */
    async discoverAssets(targetHosts = []) {
        console.log('🔍 Discovering cryptographic assets...');
        
        // In production, this would:
        // 1. Scan target hosts for cryptographic implementations
        // 2. Analyze configuration files
        // 3. Inspect code repositories
        // 4. Query certificate stores
        // 5. Check TLS/SSL configurations
        
        const discoveredAssets = [];
        
        // Simulate asset discovery
        const commonAssets = [
            { name: 'TLS Server Certificate', type: 'certificate', algorithm: 'RSA' },
            { name: 'API Authentication Key', type: 'key', algorithm: 'ECC' },
            { name: 'Database Encryption', type: 'encryption', algorithm: 'AES-256' },
            { name: 'Code Signing Certificate', type: 'certificate', algorithm: 'DSA' }
        ];
        
        for (const asset of commonAssets) {
            const inventoryAsset = await this.catalogAsset(asset);
            discoveredAssets.push(inventoryAsset);
        }
        
        this.assets = [...this.assets, ...discoveredAssets];
        return discoveredAssets;
    }

    /**
     * Catalog a discovered asset
     */
    async catalogAsset(asset) {
        const algorithmInfo = this.algorithmTypes.get(asset.algorithm) || {};
        
        return {
            id: this.generateUUID(),
            name: asset.name,
            type: asset.type,
            algorithm: asset.algorithm,
            algorithmType: algorithmInfo.type,
            quantumVulnerability: algorithmInfo.quantumVulnerable ? 'high' : 'low',
            vulnerabilityLevel: algorithmInfo.vulnerabilityLevel || 'unknown',
            dataShelfLife: this.estimateDataShelfLife(asset),
            businessCriticality: this.assessBusinessCriticality(asset),
            migrationPriority: this.calculateMigrationPriority(asset, algorithmInfo),
            discoveredDate: new Date().toISOString(),
            lastAssessed: new Date().toISOString(),
            location: asset.location || 'unknown',
            system: asset.system || 'unknown'
        };
    }

    /**
     * Classify asset by quantum vulnerability
     */
    classifyByQuantumVulnerability(asset) {
        const algorithmInfo = this.algorithmTypes.get(asset.algorithm);
        if (!algorithmInfo) return 'unknown';
        
        if (algorithmInfo.quantumVulnerable) {
            return algorithmInfo.vulnerabilityLevel;
        }
        return 'none';
    }

    /**
     * Assess data shelf-life for prioritization
     */
    estimateDataShelfLife(asset) {
        // In production, this would analyze:
        // - Data retention policies
        // - Regulatory requirements
        // - Business needs
        // - Classification level
        
        if (asset.type === 'certificate' || asset.type === 'key') {
            return 10; // Typical certificate/key lifetime
        }
        return 5; // Default
    }

    /**
     * Assess business criticality
     */
    assessBusinessCriticality(asset) {
        // In production, this would consider:
        // - System criticality
        // - Data sensitivity
        // - Business impact
        // - Regulatory requirements
        
        if (asset.type === 'certificate' && asset.name.includes('TLS')) {
            return 'critical';
        }
        if (asset.type === 'key' && asset.name.includes('Authentication')) {
            return 'high';
        }
        return 'medium';
    }

    /**
     * Calculate migration priority
     */
    calculateMigrationPriority(asset, algorithmInfo) {
        if (algorithmInfo.quantumVulnerable && algorithmInfo.vulnerabilityLevel === 'critical') {
            return 'high';
        }
        if (algorithmInfo.quantumVulnerable) {
            return 'medium';
        }
        return 'low';
    }

    /**
     * Get assets by quantum vulnerability
     */
    getAssetsByVulnerability(vulnerabilityLevel) {
        return this.assets.filter(asset => 
            asset.vulnerabilityLevel === vulnerabilityLevel
        );
    }

    /**
     * Get assets by migration priority
     */
    getAssetsByPriority(priority) {
        return this.assets.filter(asset => 
            asset.migrationPriority === priority
        );
    }

    /**
     * Generate OSCAL-formatted asset inventory
     */
    generateOSCALInventory() {
        return {
            "inventory": {
                "uuid": `urn:uuid:${this.generateUUID()}`,
                "metadata": {
                    "title": "PQC Cryptographic Asset Inventory",
                    "last-modified": new Date().toISOString(),
                    "version": "1.0.0",
                    "oscal-version": "1.0.0"
                },
                "components": this.assets.map(asset => ({
                    "uuid": `urn:uuid:${asset.id}`,
                    "type": asset.type,
                    "title": asset.name,
                    "description": `Cryptographic asset using ${asset.algorithm}`,
                    "props": [
                        {
                            "name": "algorithm",
                            "value": asset.algorithm
                        },
                        {
                            "name": "quantum-vulnerability",
                            "value": asset.quantumVulnerability
                        },
                        {
                            "name": "migration-priority",
                            "value": asset.migrationPriority
                        },
                        {
                            "name": "business-criticality",
                            "value": asset.businessCriticality
                        }
                    ]
                }))
            }
        };
    }

    generateUUID() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            const r = Math.random() * 16 | 0;
            const v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }
}

// Export for use in the main application
window.PQCAssetInventory = PQCAssetInventory;


