# 35. MIME Types e Content-Type

## 35.1 Introduzione ai MIME Types

**MIME (Multipurpose Internet Mail Extensions)** types indicano il tipo di dati trasmessi via HTTP.

**Struttura MIME Type:**

```
type/subtype[; parameter=value]

Examples:
text/html
text/plain; charset=utf-8
application/json
image/png
video/mp4; codecs="avc1.42E01E, mp4a.40.2"
```

**Categorie principali:**

```
text/*        - Testo leggibile
image/*       - Immagini
audio/*       - Audio
video/*       - Video
application/* - Dati binari/applicazione
multipart/*   - Dati multi-parte
```

---

## 35.2 Common MIME Types

### 35.2.1 - Text Types

**text/html:**

```http
GET /page.html HTTP/1.1
Host: example.com

HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Content-Length: 1234

<!DOCTYPE html>
<html>
...
</html>
```

**text/plain:**

```http
GET /readme.txt HTTP/1.1

HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8

This is plain text
No HTML formatting
```

**text/css:**

```http
GET /styles.css HTTP/1.1

HTTP/1.1 200 OK
Content-Type: text/css

body {
    font-family: Arial;
}
```

**text/javascript (deprecated, use application/javascript):**

```http
GET /app.js HTTP/1.1

HTTP/1.1 200 OK
Content-Type: application/javascript

console.log('Hello');
```

### 35.2.2 - Application Types

**application/json:**

```http
POST /api/users HTTP/1.1
Content-Type: application/json

{"name": "John", "age": 30}

HTTP/1.1 200 OK
Content-Type: application/json

{"id": 123, "status": "created"}
```

**application/xml:**

```http
POST /api/data HTTP/1.1
Content-Type: application/xml

<?xml version="1.0"?>
<user>
    <name>John</name>
    <age>30</age>
</user>
```

**application/pdf:**

```http
GET /document.pdf HTTP/1.1

HTTP/1.1 200 OK
Content-Type: application/pdf
Content-Disposition: inline; filename="document.pdf"

%PDF-1.4
...
```

**application/octet-stream:**

```http
GET /file.bin HTTP/1.1

HTTP/1.1 200 OK
Content-Type: application/octet-stream
Content-Disposition: attachment; filename="file.bin"

Binary data...
```

### 35.2.3 - Image Types

**image/jpeg, image/png, image/gif:**

```http
GET /logo.png HTTP/1.1

HTTP/1.1 200 OK
Content-Type: image/png
Content-Length: 12345

PNG binary data...
```

**image/svg+xml:**

```http
GET /icon.svg HTTP/1.1

HTTP/1.1 200 OK
Content-Type: image/svg+xml

<svg xmlns="http://www.w3.org/2000/svg">
    <circle cx="50" cy="50" r="40" fill="red" />
</svg>
```

**image/webp:**

```http
GET /photo.webp HTTP/1.1

HTTP/1.1 200 OK
Content-Type: image/webp

WebP binary data...
```

### 35.2.4 - Audio/Video Types

**audio/mpeg, audio/wav, audio/ogg:**

```http
GET /song.mp3 HTTP/1.1

HTTP/1.1 200 OK
Content-Type: audio/mpeg
Content-Length: 3456789

MP3 binary data...
```

**video/mp4, video/webm:**

```http
GET /video.mp4 HTTP/1.1

HTTP/1.1 200 OK
Content-Type: video/mp4
Content-Length: 12345678

MP4 binary data...
```

---

## 35.3 Express.js Content-Type

### 35.3.1 - Automatic Content-Type

**Express sets Content-Type automatically:**

```javascript
const express = require('express');
const app = express();

// Automatic Content-Type: application/json
app.get('/api/users', (req, res) => {
    res.json({ users: [] });
});

// Automatic Content-Type: text/html
app.get('/page', (req, res) => {
    res.send('<h1>Hello</h1>');
});

// Automatic Content-Type: text/plain
app.get('/text', (req, res) => {
    res.send('Plain text');
});

// Automatic based on file extension
app.get('/image', (req, res) => {
    res.sendFile(__dirname + '/logo.png');  // image/png
});

app.listen(3000);
```

