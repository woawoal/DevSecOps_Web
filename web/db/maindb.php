<?php

$host = 'localhost';
$db = 'LED_WG';
$user = 'root';
$pass = '1234';

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}


?>