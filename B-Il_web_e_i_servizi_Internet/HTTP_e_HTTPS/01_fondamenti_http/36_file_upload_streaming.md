# 36. File Upload e Streaming

## 36.1 Introduzione al File Upload

**File upload** permette agli utenti di caricare file dal browser al server via HTTP.

**Metodi di upload:**

```
1. Multipart Form Data (tradizionale)
   - Form con enctype="multipart/form-data"
   - Per file e dati misti

2. Base64 Encoding (JSON)
   - File codificato in Base64 in JSON
   - Meno efficiente (33% overhead)

3. Direct Binary Upload
   - PUT request con file binario
   - Più efficiente, un file alla volta

4. Chunked Upload
   - File grande diviso in chunks
   - Ripresa upload se fallisce

5. Streaming Upload
   - File caricato mentre viene letto
   - Nessun buffer in memoria
```

---

## 36.2 Multipart Form Upload

### 36.2.1 - HTML Form

**Basic file upload form:**

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>File Upload</title>
    <style>
        body { font-family: Arial; max-width: 600px; margin: 50px auto; }
        .upload-form { border: 2px dashed #ccc; padding: 20px; }
        input[type="file"] { margin: 10px 0; }
        button { padding: 10px 20px; background: #007bff; color: white; border: none; cursor: pointer; }
        .progress { width: 100%; height: 20px; background: #f0f0f0; display: none; }
        .progress-bar { height: 100%; background: #007bff; width: 0%; transition: width 0.3s; }
    </style>
</head>
<body>
    <h1>Upload File</h1>
    
    <form class="upload-form" id="uploadForm" enctype="multipart/form-data">
        <div>
            <label>Select file:</label>
            <input type="file" name="file" id="fileInput" required>
        </div>
        
        <div>
            <label>Description:</label>
            <input type="text" name="description" placeholder="Optional description">
        </div>
        
        <button type="submit">Upload</button>
        
        <div class="progress" id="progress">
            <div class="progress-bar" id="progressBar"></div>
        </div>
    </form>
    
    <div id="result"></div>
    
    <script>
        const form = document.getElementById('uploadForm');
        const fileInput = document.getElementById('fileInput');
        const progress = document.getElementById('progress');
        const progressBar = document.getElementById('progressBar');
        const result = document.getElementById('result');
        
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            
            const formData = new FormData(form);
            
            progress.style.display = 'block';
            progressBar.style.width = '0%';
            
            try {
                const xhr = new XMLHttpRequest();
                
                // Track upload progress
                xhr.upload.addEventListener('progress', (e) => {
                    if (e.lengthComputable) {
                        const percent = (e.loaded / e.total) * 100;
                        progressBar.style.width = percent + '%';
                    }
                });
                
                xhr.addEventListener('load', () => {
                    if (xhr.status === 200) {
                        const response = JSON.parse(xhr.responseText);
                        result.innerHTML = `<p style="color: green;">✓ Upload successful!</p>
                                           <p>File: ${response.file.filename}</p>
                                           <p>Size: ${response.file.size} bytes</p>`;
                    } else {
                        result.innerHTML = `<p style="color: red;">✗ Upload failed</p>`;
                    }
                    progress.style.display = 'none';
                });
                
                xhr.addEventListener('error', () => {
                    result.innerHTML = `<p style="color: red;">✗ Network error</p>`;
                    progress.style.display = 'none';
                });
                
                xhr.open('POST', '/upload');
                xhr.send(formData);
                
            } catch (error) {
                result.innerHTML = `<p style="color: red;">Error: ${error.message}</p>`;
                progress.style.display = 'none';
            }
        });
        
        // Show file info on selection
        fileInput.addEventListener('change', (e) => {
            const file = e.target.files[0];
            if (file) {
                console.log('Selected file:', {
                    name: file.name,
                    size: file.size,
                    type: file.type,
                    lastModified: new Date(file.lastModified)
                });
            }
        });
    </script>
</body>
</html>
```

### 36.2.2 - Server with Multer

**Express.js file upload:**

```javascript
const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();

// Ensure upload directory exists
const uploadDir = 'uploads';
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Storage configuration
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path.extname(file.originalname);
        const basename = path.basename(file.originalname, ext);
        cb(null, `${basename}-${uniqueSuffix}${ext}`);
    }
});

