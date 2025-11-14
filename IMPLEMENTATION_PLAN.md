# Hugo CMS - Flutter Web Frontend Implementation Plan

## Executive Summary

This document outlines the plan for building a Flutter web application that serves as a user-friendly CMS frontend for Hugo static sites. The goal is to enable non-technical users to create and update content with WYSIWYG features and automatic deployment capabilities.

---

## 1. System Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Web Application                   │
│  ┌────────────────┐  ┌──────────────┐  ┌─────────────────┐ │
│  │  WYSIWYG       │  │   File       │  │   Deployment    │ │
│  │  Editor UI     │──│  Management  │──│   Controller    │ │
│  └────────────────┘  └──────────────┘  └─────────────────┘ │
└─────────────────────────────┬───────────────────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │  Backend Service   │
                    │ (Git + Hugo Build) │
                    └─────────┬──────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
   ┌────▼────┐         ┌──────▼──────┐      ┌──────▼──────┐
   │  Hugo   │         │  Git Repo   │      │   Rsync     │
   │ Content │         │  (Gitea)    │      │  Deploy     │
   └─────────┘         └─────────────┘      └──────┬──────┘
                                                    │
                                             ┌──────▼──────┐
                                             │   kahuna    │
                                             │   Server    │
                                             └─────────────┘
