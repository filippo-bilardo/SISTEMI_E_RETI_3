<?php
// Quesito I (Seconda parte): media voti per ciascun POI

require_once __DIR__ . '/config.php';

$pdo = new PDO(DB_DSN, DB_USER, DB_PASS, [
  PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
]);

$stmt = $pdo->query('SELECT poi_id, name, avg_rating, votes FROM poi_rating_avg');
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

?><!doctype html>
<html lang="it">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Media voti POI</title>
  <style>
    body { font-family: system-ui, Arial, sans-serif; margin: 24px; }
    .wrap { max-width: 980px; margin: 0 auto; }
    table { width: 100%; border-collapse: collapse; }
    th, td { border-bottom: 1px solid #e5e5e5; padding: 10px; text-align:left; }
    th { background: #fafafa; }
    .num { text-align:right; font-variant-numeric: tabular-nums; }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Media voti ricevuti da ciascun POI</h1>
    <p>Seconda parte – Quesito I: visualizzazione media voti per POI (dati da tabella feedback).</p>

    <table>
      <thead>
        <tr>
          <th>POI</th>
          <th class="num">Media</th>
          <th class="num">N. voti</th>
        </tr>
      </thead>
      <tbody>
        <?php foreach ($rows as $r): ?>
          <tr>
            <td><?= htmlspecialchars($r['name']) ?></td>
            <td class="num"><?= $r['avg_rating'] !== null ? htmlspecialchars($r['avg_rating']) : '—' ?></td>
            <td class="num"><?= htmlspecialchars($r['votes']) ?></td>
          </tr>
        <?php endforeach; ?>
      </tbody>
    </table>
  </div>
</body>
</html>
