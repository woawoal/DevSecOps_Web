<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LED TEAM 워게임 - Mission #9</title>
    <link href="https://fonts.googleapis.com/css2?family=Rajdhani:wght@400;600;700&family=Share+Tech+Mono&display=swap" rel="stylesheet">
    <style>
        :root {
            --neon-blue: #00f3ff;
            --neon-pink: #ff00ff;
            --neon-green: #00ff00;
            --dark-bg: #0a0a1f;
            --panel-bg: rgba(10, 10, 31, 0.8);
            --grid-color: rgba(0, 243, 255, 0.1);
        }
        
        * {margin:0;padding:0;box-sizing:border-box}
        
        body {
            background-color: var(--dark-bg);
            background-image: 
                linear-gradient(var(--grid-color) 1px, transparent 1px),
                linear-gradient(90deg, var(--grid-color) 1px, transparent 1px);
            background-size: 30px 30px;
            color: #fff;
            font-family: 'Rajdhani', sans-serif;
            min-height: 100vh;
        }

        .cyber-header {
            background: linear-gradient(45deg, rgba(255, 0, 255, 0.1), rgba(0, 243, 255, 0.1));
            padding: 30px 20px;
            text-align: center;
            border-bottom: 2px solid var(--neon-blue);
            position: relative;
            overflow: hidden;
        }

        .cyber-title {
            font-size: 3em;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 3px;
            animation: titlePulse 2s infinite;
        }

        .header-status {
            display: flex;
            justify-content: center;
            gap: 30px;
            margin-top: 15px;
            font-family: 'Share Tech Mono', monospace;
        }

        .status-item {
            color: var(--neon-blue);
        }

        .blink {
            animation: blink 1s infinite;
        }

        .cyber-container {
            max-width: 800px;
            margin: 30px auto;
            padding: 0 20px;
        }

        .upload-panel {
            background: var(--panel-bg);
            border: 1px solid var(--neon-blue);
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 
                0 0 10px rgba(0, 243, 255, 0.2),
                inset 0 0 20px rgba(0, 243, 255, 0.1);
        }

        .panel-header {
            background: rgba(0, 0, 0, 0.4);
            padding: 15px;
            border-bottom: 1px solid var(--neon-blue);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .controls {
            display: flex;
            gap: 8px;
        }

        .ctrl-btn {
            width: 12px;
            height: 12px;
            border-radius: 50%;
        }

        .ctrl-btn.red { background: #ff5f56; }
        .ctrl-btn.yellow { background: #ffbd2e; }
        .ctrl-btn.green { background: #27c93f; }

        .panel-title {
            color: var(--neon-blue);
            font-size: 1.2em;
            letter-spacing: 2px;
            font-family: 'Share Tech Mono', monospace;
        }

        .upload-form {
            padding: 30px;
            text-align: center;
        }

        input[type="file"] {
            display: none;
        }

        .file-label {
            display: inline-block;
            padding: 12px 30px;
            background: rgba(0,243,255,0.1);
            border: 1px solid var(--neon-blue);
            color: var(--neon-blue);
            cursor: pointer;
            margin: 15px 0;
            transition: all 0.3s;
            font-family: 'Share Tech Mono', monospace;
        }

        .file-label:hover {
            background: rgba(0,243,255,0.2);
            box-shadow: 0 0 15px rgba(0,243,255,0.5);
            transform: translateY(-2px);
        }

        button {
            background: rgba(255,0,255,0.1);
            border: 1px solid var(--neon-pink);
            color: var(--neon-pink);
            padding: 12px 40px;
            cursor: pointer;
            transition: all 0.3s;
            font-family: 'Share Tech Mono', monospace;
            text-transform: uppercase;
            letter-spacing: 2px;
            position: relative;
            overflow: hidden;
        }

        button:hover {
            background: rgba(255,0,255,0.2);
            box-shadow: 0 0 15px rgba(255,0,255,0.5);
            transform: translateY(-2px);
        }

        button::after {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(
                90deg,
                transparent,
                rgba(255, 255, 255, 0.2),
                transparent
            );
            animation: buttonGlitch 2s infinite;
        }

        .message {
            margin: 20px;
            padding: 15px;
            border-radius: 4px;
            text-align: center;
            font-family: 'Share Tech Mono', monospace;
        }

        .success {
            background: rgba(0,255,0,0.1);
            border: 1px solid var(--neon-green);
            color: var(--neon-green);
        }

        .error {
            background: rgba(255,0,0,0.1);
            border: 1px solid var(--neon-pink);
            color: var(--neon-pink);
        }

        @keyframes titlePulse {
            0%, 100% { text-shadow: 0 0 5px var(--neon-blue), 0 0 10px var(--neon-blue), 0 0 20px var(--neon-pink); }
            50% { text-shadow: 0 0 10px var(--neon-blue), 0 0 20px var(--neon-blue), 0 0 30px var(--neon-pink); }
        }

        @keyframes blink {
            0%, 100% { opacity: 1; }
            50% { opacity: 0; }
        }

        @keyframes buttonGlitch {
            0% { transform: translateX(-100%); }
            50%, 100% { transform: translateX(100%); }
        }
    </style>
</head>
<body>
    <header class="cyber-header">
        <h1 class="cyber-title">MISSION #9: FILE UPLOAD</h1>
        <div class="header-status">
            <div class="status-item">SYSTEM: ACTIVE</div>
            <div class="status-item">SECURITY: TESTING</div>
            <div class="status-item blink">STATUS: WAITING...</div>
        </div>
    </header>

    <div class="cyber-container">
        <div class="upload-panel">
            <div class="panel-header">
                <div class="controls">
                    <span class="ctrl-btn red"></span>
                    <span class="ctrl-btn yellow"></span>
                    <span class="ctrl-btn green"></span>
                </div>
                <span class="panel-title">FILE UPLOAD INTERFACE</span>
            </div>
            <form class="upload-form" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']); ?>" method="post" enctype="multipart/form-data">
                <label class="file-label" for="file">
                    SELECT FILE
                    <input type="file" name="file" id="file" required>
                </label>
                <br>
                <button type="submit">UPLOAD</button>
            </form>

            <?php
            error_reporting(0);
            $uploadDir = 'uploads/';
            if (!file_exists($uploadDir)) mkdir($uploadDir, 0777, true);

            if ($_SERVER['REQUEST_METHOD'] === 'POST') {
                if (!isset($_FILES['file']) || $_FILES['file']['error'] === UPLOAD_ERR_NO_FILE) {
                    echo "<div class='message error'>[ ERROR ] 파일을 선택해주세요.</div>";
                } else {
                    $filename = basename($_FILES['file']['name']);
                    $targetFilePath = $uploadDir . $filename;
                    
                    if (move_uploaded_file($_FILES['file']['tmp_name'], $targetFilePath)) {
                        @chmod($targetFilePath, 0777);
                        echo "<div class='message success'>[ SUCCESS ] 파일 " . htmlspecialchars($filename) . " 업로드 완료!</div>";
                        echo "<div class='message'>[ INFO ] 파일 경로: " . htmlspecialchars($targetFilePath) . "</div>";
                    } else {
                        echo "<div class='message error'>[ ERROR ] 업로드 실패. 파일 권한을 확인하세요. 주소창에서</div>";
                    }
                }
            }
            ?>
        </div>
    </div>
</body>
</html>
