// Kilometer-boundary logic is covered by check_game.gd; this checks the web UI.
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
        await page.waitForTimeout(200);
        const header = { x: 25, y: 20, width: 1000, height: 65 };
        const footer = { x: 25, y: 578, width: 1050, height: 28 };
        const fixedHud = await page.screenshot({ clip: header });
        await page.mouse.click(670, 199); // Endless mode.
        await page.waitForTimeout(100);
        const endlessHud = await page.screenshot({ clip: header });
        const endlessFooter = await page.screenshot({ clip: footer });
        assert.notDeepEqual(endlessHud, fixedHud, 'Endless must change the mode and next-world HUD');
        await page.screenshot({ path: '.godot/web-test/endless-menu.png' });
        await page.waitForTimeout(1500);
        await page.reload();
        await page.locator('#status').waitFor({ state: 'detached', timeout: 30000 });
        await page.waitForTimeout(200);
        assert.deepEqual(await page.screenshot({ clip: header }), endlessHud, 'Endless selection must survive reload');
        assert.deepEqual(await page.screenshot({ clip: footer }), endlessFooter, 'The mode/world/countdown footer must survive reload');
        await page.mouse.click(270, 264); // Start.
        await page.waitForTimeout(400);
        assert.notDeepEqual(await page.screenshot({ clip: header }), endlessHud, 'Distance and next-world counter must advance');
        assert.notDeepEqual(await page.screenshot({ clip: footer }), endlessFooter, 'The next-world counter must advance in the footer');
        await page.screenshot({ path: '.godot/web-test/endless-running.png' });
        await page.keyboard.press('r', { delay: 50 });
        await page.waitForTimeout(150);
        assert.deepEqual(await page.screenshot({ clip: header }), endlessHud, 'Restart must restore the first segment');
        assert.deepEqual(await page.screenshot({ clip: footer }), endlessFooter, 'Restart must restore the footer countdown');
        await page.mouse.click(420, 199); // Fixed world mode.
        await page.waitForTimeout(100);
        assert.deepEqual(await page.screenshot({ clip: header }), fixedHud, 'Fixed mode must remain available');
        assert.deepEqual(errors, [], 'Mode selection and gameplay must not emit errors');
        console.log('PASS: web Endless selection, persistence, progress HUD, restart and fixed mode.');
    } finally {
        await browser.close();
    }
})().catch(error => { console.error(error); process.exitCode = 1; });
