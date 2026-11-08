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
        await page.keyboard.press('F3');
        await page.waitForTimeout(2000);
        const timings = await page.evaluate(() => new Promise(resolve => {
            const intervals = [];
            let previous;
            const sample = now => {
                if (previous !== undefined) intervals.push(now - previous);
                previous = now;
                if (intervals.length < 240) requestAnimationFrame(sample);
                else resolve(intervals);
            };
            requestAnimationFrame(sample);
        }));
        await page.screenshot({ path: '.godot/web-test/fps.png' });
        const sorted = [...timings].sort((a, b) => a - b);
        const mean = timings.reduce((sum, value) => sum + value, 0) / timings.length;
        console.log(JSON.stringify({ browser_fps: +(1000 / mean).toFixed(1), mean_ms: +mean.toFixed(2), p95_ms: +sorted[Math.floor(sorted.length * 0.95)].toFixed(2), max_ms: +sorted.at(-1).toFixed(2), frames_over_25ms: timings.filter(value => value > 25).length }));
        assert.deepEqual(errors, [], 'Interpolated web gameplay must have no runtime errors');
        console.log('PASS: frame timing sample and F3 diagnostic capture (headless timing is not a physical display benchmark).');
    } finally {
        await browser.close();
    }
})().catch(error => { console.error(error); process.exitCode = 1; });
