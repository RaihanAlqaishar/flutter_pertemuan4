import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  
  // [LATIHAN 3]: State untuk Daftar Favorit
  final TextEditingController _hobbyController = TextEditingController();
  List<String> _favorites = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadFavorites();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final provider = Provider.of<UserProvider>(context, listen: false);
      _nameController.text = provider.user.name;
      _emailController.text = provider.user.email;
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _hobbyController.dispose();
    super.dispose();
  }

  // [LATIHAN 3]: Muat Daftar Favorit
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = prefs.getStringList('favorites') ?? [];
    });
  }

  // [LATIHAN 3]: Tambah Favorit
  Future<void> _addFavorite() async {
    final hobby = _hobbyController.text.trim();
    if (hobby.isNotEmpty) {
      setState(() {
        _favorites.add(hobby);
        _hobbyController.clear();
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorites', _favorites);
    }
  }

  // [LATIHAN 3]: Hapus Favorit
  Future<void> _removeFavorite(int index) async {
    setState(() {
      _favorites.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);
  }

  // ==========================================
  // [LATIHAN 5]: Validasi Keamanan Profil
  // ==========================================
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final nameText = _nameController.text.trim();
      final emailText = _emailController.text.trim();
      final provider = Provider.of<UserProvider>(context, listen: false);

      // 1. Cek karakter berbahaya / tag HTML (Mencegah XSS Injection)
      final maliciousRegex = RegExp(r'<script.*?>.*?</script>|<.*?>', caseSensitive: false);
      if (maliciousRegex.hasMatch(nameText) || maliciousRegex.hasMatch(emailText)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Peringatan Keamanan: Input mengandung karakter tidak valid/berbahaya!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // 2. Cek apakah email sudah terdaftar di SharedPreferences oleh orang lain
      final prefs = await SharedPreferences.getInstance();
      final registeredEmail = prefs.getString('registered_email');

      if (registeredEmail != null && 
          registeredEmail == emailText && 
          emailText != provider.user.email) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email ini sudah terdaftar oleh akun lain!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Simpan email baru ke registered_email
      await prefs.setString('registered_email', emailText);

      // 3. Simpan profil jika lolos seluruh validasi keamanan
      final updatedUser = provider.user.copyWith(
        name: nameText,
        email: emailText,
        isLoggedIn: true,
      );
      
      provider.updateUser(updatedUser);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil disimpan dengan aman!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Provider.of<UserProvider>(context, listen: false).logout();
              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (provider.user.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.deepPurple,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan Profil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ==========================================
                      // [LATIHAN 3]: Bagian Daftar Favorit
                      // ==========================================
                      const Text(
                        'Daftar Favorit / Hobi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _hobbyController,
                              decoration: const InputDecoration(
                                labelText: 'Tambah Hobi Baru',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addFavorite,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _favorites.isEmpty
                          ? const Text(
                              'Belum ada hobi yang ditambahkan.',
                              style: TextStyle(color: Colors.grey),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _favorites.length,
                              itemBuilder: (context, index) {
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.favorite, color: Colors.deepPurple),
                                    title: Text(_favorites[index]),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeFavorite(index),
                                    ),
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}