### 35.3.2 - Manual Content-Type

**Set Content-Type explicitly:**

```javascript
const express = require('express');
const app = express();

// Set specific Content-Type
app.get('/api/data', (req, res) => {
    res.type('application/json');
    res.send('{"message":"Hello"}');
});

// Shorthand - accepts extensions or MIME types
app.get('/xml', (req, res) => {
    res.type('xml');  // Shorthand for application/xml
    res.send('<?xml version="1.0"?><data>Hello</data>');
});

// Using setHeader
app.get('/custom', (req, res) => {
    res.setHeader('Content-Type', 'application/vnd.api+json');
    res.send('{"data":{}}');
});

// Override automatic detection
app.get('/force-download', (req, res) => {
    res.type('application/octet-stream');
    res.setHeader('Content-Disposition', 'attachment; filename="data.txt"');
    res.send('This will download as file');
});

app.listen(3000);
```

### 35.3.3 - Content Negotiation

**Respond based on Accept header:**

```javascript
const express = require('express');
const app = express();

app.get('/api/users', (req, res) => {
    const users = [
        { id: 1, name: 'John' },
        { id: 2, name: 'Jane' }
    ];
    
    res.format({
        // Accept: application/json
        'application/json': () => {
            res.json(users);
        },
        
        // Accept: application/xml
        'application/xml': () => {
            const xml = `
                <?xml version="1.0"?>
                <users>
                    ${users.map(u => `
                        <user>
                            <id>${u.id}</id>
                            <name>${u.name}</name>
                        </user>
                    `).join('')}
                </users>
            `;
            res.type('application/xml').send(xml);
        },
        
        // Accept: text/html
        'text/html': () => {
            const html = `
                <!DOCTYPE html>
                <html>
                <body>
                    <h1>Users</h1>
                    <ul>
                        ${users.map(u => `<li>${u.name}</li>`).join('')}
                    </ul>
                </body>
                </html>
            `;
            res.send(html);
        },
        
        // Default
        'default': () => {
            res.status(406).send('Not Acceptable');
        }
    });
});

app.listen(3000);
```

---

## 35.4 File Upload MIME Types

### 35.4.1 - multipart/form-data

**File upload with multipart:**

```html
<!-- HTML Form -->
<!DOCTYPE html>
<html>
<body>
    <form action="/upload" method="POST" enctype="multipart/form-data">
        <input type="file" name="avatar" accept="image/*">
        <input type="text" name="username">
        <button type="submit">Upload</button>
    </form>
</body>
</html>
```

**Server handling:**

```javascript
const express = require('express');
const multer = require('multer');
const app = express();

const upload = multer({ dest: 'uploads/' });

app.post('/upload', upload.single('avatar'), (req, res) => {
    console.log('File:', req.file);
    // {
    //   fieldname: 'avatar',
    //   originalname: 'photo.jpg',
    //   mimetype: 'image/jpeg',
    //   size: 12345,
    //   ...
    // }
    
    console.log('Body:', req.body);
    // { username: 'john' }
    
    res.json({ message: 'File uploaded', file: req.file });
});

app.listen(3000);
```

### 35.4.2 - MIME Type Validation

**Validate uploaded file types:**

```javascript
const express = require('express');
const multer = require('multer');
const path = require('path');

const app = express();

// Allowed MIME types
const allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp'
];

const storage = multer.diskStorage({
    destination: 'uploads/',
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path.extname(file.originalname);
        cb(null, file.fieldname + '-' + uniqueSuffix + ext);
    }
});

const fileFilter = (req, file, cb) => {
    if (allowedMimeTypes.includes(file.mimetype)) {
        cb(null, true);  // Accept file
    } else {
        cb(new Error(`Invalid file type. Allowed: ${allowedMimeTypes.join(', ')}`), false);
    }
};

const upload = multer({
    storage,
    fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024  // 5MB max
    }
});

app.post('/upload', upload.single('image'), (req, res) => {
    res.json({ 
        message: 'Image uploaded successfully',
        file: req.file 
    });
});

// Error handler
app.use((err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(413).json({ error: 'File too large (max 5MB)' });
        }
    } else if (err) {
        return res.status(400).json({ error: err.message });
    }
    next();
});

app.listen(3000);
```

