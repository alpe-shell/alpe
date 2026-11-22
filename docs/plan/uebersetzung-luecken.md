# Vorschlag: deutsche Texte für die 42 Lücken (Plan 0.8 Nr. 74)

Stand 22.11.2026, Halt nach D7. **Vorschlag, noch nicht freigegeben und nicht umgesetzt.** Freigabe
durch den Maintainer vor G1, zusammen mit `docs/plan/sie-form.md`; Umsetzung danach in
`shell/translations/poexports/de.json`, und `tests/data/uebersetzung-bekannte-luecken.txt` wird
im selben Commit leer.

Die 42 Texte der Oberfläche ohne deutsche Übersetzung stehen in
`tests/data/uebersetzung-bekannte-luecken.txt`. Je Eintrag: der englische Quelltext (zugleich der
Schlüssel), wo er steht und was er bezeichnet, und der Vorschlag in Du-Form und Schweizer
Schreibweise. Begriffe wie im übrigen Katalog (Arbeitsbereich, Display, Papierkorb, Anbieter).

## Liste

**1** `%1 of %2`
- wo: Dateien, Vorschau – Stelle des gezeigten Elements unter den ausgewählten
- neu: %1 von %2

**2** `%1 × %2`
- wo: Dateien, Vorschau – Breite und Höhe eines Bilds in Pixeln
- neu: %1 × %2

**3** `%1, %2`
- wo: Dateien – Zeitangabe, %1 Wochentag, %2 Uhrzeit
- neu: %1, %2

**4** `A plugin file was added or renamed while the shell was running. Restart Alpe to load it. If the plugin was not updated, check that its imports match the file name capitalization.`
- wo: Plugins – Hinweis nach einem Ladefehler
- neu: Eine Plugin-Datei wurde hinzugefügt oder umbenannt, während die Shell lief. Starte Alpe neu, um sie zu laden. Wurde das Plugin nicht aktualisiert, prüfe, ob seine Importe mit der Gross- und Kleinschreibung der Dateinamen übereinstimmen.

**5** `Authenticating...`
- wo: Sperrbildschirm – Status, während das Passwort geprüft wird
- neu: Anmeldung wird geprüft …

**6** `Authentication error - try again`
- wo: Sperrbildschirm – Fehler bei der Prüfung
- neu: Fehler bei der Anmeldung – versuch es erneut

**7** `Authentication failed - try again`
- wo: Sperrbildschirm – Passwort abgelehnt
- neu: Anmeldung fehlgeschlagen – versuch es erneut

**8** `Bento style only`
- wo: Übersicht, Medien – Hinweis zu einer Option, die nur im Stil «Bento» wirkt
- neu: Nur im Stil «Bento»

**9** `Card backgrounds`
- wo: Übersicht, Medien – Schalter für Kartenhintergründe
- neu: Kartenhintergründe

**10** `Clicking a workspace from another display moves it to the display of the bar you clicked`
- wo: Einstellungen, Arbeitsbereich-Umschalter – Erklärung zu Nr. 28
- neu: Ein Klick auf einen Arbeitsbereich eines anderen Displays verschiebt ihn auf das Display der Leiste, in der du geklickt hast

**11** `Deleted`
- wo: Dateien, Papierkorb – Spaltenkopf (wann gelöscht)
- neu: Gelöscht

**12** `Dimensions`
- wo: Dateien, Vorschau – Zeile für Breite und Höhe eines Bilds
- neu: Abmessungen

**13** `Failed to change priority of %1`
- wo: Prozessliste – Meldung, %1 ist ein Prozessname
- neu: Priorität von %1 konnte nicht geändert werden

**14** `Failed to pause %1`
- wo: Prozessliste – Meldung, %1 ist ein Prozessname
- neu: %1 konnte nicht angehalten werden

**15** `Failed to resume %1`
- wo: Prozessliste – Meldung, %1 ist ein Prozessname
- neu: %1 konnte nicht fortgesetzt werden

**16** `Fingerprint`
- wo: Einstellungen, Sperrbildschirm – Schalter für die Anmeldung mit Fingerabdruck
- neu: Fingerabdruck

**17** `Flat turns acceleration off. Adaptive speeds the pointer up as you move faster.`
- wo: Einstellungen, Maus – Erklärung zum Beschleunigungsprofil
- neu: «Flach» schaltet die Beschleunigung aus. «Adaptiv» macht den Zeiger schneller, je schneller du die Maus bewegst.

**18** `Hide preview`
- wo: Dateien – Tooltip der Schaltfläche, die die Vorschau schliesst
- neu: Vorschau ausblenden

**19** `Highest`
- wo: Prozessliste – Voreinstellung der Priorität
- neu: Höchste

