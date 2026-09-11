import 'money_summary_model.dart';

/// One line of what Lyra costs: how much it was and how much work it was.
///
/// The five lines the backend reports —the text of a reply, the images and
/// voice notes it read, the web lookups, the catalog's vectors and the searches
/// run against them— carry different counters, and this is one class for all of
/// them because the screen asks the same two questions of each: how much, and
/// out of how much use. A line reports the counters it has and zero for the
/// ones its kind does not measure (a media call has no token count of its own).
class MoneyBotLine {
  const MoneyBotLine({
    this.total = 0,
    this.count = 0,
    this.tokens = 0,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cachedTokens = 0
  });

  /// What it cost, in the currency of the block (US dollars).
  final double total;

  /// How many calls it took. The backend names it `requests` everywhere except
  /// on the tables line, where it is `runs`, which is what [key] is for.
  final int count;

  final int tokens;
  final int inputTokens;
  final int outputTokens;
  final int cachedTokens;

  factory MoneyBotLine.fromJson(dynamic data, {String key = "requests"}) =>
    data is Map
      ? MoneyBotLine(
          total: moneyDouble(data["total"]),
          count: moneyInt(data[key]),
          tokens: moneyInt(data["tokens"]),
          inputTokens: moneyInt(data["inputTokens"]),
          outputTokens: moneyInt(data["outputTokens"]),
          cachedTokens: moneyInt(data["cachedTokens"])
        )
      : const MoneyBotLine();
}

/// What answering customers cost: writing the reply, reading what was sent in
/// —a photo, a voice note— and looking something up on the web.
///
/// The searches those replies ran are **not** here — they are under
/// [MoneyBotSpend.vectors], because vectorizing is one of the lines this block
/// exists to separate and a figure drawn in two places is two places that
/// disagree.
class MoneyBotAnswers {
  const MoneyBotAnswers({
    this.total = 0,
    this.text = const MoneyBotLine(),
    this.media = const MoneyBotLine(),
    this.research = const MoneyBotLine(),
    this.conversations = 0,
    this.messages = 0
  });

  final double total;
  final MoneyBotLine text;
  final MoneyBotLine media;
  final MoneyBotLine research;

  /// Chat sessions billed in the window, and the replies produced in them.
  /// They are what the cost is read against: a month that doubles in money and
  /// in conversations is a company that grew, one that doubles in money alone
  /// is a question for somebody.
  final int conversations;
  final int messages;

  factory MoneyBotAnswers.fromJson(dynamic data) => data is Map
    ? MoneyBotAnswers(
        total: moneyDouble(data["total"]),
        text: MoneyBotLine.fromJson(data["text"]),
        media: MoneyBotLine.fromJson(data["media"]),
        research: MoneyBotLine.fromJson(data["research"]),
        conversations: moneyInt(data["conversations"]),
        messages: moneyInt(data["messages"])
      )
    : const MoneyBotAnswers();
}

/// What turning text into vectors cost: the company's records when they were
/// imported, and every search a conversation ran against them.
class MoneyBotVectors {
  const MoneyBotVectors({
    this.total = 0,
    this.catalog = const MoneyBotLine(),
    this.queries = const MoneyBotLine()
  });

  final double total;

  /// Indexing the company's own records.
  final MoneyBotLine catalog;

  /// The searches Lyra ran while it was answering.
  final MoneyBotLine queries;

  factory MoneyBotVectors.fromJson(dynamic data) => data is Map
    ? MoneyBotVectors(
        total: moneyDouble(data["total"]),
        catalog: MoneyBotLine.fromJson(data["catalog"]),
        queries: MoneyBotLine.fromJson(data["queries"])
      )
    : const MoneyBotVectors();
}

/// **What Lyra costs the company**, over a window of its own.
///
/// Lyra is the bot that answers the company's customers on its channels, and
/// this is what running it is billed at: what it wrote, what it read, what it
/// looked up, and what preparing the company's own data for it cost. It is not
/// a bill for a product and it is not "the AI" as a line item — it is the work
/// this company's bot did, which is why the areas are the work and not the
/// providers.
///
/// The endpoint is `POST /money/ai`, which is the backend's name for it.
///
/// It is not an expense of the money screen: nobody recorded a payment for it,
/// it is measured from the provider's own counters, and it is in **US dollars**
/// while the rest of the section is in the company's currency — which is why
/// [currency] travels with it and why nothing here is ever added to a figure of
/// [MoneySummary].
///
/// **The four areas are disjoint and they add up to [total] exactly.** That is
/// the property the shape is built for: four lines and a total that is not
/// their sum is a figure nobody trusts twice. [other] is spend the backend
/// could not attribute to an area — it is reported rather than dropped, because
/// somebody is being charged for it.
///
/// The endpoint also answers a per-task cut of the same money (`tasks`). It is
/// not read here: it is the same dollars sliced another way, and a second list
/// of figures that does not add up to the total is what this shape exists to
/// avoid.
class MoneyBotSpend {
  const MoneyBotSpend({
    this.from,
    this.to,
    this.currency = "",
    this.total = 0,
    this.answers = const MoneyBotAnswers(),
    this.tables = const MoneyBotLine(),
    this.vectors = const MoneyBotVectors(),
    this.other = 0,
    this.isLoaded = false
  });

  /// The window the backend answered about, which is not always the one asked
  /// for: a range is resolved against the server's day.
  final DateTime? from;
  final DateTime? to;

  /// Always `USD` today. It is read and drawn anyway: the day a provider bills
  /// in something else, the figure must not be written with the wrong symbol.
  final String currency;

  final double total;

  /// Lyra answering customers. The backend calls this block `assistant`; here
  /// it is named after what it is, which is the bot doing its job.
  final MoneyBotAnswers answers;

  /// Making sense of an imported spreadsheet. Its counter is `runs`.
  final MoneyBotLine tables;

  final MoneyBotVectors vectors;

  /// Spend of no known area. Shown when there is any, never hidden.
  final double other;

  /// Whether this is an answer and not the empty spend the service starts with.
  final bool isLoaded;

  /// Whether the company spent nothing in the window. It is a real reading —the
  /// backend refuses rather than answering zeros when it could not measure— so
  /// it is drawn as a sentence and not as a wall of noughts.
  bool get isEmpty => total == 0;

  factory MoneyBotSpend.fromResponse(dynamic data) {
    if (data is! Map) return const MoneyBotSpend();

    final other = data["other"];

    return MoneyBotSpend(
      from: moneyDate(data["from"]),
      to: moneyDate(data["to"]),
      currency: (data["currency"] ?? "").toString().toUpperCase(),
      total: moneyDouble(data["total"]),
      answers: MoneyBotAnswers.fromJson(data["assistant"]),
      tables: MoneyBotLine.fromJson(data["tables"], key: "runs"),
      vectors: MoneyBotVectors.fromJson(data["vectors"]),
      other: other is Map ? moneyDouble(other["total"]) : 0,
      isLoaded: true
    );
  }
}
