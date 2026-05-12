/**
 * NIST 800-53 to Firestore Migration Script
 * This script parses the OSCAL catalog and prepares it for Firestore upload.
 */

const fs = require('fs');
const path = require('path');

// Path to your OSCAL catalog
const OSCAL_PATH = path.join(__dirname, '../../oscal/catalog/nist-800-53-r5-catalog.json');

async function prepareMigration() {
    console.log('🚀 Starting NIST 800-53 to Firestore Migration Preparation...');

    try {
        const rawData = fs.readFileSync(OSCAL_PATH, 'utf8');
        const catalog = JSON.parse(rawData);
        
        const controls = [];
        
        // Flatten the OSCAL structure for Firestore collections
        catalog.catalog.groups.forEach(group => {
            const family = group.title;
            group.controls.forEach(control => {
                controls.push({
                    id: control.id.toUpperCase(),
                    title: control.title,
                    family: family,
                    description: control.statements?.[0]?.description || 'No description available',
                    priority: control.props?.find(p => p.name === 'priority')?.value || 'medium',
                    lastUpdated: new Date().toISOString()
                });
            });
        });

        console.log(`✅ Parsed ${controls.length} controls.`);
        
        // In a real environment, you would use firebase-admin here
        console.log('📝 Migration Data Sample:');
        console.log(JSON.stringify(controls.slice(0, 2), null, 2));
        
        console.log('\n⚠️ NEXT STEP: Run this with your Firebase Service Account credentials.');
        
    } catch (error) {
        console.error('❌ Migration failed:', error);
    }
}

prepareMigration();
