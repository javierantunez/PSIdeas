# Initialize output paths for pot file append and for custom dictionary (ntlm.pw.txt)
[string] $outpathdictionary = "<PATH TO WRITE DICTIONARY>"
[string] $outpathpotfile = "<PATH TO WRITE POTFILE FORMATED OUTPUT>"

# Reads the hash dump file
[string[]]$allHashes = get-content <PATH OF HASHDUMP FILE TO BE PROCCESSED>
[string[]]$hashesNTLM = @()


# Extracts and deduplicate NTLM hashes
$hashesNTLM = $allHashes | %{($_ -split ":")[3]} | select -Unique 

# Prints information about number of unique hashes extracted and expected time to run in hours
Write-host "Hashes to be tested against ntlm.pw: " $hashesNTLM.count
Write-host "Expected time to check all hashes: " (((($hashesNTLM.Count)/1000/60)*20)) "hours"

# Initializes cicle counter
$counter=0
# Initializes threshold (ntlm.pw permits 1000 request in 15 minutes)
$threshold = 999
$waitseconds= 900
# Initializes arrays for new potfile lines and for hashes not found in ntlm.pw
[string[]]$newpassespotfile= @()
[string[]]$hashesNotFound= @()

# Cicle
foreach ($hashresult in $hashesNTLM)
{
    # Check current hash against ntlm.pw
    $request = Invoke-WebRequest https://ntlm.pw/$hashresult 
    # Check if content is not null (so password is found)
    if ($request.StatusCode -ne 204)
    {
        # Extracts password from request content
        $pass = $request | Select-Object -Expand Content
        # Prints the found password
        Write-host "Password found! : " $pass
        # Adds the hash plus password in potfile format to an acumulative array
        $newpassespotfile += $hashresult+":"+$pass
    }
    # Empty response = Password not found
    else
    {
        # Adds hash to an array of Not found hashes
        $hashesNotFound += $hashresult
    }
    $counter++
    # Threshold logic
    if ($counter -ge $threshold)
    {
        Write-host "Starting wait time..."
        # Waits the time limit before new batch of 1000 requests
        sleep $waitseconds
        Write-host "Continuing..."
        $counter = 0
    }
}
# Outputs
write-host "Number of passwords found: " $newpassespotfile.count
$newpassespotfile | select -Unique | sort | out-file $outpathpotfile -encoding ASCII -Append
$newpassespotfile | %{ ($_ -split ":")[1]} | select -Unique | sort | out-file $outpathdictionary -encoding ASCII -Append
