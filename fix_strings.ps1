$files = Get-ChildItem -Path "c:\Users\Varun\Documents\GitHub\SmartTube-Material\common\src\main\res" -Recurse -Filter "strings.xml"

foreach ($file in $files) {
    $content = Get-Content $file.FullName
    $newContent = @()
    $modified = $false

    foreach ($line in $content) {
        $newLine = $line

        if ($line -match 'name="auto_frame_rate_applying"') {
            # %sx%s\@%s -> %1$sx%2$s\@%3$s
            # We assume regular appearance order
            if ($newLine -match '%s.*%s.*%s') {
                 $parts = $newLine -split '%s'
                 if ($parts.Count -eq 4) {
                     $newLine = $parts[0] + "%1`$s" + $parts[1] + "%2`$s" + $parts[2] + "%3`$s" + $parts[3]
                     $modified = $true
                 }
            }
        }
        elseif ($line -match 'name="proxy_test_start"') {
            # %d...%s -> %1$d...%2$s
            if ($newLine -match '%d.*%s') {
                 $newLine = $newLine -replace '%d', '%1$d'
                 $newLine = $newLine -replace '%s', '%2$s'
                 $modified = $true
            }
        }
        elseif ($line -match 'name="proxy_test_error"') {
             # %d...%s -> %1$d...%2$s
            if ($newLine -match '%d.*%s') {
                 $newLine = $newLine -replace '%d', '%1$d'
                 $newLine = $newLine -replace '%s', '%2$s'
                 $modified = $true
            }
        }
        elseif ($line -match 'name="proxy_test_status"') {
            # %d...%s...%d...%s -> %1$d...%2$s...%3$d...%4$s
            # This is trickier with simple replace as order matters and types repeat
            # Split by tags is safer or matching exactly
            # Pattern: %d ... %s ... %d ... %s
             $parts = $newLine -split '(%d|%s)'
             # Parts will contain the delimiters.
             # Example: "Status #%d: %s %d %s" split by (%d|%s) -> "Status #", "%d", ": ", "%s", " ", "%d", " ", "%s", ""
             # We need to reconstruct
             if ($newLine -match 'name="proxy_test_status".*%d.*%s.*%d.*%s') {
                  # Using a counter
                  $c = 1
                  $newLine = [regex]::Replace($newLine, '(%d|%s)', { param($m) 
                    $res = "%" + $c + "$" + $m.Value.Substring(1)
                    $c++
                    return $res
                  })
                  $modified = $true
             }
        }

        $newContent += $newLine
    }

    if ($modified) {
        Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
        Write-Host "Updated $($file.FullName)"
    }
}
