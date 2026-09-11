const { downloadMediaMessage } = require("@whiskeysockets/baileys");
const config = require("../config");

/// Content types that carry downloadable media, mapped to the field that
/// holds their metadata inside `message.message`.
const MEDIA_TYPES = {
  imageMessage: "image",
  videoMessage: "video",
  audioMessage: "audio",
  documentMessage: "document",
  stickerMessage: "sticker"
};

/// Best-effort text out of whichever content type actually carries it. A
/// type this does not recognize still reaches the backend (as `type:
/// "unknown"` with the raw Baileys key), so a new message kind never
/// silently disappears — it just arrives without extracted text until this
/// list is extended.
function extractText(content) {
  if (!content) return null;

  return (
    content.conversation ??
    content.extendedTextMessage?.text ??
    content.imageMessage?.caption ??
    content.videoMessage?.caption ??
    content.documentMessage?.caption ??
    content.buttonsResponseMessage?.selectedDisplayText ??
    content.listResponseMessage?.singleSelectReply?.selectedRowId ??
    null
  );
}

function detectType(content) {
  if (!content) return "unknown";
  const [key] = Object.keys(content);
  if (MEDIA_TYPES[key]) return MEDIA_TYPES[key];
  if (key === "conversation" || key === "extendedTextMessage") return "text";
  if (key === "locationMessage") return "location";
  if (key === "contactMessage" || key === "contactsArrayMessage") return "contact";
  if (key === "buttonsResponseMessage" || key === "listResponseMessage") return "reply";
  return key || "unknown";
}

function jidToPhone(jid) {
  if (!jid) return null;
  return jid.split("@")[0].split(":")[0];
}

/// Turns one raw Baileys `WAMessage` into the flat shape sent both to the
/// backend (`message.received`) and to the control API (nothing today reads
/// it there, but the shape is the same on purpose: one message, one format,
/// regardless of who asks).
///
/// Media is inlined as base64 only up to `MEDIA_INLINE_MAX_BYTES`: anything
/// bigger travels as metadata only (mimetype, size, caption), so one large
/// video does not stall the backend link for every other message queued
/// behind it.
async function mapMessage(sock, waMessage, logger) {
  const content = waMessage.message;
  const type = detectType(content);

  const mapped = {
    id: waMessage.key?.id ?? null,
    // **The phone number, not the LID.** WhatsApp now addresses a one-to-one
    // chat by a "linked id" (`279688287117520@lid`) that hides the number, and
    // hands the real one alongside it in `senderPn` — which is the identity
    // everything downstream is keyed by: the backend opens a conversation per
    // number, a person reading a chat expects a number, and an answer is
    // addressed by what came in here. Falling back to the LID keeps a contact
    // WhatsApp gives no number for answerable rather than invisible, which is
    // also why `chat` below is kept: it is the only thing that can address one.
    from: jidToPhone(waMessage.key?.senderPn || waMessage.key?.remoteJid),
    // The address as WhatsApp writes it, kept because the suffix is the only
    // thing that tells a person (`@s.whatsapp.net` or `@lid`) from a group, a
    // status broadcast or a newsletter — and `from`, being digits, cannot: a
    // group's id reduces to digits just as convincingly as a phone number does.
    chat: waMessage.key?.remoteJid ?? null,
    fromMe: Boolean(waMessage.key?.fromMe),
    pushName: waMessage.pushName ?? null,
    timestamp: Number(waMessage.messageTimestamp) || Math.floor(Date.now() / 1000),
    type,
    text: extractText(content),
    media: null
  };

  const mediaField = MEDIA_TYPES[Object.keys(content ?? {})[0]];
  if (mediaField) {
    const info = content[Object.keys(content)[0]];
    mapped.media = {
      mimetype: info?.mimetype ?? null,
      fileName: info?.fileName ?? null,
      sizeBytes: info?.fileLength ? Number(info.fileLength) : null,
      base64: null
    };

    const withinLimit =
      !mapped.media.sizeBytes || mapped.media.sizeBytes <= config.mediaInlineMaxBytes;

    if (withinLimit) {
      try {
        const buffer = await downloadMediaMessage(
          waMessage,
          "buffer",
          {},
          { logger, reuploadRequest: sock.updateMediaMessage }
        );

        if (buffer.length <= config.mediaInlineMaxBytes) {
          mapped.media.base64 = buffer.toString("base64");
          mapped.media.sizeBytes = buffer.length;
        }
      } catch (error) {
        logger.warn({ err: error, messageId: mapped.id }, "Media download failed");
      }
    }
  }

  return mapped;
}

module.exports = { mapMessage };
