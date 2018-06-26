Configuration Main {
param
    #v1.4
   ( 
        [Parameter(Mandatory)]
        [String]$domainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$AdminCreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName xActiveDirectory, xNetworking, xPendingReboot
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${domainName}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager            
        {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true            
        } 

        WindowsFeature DNS 
        { 
            Ensure = "Present" 
            Name = "DNS"
        }

        WindowsFeature RSAT
        {
            Ensure = "Present"
            Name = "RSAT"
        }

        WindowsFeature ADDSInstall 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services"
        }  
		        WindowsFeature ADDSTools            
        {             
            Ensure = 'Present'             
            Name = 'RSAT-ADDS'             
        } 

        xADDomain FirstDC 
        {
            DomainName = $domainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "C:\NTDS"
            LogPath = "C:\NTDS"
            SysvolPath = "C:\SYSVOL"
            DependsOn = '[WindowsFeature]ADDSInstall'
        }

        xWaitForADDomain DscForestWait
        {
            DomainName = $domainName
            DomainUserCredential = $DomainCreds
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
            DependsOn = "[xADDomain]FirstDC"
        } 

        xPendingReboot Reboot1
        { 
            Name = "RebootServer"
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

   }
}