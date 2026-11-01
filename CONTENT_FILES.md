# Inhalte in getrennten JSON-Dateien

Events und Summon-Banner werden automatisch nach Dateinamen gruppiert:

| Inhalt | Dateinamen | JSON-Wurzel |
| --- | --- | --- |
| Events | `event.json`, `event_*.json` (außer `event_shop.json`) | `{ "events": [...] }` |
| Summon-Banner | `summon.json`, `summon_*.json` | `{ "banners": [...] }` |

Die vorhandenen Events sind unverändert auf `event_2026_10.json` (17 Events) und `event_2026_11.json` (7 Events) verteilt. `event.json` ist als leere Basisdatei erhalten.

## Einen Monat hinzufügen

1. Eine passende Monatsdatei kopieren, beispielsweise nach `event_2026_12.json`.
2. Inhalte, Zeiträume und IDs anpassen. IDs müssen innerhalb einer Gruppe eindeutig sein. Bestehende IDs erhalten, wenn Fortschritt und Belohnungsstatus weiter gelten sollen.
3. Die Datei in Xcode zum App-Target hinzufügen, damit sie im App-Bundle landet. Beim nächsten Laden wird sie automatisch erkannt; kein neuer Enum-Fall pro Monat ist nötig.

Die gleiche Vorgehensweise funktioniert für `summon_2026_12.json`. Andere JSON-Schemas bleiben unverändert. Neue Inhaltsgruppen lassen sich in `JSONContentGroup` ergänzen und über `JSONLoader.loadCollection` anbinden.

Dateien werden alphabetisch geladen. Doppelte IDs behalten den ersten Eintrag und erzeugen eine Konsolenmeldung. Fehlerhafte Dateien werden mit Dateiname und Fehler protokolliert und übersprungen; die übrigen Dateien bleiben verfügbar. Darum vor Veröffentlichung immer die Konsole und die Inhalte prüfen.

## Remote-Inhalte

Der Server kann nicht automatisch aufgelistet werden. Jede neue Remote-Datei muss deshalb im `json`-Array der serverseitigen `contentVersion.json` stehen, mit `name` ohne `.json` und dem tatsächlichen `path`. Die `contentVersion` erhöhen und alle Dateien gemeinsam veröffentlichen.

Eine vollständig heruntergeladene, neuere Remote-Gruppe mit einzelnen Inhaltsdateien ersetzt die gebündelte Gruppe. Deshalb müssen im Manifest alle weiterhin benötigten Monatsdateien dieser Gruppe stehen. Alte, nicht mehr gelistete Cache-Dateien werden nicht wieder eingeblendet. Liefert ein älterer Server nur `event.json` bzw. `summon.json`, werden die lokalen Monatsdateien zusätzlich geladen. Das gilt auch für alte Caches ohne Ressourcenindex, damit die Umstellung keine neuen Monate ausblendet. Die Änderungen hier veröffentlichen keine Dateien auf dem Server.

## Zeiträume und Gifts

Abgelaufene Events, ihre Event-Shops, Daily-Login-Kampagnen und Summon-Banner werden aus der UI ausgeblendet. Kommende Inhalte bleiben als Vorschau sichtbar. Offene Seiten aktualisieren sich im Vordergrund jede Sekunde und bei Rückkehr in die App. Einlösen/Ziehen prüft zusätzlich die aktuelle Uhrzeit.

Gifts verwenden ebenfalls `startDate` und `endDate`, beispielsweise `"startDate": "01.11.2026 00:00"` und `"endDate": "01.12.2026 00:00"`. Alle Daten gelten in Europe/Berlin. Das Enddatum ist exklusiv: Ab exakt diesem Zeitpunkt ist der Inhalt nicht mehr verfügbar. Gifts werden nur während ihres aktiven Zeitraums angeboten; fehlende oder ungültige Ablaufdaten machen sie unverfügbar. Auch Remote-Gifts müssen diese Felder bekommen.

Vorläufige Laufzeiten der bestehenden Gifts: Release 01.10.–01.12.2026, Birthday/Halloween 01.10.–01.11.2026, November-Entschädigung 01.11.–01.12.2026, jeweils 00:00 Uhr. Bereits eingelöste Belohnungen und gespeicherte IDs werden nicht entfernt. News-Veröffentlichungsdaten sind keine Ablaufdaten; Inhalte ohne Zeitraumschema werden durch diese Regel nicht verändert.

## Summon-Wahrscheinlichkeiten

`weight` ist ein relatives Gewicht, kein fertiger Prozentwert. Gewichte 2 und 6 ergeben 25 % und 75 %. Anzeige und Ziehung verwenden dieselbe Verteilung; Single und Multi haben pro Ziehung dieselben Chancen. Nichtpositive Gewichte erhalten 0 %. Ein Banner ohne positive Gewichte kann nicht gezogen werden. Prozentwerte werden auf bis zu zwei Nachkommastellen gerundet.

## Große Zahlen

HP und Schaden erscheinen mit K/M/B/T usw. Die Speicherung bleibt bei Ganzzahlen kompatibel mit vorhandenen Spielständen. Exponentielle Berechnungen werden vor der Umwandlung abgesichert und bei `Int.max` (rund 9,22 × 10^18 auf 64 Bit) gedeckelt. Oberhalb dieser Grenze wächst der Wert nicht weiter. Das ist keine unbegrenzte Big-Number-Progression.
