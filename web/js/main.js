const fetchData = async (url, method = 'GET', body = null) => {
    const options = {
        method: method,
        ...(method === 'POST' && {
            headers: {
                'Content-Type': 'application/json'
            },
            body: body ? JSON.stringify(body) : null
        })
    };

    const response = await fetch(url, options);
    
    // 응답 상태 코드 확인
    if (!response.ok) {
        throw new Error('Network response was not ok: ' + response.statusText);
        // console.error(JSON.stringify(response.error()));
    }

    // JSON 응답 처리
    const data = await response.json();
    return data;
}