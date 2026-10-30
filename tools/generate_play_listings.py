"""Write the reviewed, first-party Google Play listing copy. No network or uploads."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "docs" / "google-play" / "listings"

# Copy describes shipped behavior, rather than the aspirational DESIGN.md roadmap.
LISTINGS = [
    {
        "playLocale": "zh-CN", "appLanguage": "zh", "language": "简体中文", "region": "中国大陆（简体中文语言版本）",
        "title": "WearLoop 衣橱与穿搭记录",
        "short": "整理衣橱、保存搭配、记录每天穿什么，让喜欢的衣服反复出场。",
        "full": """好衣服，值得反复穿。

WearLoop 是一本放在手机里的衣橱手记。看看自己已经拥有什么，保存喜欢的组合，记录日常穿搭，让闲置的衣服重新出场。

整理你的衣橱
拍照或从相册添加衣物，记录分类、颜色、季节、品牌、价格和备注。按名称、品牌或备注搜索，结合分类筛选与排序，更快找到想穿的单品。

保存你的搭配
把单品组合成搭配，添加场景标签并收藏常用组合。选一套搭配记录今天的穿着，也可以自由选择单品或补记过去的日期。

了解自己的穿衣习惯
通过穿着日历、穿着次数、近 30 天利用率和单次成本，回顾衣橱的实际使用情况。可设置 14、30、60 或 90 天的闲置阈值，找回被遗忘的衣服。

在手机上识别衣物
内置的本地 AI 可从照片中识别并裁切服装单品。识别过程在设备上运行，照片不会为识别上传到服务器。保存前可以检查结果、取消选择并修改分类；识别不准确时可手动添加。

分享喜欢的穿搭
生成穿搭图片或复制文字，通过系统分享菜单自行选择分享对象。

无需注册，没有广告。衣橱数据保存在本机，核心功能可离线使用。首次打开提供可在设置中清除的示例衣橱。

支持 15 种界面语言，包括中文、日语、韩语、英语及阿拉伯语等。可跟随系统或手动选择；阿拉伯语和乌尔都语支持从右到左排版。价格金额目前使用人民币 CNY，不进行汇率换算。""",
        "notes": "全新衣架与叶片图标。新增 15 种界面语言、语言选择记忆以及阿拉伯语和乌尔都语 RTL 排版。优化小屏幕表单、日期与数字输入，保留现有衣橱数据。",
    },
    {
        "playLocale": "ja-JP", "appLanguage": "ja", "language": "日本語", "region": "日本",
        "title": "WearLoop クローゼットとコーデ記録",
        "short": "服を整理し、コーデを保存。毎日の着用記録から、お気に入りの服をもっと楽しもう。",
        "full": """お気に入りの服を、何度でも。

WearLoop は、手持ちの服と毎日のコーデを記録するクローゼットアプリです。持っている服を見渡し、好きな組み合わせを保存して、しばらく着ていない服も再発見できます。

手持ちの服を整理
カメラやアルバムから写真を追加し、カテゴリ、色、季節、ブランド、価格、メモを記録。名前・ブランド・メモの検索、カテゴリの絞り込み、並べ替えで服を探せます。

コーデを保存して着用を記録
服を組み合わせ、シーンのタグやお気に入りを設定。保存したコーデを着用記録に使うほか、単品を自由に選んだり、過去の日付を記録したりできます。

着方の習慣を振り返る
着用カレンダー、着用回数、過去 30 日間の活用率、1 回あたりのコストを確認できます。着ていない期間の目安を 14・30・60・90 日から選び、忘れていた服を見つけましょう。

端末内で服を認識
内蔵のローカル AI が写真から服を検出し、切り出します。認識は端末上で行い、そのために写真をサーバーへ送信しません。保存前に結果を確認し、選択の解除やカテゴリの修正が可能です。うまく認識できない場合は手動でも追加できます。

好きなコーデを共有
コーデ画像を作成したりテキストをコピーしたりして、端末の共有メニューから送り先を選べます。

アカウント登録も広告もありません。クローゼットのデータは端末に保存され、主な機能はオフラインで使えます。初回のサンプルデータは設定で削除できます。

日本語を含む 15 言語に対応。システム言語に合わせるか、自分で選択できます。アラビア語とウルドゥー語は右から左の表示に対応しています。価格は現在、中国人民元（CNY）で扱い、通貨換算は行いません。""",
        "notes": "ハンガーと葉の新しいアイコンになりました。15 言語、言語設定の保存、アラビア語・ウルドゥー語の右から左の表示に対応。小さな画面のフォーム、日付・数値入力を改善しました。既存のクローゼットデータは保持されます。",
    },
    {
        "playLocale": "ko-KR", "appLanguage": "ko", "language": "한국어", "region": "대한민국",
        "title": "WearLoop 옷장과 코디 기록",
        "short": "옷장을 정리하고 코디를 저장하세요. 매일의 착용 기록으로 좋아하는 옷을 더 자주 입어보세요.",
        "full": """좋아하는 옷을 더 자주 입는 즐거움.

WearLoop는 내 옷과 매일의 코디를 기록하는 옷장 앱입니다. 가진 옷을 한눈에 보고 마음에 드는 조합을 저장하며, 한동안 잊고 있던 옷도 다시 찾아보세요.

내 옷장 정리하기
카메라나 갤러리에서 사진을 추가하고 카테고리, 색상, 계절, 브랜드, 가격과 메모를 기록하세요. 이름·브랜드·메모 검색, 카테고리 필터와 정렬로 원하는 옷을 찾을 수 있습니다.

