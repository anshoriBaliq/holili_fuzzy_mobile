<?php

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

include "koneksi.php";

$query = "SELECT 
            id,
            date,
            time_start,
            time_end,
            avg_temperature,
            avg_ppm,
            avg_water_level,
            created_at,
            updated_at
          FROM history_logs
          ORDER BY id DESC
          LIMIT 10";

$result = mysqli_query($conn, $query);

$data = [];

if ($result) {

    while ($row = mysqli_fetch_assoc($result)) {
        $data[] = $row;
    }

    echo json_encode([
        "message" => "success",
        "data" => $data
    ]);

} else {

    echo json_encode([
        "message" => "error",
        "error" => mysqli_error($conn)
    ]);
}
?>