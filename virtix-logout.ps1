# Logout Technical User
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
    Write-Error "Cookie file not found: $cookieFile. Cannot logout without session cookie."
    exit 1
}

# Read the cookie from file
$cookieContent = Get-Content -Path $cookieFile -ErrorAction Stop
# Example cookieContent: JSESSIONID=abc123
$cookiePair = $cookieContent.Trim()

# Prepare headers including cookie and content-type
$headers = @{
    "Accept"        = "application/json"
    "Content-Type"  = "application/json"
    "Cookie"        = $cookiePair
}

# Empty JSON body for logout
$body = "{}"

try {
    # Create HttpClientHandler and HttpClient
    $handler = New-Object System.Net.Http.HttpClientHandler
    $client = New-Object System.Net.Http.HttpClient($handler)

    # Prepare request content with JSON and UTF-8 encoding and Content-Type
    $content = New-Object System.Net.Http.StringContent($body, [System.Text.Encoding]::UTF8, "application/json")

    # Add headers to HttpClient except Content-Type (set on content)
    foreach ($key in $headers.Keys) {
        if ($key -ne "Content-Type") {
            $client.DefaultRequestHeaders.Add($key, $headers[$key])
        }
    }

    # Send POST request to logout endpoint
    $response = $client.PostAsync("https://virtix.cloud/virtix-papi/v1/user/logout", $content).Result

    if ($response.IsSuccessStatusCode) {
        Write-Host "Logout successful!"

        # Optionally remove the cookie file after logout
        Remove-Item -Path $cookieFile -ErrorAction SilentlyContinue
        Write-Host "Deleted cookie file: $cookieFile"
    }
    else {
        Write-Error "Logout failed with status code: $($response.StatusCode)"
        $errorBody = $response.Content.ReadAsStringAsync().Result
        Write-Error "Response body: $errorBody"
    }
}
catch {
    Write-Error "Logout failed: $($_.Exception.Message)"
}

