import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart' as file_picker;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';


class FolderPage extends StatefulWidget {
  const FolderPage({super.key});

  @override
  _FolderPageState createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  List<firebase_storage.Reference> _files = [];
  List<bool> _selectedItems = [];
  ProgressDialog? _progressDialog;
  late firebase_storage.Reference storageRef;
  bool _isListingFiles = false;

  @override
  void initState() {
    super.initState();
    storageRef = firebase_storage.FirebaseStorage.instance.ref('Public');
    _listFiles();
  }

  Future<void> _listFiles() async {
    if (_isListingFiles) {
      return;
    }

    try {
      setState(() {
        _isListingFiles = true;
      });

      firebase_storage.ListResult result = await storageRef.listAll();
      setState(() {
        _files = result.items;
        _selectedItems = List.generate(result.items.length, (index) => false);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Une erreur est survenue : $e')),
      );
    } finally {
      setState(() {
        _isListingFiles = false;
      });
    }
  }

  Future<void> _uploadFile() async {
    try {
      final filePickerResult = await file_picker.FilePicker.platform.pickFiles(
          type: file_picker.FileType.any);
      if (filePickerResult != null) {
        final fileBytes = filePickerResult.files.single.bytes;
        final fileName = filePickerResult.files.single.name;
        final firebase_storage.Reference storageRef =
            firebase_storage.FirebaseStorage.instance.ref('Public/$fileName');
        await storageRef.putData(fileBytes!);
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

  Future<void> _deleteSelected() async {
    try {
      List<firebase_storage.Reference> selectedFiles = _selectedItems
          .asMap()
          .entries
          .where((entry) => entry.value)
          .map((entry) => _files[entry.key])
          .toList();

      bool confirmDelete = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmation'),
            content: const Text('Voulez-vous vraiment supprimer les fichiers sélectionnés ?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); // Annuler la suppression
                },
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Confirmer la suppression
                },
                child: const Text('Supprimer'),
              ),
            ],
          );
        },
      );

      if (confirmDelete == true) {
        for (var fileRef in selectedFiles) {
          await fileRef.delete();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichiers supprimés avec succès !')),
        );

        _listFiles();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la suppression des fichiers : $e')),
      );
    }
  }

  Future<void> _downloadSelected() async {
    try {
      List<firebase_storage.Reference> selectedFiles = _selectedItems
          .asMap()
          .entries
          .where((entry) => entry.value)
          .map((entry) => _files[entry.key])
          .toList();

      _progressDialog = ProgressDialog(context);
      _progressDialog!.style(message: 'Téléchargement en cours...');
      await _progressDialog!.show();

      final futures = selectedFiles.map((fileRef) async {
        final String downloadUrl = await fileRef.getDownloadURL();
        final String fileName = path.basename(fileRef.fullPath);
        final HttpClientRequest request = await HttpClient().getUrl(Uri.parse(downloadUrl));
        final HttpClientResponse response = await request.close();
        final List<int> bytes = await consolidateHttpClientResponseBytes(response);
        final Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
        final String filePath = path.join(appDocumentsDirectory.path, fileName);
        final File file = File(filePath);
        await file.writeAsBytes(bytes);
      });

      await Future.wait(futures);
      await _progressDialog!.hide();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fichiers téléchargés avec succès !')),
      );
    } catch (e) {
      await _progressDialog!.hide();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec du téléchargement des fichiers : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionnaire de fichiers'),
      ),
      body: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Checkbox(
              value: _selectedItems[index],
              onChanged: (value) {
                _toggleSelection(index);
              },
            ),
            title: Text(path.basename(_files[index].fullPath)),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _uploadFile,
            child: const Icon(Icons.upload),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _deleteSelected,
            child: const Icon(Icons.delete),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _downloadSelected,
            child: const Icon(Icons.download),
          ),
        ],
      ),
    );
  }
}
