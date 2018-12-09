//# sourceURL=application.js

//
//  application.js
//  CocoaHeadsNLTV
//
//  Created by Jeroen Leenarts on 30-01-18.
//  Copyright © 2018 CocoaHeadsNL. All rights reserved.
//

var baseURL;

function loadingTemplate() {
    var loadingDoc = "<document><loadingTemplate><activityIndicator><text>Loading Page</text></activityIndicator></loadingTemplate></document>";
    var parser = new DOMParser();
    var parsedTemplate = parser.parseFromString(loadingDoc, "application/xml");
    return parsedTemplate;
}

function alertTemplate() {
    var alertDoc = "<document><alertTemplate><title>Error</title><description>Page failed to load</description></alertTemplate></document>";
    var parser = new DOMParser();
    var parsedTemplate = parser.parseFromString(alertDoc, "application/xml");
    return parsedTemplate;
}

function loadAndPushDocument(url) {

    var loadingDocument = loadingTemplate();
    navigationDocument.pushDocument(loadingDocument);

    var request = new XMLHttpRequest();
    request.open("GET", url, true);
    
    request.onreadystatechange = function() {

        if (request.readyState != 4) {
            return;
        }
        
        if (request.status == 200) {
            var document = request.responseXML;
            document.addEventListener("select", handleSelectEvent);
            navigationDocument.replaceDocument(document, loadingDocument)
        }
        else {
            navigationDocument.popDocument();
            var alertDocument = alertTemplate();
            navigationDocument.presentModal(alertDocument);
        }

    };
    request.send();
}

function updateMenuItem(menuItem, url) {

    var request = new XMLHttpRequest();
    request.open("GET", url, true);
    
    request.onreadystatechange = function() {

        if (request.status == 200) {
            var document = request.responseXML;
            document.addEventListener("select", handleSelectEvent);
            var menuItemDocument = menuItem.parentNode.getFeature("MenuBarDocument");
            menuItemDocument.setDocument(document, menuItem)
        }

    };
    
    request.send();
}

function handleSelectEvent(event) {
    var selectedElement = event.target;
    
    var targetURL = selectedElement.getAttribute("selectTargetURL");
    if (!targetURL) {
        return;
    }
    targetURL = baseURL + targetURL;
    
    if (selectedElement.tagName == "menuItem") {
        updateMenuItem(selectedElement, targetURL);
    }
    else {
        loadAndPushDocument(targetURL);
    }
}

function playMedia(extension, mediaType) {
    var videourl = baseURL + extension;
    var singleVideo = new MediaItem(mediaType, videourl);
    var videoList = new Playlist();
    videoList.push(singleVideo);
    var myPlayer = new Player();
    myPlayer.playlist = videoList;
    myPlayer.play();
}

App.onLaunch = function(options) {
    baseURL = options.BASEURL;
    var templateURL = baseURL + "templates/menubar.xml";
    loadAndPushDocument(templateURL);
}

App.onWillResignActive = function() {

}

App.onDidEnterBackground = function() {

}

App.onWillEnterForeground = function() {

}

App.onDidBecomeActive = function() {
    
}

App.onWillTerminate = function() {
    
}