코디 저장과 착용 기록
여러 옷을 코디로 묶고 상황별 태그나 즐겨찾기를 설정하세요. 저장한 코디를 착용 기록에 사용하거나, 개별 옷을 자유롭게 골라 기록할 수 있습니다. 지난 날짜의 기록도 추가할 수 있어요.

옷 입는 습관 돌아보기
착용 달력, 착용 횟수, 최근 30일 활용률과 1회 착용 비용을 확인하세요. 잊힌 옷의 기준을 14·30·60·90일로 설정해 자주 입지 않는 옷을 다시 발견할 수 있습니다.

기기에서 옷 인식하기
내장된 로컬 AI가 사진 속 의류를 찾아 잘라냅니다. 인식은 기기에서 실행되며 이를 위해 사진을 서버로 전송하지 않습니다. 저장 전 결과를 확인하고 선택을 해제하거나 카테고리를 수정하세요. 인식이 정확하지 않을 때는 수동으로 추가할 수 있습니다.

좋아하는 코디 공유하기
코디 이미지를 만들거나 텍스트를 복사한 뒤 시스템 공유 메뉴에서 보낼 곳을 직접 선택하세요.

회원가입과 광고가 없습니다. 옷장 데이터는 기기에 저장되며 주요 기능은 오프라인으로 사용할 수 있습니다. 처음 제공되는 예시 옷장은 설정에서 삭제할 수 있습니다.

한국어를 포함한 15개 언어를 지원합니다. 시스템 언어를 따르거나 직접 선택할 수 있으며 아랍어와 우르두어는 오른쪽에서 왼쪽으로 표시됩니다. 가격은 현재 중국 위안화(CNY)로 표시하며 환율 변환은 하지 않습니다.""",
        "notes": "옷걸이와 잎 모양의 새 아이콘을 적용했습니다. 15개 언어, 언어 선택 저장, 아랍어·우르두어의 오른쪽에서 왼쪽 표시를 지원합니다. 작은 화면의 양식과 날짜·숫자 입력을 개선했으며 기존 옷장 데이터는 유지됩니다.",
    },
    {
        "playLocale": "en-US", "appLanguage": "en", "language": "English", "region": "United States",
        "title": "WearLoop: Outfit & Wardrobe",
        "short": "Organize your wardrobe, save outfits, and keep a daily wear journal.",
        "full": """Wear your favorites more often.

WearLoop is a wardrobe organizer and outfit journal for the clothes you already own. See what is in your wardrobe, save combinations you love, and rediscover pieces you have not worn in a while.

MAKE YOUR WARDROBE EASY TO FIND
Add clothing photos with your camera or gallery. Record categories, colors, seasons, brands, prices, and notes. Search names, brands, and notes, then filter by category or change the sort order.

SAVE OUTFITS AND RECORD WHAT YOU WEAR
Build outfits from your items, add occasion tags, and mark favorites. Log a saved outfit or choose individual pieces. You can also add entries for past dates.

UNDERSTAND YOUR WEAR HABITS
Explore your wear calendar, wear counts, wardrobe use over the last 30 days, and cost per wear. Choose a 14-, 30-, 60-, or 90-day threshold to find clothes you have been overlooking.

RECOGNIZE CLOTHING ON YOUR DEVICE
Built-in local AI detects and crops clothing items from photos. Recognition runs on your device; photos are not sent to a server for this process. Review results, deselect items, and edit categories before saving. You can add items manually whenever recognition misses something.

SHARE AN OUTFIT YOU LOVE
Create an outfit image or copy its text, then choose where to send it through your device's share menu.

No account and no ads. Your wardrobe data is stored on your device, and core features work offline. A sample wardrobe helps you get started and can be cleared in Settings.

Choose from 15 interface languages or follow your system language. Arabic and Urdu support right-to-left layouts. Price amounts currently use Chinese yuan (CNY); currency conversion is not provided.""",
        "notes": "Meet the new hanger-and-leaf icon. Added 15 interface languages, a saved language preference, and right-to-left layouts for Arabic and Urdu. Improved forms on small screens and localized date and number input. Existing wardrobe data is preserved.",
    },
    {
        "playLocale": "es-ES", "appLanguage": "es", "language": "Español", "region": "España",
        "title": "WearLoop: armario y conjuntos",
        "short": "Organiza tu armario, guarda conjuntos y registra la ropa que llevas cada día.",
        "full": """Dale más uso a tu ropa favorita.

WearLoop es un organizador de armario y un diario de conjuntos para la ropa que ya tienes. Revisa tus prendas, guarda combinaciones y redescubre lo que hace tiempo que no te pones.

ORGANIZA TU ARMARIO
Añade fotos con la cámara o desde la galería. Anota categoría, color, temporada, marca, precio y notas. Busca por nombre, marca o notas, filtra por categoría y elige cómo ordenar las prendas.

GUARDA CONJUNTOS Y REGISTRA LO QUE TE PONES
Combina prendas, añade etiquetas para distintas ocasiones y marca tus favoritos. Registra un conjunto guardado o selecciona prendas sueltas. También puedes añadir registros de fechas anteriores.

CONOCE TUS HÁBITOS
Consulta el calendario de uso, las veces que te has puesto cada prenda, el uso del armario en los últimos 30 días y el coste por uso. Elige un umbral de 14, 30, 60 o 90 días para encontrar prendas olvidadas.

RECONOCE PRENDAS EN TU DISPOSITIVO
La IA local integrada detecta y recorta prendas en las fotos. El reconocimiento se realiza en tu dispositivo, sin enviar las fotos a un servidor para ese proceso. Revisa los resultados, desmarca prendas y corrige categorías antes de guardar. Si el reconocimiento falla, puedes añadirlas manualmente.

