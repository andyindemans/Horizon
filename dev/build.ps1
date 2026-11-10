# powershell -ExecutionPolicy ByPass -File .\dev\build.ps1 [-i] [-l] [-o] [-p] [-s]

# first so `bash` is the one installed with `git`, avoid conflict with WSL
$env:Path = "C:\Program Files\Git\bin;" + $env:Path

bash ./dev/build.sh @args

exit $LASTEXITCODE
