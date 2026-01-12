pragma Singleton  
import QtQuick  
import Quickshell.Io  
  
Singleton {  
    id: root  
      
    property string baseUrl: "https://wallhaven.cc/api/v1"  
      
    function fetch(query = "") {  
        // HTTP request implementation for Wallhaven API  
        // No API key required  
        // Returns array of wallpaper objects  
    }  
}