# Logout Technical User
#######################

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
    $response = Invoke-RestMethod -Uri "https://virtix.cloud/virtix-papi/v1/user/logout" -Headers $headers -Method POST -Body $body
    Write-Host "Logout successful!"
    $response # Display the response (e.g., cookie or session info)
}
catch {
    Write-Error "Logout failed: $($_.Exception.Message)"
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
