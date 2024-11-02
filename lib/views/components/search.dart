import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtualhelp_chat/services/constants.dart';
import 'package:virtualhelp_chat/services/database.dart';
import 'package:virtualhelp_chat/services/helper.dart';
import 'package:virtualhelp_chat/views/components/conversation.dart';
import 'package:virtualhelp_chat/views/widgets/app_textfield.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _recentSearchesKey = 'recent_teacher_searches';
  static const int _maxRecentSearches = 10;

  List<TeacherModel> _searchResults = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(_recentSearchesKey) ?? [];
    setState(() {
      _recentSearches = searches;
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> searches = _recentSearches;

    // Remove if exists and add to front
    searches.remove(query);
    searches.insert(0, query);

    // Keep only the most recent searches
    if (searches.length > _maxRecentSearches) {
      searches = searches.sublist(0, _maxRecentSearches);
    }

    await prefs.setStringList(_recentSearchesKey, searches);
    setState(() {
      _recentSearches = searches;
    });
  }

  Future<void> _removeRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> searches = List.from(_recentSearches);
    searches.remove(query);
    await prefs.setStringList(_recentSearchesKey, searches);
    setState(() {
      _recentSearches = searches;
    });
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    setState(() {
      _recentSearches = [];
    });
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
      String searchQuery = _searchController.text.trim().toLowerCase();

      final QuerySnapshot results = await _firestore.collection('teachers').get();

      final List<TeacherModel> filteredResults = results.docs
          .map((doc) => TeacherModel.fromFirestore(doc))
          .where((teacher) => teacher.name.toLowerCase().contains(searchQuery))
          .toList();

      filteredResults.sort((a, b) {
        bool aStartsWith = a.name.toLowerCase().startsWith(searchQuery);
        bool bStartsWith = b.name.toLowerCase().startsWith(searchQuery);

        if (aStartsWith && !bStartsWith) return -1;
        if (!aStartsWith && bStartsWith) return 1;
        return a.name.compareTo(b.name);
      });

      setState(() {
        _searchResults = filteredResults.take(20).toList();
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

  String getChatRoomId(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "${b}_$a";
    } else {
      return "${a}_$b";
    }
  }

  Future<void> _onTeacherSelected(TeacherModel teacher) async {
    _saveRecentSearch(teacher.name); // Save the search when a teacher is selected

    final username = await Helper().getName() ?? "";
    String roomId = getChatRoomId(teacher.name, username);
    List<String> users = [teacher.name, username];
    Map<String, dynamic> chatRoomMap = {
      "chatRoomId": roomId,
      "users": users,
      // "userSvg": usersSvg,
      "unreadMessages": {teacher.name: 0, Constants.localUsername: 0}
    };
    await DatabaseMethods().createChatRoom(roomId, chatRoomMap).then((a) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Conversation(
                    roomId: roomId,
                    svg: teacher.svg,
                    name: teacher.name,
                    receiverId: teacher.id,
                  )));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find a Teacher', style: GoogleFonts.roboto()),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _searchController.text.isEmpty ? _buildRecentSearches() : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AppTextfield(
        controller: _searchController,
        hintText: 'Search for teachers by name',
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

  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearRecentSearches,
                child: Text(
                  'Clear All',
                  style: GoogleFonts.roboto(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final search = _recentSearches[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(search),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _removeRecentSearch(search),
                ),
                onTap: () {
                  _searchController.text = search;
                  _searchTeachers();
                },
              );
            },
          ),
        ),
      ],
    );
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
    final searchQuery = _searchController.text.trim();
    final nameParts = _highlightMatchedText(teacher.name, searchQuery);

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(teacher.svg),
      ),
      title: RichText(
        text: TextSpan(
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          children: nameParts,
        ),
      ),
      onTap: () => _onTeacherSelected(teacher),
    );
  }

  List<TextSpan> _highlightMatchedText(String fullText, String query) {
    if (query.isEmpty) return [TextSpan(text: fullText)];

    final List<TextSpan> spans = [];
    final lowercaseText = fullText.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final int index = lowercaseText.indexOf(lowercaseQuery, start);
      if (index == -1) {
        if (start < fullText.length) {
          spans.add(TextSpan(text: fullText.substring(start)));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(text: fullText.substring(start, index)));
      }

      spans.add(TextSpan(
        text: fullText.substring(index, index + query.length),
        style: const TextStyle(backgroundColor: Colors.yellow),
      ));

      start = index + query.length;
    }

    return spans;
  }

  Widget _buildEmptyState() {
    final String message = _searchController.text.isEmpty
        ? "Search for a teacher by name"
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
  final String svg;

  TeacherModel({
    required this.id,
    required this.name,
    required this.svg,
  });

  factory TeacherModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeacherModel(
      id: doc.id,
      name: data['name'] ?? '',
      svg: data['svg'] ?? '',
    );
  }
}
