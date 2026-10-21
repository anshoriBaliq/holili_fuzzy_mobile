<?php

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: *");
header("Access-Control-Allow-Methods: *");
header("Content-Type: application/json; charset=UTF-8");

$host = "localhost";
$user = "root";
$password = "";
$database = "aqua_scape";

$conn = new mysqli(
    $host,
    $user,
    $password,
    $database
);

if ($conn->connect_error) {

    http_response_code(500);

    echo json_encode([
        "status" => false,
        "message" => "Koneksi database gagal",
        "error" => $conn->connect_error
    ]);

    exit;
}