COMPARTE TUS CONJUNTOS
Crea una imagen del conjunto o copia su texto y elige dónde compartirlo desde el menú del dispositivo.

Sin cuenta y sin anuncios. Los datos del armario se guardan en tu dispositivo y las funciones principales funcionan sin conexión. El armario de ejemplo inicial se puede borrar en Ajustes.

Elige entre 15 idiomas o sigue el idioma del sistema. El árabe y el urdu admiten la escritura de derecha a izquierda. Los precios utilizan actualmente yuanes chinos (CNY); no se realiza conversión de divisas.""",
        "notes": "Nuevo icono de percha y hoja. Añadidos 15 idiomas, la opción de recordar el idioma y diseños de derecha a izquierda para árabe y urdu. Mejoras en formularios de pantallas pequeñas y en la entrada de fechas y números. Se conservan los datos del armario.",
    },
    {
        "playLocale": "fr-FR", "appLanguage": "fr", "language": "Français", "region": "France",
        "title": "WearLoop : dressing et tenues",
        "short": "Organisez votre dressing, créez des tenues et notez vos vêtements portés.",
        "full": """Portez plus souvent les vêtements que vous aimez.

WearLoop réunit votre dressing et votre journal de tenues dans une application. Retrouvez les vêtements que vous possédez déjà, gardez vos associations préférées et redécouvrez les pièces délaissées.

ORGANISEZ VOTRE DRESSING
Ajoutez des photos avec l'appareil photo ou depuis la galerie. Renseignez catégorie, couleur, saison, marque, prix et notes. Recherchez par nom, marque ou notes, filtrez par catégorie et choisissez un ordre de tri.

CRÉEZ DES TENUES ET NOTEZ CE QUE VOUS PORTEZ
Assemblez vos pièces, ajoutez des étiquettes par occasion et marquez vos favoris. Enregistrez une tenue portée ou sélectionnez les pièces une à une. Vous pouvez aussi compléter les jours passés.

COMPRENEZ VOS HABITUDES
Consultez le calendrier, le nombre de ports, l'utilisation du dressing sur 30 jours et le coût par utilisation. Choisissez un seuil de 14, 30, 60 ou 90 jours pour retrouver les vêtements oubliés.

RECONNAISSANCE SUR VOTRE APPAREIL
L'IA locale intégrée détecte et recadre les vêtements présents sur vos photos. Le traitement s'effectue sur votre appareil, sans envoi des photos à un serveur pour la reconnaissance. Vérifiez les résultats, désélectionnez des pièces et corrigez les catégories avant l'enregistrement. L'ajout manuel reste disponible.

PARTAGEZ VOS TENUES
Créez une image ou copiez le texte d'une tenue, puis choisissez le destinataire dans le menu de partage de votre appareil.

Sans compte et sans publicité. Les données du dressing sont stockées sur votre appareil et les fonctions principales sont disponibles hors connexion. Le dressing d'exemple peut être effacé dans les réglages.

