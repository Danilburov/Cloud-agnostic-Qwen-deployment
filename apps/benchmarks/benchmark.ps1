# ── config ──────────────────────────────────────────────────────────────
$eksEndpoint = "a6e6668657c1544fea1004b557d70d51-1351284507.eu-central-1.elb.amazonaws.com"
$bedrockModel = "qwen.qwen3-32b-v1:0"
$region = "eu-central-1"

# Pricing
$eksHourlyCost = 0.77   #t3.2xlarge costs, this should be changed if testing different instance types
$bedrockInputPer1k  = 0.00025  #per 1k input tokens
$bedrockOutputPer1k = 0.00125  #per 1k output tokens

$prompts = @(
    @{
        label = "Simple COBOL to Python"
        prompt = "Convert this COBOL code to Python: IDENTIFICATION DIVISION. PROGRAM-ID. HELLO. PROCEDURE DIVISION. DISPLAY 'Hello World'. STOP RUN."
    },
    @{
        label = "Refactor unreadable Java"
        prompt = "Refactor this Java code to be more readable, add proper variable names and comments: for(int i=0;i<arr.length;i++){if(arr[i]%2==0){sum+=arr[i];}}"
    },
    @{
        label = "BASIC to Python"
        prompt = "Convert this BASIC code to clean Python with proper variable names and comments: 010 LET X=0\n020 FOR I=1 TO 10\n030 LET X=X+I\n040 NEXT I\n050 PRINT X\n060 END"
    },
    @{
        label = "Complex COBOL to Python"
        prompt = "Convert this COBOL code to clean Python with proper variable names, functions and comments: IDENTIFICATION DIVISION. PROGRAM-ID. CALCULATE-TAX. DATA DIVISION. WORKING-STORAGE SECTION. 01 SALARY PIC 9(7)V99. 01 TAX-RATE PIC 9V99. 01 TAX-AMOUNT PIC 9(7)V99. PROCEDURE DIVISION. COMPUTE TAX-AMOUNT = SALARY * TAX-RATE. DISPLAY TAX-AMOUNT. STOP RUN."
    },
    @{
        label = "Legacy C to Python"
        prompt = "Convert this legacy C code to modern Python with proper error handling and comments: #include<stdio.h> int main(){int a[5]={1,2,3,4,5};int sum=0;int i;for(i=0;i<5;i++){sum=sum+a[i];}printf('%d',sum);return 0;}"
    }
)

$results = @()

