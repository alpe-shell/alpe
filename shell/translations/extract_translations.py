#!/usr/bin/env python3
"""Alpe: Texte der Oberfläche aus qsTr() und I18n.tr() herausziehen (Plan 0.8 Nr. 74).

    python3 shell/translations/extract_translations.py            en.json neu schreiben
    python3 shell/translations/extract_translations.py --pruefen  nichts schreiben: Ist en.json aktuell?
                                                                  Welche Texte haben keine deutsche Übersetzung?

en.json ist die Liste aller Quelltexte (englisch) der ganzen Oberfläche, auch von Alpe/. Deutsch steht
in poexports/de.json und, für die Bibliothek, in Alpe/translations/poexports/de.json – I18n.qml schlägt
in beiden nach, die Prüfung ebenso. Gepflegt werden die Dateien von Hand in diesem Repository; einen
Abgleich mit einem Übersetzungsdienst gibt es nicht. Plugins bringen ihre Texte selbst mit.
"""
import ast
import re
import json
import sys
from pathlib import Path
from collections import defaultdict


def decode_string_literal(content, quote):
    try:
        return ast.literal_eval(f"{quote}{content}{quote}")
    except (ValueError, SyntaxError):
        return content


def spans_overlap(a, b):
    return a[0] < b[1] and b[0] < a[1]


STR_DQ = r'"((?:\\.|[^"\\])*)"'
STR_SQ = r"'((?:\\.|[^'\\])*)'"


def call_patterns(func, arg_count, trailing_true=False):
    patterns = []
    for lit, quote in ((STR_DQ, '"'), (STR_SQ, "'")):
        args = r'\s*,\s*'.join([lit] * arg_count)
        tail = r'\s*,\s*true\s*\)' if trailing_true else r'\s*\)'
        patterns.append((re.compile(rf'{func}\(\s*{args}{tail}'), quote))
    return patterns


QSTR_PATTERNS = call_patterns(r'qsTr', 1)
# I18n.tr(term, context, true): Mit dem wörtlichen `true` (auf derselben Zeile) ist der Kontext ein
# eigener Schlüssel – (term, context) bekommt eine eigene Übersetzung. Ohne `true` ist der Kontext nur
# ein Hinweis für Übersetzende und landet im Feld "comment".
TR_REAL_CONTEXT_PATTERNS = call_patterns(r'I18n\.tr', 2, trailing_true=True)
TR_CONTEXT_PATTERNS = call_patterns(r'I18n\.tr', 2)
TR_SIMPLE_PATTERNS = call_patterns(r'I18n\.tr', 1)

CATALOGS = ('translations/poexports/de.json', 'Alpe/translations/poexports/de.json')


def new_translation_bucket():
    return {
        'contexts': set(),
        'real_contexts': defaultdict(list),
        'occurrences': [],
        'plain_occurrences': []
    }


def scan_line(line, occ, translations, real_patterns, context_patterns, simple_patterns, key_offset=0):
    real_spans = []
    for pattern, quote in real_patterns:
        for match in pattern.finditer(line):
            key = tuple(decode_string_literal(g, quote) for g in match.groups()[:key_offset])
            term = decode_string_literal(match.group(key_offset + 1), quote)
            context = decode_string_literal(match.group(key_offset + 2), quote)
            translations[key + (term,)]['real_contexts'][context].append(occ)
            translations[key + (term,)]['occurrences'].append(occ)
            real_spans.append(match.span())

    context_spans = []
    for pattern, quote in context_patterns:
        for match in pattern.finditer(line):
            if any(spans_overlap(match.span(), span) for span in real_spans):
                continue
            key = tuple(decode_string_literal(g, quote) for g in match.groups()[:key_offset])
            term = decode_string_literal(match.group(key_offset + 1), quote)
            context = decode_string_literal(match.group(key_offset + 2), quote)
            translations[key + (term,)]['contexts'].add(context)
            translations[key + (term,)]['occurrences'].append(occ)
            translations[key + (term,)]['plain_occurrences'].append(occ)
            context_spans.append(match.span())

    for pattern, quote in simple_patterns:
        for match in pattern.finditer(line):
            if any(spans_overlap(match.span(), span) for span in real_spans + context_spans):
                continue
            key = tuple(decode_string_literal(g, quote) for g in match.groups()[:key_offset])
            term = decode_string_literal(match.group(key_offset + 1), quote)
            translations[key + (term,)]['occurrences'].append(occ)
            translations[key + (term,)]['plain_occurrences'].append(occ)


