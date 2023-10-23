import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

const back4AppBaseUrl = 'https://parseapi.back4app.com/classes/contatos';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _errorMessage = "";
  String _response = "";
  XFile? _image;

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro de Contatos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: 'Telefone'),
            ),
            ElevatedButton(
              onPressed: () {
                _getImage(); // Capturar foto da câmera
              },
              child: Text('Capturar Foto'),
            ),
            if (_image != null)
              Image.file(File(_image!.path), width: 100, height: 100),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text;
                final phone = _phoneController.text;

                if (name.isNotEmpty && phone.isNotEmpty) {
                  //&& _image != null
                  createContactInBack4App(name, phone, ''); //(_image!.path) ??
                } else {
                  _errorMessage = "Preencha todos os campos e capture uma foto";
                  setState(() {});
                }
              },
              child: Text('Cadastrar Contato'),
            ),
            Text(_errorMessage, style: TextStyle(color: Colors.red)),
            Text(_response),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ListContactsScreen()),
                );
              },
              child: Text('Listar Contatos'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> createContactInBack4App(
      String name, String phone, String imagePath) async {
    final url = Uri.parse(back4AppBaseUrl);
    final request = http.MultipartRequest('POST', url)
      ..headers['X-Parse-Application-Id'] =
          '' // Substitua pelo ID do seu aplicativo
      ..headers['X-Parse-REST-API-Key'] =
          '' // Substitua pela chave de API REST do seu aplicativo
      ..fields['name'] = name
      ..fields['phone'] = phone
      ..fields['imagePath'] = imagePath;
    //..files.add(await http.MultipartFile.fromPath('image', imagePath))

    final response = await request.send();

    if (response.statusCode == 201) {
      _response = "Contato cadastrado com sucesso";
      setState(() {});
    } else {
      _errorMessage = "Erro ao cadastrar contato";
      setState(() {});
      print(
          'Erro ao enviar contato para o Back4App: ${await response.stream.bytesToString()}');
    }
  }
}

class ListContactsScreen extends StatefulWidget {
  @override
  _ListContactsScreenState createState() => _ListContactsScreenState();
}

class _ListContactsScreenState extends State<ListContactsScreen> {
  List<Map<String, dynamic>> contacts = [];

  @override
  void initState() {
    super.initState();
    fetchContactsFromBack4App();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Contatos'),
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return ListTile(
            title: Text('Nome: ${contact['name']}'),
            subtitle: Text('Telefone: ${contact['phone']}'),
            leading: CircleAvatar(
              backgroundImage: NetworkImage(//contact['image']['url']
                  'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQgOfgjZmIV5tQh_tD7ROPzK--kQhFyqo-tR_cz65aUQA&s'),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditContactScreen(contact),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    deleteContactFromBack4App(contact['objectId']);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> fetchContactsFromBack4App() async {
    final url = Uri.parse(back4AppBaseUrl);
    final response = await http.get(
      url,
      headers: {
        'X-Parse-Application-Id': '', // Substitua pelo ID do seu aplicativo
        'X-Parse-REST-API-Key':
            '', // Substitua pela chave de API REST do seu aplicativo
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      contacts = List<Map<String, dynamic>>.from(data['results']);
      setState(() {});
    } else {
      print('Erro ao buscar contatos do Back4App: ${response.body}');
    }
  }

  Future<void> deleteContactFromBack4App(String objectId) async {
    final url = Uri.parse('$back4AppBaseUrl/$objectId');
    final response = await http.delete(
      url,
      headers: {
        'X-Parse-Application-Id': '', // Substitua pelo ID do seu aplicativo
        'X-Parse-REST-API-Key':
            '', // Substitua pela chave de API REST do seu aplicativo
      },
    );

    if (response.statusCode == 200) {
      fetchContactsFromBack4App();
    } else {
      print('Erro ao excluir contato do Back4App: ${response.body}');
    }
  }
}

class EditContactScreen extends StatefulWidget {
  final Map<String, dynamic> contact;

  EditContactScreen(this.contact);

  @override
  _EditContactScreenState createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.contact['name'];
    _phoneController.text = widget.contact['phone'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Contato'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: 'Telefone'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text;
                final phone = _phoneController.text;

                if (name.isNotEmpty && phone.isNotEmpty) {
                  updateContactInBack4App(
                      widget.contact['objectId'], name, phone);
                } else {
                  // Tratar erro de campos vazios
                }
              },
              child: Text('Salvar Alterações'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> updateContactInBack4App(
      String objectId, String name, String phone) async {
    final url = Uri.parse('$back4AppBaseUrl/$objectId');
    final response = await http.put(
      url,
      headers: {
        'X-Parse-Application-Id': '', // Substitua pelo ID do seu aplicativo
        'X-Parse-REST-API-Key':
            '', // Substitua pela chave de API REST do seu aplicativo
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': name,
        'phone': phone,
      }),
    );

    if (response.statusCode == 200) {
      // Atualização bem-sucedida
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ListContactsScreen()),
      );
    } else {
      print('Erro ao atualizar contato no Back4App: ${response.body}');
    }
  }
}
