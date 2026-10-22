#!/usr/bin/env python3
"""Fill the catalog slots still missing after the MT pass.

The MyMemory quota cut the machine run partway (see #582). These are
locally authored translations for the remainder, marked `needs_review`
like every other MT value in the catalog: they must not ship without a
native-speaker pass. Format specifiers are preserved verbatim and
validated against the source before writing.

de-CH defaults to the German value and es-US to the Spanish value,
matching the catalog's existing regional-variant convention.
"""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from format_specifier_guard import extract_format_specifiers as spec  # noqa: E402

CATALOG = Path(__file__).resolve().parent.parent / "Framework" / "Resources" / "Localizable.xcstrings"
REGIONAL = {"de-CH": "de", "es-US": "es"}

T = {
 "%1$@ / %2$@": {"da":"%1$@ / %2$@","de":"%1$@ / %2$@","es":"%1$@ / %2$@","fr":"%1$@ / %2$@","it":"%1$@ / %2$@","ja":"%1$@ / %2$@","ko":"%1$@ / %2$@","nl":"%1$@ / %2$@","pl":"%1$@ / %2$@","sv":"%1$@ / %2$@","zh-Hans":"%1$@ / %2$@"},
 "%1$@ / %2$@ characters": {"da":"%1$@ / %2$@ tegn","de":"%1$@ / %2$@ Zeichen","es":"%1$@ / %2$@ caracteres","fr":"%1$@ / %2$@ caractères","it":"%1$@ / %2$@ caratteri","ja":"%1$@ / %2$@文字","ko":"%1$@ / %2$@자","nl":"%1$@ / %2$@ tekens","pl":"%1$@ / %2$@ znaki","sv":"%1$@ / %2$@ tecken","zh-Hans":"%1$@ / %2$@ 个字符"},
 "%1$@ fields • %2$@ complexity": {"da":"%1$@ felter • %2$@ kompleksitet","de":"%1$@ Felder • %2$@ Komplexität","es":"%1$@ campos • %2$@ complejidad","fr":"%1$@ champs • %2$@ complexité","it":"%1$@ campi • %2$@ complessità","ja":"%1$@フィールド • %2$@の複雑さ","ko":"%1$@개 필드 • %2$@ 복잡도","nl":"%1$@ velden • %2$@ complexiteit","pl":"%1$@ pól • %2$@ złożoność","sv":"%1$@ fält • %2$@ komplexitet","zh-Hans":"%1$@ 个字段 • %2$@ 复杂度"},
 "%1$@ validation error%2$@": {"da":"%1$@ valideringsfejl%2$@","de":"%1$@ Validierungsfehler%2$@","es":"%1$@ error de validación%2$@","fr":"%1$@ erreur de validation%2$@","it":"%1$@ errore di convalida%2$@","ja":"%1$@の検証エラー%2$@","ko":"%1$@ 유효성 검사 오류%2$@","nl":"%1$@ validatiefout%2$@","pl":"%1$@ błąd walidacji%2$@","sv":"%1$@ valideringsfel%2$@","zh-Hans":"%1$@ 个验证错误%2$@"},
 "%1$@ • %2$@": {"da":"%1$@ • %2$@","de":"%1$@ • %2$@","es":"%1$@ • %2$@","fr":"%1$@ • %2$@","it":"%1$@ • %2$@","ja":"%1$@ • %2$@","ko":"%1$@ • %2$@","nl":"%1$@ • %2$@","pl":"%1$@ • %2$@","sv":"%1$@ • %2$@","zh-Hans":"%1$@ • %2$@"},
 "%1$@. %2$@": {"da":"%1$@. %2$@","de":"%1$@. %2$@","es":"%1$@. %2$@","fr":"%1$@. %2$@","it":"%1$@. %2$@","ja":"%1$@。%2$@","ko":"%1$@. %2$@","nl":"%1$@. %2$@","pl":"%1$@. %2$@","sv":"%1$@. %2$@","zh-Hans":"%1$@。%2$@"},
 "%1$@: %2$@": {"da":"%1$@: %2$@","de":"%1$@: %2$@","es":"%1$@: %2$@","fr":"%1$@ : %2$@","it":"%1$@: %2$@","ja":"%1$@: %2$@","ko":"%1$@: %2$@","nl":"%1$@: %2$@","pl":"%1$@: %2$@","sv":"%1$@: %2$@","zh-Hans":"%1$@：%2$@"},
 "... and %@ more items": {"da":"... og %@ flere elementer","de":"... und %@ weitere Elemente","es":"... y %@ elementos más","fr":"... et %@ éléments supplémentaires","it":"... e altri %@ elementi","ja":"...他 %@ 件","ko":"... 및 항목 %@개 더","nl":"... en nog %@ items","pl":"... i jeszcze %@ elementów","sv":"... och %@ objekt till","zh-Hans":"...还有 %@ 个项目"},
 "%@ items": {"da":"%@ elementer","de":"%@ Elemente","es":"%@ elementos","fr":"%@ éléments","it":"%@ elementi","ja":"%@ 件","ko":"항목 %@개","nl":"%@ items","pl":"%@ elementów","sv":"%@ objekt","zh-Hans":"%@ 个项目"},
 "Barcode %@:": {"da":"Stregkode %@:","de":"Barcode %@:","es":"Código de barras %@:","fr":"Code-barres %@:","it":"Codice a barre %@:","ja":"バーコード %@:","ko":"바코드 %@:","nl":"Barcode %@:","pl":"Kod kreskowy %@:","sv":"Streckkod %@:","zh-Hans":"条形码 %@:"},
 "Columns: %@": {"da":"Kolonner: %@","de":"Spalten: %@","es":"Columnas: %@","fr":"Colonnes : %@","it":"Colonne: %@","ja":"列: %@","ko":"열: %@","nl":"Kolommen: %@","pl":"Kolumny: %@","sv":"Kolumner: %@","zh-Hans":"列：%@"},
 "Comparing %@ DataFrames": {"da":"Sammenligner %@ DataFrames","de":"Vergleiche %@ DataFrames","es":"Comparando %@ DataFrames","fr":"Comparaison de %@ DataFrames","it":"Confronto di %@ DataFrames","ja":"%@ DataFrame を比較中","ko":"DataFrame %@개 비교 중","nl":"%@ DataFrames vergelijken","pl":"Porównywanie %@ DataFrames","sv":"Jämför %@ DataFrames","zh-Hans":"正在比较 %@ 个 DataFrame"},
 "Complexity: %@": {"da":"Kompleksitet: %@","de":"Komplexität: %@","es":"Complejidad: %@","fr":"Complexité : %@","it":"Complessità: %@","ja":"複雑さ: %@","ko":"복잡도: %@","nl":"Complexiteit: %@","pl":"Złożoność: %@","sv":"Komplexitet: %@","zh-Hans":"复杂度：%@"},
 "Custom field not registered: %@": {"da":"Brugerdefineret felt ikke registreret: %@","de":"Benutzerdefiniertes Feld nicht registriert: %@","es":"Campo personalizado no registrado: %@","fr":"Champ personnalisé non inscrit : %@","it":"Campo personalizzato non registrato: %@","ja":"カスタムフィールドが登録されていません: %@","ko":"사용자 지정 필드가 등록되지 않음: %@","nl":"Aangepast veld niet geregistreerd: %@","pl":"Pole niestandardowe nie jest zarejestrowane: %@","sv":"Anpassat fält ej registrerat: %@","zh-Hans":"自定义字段未注册：%@"},
 "Data size: %@ bytes": {"da":"Datastørrelse: %@ byte","de":"Datengröße: %@ Bytes","es":"Tamaño de los datos: %@ bytes","fr":"Taille des données : %@ octets","it":"Dimensione dati: %@ byte","ja":"データサイズ: %@ バイト","ko":"데이터 크기: %@바이트","nl":"Gegevensgrootte: %@ bytes","pl":"Rozmiar danych: %@ bajtów","sv":"Datastorlek: %@ byte","zh-Hans":"数据大小：%@ 字节"},
 "Dictionary with %@ keys": {"da":"Ordbog med %@ nøgler","de":"Dictionary mit %@ Schlüsseln","es":"Diccionario con %@ claves","fr":"Dictionnaire avec %@ clés","it":"Dizionario con %@ chiavi","ja":"%@ 個のキーを含む辞書","ko":"키가 %@개인 사전","nl":"Dictionary met %@ sleutels","pl":"Słownik z %@ kluczami","sv":"Dictionary med %@ nycklar","zh-Hans":"包含 %@ 个键的字典"},
 "Field Count: %@": {"da":"Antal felter: %@","de":"Anzahl Felder: %@","es":"Número de campos: %@","fr":"Nombre de champs : %@","it":"Numero di campi: %@","ja":"フィールド数: %@","ko":"필드 수: %@","nl":"Aantal velden: %@","pl":"Liczba pól: %@","sv":"Antal fält: %@","zh-Hans":"字段数：%@"},
 "Form: %@": {"da":"Formular: %@","de":"Formular: %@","es":"Formulario: %@","fr":"Formulaire : %@","it":"Modulo: %@","ja":"フォーム: %@","ko":"양식: %@","nl":"Formulier: %@","pl":"Formularz: %@","sv":"Formulär: %@","zh-Hans":"表单：%@"},
 "Found %@ barcode(s)": {"da":"Fandt %@ stregkode(r)","de":"%@ Barcode(s) gefunden","es":"Se encontraron %@ código(s) de barras","fr":"%@ code(s)-barres trouvé(s)","it":"Trovati %@ codice(i) a barre","ja":"%@ 個のバーコードが見つかりました","ko":"바코드 %@개를 찾았습니다","nl":"%@ barcode(s) gevonden","pl":"Znaleziono %@ kod(ów) kreskowych","sv":"Hittade %@ streckkod(er)","zh-Hans":"找到 %@ 个条形码"},
 "Has Dates: %@": {"da":"Har datoer: %@","de":"Enthält Daten: %@","es":"Tiene fechas: %@","fr":"Contient des dates : %@","it":"Ha date: %@","ja":"日付あり: %@","ko":"날짜 있음: %@","nl":"Heeft datums: %@","pl":"Zawiera daty: %@","sv":"Har datum: %@","zh-Hans":"包含日期：%@"},
 "Has Media: %@": {"da":"Har medier: %@","de":"Enthält Medien: %@","es":"Tiene multimedia: %@","fr":"Contient des médias : %@","it":"Ha contenuti multimediali: %@","ja":"メディアあり: %@","ko":"미디어 있음: %@","nl":"Heeft media: %@","pl":"Zawiera multimedia: %@","sv":"Har media: %@","zh-Hans":"包含媒体：%@"},
 "Has Relationships: %@": {"da":"Har relationer: %@","de":"Enthält Beziehungen: %@","es":"Tiene relaciones: %@","fr":"Contient des relations : %@","it":"Ha relazioni: %@","ja":"リレーションシップあり: %@","ko":"관계 있음: %@","nl":"Heeft relaties: %@","pl":"Zawiera relacje: %@","sv":"Har relationer: %@","zh-Hans":"包含关系：%@"},
 "Is Hierarchical: %@": {"da":"Er hierarkisk: %@","de":"Ist hierarchisch: %@","es":"Es jerárquico: %@","fr":"Est hiérarchique : %@","it":"È gerarchico: %@","ja":"階層構造: %@","ko":"계층 구조임: %@","nl":"Is hiërarchisch: %@","pl":"Jest hierarchiczny: %@","sv":"Är hierarkisk: %@","zh-Hans":"为层级结构：%@"},
 "Item %@": {"da":"Element %@","de":"Element %@","es":"Elemento %@","fr":"Élément %@","it":"Elemento %@","ja":"項目 %@","ko":"항목 %@","nl":"Item %@","pl":"Element %@","sv":"Objekt %@","zh-Hans":"项目 %@"},
 "Mean: %.2f": {"da":"Gennemsnit: %.2f","de":"Mittelwert: %.2f","es":"Media: %.2f","fr":"Moyenne : %.2f","it":"Media: %.2f","ja":"平均: %.2f","ko":"평균: %.2f","nl":"Gemiddelde: %.2f","pl":"Średnia: %.2f","sv":"Medelvärde: %.2f","zh-Hans":"平均值：%.2f"},
 "No barcodes were detected in the image": {"da":"Der blev ikke fundet nogen stregkoder på billedet","de":"Im Bild wurden keine Barcodes erkannt","es":"No se detectaron códigos de barras en la imagen","fr":"Aucun code-barres n'a été détecté dans l'image","it":"Nessun codice a barre rilevato nell'immagine","ja":"画像内にバーコードは検出されませんでした","ko":"이미지에서 바코드가 감지되지 않았습니다","nl":"Er zijn geen barcodes gedetecteerd in de afbeelding","pl":"Nie wykryto kodów kreskowych na obrazie","sv":"Inga streckkoder upptäcktes i bilden","zh-Hans":"图像中未检测到条形码"},
 "No data quality information available": {"da":"Ingen oplysninger om datakvalitet tilgængelige","de":"Keine Informationen zur Datenqualität verfügbar","es":"No hay información de calidad de datos disponible","fr":"Aucune information sur la qualité des données disponible","it":"Nessuna informazione sulla qualità dei dati disponibile","ja":"データ品質情報はありません","ko":"사용 가능한 데이터 품질 정보가 없습니다","nl":"Geen informatie over gegevenskwaliteit beschikbaar","pl":"Brak dostępnych informacji o jakości danych","sv":"Ingen information om datakvalitet tillgänglig","zh-Hans":"没有可用的数据质量信息"},
 "No items available": {"da":"Ingen elementer tilgængelige","de":"Keine Elemente verfügbar","es":"No hay elementos disponibles","fr":"Aucun élément disponible","it":"Nessun elemento disponibile","ja":"利用可能な項目はありません","ko":"사용 가능한 항목이 없습니다","nl":"Geen items beschikbaar","pl":"Brak dostępnych elementów","sv":"Inga objekt tillgängliga","zh-Hans":"没有可用的项目"},
 "No options available": {"da":"Ingen indstillinger tilgængelige","de":"Keine Optionen verfügbar","es":"No hay opciones disponibles","fr":"Aucune option disponible","it":"Nessune opzioni disponibili","ja":"利用可能なオプションはありません","ko":"사용 가능한 옵션이 없습니다","nl":"Geen opties beschikbaar","pl":"Brak dostępnych opcji","sv":"Inga alternativ tillgängliga","zh-Hans":"没有可用的选项"},
 "No statistical analysis available": {"da":"Ingen statistisk analyse tilgængelig","de":"Keine statistische Analyse verfügbar","es":"No hay análisis estadístico disponible","fr":"Aucune analyse statistique disponible","it":"Nessuna analisi statistica disponibile","ja":"統計分析は利用できません","ko":"사용 가능한 통계 분석이 없습니다","nl":"Geen statistische analyse beschikbaar","pl":"Brak dostępnej analizy statystycznej","sv":"Ingen statistisk analys tillgänglig","zh-Hans":"没有可用的统计分析"},
 "No text regions detected": {"da":"Ingen tekstområder fundet","de":"Keine Textbereiche erkannt","es":"No se detectaron regiones de texto","fr":"Aucune région de texte détectée","it":"Nessuna regione di testo rilevata","ja":"テキスト領域は検出されませんでした","ko":"감지된 텍스트 영역이 없습니다","nl":"Geen tekstgebieden gedetecteerd","pl":"Nie wykryto obszarów tekstowych","sv":"Inga textområden upptäcktes","zh-Hans":"未检测到文本区域"},
 "No visualization recommendations available": {"da":"Ingen visualiseringsanbefalinger tilgængelige","de":"Keine Visualisierungsempfehlungen verfügbar","es":"No hay recomendaciones de visualización disponibles","fr":"Aucune recommandation de visualisation disponible","it":"Nessun consiglio di visualizzazione disponibile","ja":"視覚化の推奨事項はありません","ko":"사용 가능한 시각화 권장 사항이 없습니다","nl":"Geen visualisatie-aanbevelingen beschikbaar","pl":"Brak dostępnych rekomendacji wizualizacji","sv":"Inga visualiseringsrekommendationer tillgängliga","zh-Hans":"没有可用的可视化建议"},
 "OCR Complete (Fallback)": {"da":"OCR fuldført (reserve)","de":"OCR abgeschlossen (Fallback)","es":"OCR completado (respaldo)","fr":"OCR terminé (solution de repli)","it":"OCR completato (di riserva)","ja":"OCR完了（フォールバック）","ko":"OCR 완료(대체)","nl":"OCR voltooid (reserve)","pl":"OCR zakończono (awaryjnie)","sv":"OCR slutförd (reserv)","zh-Hans":"OCR 完成（回退）"},
 "OCR Error: %@": {"da":"OCR-fejl: %@","de":"OCR-Fehler: %@","es":"Error de OCR: %@","fr":"Erreur OCR : %@","it":"Errore OCR: %@","ja":"OCRエラー: %@","ko":"OCR 오류: %@","nl":"OCR-fout: %@","pl":"Błąd OCR: %@","sv":"OCR-fel: %@","zh-Hans":"OCR 错误：%@"},
 "Optimal layouts for %@": {"da":"Optimale layout til %@","de":"Optimale Layouts für %@","es":"Diseños óptimos para %@","fr":"Dispositions optimales pour %@","it":"Layout ottimali per %@","ja":"%@ に最適なレイアウト","ko":"%@에 최적화된 레이아웃","nl":"Optimale indelingen voor %@","pl":"Optymalne układy dla %@","sv":"Optimala layouter för %@","zh-Hans":"%@ 的最佳布局"},
 "Optional: %1$@ • Array: %2$@ • Identifiable: %3$@": {"da":"Valgfri: %1$@ • Matrix: %2$@ • Identificerbar: %3$@","de":"Optional: %1$@ • Array: %2$@ • Identifizierbar: %3$@","es":"Opcional: %1$@ • Matriz: %2$@ • Identificable: %3$@","fr":"Facultatif : %1$@ • Tableau : %2$@ • Identifiable : %3$@","it":"Facoltativo: %1$@ • Array: %2$@ • Identificabile: %3$@","ja":"オプション: %1$@ • 配列: %2$@ • 識別可能: %3$@","ko":"선택 사항: %1$@ • 배열: %2$@ • 식별 가능: %3$@","nl":"Optioneel: %1$@ • Array: %2$@ • Identificeerbaar: %3$@","pl":"Opcjonalnie: %1$@ • Tablica: %2$@ • Identyfikowalne: %3$@","sv":"Valfritt: %1$@ • Array: %2$@ • Identifierbar: %3$@","zh-Hans":"可选：%1$@ • 数组：%2$@ • 可标识：%3$@"},
 "Pattern Recognition": {"da":"Mønstergenkendelse","de":"Mustererkennung","es":"Reconocimiento de patrones","fr":"Reconnaissance de formes","it":"Riconoscimento di forme","ja":"パターン認識","ko":"패턴 인식","nl":"Patroonherkenning","pl":"Rozpoznawanie wzorców","sv":"Mönsterigenkänning","zh-Hans":"模式识别"},
 "Ready for OCR (Fallback)": {"da":"Klar til OCR (reserve)","de":"Bereit für OCR (Fallback)","es":"Listo para OCR (respaldo)","fr":"Prêt pour l'OCR (solution de repli)","it":"Pronto per OCR (di riserva)","ja":"OCRの準備完了（フォールバック）","ko":"OCR 준비 완료(대체)","nl":"Klaar voor OCR (reserve)","pl":"Gotowe do OCR (awaryjnie)","sv":"Redo för OCR (reserv)","zh-Hans":"OCR 就绪（回退）"},
 "Ready to Scan": {"da":"Klar til scanning","de":"Bereit zum Scannen","es":"Listo para escanear","fr":"Prêt à numériser","it":"Pronto per la scansione","ja":"スキャン準備完了","ko":"스캔 준비 완료","nl":"Klaar om te scannen","pl":"Gotowy do skanowania","sv":"Redo att skanna","zh-Hans":"准备扫描"},
 "Rows: %@": {"da":"Rækker: %@","de":"Zeilen: %@","es":"Filas: %@","fr":"Lignes : %@","it":"Righe: %@","ja":"行: %@","ko":"행: %@","nl":"Rijen: %@","pl":"Wiersze: %@","sv":"Rader: %@","zh-Hans":"行：%@"},
 "Scanning Barcode...": {"da":"Scanner stregkode...","de":"Barcode wird gescannt...","es":"Escaneando código de barras...","fr":"Numérisation du code-barres...","it":"Scansione del codice a barre...","ja":"バーコードをスキャン中...","ko":"바코드 스캔 중...","nl":"Barcode scannen...","pl":"Skanowanie kodu kreskowego...","sv":"Skannar streckkod...","zh-Hans":"正在扫描条形码..."},
 "Select": {"da":"Vælg","de":"Auswählen","es":"Seleccionar","fr":"Sélectionner","it":"Seleziona","ja":"選択","ko":"선택","nl":"Selecteer","pl":"Wybierz","sv":"Välj","zh-Hans":"选择"},
 "Settings": {"da":"Indstillinger","de":"Einstellungen","es":"Ajustes","fr":"Réglages","it":"Impostazioni","ja":"設定","ko":"설정","nl":"Instellingen","pl":"Ustawienia","sv":"Inställningar","zh-Hans":"设置"},
 "Camera": {"da":"Kamera","de":"Kamera","es":"Cámara","fr":"Appareil photo","it":"Fotocamera","ja":"カメラ","ko":"카메라","nl":"Camera","pl":"Aparat","sv":"Kamera","zh-Hans":"相机"},
 "Capture New": {"da":"Tag ny","de":"Neu aufnehmen","es":"Capturar nuevo","fr":"Nouvelle capture","it":"Acquisisci nuovo","ja":"新規撮影","ko":"새로 촬영","nl":"Nieuw vastleggen","pl":"Zrób nowe","sv":"Ta ny","zh-Hans":"拍摄新照片"},
 "Library": {"da":"Bibliotek","de":"Mediathek","es":"Biblioteca","fr":"Bibliothèque","it":"Libreria","ja":"ライブラリ","ko":"보관함","nl":"Bibliotheek","pl":"Biblioteka","sv":"Bibliotek","zh-Hans":"图库"},
 "Statistical Analysis": {"da":"Statistisk analyse","de":"Statistische Analyse","es":"Análisis estadístico","fr":"Analyse statistique","it":"Analisi statistica","ja":"統計分析","ko":"통계 분석","nl":"Statistische analyse","pl":"Analiza statystyczna","sv":"Statistisk analys","zh-Hans":"统计分析"},
 "String: %@": {"da":"Streng: %@","de":"Zeichenfolge: %@","es":"Cadena: %@","fr":"Chaîne : %@","it":"Stringa: %@","ja":"文字列: %@","ko":"문자열: %@","nl":"Tekenreeks: %@","pl":"Ciąg znaków: %@","sv":"Sträng: %@","zh-Hans":"字符串：%@"},
 "Tap to start barcode scanning": {"da":"Tryk for at starte stregkodescanning","de":"Tippen, um Barcode-Scan zu starten","es":"Toca para iniciar el escaneo de códigos de barras","fr":"Touchez pour démarrer la numérisation de codes-barres","it":"Tocca per avviare la scansione dei codici a barre","ja":"タップしてバーコードスキャンを開始","ko":"탭하여 바코드 스캔 시작","nl":"Tik om barcode scannen te starten","pl":"Dotknij, aby rozpocząć skanowanie kodów kreskowych","sv":"Tryck för att starta streckkodsskanning","zh-Hans":"点按以开始扫描条形码"},
 "Test Results": {"da":"Testresultater","de":"Testergebnisse","es":"Resultados de la prueba","fr":"Résultats du test","it":"Risultati del test","ja":"テスト結果","ko":"테스트 결과","nl":"Testresultaten","pl":"Wyniki testu","sv":"Testresultat","zh-Hans":"测试结果"},
 "This content is revealed when the card is expanded and shows additional details and information that can be shown or hidden.": {"da":"Dette indhold vises, når kortet udvides, og viser yderligere oplysninger, der kan vises eller skjules.","de":"Dieser Inhalt wird angezeigt, wenn die Karte erweitert wird, und zeigt zusätzliche Details und Informationen, die ein- oder ausgeblendet werden können.","es":"Este contenido se revela cuando la tarjeta se expande y muestra detalles e información adicionales que pueden mostrarse u ocultarse.","fr":"Ce contenu est révélé lorsque la carte est développée et affiche des détails et des informations supplémentaires pouvant être affichés ou masqués.","it":"Questo contenuto viene mostrato quando la scheda viene espansa e mostra dettagli e informazioni aggiuntivi che possono essere mostrati o nascosti.","ja":"このコンテンツは、カードを展開したときに表示され、表示/非表示が可能な追加の詳細と情報を示します。","ko":"이 콘텐츠는 카드가 확장될 때 표시되며 표시하거나 숨길 수 있는 추가 세부 정보와 정보를 보여줍니다.","nl":"Deze inhoud wordt weergegeven wanneer de kaart wordt uitgevouwen en toont aanvullende details en informatie die kan worden weergegeven of verborgen.","pl":"Ta treść jest ujawniana po rozwinięciu karty i pokazuje dodatkowe szczegóły i informacje, które można pokazać lub ukryć.","sv":"Detta innehåll visas när kortet expanderas och visar ytterligare detaljer och information som kan visas eller döljas.","zh-Hans":"此内容在卡片展开时显示，并显示可显示或隐藏的其他详细信息。"},
 "This content is revealed when the card is expanded and shows additional details and information.": {"da":"Dette indhold vises, når kortet udvides, og viser yderligere oplysninger.","de":"Dieser Inhalt wird angezeigt, wenn die Karte erweitert wird, und zeigt zusätzliche Details und Informationen.","es":"Este contenido se revela cuando la tarjeta se expande y muestra detalles e información adicionales.","fr":"Ce contenu est révélé lorsque la carte est développée et affiche des détails et des informations supplémentaires.","it":"Questo contenuto viene mostrato quando la scheda viene espansa e mostra dettagli e informazioni aggiuntivi.","ja":"このコンテンツは、カードを展開したときに表示され、追加の詳細と情報を示します。","ko":"이 콘텐츠는 카드가 확장될 때 표시되며 추가 세부 정보와 정보를 보여줍니다.","nl":"Deze inhoud wordt weergegeven wanneer de kaart wordt uitgevouwen en toont aanvullende details en informatie.","pl":"Ta treść jest ujawniana po rozwinięciu karty i pokazuje dodatkowe szczegóły i informacje.","sv":"Detta innehåll visas när kortet expanderas och visar ytterligare detaljer och information.","zh-Hans":"此内容在卡片展开时显示，并显示其他详细信息。"},
 "Type: %@": {"da":"Type: %@","de":"Typ: %@","es":"Tipo: %@","fr":"Type : %@","it":"Tipo: %@","ja":"タイプ: %@","ko":"유형: %@","nl":"Type: %@","pl":"Typ: %@","sv":"Typ: %@","zh-Hans":"类型：%@"},
 "Unknown Content": {"da":"Ukendt indhold","de":"Unbekannter Inhalt","es":"Contenido desconocido","fr":"Contenu inconnu","it":"Contenuto sconosciuto","ja":"不明なコンテンツ","ko":"알 수 없는 콘텐츠","nl":"Onbekende inhoud","pl":"Nieznana treść","sv":"Okänt innehåll","zh-Hans":"未知内容"},
 "Value": {"da":"Værdi","de":"Wert","es":"Valor","fr":"Valeur","it":"Valore","ja":"値","ko":"값","nl":"Waarde","pl":"Wartość","sv":"Värde","zh-Hans":"值"},
 "Value: %@": {"da":"Værdi: %@","de":"Wert: %@","es":"Valor: %@","fr":"Valeur : %@","it":"Valore: %@","ja":"値: %@","ko":"값: %@","nl":"Waarde: %@","pl":"Wartość: %@","sv":"Värde: %@","zh-Hans":"值：%@"},
 "Visualization Recommendations": {"da":"Visualiseringsanbefalinger","de":"Visualisierungsempfehlungen","es":"Recomendaciones de visualización","fr":"Recommandations de visualisation","it":"Consigli di visualizzazione","ja":"視覚化の推奨事項","ko":"시각화 권장 사항","nl":"Visualisatie-aanbevelingen","pl":"Rekomendacje wizualizacji","sv":"Visualiseringsrekommendationer","zh-Hans":"可视化建议"},
 "• Adaptive spacing": {"da":"• Tilpasset afstand","de":"• Adaptiver Abstand","es":"• Espaciado adaptable","fr":"• Espacement adaptatif","it":"• Spaziatura adattiva","ja":"• 適応型スペーシング","ko":"• 적응형 간격","nl":"• Adaptieve afstand","pl":"• Odstępy adaptacyjne","sv":"• Adaptivt avstånd","zh-Hans":"• 自适应间距"},
 "• Optimal component sizing": {"da":"• Optimal komponentstørrelse","de":"• Optimale Komponentengröße","es":"• Tamaño óptimo de componentes","fr":"• Dimensionnement optimal des composants","it":"• Dimensionamento ottimale dei componenti","ja":"• 最適なコンポーネントサイズ","ko":"• 최적의 구성 요소 크기","nl":"• Optimale componentgrootte","pl":"• Optymalny rozmiar komponentów","sv":"• Optimal komponentstorlek","zh-Hans":"• 最佳组件大小"},
 "• Platform-specific layouts": {"da":"• Platformspecifikke layout","de":"• Plattformspezifische Layouts","es":"• Diseños específicos de la plataforma","fr":"• Dispositions spécifiques à la plateforme","it":"• Layout specifici della piattaforma","ja":"• プラットフォーム固有のレイアウト","ko":"• 플랫폼별 레이아웃","nl":"• Platformspecifieke indelingen","pl":"• Układy specyficzne dla platformy","sv":"• Plattformsspecifika layouter","zh-Hans":"• 平台特定布局"},
 "Accessibility Testing": {"da":"Tilgængelighedstest","it":"Test di accessibilità"},
 "Confidence": {"da":"Tiltro","it":"Attendibilità"},
 "Array": {"zh-Hans":"数组","ko":"배열","ja":"配列","da":"Array","nl":"Array","sv":"Array"},
 "Email": {"zh-Hans":"电子邮件","ja":"メール","de":"E-Mail"},
 "Error": {"ja":"エラー","zh-Hans":"错误","es":"Error"},
 "Name": {"zh-Hans":"名称","da":"Navn","ko":"이름","de":"Name"},
 "Navigation": {"zh-Hans":"导航","ja":"ナビゲーション","ko":"탐색","de":"Navigation","fr":"Navigation"},
 "This content is revealed when the card is expanded.": {"da":"Dette indhold vises, når kortet udvides.","de":"Dieser Inhalt wird angezeigt, wenn die Karte erweitert wird.","es":"Este contenido se muestra cuando la tarjeta se expande.","fr":"Ce contenu est révélé lorsque la carte est développée.","it":"Questo contenuto viene mostrato quando la scheda viene espansa.","ja":"このコンテンツは、カードを展開したときに表示されます。","ko":"이 콘텐츠는 카드가 확장될 때 표시됩니다.","nl":"Deze inhoud wordt weergegeven wanneer de kaart wordt uitgevouwen.","pl":"Ta treść jest ujawniana po rozwinięciu karty.","sv":"Detta innehåll visas när kortet expanderas.","zh-Hans":"此内容在卡片展开时显示。"},
 "This content is revealed when the card is expanded. It can contain additional information, actions, or interactive elements.": {"da":"Dette indhold vises, når kortet udvides. Det kan indeholde yderligere oplysninger, handlinger eller interaktive elementer.","de":"Dieser Inhalt wird angezeigt, wenn die Karte erweitert wird. Er kann zusätzliche Informationen, Aktionen oder interaktive Elemente enthalten.","es":"Este contenido se muestra cuando la tarjeta se expande. Puede contener información adicional, acciones o elementos interactivos.","fr":"Ce contenu est révélé lorsque la carte est développée. Il peut contenir des informations supplémentaires, des actions ou des éléments interactifs.","it":"Questo contenuto viene mostrato quando la scheda viene espansa. Può contenere informazioni aggiuntive, azioni o elementi interattivi.","ja":"このコンテンツは、カードを展開したときに表示されます。追加情報、アクション、またはインタラクティブ要素を含む場合があります。","ko":"이 콘텐츠는 카드가 확장될 때 표시됩니다. 추가 정보, 작업 또는 대화형 요소를 포함할 수 있습니다.","nl":"Deze inhoud wordt weergegeven wanneer de kaart wordt uitgevouwen. Deze kan aanvullende informatie, acties of interactieve elementen bevatten.","pl":"Ta treść jest ujawniana po rozwinięciu karty. Może zawierać dodatkowe informacje, działania lub elementy interaktywne.","sv":"Detta innehåll visas när kortet expanderas. Det kan innehålla ytterligare information, åtgärder eller interaktiva element.","zh-Hans":"此内容在卡片展开时显示。它可以包含其他信息、操作或交互元素。"},
}


