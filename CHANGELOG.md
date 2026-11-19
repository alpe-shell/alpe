# Änderungen

Alle Fassungen heissen «Zugerberg»; gezählt wird nur die Nummer.

## 1.0 (November 2026)

Erste Fassung.

- **Installation mit einem Befehl:** `get.sh` prüft Rechner und Sitzung, installiert bei Bedarf die
  Dux Modular Shell, richtet Alpe ein (baut einen passenden Dienst, wenn der installierte nicht
  passt), installiert auf Wunsch kitty, fastfetch und die KWin-Effekte (Unschärfe, runde Ecken),
  ersetzt unter KDE Plasmas Oberfläche und spielt das Design ein. Jeder Schritt mit
  Rückfrage, `--check` für einen Probelauf.
- **Wetter:** Prognose von MeteoSchweiz (amtliche Tagesprognose, Stundenwerte aus ICON-CH),
  Niederschlagsradar der Schweiz als Film mit Hochrechnung der nächsten Stunde.
- **Sport:** National League, Super League, Nati im Eishockey und Fussball, Top-5-Ligen mit Cups,
  Champions und Europa League, NBA – Spiele, Live-Resultate, Tabellen, Bestenlisten, Spielerwerte
  und Spieldetails; Favoriten mit Mitteilungen bei Toren, Live-Spiel in der Leiste, Streamingdienst
  je Wettbewerb. Der Tab ist 6 × 8 gross, mit Spieldetail daneben 8 × 8.
- **KDE Plasma:** Alpe anstelle von plasmashell (`alpe kde ein|aus`); Griffleisten, Einrasten und
  Fenstermenü für Fenster ohne Titelleiste; Fensterregeln, Effekte, Tastenkürzel (auch eigene für
  Programme und Befehle) und Dienste in den Einstellungen; Sperrbildschirm im Alpe-Design, gesperrt
  beim Start nach automatischer Anmeldung. Vorgaben: Meta+Q schliesst Fenster, Meta+M öffnet den
  Systemmonitor (`alpe kuerzel`).
- **Hyprland und Laptops:** Unschärfe einstellbar, hyprlock in Alpe gestalten, Ladegrenze,
  Zuklappen, Tastaturbeleuchtung.
- **Design:** `alpe design export|apply|status` hält das Aussehen fest und spielt es ein – samt
  kitty und fastfetch, ohne Persönliches (Wetterort, Favoriten, Bildschirme, Pfade), Bilder nur
  als bestätigte eigene.
- **Befehl `alpe`:** `doctor`, `update`, `backup`/`restore`, `ram`, `fastfetch`, `test`, `entfernen` und mehr.
