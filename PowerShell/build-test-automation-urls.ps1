# Testable outside of agent
function Set-CanvasTestAutomationURLs ($token, $url, $solutionName, $canvasAppsPath) {
    $filter = ".meta.xml"
    $canvasApps = Get-ChildItem $canvasAppsPath -Filter "*$filter"
    $asTestCase = "As TestCase"
    [System.Collections.ArrayList]$testUrls = @()
    $testUrlsObject = New-Object -TypeName PSObject
    $testUrlsObject | Add-Member -MemberType NoteProperty -Name TestURLs -Value $testUrls
    $hostUrl = Get-HostFromUrl $url

    foreach ($app in $canvasApps) {
        $appName = $app.Name.Replace($filter, "")        
        $appDirectory = $app.Directory.ToString()
        $appSrcDirectory = "$appDirectory\$appName" + "_DocumentUri_msapp_src\Src\Tests"
        $testFiles = Get-ChildItem $appSrcDirectory

        foreach ($testFile in $testFiles) {
            $lines = Get-Content $testFile.FullName

            foreach ($line in $lines) {                
                if ($line.Contains($asTestCase)) {
                    $testCaseId = $line.Split($asTestCase)[0].Replace("`"", "").Replace("'", "").Trim()
                    $testUrl = Get-CanvasAppPlayUrl $token $hostUrl $appName
                    $testUrl = "$testUrl&__PATestCaseId=$testCaseId&source=testStudioLink"
                    $testUrls.Add($testUrl)
                }
            }
        }
    }    
    $json = ConvertTo-Json $testUrlsObject
    Set-Content -Path "CanvasTestAutomationURLs.json" -Value $json -Force
    Get-Content -Path "CanvasTestAutomationURLs.json"
}

function Get-CanvasAppPlayUrl ($token, $hostUrl, $canvasName) {
    $odataQuery = 'canvasapps?$filter=name eq ''' + $canvasName + '''&$select=appopenuri'
    $response = Invoke-DataverseHttpGet $token $hostUrl $odataQuery
    return $response.value[0].appopenuri
}