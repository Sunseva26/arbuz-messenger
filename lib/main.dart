import 'dart:io';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

// ===== КОНФИГУРАЦИЯ APPWRITE =====
// Замени на свои данные после регистрации на appwrite.io
const String APPWRITE_ENDPOINT = 'https://cloud.appwrite.io/v1';
const String APPWRITE_PROJECT_ID = 'ТВОЙ_PROJECT_ID';
const String APPWRITE_DATABASE_ID = 'arbuz_db';
const String APPWRITE_CHATS_COLLECTION = 'chats';
const String APPWRITE_MESSAGES_COLLECTION = 'messages';
const String APPWRITE_STORAGE_BUCKET = 'files';

void main() {
  runApp(const ArbuzApp());
}

class ArbuzApp extends StatelessWidget {
  const ArbuzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Арбуз',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF4CAF50),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFFE53935),
          surface: const Color(0xFFF1F8E9),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ===== ГЛАВНЫЙ ЭКРАН =====
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _usernameController = TextEditingController();
  String? _username;
  String? _currentChatId;
  String? _currentChatName;

  @override
  Widget build(BuildContext context) {
    if (_username == null) {
      return _buildLoginScreen();
    }

    if (_currentChatId == null) {
      return _buildChatsList();
    }

    return _buildChatScreen();
  }

