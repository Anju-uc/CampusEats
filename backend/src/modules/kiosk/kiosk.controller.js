const { generateKioskQR } = require("./kiosk.service");

async function getKioskChallenge(req, res, next) {
  try {
    const data = await generateKioskQR();
    return res.status(200).json({
      success: true,
      data,
    });
  } catch (error) {
    next(error);
  }
}

async function renderKioskPage(req, res, next) {
  try {
    const { qrDataUrl, expiresIn, campusId } = await generateKioskQR();
    const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>CampusEATS — Cafeteria Check-in Kiosk</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
    body { background: #0F172A; color: #F8FAFC; display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 100vh; padding: 20px; }
    .kiosk-card { background: #1E293B; border-radius: 24px; padding: 36px; max-width: 440px; width: 100%; text-align: center; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5); border: 1px solid #334155; }
    .badge { display: inline-block; background: #FF8A00; color: white; padding: 6px 14px; border-radius: 20px; font-weight: 700; font-size: 12px; letter-spacing: 0.5px; text-transform: uppercase; margin-bottom: 16px; }
    h1 { font-size: 24px; font-weight: 800; margin-bottom: 8px; color: #FFFFFF; }
    p { font-size: 14px; color: #94A3B8; margin-bottom: 24px; }
    .qr-container { background: white; padding: 18px; border-radius: 20px; display: inline-block; box-shadow: 0 10px 25px rgba(0,0,0,0.2); }
    .qr-container img { width: 260px; height: 260px; display: block; border-radius: 8px; }
    .timer { margin-top: 20px; font-size: 13px; color: #CBD5E1; font-weight: 600; }
    .footer { margin-top: 24px; font-size: 12px; color: #64748B; }
  </style>
</head>
<body>
  <div class="kiosk-card">
    <div class="badge">Cafeteria Zone Check-In</div>
    <h1>Scan to Verify Campus Access</h1>
    <p>Point your CampusEats scanner at this QR code to unlock ordering at <strong>${campusId}</strong>.</p>
    <div class="qr-container">
      <img id="qr-img" src="${qrDataUrl}" alt="Campus Check-in QR Code" />
    </div>
    <div class="timer">Refreshing in <span id="countdown">${expiresIn}</span>s...</div>
    <div class="footer">CampusEats Security • Single-use Cryptographic Challenge</div>
  </div>

  <script>
    let secondsLeft = ${expiresIn};
    const countdownEl = document.getElementById('countdown');
    const qrImgEl = document.getElementById('qr-img');

    async function refreshQR() {
      try {
        const res = await fetch('/api/kiosk/challenge');
        const json = await res.json();
        if (json.success && json.data) {
          qrImgEl.src = json.data.qrDataUrl;
          secondsLeft = json.data.expiresIn || 120;
        }
      } catch (err) {
        console.error('Failed to refresh QR', err);
      }
    }

    setInterval(() => {
      secondsLeft--;
      if (secondsLeft <= 0) {
        countdownEl.textContent = '0';
        refreshQR();
      } else {
        countdownEl.textContent = secondsLeft;
      }
    }, 1000);
  </script>
</body>
</html>
    `;
    res.setHeader("Content-Type", "text/html");
    return res.status(200).send(html);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getKioskChallenge,
  renderKioskPage,
};
