<?php

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include "koneksi.php";


// Ambil data Postman

$temperatur = $_POST['temperatur'] ?? null;
$tds        = $_POST['tds'] ?? null;
$ph         = $_POST['ph'] ?? null;



// cek data

if(
    $temperatur === null ||
    $tds === null ||
    $ph === null
){

    echo json_encode([
        "status"=>false,
        "message"=>"Data sensor tidak lengkap"
    ]);

    exit;

}



// INSERT DATABASE

$sql = "
INSERT INTO sensor_readings
(
 temperatur,
 tds,
 ph,
 created_at,
 updated_at
)

VALUES
(
 ?,
 ?,
 ?,
 NOW(),
 NOW()
)
";


$stmt = $conn->prepare($sql);


$stmt->bind_param(
    "ddd",
    $temperatur,
    $tds,
    $ph
);



if($stmt->execute()){


    echo json_encode([

        "status"=>true,

        "message"=>"Data berhasil disimpan",

        "id"=>$stmt->insert_id

    ]);


}else{


    echo json_encode([

        "status"=>false,

        "message"=>"Gagal menyimpan",

        "error"=>$stmt->error

    ]);

}


$stmt->close();
$conn->close();

?>