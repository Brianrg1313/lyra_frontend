# Module: messages section

**Path** `lib/screens/home/sections/messages`
**Role** Conversation desk: the chats the assistant holds with customers (WhatsApp). Two panels,
1/3 inbox + 2/3 open chat. Content of the `messages` home section.
**Services** `ChatsService`, `ChatThreadService` (`lib/services/chats`) — created by this section, not app-wide.
**Backend** `/aries/v1` through the `aries` client (`lib/toolkit/backend/api.dart`). Contract:
`E:/andromeda/backend/projects/lyra/docs/guides/aries-chat-desk.md`.

## Invariants

- **The open chat is state, not a URL** (`ChatsService.selected`): one route, no `:id`. The right
  panel is keyed by chat id, so each chat gets a fresh `ChatThreadService`.
- **Nothing is measured here**: stage, tags, attention, answered come from the backend or its events.
- **Tags are a set, replaced whole** (`chat/tags`). A row carries codes only, named by the catalog
  (`ChatsService.tagOf`); the detail and the event carry names, `since` and `tickets`.
- **Dedupe by message id**: a send answer and its `chat/message` echo are the same message.
- A send can land on **another chat id** (expired session): `ChatsService.moved` switches to it.
- A pause with `until` expires without an event: always read `ChatBot.isPausedAt(now)`.
- Header search (`HomeService.searchQuery`) travels as `SEARCH`, debounced.
- Events are fire-and-forget: `ConnectionService.onRestored` rereads list, summary and open chat.

## Files

- `_messages.dart` — `MessagesSection`: creates/provides `ChatsService`, loads it, forwards header search; `Row` of `InboxPanel` (flex 1) and `_OpenChat` (flex 2).
  Also reads the app-wide `ChannelsService`: none → `MessagesStart` instead of the desk (kept through the reads that follow; a failed read keeps the desk).
- `start/_start.dart` — `MessagesStart`: no channel yet; the desk's two panels with networks in place of chats: `ChannelPreset` rows (ready first, "soon" disabled, a blank one) left, the picked one's preview right (stacked when narrow);
  connecting opens `showCreateChannel`; a WhatsApp Personal one goes on to its QR (`linkBaileysChannel`) **before** the channels reload, which swaps this page for the desk.
- `start/preset_row.dart` — `PresetRow`: a network in the list (mark, name, what it takes). `start/preset_preview.dart` — `PresetPreview`: what it takes, a sample exchange in the chat's bubbles, its tools, connect.
- `chat_format.dart` — `chatTimeLabel`, `chatDateLabel`, `chatWaitLabel`.
- `tags/chat_stage_tag.dart` — `ChatStageTag`. `tags/chat_stage_color.dart` — `chatStageColor` (same hues as `saleStageColor` for shared codes; `paid` = the board's handover hue), `chatWaitingColor`.
- `tags/chat_tags.dart` — `ChatTags` (wrap). `tags/chat_tag_chip.dart` — `ChatTagChip` (bold = work for a person; tooltip since + tickets).
- `tags/chat_tag_color.dart` — `chatTagsBeside` (drops the tag that repeats the stage), `chatTagColor` (stage hue for shared meanings, else level).
- `inbox/_inbox.dart` — `InboxPanel`: title + count, filters, pending banner, list. `inbox/inbox_list.dart` — `InboxList`: paged list (auto "more" near the end).
- `inbox/inbox_filters.dart` — `InboxFilters` (chips per `ChatsFilter` with summary counts), `inboxFilterTitle`. `inbox/inbox_filter_chip.dart` — `InboxFilterChip`.
- `inbox/inbox_tile.dart` — `InboxTile`: avatar, name, last activity, stage + tag chips, attention (only when no tag names it)/paused/unanswered marks.
  `unseen` (customer wrote since this person opened it, `chats.unread`): bold name, time and `UnseenMark` in the side bar number's red,
  in place of the unanswered dot.
- `chat/_chat.dart` — `ChatPanel({id})`: owns `ChatThreadService`; header, attention bar, messages, composer.
- `chat/chat_header.dart` — `ChatHeader`: identity + stage, tags, take over (duration menu) / return to assistant, assign (`ChatThreadService.assignable`: who may take this chat, read on each open; a `desk_member_branch` refusal is its flag), options menu (mark read, approve the payment → `showApprovePayment` (`paid`, «Por cerrar»; a short amount allowed), close the sale (`sold`, confirmed; approves too when it was not), ended, undo (close first, then the approval), AI cost → `showChatUsage`, earlier sessions); `widgets/chat_bot_line.dart` — `ChatBotLine`: who answers + assignee; `widgets/chat_handover_button.dart` — `ChatHandoverButton`.
- `chat/chat_attention.dart` — `ChatAttentionBar`, `chatAttentionTitle`: most urgent mark, team-only detail, resolve button for `pending`; a `question` mark lists its questions, each with its answer box.
- `chat/chat_question.dart` — `ChatQuestionAnswer`: one question the assistant left with the team and the box a person answers it in — the answer goes to the assistant (`ChatThreadService.answer`, `QUESTION_ID` + `ANSWER`), which tells the customer at once in its own words, without pausing it; the flag says now · when given back · session over (`ChatRelay`).
- `chat/message_list.dart` — `MessageList`: reversed `ListView`, loads older (`BEFORE`) near the top, groups runs by author.
- `chat/message_bubble.dart` — `MessageBubble`: side by direction, fill by author, image (`FileModel` → `showImageViewer`), audio mark, ticks/queued/failed.
- `chat/chat_composer.dart` — `ChatComposer`: `Input` + send (Enter sends); hint that replying pauses the assistant.
