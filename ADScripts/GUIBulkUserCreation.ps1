$inputXML = @"
<Window x:Class="WpfApplication1.MainWindow"
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="UserCreation" Height="353" Width="595">
  <Grid> 
	<Label x:Name="label1" Content="Bulk User Creation" HorizontalAlignment="Left" Height="24" Margin="220,12,245,0" VerticalAlignment="Top" />
	<Label x:Name="label" Content="Select the input file" HorizontalAlignment="Left" Height="28" Margin="16,53,0,0"  VerticalAlignment="Top" Width="120" />
	<TextBox x:Name="InputFile" Margin="139,53,159,0"  IsEnabled="False" Height="28" VerticalAlignment="Top" />
	<Button x:Name="browse" Content="Browse" Height="28" HorizontalAlignment="Right" Margin="0,53,42,0"  VerticalAlignment="Top" Width="103"/>
        <Button Margin="188,95,200,0" x:Name="Create" Height="31" VerticalAlignment="Top" Content="Create the Users" />
        <TextBox x:Name="Output" Margin="22,141,28,38"  IsReadOnly="True" />
        <Label Height="26" Margin="156,0,156,8" x:Name="Copyright" VerticalAlignment="Bottom" Content="Copyright (c) Ajaz Ahmed 2017, Rights reserved" />
    </Grid>
</Window>

"@  
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
 
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
  try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."}
 
#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================
 
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "My$($_.Name)" -Value $Form.FindName($_.Name)}
 
 
#===========================================================================
# Actually make the objects work
#===========================================================================
$initialDirectory = "C:\"

Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

$MyOutput.text += "The creation has not yet started`r`n"

Function Create-Users {
$MyOutput.Text += "The creation has started...`r`n"
sleep 2
Import-CSV $MyInputFile.Text | ForEach {
    $userprincipalname = "$($_.SamAccountName)@Ahmedajaz.com"
    $DisplayName = $_.FirstName + " " + $_.LastName
    $Name = $_.FirstName + " " + $_.LastName
    $user = $_.SamAccountName
    $Homedrive = "H:"
    try
	{
	New-ADUser -SamAccountName $user -UserPrincipalName $userprincipalname -GivenName $_.FirstName -SurName $_.LastName -Name $Name -Displayname $Displayname -Description $_.Task -Office $_.Office -Company $_.Company -Homedrive $Homedrive -HomeDirectory $_.HomeDir -Path $_.OU -AccountPassword (ConvertTo-SecureString $_.Password -AsPlainText -Force) -Enabled $True -ChangePasswordAtLogon $True -PassThru -ErrorAction Stop
	$MyOutput.Text += "User $user created successfully`r`n"
    }
    catch
	{ 
	$MyOutput.Text += "User Exists already OR Error occurred in creating $user `r`n"
	}
       
}

Sleep 2
$MyOutput.Text += "The Script has completed successfully.`r`n"
}

$Mybrowse.Add_Click({

$MyInputFile.Text=Get-FileName


})
$Mycreate.Add_Click({

Create-Users
})


#Sample entry of how to add data to a field
 
#$vmpicklistView.items.Add([pscustomobject]@{'VMName'=($_).Name;Status=$_.Status;Other="Yes"})
 
#===========================================================================
# Shows the form
#===========================================================================

$Form.ShowDialog() | Out-Null
