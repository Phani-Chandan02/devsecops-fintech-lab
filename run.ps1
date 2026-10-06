param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath
)

$bashExe = "C:\Program Files\Git\usr\bin\bash.exe"
$pyPath = "/c/Users/phani/AppData/Local/Programs/Python/Python311:/c/Users/phani/AppData/Local/Programs/Python/Python311/Scripts"
$envPath = "${pyPath}:/c/Users/phani/AppData/Local/Programs/Amazon/AWSCLIV2:/usr/bin:`$PATH"
$scriptUnix = $ScriptPath.Replace("\", "/")

& $bashExe -c "export PATH='$envPath'; ./$scriptUnix"