Choisissez parmi 15 langues ou suivez celle du système. L'arabe et l'ourdou bénéficient d'une présentation de droite à gauche. Les prix utilisent actuellement le yuan chinois (CNY), sans conversion de devises.""",
        "notes": "Nouvelle icône avec cintre et feuille. Ajout de 15 langues, mémorisation de la langue choisie et présentation de droite à gauche pour l'arabe et l'ourdou. Amélioration des formulaires sur petit écran et de la saisie des dates et nombres. Vos données sont conservées.",
    },
    {
        "playLocale": "de-DE", "appLanguage": "de", "language": "Deutsch", "region": "Deutschland",
        "title": "WearLoop: Kleiderschrank",
        "short": "Kleidung ordnen, Outfits speichern und täglich festhalten, was du trägst.",
        "full": """Trag deine Lieblingsstücke öfter.

WearLoop verbindet einen digitalen Kleiderschrank mit einem Outfit-Tagebuch. Behalte deine vorhandene Kleidung im Blick, speichere Kombinationen und entdecke lange nicht getragene Stücke wieder.

DEINEN KLEIDERSCHRANK ORDNEN
Füge Fotos mit der Kamera oder aus der Galerie hinzu. Erfasse Kategorie, Farbe, Saison, Marke, Preis und Notizen. Suche nach Namen, Marken oder Notizen, filtere nach Kategorien und ändere die Sortierung.

OUTFITS SPEICHERN UND TRAGEN DOKUMENTIEREN
Stelle Outfits zusammen, ergänze Anlass-Tags und markiere Favoriten. Trage ein gespeichertes Outfit ein oder wähle einzelne Kleidungsstücke aus. Auch vergangene Tage lassen sich nachtragen.

DEINE GEWOHNHEITEN VERSTEHEN
Sieh dir den Tragekalender, Tragehäufigkeiten, die Nutzung der letzten 30 Tage und die Kosten pro Tragen an. Wähle 14, 30, 60 oder 90 Tage als Grenze, um vergessene Kleidung zu finden.

KLEIDUNG AUF DEINEM GERÄT ERKENNEN
Die integrierte lokale KI erkennt Kleidungsstücke auf Fotos und schneidet sie zu. Die Erkennung läuft auf deinem Gerät; dafür werden keine Fotos an einen Server gesendet. Prüfe die Ergebnisse, entferne Auswahlen und passe Kategorien vor dem Speichern an. Bei unpassenden Ergebnissen kannst du Stücke manuell hinzufügen.

OUTFITS TEILEN
Erstelle ein Outfit-Bild oder kopiere den Text und wähle über das Teilen-Menü deines Geräts, wohin du es senden möchtest.

Ohne Konto und ohne Werbung. Deine Kleiderschrankdaten werden auf deinem Gerät gespeichert, die Hauptfunktionen sind offline nutzbar. Den anfangs enthaltenen Beispiel-Kleiderschrank kannst du in den Einstellungen löschen.

Wähle aus 15 Sprachen oder nutze die Systemsprache. Arabisch und Urdu unterstützen die Darstellung von rechts nach links. Preise werden derzeit in chinesischen Yuan (CNY) geführt; es findet keine Währungsumrechnung statt.""",
        "notes": "Neues Symbol mit Kleiderbügel und Blatt. Jetzt mit 15 Sprachen, gespeicherter Sprachauswahl und Rechts-nach-links-Layouts für Arabisch und Urdu. Formulare auf kleinen Bildschirmen sowie Datums- und Zahleneingaben wurden verbessert. Vorhandene Daten bleiben erhalten.",
    },
    {
        "playLocale": "vi", "appLanguage": "vi", "language": "Tiếng Việt", "region": "Việt Nam",
        "title": "WearLoop: Tủ đồ và phối đồ",
        "short": "Sắp xếp tủ đồ, lưu cách phối và ghi lại trang phục bạn mặc mỗi ngày.",
        "full": """Mặc những món đồ yêu thích thường xuyên hơn.

WearLoop giúp bạn quản lý tủ đồ và lưu nhật ký trang phục. Xem lại những món đã có, lưu cách phối yêu thích và tìm lại quần áo lâu chưa mặc.

SẮP XẾP TỦ ĐỒ
Thêm ảnh từ máy ảnh hoặc thư viện. Ghi danh mục, màu sắc, mùa, thương hiệu, giá và ghi chú. Tìm theo tên, thương hiệu hoặc ghi chú; lọc danh mục và đổi thứ tự sắp xếp.

LƯU CÁCH PHỐI VÀ GHI LẠI LẦN MẶC
Kết hợp các món đồ, thêm nhãn theo dịp và đánh dấu yêu thích. Ghi nhận một bộ đã lưu hoặc tự chọn từng món. Bạn cũng có thể bổ sung nhật ký cho những ngày trước.

HIỂU THÓI QUEN MẶC ĐỒ
Xem lịch mặc, số lần mặc, tỷ lệ sử dụng tủ đồ trong 30 ngày và chi phí mỗi lần mặc. Chọn mốc 14, 30, 60 hoặc 90 ngày để tìm các món bị bỏ quên.

NHẬN DIỆN NGAY TRÊN THIẾT BỊ
AI cục bộ tích hợp phát hiện và cắt ảnh từng món quần áo. Quá trình nhận diện chạy trên thiết bị, không gửi ảnh lên máy chủ để xử lý. Kiểm tra kết quả, bỏ chọn món và sửa danh mục trước khi lưu. Nếu nhận diện chưa đúng, bạn có thể thêm thủ công.

CHIA SẺ BỘ ĐỒ YÊU THÍCH
Tạo ảnh bộ đồ hoặc sao chép nội dung rồi chọn nơi gửi qua menu chia sẻ của thiết bị.

Không cần tài khoản, không có quảng cáo. Dữ liệu tủ đồ được lưu trên thiết bị; các chức năng chính dùng được ngoại tuyến. Bạn có thể xóa tủ đồ mẫu ban đầu trong phần Cài đặt.

Chọn một trong 15 ngôn ngữ giao diện hoặc dùng ngôn ngữ hệ thống. Tiếng Ả Rập và Urdu hỗ trợ bố cục từ phải sang trái. Giá hiện được ghi bằng nhân dân tệ Trung Quốc (CNY), không có chuyển đổi tiền tệ.""",
        "notes": "Biểu tượng mới hình móc áo và chiếc lá. Bổ sung 15 ngôn ngữ, lưu lựa chọn ngôn ngữ và bố cục từ phải sang trái cho tiếng Ả Rập, Urdu. Cải thiện biểu mẫu trên màn hình nhỏ cùng cách nhập ngày và số. Dữ liệu tủ đồ hiện có được giữ lại.",
    },
    {
        "playLocale": "hi-IN", "appLanguage": "hi", "language": "हिन्दी", "region": "भारत",
        "title": "WearLoop: कपड़े और पहनावे",
        "short": "कपड़े व्यवस्थित करें, पहनावे सहेजें और रोज़ क्या पहना, उसका रिकॉर्ड रखें।",
        "full": """अपने पसंदीदा कपड़े बार-बार पहनें।

WearLoop आपके कपड़ों को व्यवस्थित करने और रोज़ के पहनावे का रिकॉर्ड रखने में मदद करता है। देखें कि आपके पास क्या है, पसंदीदा जोड़ियाँ सहेजें और लंबे समय से न पहने गए कपड़ों को फिर से अपनाएँ।

अपने कपड़े व्यवस्थित करें
कैमरे या गैलरी से फ़ोटो जोड़ें। श्रेणी, रंग, मौसम, ब्रांड, कीमत और नोट लिखें। नाम, ब्रांड या नोट से खोजें, श्रेणी के अनुसार छाँटें और क्रम बदलें।

पहनावे सहेजें और रिकॉर्ड बनाएँ
कपड़ों को मिलाकर पहनावे बनाएँ, अवसर के टैग लगाएँ और पसंदीदा चुनें। सहेजा हुआ पहनावा दर्ज करें या अलग-अलग कपड़े चुनें। पिछली तारीखों का रिकॉर्ड भी जोड़ सकते हैं।

अपनी आदतें समझें
पहनने का कैलेंडर, कितनी बार पहना, पिछले 30 दिनों में कपड़ों का उपयोग और हर बार पहनने की लागत देखें। भूले हुए कपड़े खोजने के लिए 14, 30, 60 या 90 दिनों की सीमा चुनें।

डिवाइस पर कपड़ों की पहचान
ऐप का स्थानीय AI फ़ोटो में कपड़े पहचानकर उन्हें काटता है। पहचान आपके डिवाइस पर होती है; इस काम के लिए फ़ोटो सर्वर पर नहीं भेजी जातीं। सहेजने से पहले परिणाम जाँचें, कपड़े हटाएँ और श्रेणियाँ बदलें। पहचान सही न हो तो कपड़े खुद जोड़ सकते हैं।

पसंदीदा पहनावे साझा करें
पहनावे की तस्वीर बनाएँ या उसका टेक्स्ट कॉपी करें। फिर डिवाइस के शेयर मेन्यू से चुनें कि कहाँ भेजना है।

न खाते की ज़रूरत, न विज्ञापन। कपड़ों का डेटा आपके डिवाइस पर सहेजा जाता है और मुख्य सुविधाएँ ऑफ़लाइन चलती हैं। शुरुआत में मिले नमूना कपड़े सेटिंग में मिटाए जा सकते हैं।

15 इंटरफ़ेस भाषाओं में से चुनें या सिस्टम की भाषा इस्तेमाल करें। अरबी और उर्दू में दाएँ से बाएँ लेआउट उपलब्ध है। कीमतें अभी चीनी युआन (CNY) में हैं; मुद्रा का रूपांतरण नहीं होता।""",
        "notes": "हैंगर और पत्ती वाला नया आइकन। 15 भाषाएँ, भाषा का चुनाव सहेजने की सुविधा और अरबी व उर्दू के लिए दाएँ से बाएँ लेआउट जोड़े गए। छोटे पर्दों पर फ़ॉर्म तथा तारीख और संख्या दर्ज करना बेहतर किया गया। मौजूदा कपड़ों का डेटा सुरक्षित रहता है।",
    },
    {
        "playLocale": "ar", "appLanguage": "ar", "language": "العربية", "region": "العربية (دون تقييد بدولة واحدة)",
        "title": "WearLoop: خزانة وإطلالات",
        "short": "نظّم خزانة ملابسك، واحفظ إطلالاتك، وسجّل ما ترتديه كل يوم.",
        "full": """ارتدِ ملابسك المفضلة مرات أكثر.

يساعدك WearLoop على تنظيم خزانة ملابسك وتدوين إطلالاتك اليومية. تعرّف على ما تملكه، واحفظ التنسيقات التي تحبها، واكتشف من جديد قطعًا لم ترتدها منذ فترة.

نظّم خزانة ملابسك
أضف صورًا بالكاميرا أو من المعرض، وسجّل الفئة واللون والموسم والعلامة التجارية والسعر والملاحظات. ابحث بالاسم أو العلامة أو الملاحظات، وصفِّ حسب الفئة وغيّر ترتيب العرض.

احفظ الإطلالات وسجّل ما ترتديه
اجمع قطعك في إطلالات، وأضف وسوم المناسبات وحدّد المفضلة. سجّل إطلالة محفوظة أو اختر القطع منفردة. يمكنك أيضًا إضافة سجلات لأيام سابقة.

تعرّف على عاداتك
راجع تقويم الارتداء وعدد مرات ارتداء القطع، واستخدام الخزانة خلال آخر 30 يومًا، والتكلفة لكل مرة ارتداء. اختر حدًا من 14 أو 30 أو 60 أو 90 يومًا للعثور على الملابس المنسية.

تعرّف على الملابس على جهازك
يكتشف الذكاء الاصطناعي المحلي المدمج قطع الملابس في الصور ويقتصّها. تجري عملية التعرّف على جهازك، ولا تُرسل الصور إلى خادم لهذا الغرض. راجع النتائج وألغِ تحديد القطع وعدّل فئاتها قبل الحفظ. ويمكنك إضافة القطع يدويًا إذا كانت النتائج غير دقيقة.

شارك الإطلالات التي تحبها
أنشئ صورة للإطلالة أو انسخ نصها، ثم اختر وجهة الإرسال من قائمة المشاركة في جهازك.

لا حاجة إلى حساب، ولا توجد إعلانات. تُحفظ بيانات الخزانة على جهازك، وتعمل الميزات الأساسية دون اتصال. يمكنك حذف الخزانة التجريبية من الإعدادات.

اختر من بين 15 لغة للواجهة أو اتبع لغة النظام. تدعم العربية والأردية العرض من اليمين إلى اليسار. تُسجّل الأسعار حاليًا باليوان الصيني (CNY)، ولا يتوفر تحويل للعملات.""",
        "notes": "أيقونة جديدة تجمع علاقة ملابس وورقة شجر. أضفنا 15 لغة وحفظ تفضيل اللغة، مع تخطيط من اليمين إلى اليسار للعربية والأردية. حسّنا النماذج على الشاشات الصغيرة وإدخال التواريخ والأرقام. تبقى بيانات خزانة ملابسك الحالية محفوظة.",
    },
    {
        "playLocale": "bn-BD", "appLanguage": "bn", "language": "বাংলা", "region": "বাংলাদেশ",
        "title": "WearLoop: পোশাক ও সাজ",
        "short": "পোশাক গুছিয়ে রাখুন, পছন্দের সাজ সংরক্ষণ করুন আর রোজ কী পরেন তার হিসাব রাখুন।",
        "full": """পছন্দের পোশাক বারবার পরুন।

WearLoop আপনার পোশাক গুছিয়ে রাখতে এবং প্রতিদিনের সাজের ডায়েরি রাখতে সাহায্য করে। কী কী আছে দেখুন, পছন্দের পোশাকের সমন্বয় সংরক্ষণ করুন আর অনেক দিন না পরা পোশাক নতুন করে খুঁজে নিন।

পোশাক গুছিয়ে রাখুন
ক্যামেরা বা গ্যালারি থেকে ছবি যোগ করুন। ধরন, রং, ঋতু, ব্র্যান্ড, দাম ও নোট লিখে রাখুন। নাম, ব্র্যান্ড বা নোট দিয়ে খুঁজুন, ধরন অনুযায়ী ফিল্টার করুন এবং সাজানোর ক্রম বদলান।

সাজ সংরক্ষণ ও পরার হিসাব
বিভিন্ন পোশাক মিলিয়ে সাজ তৈরি করুন, উপলক্ষের ট্যাগ দিন এবং পছন্দের সাজ চিহ্নিত করুন। সংরক্ষিত সাজ বা আলাদা পোশাক বেছে পরার রেকর্ড রাখুন। আগের দিনের রেকর্ডও যোগ করতে পারেন।

নিজের অভ্যাস জানুন
পরার ক্যালেন্ডার, কতবার পরেছেন, গত ৩০ দিনে পোশাক ব্যবহারের হার এবং প্রতিবার পরার খরচ দেখুন। ভুলে যাওয়া পোশাক খুঁজতে ১৪, ৩০, ৬০ বা ৯০ দিনের সীমা বেছে নিন।

ডিভাইসেই পোশাক শনাক্ত করুন
অ্যাপের স্থানীয় AI ছবি থেকে পোশাক শনাক্ত করে কেটে নেয়। শনাক্তকরণ আপনার ডিভাইসেই হয়; এই কাজের জন্য ছবি কোনো সার্ভারে পাঠানো হয় না। সংরক্ষণের আগে ফলাফল দেখুন, নির্বাচন বাদ দিন ও ধরন সংশোধন করুন। ফল ঠিক না হলে নিজেও পোশাক যোগ করতে পারেন।

পছন্দের সাজ শেয়ার করুন
সাজের ছবি তৈরি করুন বা লেখা কপি করুন। তারপর ডিভাইসের শেয়ার মেনু থেকে কোথায় পাঠাবেন বেছে নিন।

অ্যাকাউন্ট বা বিজ্ঞাপন নেই। পোশাকের তথ্য আপনার ডিভাইসে থাকে এবং প্রধান সুবিধাগুলো অফলাইনে চলে। শুরুতে দেওয়া নমুনা পোশাক সেটিংস থেকে মুছে ফেলতে পারেন।

ইন্টারফেসের ১৫টি ভাষা থেকে বেছে নিন বা সিস্টেমের ভাষা ব্যবহার করুন। আরবি ও উর্দুতে ডান থেকে বাঁয়ে বিন্যাস রয়েছে। দাম বর্তমানে চীনা ইউয়ানে (CNY) রাখা হয়; মুদ্রা রূপান্তর করা হয় না।""",
        "notes": "হ্যাঙ্গার ও পাতার নতুন আইকন। ১৫টি ভাষা, ভাষার পছন্দ মনে রাখা এবং আরবি ও উর্দুর জন্য ডান থেকে বাঁয়ে বিন্যাস যোগ হয়েছে। ছোট পর্দায় ফর্ম এবং তারিখ ও সংখ্যা লেখা উন্নত হয়েছে। আগের পোশাকের তথ্য বজায় থাকে।",
    },
    {
        "playLocale": "pt-BR", "appLanguage": "pt", "language": "Português", "region": "Brasil",
        "title": "WearLoop: roupas e looks",
        "short": "Organize seu guarda-roupa, salve looks e registre o que você usa a cada dia.",
        "full": """Use suas peças favoritas mais vezes.

O WearLoop é um organizador de guarda-roupa e diário de looks para as roupas que você já tem. Veja suas peças, salve combinações e redescubra o que ficou esquecido.

ORGANIZE SEU GUARDA-ROUPA
Adicione fotos pela câmera ou galeria. Registre categoria, cor, estação, marca, preço e anotações. Busque por nome, marca ou anotações, filtre por categoria e altere a ordem das peças.

SALVE LOOKS E REGISTRE O USO
Combine suas peças, adicione etiquetas por ocasião e marque favoritos. Registre um look salvo ou escolha itens individuais. Você também pode preencher os dias anteriores.

ENTENDA SEUS HÁBITOS
Confira o calendário de uso, quantas vezes usou cada peça, o aproveitamento do guarda-roupa nos últimos 30 dias e o custo por uso. Escolha um limite de 14, 30, 60 ou 90 dias para encontrar roupas esquecidas.

RECONHEÇA ROUPAS NO SEU DISPOSITIVO
A IA local integrada identifica e recorta peças nas fotos. O reconhecimento acontece no dispositivo, sem enviar fotos a um servidor para esse processo. Revise os resultados, desmarque peças e ajuste categorias antes de salvar. Se o reconhecimento não acertar, você pode adicionar os itens manualmente.

COMPARTILHE SEUS LOOKS
Crie uma imagem do look ou copie seu texto e escolha onde enviar pelo menu de compartilhamento do dispositivo.

Sem conta e sem anúncios. Os dados do guarda-roupa ficam no seu dispositivo, e as funções principais funcionam offline. O guarda-roupa de exemplo pode ser apagado nas configurações.

Escolha entre 15 idiomas ou siga o idioma do sistema. Árabe e urdu têm layouts da direita para a esquerda. Os preços usam atualmente o yuan chinês (CNY), sem conversão de moedas.""",
        "notes": "Novo ícone de cabide e folha. Adicionados 15 idiomas, a opção de lembrar o idioma e layouts da direita para a esquerda para árabe e urdu. Melhorias nos formulários em telas pequenas e na entrada de datas e números. Os dados existentes são preservados.",
    },
    {
        "playLocale": "ru-RU", "appLanguage": "ru", "language": "Русский", "region": "Россия",
        "title": "WearLoop: гардероб и образы",
        "short": "Организуйте гардероб, сохраняйте образы и записывайте, что носите каждый день.",
        "full": """Носите любимые вещи чаще.

WearLoop помогает организовать гардероб и вести дневник образов. Посмотрите, какие вещи у вас уже есть, сохраните удачные сочетания и заново откройте одежду, которую давно не надевали.

НАВЕДИТЕ ПОРЯДОК В ГАРДЕРОБЕ
Добавляйте фото с камеры или из галереи. Указывайте категорию, цвет, сезон, бренд, цену и заметки. Ищите по названию, бренду или заметкам, фильтруйте по категории и выбирайте порядок сортировки.

СОХРАНЯЙТЕ ОБРАЗЫ И ОТМЕЧАЙТЕ, ЧТО НАДЕЛИ
Объединяйте вещи в образы, добавляйте теги по случаю и отмечайте избранное. Записывайте готовый образ или выбирайте отдельные вещи. Можно добавлять записи за прошедшие дни.

ИЗУЧАЙТЕ СВОИ ПРИВЫЧКИ
Смотрите календарь, количество выходов в каждой вещи, использование гардероба за последние 30 дней и стоимость одного выхода. Выберите срок 14, 30, 60 или 90 дней, чтобы находить забытые вещи.

РАСПОЗНАВАЙТЕ ОДЕЖДУ НА УСТРОЙСТВЕ
Встроенный локальный ИИ находит и вырезает предметы одежды на фотографиях. Обработка выполняется на устройстве; для распознавания фото не отправляются на сервер. Проверьте результат, снимите выбор с ненужных вещей и исправьте категории перед сохранением. Если распознавание ошиблось, вещи можно добавить вручную.

ДЕЛИТЕСЬ ОБРАЗАМИ
Создайте изображение образа или скопируйте текст и выберите получателя в системном меню отправки.

Без аккаунта и рекламы. Данные гардероба хранятся на устройстве, основные функции доступны без интернета. Начальный пример гардероба можно удалить в настройках.

Выбирайте один из 15 языков или используйте язык системы. Для арабского и урду предусмотрен интерфейс справа налево. Цены сейчас указаны в китайских юанях (CNY), без конвертации валют.""",
        "notes": "Новый значок с вешалкой и листом. Добавлены 15 языков, сохранение выбранного языка и интерфейс справа налево для арабского и урду. Улучшены формы на маленьких экранах и ввод дат и чисел. Данные гардероба сохраняются.",
    },
    {
        "playLocale": "ur", "appLanguage": "ur", "language": "اردو", "region": "اردو (پاکستان اور دیگر علاقے)",
        "title": "WearLoop: کپڑے اور انداز",
        "short": "کپڑے ترتیب دیں، پسندیدہ لباس کے امتزاج محفوظ کریں اور روز پہننے کا ریکارڈ رکھیں۔",
        "full": """اپنے پسندیدہ کپڑے زیادہ بار پہنیں۔

WearLoop آپ کے کپڑے ترتیب دینے اور روز کے لباس کا ریکارڈ رکھنے میں مدد کرتا ہے۔ دیکھیں کہ آپ کے پاس کیا ہے، پسندیدہ امتزاج محفوظ کریں اور وہ کپڑے دوبارہ دریافت کریں جو کافی عرصے سے نہیں پہنے۔

کپڑے ترتیب دیں
کیمرے یا گیلری سے تصاویر شامل کریں۔ زمرہ، رنگ، موسم، برانڈ، قیمت اور نوٹ درج کریں۔ نام، برانڈ یا نوٹ سے تلاش کریں، زمرے کے مطابق فلٹر کریں اور ترتیب بدلیں۔

لباس کے امتزاج اور پہننے کا ریکارڈ
مختلف کپڑوں سے امتزاج بنائیں، موقع کے ٹیگ لگائیں اور پسندیدہ نشان زد کریں۔ محفوظ امتزاج یا الگ الگ کپڑے منتخب کر کے پہننے کا ریکارڈ رکھیں۔ پچھلی تاریخوں کے اندراج بھی شامل کر سکتے ہیں۔

اپنی عادتیں جانیں
پہننے کا کیلنڈر، کتنی بار پہنا، گزشتہ 30 دنوں میں کپڑوں کا استعمال اور فی بار پہننے کی لاگت دیکھیں۔ بھولے ہوئے کپڑے تلاش کرنے کے لیے 14، 30، 60 یا 90 دن کی حد منتخب کریں۔

آلے پر کپڑوں کی شناخت
ایپ کی مقامی AI تصاویر میں کپڑے شناخت کر کے ان کے حصے کاٹتی ہے۔ شناخت آپ کے آلے پر ہوتی ہے؛ اس کام کے لیے تصاویر سرور پر نہیں بھیجی جاتیں۔ محفوظ کرنے سے پہلے نتائج دیکھیں، انتخاب ختم کریں اور زمرے درست کریں۔ نتائج درست نہ ہوں تو کپڑے خود شامل کر سکتے ہیں۔

پسندیدہ امتزاج شیئر کریں
لباس کی تصویر بنائیں یا اس کا متن کاپی کریں۔ پھر آلے کے شیئر مینو سے منتخب کریں کہ کہاں بھیجنا ہے۔

نہ اکاؤنٹ کی ضرورت، نہ اشتہارات۔ کپڑوں کا ڈیٹا آپ کے آلے پر محفوظ ہوتا ہے اور بنیادی سہولتیں آف لائن چلتی ہیں۔ شروع میں دیے گئے نمونہ کپڑے ترتیبات سے مٹائے جا سکتے ہیں۔

انٹرفیس کی 15 زبانوں میں سے منتخب کریں یا سسٹم کی زبان استعمال کریں۔ عربی اور اردو میں دائیں سے بائیں ترتیب موجود ہے۔ قیمتیں فی الحال چینی یوآن (CNY) میں ہیں؛ کرنسی تبدیل نہیں کی جاتی۔""",
        "notes": "ہینگر اور پتے والا نیا آئیکن۔ 15 زبانیں، زبان کا انتخاب یاد رکھنا اور عربی و اردو کے لیے دائیں سے بائیں ترتیب شامل کی گئی۔ چھوٹی اسکرینوں پر فارم اور تاریخ و عدد کا اندراج بہتر ہوا۔ کپڑوں کا موجودہ ڈیٹا برقرار رہتا ہے۔",
    },
    {
        "playLocale": "id", "appLanguage": "id", "language": "Bahasa Indonesia", "region": "Indonesia",
        "title": "WearLoop: Lemari & Outfit",
        "short": "Atur koleksi pakaian, simpan padu padan, dan catat outfit harianmu.",
        "full": """Pakai pakaian favoritmu lebih sering.

WearLoop adalah pengelola lemari pakaian dan jurnal outfit untuk pakaian yang sudah kamu miliki. Lihat koleksimu, simpan padu padan favorit, dan temukan kembali pakaian yang lama tidak dipakai.

ATUR LEMARI PAKAIANMU
Tambahkan foto dari kamera atau galeri. Catat kategori, warna, musim, merek, harga, dan catatan. Cari berdasarkan nama, merek, atau catatan, filter menurut kategori, dan ubah urutan tampilannya.

SIMPAN OUTFIT DAN CATAT PEMAKAIAN
Gabungkan pakaian menjadi outfit, tambahkan tag acara, dan tandai favorit. Catat outfit tersimpan atau pilih setiap item sendiri. Kamu juga bisa menambahkan catatan untuk hari sebelumnya.

PAHAMI KEBIASAAN BERPAKAIAN
Lihat kalender pemakaian, jumlah pemakaian, penggunaan koleksi selama 30 hari terakhir, dan biaya per pemakaian. Pilih batas 14, 30, 60, atau 90 hari untuk menemukan pakaian yang terlupakan.

KENALI PAKAIAN DI PERANGKATMU
AI lokal bawaan mendeteksi dan memotong gambar pakaian dari foto. Pengenalan berjalan di perangkatmu; foto tidak dikirim ke server untuk proses ini. Periksa hasilnya, batalkan pilihan, dan perbaiki kategori sebelum menyimpan. Jika hasilnya kurang tepat, kamu bisa menambahkan pakaian secara manual.

BAGIKAN OUTFIT FAVORIT
Buat gambar outfit atau salin teksnya, lalu pilih tujuan melalui menu berbagi perangkatmu.

Tanpa akun dan tanpa iklan. Data lemari disimpan di perangkatmu dan fitur utama dapat dipakai secara offline. Koleksi contoh awal bisa dihapus di Pengaturan.

Pilih dari 15 bahasa antarmuka atau ikuti bahasa sistem. Bahasa Arab dan Urdu mendukung tata letak dari kanan ke kiri. Harga saat ini menggunakan yuan Tiongkok (CNY), tanpa konversi mata uang.""",
        "notes": "Ikon baru berupa gantungan dan daun. Ditambahkan 15 bahasa, pilihan bahasa yang tersimpan, serta tata letak kanan ke kiri untuk bahasa Arab dan Urdu. Formulir di layar kecil serta input tanggal dan angka ditingkatkan. Data lemari yang ada tetap tersimpan.",
    },
]

