import qs  
import qs.services  
import qs.modules.common  
import qs.modules.common.widgets  
import qs.modules.common.functions  
import qs.modules.ii.sidebarLeft.wallpaperBrowser  
import QtQuick  
import QtQuick.Controls  
import QtQuick.Layouts  
import Qt5Compat.GraphicalEffects  
import Quickshell  
  
Item {  
    id: root  
    property real padding: 4  
    property var inputField: searchInputField  
    property string commandPrefix: "/"  
    property string currentService: WallpaperBrowser.currentProvider ?? "unsplash"  
    property var suggestionQuery: ""  
    property var suggestionList: []  
      
    // Exact same pattern as Anime  
    readonly property var responses: WallpaperBrowser.responses  
    property int lastResponseLength: 0  
      
    // Download paths  
    property string previewDownloadPath: Config.options?.downloads?.previewPath ?? `${SystemInfo.homeDir}/.cache/wallpapers/previews`  
    property string downloadPath: Config.options?.downloads?.wallpaperPath ?? `${SystemInfo.homeDir}/Pictures/Wallpapers`  
    property string nsfwPath: Config.options?.downloads?.nsfwPath ?? `${SystemInfo.homeDir}/Pictures/Wallpapers/NSFW`  
      
    // Pagination properties  
    property real scrollOnNewResponse: 100  
    property real pullLoadingGap: 100  
    property bool pullLoading: false  
    property real normalizedPullDistance: 0  
      
    onFocusChanged: focus => {  
        if (focus) {  
            root.inputField.forceActiveFocus();  
        }  
    }  
      
    ColumnLayout {  
        anchors.fill: parent  
        spacing: 10  
          
        PagePlaceholder {  
            id: placeholderItem  
            shown: root.responses.length === 0  
            icon: "wallpaper"  
            title: Translation.tr("Wallpapers")  
            description: Translation.tr("Browse wallpapers from Unsplash and Wallhaven")  
            shape: MaterialShape.Shape.Bun  
            Layout.fillWidth: true  
            Layout.fillHeight: true  
        }  
          
        Item {  
            Layout.fillWidth: true  
            Layout.fillHeight: true  
              
            layer.enabled: true  
            layer.effect: OpacityMask {  
                maskSource: Rectangle {  
                    width: parent.width  
                    height: parent.height  
                    radius: Appearance.rounding.small  
                }  
            }  
              
            ScrollEdgeFade {  
                z: 1  
                target: responseListView  
                vertical: true  
            }  
              
            StyledListView {  
                id: responseListView  
                visible: root.responses.length > 0  
                model: ScriptModel {  
                    values: root.responses  
                }  
                delegate: WallpaperResponse {  
                    responseData: modelData  
                    tagInputField: root.inputField  
                    previewDownloadPath: root.previewDownloadPath  
                    downloadPath: root.downloadPath  
                    nsfwPath: root.nsfwPath  
                }  
            }
                  
                model: ScriptModel {  
                    values: root.responses  
                }  
                  
                delegate: WallpaperResponse {  
                    responseData: modelData  
                    tagInputField: root.inputField  
                    previewDownloadPath: root.previewDownloadPath  
                    downloadPath: root.downloadPath  
                    nsfwPath: root.nsfwPath  
                }  
                  
                onDragEnded: {  
                    const gap = responseListView.verticalOvershoot  
                    if (gap > root.pullLoadingGap) {  
                        root.pullLoading = true  
                        root.handleInput(`${root.commandPrefix}next`)  
                    }  
                }  
            }  
              
            ScrollToBottomButton {  
                z: 3  
                target: responseListView  
            }  
              
            MaterialLoadingIndicator {  
                id: loadingIndicator  
                z: 4  
                anchors {  
                    horizontalCenter: parent.horizontalCenter  
                    bottom: parent.bottom  
                    bottomMargin: 20 + (root.pullLoading ? 0 : Math.max(0, (root.normalizedPullDistance - 0.5) * 50))  
                }  
                loading: WallpaperBrowser.runningRequests > 0  
            }  
        }  
          
        DescriptionBox {  
            text: root.suggestionList[suggestions.selectedIndex]?.description ?? ""  
            showArrows: root.suggestionList.length > 1  
        }  
          
        FlowButtonGroup {  
            id: suggestions  
            visible: root.suggestionList.length > 0 && searchInputField.text.length > 0  
            property int selectedIndex: 0  
            Layout.fillWidth: true  
            spacing: 5  
              
            Repeater {  
                id: suggestionRepeater  
                model: {  
                    suggestions.selectedIndex = 0;  
                    return root.suggestionList.slice(0, 10);  
                }  
                delegate: ApiCommandButton {  
                    id: commandButton  
                    colBackground: suggestions.selectedIndex === index ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colSecondaryContainer  
                    bounce: false  
                    contentItem: StyledText {  
                        font.pixelSize: Appearance.font.pixelSize.small  
                        color: Appearance.m3colors.m3onSurface  
                        horizontalAlignment: Text.AlignHCenter  
                        text: modelData.displayName ?? modelData.name  
                    }  
                    onHoveredChanged: {  
                        if (commandButton.hovered) {  
                            suggestions.selectedIndex = index;  
                        }  
                    }  
                    onClicked: {  
                        suggestions.acceptSuggestion(modelData.name);  
                    }  
                }  
            }  
              
            function acceptSuggestion(word) {  
                const words = searchInputField.text.trim().split(/\s+/);  
                if (words.length > 0) {  
                    words[words.length - 1] = word;  
                } else {  
                    words.push(word);  
                }  
                const updatedText = words.join(" ") + " ";  
                searchInputField.text = updatedText;  
                searchInputField.cursorPosition = searchInputField.text.length;  
                searchInputField.forceActiveFocus();  
            }  
              
            function acceptSelectedWord() {  
                if (suggestions.selectedIndex >= 0 && suggestions.selectedIndex < suggestionRepeater.count) {  
                    const word = root.suggestionList[suggestions.selectedIndex].name;  
                    suggestions.acceptSuggestion(word);  
                }  
            }  
        }  
          
        Rectangle {  
            id: searchInputContainer  
            property real spacing: 5  
            Layout.fillWidth: true  
            radius: Appearance.rounding.normal - root.padding  
            color: Appearance.colors.colLayer2  
            implicitHeight: Math.max(inputFieldRowLayout.implicitHeight + inputFieldRowLayout.anchors.topMargin + statusRowLayout.implicitHeight + statusRowLayout.anchors.bottomMargin + spacing, 45)  
            clip: true  
              
            RowLayout {  
                id: inputFieldRowLayout  
                anchors.left: parent.left  
                anchors.right: parent.right  
                anchors.top: parent.top  
                anchors.margins: 10  
                spacing: 10  
                  
                StyledTextArea {  
                    id: searchInputField  
                    Layout.fillWidth: true  
                    Layout.fillHeight: true  
                    placeholderText: Translation.tr("Search wallpapers... (e.g., nature, abstract) or use /commands")  
                    font.family: Appearance.font.family.reading  
                    font.pixelSize: Appearance.font.pixelSize.normal  
                      
                    onTextChanged: {  
                        if (searchInputField.text.length === 0) {  
                            root.suggestionQuery = "";  
                            root.suggestionList = [];  
                            return;  
                        } else if (searchInputField.text.startsWith(`${root.commandPrefix}service`)) {  
                            root.suggestionQuery = searchInputField.text.split(" ").slice(1).join(" ");  
                            root.suggestionList = [  
                                { name: `${root.commandPrefix}service unsplash`, description: "Use Unsplash (requires API key)" },  
                                { name: `${root.commandPrefix}service wallhaven`, description: "Use Wallhaven (no API key required)" }  
                            ];  
                        } else if (searchInputField.text.startsWith(`${root.commandPrefix}api`)) {  
                            root.suggestionQuery = searchInputField.text.split(" ").slice(1).join(" ");  
                            if (root.currentService === "wallhaven") {  
                                root.suggestionList = [  
                                    { name: `${root.commandPrefix}api`, description: "Wallhaven doesn't require an API key" }  
                                ];  
                            } else {  
                                root.suggestionList = [  
                                    { name: `${root.commandPrefix}api YOUR_KEY`, description: "Set your Unsplash API key" }  
                                ];  
                            }  
                        } else if (searchInputField.text.startsWith(root.commandPrefix)) {  
                            root.suggestionQuery = searchInputField.text;  
                            root.suggestionList = root.allCommands.filter(cmd => cmd.name.startsWith(searchInputField.text.substring(1))).map(cmd => {  
                                return { name: `${root.commandPrefix}${cmd.name}`, description: `${cmd.description}` };  
                            });  
                        }  
                    }  
                      
                    Keys.onPressed: event => {  
                        if (event.key === Qt.Key_Return && event.modifiers & Qt.ShiftModifier) {  
                            searchInputField.insert(searchInputField.cursorPosition, "\n");  
                        } else if (event.key === Qt.Key_Return) {  
                            const inputText = searchInputField.text;  
                            searchInputField.clear();  
                            root.handleInput(inputText);  
                            event.accepted = true;  
                        } else if (event.key === Qt.Key_Tab) {  
                            if (root.suggestionList.length > 0) {  
                                const selected = root.suggestionList[suggestions.selectedIndex];  
                                searchInputField.text = selected.name + " ";  
                                searchInputField.cursorPosition = searchInputField.text.length;  
                                searchInputField.forceActiveFocus();  
                            }  
                            event.accepted = true;  
                        } else if (event.key === Qt.Key_Up) {  
                            if (suggestions.selectedIndex > 0) {  
                                suggestions.selectedIndex--;  
                            }  
                            event.accepted = true;  
                        } else if (event.key === Qt.Key_Down) {  
                            if (suggestions.selectedIndex < root.suggestionList.length - 1) {  
                                suggestions.selectedIndex++;  
                            }  
                            event.accepted = true;  
                        }  
                    }  
                }  
                  
                Button {  
                    id: searchButton  
                    Layout.preferredWidth: 40  
                    Layout.preferredHeight: 40  
                    enabled: searchInputField.text.trim().length > 0  
                      
                MaterialSymbol {  
                    anchors.centerIn: parent  
                    iconSize: Appearance.font.pixelSize.larger  
                    color: searchButton.enabled ?   
                           Appearance.colors.colOnLayer2 :   
                           Appearance.colors.colOnLayer2Disabled  
                    text: "search"  
                }
                      
                    background: Rectangle {  
                        color: searchButton.enabled ? Appearance.colors.colLayer2Active : Appearance.colors.colLayer2  
                        radius: Appearance.rounding.normal  
                    }  
                      
                    onClicked: {  
                        const inputText = searchInputField.text;  
                        searchInputField.clear();  
                        root.handleInput(inputText);  
                    }  
                }  
            }  
              
            RowLayout {  
                id: statusRowLayout  
                anchors.left: parent.left  
                anchors.right: parent.right  
                anchors.bottom: parent.bottom  
                anchors.bottomMargin: 5  
                anchors.leftMargin: 10  
                anchors.rightMargin: 5  
                spacing: 8  
                  
                ApiInputBoxIndicator {  
                    icon: "wallpaper"  
                    text: currentService === "wallhaven" ? "Wallhaven" : "Unsplash"  
                    tooltipText: Translation.tr("Current service: %1\nSet it with %2service SERVICE").arg(currentService === "wallhaven" ? "Wallhaven" : "Unsplash").arg(root.commandPrefix)  
                }  
                  
                ApiInputBoxIndicator {  
                    icon: "key"  
                    text: "✓"  
                    tooltipText: Translation.tr("API key is set\nChange with %1api YOUR_API_KEY").arg(root.commandPrefix)  
                }  
                  
                Item { Layout.fillWidth: true }  
                  
                ButtonGroup {  
                    padding: 0  
                    Repeater {  
                        model: [  
                            { name: "api" },  
                            { name: "service" }  
                        ]  
                        delegate: ApiCommandButton {  
                            property string commandRepresentation: `${root.commandPrefix}${modelData.name}`  
                            buttonText: commandRepresentation  
                            downAction: () => {  
                                searchInputField.text = commandRepresentation + " ";  
                                searchInputField.cursorPosition = searchInputField.text.length;  
                                searchInputField.forceActiveFocus();  
                            }  
                        }  
                    }  
                }  
            }  
        }  
    }  
      
    property var allCommands: [  
        { name: "api", description: "Set API key for current service", execute: args => {  
            if (args.length === 0) {  
                WallpaperBrowser.addSystemMessage("Usage: /api YOUR_API_KEY");  
                return;  
            }  
            const currentService = root.currentService;  
            if (currentService === "wallhaven") {  
                WallpaperBrowser.addSystemMessage("Wallhaven doesn't require an API key");  
                return;  
            }  
            KeyringStorage.setNestedField(["apiKeys", `wallpapers_${currentService}`], args[0].trim());  
            WallpaperBrowser.addSystemMessage(`API key set for ${currentService}`);  
        } },  
        { name: "service", description: "Change wallpaper service", execute: args => {  
            if (args.length === 0) {  
                WallpaperBrowser.addSystemMessage("Available services: unsplash, wallhaven");  
                return;  
            }  
            const service = args[0].toLowerCase();  
            if (service === "unsplash" || service === "wallhaven") {  
                WallpaperBrowser.setProvider(service);  
            } else {  
                WallpaperBrowser.addSystemMessage("Invalid service. Use: unsplash or wallhaven");  
            }  
        } },  
        { name: "clear", description: "Clear the current list of images", execute: () => {  
            WallpaperBrowser.clearResponses();  
        } },  
        { name: "next", description: "Load next page", execute: () => {  
            if (root.responses.length > 0) {  
                const lastResponse = root.responses[root.responses.length - 1];  
                if (lastResponse.page > 0) {  
                    WallpaperBrowser.makeRequest(lastResponse.tags, false, 20, lastResponse.page + 1);  
                }  
            }  
        } }  
    ]  
      
    function handleInput(inputText) {  
        if (inputText.startsWith(root.commandPrefix)) {  
            const command = inputText.split(" ")[0].substring(1);  
            const args = inputText.split(" ").slice(1);  
            const commandObj = root.allCommands.find(cmd => cmd.name === `${command}`);  
            if (commandObj) {  
                commandObj.execute(args);  
            } else {  
                WallpaperBrowser.addSystemMessage(`Unknown command: ${command}`);  
            }  
        } else {  
            // Parse page number if present  
            const parts = inputText.split(" ");  
            let tags = [];  
            let page = 1;  
              
            parts.forEach(part => {  
                const pageNum = parseInt(part);  
                if (!isNaN(pageNum) && pageNum > 0) {  
                    page = pageNum;  
                } else if (part.trim().length > 0) {  
                    tags.push(part);  
                }  
            });  
              
            if (tags.length > 0) {  
                WallpaperBrowser.makeRequest(tags, false, 20, page);  
            }  
        }  
    }  
}