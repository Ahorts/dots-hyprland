pragma Singleton  
import QtQuick  
import Quickshell.Io  
  
Singleton {  
    id: root  
      
    property string baseUrl: "https://api.unsplash.com"  
    property var apiKeys: KeyringStorage.keyringData?.apiKeys ?? {}  
      
    function fetch(query = "") {  
        const apiKey = apiKeys.wallpapers_unsplash;  
        if (!apiKey) return [];  
          
        // HTTP request implementation for Unsplash API  
        // Returns array of wallpaper objects  
    }  
}