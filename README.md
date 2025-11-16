# Hugo CMS

A modern Flutter web application that serves as a user-friendly CMS frontend for Hugo static sites. Built with Flutter for the web interface and Dart for the backend API.

## Features

- **WYSIWYG Editor**: Rich text editing with live Markdown preview
- **Content Management**: Easy creation and editing of Hugo content
- **Media Library**: Upload and manage images
- **Git Integration**: Automatic version control for all changes
- **One-Click Deployment**: Build and deploy to your server with rsync
- **Self-Hosted**: Complete control over your infrastructure

## Project Structure

```
hcms/
├── flutter_cms/          # Flutter web application
│   ├── lib/
│   │   └── main.dart    # Main application
│   ├── web/             # Web-specific files
│   └── pubspec.yaml
│
├── backend/             # Dart backend API
│   ├── bin/
│   │   └── server.dart  # Server entry point
│   ├── lib/
│   │   ├── routes/      # API routes
│   │   ├── services/    # Business logic
│   │   └── middleware/  # HTTP middleware
│   └── pubspec.yaml
│
├── hugo_site/           # Hugo static site
│   ├── content/         # Markdown content
│   ├── themes/          # Hugo themes
│   ├── config.yaml      # Hugo configuration
│   └── deploy.sh        # Deployment script
│
├── .env                 # Environment configuration
└── IMPLEMENTATION_PLAN.md  # Detailed implementation guide
```

## Prerequisites

