Fonction Stop-ADClientNodes {
    param ($domain)
    $computers = Get-ADComputer -Filter * -Properties PrimaryGroupID - Server $domain
    Foreach ($computer in $computers) {
        if ($computer.PrimaryGroupID -ne 516) {
            Stop-Computer -ComputerName $computer.Name
        }
    }
}