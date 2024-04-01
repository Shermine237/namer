import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart' as path;

class FolderPage extends StatefulWidget {
  const FolderPage({Key? key}) : super(key: key);

  @override
  _FolderPageState createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  List<String> _folders = [];

  @override
  void initState() {
    super.initState();
    _fetchFolders();
  }

  Future<void> _fetchFolders() async {
    List<firebase_storage.Reference> allItems = await _listAllItems();

    List<String> folders = [];

    for (var item in allItems) {
      String folderName = path.dirname(item.fullPath);
      if (!folders.contains(folderName)) {
        folders.add(folderName);
      }
    }

    setState(() {
      _folders = folders;
    });
  }

  Future<List<firebase_storage.Reference>> _listAllItems() async {
    firebase_storage.ListResult result =
        await firebase_storage.FirebaseStorage.instance.ref().listAll();

    return result.items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Folder List'),
      ),
      body: ListView.builder(
        itemCount: _folders.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_folders[index]),
            onTap: () {
              // Handle folder tap
              String folderName = _folders[index];
              // Do something with the folderName
            },
          );
        },
      ),
    );
  }
}