- **Dart SDK** 3.2+ ([Install Dart](https://dart.dev/get-dart))
- **Flutter SDK** 3.16+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Hugo** 0.120+ ([Install Hugo](https://gohugo.io/installation/))
- **Git** (for version control)
- **SSH access** to your deployment server

## Quick Start

### 1. Clone the Repository

```bash
git clone <your-gitea-repo-url>
cd hcms
```

### 2. Configure Environment

Copy the example environment file and update with your settings:

```bash
cp .env.example .env
```

Edit `.env`:

```env
PORT=8080
HUGO_SITE_PATH=../hugo_site
DEPLOY_USER=erik
DEPLOY_HOST=kahuna
DEPLOY_PATH=Server/websites/smltags_com/public/
```

### 3. Set Up SSH Keys for Deployment

Generate SSH key (if you don't have one):

```bash
ssh-keygen -t ed25519 -C "cms-deployment"
```

Copy public key to deployment server:

```bash
ssh-copy-id erik@kahuna
```

Test SSH connection:

```bash
ssh erik@kahuna
```

### 4. Install Dependencies

**Backend:**

```bash
cd backend
dart pub get
cd ..
```

**Flutter CMS:**

```bash
cd flutter_cms
flutter pub get
cd ..
```

### 5. Start the Backend Server

```bash
cd backend
dart run bin/server.dart
```

The server will start on `http://localhost:8080`

### 6. Run the Flutter Web App

In a new terminal:

```bash
cd flutter_cms
flutter run -d chrome
```

The app will open in your browser at `http://localhost:*`

### 7. Test Deployment

Build and deploy the Hugo site:

```bash
cd hugo_site
./deploy.sh
```

This will:
1. Build the Hugo site (`hugo --minify`)
2. Deploy to your server via rsync

## API Endpoints

The backend provides the following REST API endpoints:

### Content Management

- `GET /api/content` - List all content files
- `GET /api/content/:path` - Get specific content file
- `POST /api/content` - Create new content
- `PUT /api/content/:path` - Update content
- `DELETE /api/content/:path` - Delete content

### Git Operations

- `GET /api/git/status` - Get Git status
- `POST /api/git/commit` - Commit changes
- `POST /api/git/push` - Push to remote
- `GET /api/git/history/:path` - Get file history

### Deployment

- `GET /api/deploy/status` - Get deployment status
- `POST /api/deploy/trigger` - Trigger deployment
- `GET /api/deploy/history` - Get deployment history

## Development

### Running in Development Mode

**Backend with auto-reload:**

```bash
cd backend
dart run --observe bin/server.dart
```

**Flutter with hot reload:**

```bash
cd flutter_cms
flutter run -d chrome --web-port=8081
```

### Project Configuration

**Hugo Configuration:**

Edit `hugo_site/config.yaml` to customize your Hugo site settings.

**Deployment Configuration:**

Edit `hugo_site/deploy.sh` to modify deployment settings:

```bash
USER=erik
HOST=kahuna
DIR=Server/websites/smltags_com/public/
```

## Usage

### Creating a New Post

1. Open the Flutter CMS in your browser
2. Click "New Post" from the dashboard
3. Fill in the title and content
4. Add tags and categories in the frontmatter
5. Click "Save" to save as a draft
6. Click "Publish" to publish and deploy

### Editing Existing Content

1. Browse content files in the sidebar
2. Click on a file to open it
3. Make your changes
4. Save and publish

### Media Management

1. Go to Media Library
2. Upload images via drag-and-drop
3. Click on an image to insert into your content

### Deployment

The deployment process:

1. Content is saved to Hugo markdown files
2. Changes are committed to Git
3. Hugo builds the static site
4. Site is deployed to server via rsync

## Configuration

### Hugo Site Setup

To use a Hugo theme:

```bash
cd hugo_site
git submodule add <theme-repo-url> themes/<theme-name>
```

Update `config.yaml`:

```yaml
theme: "<theme-name>"
```

### Custom Domain

Update `hugo_site/config.yaml`:

```yaml
baseURL: "https://yourdomain.com/"
```

## Deployment

### Manual Deployment

```bash
cd hugo_site
./deploy.sh
```

### Automated Deployment via CMS

1. Make content changes in the CMS
2. Click "Deploy" button
3. Monitor deployment logs in real-time

### Deployment Verification

After deployment, visit your site to verify changes:

```bash
curl https://yourdomain.com/
```

## Troubleshooting

### Backend Won't Start

**Issue:** `dart: command not found`
**Solution:** Install Dart SDK

**Issue:** `Could not resolve package`
**Solution:** Run `dart pub get` in backend directory

### Deployment Fails

**Issue:** `Permission denied (publickey)`
**Solution:** Set up SSH keys properly:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub erik@kahuna
```

**Issue:** `hugo: command not found`
**Solution:** Install Hugo CLI

### Flutter Build Issues

**Issue:** Dependencies conflict
**Solution:**

```bash
cd flutter_cms
flutter clean
flutter pub get
```

## Production Deployment

### Backend Server

For production, run the backend with a process manager like `systemd`:

Create `/etc/systemd/system/hugo-cms-backend.service`:

```ini
[Unit]
Description=Hugo CMS Backend
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/hcms/backend
ExecStart=/usr/bin/dart run bin/server.dart
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable hugo-cms-backend
sudo systemctl start hugo-cms-backend
```

### Frontend Build

Build Flutter for production:

```bash
cd flutter_cms
flutter build web --release
```

Serve the built files from `flutter_cms/build/web` with nginx or another web server.

## Security Considerations

1. **SSH Keys**: Keep private keys secure, never commit to Git
2. **Environment Variables**: Never commit `.env` file
3. **Access Control**: Implement authentication (TODO in Phase 2)
4. **HTTPS**: Use HTTPS in production
5. **Firewall**: Restrict backend API access

## Contributing

This is a custom CMS built for specific use cases. Feel free to modify and extend as needed.

## License

Proprietary - For internal use

## Support

For detailed implementation information, see [IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md)

## Next Steps

- [ ] Implement authentication system
- [x] Add content browsing and editing (Phase 2 ✅)
- [x] Add basic markdown editor with preview (Phase 2 ✅)
- [x] Add frontmatter form editor (Phase 2 ✅)
- [x] Add WYSIWYG editor (flutter_quill integration) - Phase 3 ✅
- [x] Add media library functionality - Phase 4 ✅
- [ ] Implement real-time deployment logs - Phase 6
- [ ] Add content preview feature
- [ ] Create user management system

## Version History

- **v1.3.0** - Phase 4: Media Management (Current)
  - Complete media library with grid layout
  - Multiple image upload with file picker
  - Image preview and detailed information panel
  - Delete images with confirmation
  - Image picker dialog for editor integration
  - Insert images into content with one click
  - Backend media API with multipart upload support
  - Automatic Hugo-compatible paths (/images/...)

- **v1.2.0** - Phase 3: WYSIWYG Editor
  - Rich text WYSIWYG editor using flutter_quill
  - Bidirectional markdown ↔ Quill Delta conversion
  - Editor mode toggle (WYSIWYG vs Markdown)
  - Full formatting toolbar (bold, italic, headers, lists, quotes, code, links)
  - Seamless conversion between visual and markdown editing
  - Enhanced UI with better visual hierarchy

- **v1.1.0** - Phase 2: Content Management
  - Content file browser with search and filtering
  - Full-featured markdown editor with live preview
  - Frontmatter form editor (date, tags, categories, etc.)
  - Save and commit functionality
  - Integration with backend API
  - State management with Provider

- **v1.0.0** - Phase 1: Project Foundation
  - Basic Flutter web structure
  - Hugo site with sample content
  - Backend API with content, git, and deployment endpoints
  - Deployment script with rsync
