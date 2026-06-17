$endpoint = "http://a27015f93e7954f5a9c4582a591c2211-318622494.eu-central-1.elb.amazonaws.com"

$body = @{
    model = "qwen"
    messages = @(
        @{
            role = "user"
            content = "What is 9+9?"
        }
    )
    max_tokens = 200
} | ConvertTo-Json -Depth 10

Write-Host "Sending request..."

try {
    $response = Invoke-WebRequest -Uri "$endpoint/openai/v1/chat/completions" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body

    Write-Host "Status: $($response.StatusCode)"
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
} catch {
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $errorBody = $reader.ReadToEnd()
    Write-Host "Error body: $errorBody"
}