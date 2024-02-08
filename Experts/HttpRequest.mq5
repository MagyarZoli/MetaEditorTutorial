/*
```cmd
   C:\Apache24\bin>httpd -k install
```
*/

void SendDataToServer();

int OnInit() {
   Print("OnInit");
   return INIT_SUCCEEDED;
}

void OnTick() {
   SendDataToServer();
}

void SendDataToServer() {
   string cookie = NULL, headers; 
   char post[], result[]; 
   string url = "https://finance.yahoo.com"; 
   ResetLastError(); 
   int res = WebRequest("GET", url, cookie, NULL, 500, post, 0, result, headers); 
   if (res == -1) { 
      Print("Error in WebRequest. Error code = ", GetLastError()); 
      MessageBox("Add the address '" + url + "' to the list of allowed URLs on tab 'Expert Advisors'", "Error", MB_ICONINFORMATION); 
   } else { 
      if(res == 200) { 
         PrintFormat("The file has been successfully downloaded, File size %d byte.", ArraySize(result)); 
         int filehandle = FileOpen("url.htm", FILE_WRITE|FILE_BIN); 
         if (filehandle != INVALID_HANDLE) { 
            FileWriteArray(filehandle, result, 0, ArraySize(result)); 
            FileClose(filehandle); 
         } else Print("Error in FileOpen. Error code = ", GetLastError()); 
      } else PrintFormat("Downloading '%s' failed, error code %d", url, res); 
   } 
}