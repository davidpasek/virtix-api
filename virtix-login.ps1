# Login Technical User
######################

# Path to cookies data
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

Write-Host "Cookie file path: $cookieFile"

# Define credentials
$username = $env:VIRTIX_USERNAME.Trim()    # Good practice to trim
$password = $env:VIRTIX_PASSWORD.Trim()    # Good practice to trim

# Encode the credentials using UTF-8 (best practice for Basic Auth)
$pair = "$username`:$password"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
$base64 = [Convert]::ToBase64String($bytes)

# Build the headers except Content-Type (set on content, not headers)
$headers = @{
    "Accept"        = "application/json"
    "Authorization" = "Basic $base64"      # Keeping this as per previous doc
}

# JSON body for POST request
$body = "{}"

try {
    # Create HttpClient with CookieContainer to handle cookies automatically
    $cookieJar = New-Object System.Net.CookieContainer
    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.CookieContainer = $cookieJar
    $client = New-Object System.Net.Http.HttpClient($handler)

    # Prepare request content with JSON and UTF-8 encoding and Content-Type
    $content = New-Object System.Net.Http.StringContent($body, [System.Text.Encoding]::UTF8, "application/json")

    # Add headers except Content-Type
    foreach ($key in $headers.Keys) {
        $client.DefaultRequestHeaders.Add($key, $headers[$key])
    }

    # Send POST request to login endpoint
    $response = $client.PostAsync("https://virtix.cloud/virtix-papi/v1/user/login", $content).Result

    if ($response.IsSuccessStatusCode) {
        Write-Host "Login successful!"

        # Parse JSON response body
        $respBody = $response.Content.ReadAsStringAsync().Result
        $json = $respBody | ConvertFrom-Json
        $VIRTIX_SESSION_ID = $json.id
        Write-Host "Session ID: $VIRTIX_SESSION_ID"

        # Extract the JSESSIONID cookie from the cookie jar
        $cookies = $cookieJar.GetCookies([Uri] "https://virtix.cloud")
        foreach ($cookie in $cookies) {
            if ($cookie.Name -eq "JSESSIONID") {
                # Save JSESSIONID cookie value to file
                Set-Content -Path $cookieFile -Value "JSESSIONID=$($cookie.Value)"
                Write-Host "Saved cookie JSESSIONID to $cookieFile"
            }
        }
    }
    else {
        Write-Error "Login failed with status code: $($response.StatusCode)"
        $errorBody = $response.Content.ReadAsStringAsync().Result
        Write-Error "Response body: $errorBody"
    }
}
catch {
    Write-Error "Login failed: $($_.Exception.Message)"
}

