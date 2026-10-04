const puppeteer = require('puppeteer');
require('dotenv').config();

async function testBrowser() {
  const clientId = process.env.CASHFREE_CLIENT_ID;
  const clientSecret = process.env.CASHFREE_CLIENT_SECRET;
  const apiVersion = process.env.CASHFREE_API_VERSION || '2025-01-01';

  const orderId = 'order_' + Date.now() + '_' + Math.random().toString(36).substring(2, 7);
  const payload = {
    order_id: orderId,
    order_amount: 93.00,
    order_currency: 'INR',
    customer_details: {
      customer_id: 'cust_PES1UG24CA003',
      customer_name: 'Student 003',
      customer_email: 'student003@campuseats.internal',
      customer_phone: '9999999999'
    },
    order_meta: {
      return_url: 'http://localhost:5000/api/payments/cashfree-return?order_id={order_id}'
    },
    order_note: 'CampusEATS Order'
  };

  const response = await fetch('https://sandbox.cashfree.com/pg/orders', {
    method: 'POST',
    headers: {
      'x-client-id': clientId,
      'x-client-secret': clientSecret,
      'x-api-version': apiVersion,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(payload)
  });

  const data = await response.json();
  console.log('Created order:', data.order_id);
  console.log('payment_session_id:', data.payment_session_id);

  const browser = await puppeteer.launch({ headless: 'new' });
  const page = await browser.newPage();
  
  page.on('console', msg => console.log('BROWSER LOG:', msg.text()));
  page.on('pageerror', err => console.log('BROWSER ERROR:', err.message));
  page.on('requestfailed', req => console.log('REQUEST FAILED:', req.url(), req.failure()?.errorText));

  const htmlContent = `
    <!DOCTYPE html>
    <html>
      <head>
        <script src="https://sdk.cashfree.com/js/v3/cashfree.js"></script>
      </head>
      <body>
        <h1>Testing Cashfree</h1>
        <button id="pay-btn">Pay</button>
        <script>
          const cashfree = Cashfree({ mode: "sandbox" });
          document.getElementById('pay-btn').addEventListener('click', () => {
            cashfree.checkout({
              paymentSessionId: "${data.payment_session_id}",
              redirectTarget: "_modal"
            }).then(res => console.log('CHECKOUT RESULT:', JSON.stringify(res)));
          });
        </script>
      </body>
    </html>
  `;

  await page.setContent(htmlContent);
  await page.click('#pay-btn');
  await new Promise(r => setTimeout(r, 6000));
  
  const frames = page.frames();
  console.log('Total frames:', frames.length);
  for (const f of frames) {
    console.log('Frame URL:', f.url());
    try {
      const text = await f.evaluate(() => document.body.innerText);
      console.log('Frame text snippet:', text.substring(0, 300));
    } catch (e) {}
  }

  await browser.close();
}

testBrowser().catch(console.error);
