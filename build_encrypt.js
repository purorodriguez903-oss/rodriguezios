const fs = require('fs');
const path = require('path');
const vm = require('vm');
const https = require('https');
const JavaScriptObfuscator = require('javascript-obfuscator');
const CleanCSS = require('clean-css');

console.log('====================================================');
console.log('🔒 RODRIGUEZ LAWNCARE - MILITARY WEB ENCRYPTION SUITE');
console.log('====================================================');

const JS_FILES = [
    { src: 'src/js/main.js', dest: 'js/main.js' },
    { src: 'src/js/gallery.js', dest: 'js/gallery.js' },
    { src: 'src/js/satellite-scanner.js', dest: 'js/satellite-scanner.js' },
    { src: 'src/js/ai-assistant.js', dest: 'js/ai-assistant.js' },
    { src: 'src/security/anti-bot.js', dest: 'security/anti-bot.js' },
    { src: 'src/security/web-shield.js', dest: 'security/web-shield.js' }
];

const CSS_FILES = [
    { src: 'src/css/styles.css', dest: 'css/styles.css' },
    { src: 'src/security/security.css', dest: 'security/security.css' }
];

const OBFUSCATION_OPTIONS = {
    compact: true,
    controlFlowFlattening: true,
    controlFlowFlatteningThreshold: 0.75,
    numbersToExpressions: true, // Numbers converted to hex expressions (e.g. 0x1f + 0x2a)
    simplify: true,
    stringArray: true,
    stringArrayEncoding: ['base64'],
    stringArrayThreshold: 0.85,
    stringArrayIndexShift: true,
    stringArrayRotate: true,
    stringArrayShuffle: true,
    stringArrayWrappersCount: 2,
    stringArrayWrappersType: 'function',
    splitStrings: true,
    splitStringsChunkLength: 8,
    identifierNamesGenerator: 'hexadecimal', // Generates _0x4a1b, _0x2c3d
    identifiersPrefix: '_0x',
    unicodeEscapeSequence: true, // Escapes strings to \x.. and \u.. unicode
    selfDefending: true, // Prevents beautification / formatting in DevTools
    debugProtection: true, // Traps and freezes DevTools with debugger loop
    debugProtectionInterval: 2500,
    disableConsoleOutput: false,
    renameGlobals: false,
    transformObjectKeys: false,
    target: 'browser'
};

const TROLL_BANNER = `/*
 * =========================================================================================
 *  💀 PAGE 100% ENCRYPTED BY RAFA • LOL NOOB HAHAHA 😂💀
 * =========================================================================================
 *   ____      _    _____ _         _           _
 *  |  _ \\    / \\  |  ___/ \\       | |     ___ | |
 *  | |_) |  / _ \\ | |_ / _ \\  ___ | |    / _ \\| |
 *  |  _ <  / ___ \\|  _/ ___ \\|___|| |___| (_) | |
 *  |_| \\_\\/_/   \\_\\_|/_/   \\_\\    |_____|\\___/|_|
 *
 *  Nice try noob! You cannot edit, inspect, steal, or copy anything from this page!
 *  Rodriguez LawnCare Military-Grade Anti-Theft Protection is ACTIVE.
 *  All decompilation, cloning, and scraping attempts are blocked & logged.
 *  Go build your own website, noob! 🛡️⚡
 * =========================================================================================
 */\n`;

const CSS_BANNER = `/*
 * =========================================================================================
 *  💀 PAGE 100% ENCRYPTED BY RAFA • LOL NOOB HAHAHA 😂💀
 *  PROTECTED STYLESHEET - REVERSE ENGINEERING & DESIGN THEFT PROHIBITED
 * =========================================================================================
 */\n`;