// File filter
const fileFilter = (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|pdf|doc|docx/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (extname && mimetype) {
        cb(null, true);
    } else {
        cb(new Error('Invalid file type. Allowed: JPEG, PNG, GIF, PDF, DOC, DOCX'));
    }
};

const upload = multer({
    storage,
    fileFilter,
    limits: {
        fileSize: 10 * 1024 * 1024,  // 10MB max
        files: 1
    }
});

// Serve HTML form
app.get('/', (req, res) => {
    res.sendFile(__dirname + '/upload.html');
});

// Handle file upload
app.post('/upload', upload.single('file'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'No file uploaded' });
    }
    
    console.log('File uploaded:', req.file);
    console.log('Description:', req.body.description);
    
    res.json({
        message: 'File uploaded successfully',
        file: {
            filename: req.file.filename,
            originalname: req.file.originalname,
            mimetype: req.file.mimetype,
            size: req.file.size,
            path: req.file.path
        },
        description: req.body.description
    });
});

// Error handling
app.use((err, req, res, next) => {
    console.error(err);
    
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(413).json({ error: 'File too large (max 10MB)' });
        }
        if (err.code === 'LIMIT_UNEXPECTED_FILE') {
            return res.status(400).json({ error: 'Unexpected field' });
        }
    }
    
    res.status(400).json({ error: err.message });
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
```

---

## 36.3 Multiple Files Upload

### 36.3.1 - Multiple Files, Same Field

**HTML:**

```html
<form id="uploadForm" enctype="multipart/form-data">
    <input type="file" name="photos" multiple required>
    <button type="submit">Upload Photos</button>
</form>

<script>
    document.getElementById('uploadForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const formData = new FormData(e.target);
        const files = formData.getAll('photos');
        
        console.log(`Uploading ${files.length} files`);
        
        const response = await fetch('/upload/multiple', {
            method: 'POST',
            body: formData
        });
        
        const result = await response.json();
        console.log(result);
    });
</script>
```

**Server:**

```javascript
const express = require('express');
const multer = require('multer');

const app = express();
const upload = multer({ dest: 'uploads/' });

// Upload multiple files
app.post('/upload/multiple', upload.array('photos', 10), (req, res) => {
    if (!req.files || req.files.length === 0) {
        return res.status(400).json({ error: 'No files uploaded' });
    }
    
    const files = req.files.map(file => ({
        filename: file.filename,
        originalname: file.originalname,
        mimetype: file.mimetype,
        size: file.size
    }));
    
    res.json({
        message: `${req.files.length} files uploaded`,
        files
    });
});

app.listen(3000);
```

### 36.3.2 - Multiple Fields

**Different files in different fields:**

```html
<form id="uploadForm" enctype="multipart/form-data">
    <div>
        <label>Profile Picture:</label>
        <input type="file" name="avatar" accept="image/*" required>
    </div>
    
    <div>
        <label>Documents (max 3):</label>
        <input type="file" name="documents" multiple accept=".pdf,.doc,.docx">
    </div>
    
    <button type="submit">Upload</button>
</form>
```

**Server:**

```javascript
const express = require('express');
const multer = require('multer');

const app = express();
const upload = multer({ dest: 'uploads/' });

app.post('/upload/mixed', upload.fields([
    { name: 'avatar', maxCount: 1 },
    { name: 'documents', maxCount: 3 }
]), (req, res) => {
    const response = {
        message: 'Files uploaded',
        files: {}
    };
    
    if (req.files.avatar) {
        response.files.avatar = req.files.avatar[0];
    }
    
    if (req.files.documents) {
        response.files.documents = req.files.documents;
    }
    
    res.json(response);
});