```

### Key Components

1. **Flutter Web Frontend**: User interface with WYSIWYG editing capabilities
2. **Backend API Service**: Handles file operations, Git operations, Hugo builds, and rsync deployment
3. **Git Repository (Gitea)**: Self-hosted Git server storing Hugo content and configuration
4. **Deployment System**: Hugo build + rsync to remote server
5. **Hosting Server (kahuna)**: Self-hosted server serving the static site

---

## 2. Technical Stack

### Frontend (Flutter Web)
- **Framework**: Flutter 3.x (latest stable)
- **Language**: Dart 3.x
- **Rich Text Editor**: `flutter_quill` (WYSIWYG capabilities)
- **Markdown Processing**: `markdown` package for preview/conversion
- **File Management**: Custom widgets for content browsing
- **HTTP Client**: `http` or `dio` for API communication
- **State Management**: `provider` or `riverpod` for application state
- **Routing**: `go_router` for navigation

### Backend Service Options

**Option A: Dart Backend (Recommended for simplicity)**
- **Framework**: `shelf` or `dart_frog`
- **Git Operations**: `git` package or command-line execution
- **File System**: Native Dart I/O
- **Authentication**: JWT tokens

**Option B: Node.js Backend**
- **Framework**: Express.js or Fastify
- **Git Operations**: `simple-git` npm package
- **File System**: Node.js fs module

### Hugo Site
- **Hugo Version**: Latest stable (0.120+)
- **Content Format**: Markdown with YAML frontmatter
- **Theme**: Configurable (user can choose)
- **Configuration**: YAML or TOML

### Deployment & Infrastructure
- **Version Control**: Self-hosted Gitea
- **Build System**: Hugo CLI (executed by backend service)
- **Deployment Method**: Rsync over SSH
- **Hosting**: Self-hosted server (kahuna)
- **Build Trigger**: API call from CMS or Git webhook
- **SSH Authentication**: SSH keys for passwordless rsync

---

## 3. Project Structure

```
hcms/
├── flutter_cms/                 # Flutter web application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/              # Data models
│   │   │   ├── content_file.dart
│   │   │   ├── frontmatter.dart
│   │   │   └── hugo_config.dart
│   │   ├── services/            # Business logic
│   │   │   ├── api_service.dart
│   │   │   ├── content_service.dart
│   │   │   ├── git_service.dart
│   │   │   └── deployment_service.dart
│   │   ├── providers/           # State management
│   │   │   ├── content_provider.dart
│   │   │   ├── auth_provider.dart
│   │   │   └── config_provider.dart
│   │   ├── widgets/             # Reusable UI components
│   │   │   ├── editor/
│   │   │   │   ├── wysiwyg_editor.dart
│   │   │   │   ├── markdown_toolbar.dart
│   │   │   │   └── frontmatter_form.dart
│   │   │   ├── file_browser/
│   │   │   │   ├── content_tree.dart
│   │   │   │   └── file_list_item.dart
│   │   │   └── layout/
│   │   │       ├── app_sidebar.dart
│   │   │       └── app_header.dart
│   │   └── screens/             # Main pages
│   │       ├── login_screen.dart
│   │       ├── dashboard_screen.dart
│   │       ├── content_editor_screen.dart
│   │       ├── media_library_screen.dart
│   │       ├── settings_screen.dart
│   │       └── deployment_screen.dart
│   ├── web/
│   │   ├── index.html
│   │   └── manifest.json
│   ├── pubspec.yaml
│   └── README.md
│
├── backend/                     # Backend API service
│   ├── lib/
│   │   ├── server.dart
│   │   ├── routes/
│   │   │   ├── content_routes.dart
│   │   │   ├── git_routes.dart
│   │   │   └── deploy_routes.dart
│   │   ├── services/
│   │   │   ├── git_service.dart
│   │   │   ├── file_service.dart
│   │   │   └── hugo_service.dart
│   │   └── middleware/
│   │       ├── auth_middleware.dart
│   │       └── cors_middleware.dart
│   ├── pubspec.yaml
│   └── README.md
│
├── hugo_site/                   # Hugo static site
│   ├── config.yaml
│   ├── content/
│   │   ├── posts/
│   │   └── pages/
│   ├── themes/
│   ├── static/
│   │   └── images/
│   ├── layouts/
│   ├── archetypes/
│   └── deploy.sh                # Rsync deployment script
│
├── scripts/
│   ├── build-and-deploy.sh      # Hugo build + rsync deployment
│   └── setup-ssh-keys.sh        # SSH key configuration helper
│
├── docker-compose.yml           # Local development setup
├── .gitignore
└── README.md
```

---

## 4. Core Features & Implementation

### 4.1 Content Management

#### **Content Listing & Navigation**
- Display content directory tree structure
- Filter by content type (posts, pages)
- Search functionality across content
- Sort by date, title, status

**Implementation:**
- Use `DirectoryService` to scan Hugo content directory
- Parse frontmatter to extract metadata
- Display in hierarchical tree widget
- Implement search using fuzzy matching

#### **Content Creation**
- Template selection (from Hugo archetypes)
- Pre-filled frontmatter based on content type
- URL slug generation
- Category/tag management

**Implementation:**
```dart
class ContentService {
  Future<ContentFile> createNewPost({
    required String title,
    required String contentType,
    Map<String, dynamic>? customFrontmatter,
  }) async {
    // Generate filename from title
    final slug = slugify(title);
    final filename = '$slug.md';

    // Create from archetype
    final template = await getArchetype(contentType);

    // Populate frontmatter
    final frontmatter = {
      'title': title,
      'date': DateTime.now().toIso8601String(),
      'draft': true,
      ...?customFrontmatter,
    };

    // Create file
    return ContentFile(
      path: 'content/$contentType/$filename',
      frontmatter: frontmatter,
      body: template.defaultContent,
    );
  }
}
```

### 4.2 WYSIWYG Editor

#### **Rich Text Editing**
- Use `flutter_quill` for WYSIWYG editing
- Support for: bold, italic, headers, lists, links, images
- Live markdown preview in split-pane view
- Code block syntax highlighting

**Implementation:**
```dart
class WysiwygEditor extends StatefulWidget {
  final ContentFile content;
  final Function(String) onContentChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: QuillEditor(
            controller: _quillController,
            scrollController: _scrollController,
            focusNode: _focusNode,
          ),
        ),
        VerticalDivider(),
        Expanded(
          child: MarkdownPreview(
            markdown: convertDeltaToMarkdown(_quillController.document),
          ),
        ),
      ],
    );
  }
}
```

#### **Frontmatter Editor**
- Form-based frontmatter editing
- Type-specific inputs (date picker, tag selector, etc.)
- Validation for required fields
- Custom field support

**Features:**
- Title (text input)
- Date (date/time picker)
- Draft status (toggle)
- Categories/Tags (multi-select chips)
- Featured image (media selector)
- Custom fields (key-value editor)

### 4.3 Media Library

#### **Image Management**
- Upload images to Hugo static directory
- Drag-and-drop upload
- Image preview gallery
- Insert into editor functionality
- Image optimization (resize, compress)

**Implementation:**
```dart
class MediaLibraryService {
  Future<String> uploadImage(Uint8List imageData, String filename) async {
    // Optimize image
    final optimized = await optimizeImage(imageData);

    // Save to static/images/
    final path = 'static/images/$filename';
    await api.uploadFile(path, optimized);

    // Return Hugo-compatible URL
    return '/images/$filename';
  }
}
```

### 4.4 Git Integration

#### **Version Control Operations**
- Auto-save drafts to Git
- Commit with meaningful messages
- View commit history
- Branch management (optional advanced feature)

**Backend Implementation:**
```dart
class GitService {
  final String repoPath;