def main():
    DEST.mkdir(parents=True, exist_ok=True)
    manifest = {
        "applicationId": "com.wearloop.wearloop",
        "version": "1.2.0",
        "defaultLocale": "en-US",
        "generatedAt": "2026-10-29",
        "sources": [
            "https://support.google.com/googleplay/android-developer/answer/9844778?hl=en",
            "https://support.google.com/googleplay/android-developer/answer/9859152?hl=en",
        ],
        "scope": "15 supported app languages mapped to Google Play's supported listing locales. Regions describe locale variants, not country availability or publication status. Same-language users elsewhere can receive the localized listing; selecting distribution countries is separate.",
        "translationReview": "Authored and checked for feature accuracy and field lengths; native-speaker review has not been completed.",
        "priceDisclosure": "All full descriptions disclose CNY pricing and lack of currency conversion.",
        "listings": [],
    }
    names = {"title":"title.txt", "short":"short-description.txt", "full":"full-description.txt", "notes":"release-notes.txt"}
    for listing in LISTINGS:
        path = DEST / listing["playLocale"]
        path.mkdir(exist_ok=True)
        counts = {}
        for key, filename in names.items():
            value = listing[key].strip()
            (path / filename).write_text(value + "\n", encoding="utf-8")
            counts[filename] = {"codePoints": len(value), "utf16Units":len(value.encode("utf-16-le"))//2}
        manifest["listings"].append({**{key:listing[key] for key in ("playLocale","appLanguage","language","region")}, "directory":listing["playLocale"], "characterCounts":counts})
    (DEST / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
    print(f"Wrote {len(LISTINGS)} localized listings under {DEST}")

if __name__ == "__main__":
    main()