app.listen(3000);
```

---

## 36.4 Chunked Upload

### 36.4.1 - Client-Side Chunking

**Upload large files in chunks:**

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Chunked Upload</title>
</head>
<body>
    <h1>Chunked File Upload</h1>
    
    <input type="file" id="fileInput">
    <button onclick="uploadFile()">Upload</button>
    
    <div id="status"></div>
    <progress id="progress" max="100" value="0" style="width: 100%;"></progress>
    
    <script>
        const CHUNK_SIZE = 1024 * 1024; // 1MB chunks
        
        async function uploadFile() {
            const fileInput = document.getElementById('fileInput');
            const file = fileInput.files[0];
            
            if (!file) {
                alert('Please select a file');
                return;
            }
            
            const totalChunks = Math.ceil(file.size / CHUNK_SIZE);
            const fileId = Date.now() + '-' + Math.random().toString(36);
            
            console.log(`Uploading ${file.name} (${file.size} bytes) in ${totalChunks} chunks`);
            
            for (let chunkIndex = 0; chunkIndex < totalChunks; chunkIndex++) {
                const start = chunkIndex * CHUNK_SIZE;
                const end = Math.min(start + CHUNK_SIZE, file.size);
                const chunk = file.slice(start, end);
                
                const formData = new FormData();
                formData.append('chunk', chunk);
                formData.append('chunkIndex', chunkIndex);
                formData.append('totalChunks', totalChunks);
                formData.append('fileId', fileId);
                formData.append('filename', file.name);
                
                try {
                    const response = await fetch('/upload/chunk', {
                        method: 'POST',
                        body: formData
                    });
                    
                    const result = await response.json();
                    
                    const progress = ((chunkIndex + 1) / totalChunks) * 100;
                    document.getElementById('progress').value = progress;
                    document.getElementById('status').textContent = 
                        `Uploading: ${progress.toFixed(1)}% (${chunkIndex + 1}/${totalChunks})`;
                    
                    if (result.complete) {
                        document.getElementById('status').textContent = 
                            `✓ Upload complete! File: ${result.filename}`;
                    }
                    
                } catch (error) {
                    console.error('Chunk upload failed:', error);
                    document.getElementById('status').textContent = 
                        `✗ Upload failed at chunk ${chunkIndex + 1}`;
                    return;
                }
            }
        }
    </script>
</body>
</html>
```

### 36.4.2 - Server-Side Chunk Assembly

**Assemble chunks on server:**

```javascript
const express = require('express');
const multer = require('multer');
const fs = require('fs');
const path = require('path');

const app = express();
const upload = multer({ dest: 'temp/' });

const chunksDir = 'chunks';
const uploadsDir = 'uploads';

// Ensure directories exist
[chunksDir, uploadsDir].forEach(dir => {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
});

app.post('/upload/chunk', upload.single('chunk'), async (req, res) => {
    const { chunkIndex, totalChunks, fileId, filename } = req.body;
    const chunk = req.file;
    
    if (!chunk) {
        return res.status(400).json({ error: 'No chunk uploaded' });
    }
    
    // Create directory for this file's chunks
    const fileChunksDir = path.join(chunksDir, fileId);
    if (!fs.existsSync(fileChunksDir)) {
        fs.mkdirSync(fileChunksDir, { recursive: true });
    }
    
    // Save chunk
    const chunkPath = path.join(fileChunksDir, `chunk-${chunkIndex}`);
    fs.renameSync(chunk.path, chunkPath);
    
    console.log(`Received chunk ${parseInt(chunkIndex) + 1}/${totalChunks} for ${filename}`);
    
    // Check if all chunks received
    const receivedChunks = fs.readdirSync(fileChunksDir).length;
    
    if (receivedChunks === parseInt(totalChunks)) {
        // Assemble file
        const finalPath = path.join(uploadsDir, filename);
        const writeStream = fs.createWriteStream(finalPath);
        
        for (let i = 0; i < totalChunks; i++) {
            const chunkPath = path.join(fileChunksDir, `chunk-${i}`);
            const chunkBuffer = fs.readFileSync(chunkPath);
            writeStream.write(chunkBuffer);
        }
        
        writeStream.end();
        
        // Clean up chunks
        fs.rmSync(fileChunksDir, { recursive: true });
        
        console.log(`File assembled: ${filename}`);
        
        return res.json({
            message: 'Upload complete',
            complete: true,
            filename: filename,
            path: finalPath
        });
    }
    
    res.json({
        message: 'Chunk received',
        complete: false,
        received: receivedChunks,
        total: totalChunks
    });
});

app.listen(3000);
```

---

## 36.5 Streaming Upload

### 36.5.1 - Direct Stream to Disk

**Stream upload without buffering:**

```javascript
const express = require('express');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const app = express();

app.post('/upload/stream', (req, res) => {
    const filename = req.headers['x-filename'] || 'upload-' + Date.now();
    const filepath = path.join('uploads', filename);
    
    const writeStream = fs.createWriteStream(filepath);
    let uploadedSize = 0;
    
    req.on('data', (chunk) => {
        uploadedSize += chunk.length;
        console.log(`Received ${uploadedSize} bytes`);
    });
    
    req.pipe(writeStream);
    
    writeStream.on('finish', () => {
        console.log(`Upload complete: ${filename} (${uploadedSize} bytes)`);
        
        res.json({
            message: 'Upload complete',
            filename,
            size: uploadedSize
        });
    });
    
    writeStream.on('error', (error) => {
        console.error('Write error:', error);
        res.status(500).json({ error: 'Upload failed' });
    });
    
    req.on('error', (error) => {
        console.error('Request error:', error);
        writeStream.destroy();
        fs.unlinkSync(filepath);
    });
});

app.listen(3000);
```

