# Get vPDC Racks
######################

# Determine cookie file path (reuse same logic as login)
if ($env:TEMP) {
    $cookieFile = Join-Path $env:TEMP "virtix_cookies.txt"
}
elseif ($env:TMP) {
    $cookieFile = Join-Path $env:TMP "virtix_cookies.txt"
}
elseif ($env:HOME) {
    $cookieFile = Join-Path $env:HOME "virtix_cookies.txt"
}
else {
    # Fallback to current directory if nothing else available
    $cookieFile = ".\virtix_cookies.txt"
}

Write-Host "Using cookie file path: $cookieFile"

# Check if cookie file exists
if (-Not (Test-Path $cookieFile)) {
    Write-Error "Cookie file not found: $cookieFile. Cannot proceed without session cookie."
    exit 1
}

# Read the cookie from file
$cookieContent = Get-Content -Path $cookieFile -ErrorAction Stop
# Example cookieContent: JSESSIONID=abc123
$cookiePair = $cookieContent.Trim()

# Prepare headers including cookie and accept
$headers = @{
    "Accept" = "application/json"
    "Cookie" = $cookiePair
}

try {
    # Create HttpClientHandler and HttpClient
    $handler = New-Object System.Net.Http.HttpClientHandler
    $client = New-Object System.Net.Http.HttpClient($handler)

    # Add headers to HttpClient
    foreach ($key in $headers.Keys) {
        $client.DefaultRequestHeaders.Add($key, $headers[$key])
    }

    # Send GET request to rack endpoint (no body)
    $response = $client.GetAsync("https://virtix.cloud/virtix-papi/v1/rack").Result

    if ($response.IsSuccessStatusCode) {
        Write-Host "API call successful!"

        # Read and parse JSON response body
        $respBody = $response.Content.ReadAsStringAsync().Result
        $json = $respBody | ConvertFrom-Json

        # Output racks nicely formatted
        $json | ConvertTo-Json -Depth 5 | Write-Host
    }
    else {
        Write-Error "API call failed with status code: $($response.StatusCode)"
        $errorBody = $response.Content.ReadAsStringAsync().Result
        Write-Error "Response body: $errorBody"
    }
}
catch {
    Write-Error "API call failed: $($_.Exception.Message)"
}

