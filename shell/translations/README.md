# Übersetzungen der Oberfläche

Gepflegt werden nur Deutsch und die englischen Quelltexte, beide von Hand und ausschliesslich in
diesem Repository. Einen Abgleich mit einem Übersetzungsdienst gibt es nicht.

## Dateien

- `en.json` – alle Quelltexte aus `qsTr()` und `I18n.tr()` der ganzen Oberfläche (auch `Alpe/`),
  erzeugt von `extract_translations.py`. Die Oberfläche liest die Datei nicht; sie ist die Liste,
  gegen die die deutschen Kataloge geprüft werden.
- `poexports/de.json` – Deutsch für die Oberfläche: `{ "Kontext": { "Text": "Übersetzung" } }`.
- `../Alpe/translations/poexports/de.json` – Deutsch für die Bibliothek `Alpe/`, gleiches Format.
  `I18n.tr()` schlägt zuerst im Katalog der Oberfläche nach, dann in diesem.
- `settings_search_index.json` – Suchindex der Einstellungen, erzeugt von
  `extract_settings_index.py`; die Suche in den Einstellungen liest ihn.

## Felder in `en.json`

- `term` – der englische Quelltext
- `context` – gleich `term`, ausser bei `I18n.tr(text, kontext, true)`: Dann ist der Kontext ein
  eigener Schlüssel mit eigener Übersetzung.
- `reference` – Dateien, in denen der Text vorkommt (ohne Zeilennummern)
- `comment` – Hinweis aus `I18n.tr(text, hinweis)` für Übersetzende

## Nach Änderungen an Texten

```bash
python3 shell/translations/extract_translations.py            # en.json neu schreiben
python3 shell/translations/extract_translations.py --pruefen  # nur prüfen, nennt Texte ohne Deutsch
```

Neue Texte danach in `poexports/de.json` übersetzen (Schweizer Schreibweise). `tests/test_uebersetzung.py`
(in `tools/test.sh`) schlägt fehl, wenn `en.json` veraltet ist, ein neuer Text keine Übersetzung hat
oder zwei Texte sich nur in Gross-/Kleinschreibung oder Schlusszeichen unterscheiden
(`check_term_variants.py`). Die bei der Einführung der Prüfung offenen Lücken stehen in
`tests/data/uebersetzung-bekannte-luecken.txt`.
