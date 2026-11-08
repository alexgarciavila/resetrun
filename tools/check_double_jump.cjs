// Physics, jump limits and pose anchors are checked by check_game.gd.
const assert = require('node:assert/strict');
const path = require('node:path');
const { createRequire } = require('node:module');
const { chromium } = createRequire(path.resolve(__dirname, '../.godot/web-test/package.json'))('playwright');

(async () => {
    const browser = await chromium.launch({ channel: 'msedge', headless: true });
    try {
        const page = await browser.newPage({ viewport: { width: 1100, height: 640 }, hasTouch: true });
        const errors = [];
        page.on('pageerror', error => errors.push(error.message));
        page.on('console', message => {
            if (/SCRIPT ERROR|Parse Error|^ERROR:/.test(message.text())) errors.push(message.text());
        });
        await page.goto(process.env.RESET_RUN_URL || 'http://127.0.0.1:8060/');
        await page.locator('#status').waitFor({ state: 'detached', timeout: 30000 });
        await page.mouse.click(270, 264);
        await page.keyboard.press('Space', { delay: 50 });
        await page.waitForTimeout(200);
        await page.screenshot({ path: '.godot/web-test/single-jump.png' });
        await page.keyboard.press('Space', { delay: 50 });
        await page.waitForTimeout(580);
        await page.screenshot({ path: '.godot/web-test/double-jump-upright.png' });
        await page.waitForTimeout(120);
        await page.screenshot({ path: '.godot/web-test/double-jump-descent.png' });
        await page.waitForTimeout(650);
        await page.keyboard.press('r', { delay: 50 });
        await page.mouse.click(270, 264);
        await page.touchscreen.tap(500, 330);
        await page.waitForTimeout(200);
        await page.touchscreen.tap(500, 330);
        await page.waitForTimeout(580);
        await page.screenshot({ path: '.godot/web-test/double-jump-touch.png' });
        assert.deepEqual(errors, [], 'Keyboard/touch double jump and the new atlas must load without errors');
        console.log('PASS: web keyboard/touch double jump, upright poses, transparent sprites and restart.');
    } finally {
        await browser.close();
    }
})().catch(error => { console.error(error); process.exitCode = 1; });