def main() -> int:
    data = json.loads(CATALOG.read_text(encoding="utf-8"))
    filled = skipped = 0
    problems = []
    for key, entry in data["strings"].items():
        if entry.get("shouldTranslate") is False:
            continue
        source = entry.get("localizations", {}).get("en", {}).get("stringUnit", {}).get("value", key)
        variants = T.get(source)
        if not variants:
            continue
        locs = entry.setdefault("localizations", {})
        for lang, text in list(variants.items()) + [
            (regional, variants[base])
            for regional, base in REGIONAL.items()
            if base in variants
        ]:
            if lang in locs:
                skipped += 1
                continue
            if sorted(spec(text)) != sorted(spec(source)):
                problems.append(f"{key!r} [{lang}]: specifiers {spec(text)} != {spec(source)}")
                continue
            locs[lang] = {"stringUnit": {"state": "needs_review", "value": text}}
            filled += 1
    if problems:
        print("\n".join(problems))
        return 1
    # Xcode-style serialization: sorted keys, two-space indent, " : " separators.
    with CATALOG.open("w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2, sort_keys=True)
        fh.write("\n")
    text = CATALOG.read_text(encoding="utf-8").replace('": ', '" : ').replace('",\n', '",\n')
    CATALOG.write_text(text, encoding="utf-8")
    print(f"filled {filled} slots, skipped {skipped} existing")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