**Client:**

```javascript
async function uploadFileStream(file) {
    const response = await fetch('/upload/stream', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/octet-stream',
            'X-Filename': file.name
        },
        body: file
    });
    
    return await response.json();
}

// Usage
const fileInput = document.getElementById('fileInput');
const file = fileInput.files[0];
const result = await uploadFileStream(file);
console.log(result);
```

### 36.5.2 - Stream with Hash Calculation

**Calculate hash while streaming:**

```javascript
const express = require('express');
const fs = require('fs');
const crypto = require('crypto');
const path = require('path');

const app = express();

app.post('/upload/stream-hash', (req, res) => {
    const filename = req.headers['x-filename'] || 'upload-' + Date.now();
    const filepath = path.join('uploads', filename);
    
    const writeStream = fs.createWriteStream(filepath);
    const hash = crypto.createHash('sha256');
    
    let uploadedSize = 0;
    
    req.on('data', (chunk) => {
        uploadedSize += chunk.length;
        hash.update(chunk);
        writeStream.write(chunk);
    });
    
    req.on('end', () => {
        writeStream.end();
        
        const checksum = hash.digest('hex');
        
        console.log(`Upload complete: ${filename}`);
        console.log(`Size: ${uploadedSize} bytes`);
        console.log(`SHA-256: ${checksum}`);
        
        res.json({
            message: 'Upload complete',
            filename,
            size: uploadedSize,
            sha256: checksum
        });
    });
    
    req.on('error', (error) => {
        console.error('Upload error:', error);
        writeStream.destroy();
        fs.unlinkSync(filepath);
        res.status(500).json({ error: 'Upload failed' });
    });
});

app.listen(3000);
```

---

## 36.6 File Download Streaming

### 36.6.1 - Stream File Download

**Efficient file download:**

```javascript
const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();

// Stream download
app.get('/download/:filename', (req, res) => {
    const filename = req.params.filename;
    const filepath = path.join('uploads', filename);
    
    // Check if file exists
    if (!fs.existsSync(filepath)) {
        return res.status(404).json({ error: 'File not found' });
    }
    
    const stat = fs.statSync(filepath);
    
    res.setHeader('Content-Type', 'application/octet-stream');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.setHeader('Content-Length', stat.size);
    
    const readStream = fs.createReadStream(filepath);
    
    readStream.on('error', (error) => {
        console.error('Read error:', error);
        res.status(500).end();
    });
    
    readStream.pipe(res);
});

app.listen(3000);
```

### 36.6.2 - Range Requests (Partial Download)

**Support resumable downloads:**

```javascript
const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();

app.get('/download/:filename', (req, res) => {
    const filename = req.params.filename;
    const filepath = path.join('uploads', filename);
    
    if (!fs.existsSync(filepath)) {
        return res.status(404).json({ error: 'File not found' });
    }
    
    const stat = fs.statSync(filepath);
    const fileSize = stat.size;
    const range = req.headers.range;
    
    if (range) {
        // Parse range header
        const parts = range.replace(/bytes=/, '').split('-');
        const start = parseInt(parts[0], 10);
        const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
        const chunksize = (end - start) + 1;
        
        console.log(`Range request: bytes ${start}-${end}/${fileSize}`);
        
        const readStream = fs.createReadStream(filepath, { start, end });
        
        res.writeHead(206, {
            'Content-Range': `bytes ${start}-${end}/${fileSize}`,
            'Accept-Ranges': 'bytes',
            'Content-Length': chunksize,
            'Content-Type': 'application/octet-stream'
        });
        
        readStream.pipe(res);
    } else {
        // Full file
        res.writeHead(200, {
            'Content-Length': fileSize,
            'Content-Type': 'application/octet-stream',
            'Content-Disposition': `attachment; filename="${filename}"`
        });
        
        fs.createReadStream(filepath).pipe(res);
    }
});

app.listen(3000);
```

---

## 36.7 Image Processing

### 36.7.1 - Resize on Upload

**Process images with Sharp:**

