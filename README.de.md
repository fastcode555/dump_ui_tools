# Android UI Analyzer Tool

[English](README.md) | [中文](README.zh.md) | [Deutsch](README.de.md) | [한국어](README.ko.md) | [日本語](README.ja.md)

---

Eine leistungsstarke Flutter-Desktop-Anwendung zur Analyse von Android UI-Hierarchien aus XML-Dump-Dateien. Dieses Tool hilft Entwicklern dabei, UI-Strukturen zu verstehen, Layout-Probleme zu debuggen und die Entwicklung von UI-Automatisierungstests zu beschleunigen.

![App-Screenshot](docs/images/app-screenshot.png)

## Funktionen

### Kernfunktionalität
- **🔍 UI-Hierarchie-Visualisierung**: Interaktive Baumansicht von Android UI-Strukturen
- **🔎 Erweiterte Suche & Filterung**: Elemente nach Text, Ressourcen-ID, Klassenname oder Eigenschaften finden
- **📊 Eigenschaftsprüfung**: Detaillierte Ansicht von UI-Element-Attributen und -Grenzen
- **🖼️ Visuelle Vorschau**: Skalierte Gerätebildschirm-Darstellung mit Element-Hervorhebung
- **📝 XML-Ansicht**: Syntax-hervorgehobene XML-Anzeige mit Export-Funktionen
- **📚 Verlaufsverwaltung**: Zugriff auf und Verwaltung zuvor erfasster UI-Dumps

### Hauptvorteile
- Beschleunigung der UI-Automatisierungstest-Entwicklung
- Debugging komplexer Layout-Hierarchien
- Verständnis von Barrierefreiheits-Strukturen
- Export von Daten für weitere Analysen
- Optimierung von Mobile-App-Test-Workflows

## Schnellstart

### Voraussetzungen
- macOS 10.14 oder höher
- Android-Gerät mit aktiviertem USB-Debugging
- ADB (Android Debug Bridge) installiert

