# Module: knowledge section

**Path** `lib/screens/home/sections/knowledge`
**Role** Frequent questions: what Lyra knows to answer when a customer asks how the business works, and the
questions customers asked that nobody answered yet. Content of the `knowledge` home section (cloud only).
**Services** `KnowledgeService`, `KnowledgeProductSearch` (`lib/services/knowledge`); `BusinessBranchesService`
for the branch picker. All created by this section, not app-wide.
**Backend** `/lyra/v1/knowledge` (`lib/models/knowledge/MODULE.md` in the backend).

## Invariants

- **An empty answer is the pending state.** Lyra never uses a question without its context; the backend computes
  `state` (`pending · off · scheduled · expired · active`) against the company's day — never derive it here.
- Questions Lyra leaves come from `ask_team` (a promise delivered to a customer); a repeat lands on the same row
  (`asks`). The open chat is not a URL, so a question does not link its conversation yet.
- Branch and products **scope** an answer (Lyra says it as theirs); the dates **filter** it. Spots, hours and
  deadlines are text inside the context (`KnowledgeSnippets`).
- The form is a modal above the section's providers: it returns a `KnowledgeDraft`, `openKnowledgeForm` writes.

## Files

- `_knowledge.dart` — `KnowledgeSection`: creates and provides `KnowledgeService`, `BusinessBranchesService`, `KnowledgeView`.
- `knowledge_page.dart` — `KnowledgePage`: bar (title, subtitle, "New question") + body.
- `knowledge_body.dart` — `KnowledgeBody`: the only listener of the service (loading, error, empty, list).
- `knowledge_pending_banner.dart` — `KnowledgePendingBanner`: how many wait for a context, "Show them".
- `knowledge_filters.dart` — `KnowledgeFilters`: state chips with counts (inside the branch), branch menu when there is a choice.
- `knowledge_list.dart` — `KnowledgeList` (filter + header search) and `sortKnowledge` (pending first, most asked on top).
- `knowledge_row.dart` — `KnowledgeRow`: question, state, context or "no context", scope line; tap opens the form.
- `knowledge_state_tag.dart` — `KnowledgeStateTag`. `knowledge_options_button.dart` — `KnowledgeOptionsButton` (on/off, delete).
- `knowledge_actions.dart` — `openKnowledgeForm(context, entry?)`: opens the form and writes through the service.
- `knowledge_format.dart` — `knowledgeDay`: a `YYYY-MM-DD` day in the app's language.
- `state/knowledge_view.dart` — `KnowledgeView` (filter + branch), `KnowledgeFilter`.
