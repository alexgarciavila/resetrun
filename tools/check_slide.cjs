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
        await page.evaluate(() => {
            window.slideContextMenus = [];
            document.addEventListener('contextmenu', event => window.slideContextMenus.push(event.defaultPrevented));
        });
        for (const key of ['ArrowDown', 'Control']) {
            await page.keyboard.press('r', { delay: 50 });
            await page.mouse.click(270, 264);
            await page.keyboard.down(key);
            await page.waitForTimeout(650);
            await page.screenshot({ path: `.godot/web-test/slide-${key}.png` });
            await page.keyboard.up(key);
            await page.waitForTimeout(350);
            await page.screenshot({ path: `.godot/web-test/slide-released-${key}.png` });
        }
        await page.keyboard.press('r', { delay: 50 });
        await page.mouse.click(270, 264);
        await page.mouse.move(500, 330);
        await page.mouse.down({ button: 'right' });
        await page.waitForTimeout(650);
        await page.screenshot({ path: '.godot/web-test/slide-right-mouse.png' });
        await page.mouse.up({ button: 'right' });
        await page.waitForTimeout(350);
        assert.ok(await page.evaluate(() => window.slideContextMenus.length > 0 && window.slideContextMenus.every(Boolean)), 'Right mouse must not open the browser context menu');
        await page.keyboard.down('ArrowDown');
        await page.waitForTimeout(100);
        await page.keyboard.press('Space', { delay: 50 });
        await page.waitForTimeout(150);
        await page.screenshot({ path: '.godot/web-test/slide-interrupted-by-jump.png' });
        await page.keyboard.up('ArrowDown');
        assert.deepEqual(errors, [], 'Slide controls, atlas and recovery must load without runtime errors');
        console.log('PASS: web Down/Ctrl/right mouse hold/release, context menu prevention, jump interruption and slide captures.');
    } finally {
        await browser.close();
    }
})().catch(error => { console.error(error); process.exitCode = 1; });