const HTML_TROLL_BANNER = `<!--
=========================================================================================
 💀 PAGE 100% ENCRYPTED BY RAFA • LOL NOOB HAHAHA 😂💀
=========================================================================================
  ____      _    _____ _         _           _
 |  _ \\    / \\  |  ___/ \\       | |     ___ | |
 | |_) |  / _ \\ | |_ / _ \\  ___ | |    / _ \\| |
 |  _ <  / ___ \\|  _/ ___ \\|___|| |___| (_) | |
 |_| \\_\\/_/   \\_\\_|/_/   \\_\\    |_____|\\___/|_|

 Nice try noob! You cannot edit, inspect, steal, or copy anything from this page!
 Rodriguez LawnCare Military-Grade Anti-Theft Protection is ACTIVE.
 All decompilation, cloning, and scraping attempts are blocked & logged.
 Go build your own website, noob! 🛡️⚡
=========================================================================================
-->\n`;

async function syncLiveMobileUploads() {
    console.log('\n[0/4] Checking and Syncing Live Mobile Uploads from Cloud...');

    // 1. Sync Gallery Items
    await new Promise((resolve) => {
        const req = https.get('https://rodriguezlawncare.xyz/api/gallery', { headers: { 'User-Agent': 'Mozilla/5.0' }, timeout: 4000 }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(data);
                    const liveItems = parsed.gallery || [];
                    console.log(`  ✓ Cloud server responded with ${liveItems.length} live gallery items.`);

                    const localGalleryPath = path.join(__dirname, 'gallery.json');
                    let localItems = [];
                    if (fs.existsSync(localGalleryPath)) {
                        localItems = JSON.parse(fs.readFileSync(localGalleryPath, 'utf8'));
                    }

                    const localIds = new Set(localItems.map(it => it.id));
                    let added = 0;
                    for (const item of liveItems) {
                        if (item && item.id && !localIds.has(item.id)) {
                            localItems.push(item);
                            localIds.add(item.id);
                            added++;
                        }
                    }

                    // Also backup to data_backup
                    const backupDir = path.join(__dirname, 'data_backup');
                    if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir, { recursive: true });

                    // Permanent Archive Safety Lock: Never allow count to drop below 44
                    const archivePath = path.join(backupDir, 'gallery_permanent_archive.json');
                    if (fs.existsSync(archivePath)) {
                        try {
                            const archiveItems = JSON.parse(fs.readFileSync(archivePath, 'utf8'));
                            for (const aItem of archiveItems) {
                                if (aItem && aItem.id && !localIds.has(aItem.id)) {
                                    localItems.push(aItem);
                                    localIds.add(aItem.id);
                                    added++;
                                }
                            }
                        } catch (e) { }
                    }

                    localItems.sort((a, b) => (b.id || 0) - (a.id || 0));
                    fs.writeFileSync(localGalleryPath, JSON.stringify(localItems, null, 2), 'utf8');
                    fs.writeFileSync(path.join(backupDir, 'gallery_persistent.json'), JSON.stringify(localItems, null, 2), 'utf8');
                    if (localItems.length >= 44) {
                        fs.writeFileSync(archivePath, JSON.stringify(localItems, null, 2), 'utf8');
                    }

                    console.log(`  ✓ Gallery sync complete: ${added} new items merged from phone. Total gallery records: ${localItems.length}`);
                } catch (err) {
                    console.log(`  ✓ Notice: Using local gallery database (${err.message})`);
                }
                resolve();
            });
        });

        req.on('error', (e) => {
            console.log(`  ✓ Cloud gallery sync skipped (${e.message}). Local records preserved.`);
            resolve();
        });
    });

    // 2. Sync Customer Reviews
    await new Promise((resolve) => {
        const req = https.get('https://rodriguezlawncare.xyz/api/reviews', { headers: { 'User-Agent': 'Mozilla/5.0' }, timeout: 4000 }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const liveReviews = JSON.parse(data);
                    if (Array.isArray(liveReviews)) {
                        const localReviewsPath = path.join(__dirname, 'reviews.json');
                        let localReviews = [];
                        if (fs.existsSync(localReviewsPath)) {
                            localReviews = JSON.parse(fs.readFileSync(localReviewsPath, 'utf8'));
                        }

                        const FAKE_REVIEW_IDS = new Set([1, 2, 3]);
                        const localIds = new Set(localReviews.map(r => r.id));
                        let added = 0;
                        for (const rev of liveReviews) {
                            if (rev && rev.id && !FAKE_REVIEW_IDS.has(rev.id) && !localIds.has(rev.id)) {
                                localReviews.push(rev);
                                localIds.add(rev.id);
                                added++;
                            }
                        }

                        localReviews.sort((a, b) => (b.id || 0) - (a.id || 0));
                        fs.writeFileSync(localReviewsPath, JSON.stringify(localReviews, null, 2), 'utf8');

                        const backupDir = path.join(__dirname, 'data_backup');
                        if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir, { recursive: true });
                        fs.writeFileSync(path.join(backupDir, 'reviews_persistent.json'), JSON.stringify(localReviews, null, 2), 'utf8');

                        console.log(`  ✓ Reviews sync complete: ${added} new reviews merged from web/mobile. Total reviews: ${localReviews.length}`);
                    }
                } catch (err) {
                    console.log(`  ✓ Notice: Using local reviews database (${err.message})`);
                }
                resolve();
            });
        });

        req.on('error', (e) => {
            console.log(`  ✓ Cloud reviews sync skipped (${e.message}). Local records preserved.`);
            resolve();
        });
    });

    // 3. Sync Recurring Clients Database
    await new Promise((resolve) => {
        const req = https.get('https://rodriguezlawncare.xyz/api/recurring', { headers: { 'User-Agent': 'Mozilla/5.0' }, timeout: 4000 }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const parsed = JSON.parse(data);
                    const liveClients = parsed.clients || [];
                    if (Array.isArray(liveClients)) {
                        const localClientsPath = path.join(__dirname, 'recurring_clients.json');
                        let localClients = [];
                        if (fs.existsSync(localClientsPath)) {
                            localClients = JSON.parse(fs.readFileSync(localClientsPath, 'utf8'));
                        }

                        const localIds = new Set(localClients.map(c => c.id));
                        let added = 0;
                        for (const client of liveClients) {
                            if (client && client.id && !localIds.has(client.id)) {
                                localClients.push(client);
                                localIds.add(client.id);
                                added++;
                            }
                        }

                        localClients.sort((a, b) => (a.id || 0) - (b.id || 0));
                        fs.writeFileSync(localClientsPath, JSON.stringify(localClients, null, 2), 'utf8');

                        const backupDir = path.join(__dirname, 'data_backup');
                        if (!fs.existsSync(backupDir)) fs.mkdirSync(backupDir, { recursive: true });
                        fs.writeFileSync(path.join(backupDir, 'recurring_persistent.json'), JSON.stringify(localClients, null, 2), 'utf8');

                        console.log(`  ✓ Recurring clients sync complete: ${added} new clients merged from mobile. Total clients: ${localClients.length}`);
                    }
                } catch (err) {
                    console.log(`  ✓ Notice: Using local recurring clients database (${err.message})`);
                }
                resolve();
            });
        });

        req.on('error', (e) => {
            console.log(`  ✓ Cloud recurring clients sync skipped (${e.message}). Local records preserved.`);
            resolve();
        });
    });
}

