param (
    [switch]$b = $false,
    [switch]$r = $false,
    [switch]$h = $false
)

$Config = (Get-Content -Raw -Encoding UTF8 ./config/config.json) | ConvertFrom-Json
$ImageName = $Config.info.id
$ContainerName = "$($ImageName)-container"

# build
if ($b) {
    # update the OS name in the grub configuration file
    $GrubConfiguration = Get-Content -Raw -Encoding UTF8 ./targets/x86_64/iso/boot/grub/grub.cfg
    $GrubConfiguration = $GrubConfiguration -replace 'set \[name=\".*\"\]', ('set [name="' + $Config.info.name+ '"]')
    Out-File -FilePath ./targets/x86_64/iso/boot/grub/grub.cfg -InputObject $GrubConfiguration -Encoding UTF8

    # check if the container is already running, if not start it
    $IsRunning = $( docker container inspect -f '{{.State.Status}}' $ContainerName )
    if ($IsRunning -ne "running") {
        docker run -d --name $ContainerName --rm -v "${pwd}:/root/env" $ImageName
    }

    docker exec $ContainerName make build-x86_64
}

# run
if ($r) {
    qemu-system-x86_64 -cdrom dist/x86_64/kernel.iso
}

# no tags / help
if ($h -Or ((-Not $r) -And (-Not $b))) {
    Write-Host "use '-b' to build the iso file"
    Write-Host "use '-r' to run the iso file"
}