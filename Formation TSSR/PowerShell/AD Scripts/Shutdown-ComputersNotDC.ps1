$computers = Get-ADComputer -Filter * -Properties PrimaryGroupID
Foreach ($computer in $computers) {
    if ($computer.PrimaryGroupID -ne 516) {
        Stop-Computer -ComputerName $computer.Name
      }
}