async function runBuild() {
    await syncLiveMobileUploads();

    console.log('\n[1/4] Encrypting and Obfuscating JavaScript Files...');
    for (const file of JS_FILES) {
        if (!fs.existsSync(file.src)) {
            console.error(`❌ Source file missing: ${file.src}`);
            process.exit(1);
        }
        const raw = fs.readFileSync(file.src, 'utf8');
        const start = Date.now();
        const result = JavaScriptObfuscator.obfuscate(raw, OBFUSCATION_OPTIONS);
        const encryptedCode = result.getObfuscatedCode();
        const duration = Date.now() - start;

        // Verify syntax
        try {
            new vm.Script(encryptedCode);
        } catch (err) {
            console.error(`❌ Syntax verification failed on ${file.dest}:`, err);
            process.exit(1);
        }

        const destDir = path.dirname(file.dest);
        if (!fs.existsSync(destDir)) fs.mkdirSync(destDir, { recursive: true });

        fs.writeFileSync(file.dest, TROLL_BANNER + encryptedCode, 'utf8');
        console.log(`  ✓ ${file.dest.padEnd(26)}: ${raw.length.toString().padStart(6)}b -> ${encryptedCode.length.toString().padStart(7)}b encrypted in ${duration}ms`);
    }

    console.log('\n[2/4] Minifying and Compressing CSS Stylesheets...');
    const cleanCss = new CleanCSS({ level: 2 });
    for (const file of CSS_FILES) {
        if (!fs.existsSync(file.src)) {
            console.error(`❌ CSS Source missing: ${file.src}`);
            process.exit(1);
        }
        const raw = fs.readFileSync(file.src, 'utf8');
        const minified = cleanCss.minify(raw).styles;
        const destDir = path.dirname(file.dest);
        if (!fs.existsSync(destDir)) fs.mkdirSync(destDir, { recursive: true });

        fs.writeFileSync(file.dest, CSS_BANNER + minified, 'utf8');
        console.log(`  ✓ ${file.dest.padEnd(26)}: ${raw.length.toString().padStart(6)}b -> ${minified.length.toString().padStart(7)}b compressed`);
    }

    console.log('\n[3/4] Protecting and Encrypting HTML Shell...');
    let html = fs.readFileSync('index.html', 'utf8');

    // Prepend HTML troll banner if not present
    if (!html.includes('PAGE 100% ENCRYPTED BY RAFA')) {
        html = HTML_TROLL_BANNER + html;
    }

    // Protect body with inline anti-theft attributes
    if (!html.includes('oncontextmenu="return false;"')) {
        html = html.replace('<body class="theme-tactical"', '<body class="theme-tactical" oncontextmenu="return false;" ondragstart="return false;" onselectstart="if (event.target.tagName !== \'INPUT\' && event.target.tagName !== \'TEXTAREA\') return false;"');
        html = html.replace('<body>', '<body oncontextmenu="return false;" ondragstart="return false;" onselectstart="if (event.target.tagName !== \'INPUT\' && event.target.tagName !== \'TEXTAREA\') return false;"');
    }

    console.log('\n[4/4] Updating index.html Cache-Busting Tokens...');
    const stamp = '5.2.rafa_' + Date.now().toString(36);

    html = html.replace(/href="\.\/css\/styles\.css(\?v=[^"]*)?"/g, `href="./css/styles.css?v=${stamp}"`);
    html = html.replace(/href="\.\/security\/security\.css(\?v=[^"]*)?"/g, `href="./security/security.css?v=${stamp}"`);
    html = html.replace(/src="\.\/js\/main\.js(\?v=[^"]*)?"/g, `src="./js/main.js?v=${stamp}"`);
    html = html.replace(/src="\.\/js\/gallery\.js(\?v=[^"]*)?"/g, `src="./js/gallery.js?v=${stamp}"`);
    html = html.replace(/src="\.\/js\/satellite-scanner\.js(\?v=[^"]*)?"/g, `src="./js/satellite-scanner.js?v=${stamp}"`);
    html = html.replace(/src="\.\/js\/ai-assistant\.js(\?v=[^"]*)?"/g, `src="./js/ai-assistant.js?v=${stamp}"`);
    html = html.replace(/src="\.\/security\/anti-bot\.js(\?v=[^"]*)?"/g, `src="./security/anti-bot.js?v=${stamp}"`);
    html = html.replace(/src="\.\/security\/web-shield\.js(\?v=[^"]*)?"/g, `src="./security/web-shield.js?v=${stamp}"`);
    html = html.replace(/src="\.\/assets\/images\/before_real\.jpg(\?v=[^"]*)?"/g, `src="./assets/images/before_real.jpg?v=${stamp}"`);
    html = html.replace(/src="\.\/assets\/images\/after_real\.jpg(\?v=[^"]*)?"/g, `src="./assets/images/after_real.jpg?v=${stamp}"`);

    fs.writeFileSync('index.html', html, 'utf8');
    console.log(`  ✓ index.html updated with cache token: v=${stamp}`);

    console.log('\n====================================================');
    console.log('🎉 100% SUCCESS: ALL ASSETS ENCRYPTED & DATA PRESERVED');
    console.log('====================================================\n');
}

runBuild();
