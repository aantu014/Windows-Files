'Description: This script backs up the Windows Services startup configuration to a REG file.
'For Windows 10, Windows Server 2016
'© 2016-2019  Ramesh Srinivasan
'Website: https://www.winhelponline.com/blog/
'Revised: Jul 07, 2019

Option Explicit
If WScript.Arguments.length = 0 Then
   Dim objShell : Set objShell = CreateObject("Shell.Application")
   objShell.ShellExecute "wscript.exe", Chr(34) & _
   WScript.ScriptFullName & Chr(34) & " uac", "", "runas", 1
Else   
   Dim WshShell, objFSO, strNow, intServiceType, intStartupType, strDisplayName, iSvcCnt
   Dim sREGFile, sBATFile, r, b, strComputer, objWMIService, colListOfServices, objService   
   Set WshShell = CreateObject("Wscript.Shell")
   Set objFSO = Wscript.CreateObject("Scripting.FilesystemObject")
   
   strNow = Year(Date) & Right("0" & Month(Date), 2) & Right("0" & Day(Date), 2)
   
   Dim objFile: Set objFile = objFSO.GetFile(WScript.ScriptFullName)  
   sREGFile = objFSO.GetParentFolderName(objFile) & "\svc_curr_state_" & strNow & ".reg"
   sBATFile = objFSO.GetParentFolderName(objFile) & "\svc_curr_state_" & strNow & ".bat"
   
   Set r = objFSO.CreateTextFile (sREGFile, True)
   r.WriteLine "Windows Registry Editor Version 5.00"
   r.WriteBlankLines 1
   r.WriteLine ";Services Startup Configuration Backup " & Now
   r.WriteBlankLines 1
   
   Set b = objFSO.CreateTextFile (sBATFile, True)
   b.WriteLine "@echo Restore Service Startup State saved at " & Now
   b.WriteBlankLines 1
   
   strComputer = "."
   iSvcCnt=0
   Dim sStartState, sSvcName, sSkippedSvc
   
   Set objWMIService = GetObject("winmgmts:" _
   & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
   
   Set colListOfServices = objWMIService.ExecQuery _
   ("Select * from Win32_Service")
   
   For Each objService In colListOfServices
      iSvcCnt=iSvcCnt + 1
      r.WriteLine "[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\" & trim(objService.Name) & "]"
      sStartState = lcase(objService.StartMode)
      sSvcName = objService.Name
      Select Case sStartState
         Case "boot"
         
         r.WriteLine chr(34) & "Start" & Chr(34) & "=dword:00000000"
         b.WriteLine "sc.exe config " & sSvcName & " start= boot"
         
         Case "system"
         r.WriteLine chr(34) & "Start" & Chr(34) & "=dword:00000001"
         b.WriteLine "sc.exe config " & sSvcName & " start= system"
         
         Case "auto"
         'Check if it's Automatic (Delayed start)
         r.WriteLine chr(34) & "Start" & Chr(34) & "=dword:00000002"     
         If objService.DelayedAutoStart = True Then
            r.WriteLine chr(34) & "DelayedAutostart" & Chr(34) & "=dword:00000001"
            b.WriteLine "sc.exe config " & sSvcName & " start= delayed-auto"
         Else
            r.WriteLine chr(34) & "DelayedAutostart" & Chr(34) & "=-"
            b.WriteLine "sc.exe config " & sSvcName & " start= auto"
         End If
         
         Case "manual"
         
         r.WriteLine chr(34) & "Start" & Chr(34) & "=dword:00000003"
         b.WriteLine "sc.exe config " & sSvcName & " start= demand"
         
         Case "disabled"
         
         r.WriteLine chr(34) & "Start" & Chr(34) & "=dword:00000004"
         b.WriteLine "sc.exe config " & sSvcName & " start= disabled"
         
         Case "unknown"	sSkippedSvc = sSkippedSvc & ", " & sSvcName
         'Case Else
      End Select
      r.WriteBlankLines 1
   Next
   
   If trim(sSkippedSvc) <> "" Then
      WScript.Echo iSvcCnt & " Services found. The services " & sSkippedSvc & " could not be backed up."
   Else
      WScript.Echo iSvcCnt & " Services found and their startup configuration backed up."
   End If
   
   r.Close
   b.WriteLine "@pause"
   b.Close
   WshShell.Run "notepad.exe " & sREGFile
   WshShell.Run "notepad.exe " & sBATFile
   Set objFSO = Nothing
   Set WshShell = Nothing
End If
