import 'package:flutter/material.dart';

import 'api.dart';
import 'friend_farm_screen.dart';
import 'messages.dart';
import 'models.dart';

class FriendsScreen extends StatefulWidget {
  final ApiClient api;
  const FriendsScreen({super.key, required this.api});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _name = TextEditingController();
  List<Friend>? _friends;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run(widget.api.friends);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Returns true on success.
  Future<bool> _run(Future<List<Friend>> Function() call) async {
    try {
      final friends = await call();
      if (!mounted) return false;
      setState(() {
        _friends = friends;
        _error = null;
      });
      return true;
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = localize(e.message));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = _friends;
    return Scaffold(
      appBar: AppBar(title: const Text('Соседи')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _name,
                      maxLength: 20,
                      decoration: InputDecoration(labelText: 'Имя соседа', errorText: _error, counterText: ''),
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _add, child: const Text('Добавить')),
                ],
              ),
            ),
            Expanded(
              child: friends == null
                  ? Center(
                      child: _error == null
                          ? const CircularProgressIndicator()
                          : FilledButton(
                              onPressed: () {
                                setState(() => _error = null);
                                _run(widget.api.friends);
                              },
                              child: const Text('Повторить'),
                            ),
                    )
                  : friends.isEmpty
                      ? const Center(child: Text('Пока нет соседей. Добавьте друга по имени.'))
                      : ListView(
                          children: [
                            for (final f in friends)
                              ListTile(
                                leading: const Text('🧑‍🌾', style: TextStyle(fontSize: 28)),
                                title: Text(f.name),
                                subtitle: Text('Уровень ${f.level}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => FriendFarmScreen(api: widget.api, friend: f)),
                                ),
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    // Keep the text on failure so the player can fix a typo instead of retyping.
    if (await _run(() => widget.api.addFriend(name))) _name.clear();
  }
}
