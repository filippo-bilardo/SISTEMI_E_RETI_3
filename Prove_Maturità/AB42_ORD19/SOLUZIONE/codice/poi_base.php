<?php
// Pagina POI - tariffa base
// Riferimento: Prima Parte - Punto 3 (pagina base: video breve + max 3 immagini con didascalia)

require_once __DIR__ . '/config.php';

$poiId = isset($_GET['poi']) ? (int)$_GET['poi'] : 0;
$lang = isset($_GET['lang']) ? $_GET['lang'] : 'it';
if (!in_array($lang, ['it','en'], true)) {
  $lang = 'it';
}

if ($poiId <= 0) {
  http_response_code(400);
  echo 'Parametro poi non valido';
  exit;
}

$pdo = new PDO(DB_DSN, DB_USER, DB_PASS, [
  PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
]);

// Video base: italiano con sottotitoli EN (qui semplifico: seleziono media video_base in IT)
$videoStmt = $pdo->prepare("SELECT url FROM media WHERE poi_id = :poi AND kind = 'video_base' AND lang = 'it' ORDER BY sort_order LIMIT 1");
$videoStmt->execute([':poi' => $poiId]);
$videoUrl = $videoStmt->fetchColumn();

// Immagini base: max 3, caption in IT/EN
$imgStmt = $pdo->prepare("SELECT url, caption FROM media WHERE poi_id = :poi AND kind = 'image' AND lang = :lang ORDER BY sort_order LIMIT 3");
$imgStmt->execute([':poi' => $poiId, ':lang' => $lang]);
$images = $imgStmt->fetchAll(PDO::FETCH_ASSOC);

$nameStmt = $pdo->prepare("SELECT name FROM poi WHERE poi_id = :poi");
$nameStmt->execute([':poi' => $poiId]);
$poiName = $nameStmt->fetchColumn();

?><!doctype html>
<html lang="<?= htmlspecialchars($lang) ?>">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title><?= htmlspecialchars($poiName ?: 'POI') ?> - Pagina base</title>
  <style>
    body { font-family: system-ui, Arial, sans-serif; margin: 24px; }
    .wrap { max-width: 980px; margin: 0 auto; }
    header { display: flex; align-items: baseline; justify-content: space-between; gap: 16px; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 16px; }
    figure { margin: 0; border: 1px solid #ddd; border-radius: 10px; overflow: hidden; }
    figure img { width: 100%; height: 220px; object-fit: cover; display:block; }
    figcaption { padding: 10px 12px; font-size: 14px; color: #333; }
    video { width: 100%; border-radius: 10px; border: 1px solid #ddd; }
    .note { color:#555; font-size: 13px; }
  </style>
</head>
<body>
  <div class="wrap">
    <header>
      <h1><?= htmlspecialchars($poiName ?: ('POI #' . $poiId)) ?></h1>
      <div>
        <a href="?poi=<?= $poiId ?>&lang=it">IT</a> |
        <a href="?poi=<?= $poiId ?>&lang=en">EN</a>
      </div>
    </header>

    <p class="note">Pagina multimediale di base: video breve (IT + sottotitoli EN) e massimo 3 immagini.</p>

    <?php if ($videoUrl): ?>
      <h2>Video</h2>
      <video controls preload="metadata">
        <source src="<?= htmlspecialchars($videoUrl) ?>" type="video/mp4" />
        Il tuo browser non supporta il tag video.
      </video>
      <p class="note">Sottotitoli EN: gestibili con traccia VTT (non mostrata in questo estratto).</p>
    <?php else: ?>
      <p><strong>Video non disponibile</strong></p>
    <?php endif; ?>

    <h2>Immagini</h2>
    <div class="grid">
      <?php foreach ($images as $img): ?>
        <figure>
          <img src="<?= htmlspecialchars($img['url']) ?>" alt="" />
          <figcaption><?= htmlspecialchars($img['caption'] ?? '') ?></figcaption>
        </figure>
      <?php endforeach; ?>
    </div>
  </div>
</body>
</html>
