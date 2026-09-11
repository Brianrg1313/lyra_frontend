import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/money/money_bot_model.dart';
import 'package:app/screens/home/sections/finance/money_format.dart';

/// What `POST /lyra/v1/money/ai` —what the bot costs— answers, and the two
/// things about it that a
/// screen can get wrong without anyone noticing.
///
/// The four areas are **disjoint and add up to the total**: that is the whole
/// point of the shape, and a card that draws a figure the backend nests one
/// level away —or counts the searches a reply ran inside the replies— shows a
/// total that is not the sum of its lines. And an answer that could not be read
/// must not become zeros: the backend refuses rather than claiming the company
/// spent nothing, and the parse has to keep that difference alive.
Map<String, dynamic> _response() => {
  "from": "2026-08-08T00:00:00.000Z",
  "to": "2026-09-07T12:00:00.000Z",
  "currency": "usd",
  "total": 1.5,
  "assistant": {
    "total": 1.1,
    "text": {
      "total": 0.9,
      "requests": 40,
      "inputTokens": 12000,
      "outputTokens": 3000,
      "cachedTokens": 800
    },
    "media": {"total": 0.15, "requests": 3},
    "research": {"total": 0.05, "requests": 1},
    "conversations": 12,
    "messages": 84
  },
  "tables": {"total": 0.25, "runs": 4},
  "vectors": {
    "total": 0.14,
    "requests": 30,
    "tokens": 9000,
    "catalog": {"total": 0.1, "requests": 20, "tokens": 7000},
    "queries": {"total": 0.04, "requests": 10, "tokens": 2000}
  },
  "other": {"total": 0.01},
  "tasks": [
    {
      "task": "normalizer",
      "name": "Normalizacion de tablas",
      "area": "tables",
      "kind": "text",
      "runs": 4,
      "inputTokens": 5000,
      "outputTokens": 900,
      "cost": 0.25
    }
  ]
};

void main() {
  test("the four areas are read apart and add up to the total", () {
    final spend = MoneyBotSpend.fromResponse(_response());

    expect(spend.isLoaded, isTrue);
    expect(spend.total, 1.5);
    expect(spend.answers.total, 1.1);
    expect(spend.tables.total, 0.25);
    expect(spend.vectors.total, 0.14);
    expect(spend.other, 0.01);

    final sum = spend.answers.total +
      spend.tables.total +
      spend.vectors.total +
      spend.other;

    expect(sum, closeTo(spend.total, 0.0001));
  });

  test("answering is split in three and its searches are not in it", () {
    final spend = MoneyBotSpend.fromResponse(_response());

    expect(spend.answers.text.total, 0.9);
    expect(spend.answers.media.total, 0.15);
    expect(spend.answers.research.total, 0.05);
    expect(spend.answers.text.inputTokens, 12000);
    expect(spend.answers.text.cachedTokens, 800);
    expect(spend.answers.conversations, 12);
    expect(spend.answers.messages, 84);

    // The embeddings a conversation paid for are one card down, under the
    // vectors: a figure that appeared in both would be two cards disagreeing.
    expect(spend.vectors.queries.total, 0.04);
    expect(
      spend.answers.text.total +
        spend.answers.media.total +
        spend.answers.research.total,
      closeTo(spend.answers.total, 0.0001)
    );
  });

  test("the tables line counts runs, which is what the backend calls it", () {
    final spend = MoneyBotSpend.fromResponse(_response());

    expect(spend.tables.count, 4);
    expect(spend.vectors.catalog.count, 20);
    expect(spend.vectors.queries.count, 10);
  });

  test("the currency travels with the figures and is never assumed", () {
    final spend = MoneyBotSpend.fromResponse(_response());

    // Upper-cased because that is how the catalog is keyed; it is USD and not
    // the company's currency, which is why it is read at all.
    expect(spend.currency, "USD");
    expect(spend.from, DateTime.utc(2026, 8, 8));
  });

  test("an answer that was not understood is not a spend of zero", () {
    // The backend declines (503) when it could not measure, so that nothing
    // claims the company spent nothing. Anything that is not an object has to
    // reach the service as "not loaded" and become an error there.
    expect(MoneyBotSpend.fromResponse(null).isLoaded, isFalse);
    expect(MoneyBotSpend.fromResponse("boom").isLoaded, isFalse);

    // A measured zero is the other case: it is an answer, and it is drawn as a
    // sentence rather than as an error.
    final quiet = MoneyBotSpend.fromResponse({"currency": "USD", "total": 0});

    expect(quiet.isLoaded, isTrue);
    expect(quiet.isEmpty, isTrue);
  });

  test("a spend under a cent is written as a figure and not as zero", () {
    // The bot is billed per token: a quiet week is fractions of a cent, and the
    // section's own two-decimal format would report it as nothing.
    expect(moneyFineLabel(0.0004, "USD"), contains("0.0004"));
    expect(moneyFineLabel(0.0004, "USD"), isNot(contains("0.00 ")));

    // Above a cent it is written like every other figure of the section, so the
    // two agree wherever both can be read.
    expect(moneyFineLabel(1.5, "USD"), moneyLabel(1.5, "USD"));
    expect(moneyFineLabel(0, "USD"), moneyLabel(0, "USD"));
  });
}
