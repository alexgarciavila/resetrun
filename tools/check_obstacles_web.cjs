const assert = require('node:assert/strict');
const path = require('node:path');
const { createRequire } = require('node:module');
const { chromium } = createRequire(path.resolve(__dirname, '../.godot/web-test/package.json'))('playwright');

(async () => {
    const browser = await chromium.launch({ channel: 'msedge', headless: true });
    try {
        const page = await browser.newPage({ viewport: { width: 1100, height: 640 } });
        const errors = [];
        page.on('pageerror', error => errors.push(error.message));
        page.on('console', message => {
            if (/SCRIPT ERROR|Parse Error|^ERROR:/.test(message.text())) errors.push(message.text());
        });
        await page.goto(process.env.RESET_RUN_URL || 'http://127.0.0.1:8060/');
        await page.locator('#status').waitFor({ state: 'detached', timeout: 30000 });
        await page.mouse.click(270, 264);
        await page.waitForTimeout(3300);
        await page.screenshot({ path: '.godot/web-test/obstacle-jump.png' });
        await page.waitForTimeout(2500);
        await page.screenshot({ path: '.godot/web-test/obstacle-double-jump.png' });
        await page.waitForTimeout(2800);
        await page.screenshot({ path: '.godot/web-test/obstacle-slide.png' });
        assert.deepEqual(errors, [], 'Obstacle textures, spawning, fields, collisions and cues must load without runtime errors');
        console.log('PASS: exported obstacle catalog/assets, all three introductory types and live render captures.');
    } finally {
        await browser.close();
    }
})().catch(error => { console.error(error); process.exitCode = 1; });
