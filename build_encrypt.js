const fs = require('fs');
const path = require('path');
const vm = require('vm');
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

// Configuration optimized for heavy obfuscation, Chinese/Hex numbers,
// anti-tampering, debug protection, and 100% browser compatibility.
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
    disableConsoleOutput: false, // Keep normal console flow for any network logs
    renameGlobals: false, // Preserves global window APIs and DOM hooks
    transformObjectKeys: false, // Preserves DOM dataset and object properties
    target: 'browser'
};

console.log('\n[1/3] Encrypting and Obfuscating JavaScript Files...');
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

    // Ensure target directory exists
    const destDir = path.dirname(file.dest);
    if (!fs.existsSync(destDir)) fs.mkdirSync(destDir, { recursive: true });

    // Prepend security header
    const banner = '/* (C) RODRIGUEZ LAWNCARE - PROPRIETARY ENCRYPTED CLIENT ASSET. REVERSE ENGINEERING & DECOMPILATION PROHIBITED. */\n';
    fs.writeFileSync(file.dest, banner + encryptedCode, 'utf8');

    console.log(`  ✓ ${file.dest.padEnd(26)}: ${raw.length.toString().padStart(6)}b -> ${encryptedCode.length.toString().padStart(7)}b encrypted in ${duration}ms`);
}

console.log('\n[2/3] Minifying and Compressing CSS Stylesheets...');
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

    const banner = '/* (C) RODRIGUEZ LAWNCARE - PROTECTED STYLESHEET */\n';
    fs.writeFileSync(file.dest, banner + minified, 'utf8');
    console.log(`  ✓ ${file.dest.padEnd(26)}: ${raw.length.toString().padStart(6)}b -> ${minified.length.toString().padStart(7)}b compressed`);
}

console.log('\n[3/3] Updating index.html Cache-Busting Tokens...');
let html = fs.readFileSync('index.html', 'utf8');
const stamp = '5.0.sec_' + Date.now().toString(36);

html = html.replace(/href="\.\/css\/styles\.css(\?v=[^"]*)?"/g, `href="./css/styles.css?v=${stamp}"`);
html = html.replace(/href="\.\/security\/security\.css(\?v=[^"]*)?"/g, `href="./security/security.css?v=${stamp}"`);
html = html.replace(/src="\.\/js\/main\.js(\?v=[^"]*)?"/g, `src="./js/main.js?v=${stamp}"`);
html = html.replace(/src="\.\/js\/gallery\.js(\?v=[^"]*)?"/g, `src="./js/gallery.js?v=${stamp}"`);
html = html.replace(/src="\.\/js\/satellite-scanner\.js(\?v=[^"]*)?"/g, `src="./js/satellite-scanner.js?v=${stamp}"`);
html = html.replace(/src="\.\/js\/ai-assistant\.js(\?v=[^"]*)?"/g, `src="./js/ai-assistant.js?v=${stamp}"`);
html = html.replace(/src="\.\/security\/anti-bot\.js(\?v=[^"]*)?"/g, `src="./security/anti-bot.js?v=${stamp}"`);
html = html.replace(/src="\.\/security\/web-shield\.js(\?v=[^"]*)?"/g, `src="./security/web-shield.js?v=${stamp}"`);

fs.writeFileSync('index.html', html, 'utf8');
console.log(`  ✓ index.html updated with cache token: v=${stamp}`);

console.log('\n====================================================');
console.log('🎉 100% SUCCESS: ALL ASSETS ENCRYPTED AND DEPLOYABLE');
console.log('====================================================\n');