### Installation
1. Laden Sie die neueste Version von [Releases](https://github.com/your-repo/releases) herunter
2. Extrahieren und in den Applications-Ordner verschieben
3. Anwendung starten
4. Android-Gerät verbinden und mit der Analyse beginnen!

### Grundlegende Verwendung
1. **Gerät verbinden**: Android-Gerät mit aktiviertem USB-Debugging
2. **UI erfassen**: Klicken Sie auf "UI erfassen" um die aktuelle Bildschirm-Hierarchie zu erhalten
3. **Erkunden**: Verwenden Sie Baumansicht, Suche und Filter um Elemente zu finden
4. **Prüfen**: Klicken Sie auf Elemente um detaillierte Eigenschaften anzuzeigen
5. **Exportieren**: XML-Dateien für Automatisierungsskripte speichern

## Dokumentation

- **[Benutzerhandbuch](docs/USER_GUIDE.md)**: Vollständige Benutzerdokumentation
- **[Entwicklerhandbuch](docs/DEVELOPER_GUIDE.md)**: Technische Implementierungsdetails
- **[Bereitstellungshandbuch](docs/DEPLOYMENT_GUIDE.md)**: Build- und Verteilungsanweisungen
- **[Testbericht](docs/TEST_REPORT.md)**: Umfassende Testvalidierung

## Projektstruktur

```
lib/
├── main.dart                 # Anwendungseinstiegspunkt
├── controllers/              # Zustandsverwaltung und Geschäftslogik
│   ├── ui_analyzer_state.dart
│   ├── search_controller.dart
│   └── filter_controller.dart
├── models/                   # Datenmodelle und Entitäten
│   ├── ui_element.dart
│   ├── android_device.dart
│   └── filter_criteria.dart
├── services/                 # Externe Service-Integrationen
│   ├── adb_service.dart
│   ├── xml_parser.dart
│   ├── file_manager.dart
│   └── user_preferences.dart
├── ui/                       # Benutzeroberflächen-Komponenten
│   ├── panels/              # Haupt-UI-Panels
│   ├── widgets/             # Wiederverwendbare Komponenten
│   ├── dialogs/             # Modale Dialoge
│   └── themes/              # Theme-Konfiguration
└── utils/                   # Hilfsfunktionen und Utilities

test/                        # Umfassende Test-Suite
docs/                        # Dokumentation
```

## Entwicklung

### Voraussetzungen
- Flutter SDK 3.7.2+ (empfohlen über FVM verwaltet)
- Dart SDK 2.19.0+
- macOS-Entwicklungsumgebung
- Xcode (für macOS-Builds)

### Setup
```bash
# Repository klonen
git clone <repository-url>
cd android-ui-analyzer

# Abhängigkeiten installieren
fvm flutter pub get

# Anwendung ausführen
fvm flutter run -d macos
```

### Entwicklungsbefehle
```bash
# Code-Analyse
fvm flutter analyze

# Tests ausführen
fvm flutter test

# Integrationstests ausführen
fvm flutter test test/integration/

# Release-Build erstellen
fvm flutter build macos --release
```

### Testing
Das Projekt umfasst umfassende Tests:
- **Unit Tests**: Validierung der Kern-Geschäftslogik
- **Integration Tests**: End-to-End-Funktionalitätsverifizierung
- **Widget Tests**: UI-Komponenten-Verhaltenstests

Test-Suite ausführen:
```bash
# Alle Tests
fvm flutter test

# Bestimmte Test-Datei
fvm flutter test test/integration/final_integration_test.dart

# Mit Coverage
fvm flutter test --coverage
```

## Architektur

### Clean Architecture Pattern
- **UI Layer**: Flutter Widgets und Panels
- **Business Logic**: Controller und Zustandsverwaltung
- **Data Layer**: Services und Repositories
- **External**: ADB-Integration und Dateisystem

### Schlüsseltechnologien
- **Flutter**: Cross-Platform UI-Framework
- **Provider**: Zustandsverwaltung
- **XML**: Android UI-Dump-Parsing
- **ADB**: Android-Gerätekommunikation
- **Material Design 3**: Moderne UI-Komponenten

## Beitragen

Wir freuen uns über Beiträge! Bitte sehen Sie unsere Beitragsrichtlinien:

1. Repository forken
2. Feature-Branch erstellen
3. Änderungen mit Tests vornehmen
4. Pull Request einreichen

### Code-Stil
- Dart-Styleguide befolgen
- Dokumentation für öffentliche APIs hinzufügen
- Tests für neue Features einschließen
- Aussagekräftige Commit-Nachrichten verwenden

## Performance

### Benchmarks
- **XML-Parsing**: < 500ms für typische UI-Dumps
- **Suche**: < 100ms Antwortzeit
- **Speicherverbrauch**: Optimiert für große Hierarchien
- **UI-Reaktivität**: 60fps flüssige Interaktionen

### Optimierungsfunktionen
- Lazy Loading für große Bäume
- Virtuelles Scrollen für Performance
- Debounced-Suche um Verzögerungen zu verhindern
- Effiziente Speicherverwaltung

## Sicherheit

### Datenschutz
- Keine sensiblen Daten übertragen
- Nur lokale Dateiverarbeitung
- Sichere temporäre Dateiverarbeitung
- Datenschutzorientiertes Design

### Best Practices
- Eingabevalidierung und -bereinigung
- Sicheres XML-Parsing
- Angemessene Fehlerbehandlung
- Ressourcenbereinigung

## Kompatibilität

### Unterstützte Plattformen
- **Primär**: macOS 10.14+
- **Android-Geräte**: API 16+ (Android 4.1+)
- **ADB-Versionen**: Alle modernen Versionen

### Getestete Konfigurationen
- Verschiedene Android-Gerätehersteller
- Unterschiedliche Bildschirmgrößen und -ausrichtungen
- Komplexe UI-Hierarchien und -Layouts
- Mehrere Android-Versionen

## Fehlerbehebung

### Häufige Probleme
- **Gerät nicht erkannt**: USB-Debugging und ADB-Installation überprüfen
- **UI-Erfassung fehlgeschlagen**: Sicherstellen, dass Gerät entsperrt ist und App Berechtigungen hat
- **Performance-Probleme**: Filter verwenden um angezeigte Elemente zu reduzieren

Detaillierte Fehlerbehebung siehe [Benutzerhandbuch](docs/USER_GUIDE.md).

## Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert - siehe [LICENSE](LICENSE)-Datei für Details.

## Danksagungen

- Flutter-Team für das ausgezeichnete Framework
- Android-Team für UIAutomator-Tools
- Open-Source-Community für Abhängigkeiten
- Mitwirkende und Tester

## Support

- **Dokumentation**: docs/-Verzeichnis überprüfen
- **Probleme**: GitHub Issues für Bug-Reports verwenden
- **Diskussionen**: GitHub Discussions für Fragen
- **E-Mail**: [support@example.com](mailto:support@example.com)

---

**Mit ❤️ für Android-Entwickler und -Tester erstellt** 