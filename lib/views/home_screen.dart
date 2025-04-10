// main_screen.dart (formerly HomeScreen)
import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'chatbot_tab.dart';
import 'settings_tab.dart';

class MainScreen extends StatefulWidget {
  final String? userName;
  final VoidCallback? onLogout;

  const MainScreen({Key? key, this.userName, this.onLogout}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _getAppBarTitle(),
        backgroundColor: Colors.green[800],
        automaticallyImplyLeading: false, // Removes the back arrow
        actions: [
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: widget.onLogout,
              // tooltip: 'Logout',
            ),
        ],
      ),
      body: _getBodyContent(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chatbot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[800],
        onTap: _onItemTapped,
      ),
    );
  }

  Text _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return const Text('Home');
      case 1:
        return const Text('Chatbot');
      case 2:
        return const Text('Settings');
      default:
        return const Text('Banana Assist');
    }
  }

  Widget _getBodyContent() {
    switch (_selectedIndex) {
      case 0:
        return HomeTab(userName: widget.userName, onLogout: widget.onLogout);
      case 1:
        return const ChatbotTab();
      case 2:
        return SettingsTab(onLogout: widget.onLogout);
      default:
        return HomeTab(userName: widget.userName, onLogout: widget.onLogout);
    }
  }
}
