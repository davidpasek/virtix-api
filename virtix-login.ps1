# Login Technical User
######################

# Define credentials
$username = $env:VIRTIX_USERNAME.Trim()	# Good practice to trim
$password = $env:VIRTIX_PASSWORD.Trim() # Good practice to trim

# Encode the credentials using UTF-8 (best practice for Basic Auth)
$pair = "$username`:$password"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
$base64 = [Convert]::ToBase64String($bytes)

# Build the headers
# Include Authorization based on previous doc, and Content-Type for the empty body
$headers = @{
    "Accept"        = "application/json"
    "Authorization" = "Basic $base64"      # Keeping this as per previous doc
    "Content-Type"  = "application/json"   # <--- CRITICAL: Set Content-Type for POST request
}

# Send the request with an explicit empty JSON body
# The curl command sends an empty body, and the 415 suggests a type was expected.
# An empty JSON object `{}` is a valid JSON body that is empty.
$body = "{}"

try {
    $response = Invoke-RestMethod -Uri "https://virtix.cloud/virtix-papi/v1/user/login" -Headers $headers -Method POST -Body $body
    Write-Host "Login successful!"
    # $response # Display the response (e.g., cookie or session info)
    $VIRTIX_SESSION_ID=$response.id
    $VIRTIX_SESSION_ID # Display the VIRTIX SESSIOn ID
}
catch {
    Write-Error "Login failed: $($_.Exception.Message)"
    # Attempt to read the server's error response body for more details
    if ($_.Exception.Response) {
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseContent = $reader.ReadToEnd()
            Write-Error "Server response body: $responseContent"
        }
        catch {
            Write-Error "Could not read server response body: $($_.Exception.Message)"
        }
    }
}