foreach ($item in $prompts) {
    $label = $item.label
    $prompt = $item.prompt

    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host "Test: $label"
    Write-Host "Prompt: $prompt"
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    #EKS request
    $eksBody = @{
        model = "qwen"
        messages = @(@{ role = "user"; content = $prompt })
        max_tokens = 1000
    } | ConvertTo-Json -Depth 10

    $eksStart = Get-Date
    try {
        $eksResponse = Invoke-WebRequest `
            -Uri "$eksEndpoint/openai/v1/chat/completions" `
            -Method POST `
            -ContentType "application/json" `
            -Body $eksBody `
            -UseBasicParsing
        $eksEnd = Get-Date
        $eksLatency = ($eksEnd - $eksStart).TotalMilliseconds

        $eksParsed = $eksResponse.Content | ConvertFrom-Json
        $eksAnswer = $eksParsed.choices[0].message.content
        $eksInputTokens = $eksParsed.usage.prompt_tokens
        $eksOutputTokens = $eksParsed.usage.completion_tokens
        $eksTotalTokens = $eksParsed.usage.total_tokens

        $eksRequestsPerHour = 3600000 / $eksLatency
        $eksCostPerRequest  = $eksHourlyCost / $eksRequestsPerHour

        Write-Host "`n[EKS - Qwen2.5-1.5B on m5.4xlarge]"
        Write-Host "Answer: $eksAnswer"
        Write-Host "Latency: $([math]::Round($eksLatency))ms"
        Write-Host "Input tokens: $eksInputTokens"
        Write-Host "Output tokens: $eksOutputTokens"
        Write-Host "Total tokens: $eksTotalTokens"
        Write-Host "Cost/request: `$$([math]::Round($eksCostPerRequest, 6))"
    } catch {
        $eksLatency = -1
        $eksAnswer = "ERROR"
        $eksInputTokens = 0
        $eksOutputTokens = 0
        $eksTotalTokens = 0
        $eksCostPerRequest = 0
        Write-Host "[EKS] Error: $($_.Exception.Message)"
    }

    # ── Bedrock request ──────────────────────────────────────────────────
    $bedrockMessages = '[{"role":"user","content":[{"text":"' + ($prompt -replace '"', '\"') + '"}]}]'

    $bedrockStart = Get-Date
    try {
        $bedrockResponse = aws bedrock-runtime converse `
            --region $region `
            --model-id $bedrockModel `
            --messages $bedrockMessages | ConvertFrom-Json
        $bedrockEnd = Get-Date
        $bedrockLatency = ($bedrockEnd - $bedrockStart).TotalMilliseconds

        $bedrockAnswer = $bedrockResponse.output.message.content[0].text
        $bedrockInputTokens = $bedrockResponse.usage.inputTokens
        $bedrockOutputTokens = $bedrockResponse.usage.outputTokens
        $bedrockTotalTokens = $bedrockResponse.usage.totalTokens
        $bedrockApiLatency = $bedrockResponse.metrics.latencyMs

        $bedrockCostPerRequest = (($bedrockInputTokens / 1000) * $bedrockInputPer1k) + `
                                 (($bedrockOutputTokens / 1000) * $bedrockOutputPer1k)

        Write-Host "`n[Bedrock - Qwen3 32B]"
        Write-Host "Answer: $bedrockAnswer"
        Write-Host "Latency: $([math]::Round($bedrockLatency))ms (API: $($bedrockApiLatency)ms)"
        Write-Host "Input tokens: $bedrockInputTokens"
        Write-Host "Output tokens: $bedrockOutputTokens"
        Write-Host "Total tokens: $bedrockTotalTokens"
        Write-Host "Cost/request: `$$([math]::Round($bedrockCostPerRequest, 6))"
    } catch {
        $bedrockLatency = -1
        $bedrockAnswer = "ERROR"
        $bedrockInputTokens = 0
        $bedrockOutputTokens = 0
        $bedrockTotalTokens = 0
        $bedrockApiLatency = 0
        $bedrockCostPerRequest = 0
        Write-Host "[Bedrock] Error: $($_.Exception.Message)"
    }

    #store the results
    $results += [PSCustomObject]@{
        Label = $label
        Prompt = $prompt
        EKS_Model = "Qwen2.5-1.5B"
        EKS_Instance = "m5.4xlarge"
        EKS_Answer = $eksAnswer
        EKS_Latency_ms = [math]::Round($eksLatency)
        EKS_InputTokens = $eksInputTokens
        EKS_OutputTokens = $eksOutputTokens
        EKS_TotalTokens = $eksTotalTokens
        EKS_CostPerRequest = [math]::Round($eksCostPerRequest, 6)
        Bedrock_Model = "Qwen3-32B"
        Bedrock_Answer = $bedrockAnswer
        Bedrock_Latency_ms = [math]::Round($bedrockLatency)
        Bedrock_ApiLatency_ms = $bedrockApiLatency
        Bedrock_InputTokens = $bedrockInputTokens
        Bedrock_OutputTokens = $bedrockOutputTokens
        Bedrock_TotalTokens = $bedrockTotalTokens
        Bedrock_CostPerRequest = [math]::Round($bedrockCostPerRequest, 6)
    }
}

#summary
Write-Host "`n`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "SUMMARY"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$results | Select-Object Label, EKS_Latency_ms, Bedrock_Latency_ms, EKS_CostPerRequest, Bedrock_CostPerRequest | Format-Table -AutoSize

#cost at scale
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "COST AT SCALE (1000 requests/day)"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
$eksDailyCost = $eksHourlyCost * 24
$bedrockDailyCost = ($results | Measure-Object -Property Bedrock_CostPerRequest -Average).Average * 1000
Write-Host "EKS (always on):`$$([math]::Round($eksDailyCost, 2))/day (fixed)"
Write-Host "Bedrock (avg):`$$([math]::Round($bedrockDailyCost, 4))/day (variable)"

#export to file the results
$results | ConvertTo-Json -Depth 10 | Out-File "results.json"
$results | Export-Csv -Path "results.csv" -NoTypeInformation
Write-Host "`nResults saved to results.json and results.csv"
