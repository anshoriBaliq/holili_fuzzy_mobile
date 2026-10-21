<?php
header('Content-Type: application/json');

include 'koneksi.php';

$date = isset($_GET['date']) ? trim($_GET['date']) : null;
$limit = isset($_GET['limit']) ? (int) $_GET['limit'] : null;

if ($date !== null) {
    $parsedDate = DateTime::createFromFormat('Y-m-d', $date);
    $isValidDate = $parsedDate && $parsedDate->format('Y-m-d') === $date;

    if (!$isValidDate) {
        http_response_code(400);
        echo json_encode([
            'message' => 'invalid_date',
            'data' => [],
        ]);
        exit;
    }
}

if ($limit !== null) {
    $limit = max(1, min($limit, 5000));
}

$query = 'SELECT
            id,
            temperatur,
            tds,
            ph,
            created_at,
            updated_at
          FROM sensor_readings';

if ($date !== null) {
    $query .= ' WHERE DATE(created_at) = ?';
}

if ($limit !== null) {
    // Ambil N data terbaru, lalu balik kembali ke urutan kronologis.
    $query .= ' ORDER BY created_at DESC LIMIT ?';
} else {
    $query .= ' ORDER BY created_at ASC';
}

$stmt = $conn->prepare($query);

if (!$stmt) {
    http_response_code(500);
    echo json_encode([
        'message' => 'query_prepare_failed',
        'data' => [],
    ]);
    exit;
}

if ($date !== null && $limit !== null) {
    $stmt->bind_param('si', $date, $limit);
} elseif ($date !== null) {
    $stmt->bind_param('s', $date);
} elseif ($limit !== null) {
    $stmt->bind_param('i', $limit);
}

if (!$stmt->execute()) {
    http_response_code(500);
    echo json_encode([
        'message' => 'query_execution_failed',
        'data' => [],
    ]);
    exit;
}

$result = $stmt->get_result();
$data = [];

while ($row = $result->fetch_assoc()) {
    $data[] = $row;
}

if ($limit !== null) {
    $data = array_reverse($data);
}

echo json_encode([
    'message' => 'success',
    'data' => $data,
]);

$stmt->close();
$conn->close();
?>