  Future<void> commitChanges(String message, List<String> files) async {
    // Add files
    await runGit(['add', ...files]);

    // Commit
    await runGit(['commit', '-m', message]);

    // Push to remote
    await runGit(['push', 'origin', 'main']);
  }

  Future<List<Commit>> getHistory(String filePath) async {
    final result = await runGit([
      'log',
      '--pretty=format:%H|%an|%ae|%ad|%s',
      '--',
      filePath,
    ]);

    return parseGitLog(result);
  }
}
```

### 4.5 Deployment

#### **Automated Deployment**
- Trigger Hugo build on content save
- Backend service executes build and deployment
- Deploy via rsync to self-hosted server
- Display build status and logs

**Deployment Script (deploy.sh):**
```bash
#!/bin/sh
# Hugo build and rsync deployment script

USER=erik
HOST=kahuna
DIR=Server/websites/smltags_com/public/

# Navigate to Hugo site directory
cd "$(dirname "$0")"

# Build the Hugo site
echo "Building Hugo site..."
hugo --minify

if [ $? -ne 0 ]; then
    echo "Hugo build failed!"
    exit 1
fi

# Deploy via rsync
echo "Deploying to ${USER}@${HOST}..."
rsync -avz --delete public/ ${USER}@${HOST}:~/${DIR}

if [ $? -eq 0 ]; then
    echo "Deployment successful!"
    exit 0
else
    echo "Deployment failed!"
    exit 1
fi
```

**Backend Deployment Service:**
```dart
class DeploymentService {
  final String hugoSitePath;
  final String deployScriptPath;