```javascript
const express = require('express');
const multer = require('multer');
const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

const app = express();

const upload = multer({
    dest: 'temp/',
    fileFilter: (req, file, cb) => {
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        } else {
            cb(new Error('Only images allowed'));
        }
    }
});

app.post('/upload/image', upload.single('image'), async (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'No image uploaded' });
    }
    
    const filename = Date.now() + '-' + req.file.originalname;
    const outputPath = path.join('uploads', filename);
    const thumbPath = path.join('uploads', 'thumbs', filename);
    
    try {
        // Create thumbnail directory
        if (!fs.existsSync('uploads/thumbs')) {
            fs.mkdirSync('uploads/thumbs', { recursive: true });
        }
        
        // Original image (optimized)
        await sharp(req.file.path)
            .resize(1920, 1080, { fit: 'inside', withoutEnlargement: true })
            .jpeg({ quality: 85 })
            .toFile(outputPath);
        
        // Thumbnail
        await sharp(req.file.path)
            .resize(300, 300, { fit: 'cover' })
            .jpeg({ quality: 80 })
            .toFile(thumbPath);
        
        // Get metadata
        const metadata = await sharp(outputPath).metadata();
        
        // Clean up temp file
        fs.unlinkSync(req.file.path);
        
        res.json({
            message: 'Image uploaded and processed',
            original: {
                filename,
                path: outputPath,
                width: metadata.width,
                height: metadata.height,
                format: metadata.format,
                size: fs.statSync(outputPath).size
            },
            thumbnail: {
                path: thumbPath,
                size: fs.statSync(thumbPath).size
            }
        });
        
    } catch (error) {
        console.error('Image processing error:', error);
        fs.unlinkSync(req.file.path);
        res.status(500).json({ error: 'Image processing failed' });
    }
});

app.listen(3000);
```

---

## 36.8 Production Best Practices

### 36.8.1 - Complete Upload System

**Full production upload server:**

```javascript
const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const rateLimit = require('express-rate-limit');

const app = express();

// Rate limiting
const uploadLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 10,
    message: 'Too many uploads, try again later'
});

// Storage configuration
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const uploadDir = 'uploads';
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const hash = crypto.randomBytes(16).toString('hex');
        const ext = path.extname(file.originalname);
        cb(null, `${hash}${ext}`);
    }
});

// File validation
const fileFilter = (req, file, cb) => {
    const allowedMimes = {
        'image/jpeg': true,
        'image/png': true,
        'image/gif': true,
        'image/webp': true,
        'application/pdf': true
    };
    
    if (allowedMimes[file.mimetype]) {
        cb(null, true);
    } else {
        cb(new Error(`Invalid file type: ${file.mimetype}`));
    }
};

const upload = multer({
    storage,
    fileFilter,
    limits: {
        fileSize: 10 * 1024 * 1024,  // 10MB
        files: 5
    }
});

// Upload endpoint
app.post('/upload', uploadLimiter, upload.array('files', 5), (req, res) => {
    if (!req.files || req.files.length === 0) {
        return res.status(400).json({ error: 'No files uploaded' });
    }
    
    const files = req.files.map(file => ({
        filename: file.filename,
        originalname: file.originalname,
        mimetype: file.mimetype,
        size: file.size,
        url: `/files/${file.filename}`
    }));
    
    res.json({
        message: `${files.length} file(s) uploaded successfully`,
        files
    });
});

// Serve files
app.get('/files/:filename', (req, res) => {
    const filepath = path.join('uploads', req.params.filename);
    
    if (!fs.existsSync(filepath)) {
        return res.status(404).json({ error: 'File not found' });
    }
    
    res.sendFile(path.resolve(filepath));
});

// Error handling
app.use((err, req, res, next) => {
    console.error(err);
    
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(413).json({ error: 'File too large (max 10MB)' });
        }
        if (err.code === 'LIMIT_FILE_COUNT') {
            return res.status(400).json({ error: 'Too many files (max 5)' });
        }
    }
    
    res.status(400).json({ error: err.message });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Upload server running on port ${PORT}`);
});
```

---

**Capitolo 36 completato!**

Ho completato i capitoli 32-36:
- **32**: CORS Avanzato
- **33**: Content Security Policy (CSP)
- **34**: Subresource Integrity (SRI)
- **35**: MIME Types e Content-Type
- **36**: File Upload e Streaming

Tutti i capitoli includono esempi completi e production-ready! 🎉
