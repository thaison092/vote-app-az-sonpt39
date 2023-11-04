Workflow stop-start-vmss
{ 
    Param 
    (    
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
        [String] 
        $AzureSubscriptionId, 
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()] 
        [String] 
        $AzureVMList="All", 
        [Parameter(Mandatory=$true)][ValidateSet("Start","Stop")] 
        [String] 
        $Action 
    ) 
     
    # Ensures you do not inherit an AzContext in your runbook
    Disable-AzContextAutosave -Scope Process

    # Connect to Azure with system-assigned managed identity
    $AzureContext = (Connect-AzAccount -Identity).context

    # set and store context
    $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext 

    # get credential
    $credential = Get-AutomationPSCredential -Name "AzureCredential"

    # Connect to Azure with credential
    $AzureContext = (Connect-AzAccount -Credential $credential -TenantId $AzureContext.Subscription.TenantId).context 

    # set and store context
    $AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription `
        -TenantId $AzureContext.Subscription.TenantId `
        -DefaultProfile $AzureContext
 
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionNamenAsCon  
    $connectionName = "AzureRunAsConnection"
    try
    {
        "Logging in to Azure..."
        Add-AzureRmAccount `
            -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
        "Logged in."
    
    }
    catch {
        if (!$servicePrincipalConnection)
        {
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        } else{
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
    if($ResourceGroupName) {
        $VMs = Get-AzureRmVM - ResourceGroupName $ResourceGroupName
    }
    else {
        $VMs = Get-AzureRmVM
    }
    # Stop each of the VMs
    foreach ($VM in $VMs) {
        $StopRtn = $VM | Stop-AzureRmVM - Force -ErrorAction Continue
        if (!$StopRtn.IsSuccessStatusCode) {
            # The VM failed to stop, so send notice
            Write-Output ($VM.Name + " failed to stop")
            Write-Error ($VM.Name + " failed to stop. Error was:") -ErrorAction Continue 
            Write-Error (ConvertTo-Ison $StopRtn) -ErrorAction Continue
        }
        else {
            # The VM stopped, so send notice
            Write-Output ($VM.Name + " has been stopped")
        }
    }
    # if($AzureVMList -ne "All") 
    # { 
    #     $AzureVMs = $AzureVMList.Split(",") 
    #     [System.Collections.ArrayList]$AzureVMsToHandle = $AzureVMs 
    # } 
    # else 
    # { 
    #     $AzureVMs = (Get-AzVM -DefaultProfile $AzureContext).Name 
    #     [System.Collections.ArrayList]$AzureVMsToHandle = $AzureVMs 
    # } 
 
    # foreach($AzureVM in $AzureVMsToHandle) 
    # { 
    #     if(!(Get-AzVM -DefaultProfile $AzureContext | ? {$_.Name -eq $AzureVM})) 
    #     { 
    #         throw " AzureVM : [$AzureVM] - Does not exist! - Check your inputs " 
    #     } 
    # } 
 
    # if($Action -eq "Stop") 
    # { 
    #     Write-Output "Stopping VMs"; 
    #     foreach -parallel ($AzureVM in $AzureVMsToHandle) 
    #     { 
    #         Get-AzVM -DefaultProfile $AzureContext | ? {$_.Name -eq $AzureVM} | Stop-AzVM -DefaultProfile $AzureContext -Force 
    #     } 
    # } 
    # else 
    # { 
    #     Write-Output "Starting VMs"; 
    #     foreach -parallel ($AzureVM in $AzureVMsToHandle) 
    #     { 
    #         Get-AzVM -DefaultProfile $AzureContext | ? {$_.Name -eq $AzureVM} | Start-AzVM -DefaultProfile $AzureContext
    #     } 
    # } 
}