**20** `Jump to a folder you visited`
- wo: Dateien, Ortsleiste – Platzhalter im Sprung-Modus
- neu: Zu einem besuchten Ordner springen

**21** `Keyboard`
- wo: Einstellungen – Name der Seite
- neu: Tastatur

**22** `Last used`
- wo: Dateien, «Zuletzt verwendet» – Spaltenkopf (wann zuletzt geöffnet)
- neu: Zuletzt verwendet

**23** `Launch new instance`
- wo: Einstellungen, Dock – Auswahl für die Aktion bei Mittelklick
- neu: Neue Instanz starten

**24** `Login`
- wo: Einstellungen, Klänge – Schalter für den Klang beim Anmelden
- neu: Anmeldung

**25** `Lowest`
- wo: Prozessliste – Voreinstellung der Priorität
- neu: Niedrigste

**26** `Middle-click action`
- wo: Einstellungen, Dock – Einstellung
- neu: Aktion bei Mittelklick

**27** `Mouse behavior`
- wo: Einstellungen, Dock – Titel der Karte
- neu: Mausverhalten

**28** `Move workspace to this display`
- wo: Einstellungen, Arbeitsbereich-Umschalter – Schalter
- neu: Arbeitsbereich auf dieses Display verschieben

**29** `Nothing is at this location`
- wo: Dateien, Ortsleiste – Fehler, wenn der eingegebene Ort nicht existiert
- neu: An diesem Ort ist nichts

**30** `Original location`
- wo: Dateien, Papierkorb – Spaltenkopf (woher gelöscht)
- neu: Ursprünglicher Ort

**31** `Paged grid`
- wo: Übersicht, Hintergrundbilder – Auswahl der Anordnung
- neu: Raster mit Seiten

**32** `Security key`
- wo: Sperrbildschirm – Tooltip der Schaltfläche für den Sicherheitsschlüssel
- neu: Sicherheitsschlüssel

**33** `Spinning Record`
- wo: Übersicht, Medien – Form des Albumbilds, dreht sich wie eine Schallplatte
- neu: Drehende Schallplatte

**34** `Stay awake with the lid closed`
- wo: Kontrollzentrum, Wachhalten – Option, die auch den Ruhezustand beim Zuklappen verhindert
- neu: Bei geschlossenem Deckel wach bleiben

**35** `Swaying Square`
- wo: Übersicht, Medien – Form des Albumbilds
- neu: Schwingendes Quadrat

**36** `The next enabled provider is used when one fails.`
- wo: Einstellungen, Wetter – Hinweis zur Reihenfolge der Anbieter
- neu: Fällt ein Anbieter aus, wird der nächste eingeschaltete verwendet.

**37** `This kind of location is not supported`
- wo: Dateien, Ortsleiste – Fehler bei einer nicht unterstützten Adresse
- neu: Diese Art von Ort wird nicht unterstützt

**38** `Today, %1`
- wo: Dateien – Zeitangabe, %1 ist die Uhrzeit
- neu: Heute, %1

**39** `Type a path, ~ or an address such as sftp://host`
- wo: Dateien, Ortsleiste – Platzhalter
- neu: Pfad, ~ oder eine Adresse wie sftp://host eingeben

**40** `Use ~ for your own home folder or type the full path`
- wo: Dateien, Ortsleiste – Hinweis
- neu: Verwende ~ für deinen eigenen Benutzerordner oder gib den ganzen Pfad ein

**41** `Weather providers`
- wo: Einstellungen, Wetter – Titel der Karte
- neu: Wetter-Anbieter

**42** `Yesterday, %1`
- wo: Dateien – Zeitangabe, %1 ist die Uhrzeit
- neu: Gestern, %1

## Anmerkungen

- Nr. 2, 3: Der deutsche Text ist gleich dem englischen. Der Eintrag gehört trotzdem in den Katalog,
  sonst bleibt die Lücke in der Prüfung stehen.
- Nr. 5–7: «Anmeldung» statt «Authentifizierung», weil der Text auf dem Sperrbildschirm steht und kurz
  sein muss. Der Katalog sagt in den Einstellungen sonst «Authentifizierung».
- Nr. 8: «Bento» ist der Name eines Stils und bleibt unübersetzt.
- Nr. 22: gleichlautend mit dem Namen der Ansicht; als Spaltenkopf wäre auch «Zuletzt geöffnet» möglich.
- Nr. 41: Schreibweise wie «Songtext-Anbieter» im Katalog.
- Die Angaben unter «wo» stammen aus dem Kontext, den der Quelltext für Übersetzende mitgibt
  (`I18n.tr(Text, Kontext)`), bei Nr. 4, 10, 17, 28, 37, 39 und 40 aus dem Wortlaut; angesehen in der
  laufenden Oberfläche habe ich die Stellen nicht.
