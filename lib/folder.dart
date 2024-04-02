import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart'; // Import pour PickedFile
import 'dart:io'; // Import pour la classe File

class FolderPage extends StatefulWidget {
  const FolderPage({Key? key}) : super(key: key);

  @override
  _FolderPageState createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  List<firebase_storage.Reference> _files = [];
  List<bool> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _listFiles();
  }

  Future<void> _listFiles() async {
    try {
      firebase_storage.Reference storageRef =
          firebase_storage.FirebaseStorage.instance.ref('Public');
      firebase_storage.ListResult result = await storageRef.listAll();
      setState(() {
        _files = result.items;
        _selectedItems = List.generate(result.items.length, (index) => false);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Une erreur est survenue : $e')),
      );
    }
  }

  Future<void> _uploadFile() async {
    try {
      final FilePickerResult? pickedFile =
          await FilePicker.platform.pickFiles(type: FileType.any);
      if (pickedFile != null) {
        final File file = File(pickedFile.files.single.path!);
        String filename = path.basename(file.path);
        firebase_storage.Reference storageRef =
            firebase_storage.FirebaseStorage.instance
                .ref('Public/$filename');
        await storageRef.putFile(file);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier téléversé avec succès !')),
        );
        _listFiles();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec du téléversement du fichier : $e')),
      );
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      _selectedItems[index] = !_selectedItems[index];
    });
  }

  void _deleteSelected() {
    // Ajoutez ici la logique pour supprimer les fichiers sélectionnés
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dossier public'),
        leading: IconButton(
          onPressed: _deleteSelected,
          icon: const Icon(Icons.delete),
          tooltip: 'Supprimer les fichiers sélectionnés',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                firebase_storage.Reference fileRef = _files[index];
                String filename = path.basename(fileRef.fullPath);
                bool isSelected = _selectedItems[index];
                return ListTile(
                  title: Text(filename),
                  onTap: () => _toggleSelection(index),
                  tileColor: isSelected ? Colors.blue.withOpacity(0.3) : null,
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _uploadFile(),
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Téléverser un fichier'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