def extract_qstr_strings(root_dir):
    translations = defaultdict(new_translation_bucket)

    # Die ganze Oberfläche, auch Alpe/ (Bibliothek, Dash, Dateiwähler): Seit D7.2 liegt dort mehr als
    # die frühere Bibliothek, und I18n.tr() schlägt ohnehin in beiden Katalogen nach.
    for qml_file in sorted(Path(root_dir).rglob('*.qml')):
        relative_path = qml_file.relative_to(root_dir)

        with open(qml_file, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                occ = {'file': str(relative_path), 'line': line_num}
                for pattern, quote in QSTR_PATTERNS:
                    for match in pattern.finditer(line):
                        term = decode_string_literal(match.group(1), quote)
                        translations[(term,)]['occurrences'].append(occ)
                        translations[(term,)]['plain_occurrences'].append(occ)
                scan_line(line, occ, translations, TR_REAL_CONTEXT_PATTERNS, TR_CONTEXT_PATTERNS, TR_SIMPLE_PATTERNS)

    return {key[0]: data for key, data in translations.items()}


def references(occurrences):
    # Nur Dateien, ohne Zeilennummern: sonst änderte jede verschobene Zeile en.json.
    return ", ".join(sorted({occ['file'] for occ in occurrences}))


def create_catalog(translations):
    """Einträge von en.json: je Text einer mit context == term, dazu einer je echtem Kontext."""
    entries = []

    for term, data in sorted(translations.items()):
        if data['plain_occurrences']:
            contexts = sorted(data['contexts']) if data['contexts'] else []
            entries.append({
                "term": term,
                "context": term,
                "reference": references(data['plain_occurrences']),
                "comment": " | ".join(contexts)
            })

        for context in sorted(data['real_contexts']):
            entries.append({
                "term": term,
                "context": context,
                "reference": references(data['real_contexts'][context]),
                "comment": ""
            })

    return entries


def entry_key(entry):
    return (entry["context"], entry["term"], entry.get("comment", ""))


def load_json(path, default):
    try:
        with open(path, encoding='utf-8') as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def translated(tables, context, term):
    """Wie I18n.qml nachschlägt: (Kontext, Text), dann (Text, Text), dann der Text in irgendeinem Kontext."""
    for table in tables:
        if table.get(context, {}).get(term) or table.get(term, {}).get(term):
            return True
        if any(bucket.get(term) for bucket in table.values() if isinstance(bucket, dict)):
            return True
    return False


def check(root_dir):
    """Vergleicht die Oberfläche mit en.json und den deutschen Katalogen, ohne etwas zu schreiben.

    Ergebnis: (neu, weg, luecken, ueberzaehlig) – Einträge, die in en.json fehlen bzw. dort zu viel sind,
    Paare (Kontext, Text) ohne deutsche Übersetzung, und Paare in den Katalogen, die kein Text mehr braucht.
    """
    root_dir = Path(root_dir)
    entries = create_catalog(extract_qstr_strings(root_dir))
    current = {entry_key(entry) for entry in entries}
    stored = {entry_key(entry) for entry in load_json(root_dir / 'translations' / 'en.json', [])}
    tables = [load_json(root_dir / name, {}) for name in CATALOGS]
    pairs = {(entry["context"], entry["term"]) for entry in entries}
    terms = {term for _context, term in pairs}
    gaps = sorted(pair for pair in pairs if not translated(tables, *pair))
    surplus = sorted({(context, term) for table in tables for context, bucket in table.items() if isinstance(bucket, dict)
                      for term in bucket if (context, term) not in pairs and term not in terms})
    return sorted(current - stored), sorted(stored - current), gaps, surplus


def main(argv):
    script_dir = Path(__file__).parent
    root_dir = script_dir.parent

    if '--pruefen' in argv:
        new, gone, gaps, surplus = check(root_dir)
        for label, items in (("fehlt in en.json", new), ("in en.json, aber nicht mehr in der Oberfläche", gone)):
            for context, term, _comment in items:
                print(f"{label}: {term!r}" + ("" if context == term else f" (Kontext {context!r})"))
        for label, items in (("ohne deutsche Übersetzung", gaps), ("überzählig in de.json", surplus)):
            for context, term in items:
                print(f"{label}: {term!r}" + ("" if context == term else f" (Kontext {context!r})"))
        print(f"en.json: {len(new)} fehlen, {len(gone)} überzählig; Deutsch: {len(gaps)} ohne Übersetzung, {len(surplus)} überzählig")
        return 1 if new or gone else 0

    translations = extract_qstr_strings(root_dir)
    entries = create_catalog(translations)
    en_json_path = script_dir / 'en.json'
    with open(en_json_path, 'w', encoding='utf-8') as f:
        json.dump(entries, f, indent=2, ensure_ascii=False)
        f.write('\n')
    print(f"{en_json_path}: {len(entries)} Einträge aus {len(translations)} Texten")
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
