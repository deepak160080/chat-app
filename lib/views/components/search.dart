import 'dart:async';
import 'package:chat_app/views/auth/login_page.dart';
import 'package:chat_app/views/components/conversation.dart';
import 'package:chat_app/views/widgets/app_textfield.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
 State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<TeacherModel> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _searchTeachers();
      } else {
        setState(() {
          _searchResults.clear();
        });
      }
    });
  }

  Future<void> _searchTeachers() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final QuerySnapshot results = await _firestore
          .collection('teachers')
          .where('name', isGreaterThanOrEqualTo: _searchController.text.trim())
          .where('name', isLessThan: '${_searchController.text.trim()}z')
          .limit(20)
          .get();

      setState(() {
        _searchResults = results.docs
            .map((doc) => TeacherModel.fromFirestore(doc))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error searching for teachers: $e");
      setState(() {
        _searchResults.clear();
        _isLoading = false;
      });
      _showErrorSnackBar('Error searching for teachers. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Search', style: GoogleFonts.roboto()),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AppTextfield(
        controller: _searchController,
        hintText: 'Search teachers',
        icon: Icons.search,
        onChanged: (value) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            if (_searchController.text.isNotEmpty) {
              _searchTeachers();
            } else {
              setState(() {
                _searchResults.clear();
              });
            }
          });
        },
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (_isLoading) {
      return Container(
        width: 20,
        height: 20,
        margin: const EdgeInsets.all(10),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    } else if (_searchController.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          _searchController.clear();
          setState(() => _searchResults.clear());
        },
      );
    }
    return null;
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildTeacherListTile(_searchResults[index]);
      },
    );
  }

  Widget _buildTeacherListTile(TeacherModel teacher) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(teacher.name[0].toUpperCase()),
      ),
      title: Text('${teacher.username}_T', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
      subtitle: Text(teacher.name, style: GoogleFonts.roboto()),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => Conversation(roomId: teacher.id, svg: teacher.username, name: teacher.name, )));
        print('Selected teacher: ${teacher.name}');
      },
    );
  }

  Widget _buildEmptyState() {
    final String message = _searchController.text.isEmpty
        ? "Start typing to search for teachers"
        : 'No teachers found with the name "${_searchController.text.trim()}"';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isEmpty ? Icons.search : Icons.search_off,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.roboto(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class TeacherModel {
  final String id;
  final String name;
  final String username;

  TeacherModel({required this.id, required this.name, required this.username});

  factory TeacherModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeacherModel(
      id: doc.id,
      name: data['name'] ?? '',
      username: data['username'] ?? '',
    );
  }
}