  Future<DeploymentResult> deploy() async {
    try {
      // Execute deployment script
      final result = await Process.run(
        'bash',
        [deployScriptPath],
        workingDirectory: hugoSitePath,
      );

      // Capture output
      final output = result.stdout.toString();
      final errors = result.stderr.toString();

      // Return result
      return DeploymentResult(
        success: result.exitCode == 0,
        output: output,
        errors: errors,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return DeploymentResult(
        success: false,
        errors: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  // Stream deployment logs in real-time
  Stream<String> deployWithLogs() async* {
    final process = await Process.start(
      'bash',
      [deployScriptPath],
      workingDirectory: hugoSitePath,
    );

    yield* process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    yield* process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter());
  }
}
```

**Frontend Status Display:**
```dart
class DeploymentScreen extends StatelessWidget {
  Widget build(BuildContext context) {
    return StreamBuilder<BuildStatus>(
      stream: deploymentService.watchBuildStatus(),
      builder: (context, snapshot) {
        return Column(
          children: [
            BuildStatusIndicator(status: snapshot.data),
            DeployButton(
              onPressed: () => deploymentService.triggerDeploy(),
            ),
            RecentDeploymentsList(),
          ],
        );
      },
    );
  }
}
```

---

## 5. User Interface Design

### Dashboard
- Recent content list
- Quick stats (total posts, drafts, published)
- Recent deployments status
- Quick actions (New Post, View Site)

### Content Editor
- Split-pane layout:
  - Left: File browser / Content tree
  - Center: Editor (WYSIWYG + Markdown preview tabs)
  - Right: Frontmatter form / Settings panel
- Top toolbar: Save, Publish, Preview, Settings
- Bottom status bar: Last saved, word count, deployment status

### Settings
- Hugo configuration editor
- Site settings (title, base URL, etc.)
- Theme selection
- Deployment configuration
- User preferences

---

## 6. API Design

### RESTful Endpoints

**Content Management**
```
GET    /api/content              # List all content
GET    /api/content/:path        # Get specific content file
POST   /api/content              # Create new content
PUT    /api/content/:path        # Update content
DELETE /api/content/:path        # Delete content
```

**Media Management**
```
GET    /api/media                # List media files
POST   /api/media                # Upload media
DELETE /api/media/:filename      # Delete media
```

**Git Operations**
```
GET    /api/git/status           # Git status
GET    /api/git/history/:path    # File history
POST   /api/git/commit           # Commit changes
POST   /api/git/push             # Push to remote
```

**Deployment**
```
GET    /api/deploy/status        # Current deployment status
POST   /api/deploy/trigger       # Trigger new deployment
GET    /api/deploy/logs/:id      # Get deployment logs
```

**Configuration**
```
GET    /api/config               # Get Hugo config
PUT    /api/config               # Update Hugo config
```

### Request/Response Examples

**Create Content:**
```json
POST /api/content
{
  "path": "content/posts/my-new-post.md",
  "frontmatter": {
    "title": "My New Post",
    "date": "2025-11-14T10:00:00Z",
    "draft": true,
    "tags": ["flutter", "hugo"]
  },
  "content": "# Hello World\n\nThis is my post content."
}

Response 201:
{
  "success": true,
  "path": "content/posts/my-new-post.md",
  "url": "/posts/my-new-post/"
}
```

---

## 7. Security Considerations

### Authentication & Authorization
- JWT-based authentication
- Role-based access control (Admin, Editor, Viewer)
- Session management
- Secure token storage

### Data Protection
- Input validation and sanitization
- CORS configuration
- Rate limiting on API endpoints
- File upload restrictions (size, type)

### Git Security
- SSH key management for Git operations
- Encrypted credential storage
- Audit logging for all changes

---

## 8. Development Phases

### Phase 1: Foundation (Weeks 1-2)
**Goal:** Set up project structure and basic infrastructure

- [ ] Initialize Flutter web project
- [ ] Set up Hugo site with sample content
- [ ] Create backend API skeleton
- [ ] Implement basic authentication
- [ ] Set up development environment (Docker Compose)

**Deliverables:**
- Running Flutter web app (hello world)
- Basic Hugo site with sample posts
- Backend API serving static content
- Development documentation

### Phase 2: Content Management (Weeks 3-4)
**Goal:** Implement core content management features

- [ ] Build file browser UI
- [ ] Implement content listing API
- [ ] Create content creation flow
- [ ] Add basic markdown editor
- [ ] Parse and display frontmatter

**Deliverables:**
- Functional content browser
- Create/Read/Update operations for content
- Basic text editor

### Phase 3: WYSIWYG Editor (Weeks 5-6)
**Goal:** Implement rich text editing capabilities

- [ ] Integrate flutter_quill
- [ ] Build custom toolbar
- [ ] Implement markdown conversion
- [ ] Add split-pane preview
- [ ] Create frontmatter form UI

**Deliverables:**
- Full WYSIWYG editor
- Live markdown preview
- Frontmatter editing form

### Phase 4: Media Management (Week 7)
**Goal:** Add media upload and management

- [ ] Implement image upload
- [ ] Create media library UI
- [ ] Add image optimization
- [ ] Integrate with editor (insert images)

**Deliverables:**
- Functional media library
- Image upload and management
- Editor integration

### Phase 5: Git Integration (Week 8)
**Goal:** Add version control capabilities

- [ ] Implement Git service in backend
- [ ] Auto-commit on save
- [ ] Display commit history
- [ ] Add manual commit UI

**Deliverables:**
- Automatic version control
- Commit history viewer
- Manual commit functionality

### Phase 6: Deployment (Weeks 9-10)
**Goal:** Automate Hugo builds and deployment

- [ ] Create deployment script (hugo + rsync)
- [ ] Set up SSH keys for passwordless deployment
- [ ] Implement deployment trigger API in backend
- [ ] Build deployment status UI with live logs
- [ ] Add deployment history tracking
- [ ] Test deployment to kahuna server

**Deliverables:**
- Automated deployment pipeline with rsync
- Deployment dashboard with real-time logs
- Build status monitoring
- SSH key configuration documentation

### Phase 7: Polish & Testing (Weeks 11-12)
**Goal:** Refine UI/UX and ensure quality

- [ ] Comprehensive testing (unit, integration, e2e)
- [ ] UI/UX improvements
- [ ] Performance optimization
- [ ] Documentation
- [ ] Bug fixes

**Deliverables:**
- Production-ready application
- Complete documentation
- Test coverage reports

---

## 9. Technical Challenges & Solutions

### Challenge 1: Markdown ↔ Rich Text Conversion
**Problem:** Converting between Quill Delta format and Markdown

**Solution:**
- Use `flutter_quill` with custom converters
- Implement bidirectional conversion library
- Handle edge cases (tables, code blocks, custom HTML)

### Challenge 2: Real-time Collaboration
**Problem:** Multiple users editing same content

**Solution (Future Enhancement):**
- Implement WebSocket-based conflict detection
- Use Operational Transform or CRDT for merging
- Lock files during editing

### Challenge 3: Large File Handling
**Problem:** Performance with many content files

**Solution:**
- Implement pagination in content listing
- Lazy loading for file tree
- Virtual scrolling for large lists
- Caching frequently accessed content

### Challenge 4: Git Conflicts
**Problem:** Merge conflicts from concurrent edits

**Solution:**
- File locking during editing
- Conflict detection before commit
- Manual conflict resolution UI
- Regular pull before edit

---

## 10. Future Enhancements

### Short-term (3-6 months)
- [ ] Draft/preview functionality
- [ ] Content scheduling (publish date)
- [ ] SEO tools (meta tags editor, sitemap preview)
- [ ] Analytics integration (Google Analytics dashboard)
- [ ] Multi-language support (i18n)

### Medium-term (6-12 months)
- [ ] Real-time collaboration
- [ ] Content templates library
- [ ] Advanced media editing (crop, filters)
- [ ] Custom shortcode builder
- [ ] Theme customization UI

### Long-term (12+ months)
- [ ] Mobile apps (iOS/Android)
- [ ] Plugin system for extensions
- [ ] A/B testing features
- [ ] Advanced workflow management
- [ ] Multi-site management

---

## 11. Success Metrics

### User Experience
- Time to create first post: < 2 minutes
- Time to publish update: < 1 minute
- Learning curve: Non-technical user productive in < 30 minutes

### Performance
- Editor load time: < 2 seconds
- Save operation: < 500ms
- Deployment time: < 2 minutes (depends on Hugo site size)
- Build/deploy success rate: > 99%

### Reliability
- Uptime: > 99.9%
- Data loss incidents: 0 (Git provides safety net)
- Successful deployments: > 95%

---

## 12. Resource Requirements

### Development Team
- 1 Flutter Developer (full-time)
- 1 Backend Developer (full-time) OR the same person if proficient in both
- 1 UI/UX Designer (part-time, 50%)
- 1 QA Engineer (part-time, 50%)

### Infrastructure
- **Development:**
  - Local development machines
  - Self-hosted Gitea server (already in place)

- **Production:**
  - Backend hosting (can run on same server as Gitea or separate)
  - Hugo site hosting (kahuna server - already in place)
  - SSH access between backend and kahuna server
  - Optional: Reverse proxy (nginx/caddy) for CMS web interface

### Tools & Services
- Flutter SDK (free)
- Hugo (free)
- Gitea (free, self-hosted)
- Rsync (included with most Linux distributions)
- SSH (included with most Linux distributions)
- No external CI/CD costs (self-hosted deployment)

---

## 13. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Markdown conversion issues | Medium | High | Extensive testing, fallback to raw markdown editor |
| Git conflicts | Medium | Medium | File locking, conflict detection UI |
| Deployment failures | Low | High | Robust error handling, rollback capability |
| Performance with large sites | Medium | Medium | Pagination, lazy loading, caching |
| Security vulnerabilities | Low | High | Security audit, input validation, regular updates |
| Browser compatibility | Low | Medium | Test on major browsers, progressive enhancement |

---

## 14. Getting Started

### Prerequisites
- Flutter SDK 3.16+ installed
- Dart SDK 3.2+ installed
- Hugo CLI installed
- Git installed
- Node.js 18+ (if using Node backend)

### Initial Setup Steps

1. **Clone Repository from Gitea**
   ```bash
   git clone <gitea-repo-url>
   cd hcms
   ```

2. **Initialize Hugo Site**
   ```bash
   hugo new site hugo_site
   cd hugo_site
   # Add theme (if using git submodule)
   git submodule add <theme-repo> themes/<theme-name>
   # Or copy theme directly to themes/ directory
   ```

3. **Set Up Flutter App**
   ```bash
   flutter create flutter_cms
   cd flutter_cms
   flutter pub add flutter_quill provider go_router http
   ```

4. **Set Up Backend**
   ```bash
   cd backend
   dart pub add shelf shelf_router
   ```

5. **Configure SSH Keys for Deployment**
   ```bash
   # Generate SSH key for deployment (if not already exists)
   ssh-keygen -t ed25519 -C "cms-deployment"

   # Copy public key to kahuna server
   ssh-copy-id erik@kahuna

   # Test SSH connection
   ssh erik@kahuna
   ```

6. **Configure Environment**
   - Create `.env` file with configuration:
     ```env
     GITEA_URL=<your-gitea-url>
     HUGO_SITE_PATH=./hugo_site
     DEPLOY_USER=erik
     DEPLOY_HOST=kahuna
     DEPLOY_PATH=Server/websites/smltags_com/public/
     ```
   - Set up Gitea repository webhook (optional)
   - Configure backend server authentication

7. **Create Deployment Script**
   ```bash
   cp scripts/deploy.sh hugo_site/
   chmod +x hugo_site/deploy.sh
   # Test deployment
   cd hugo_site && ./deploy.sh
   ```

8. **Run Development Environment**
   ```bash
   docker-compose up
   ```

---

## 15. Conclusion

This implementation plan provides a comprehensive roadmap for building a Flutter web CMS for Hugo. The phased approach allows for incremental delivery and validation of features, while the modular architecture ensures maintainability and extensibility.

The key success factors are:
1. **User-centric design** - Making content management intuitive for non-technical users
2. **Robust Git integration** - Ensuring no data loss and full version history
3. **Automated deployment** - One-click publishing with reliable builds
4. **Performance** - Fast, responsive UI even with large content libraries

With proper execution, this project can deliver a powerful yet simple content management solution that bridges the gap between Hugo's performance and traditional CMS usability.

---

## Appendix A: Self-Hosted Deployment Architecture

### Deployment Flow Options

#### Option 1: Direct Backend Deployment (Recommended)
```
User clicks "Publish" → Flutter CMS → Backend API → Execute deploy.sh → Hugo Build → Rsync to kahuna
```

**Advantages:**
- Simple, direct control
- Real-time feedback to user
- No additional infrastructure needed
- Easy to debug and monitor

**Implementation:**
- Backend service has SSH keys configured
- Deploy endpoint triggers the deployment script
- Streams logs back to frontend in real-time

#### Option 2: Git Push + Gitea Webhook
```
User clicks "Publish" → Flutter CMS → Git Commit + Push → Gitea Webhook → Trigger deployment service → Hugo Build → Rsync to kahuna
```

**Advantages:**
- Decoupled from CMS
- Can be triggered by any git push
- More "GitOps" style workflow

**Disadvantages:**
- Requires webhook listener service
- More complex setup
- Delayed feedback to user

**Implementation:**
```dart
// Gitea webhook handler
@Route.post('/webhook/gitea')
Future<Response> handleGiteaWebhook(Request request) async {
  final payload = await request.readAsString();
  final data = jsonDecode(payload);

  // Verify webhook secret
  if (!verifyWebhookSignature(request, payload)) {
    return Response.forbidden('Invalid signature');
  }

  // Check if push to main branch
  if (data['ref'] == 'refs/heads/main') {
    // Trigger deployment
    deploymentService.deploy();
  }

  return Response.ok('Webhook processed');
}
```

### SSH Key Management

**Setup for Backend Service:**

1. Generate SSH key pair for the backend service:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/cms_deploy_key -C "cms-backend-deployment"
   ```

2. Add public key to kahuna server:
   ```bash
   ssh-copy-id -i ~/.ssh/cms_deploy_key.pub erik@kahuna
   ```

3. Configure SSH config for easy access:
   ```bash
   # ~/.ssh/config
   Host kahuna
       HostName kahuna
       User erik
       IdentityFile ~/.ssh/cms_deploy_key
       StrictHostKeyChecking no
   ```

4. Test connection:
   ```bash
   ssh kahuna "echo 'Connection successful'"
   ```

### Security Considerations for Self-Hosted Setup

1. **SSH Security:**
   - Use ED25519 keys (more secure than RSA)
   - Restrict SSH key to specific commands (optional):
     ```bash
     # On kahuna, in ~/.ssh/authorized_keys
     command="rsync --server --daemon ." ssh-ed25519 AAAA... cms-backend
     ```
   - Use SSH agent forwarding carefully
   - Regular key rotation

2. **Backend Security:**
   - Backend service should run with minimal privileges
   - Use firewall rules to restrict access
   - Implement rate limiting on deployment endpoint
   - Require authentication for all CMS operations

3. **Gitea Security:**
   - Enable 2FA for Gitea users
   - Use SSH keys for git operations
   - Regular backups of Gitea data
   - Keep Gitea updated

### Deployment Monitoring

**Enhanced Deployment Service with History:**

```dart
class DeploymentHistory {
  final String id;
  final DateTime timestamp;
  final bool success;
  final String output;
  final String? error;
  final String triggeredBy;
  final int durationMs;

  DeploymentHistory({
    required this.id,
    required this.timestamp,
    required this.success,
    required this.output,
    this.error,
    required this.triggeredBy,
    required this.durationMs,
  });
}

class EnhancedDeploymentService {
  final List<DeploymentHistory> _history = [];

  Future<DeploymentHistory> deployWithTracking(String userId) async {
    final id = Uuid().v4();
    final startTime = DateTime.now();

    try {
      final result = await deploy();
      final endTime = DateTime.now();

      final history = DeploymentHistory(
        id: id,
        timestamp: startTime,
        success: result.success,
        output: result.output,
        error: result.errors,
        triggeredBy: userId,
        durationMs: endTime.difference(startTime).inMilliseconds,
      );

      _history.insert(0, history);
      _saveToDatabase(history);

      return history;
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  List<DeploymentHistory> getRecentDeployments({int limit = 20}) {
    return _history.take(limit).toList();
  }
}
```

### Backup and Recovery

**Pre-deployment Backup Strategy:**

```bash
#!/bin/sh
# Enhanced deployment script with backup

USER=erik
HOST=kahuna
DIR=Server/websites/smltags_com/public/
BACKUP_DIR=Server/websites/smltags_com/backups/

# Create backup of current site
BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
ssh ${USER}@${HOST} "cd ~/${DIR} && tar -czf ~/${BACKUP_DIR}/${BACKUP_NAME}.tar.gz ."

# Build Hugo site
hugo --minify || exit 1

# Deploy with rsync
rsync -avz --delete public/ ${USER}@${HOST}:~/${DIR}

# Verify deployment
if [ $? -eq 0 ]; then
    echo "Deployment successful!"
    # Clean old backups (keep last 10)
    ssh ${USER}@${HOST} "cd ~/${BACKUP_DIR} && ls -t | tail -n +11 | xargs rm -f"
    exit 0
else
    echo "Deployment failed! Backup available at ${BACKUP_NAME}.tar.gz"
    exit 1
fi
```

### Performance Optimization

**Incremental Deployments:**

The `--delete` flag in rsync ensures removed files are deleted on the server, while rsync's delta-transfer algorithm only sends changed files, making deployments fast even for large sites.

**Hugo Build Optimization:**

```bash
# Use parallel processing for faster builds
hugo --minify --maxDeletes 100 --gc

# For very large sites, consider:
# - Using Hugo's page bundles
# - Implementing partial rebuilds (only changed content)
# - Caching builds
```

---

## Appendix B: Technology Alternatives Considered

### Editor Alternatives
- **Zefyr**: Simpler but less feature-rich than flutter_quill
- **HTML Editor Enhanced**: Web-based, but harder to convert to markdown
- **Custom solution**: More control but significant development time

### Backend Alternatives
- **Go backend**: Excellent performance, native Git support
- **Python FastAPI**: Quick development, good ecosystem
- **Serverless only**: Lower cost but more complex architecture

### Deployment Platforms
- **Rsync over SSH**: Simple, reliable, full control (Selected)
- **Cloudflare Pages**: Excellent performance, generous free tier
- **AWS Amplify**: More features but higher complexity
- **Git-based deployment**: Direct from Gitea webhooks

---

## Appendix C: References & Resources

### Documentation
- [Hugo Documentation](https://gohugo.io/documentation/)
- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web)
- [flutter_quill Package](https://pub.dev/packages/flutter_quill)
- [Gitea Documentation](https://docs.gitea.io/)
- [Rsync Manual](https://linux.die.net/man/1/rsync)

### Example Projects
- [flutter-hugo-cms](https://github.com/omaroued/flutter-hugo-cms) - Reference implementation
- [Netlify CMS](https://www.netlifycms.org/) - Alternative approach (React-based)

### Tutorials
- [Building a Markdown Editor in Flutter](https://medium.com/yavar/building-a-markdown-editor-in-flutter-a-step-by-step-guide-137b43fe6df5)
- [Hugo Deployment Methods](https://gohugo.io/hosting-and-deployment/)
- [SSH Key-Based Authentication](https://www.ssh.com/academy/ssh/copy-id)
- [Gitea Webhooks](https://docs.gitea.io/en-us/webhooks/)

---

**Document Version:** 1.1
**Last Updated:** 2025-11-14
**Author:** Claude (AI Assistant)
**Status:** Updated for Self-Hosted Infrastructure (Gitea + Rsync)
