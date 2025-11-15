import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'services/api_service.dart';
import 'providers/content_provider.dart';
import 'screens/content_editor_page.dart';

void main() {
  runApp(const HugoCmsApp());
}

class HugoCmsApp extends StatelessWidget {
  const HugoCmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize API service
    final apiService = ApiService(baseUrl: 'http://localhost:8080');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ContentProvider(apiService),
        ),
      ],
      child: MaterialApp.router(
        title: 'Hugo CMS',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: _router,
      ),
    );
  }
}

// Router configuration
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const DashboardScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'editor',
          builder: (BuildContext context, GoRouterState state) {
            return const ContentEditorPage();
          },
        ),
        GoRoute(
          path: 'media',
          builder: (BuildContext context, GoRouterState state) {
            return const MediaLibraryScreen();
          },
        ),
        GoRoute(
          path: 'settings',
          builder: (BuildContext context, GoRouterState state) {
            return const SettingsScreen();
          },
        ),
      ],
    ),
  ],
);

// Dashboard Screen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hugo CMS Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.dashboard,
              size: 100,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to Hugo CMS',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('A modern CMS for Hugo static sites'),
            const SizedBox(height: 40),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _DashboardCard(
                  title: 'Content Editor',
                  icon: Icons.edit_document,
                  description: 'Edit and manage content',
                  onTap: () => context.go('/editor'),
                ),
                _DashboardCard(
                  title: 'Media Library',
                  icon: Icons.photo_library,
                  description: 'Manage images and files',
                  onTap: () => context.go('/media'),
                ),
                _DashboardCard(
                  title: 'Settings',
                  icon: Icons.settings,
                  description: 'Configure your site',
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dashboard Card Widget
class _DashboardCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        child: Container(
          width: 200,
          height: 150,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.deepPurple),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// App Drawer
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.web, size: 40, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'Hugo CMS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Content Management System',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              context.go('/');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Content Editor'),
            onTap: () {
              context.go('/editor');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Media Library'),
            onTap: () {
              context.go('/media');
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              context.go('/settings');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// Placeholder screens
class MediaLibraryScreen extends StatelessWidget {
  const MediaLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Library'),
      ),
      drawer: const AppDrawer(),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Media Library - Coming in Phase 4'),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hugo Site Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            const ListTile(
              leading: Icon(Icons.public),
              title: Text('Base URL'),
              subtitle: Text('https://example.com'),
            ),
            const ListTile(
              leading: Icon(Icons.language),
              title: Text('Language'),
              subtitle: Text('en-us'),
            ),
            const ListTile(
              leading: Icon(Icons.color_lens),
              title: Text('Theme'),
              subtitle: Text('Not configured'),
            ),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Deployment',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(Icons.server),
              title: Text('Deploy Host'),
              subtitle: Text('kahuna'),
            ),
            const ListTile(
              leading: Icon(Icons.folder),
              title: Text('Deploy Path'),
              subtitle: Text('Server/websites/smltags_com/public/'),
            ),
          ],
        ),
      ),
    );
  }
}