  Widget _buildLoginScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.water_drop, size: 80, color: Color(0xFF4CAF50)),
                    const SizedBox(height: 16),
                    const Text(
                      '🍉 Арбуз',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Войдите в мессенджер',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Ваше имя',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_usernameController.text.trim().isNotEmpty) {
                            setState(() {
                              _username = _usernameController.text.trim();
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Войти', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatsList() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍉 Арбуз'),
        actions: [
          IconButton(icon: const Icon(Icons.group_add), onPressed: _createGroup),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF4CAF50)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 40)),
                  const SizedBox(height: 8),
                  Text(_username!, style: const TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Настройки'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Выйти', style: TextStyle(color: Colors.red)),
              onTap: () => setState(() => _username = null),
            ),
          ],
        ),
      ),
      body: FutureBuilder<models.DocumentList>(
        future: _getChats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data!.documents;
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Нет чатов', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Создайте группу кнопкой +', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF4CAF50),
                    child: Text(chat.data['name'].toString().substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(chat.data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    setState(() {
                      _currentChatId = chat.$id;
                      _currentChatName = chat.data['name'];
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatScreen() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() { _currentChatId = null; _currentChatName = null; }),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Text(_currentChatName!.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Text(_currentChatName!),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<models.RealtimeMessage>(
              stream: _subscribeToMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return FutureBuilder<models.DocumentList>(
                  future: _getMessages(),
                  builder: (context, msgSnapshot) {
                    if (!msgSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final messages = msgSnapshot.data!.documents;
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat, size: 60, color: Colors.grey.shade400),
                            Text('Нет сообщений', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.data['username'] == _username;
                        return _buildMessageBubble(msg.data, isMe);
                      },
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final fileUrl = msg['file_url'];
    final fileType = msg['file_type'];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF4CAF50) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(msg['username'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE53935), fontSize: 12)),
                ),
              if (msg['text'] != null && msg['text'].toString().isNotEmpty)
                Text(msg['text'].toString(), style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16)),
              if (fileUrl != null && fileUrl.toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildFilePreview(fileUrl.toString(), fileType.toString()),
              ],
              const SizedBox(height: 4),
              Text(
                _formatTime(msg['created_at'].toString()),
                style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 11),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview(String url, String type) {
    if (type.startsWith('image/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(url, fit: BoxFit.cover, width: 200, loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        }),
      );
    } else if (type.startsWith('video/')) {
      return GestureDetector(
        onTap: () => _downloadAndOpenFile(url, 'video.mp4'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(Icons.play_circle_fill, color: Colors.white, size: 30), SizedBox(width: 8), Text('Видео', style: TextStyle(color: Colors.white))],
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => _downloadAndOpenFile(url, 'file'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.attach_file, size: 24), SizedBox(width: 8), Text('Файл')],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final TextEditingController controller = TextEditingController();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))]),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.attach_file, color: Color(0xFF4CAF50)), onPressed: () => _pickFile()),
            IconButton(icon: const Icon(Icons.camera_alt, color: Color(0xFF4CAF50)), onPressed: () => _pickImage(ImageSource.camera)),
            IconButton(icon: const Icon(Icons.photo, color: Color(0xFF4CAF50)), onPressed: () => _pickImage(ImageSource.gallery)),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Сообщение...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    _sendMessage(text.trim(), null, null);
                    controller.clear();
                  }
                },
              ),
            ),
            IconButton(icon: const Icon(Icons.send, color: Color(0xFF4CAF50)), onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _sendMessage(controller.text.trim(), null, null);
                controller.clear();
              }
            }),
          ],
        ),
      ),
    );
  }

  // ===== МЕТОДЫ APPWRITE =====
  Client _getClient() {
    return Client().setEndpoint(APPWRITE_ENDPOINT).setProject(APPWRITE_PROJECT_ID);
  }

  Future<models.DocumentList> _getChats() async {
    final databases = Databases(_getClient());
    return await databases.listDocuments(databaseId: APPWRITE_DATABASE_ID, collectionId: APPWRITE_CHATS_COLLECTION);
  }

  Future<models.DocumentList> _getMessages() async {
    final databases = Databases(_getClient());
    return await databases.listDocuments(
      databaseId: APPWRITE_DATABASE_ID,
      collectionId: APPWRITE_MESSAGES_COLLECTION,
      queries: [Query.equal('chat_id', _currentChatId!), Query.orderAsc('created_at')],
    );
  }

  Stream<models.RealtimeMessage> _subscribeToMessages() {
    final realtime = Realtime(_getClient());
    return realtime.subscribe([
      'databases.${APPWRITE_DATABASE_ID}.collections.${APPWRITE_MESSAGES_COLLECTION}.documents'
    ]).stream;
  }

  void _sendMessage(String text, String? fileUrl, String? fileType) async {
    final databases = Databases(_getClient());
    await databases.createDocument(
      databaseId: APPWRITE_DATABASE_ID,
      collectionId: APPWRITE_MESSAGES_COLLECTION,
      documentId: ID.unique(),
      data: {
        'chat_id': _currentChatId,
        'username': _username,
        'text': text,
        'file_url': fileUrl ?? '',
        'file_type': fileType ?? '',
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  void _createGroup() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Новая группа'),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: 'Название', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final databases = Databases(_getClient());
                await databases.createDocument(
                  databaseId: APPWRITE_DATABASE_ID,
                  collectionId: APPWRITE_CHATS_COLLECTION,
                  documentId: ID.unique(),
                  data: {'name': controller.text.trim()},
                );
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
            child: const Text('Создать', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      await _uploadFile(File(image.path), 'image/${image.path.split('.').last}');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      await _uploadFile(file, result.files.single.extension ?? 'file');
    }
  }

  Future<void> _uploadFile(File file, String type) async {
    final storage = Storage(_getClient());
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    await storage.createFile(
      bucketId: APPWRITE_STORAGE_BUCKET,
      fileId: ID.unique(),
      file: InputFile(path: file.path, filename: fileName),
    );
    final fileUrl = '${APPWRITE_ENDPOINT}/storage/buckets/${APPWRITE_STORAGE_BUCKET}/files/$fileName/view?project=${APPWRITE_PROJECT_ID}';
    _sendMessage('', fileUrl, type);
  }

  Future<void> _downloadAndOpenFile(String url, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    // Скачивание и открытие файла
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(Uri.parse(url));
    final response = await request.close();
    await response.pipe(file.openWrite());
    await OpenFile.open(file.path);
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return '';
    }
  }
}
