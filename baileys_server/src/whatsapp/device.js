const fs = require("fs");
const path = require("path");
const { Browsers } = require("@whiskeysockets/baileys");

/// The identity WhatsApp records for this linked device, shown in the phone's
/// "Linked devices" list. Baileys defaults to `Browsers.ubuntu("Chrome")`,
/// which is why an unconfigured session shows up as an Ubuntu machine; this
/// is a Windows desktop sidecar, so it says Windows.
///
/// The tuple is `[os, client, osVersion]`: WhatsApp displays `os`, and uses
/// `client` only to pick the device icon (an unknown value falls back to
/// `DeviceProps.PlatformType.DESKTOP` — see Baileys'
/// `Utils/validate-connection.js`), which is the icon we want anyway.
const DEVICE_BROWSER = Browsers.windows("Lyra");

/// Where the identity used at pairing time is remembered, next to (not
/// inside) the Baileys auth folder, so wiping auth never loses the record of
/// what that auth was paired as.
function deviceFile(authFolder) {
  return path.join(path.dirname(authFolder), "device.json");
}

/// Drops an auth folder that was paired under a different device identity.
///
/// The `os`/`client` pair is not a runtime setting: it travels in the
/// companion registration at QR-scan time and is frozen into the linked-device
/// entry on the phone. Editing [DEVICE_BROWSER] therefore does nothing to a
/// session that is already paired — it keeps reconnecting under the old
/// identity forever, which is exactly how a session ends up still reading
/// "Ubuntu" long after this file says Windows. Forcing a fresh QR is the only
/// way to apply it, so that is what happens here.
///
/// Returns `true` when the auth was wiped (the caller's next `start()` will
/// issue a QR).
function ensurePairedAsCurrentDevice(authFolder, logger) {
  const file = deviceFile(authFolder);
  const current = DEVICE_BROWSER.join("|");

  let stored = null;
  try {
    stored = JSON.parse(fs.readFileSync(file, "utf8")).browser ?? null;
  } catch {
    // No record yet: either a session that has never paired (nothing to
    // wipe, handled below) or one paired before this check existed, which
    // has to be treated as a mismatch since its identity is unknown.
  }

  if (stored === current) return false;

  const paired = fs.existsSync(path.join(authFolder, "creds.json"));

  if (paired) {
    logger.warn(
      { stored, current },
      "Linked device identity changed; wiping auth so a new QR re-pairs it"
    );
    fs.rmSync(authFolder, { recursive: true, force: true });
  }

  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify({ browser: current }, null, 2));

  return paired;
}

module.exports = { DEVICE_BROWSER, ensurePairedAsCurrentDevice };
