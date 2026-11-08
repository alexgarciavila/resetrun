// Run after exporting, with the local server active.
const assert = require('node:assert/strict');
const path = require('node:path');
const { createRequire } = require('node:module');
const { chromium } = createRequire(path.resolve(__dirname, '../.godot/web-test/package.json'))('playwright');
const worlds = ['datacenter', 'botiga', 'magatzem', 'magatzem2', 'oficina', 'taller', 'taller2', 'vendrell'];

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
        const signatures = new Set();
        for (let index = 0; index < worlds.length; index++) {
            await page.keyboard.press('m', { delay: 50 });
            await page.waitForTimeout(100);
            if (index === 4) await page.mouse.click(364, 526); // Next page.
            await page.mouse.click(index % 2 === 0 ? 350 : 730, index % 4 < 2 ? 220 : 390);
            await page.waitForTimeout(100);
            if (index === 0 || index === 4) {
                await page.screenshot({ path: `.godot/web-test/worlds-page-${index === 0 ? 1 : 2}.png` });
            }
            await page.mouse.click(650, 526); // Play the selected world.
            await page.waitForTimeout(150);
            await page.screenshot({ path: `.godot/web-test/world-${worlds[index]}.png` });
            const scenery = await page.screenshot({ clip: { x: 900, y: 150, width: 180, height: 250 } });
            signatures.add(scenery.toString('base64'));
            await page.keyboard.press('r', { delay: 50 });
            await page.waitForTimeout(100);
        }
        assert.equal(signatures.size, worlds.length, 'Every world must render its own background');
        const caption = { x: 30, y: 580, width: 1040, height: 24 };
        const selected = await page.screenshot({ clip: caption });
        await page.waitForTimeout(1500);
        await page.reload();
        await page.locator('#status').waitFor({ state: 'detached', timeout: 30000 });
        await page.waitForTimeout(300);
        assert.deepEqual(await page.screenshot({ clip: caption }), selected, 'Selected world must survive reload');
        assert.deepEqual(errors, [], 'All world assets and scripts must load without runtime errors');
        console.log('PASS: eight selectable worlds, both pages, distinct backgrounds, gameplay, reset and saved selection.');
    } finally {
        await browser.close();
    }
})().catch(error => { console.error(error); process.exitCode = 1; });
