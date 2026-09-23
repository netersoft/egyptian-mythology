// A term of the glossary (assets/glossary/glossary_<locale>.json). [aliases]
// are the exact forms the docs use for it ("vases canopes", "vase canope"),
// each linked on its first mention; [definition] may hold inline HTML.
class GlossaryEntry {
  final String id;
  final String term;
  final List<String> aliases;
  final String definition;

  const GlossaryEntry({required this.id, required this.term, required this.aliases, required this.definition});

  factory GlossaryEntry.fromJson(Map<String, dynamic> json) => GlossaryEntry(
    id: json['id'] as String,
    term: json['term'] as String,
    aliases: (json['aliases'] as List<dynamic>).cast<String>(),
    definition: json['definition'] as String,
  );
}
