#================================================================================================================
#
# Script Part    : Task Sequence Protect with AD
# Author 		 : Damien VAN ROBAEYS
# Twitter 		 : https://twitter.com/syst_and_deploy
# Blog 		     : http://www.systanddeploy.com/
#
#================================================================================================================

Param
(
	[string]$AD_Server,
	[string]$Group		
)				

[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')  				| out-null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 				| out-null
[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.dll')       				| out-null
[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.IconPacks.dll')       				| out-null

function LoadXml ($global:filename)
{
    $XamlLoader=(New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}

# Load MainWindow
$XamlMainWindow=LoadXml("TS_Password.xaml")
$Reader=(New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Form=[Windows.Markup.XamlReader]::Load($Reader)

########################################################################################################################################################################################################	
#*******************************************************************************************************************************************************************************************************
# 																		BUTTONS AND LABELS INITIALIZATION 
#*******************************************************************************************************************************************************************************************************
########################################################################################################################################################################################################

#************************************************************************** DATAGRID *******************************************************************************************************************
$Enter_TS = $form.FindName("Enter_TS")
$Typed_PWD = $form.FindName("Typed_PWD")
$Password_1 = $form.FindName("Password_1")
$Password_2 = $form.FindName("Password_2")
$Password_3 = $form.FindName("Password_3")
$Password_4 = $form.FindName("Password_4")
$Password_5 = $form.FindName("Password_5")
$Lock1 = $form.FindName("Lock1")
$Lock2 = $form.FindName("Lock2")
$Lock3 = $form.FindName("Lock3")
$Lock4 = $form.FindName("Lock4")
$Lock5 = $form.FindName("Lock5")
$Change_Theme = $form.FindName("Change_Theme")
$Typed_User = $form.FindName("Typed_User")
$Typed_PWD = $form.FindName("Typed_PWD")

$Script:TS_Status = $False
$Script:TS_PWD_Status = $False


If($AD_Server -eq "")
	{
		[System.Windows.Forms.MessageBox]::Show("Please specify the AD server parameter: -AD_Server", "Oops, Missing parameter")	 | out-null
		break
	}
	
If($Group -eq "")
	{
		[System.Windows.Forms.MessageBox]::Show("Please specify the authorized AD group parameter: -Group", "Oops, Missing parameter") | out-null
		$MonInterface.Activate()			
		break
	}	
	

Try
	{
		$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
		$Script:TS_PWD = $tsenv.value("TS_Password")		
		$Script:TS_Status = $True

	}
Catch
	{
		$Script:TS_Status = $False
		[System.Windows.Forms.MessageBox]::Show("Please check you're running a Task Sequence", "Oops, Task Sequence error")	
	}

If($TS_Status -eq $True)
	{
		Try
		{
			$TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
			$TSProgressUI.CloseProgressDialog()
			$TSProgressUI = $null
		}
		Catch
		{
		}		
	}

$AD_Module_Status = $False	
$module_name = "activedirectory"
Try
	{		
		If (!(Get-Module -listavailable | where {$_.name -like "*$module_name*"})) 
			{
				[System.Windows.Forms.MessageBox]::Show("The ActiveDirectory module does not exist.`Please check you have correctly integrated it into your boot image.", "Oops, ActiveDirectory module error")	
				Break
			}
		Else
			{
				Import-Module $module_name -ErrorAction SilentlyContinue
			}
		$AD_Module_Status = $True
	}
Catch
	{
		$AD_Module_Status = $False
		[System.Windows.Forms.MessageBox]::Show("An issue occured while importing the ActiveDirectory module.", "Oops, ActiveDirectory module error")			
		Break
	} 
	

$TS_Deploy_Group = $Group

	
$TS_Status = $true
	
$Enter_TS.Add_Click({
	If($TS_Status -eq $True)
		{
			$Get_User = $Typed_User.Text
			$Get_PWD = $Typed_PWD.Password	

			If(($Get_User -ne "") -and ($Get_PWD -ne ""))
				{
					$Script:PWD_Max_Test = 5	

					$User_PWD = ConvertTo-SecureString -String $Get_PWD -AsPlainText -Force
					$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Get_User, $User_PWD)
						
					$AD_User_Status = $False	
					Try
						{	
							$Get_AD_User_Name = Get-ADUser $Get_User -server $AD_Server	-Credential $Creds						
							$AD_User_Status = $True									
						}
					Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] 
						{		
							[System.Windows.Forms.MessageBox]::Show("The user $Get_User has not been found", "User not found")														
						}	
					Catch [Microsoft.ActiveDirectory.Management.ADServerDownException] 
						{		
							[System.Windows.Forms.MessageBox]::Show("Check the server name or IP configuration", "Error while contacting AD Server")	
						}
					Catch [System.Security.Authentication.AuthenticationException]		
						{		
							[System.Windows.Forms.MessageBox]::Show("Please check the admin user name or password", "Invalid credentials")										
						}					
					Catch 
						{		
							If($AD_Server -ne "") 
								{
									[System.Windows.Forms.MessageBox]::Show("Check the server name or IP configuration", "Error while contacting AD Server")								
								}
						}	
						

							
					If($AD_User_Status -eq $True)
						{
							$Get_User_Groups = (Get-ADPrincipalGroupMembership ($Get_AD_User_Name.SamAccountName) -server $AD_Server -Credential $Creds)	
							If($Get_User_Groups.SamAccountName -contains $TS_Deploy_Group)
								{
									$Script:Password_Status = $True
								}
							Else
								{
									$Script:Password_Status = $False
									[System.Windows.Forms.MessageBox]::Show("The specified user is not member of the group: $TS_Deploy_Group", "Unauthorized user")										
								}	
						}

					If($Password_Status -eq $True)
						{
							$Form.Close()
							$Bad_PWD_Count = $Bad_PWD_Count + 1
														
							switch ($Bad_PWD_Count) 
								{
									1 {
											$Password_1.Foreground="#00a300"
											$Password_1.Kind="LockOpenOutline"
											$Lock1.BorderBrush="#00a300"	
									  }
									2 { 
											$Password_2.Foreground="#00a300"
											$Password_2.Kind="LockOpenOutline"
											$Lock2.BorderBrush="#00a300"	
									  }
									3 { 
											$Password_3.Foreground="#00a300"
											$Password_3.Kind="LockOpen"
											$Lock3.BorderBrush="#00a300"		
									  }
									4 { 
											$Password_4.Foreground="#00a300"
											$Password_4.Kind="LockOpen"
											$Lock4.BorderBrush="#00a300"		
									  }
									5 { 
											$Password_5.Foreground="#00a300"
											$Password_5.Kind="LockOpen"
											$Lock5.BorderBrush="#00a300"		
									  }
								}					
						}
					Else
						{
							$Script:Password_Status = $False
							$Script:Bad_PWD_Count += 1
							If($PWD_Max_Test -le $Bad_PWD_Count)
								{	
									[System.Windows.Forms.MessageBox]::Show("You typed 5 bad passwords !!!`nYour computer will now exit the TS and reboot !!!", "Oops, Access denied")									
									$Script:Five_Bad_PWD = $True			
									$Form.Close()									
									Start-Process -FilePath "wpeutil" -ArgumentList "reboot"			
								}
							Else
								{
									$Script:Five_Bad_PWD = $False				
									switch ($Bad_PWD_Count) 
									{
										1 {
												$Password_1.Foreground="Red"
												$Lock1.BorderBrush="Red"										
										  }
										2 { 
												$Password_2.Foreground="Red"
												$Lock2.BorderBrush="Red"						
										  }
										3 { 
												$Password_3.Foreground="Red"
												$Lock3.BorderBrush="Red"						
										  }
										4 { 
												$Password_4.Foreground="Red"
												$Lock4.BorderBrush="Red"	
												[System.Windows.Forms.MessageBox]::Show("One last account attempt", "User account error")																		
										  }
										5 { 
												$Password_5.Foreground="Red"
												$Lock5.BorderBrush="Red"						
										  }
									}			
								}
						}				
				}
			Else
				{
					[System.Windows.Forms.MessageBox]::Show("Please type a user name and password !!!", "Oops, Something is missing")		
				}

		}
	Else
		{
			[System.Windows.Forms.MessageBox]::Show("Please check you're running a Task Sequence !!!", "Oops, Task Sequence error")		
		}
})


$MonInterface.Add_Closing({
	$_.Cancel = $true
	$MonInterface.Hide()	
})


$Form.Add_Closing({
	If($Password_Status -eq $True)		
		{
			[System.Windows.Forms.MessageBox]::Show("TS will continue to the next step", "TS Passord unlocked")		
		}
	ElseIf($Five_Bad_PWD -ne $True)	
		{
			$_.Cancel = $true	
			[System.Windows.Forms.MessageBox]::Show("You can not start the TS without the correct password !!!", "TS Passord required")		
		}
})


$Change_Theme.Add_Click({
	$Theme = [MahApps.Metro.ThemeManager]::DetectAppStyle($form)	
	$my_theme = ($Theme.Item1).name
	If($my_theme -eq "BaseLight")
		{
			[MahApps.Metro.ThemeManager]::ChangeAppStyle($form, $Theme.Item2, [MahApps.Metro.ThemeManager]::GetAppTheme("BaseDark"));	
		}
	ElseIf($my_theme -eq "BaseDark")
		{					
			[MahApps.Metro.ThemeManager]::ChangeAppStyle($form, $Theme.Item2, [MahApps.Metro.ThemeManager]::GetAppTheme("BaseLight"));			
		}		
})	


$Form.ShowDialog() | Out-Null