### 35.4.3 - Multiple Files Upload

**Upload multiple files:**

```javascript
const express = require('express');
const multer = require('multer');

const app = express();
const upload = multer({ dest: 'uploads/' });

// Multiple files, same field
app.post('/upload/multiple', upload.array('photos', 10), (req, res) => {
    console.log('Files:', req.files);
    // Array of files
    
    res.json({ 
        message: `${req.files.length} files uploaded`,
        files: req.files.map(f => ({
            filename: f.filename,
            mimetype: f.mimetype,
            size: f.size
        }))
    });
});

// Multiple files, different fields
app.post('/upload/mixed', upload.fields([
    { name: 'avatar', maxCount: 1 },
    { name: 'gallery', maxCount: 5 }
]), (req, res) => {
    console.log('Avatar:', req.files.avatar);
    console.log('Gallery:', req.files.gallery);
    
    res.json({ 
        avatar: req.files.avatar[0],
        gallery: req.files.gallery
    });
});

app.listen(3000);
```

---

## 35.5 MIME Type Sniffing

### 35.5.1 - X-Content-Type-Options

**Prevent MIME sniffing:**

```javascript
const express = require('express');
const app = express();

// Prevent browsers from MIME-sniffing
app.use((req, res, next) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    next();
});

// Serve file with correct Content-Type
app.get('/script.js', (req, res) => {
    res.type('application/javascript');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.send('console.log("Script")');
});

// If Content-Type is wrong, browser won't execute
app.get('/malicious', (req, res) => {
    res.type('text/plain');  // Wrong type
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.send('<script>alert("XSS")</script>');  // Won't execute
});

app.listen(3000);
```

### 35.5.2 - Security Implications

**MIME sniffing attack:**

```javascript
// ❌ Vulnerable - no X-Content-Type-Options
app.get('/user-upload/:filename', (req, res) => {
    const filepath = path.join('uploads', req.params.filename);
    res.sendFile(filepath);
    // Browser might interpret .txt as .html if contains HTML
});

// ✓ Secure - force correct Content-Type
app.get('/user-upload/:filename', (req, res) => {
    const filepath = path.join('uploads', req.params.filename);
    
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Content-Type', 'application/octet-stream');
    res.setHeader('Content-Disposition', 'attachment');
    
    res.sendFile(filepath);
});
```

---

## 35.6 Custom MIME Types

### 35.6.1 - Register Custom Types

**Define custom MIME types:**

```javascript
const express = require('express');
const mime = require('mime-types');

const app = express();

// Add custom MIME type
mime.types['application/vnd.myapp+json'] = ['myapp'];

app.get('/api/custom', (req, res) => {
    res.type('application/vnd.myapp+json');
    res.json({ 
        data: 'Custom format',
        version: '1.0'
    });
});

// Vendor-specific MIME type
app.get('/api/v2/data', (req, res) => {
    res.type('application/vnd.api+json; version=2');
    res.json({
        data: {
            type: 'users',
            id: '1',
            attributes: { name: 'John' }
        }
    });
});

app.listen(3000);
```

### 35.6.2 - API Versioning with MIME Types

**Version API using Content-Type:**

```javascript
const express = require('express');
const app = express();

app.use(express.json());

app.get('/api/users', (req, res) => {
    const accept = req.get('Accept');
    
    // Version 1
    if (accept.includes('application/vnd.myapi.v1+json')) {
        return res.json({
            users: [
                { id: 1, name: 'John' }
            ]
        });
    }
    
    // Version 2
    if (accept.includes('application/vnd.myapi.v2+json')) {
        return res.json({
            data: [
                {
                    type: 'user',
                    id: '1',
                    attributes: { name: 'John' }
                }
            ]
        });
    }
    
    // Default to latest
    res.json({
        data: [
            {
                type: 'user',
                id: '1',
                attributes: { name: 'John' }
            }
        ]
    });
});

app.listen(3000);
```

---

## 35.7 Nginx MIME Types

### 35.7.1 - Nginx Configuration

**mime.types file:**

