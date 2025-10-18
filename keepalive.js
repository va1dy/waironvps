const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

const cookiesPath = path.resolve(__dirname, 'cookies.json');
const newCookiesPath = path.resolve(__dirname, 'new_cookies.json');

const urls = [
    'link1',
    'link2'
];

function logEvent(code, message) {
    const time = new Date().toLocaleTimeString();
    console.log(`[${time}] [CODE:${code}] ${message}`);
}

function getRandomDelay() {
    const delay = Math.floor(Math.random() * (40 - 6 + 1)) + 6;
    logEvent('TIME', `Случайная задержка: ${delay} сек.`);
    return delay * 1000;
}

async function openPages() {
    let cookies = [];

    // Загружаем старые cookies
    if (fs.existsSync(cookiesPath)) {
        try {
            cookies = JSON.parse(fs.readFileSync(cookiesPath, 'utf8'));
            logEvent(200, `Cookies успешно загружены (${cookies.length} шт.)`);
        } catch (err) {
            logEvent(500, 'Ошибка при чтении cookies.json: ' + err.message);
        }
    } else {
        logEvent(404, 'Файл cookies.json не найден — вход может потребоваться вручную.');
    }

    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const pages = await Promise.all(urls.map(async (url) => {
        const page = await browser.newPage();

        if (cookies.length > 0) {
            await page.setCookie(...cookies);
        }

        logEvent('TG', `Открытие страницы: ${url}`);

        // Ловим все запросы
        page.on('requestfinished', (req) => {
            logEvent('HTTP', `GET ${req.response()?.status()} → ${req.url()}`);
        });
        page.on('requestfailed', (req) => {
            logEvent('FAIL', `Запрос не удался: ${req.url()} (${req.failure()?.errorText})`);
        });

        await page.goto(url, { waitUntil: 'load', timeout: 60000 });
        logEvent('OK', `Страница ${url} успешно загружена.`);

        // Сохраняем новые cookies после загрузки
        const newCookies = await page.cookies();
        fs.writeFileSync(newCookiesPath, JSON.stringify(newCookies, null, 2));
        logEvent(201, `Новые cookies сохранены → ${newCookiesPath} (${newCookies.length} шт.)`);

        return page;
    }));

    const stayTime = 10000;
    logEvent(202, `Держим страницы открытыми ${stayTime / 1000} сек...`);
    await new Promise(resolve => setTimeout(resolve, stayTime));

    await Promise.all(pages.map(page => page.close()));
    await browser.close();
    logEvent(203, 'Все страницы и браузер закрыты.');

    const waitTime = getRandomDelay();
    logEvent(204, `Ждём ${waitTime / 1000} сек перед новым циклом...`);
    await new Promise(resolve => setTimeout(resolve, waitTime));

    logEvent('TG', 'Перезапуск цикла...');
    openPages();
}

logEvent('INIT', 'Запуск скрипта keepAlive...');
openPages();
