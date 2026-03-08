$token = "6db4d0af-ad0c-45da-9578-f417d61ddc8b"
$apiUrl = "https://backboard.railway.app/graphql/v2"

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

$deployQuery = @"
query {
  deployments(
    input: {
      projectId: "31b61dfd-e112-4c10-8680-3cbdc926b132"
    }
  ) {
    edges {
      node {
        id
        status
        createdAt
        meta
      }
    }
  }
}
"@

$body = @{ query = $deployQuery } | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body -ErrorAction Stop
    $edges = $response.data.deployments.edges
    
    # We will pick the top 1 newest deployment
    $dep = $edges[0].node
    Write-Output "=== Deployment: $($dep.id) ==="
    Write-Output "Message: $($dep.meta.commitMessage)"
    Write-Output "Status: $($dep.status)"
    
    $runLogQuery = @"
    query {
      deploymentLogs(
        deploymentId: "$($dep.id)"
      ) {
        message
        timestamp
      }
    }
"@
    $runLogBody = @{ query = $runLogQuery } | ConvertTo-Json -Depth 10
    $runLogResponse = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $runLogBody -ErrorAction Stop
    $runLogs = $runLogResponse.data.deploymentLogs
    
    if ($runLogs -and $runLogs.Count -gt 0) {
        Write-Output "`n=== Runtime Logs ==="
        $startIdx = [math]::Max(0, $runLogs.Count - 35)
        for ($j = $startIdx; $j -lt $runLogs.Count; $j++) {
            $log = $runLogs[$j]
            Write-Output "[$($log.timestamp)] $($log.message)"
        }
    } else {
        Write-Output "`n[No runtime logs yet. Container is likely still pending/building.]"
    }
        
    $buildLogQuery = @"
    query {
      buildLogs(
        deploymentId: "$($dep.id)"
      ) {
        message
        timestamp
      }
    }
"@
    $buildLogBody = @{ query = $buildLogQuery } | ConvertTo-Json -Depth 10
    $buildLogResponse = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $buildLogBody -ErrorAction Stop
    $buildLogs = $buildLogResponse.data.buildLogs
    
    if ($buildLogs -and $buildLogs.Count -gt 0) {
        Write-Output "`n=== Build Logs Tail ==="
        $startIdx = [math]::Max(0, $buildLogs.Count - 6)
        for ($j = $startIdx; $j -lt $buildLogs.Count; $j++) {
            $log = $buildLogs[$j]
            Write-Output "[$($log.timestamp)] $($log.message)"
        }
    }
    
} catch {
    Write-Error "Failed to connect to Railway API: $_"
}