```nginx
# /etc/nginx/mime.types
types {
    text/html                             html htm shtml;
    text/css                              css;
    text/xml                              xml;
    image/gif                             gif;
    image/jpeg                            jpeg jpg;
    image/png                             png;
    image/webp                            webp;
    image/svg+xml                         svg svgz;
    
    application/javascript                js;
    application/json                      json;
    application/pdf                       pdf;
    application/zip                       zip;
    
    audio/mpeg                            mp3;
    audio/ogg                             ogg;
    
    video/mp4                             mp4;
    video/webm                            webm;
    
    font/woff                             woff;
    font/woff2                            woff2;
}
```

**nginx.conf:**

```nginx
http {
    include       mime.types;
    default_type  application/octet-stream;
    
    server {
        listen 80;
        server_name example.com;
        
        root /var/www/html;
        
        # Force correct Content-Type for specific files
        location ~* \.js$ {
            add_header Content-Type application/javascript;
            add_header X-Content-Type-Options nosniff;
        }
        
        # Custom MIME type
        location /api/ {
            add_header Content-Type application/vnd.api+json;
            proxy_pass http://backend;
        }
        
        # Download files
        location /downloads/ {
            add_header Content-Type application/octet-stream;
            add_header Content-Disposition "attachment";
        }
    }
}
```

---

## 35.8 Complete MIME Type Example

### 35.8.1 - Production Server

**Full Express server with MIME handling:**

```javascript
const express = require('express');
const multer = require('multer');
const helmet = require('helmet');
const path = require('path');
const mime = require('mime-types');

const app = express();

// Security headers
app.use(helmet({
    contentSecurityPolicy: false,  // Configure separately
    noSniff: true  // X-Content-Type-Options: nosniff
}));

// Body parsing
app.use(express.json({ type: 'application/json' }));
app.use(express.urlencoded({ extended: true }));

// Custom MIME types
mime.types['application/vnd.myapp+json'] = ['myapp'];

// File upload configuration
const storage = multer.diskStorage({
    destination: 'uploads/',
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const fileFilter = (req, file, cb) => {
    const allowedMimes = {
        'image/jpeg': ['.jpg', '.jpeg'],
        'image/png': ['.png'],
        'image/gif': ['.gif'],
        'image/webp': ['.webp'],
        'application/pdf': ['.pdf']
    };
    
    if (allowedMimes[file.mimetype]) {
        cb(null, true);
    } else {
        cb(new Error('Invalid file type: ' + file.mimetype), false);
    }
};

const upload = multer({
    storage,
    fileFilter,
    limits: { fileSize: 10 * 1024 * 1024 }  // 10MB
});

// API endpoints
app.get('/api/users', (req, res) => {
    res.format({
        'application/json': () => {
            res.json({ users: [] });
        },
        'application/xml': () => {
            res.type('application/xml');
            res.send('<?xml version="1.0"?><users></users>');
        },
        'default': () => {
            res.status(406).send('Not Acceptable');
        }
    });
});

// File upload
app.post('/upload', upload.single('file'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'No file uploaded' });
    }
    
    res.json({
        message: 'File uploaded successfully',
        file: {
            filename: req.file.filename,
            mimetype: req.file.mimetype,
            size: req.file.size
        }
    });
});

// Serve uploaded files
app.get('/files/:filename', (req, res) => {
    const filepath = path.join(__dirname, 'uploads', req.params.filename);
    const mimeType = mime.lookup(filepath);
    
    if (!mimeType) {
        return res.status(400).send('Invalid file type');
    }
    
    res.type(mimeType);
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.sendFile(filepath);
});

// Download files
app.get('/download/:filename', (req, res) => {
    const filepath = path.join(__dirname, 'uploads', req.params.filename);
    
    res.type('application/octet-stream');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Content-Disposition', `attachment; filename="${req.params.filename}"`);
    res.sendFile(filepath);
});

// Error handler
app.use((err, req, res, next) => {
    console.error(err);
    
    if (err instanceof multer.MulterError) {
        return res.status(400).json({ error: err.message });
    }
    
    res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log('MIME type handling: Enabled');
    console.log('X-Content-Type-Options: nosniff');
});
```

---

**Capitolo 35 completato!**

Prossimo: **Capitolo 36 - File Upload e Streaming**
