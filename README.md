# Fork from https://github.com/Elyx0/react-native-document-picker

(iOS)  
Refer the [documentation](https://developer.apple.com/library/content/documentation/FileManagement/Conceptual/DocumentPickerProgrammingGuide/AccessingDocuments/AccessingDocuments.html#//apple_ref/doc/uid/TP40014451-CH2-SW6) on Apple developer, seem the import action does not require [startAccessingSecurityScopedResource](https://developer.apple.com/documentation/foundation/nsurl/1417051-startaccessingsecurityscopedreso). Refer to the documentation, import action will do as below
```
The document picker calls the delegate’s documentPicker:didPickDocumentAtURL: method when the user selects a file. 
The URL points to a temporary file in the app’s sandbox. The file remains available until the app closes.
```  

**BUT** not sure what is going wrong, the temporary file returned from documentPicker will be clear around 1 minute in auto. I also check the code in other place but did not found any strange.  
  
For my case, I need the file available and support previewing until user press the confirm button. I updated the logic and copy the temporary file returned from documentPicker to another temp folder. Clear function also added for delete the file copied.

Remark:
------
Response updated
```javascript
DocumentPicker.show({
filetype: [xxxx],
},(error,res) => {
console.log(
res.uri,
res.path, // [NSURL path] without schema - iOS only
res.type, // mime type - Android only
res.fileName,
res.fileSize
);
});
```

