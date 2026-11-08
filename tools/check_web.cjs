// Install once: npm install --prefix .godot/web-test playwright
// Run with the local server active: node tools/check_web.cjs
const assert = require('node:assert/strict');
const path = require('node:path');
const { createRequire } = require('node:module');
const { chromium } = createRequire(path.resolve(__dirname, '../.godot/web-test/package.json'))('playwright');

(async () => {
    const browser = await chromium.launch({ channel: 'msedge', headless: true });
    try {
        const page = await browser.newPage({ viewport: { width: 1100, height: 640 } });
        // Measure the real Web Audio output, rather than only checking mute flags.
        await page.addInitScript(() => {
            window.resetRunMeters = [];
            const connect = AudioNode.prototype.connect;
            AudioNode.prototype.connect = function (destination, ...args) {
                if (destination === this.context.destination) {
                    const meter = this.context.createAnalyser();
                    meter.fftSize = 2048;
                    connect.call(this, meter);
                    connect.call(meter, destination, ...args);
                    window.resetRunMeters.push(meter);
                    return destination;
                }
                return connect.call(this, destination, ...args);
            };
        });
        const audioLevel = () => page.evaluate(() => Math.max(0, ...window.resetRunMeters.map(meter => {
            const samples = new Float32Array(meter.fftSize);
            meter.getFloatTimeDomainData(samples);
            return Math.sqrt(samples.reduce((sum, sample) => sum + sample * sample, 0) / samples.length);
        })));
        const errors = [];
        page.on('pageerror', error => errors.push(error.message));
        page.on('console', message => {
            if (/SCRIPT ERROR|Parse Error|Failed to load script|^ERROR:/.test(message.text())) {
                errors.push(message.text());
            }
        });
        await page.goto(process.env.RESET_RUN_URL || 'http://127.0.0.1:8060/');
        await page.locator('#status').waitFor({ state: 'detached', timeout: 30000 });
        assert.equal(await page.locator('html').getAttribute('lang'), 'ca', 'Web document language must be Catalan');
        await page.waitForTimeout(500);
        assert.deepEqual(errors, [], 'Export must load without runtime errors');
        await page.screenshot({ path: '.godot/web-test/menu.png' });
        const startHud = { x: 160, y: 20, width: 620, height: 34 };
        const idleHud = await page.screenshot({ clip: startHud });
        await page.mouse.click(480, 264); // Main menu: Worlds.
        await page.waitForTimeout(100);
        await page.screenshot({ path: '.godot/web-test/worlds.png' });
        const modalTitle = { x: 150, y: 76, width: 790, height: 40 };
        const selectorTitle = await page.screenshot({ clip: modalTitle });
        await page.mouse.click(740, 250); // Select Botiga without starting gameplay.
        await page.keyboard.press('Space');
        await page.waitForTimeout(100);
        assert.deepEqual(await page.screenshot({ clip: modalTitle }), selectorTitle, 'World selection and modal keys must not start gameplay');
        await page.mouse.click(350, 300); // Select Datacenter, including its preview image.
        await page.keyboard.press('Escape');
        await page.waitForTimeout(100);
        assert.deepEqual(await page.screenshot({ clip: startHud }), idleHud, 'Returning from worlds must retain the idle game');
        await page.keyboard.press('m');
        await page.mouse.click(650, 514); // World selector: Play.
        await page.waitForTimeout(200);
        assert.notDeepEqual(await page.screenshot({ clip: startHud }), idleHud, 'World selector Play must launch Datacenter');
        await page.keyboard.press('r');
        await page.waitForTimeout(100);
        const backdrop = { x: 1030, y: 290, width: 40, height: 80 };
        const originalScenery = await page.screenshot({ clip: backdrop });
        await page.keyboard.press('o');
        await page.waitForTimeout(600);
        assert.ok(await audioLevel() > 0.001, 'Music must actually reach the browser audio output');
        // Interact with the exported canvas, including controls that must consume clicks.
        await page.mouse.click(400, 240); // Music volume.
        await page.mouse.click(800, 240); // Mute music.
        await page.waitForTimeout(150);
        assert.equal(await audioLevel(), 0, 'Muting music must silence its output');
        await page.mouse.click(710, 373); // Preview effect while music is muted.
        await page.waitForTimeout(25);
        assert.ok(await audioLevel() > 0.001, 'Effects must remain audible when music is muted');
        await page.mouse.click(470, 294); // Effects volume.
        await page.mouse.click(800, 294); // Mute effects.
        await page.waitForTimeout(150);
        await page.mouse.click(710, 373);
        await page.waitForTimeout(25);
        assert.equal(await audioLevel(), 0, 'Muted effects must produce no audio');
        await page.mouse.click(800, 240); // Unmute music before testing Master.
        await page.waitForTimeout(150);
        assert.ok(await audioLevel() > 0.001, 'Unmuting music must restore audio');
        await page.mouse.click(365, 373); // Master mute.
        await page.waitForTimeout(150);
        assert.equal(await audioLevel(), 0, 'Master mute must silence real browser output');
        await page.mouse.click(800, 240); // Save all three mute switches enabled.
        await page.keyboard.press('Escape');
        await page.waitForTimeout(100);
        assert.deepEqual(await page.screenshot({ clip: backdrop }), originalScenery, 'Sound settings must preserve original scenery colors');
        await page.keyboard.press('o');
        await page.waitForTimeout(100);
        const audioRegion = { x: 205, y: 220, width: 690, height: 180 };
        const savedAudio = await page.screenshot({ clip: audioRegion });
        await page.screenshot({ path: '.godot/web-test/options.png' });
        await page.waitForTimeout(1500); // Allow the browser filesystem to sync to IndexedDB.
        await page.reload();
        await page.locator('#status').waitFor({ state: 'detached', timeout: 30000 });
        await page.waitForTimeout(300);
        assert.deepEqual(await page.screenshot({ clip: backdrop }), originalScenery, 'Original scenery must remain after reload');
        await page.keyboard.press('o');
        await page.waitForTimeout(100);
        assert.deepEqual(await page.screenshot({ clip: audioRegion }), savedAudio, 'Volumes and all mute switches must survive reload');
        await page.mouse.click(365, 373); // Restore master audio.
        await page.mouse.click(800, 240); // Restore music.
        await page.mouse.click(800, 294); // Restore effects.
        await page.keyboard.press('Escape');
        await page.waitForTimeout(100);
        const hud = { x: 160, y: 20, width: 620, height: 34 };
        const initial = await page.screenshot({ clip: hud });
        await page.mouse.click(500, 320); // Click outside menu buttons to start.
        await page.waitForTimeout(300);
        assert.notDeepEqual(await page.screenshot({ clip: hud }), initial, 'Space must start the distance counter');
        await page.keyboard.press('Space');
        await page.waitForTimeout(200);
        await page.screenshot({ path: '.godot/web-test/jump.png' });
        await page.keyboard.press('r');
        await page.waitForTimeout(100);
        assert.deepEqual(await page.screenshot({ clip: hud }), initial, 'R must reset distance, speed and lives');
        await page.locator('canvas').click({ position: { x: 500, y: 350 } });
        await page.waitForTimeout(300);
        assert.notDeepEqual(await page.screenshot({ clip: hud }), initial, 'Click must also start the game');
        assert.deepEqual(errors, [], 'Gameplay must not emit runtime errors');
        console.log('PASS: original scenery, real music/effect audio and silence, volume/mute persistence, gameplay input, distance and restart.');
    } finally {
        await browser.close();
    }
})().catch(error => { console.error(error); process.exitCode = 1; });
